package it.finmatica.tr4.elaborazioni

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovyx.gpars.GParsPool
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.InstallazioneParametro
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.elaborazioni.DettaglioElaborazioneDTO
import it.finmatica.tr4.dto.elaborazioni.ElaborazioneMassivaDTO
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.io.FileUtils
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.apache.pdfbox.pdmodel.PDDocument
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin
import org.hibernate.FetchMode
import org.hibernate.criterion.CriteriaSpecification
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.text.DecimalFormat
import java.util.concurrent.ConcurrentHashMap

@Transactional
class ElaborazioniService {

    private static Log log = LogFactory.getLog(ElaborazioniService)

    public static TIPO_ATTIVITA_GENERA_DOCUMENTI = 1
    public static TIPO_ATTIVITA_INVIO_A_TIPOGRAFIA = 2
    public static TIPO_ATTIVITA_INVIO_A_DOCUMENTALE = 3
    public static TIPO_ATTIVITA_ALLEGA_AVVISO_AGID = 4
    public static TIPO_ATTIVITA_INVIO_APPIO = 5
    public static TIPO_ATTIVITA_GENERA_ANGR_TRIB = 6
    public static TIPO_ATTIVITA_CONTROLLA_ANGR_TRIB = 7
    public static TIPO_ATTIVITA_ALLINEAMENTO_ANGR_TRIB = 8

    public static STATO_ATTIVITA_INSERITO = 0
    public static STATO_ATTIVITA_IN_CORSO = 1
    public static STATO_ATTIVITA_COMPLETATA = 2
    public static STATO_ATTIVITA_ERRORE = 3

    public static final TIPO_ELABORAZIONE_PRATICHE = 'P'
    public static final TIPO_ELABORAZIONE_RUOLI = 'R'
    public static final TIPO_ELABORAZIONE_IMPOSTA = 'I'
    public static final TIPO_ELABORAZIONE_ANAGRAFE_TRIBUTARIA = 'AT'
    public static final TIPO_ELABORAZIONE_LETTERA_GENERICA = 'LG'

    public static TIPO_ATTIVITA = [
            STAMPA     : 'S', // Stampa
            TIPOGRAFIA : 'T', // Tipografia
            DOCUMENTALE: 'D', // Documentale
            AGID       : 'A'  // Avviso AgID
    ]

    def dettagliOrderBy = [
            [property: "sogg.cognomeNome", direction: "asc"],
            [property: "id", direction: "asc"]
    ]

    CommonService commonService
    def springSecurityService
    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP
    def modelliService
    def contribuentiService
    SoggettiService soggettiService

    private DOC_FOLDER = "DOC_FOLDER"
    private def docFolder = ''

    def getDocFolder() {
        docFolder = ''
        // Se non è ancora stato caricato si recuperad dal db
        if (docFolder.isEmpty()) {
            docFolder = InstallazioneParametro.get(DOC_FOLDER)?.valore ?: ''
        }

        // Se è configurato nel db
        if (docFolder != null && !docFolder.isEmpty()) {
            // Si verifica l'esistenza della cartella, altrimenti si crea
            def folder = new File(docFolder)
            if (!folder.exists()) {
                folder.mkdirs()
                log.info "Creata cartella elaborazioni massive [${folder}]"
            }
        }

        // A questo punto docFolder contiene il nome della cartella o null se non è condifurato nel db
        return docFolder
    }

    def creaElaborazione(def elab, def dett, def creaElaborazioniSeparate, def creaElaborazioneAAT, def creaDettagliEredi, def selectAllDetails) {

        final def PEC_SUFFISSO = "_PEC"
        final def EMAIL_SUFFISSO = "_EMAIL"
        final def AAT = "_AT"

        ElaborazioneMassiva elaborazionePec = null
        ElaborazioneMassiva elaborazioneEmail = null

        ElaborazioneMassiva elaborazione = new ElaborazioneMassiva(
                [nomeElaborazione: elab.nomeElaborazione,
                 tipoElaborazione: elab.tipoElaborazione,
                 tipoTributo     : elab.tipoTributo,
                 gruppoTributo   : elab.gruppoTributo,
                 tipoPratica     : elab.tipoPratica, // Solo in caso di elaborazioni su pratiche
                 ruolo           : elab.ruolo,            // Solo nel caso di elaborazioni su ruolo
                 anno            : elab.anno,            // Solo nel caso di elaborazioni su anno
                 dataElaborazione: new Date(),
                 utente          : elab.utente,
                 dettagli        : []]
        ).save(flush: true, failOnError: true)

        if (creaElaborazioniSeparate) {
            elaborazionePec = new ElaborazioneMassiva(
                    [nomeElaborazione: "${elab.nomeElaborazione}${PEC_SUFFISSO}",
                     tipoElaborazione: elab.tipoElaborazione,
                     tipoTributo     : elab.tipoTributo,
                     gruppoTributo   : elab.gruppoTributo,
                     tipoPratica     : elab.tipoPratica,
                     ruolo           : elab.ruolo,
                     anno            : elab.anno,
                     dataElaborazione: new Date(),
                     utente          : elab.utente,
                     dettagli        : []]
            ).save(flush: true, failOnError: true)
            elaborazioneEmail = new ElaborazioneMassiva(
                    [nomeElaborazione: "${elab.nomeElaborazione}${EMAIL_SUFFISSO}",
                     tipoElaborazione: elab.tipoElaborazione,
                     tipoTributo     : elab.tipoTributo,
                     gruppoTributo   : elab.gruppoTributo,
                     tipoPratica     : elab.tipoPratica,
                     ruolo           : elab.ruolo,
                     anno            : elab.anno,
                     dataElaborazione: new Date(),
                     utente          : elab.utente,
                     dettagli        : []]
            ).save(flush: true, failOnError: true)
        }

        def elabTemp = elaborazione
        int i = 0
        int nEmail = 0
        int nPec = 0

        def codiciFiscali = []

        dett.each {
            def cont = Contribuente.findByCodFiscale(it.codFiscale).toDTO(["soggetto"])

            if (creaElaborazioniSeparate) {
                // PEC
                if (contribuentiService.fRecapito(cont.soggetto.id, elab.tipoTributo.tipoTributo, 3)) {
                    elabTemp = elaborazionePec
                    nPec++
                } else if (contribuentiService.fRecapito(cont.soggetto.id, elab.tipoTributo.tipoTributo, 2)) {
                    // EMAIL
                    elabTemp = elaborazioneEmail
                    nEmail++
                } else {
                    elabTemp = elaborazione
                }
            }
            def dettaglioPrincipale = (new DettaglioElaborazione([
                    pratica        : it.pratica, // Elaborazioni su pratica
                    contribuente   : cont.toDomain(),
                    elaborazione   : elabTemp,
                    flagSelezionato: ((selectAllDetails ?: false) ? 'S' : null)
            ])
            ).save(failOnError: true, flush: true)

            if (creaDettagliEredi) {
                def erediSoggetto = soggettiService.getErediSoggetto(cont.soggetto)
                // In caso di gestione degli eredi si elimina il dettaglio per il deceduto
                if (!erediSoggetto.empty) {
                    dettaglioPrincipale.delete(failOnError: true, flush: true)
                }
                erediSoggetto.each { eredeSoggetto ->
                    (new DettaglioElaborazione([
                            pratica        : it.pratica, // Elaborazioni su pratica
                            contribuente   : cont.toDomain(),
                            elaborazione   : elabTemp,
                            flagSelezionato: ((selectAllDetails ?: false) ? 'S' : null),
                            eredeSoggetto  : eredeSoggetto.toDomain()
                    ])
                    ).save(failOnError: true, flush: true)
                }
            }

            if (++i % 100 == 0) cleanUpGorm()
        }

        if (creaElaborazioniSeparate) {
            if (nEmail == 0) {
                elaborazioneEmail.delete(flush: true)
            }

            if (nPec == 0) {
                elaborazionePec.delete(flush: true)
            }
        }

        if (creaElaborazioneAAT) {
            creaElaborzioneAT(elaborazione.id)
        }

        if (!creaElaborazioniSeparate) {
            return elaborazione
        } else {
            return [elabEmail: elaborazioneEmail, elabPer: elaborazionePec]
        }
    }

    def creaElaborzioneAT(def idElaborazioneDaCopiare) {

        ElaborazioneMassivaDTO elaborazione = ElaborazioneMassiva.get(idElaborazioneDaCopiare).toDTO()
        List<DettaglioElaborazioneDTO> dettagli = DettaglioElaborazione.findAllByElaborazione(elaborazione.toDomain()).toDTO()

        elaborazione.id = null
        elaborazione.ruolo = null
        elaborazione.nomeElaborazione += '_AT'
        elaborazione.tipoElaborazione = TipoElaborazione.findById(TIPO_ELABORAZIONE_ANAGRAFE_TRIBUTARIA).toDTO()
        elaborazione.dataElaborazione = new Date()
        elaborazione.dettagli = []
        elaborazione = elaborazione.toDomain().save(failOnError: true, flush: true).toDTO()

        def i = 0
        def codiciFiscali = []
        dettagli.each {

            if (!(it.contribuente.codFiscale in codiciFiscali)) {
                codiciFiscali << it.contribuente.codFiscale

                (new DettaglioElaborazione([
                        contribuente   : it.contribuente.toDomain(),
                        elaborazione   : elaborazione.toDomain(),
                        flagSelezionato: "S"
                ])
                ).save(failOnError: true, flush: true)
            }

            if (++i % 100 == 0) cleanUpGorm()
        }

    }

    def listaElaborazioni(def params = null, def filtri = null, def sortBy = null, def listaTributiAbilitati) {

        params = params ?: [:]
        params.max = params.max ?: 20
        params.activePage = params.activePage ?: 0
        params.offset = params.activePage * params.max

        List<ElaborazioneMassiva> elencoElaborazioni = ElaborazioneMassiva.createCriteria().list(params) {
            createAlias('tipoElaborazione', 'tiel', CriteriaSpecification.LEFT_JOIN)
            createAlias('tiel.tipiAttivitaElaborazione', 'tiatel', CriteriaSpecification.LEFT_JOIN)

            setResultTransformer(CriteriaSpecification.DISTINCT_ROOT_ENTITY)

            order('id', "desc")

            if (filtri?.utente) {
                eq('utente', filtri.utente)
            }

            if (!listaTributiAbilitati?.empty) {
                'in'("tipoTributo.tipoTributo", listaTributiAbilitati)
            }
        }

        List<GruppoTributo> gruppiTributo = GruppoTributo.createCriteria().list(params) {

            order('gruppoTributo', "asc")

            if (!listaTributiAbilitati?.empty) {
                'in'("tipoTributo.tipoTributo", listaTributiAbilitati)
            }
        }

        return [
                record      : elencoElaborazioni.collect { elab ->

                    GruppoTributo gruppoTributo = gruppiTributo.find { grp -> grp.tipoTributo == elab.tipoTributo && grp.gruppoTributo == elab.gruppoTributo }
                    String gruppoTributoDescr = gruppoTributo?.descrizione ?: ''

                    elab.toDTO().asMap() + [
                            documenti               : DettaglioElaborazione.countByElaborazione(elab),
                            attivita                : [],
                            tipoTributoDescrizione  : elab.tipoTributo.getTipoTributoAttuale(),
                            gruppoTributoDescrizione: gruppoTributoDescr
                    ]

                },
                numeroRecord: elencoElaborazioni.totalCount
        ]

    }

    def listaAttivita(def elaborazione) {

        def lista = AttivitaElaborazione.findAllByElaborazione(ElaborazioneMassiva.get(elaborazione)).toDTO(["tipoAttivita", "modello", "tipoSpedizione", "statoAttivita", "dettaglioComunicazione"]).sort { -it.id }
                .collect {

                    def stampe = DettaglioElaborazione.countByStampaId(it.id)
                    def tipografia = DettaglioElaborazione.countByTipografiaId(it.id)
                    def documentale = DettaglioElaborazione.countByDocumentaleId(it.id)
                    def agid = DettaglioElaborazione.countByAvvisoAgidId(it.id)
                    def appio = DettaglioElaborazione.countByAppioId(it.id)
                    def anagr = DettaglioElaborazione.countByAnagrId(it.id)
                    def contrAT = DettaglioElaborazione.countByControlloAtId(it.id)
                    def allAT = DettaglioElaborazione.countByAllineamentoAtId(it.id)

                    def elaborati = stampe > 0 ? stampe : tipografia > 0 ? tipografia : documentale > 0 ? documentale : agid > 0 ? agid : appio > 0 ? appio :
                            anagr > 0 ? anagr : contrAT > 0 ? contrAT : allAT

                    def documentoPresente = (AttivitaElaborazioneDocumento.countByIdAndDocumentoIsNotNull(it.id) > 0)

                    def totaleElaborati = 0
                    if (it?.statoAttivita?.id == 1) {
                        totaleElaborati = totaleListaDettagliDaElaborare(it.elaborazione.id)
                    }

                    it.asMap() +
                            [elaborati               : elaborati,
                             totaleElaborati         : totaleElaborati,
                             documento               : null,
                             documentoPresente       : documentoPresente,
                             ultimaAttivitaIsInvioDoc: false
                            ]
                }

        // Controllo se l'ultima attività è di tipo INVIO AL DOCUMENTALE per disabilitare l'operazione di elimina di ciascuna attività
        boolean ultimaAttivitaIsInvioDoc = (lista.size() == 0) ? false : (lista[0].tipoAttivita.id == 3)
        lista.each() {
            it.ultimaAttivitaIsInvioDoc = ultimaAttivitaIsInvioDoc
        }

        return lista
    }

    def totaleListaDettagliDaElaborare(def idElaborazione) {
        def parametri = [:]
        parametri.pIdElaborazione = idElaborazione

        String sql = """
					SELECT 1
					FROM DettaglioElaborazione dett
					WHERE dett.elaborazione.id = :pIdElaborazione
					and dett.flagSelezionato = 'S'
				"""
        return DettaglioElaborazione.executeQuery(sql, parametri)?.size()
    }

    def totaleAttivitaAttive() {
        def attivitaInCorso = AttivitaElaborazione.findAllByStatoAttivita(StatoAttivita.get(STATO_ATTIVITA_IN_CORSO)).size()
        def attivitaInAttesa = AttivitaElaborazione.findAllByStatoAttivita(StatoAttivita.get(STATO_ATTIVITA_INSERITO)).size()
        return attivitaInCorso + attivitaInAttesa
    }

    def listaDettagli(def elaborazione, def params = null, def filtri = null, def sortBy = null) {

        def elencoDettagli = _listaDettagli(elaborazione, params, filtri, sortBy)

        return [
                record      : elencoDettagli.collect {

                    def p = it.pratica
                    def cf = p?.contribuente?.codFiscale ?: it.contribuente.codFiscale
                    def cn =
                            "${p?.contribuente?.soggetto?.cognome ?: it?.contribuente?.soggetto?.cognome ?: ''} ${p?.contribuente?.soggetto?.nome ?: it?.contribuente?.soggetto?.nome ?: ''}"
                    def tipoTributo = p?.tipoTributo?.toDTO()?.getTipoTributoAttuale(p?.anno)

                    // Se si richiede tutto l'elenco siamo in stampa e l'informazione sulla presenza del documento non serve
                    def documentoPresente =
                            params.max == Integer.MAX_VALUE ? null : (DettaglioElaborazioneDocumento.countByIdAndDocumentoIsNotNull(it.id) > 0)

                    it.asMap() +
                            [codFiscale   : cf, nominativo: cn, tipoTributoDesc: tipoTributo,
                             documento    : null, documentoPresente: documentoPresente,
                             eredeSoggetto: it.eredeSoggetto?.toDTO(['soggettoErede'])]
                },
                numeroRecord: elencoDettagli.totalCount
        ]

    }

    def listaDettagliDaElaborare(def elaborazione, def sortBy) {

        def dettagliDaElaborare = DettaglioElaborazione.createCriteria().list {

            createAlias("contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.LEFT_JOIN)

            eq('elaborazione', elaborazione)
            eq('flagSelezionato', 'S')

            fetchMode("pratica", FetchMode.JOIN)

            if (sortBy) {
                sortBy.each {
                    order(it.property, it.direction)
                }
            }
        }

        return dettagliDaElaborare
    }

    def aggiornaSelezioneDettaglio(def selezione) {
        // Aggiornamento puntuale
        def dett = DettaglioElaborazione.get(selezione.keySet()[0])
        dett.flagSelezionato = (selezione.values()[0] ? 'S' : null)
        dett.save(failOnError: true, flush: true)

    }

    def aggiornaSelezioneDettagli(def elaborazione, def dettagli, def value) {

        def subListSize = 250
        def subList = dettagli.collect { it.id }.collate(subListSize)

        subList.each {
            DettaglioElaborazione.executeUpdate(
                    """update DettaglioElaborazione set flagSelezionato = ${value ? "'S'" : null} where id in :idDettagli""",
                    [idDettagli: it]
            )

        }

    }

    def listaDettagliSoloId(def elaborazione, def params = null, def filtri = null, def sortBy = null) {

        def elencoDettagli = _listaDettagli(elaborazione, params, filtri, sortBy)

        return elencoDettagli.collect { ["id": it.id, "flagSelezionato": (it.flagSelezionato == 'S')] }
    }

    def creaAttivita(def attivita) {

        def att = new AttivitaElaborazione(
                [
                        dataAttivita          : new Date(),
                        tipoAttivita          : attivita.tipoAttivita,
                        statoAttivita         : attivita.statoAttivita,
                        modello               : attivita.modello,
                        flagF24               : attivita.flagF24,
                        elaborazione          : ElaborazioneMassiva.get(attivita.elaborazione),
                        tipoSpedizione        : attivita.tipoSpedizione,
                        testoAppio            : attivita.testoAppio,
                        flagNotifica          : attivita.notifica,
                        dettaglioComunicazione: attivita.dettaglioComunicazione?.toDomain(),
                ]
        )

        return att.save(failOnError: true, flush: true)

    }

    def elaboraDettaglio(def dettaglio, def attivita, def nomeFile, def doc, def tipoAttivita) {

        def documentoCreato = false

        def dett = DettaglioElaborazione.get(dettaglio)
        def att = AttivitaElaborazione.get(attivita)

        dett[decodificaAttivita(tipoAttivita)] = attivita
        dett.save(failOnError: true, flush: true)

        if (doc instanceof Exception) {
            // Si è verificato un errore, salvo l'errore ed elimino un eventuale vecchio documento
            if (doc.cause) {
                dett.note = doc?.cause?.message?.toString()?.take(1999)
            } else if (doc.message) {
                dett.note = doc.message.take(1999)
            }
            att.note = "Presenza di errori."
        } else {
            // Tutto ok, elimino l'eventuale presenza di errori di una vecchia elaborazione
            dett.note = null
            dett.nomeFile = nomeFile

            def pdfDoc = PDDocument.load(doc)
            dett.numPagine = pdfDoc.numberOfPages

            if (pdfDoc) {
                pdfDoc.close()
            }

            documentoCreato = true

        }

        def newDoc = dett.save(failOnError: true, flush: true)

        // Se è stato creato il documento si salva
        def dettDoc = null
        dettDoc = DettaglioElaborazioneDocumento.get(newDoc.id)
        if (documentoCreato) {
            dettDoc.documento = doc
        } else {
            dettDoc.documento = null
        }

        def execTime = commonService.timeMe {
            dettDoc.save(failOnError: true, flush: true)
        }
        log.info "[Salvataggio dettaglio] ${execTime}"
    }

    def cambiaStatoAttivita(def attivita, def stato, def note = null) {
        attivita = AttivitaElaborazione.get(attivita.id)

        log.info("Cambio stato attività [${attivita.id}] da [${attivita.statoAttivita.descrizione}] a [${stato.descrizione}]")

        attivita.statoAttivita = stato

        if (note) {
            attivita.note = note
        }

        attivita.save(failOnError: true, flush: true)
    }

    def correggiStatoAttivita(def attivita) {
        attivita = AttivitaElaborazione.get(attivita.id)
        if (attivita.statoAttivita.descrizione == STATO_ATTIVITA_ERRORE) {
            cambiaStatoAttivita(attivita, STATO_ATTIVITA_IN_CORSO)
        }
    }

    def sganciaAttivita(def dettaglio, def tipoAttivita) {
        def dett = DettaglioElaborazione.get(dettaglio)

        dett[decodificaAttivita(tipoAttivita)] = null

        dett.save(failOnError: true, flush: true)
    }

    /**
     * P: Pratiche				Nessun Ruolo, nessun Anno, dettagli hanno Pratica
     * R: Ruoli					Specificato ruolo, nessun Anno, dettagli senza Pratica
     * I: Imposta			    Nessun Ruolo, specificato Anno, dettagli possono avere pratica
     * AT: Anagrafe Tributaria  Nessun Ruolo, dettagli senza Pratica
     **/
    def tipoElaborazione(def elaborazioneId) {

        return ElaborazioneMassiva.get(elaborazioneId).tipoElaborazione.id
    }

    def tipoPraticaElaborazione(def elaborazione) {

        if (tipoElaborazione(elaborazione) == TIPO_ELABORAZIONE_PRATICHE) {
            return DettaglioElaborazione.findByElaborazione(ElaborazioneMassiva.get(elaborazione)).pratica.tipoPratica
        } else {
            null
        }

    }

    def mergePDF(def elaborazione, def outputFolder, def tipoLimete = null, def limite = null) {

        def logFile = new File("${outputFolder}/log.txt")

        def listaDettagli = listaDettagliDaElaborare(
                ElaborazioneMassiva.get(elaborazione),
                dettagliOrderBy
        )

        def liste = []
        def index = 0
        def totalActual = 0.0

        if (tipoLimete != 'NO') {

            switch (tipoLimete) {
                case "NUMP":
                    log.info "Impostato limite a ${limite} pagine."
                    logFile << "Impostato limite a ${limite} pagine.\n"
                    break
                case "DIM":
                    log.info "Impostato limite a ${limite}MB."
                    logFile << "Impostato limite a ${limite}MB.\n"
                    break
            }

            listaDettagli.each {

                def actualValue = (tipoLimete == 'NUMP' ? it.numPagine : (getDimensioneDocumenti([it.id])[it.id].dimensione / 1_000_000))

                if ((totalActual + actualValue) > limite) {
                    index++
                    totalActual = 0
                }

                if (liste[index] == null) {
                    liste[index] = []
                }

                liste[index] << it
                totalActual += actualValue

            }

        } else {
            liste[0] = listaDettagli
        }

        log.info "Verranno creati ${liste.size()} pdf."
        logFile << "Verranno creati ${liste.size()} pdf.\n"

        def nPdf = 1
        def mergedFiles = [:]
        liste.each {
            log.info "Inizio elaborazione lista ${nPdf} di ${liste.size()}."
            logFile << "Inizio elaborazione lista ${nPdf} di ${liste.size()}.\n"
            mergedFiles << [(_mergePDF(it, outputFolder)): it]
            log.info "Fine elaborazione lista ${nPdf} di ${liste.size()}."
            logFile << "Fine elaborazione lista ${nPdf} di ${liste.size()}.\n"
            nPdf++
        }

        return mergedFiles
    }

    private _mergePDF(def listaDettagli, def outputFolder) {

        def logFile = new File("${outputFolder}/log.txt")

        // Sort necessaria perchè PDF concatenati e righe csv devono essere nello stesso ordine
        def maxDocuments = 25
        def maxThreads = 10
        def index = 0
        ConcurrentHashMap mapDettagli = [:]
        ConcurrentHashMap mapMergedFile = [:]


        listaDettagli.collate(maxDocuments).each { mapDettagli << [(index++): it] }

        log.info "Estrazione pdf da DB..."
        logFile << "Estrazione pdf da DB...\n"
        GParsPool.withPool(maxThreads) {
            log.info "[mergePDF]: Avvio di ${mapDettagli.size()} processi."
            mapDettagli.eachParallel {
                def fileName = null
                def oldFileName = null
                int i = 0
                def listSize = it.value.size()
                def key = it.key
                it.value.each {

                    def now = System.currentTimeMillis()

                    def fileNameConcat = "${outputFolder}${UUID.randomUUID().toString()}.pdf"

                    def listaFiles = []
                    def documentoAttuale = DettaglioElaborazioneDocumento.get(it.id).documento

                    new File(fileNameConcat).withOutputStream {
                        it.write(documentoAttuale)
                    }

                    // Prima iterazione il file temporaneo è vuoto
                    if (fileName == null) {
                        listaFiles = [fileNameConcat]
                    } else {
                        oldFileName = fileName
                        listaFiles = [fileName, fileNameConcat]
                    }

                    fileName = modelliService.mergePdf(listaFiles, outputFolder)
                    new File(fileNameConcat).delete()
                    if (oldFileName != null) {
                        new File(oldFileName).delete()
                    }

                    def tempo = ((System.currentTimeMillis() - now) as BigDecimal) / 1000
                    log.info "[${key}]: Documento ${++i} di ${listSize} concatenato in ${tempo}s. File di destinazione ${fileName} [${new File(fileName).size() / 1024 / 1024}Mb]"
                    logFile << "[${key}]: Documento ${i} di ${listSize} concatenato in ${tempo}s. File di destinazione ${fileName} [${new File(fileName).size() / 1024 / 1024}Mb]\n"
                }
                mapMergedFile << [(it.key): (fileName)]
            }
        }
        log.info "Estrazione pdf da DB completata."
        logFile << "Estrazione pdf da DB completata.\n"

        log.info "Concatenamento file in singolo pdf..."
        logFile << "Concatenamento file in singolo pdf...\n"
        def mergedFileName = modelliService.mergePdf(mapMergedFile.sort { it.key }.values().toList(), outputFolder)
        log.info "Concatenamento file in singolo pdf completato."
        logFile << "Concatenamento file in singolo pdf completato.\n"

        log.info "Eliminazione dei file temporanei..."
        logFile << "Eliminazione dei file temporanei...\n"
        mapMergedFile.values().toList().each { new File(it).delete() }
        log.info "Eliminazione dei file temporanei completata."
        logFile << "Eliminazione dei file temporanei completata.\n"

        log.info "Operazione di concatenamento file conclusa, creato file ${mergedFileName}."
        logFile << "Operazione di concatenamento file conclusa, creato file ${mergedFileName}.\n"

        return mergedFileName
    }

    def inviaATipografia(def dettagli, def attivita, def cliente, def nomeFile, def outputFolder, def index) {

        def logFile = new File("${outputFolder}/log.txt")

        def att = AttivitaElaborazione.get(attivita)

        def docTrattati = 0

        def csvFile = new File("${outputFolder}${nomeFile}_${(index as String).padLeft(2, "0")}.csv")

        log.info "Salvataggio file CSV..."
        log.info "Creazione file: [${outputFolder}${nomeFile}_${index}.csv]"
        logFile << "Salvataggio file CSV...\n"
        logFile << "Creazione file: [${outputFolder}${nomeFile}_${index}.csv]\n"

        def execTime = commonService.timeMe {

            def maxElements = 100
            def maxThreads = 10
            ConcurrentHashMap mapDettagli = [:]
            ConcurrentHashMap mapDettagliElaborati = [:]
            def groupIndex = 0

            dettagli.collate(maxElements).each { mapDettagli << [(groupIndex++): it] }

            GParsPool.withPool(maxThreads) {

                mapDettagli.eachParallel { md ->
                    md.value.each {

                        // Non esiste il documento, non si inserisce la riga nel csv
                        if (it.numPagine != null) {
                            it.tipografiaId = attivita

                            def ce = null
                            DettaglioElaborazione.withTransaction { tx ->
                                ce = contribuentiService.contribuenteEnte(
                                        it.contribuente.codFiscale,
                                        att.elaborazione.tipoTributo.tipoTributo,
                                        it.eredeSoggetto?.soggettoEredeId?.id
                                )[0]
                                it.save(failOnError: true, flush: true)
                            }

                            def tipo = new Tipografia()
                            tipo.campo1 = cliente.amm.descrizione.replace(" ", "_").toUpperCase()
                            tipo.campo2 = ce["CAMPO_CSV"]
                            tipo.campo3 = ce["VIA_DEST"]
                            tipo.campo4 =
                                    (ce["NUM_CIV_DEST"] != null ? "${ce["NUM_CIV_DEST"]}" : '') +
                                            (ce["SUFFISSO_DEST"] != null ? "/${ce["SUFFISSO_DEST"]}" : '') +
                                            (ce["SCALA_DEST"] != null ? "/${ce["SCALA_DEST"]}" : '') +
                                            (ce["INTERNO_DEST"] != null ? "/${ce["INTERNO_DEST"]}" : '')
                            tipo.campo5 = ce["COMUNE_DEST"]
                            tipo.campo6 = ce["PROVINCIA_DEST"]
                            tipo.campo7 = ce["CAP_DEST"]?.trim() ?: ''
                            tipo.campo8 = ce["STATO_DEST"]?.trim() ?: ''
                            // Da 9 a 12 non utilizzati
                            tipo.campo13 = it.eredeSoggetto ? it.eredeSoggetto?.soggettoEredeId?.codFiscale : ce["COD_FISCALE"]
                            tipo.campo14 = it.numPagine // Si memorizza temporaneamente il numero di pagine
                            tipo.campo16 = "${nomeFile}_${(index as String).padLeft(2, "0")}.pdf"
                            tipo.campo17 = att.tipoSpedizione.tipoSpedizione

                            if (att.tipoSpedizione.tipoSpedizione in ['AR', 'AG']) {
                                def indirizzo = cliente.amministrazione.soggetto.indirizzoResidenza.split(',')
                                tipo.campo18 = "${cliente.amministrazione.soggetto.cognome} ${cliente.amministrazione.soggetto.nome ?: ''}"
                                tipo.campo19 = indirizzo[0]
                                tipo.campo20 = indirizzo[1]
                                tipo.campo21 = "${cliente.amministrazione.soggetto.cognome} ${cliente.amministrazione.soggetto.nome ?: ''}"
                                tipo.campo22 = cliente.amministrazione.soggetto.provinciaResidenza?.sigla
                                tipo.campo23 = cliente.amministrazione.soggetto.capResidenza
                            }

                            /**
                             * Campi personalizzati:
                             * - campo9: Feature 50166
                             */
                            if (it.pratica) {
                                tipo.campo9 = it.pratica.id
                            }

                            if (mapDettagliElaborati[md.key] == null) {
                                mapDettagliElaborati[md.key] = []
                            }

                            mapDettagliElaborati[md.key] << tipo

                        }

                        docTrattati++
                        if (docTrattati % 100 == 0) {
                            log.info "${new DecimalFormat("#.##").format((((docTrattati / dettagli.size()) * 100)))}% completato"
                            logFile << "${new DecimalFormat("#.##").format((((docTrattati / dettagli.size()) * 100)))}% completato\n"
                        }
                    }
                }
            }

            def pageIndex = 1
            mapDettagliElaborati.sort { it.key }.each {
                it.value.each { tipo ->

                    // Fuori dal multithreading si impostano pagina iniziale e finale
                    def numPages = tipo.campo14
                    tipo.campo14 = pageIndex
                    pageIndex += (numPages - 1)
                    tipo.campo15 = pageIndex++

                    def campi = tipo.properties.findAll { it.key.startsWith("campo") }
                            .sort { it.key.substring(5) as Integer }.values().collect { it ?: "" }.join(";")

                    csvFile.append("$campi\r\n")
                }
            }
        }

        log.info "Creazione file CSV completata in ${execTime}."
        logFile << "Creazione file CSV completata in ${execTime}.\n"

    }

    def allegaAvvisoAgidRuolo(def dettaglio, def attivitaId, def ruolo, def cf) {

        log.info "Elaborazione avviso AgID per dettaglio [${dettaglio.id}]"

        def docBlob = DettaglioElaborazioneDocumento.get(dettaglio.id)

        def docConAvviso = modelliService.generaAvvisiAgidRuolo(
                DettaglioElaborazioneDocumento.get(dettaglio.id).documento, ruolo, cf
        )

        allegaAvvisoAgid(docConAvviso, docBlob, attivitaId, dettaglio)
    }


    def allegaAvvisoAgidPratica(def dettaglio, def attivitaId, def idPratica) {

        log.info "Elaborazione avviso AgID per dettaglio [${dettaglio.id}]"

        def docBlob = DettaglioElaborazioneDocumento.get(dettaglio.id)

        def docConAvviso = modelliService.generaAvvisiAgidPratica(
                docBlob.documento, idPratica
        )

        allegaAvvisoAgid(docConAvviso, docBlob, attivitaId, dettaglio)
    }

    def allegaAvvisoAgidImposta(def dettaglio, def attivitaId, def cf, def anno, def tipoTributo, def gruppoTributo = null) {

        log.info "Elaborazione avviso AgID per dettaglio [${dettaglio.id}]"

        def docBlob = DettaglioElaborazioneDocumento.get(dettaglio.id)

        def docConAvviso = modelliService.generaAvvisiAgidImposte(
                docBlob.documento,
                cf, anno, tipoTributo, gruppoTributo
        )

        allegaAvvisoAgid(docConAvviso, docBlob, attivitaId, dettaglio)
    }

    private allegaAvvisoAgid(def documento, def docBlob, def attivitaId, def dettaglio) {

        if (documento instanceof String) {
            dettaglio.note = documento
        } else {
            def pdfDoc = PDDocument.load(documento)
            dettaglio.numPagine = pdfDoc.numberOfPages
            dettaglio.avvisoAgidId = attivitaId
            dettaglio.note = null
            docBlob.documento = documento
            pdfDoc.close()

            docBlob.save(failOnError: true, flush: true)
        }

        dettaglio.avvisoAgidId = attivitaId
        dettaglio.save(failOnError: true, flush: true)

        return documento
    }

    def chiudiElaborazioniPendenti() {
        log.info "Inizio verifica elaborazioni pendenti..."
        def attivitaInAttesa =
                AttivitaElaborazione.findAllByStatoAttivita(StatoAttivita.get(STATO_ATTIVITA_INSERITO))
                        .collect { it.id }
        def attivitaInCorso = AttivitaElaborazione
                .findAllByStatoAttivita(StatoAttivita.get(STATO_ATTIVITA_IN_CORSO))
                .collect { it.id }

        def errore = StatoAttivita.get(STATO_ATTIVITA_ERRORE)

        if (!attivitaInAttesa.isEmpty()) {

            attivitaInAttesa.collate(500).each {
                AttivitaElaborazione.executeUpdate(
                        """update AttivitaElaborazione set statoAttivita = :errore where id in :idAttivita""",
                        [errore: errore, idAttivita: it]
                )
            }

            log.info "Cambiato stato a ${attivitaInAttesa.size()} in attesa."
        }

        if (!attivitaInCorso.isEmpty()) {
            attivitaInCorso.collate(500).each {
                AttivitaElaborazione.executeUpdate(
                        """update AttivitaElaborazione set statoAttivita = :errore where id in :idAttivita""",
                        [errore: errore, idAttivita: it]
                )
            }
            log.info "Cambiato stato a ${attivitaInCorso.size()} in corso."
        }

        log.info "Fine verifica elaborazioni pendenti."
    }

    def utentiElaborazioni() {
        ElaborazioneMassiva.createCriteria().listDistinct {
            projections {
                groupProperty('utente')
            }

            order('utente')
        }
    }

    def attivitaElaborazione(def idElaborazione) {
        AttivitaElaborazione.createCriteria().list {
            projections {
                property('id')
                property('tipoAttivita')
                property('dataAttivita')
            }

            eq('elaborazione.id', idElaborazione)
            order('id', 'desc')
        }.collect {
            [
                    idAttivita : it[0],
                    descrizione: "${it[0]} - ${it[1].descrizione} (${it[2]?.format('dd/MM/yyyy HH:mm:ss')})"
            ]
        }
    }

    def logAttivita(def idAttivita) {
        // Al momento è gestita solo l'attività di tipo 2

        AttivitaElaborazione attivita = AttivitaElaborazione.get(idAttivita)
        def fileName = "${getDocFolder()}${File.separator}${attivita.id}${File.separator}/log.txt"

        new File(fileName).text

    }

    def getDimensioneDocumenti(def listaIdDettagli) {

        def sql = """
                    select deel.dettaglio_id, dbms_lob.getlength(deel.documento) dimensione
                        from dettagli_elaborazione deel
                    where deel.dettaglio_id in :pListaIdDettagli
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        sqlQuery.with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setParameterList('pListaIdDettagli', listaIdDettagli)
            list()
        }.collectEntries {
            [(it.dettaglioId as Long): [
                    dimensione      : it.dimensione,
                    dimensioneString: it.dimensione != null ? commonService.humanReadableSize(it.dimensione as Long) : ""
            ]
            ]
        }
    }

    def getDimensioneTotaleDocumenti(def idElaborazione, def soloSelezionati = false) {

        def sql = """
                    select sum(dbms_lob.getlength(deel.documento)) dimensione
                        from dettagli_elaborazione deel
                    where deel.elaborazione_id = :pIdElaborazione
                    ${soloSelezionati ? "and nvl(deel.flag_selezionato, 'N') = :pSelezionato" : ''}
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def dimensione = sqlQuery.with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setParameter('pIdElaborazione', idElaborazione)
            if (soloSelezionati) {
                setParameter('pSelezionato', 'S')
            }
            list()
        }[0].dimensione

        return dimensione as Long
    }

    def getDimensioneDocumentiMax(def idElaborazione) {
        def sql = """
                    select max(dbms_lob.getlength(deel.documento)) dimensione
                        from dettagli_elaborazione deel
                    where deel.elaborazione_id = :pIdElaborazione
                    and nvl(deel.flag_selezionato, 'N') = 'S'
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def dimensione = sqlQuery.with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setParameter('pIdElaborazione', idElaborazione)

            list()
        }[0].dimensione

        return dimensione as Long
    }

    def getPagineTotaleDocumenti(def idElaborazione, def soloSelezionati = false) {

        def sql = """
                    select sum(deel.num_pagine) pagine
                        from dettagli_elaborazione deel
                    where deel.elaborazione_id = :pIdElaborazione
                    ${soloSelezionati ? "and nvl(deel.flag_selezionato, 'N') = :pSelezionato" : ''}
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def pagine = sqlQuery.with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setParameter('pIdElaborazione', idElaborazione)
            if (soloSelezionati) {
                setParameter('pSelezionato', 'S')
            }
            list()
        }[0].pagine

        return pagine as Long
    }

    def getPagineDocumentiMax(def idElaborazione) {
        def sql = """
                    select max(deel.num_pagine) pagine
                        from dettagli_elaborazione deel
                    where deel.elaborazione_id = :pIdElaborazione
                    and nvl(deel.flag_selezionato, 'N') = 'S'
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def pagine = sqlQuery.with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setParameter('pIdElaborazione', idElaborazione)

            list()
        }[0].pagine

        return pagine as Long
    }

    private def _listaDettagli(def elaborazione, def params = null, def filtri = null, def sortBy = null) {

        params = params ?: [:]
        params.max = params.max ?: 20
        params.activePage = params.activePage ?: 0
        params.offset = params.activePage * params.max

        def elencoDettagli = DettaglioElaborazione.createCriteria().list(params) {

            createAlias("contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.LEFT_JOIN)

            eq('elaborazione', ElaborazioneMassiva.get(elaborazione))

            if (filtri?.nome) {
                ilike("sogg.nome", "${filtri.nome.toUpperCase()}%")
            }
            if (filtri?.cognome) {
                ilike("sogg.cognome", "${filtri.cognome.toUpperCase()}%")
            }
            if (filtri?.codFiscale) {
                ilike("cont.codFiscale", "${filtri.codFiscale.toUpperCase()}%")
            }

            if (filtri?.stampa && filtri.stampa != 'T') {
                filtri.stampa == 'S' ? isNotNull('stampaId') : isNull('stampaId')
            }
            if (filtri?.tipografia && filtri.tipografia != 'T') {
                filtri.tipografia == 'S' ? isNotNull('tipografiaId') : isNull('tipografiaId')
            }
            if (filtri?.documentale && filtri.documentale != 'T') {
                filtri.documentale == 'S' ? isNotNull('documentaleId') : isNull('documentaleId')
            }
            if (filtri?.agid && filtri.agid != 'T') {
                filtri.agid == 'S' ? isNotNull('avvisoAgidId') : isNull('avvisoAgidId')
            }
            if (filtri?.appio && filtri.appio != 'T') {
                filtri.appio == 'S' ? isNotNull('appioId') : isNull('appioId')
            }
            if (filtri?.esportaAT && filtri.esportaAT != 'T') {
                filtri.esportaAT == 'S' ? isNotNull('anagrId') : isNull('anagrId')
            }
            if (filtri?.controlloAT && filtri.controlloAT != 'T') {
                filtri.controlloAT == 'S' ? isNotNull('controlloAtId') : isNull('controlloAtId')
            }
            if (filtri?.allineamentoAT && filtri.allineamentoAT != 'T') {
                filtri.allineamentoAT == 'S' ? isNotNull('allineamentoAtId') : isNull('allineamentoAtId')
            }

            if (filtri?.presenzaErrori && filtri.presenzaErrori != 'T') {
                filtri.presenzaErrori == 'S' ? isNotNull('note') : isNull('note')
            }
            if (filtri?.selezionati && filtri.selezionati != 'T') {
                filtri.selezionati == 'S' ? isNotNull('flagSelezionato') : isNull('flagSelezionato')
            }
            if (filtri?.attivita) {
                or {
                    eq('stampaId', filtri?.attivita?.idAttivita)
                    eq('documentaleId', filtri?.attivita?.idAttivita)
                    eq('tipografiaId', filtri?.attivita?.idAttivita)
                    eq('avvisoAgidId', filtri?.attivita?.idAttivita)
                    eq('appioId', filtri?.attivita?.idAttivita)
                    eq('anagrId', filtri?.attivita?.idAttivita)
                    eq('controlloAtId', filtri?.attivita?.idAttivita)
                    eq('allineamentoAtId', filtri?.attivita?.idAttivita)
                }
            }

            if (sortBy) {
                sortBy.each {
                    order(it.property, it.direction)
                }
            }
        }

        return elencoDettagli
    }

    private cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }

    @NotTransactional
    private def decodificaAttivita(def tipoAttivita) {
        switch (tipoAttivita) {
            case TIPO_ATTIVITA.STAMPA:
                return "stampaId"
            case TIPO_ATTIVITA.TIPOGRAFIA:
                return "tipografiaId"
            case TIPO_ATTIVITA.DOCUMENTALE:
                return "documentaleId"
            case TIPO_ATTIVITA.AGID:
                return "avvisoAgidId"
            default:
                throw new RuntimeException("Tipologia ${tipoAttivita} non supportata.")
        }
    }

    def esisteRecordSamRisposte(def attivitaId) {

        def parametri = [:]

        parametri << ["attivita_id": attivitaId]

        def query = """
                    select count(*) num_risposte
                      from attivita_elaborazione atel,
                           sam_interrogazioni    sain,
                           sam_risposte          sari
                     where atel.attivita_id = sain.attivita_id
                       and sain.interrogazione = sari.interrogazione
                       and atel.attivita_id = :attivita_id
                    """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0].numRisposte > 0
    }

    def abilitaEliminaElaborazione(def idElaborazione) {
        return AttivitaElaborazione.createCriteria().count {
            createAlias('elaborazione', 'elab', CriteriaSpecification.INNER_JOIN)
            createAlias('statoAttivita', 'stat', CriteriaSpecification.INNER_JOIN)
            createAlias('tipoAttivita', 'tiat', CriteriaSpecification.INNER_JOIN)
            eq('elab.id', idElaborazione)
            or {
                ne('statoAttivita.id', 2 as Long)    // TERMINATA
                eq('tipoAttivita.id', TIPO_ATTIVITA_INVIO_A_DOCUMENTALE as Long)
            }
        } == 0
    }

    def recuperaTipoDocumentoDaElaborazione(def elaborazione) {
        switch (elaborazione.tipoElaborazione.id) {
            case TIPO_ELABORAZIONE_RUOLI:
                return 'S'
            case TIPO_ELABORAZIONE_IMPOSTA:
                return 'C'
            case TIPO_ELABORAZIONE_PRATICHE:
                return elaborazione.tipoPratica == 'S' ? 'T' : elaborazione.tipoPratica
            case TIPO_ELABORAZIONE_LETTERA_GENERICA:
                return 'G'
        }
    }

    def getPathToDocFolderByIdAttivita(def idAttivita) {
        return "${getDocFolder()}${File.separator}${idAttivita}${File.separator}"
    }

    def eliminaCartellaElaborazione(def pathToFolder) {
        def fileFolder = new File(pathToFolder)
        (new FileUtils()).deleteDirectory(fileFolder)
    }

    @Deprecated
    def getDettagliElaborazioneDocumento(def filter) {
        DettaglioElaborazioneDocumento.createCriteria().list {
            if (filter.dettaglioElaborazioneList && filter.dettaglioElaborazioneList.size() > 1) {
                inList('id', filter.dettaglioElaborazioneList.id)
            }
            if (filter.dettaglioElaborazione) {
                eq('id', filter.dettaglioElaborazione.id)
            }
        }
    }
}
