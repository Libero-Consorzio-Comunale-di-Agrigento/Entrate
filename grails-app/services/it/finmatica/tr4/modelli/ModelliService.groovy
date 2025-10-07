package it.finmatica.tr4.modelli

import com.aspose.words.*
import com.aspose.words.net.System.Data.DataTable
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.ParametriRateazione
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.ModelliDTO
import it.finmatica.tr4.dto.ModelliDettaglioDTO
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import oracle.jdbc.OracleTypes
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.zkoss.util.media.AMedia
import org.zkoss.zul.Filedownload
import transform.AliasToEntityCamelCaseMapResultTransformer

import javax.servlet.ServletContext
import java.math.RoundingMode
import java.util.List
import java.util.regex.Pattern

// 	Tipo B non supportato, alias con tipo 'S'
//	tr4_to_gdm.componi_nome_file

class ModelliService {

    private static final String TAG_AVVISO_AGID = "AVVISO_AGID_018e5aa0-3dce-70ed-8836-24ffc4a275a0"
    CommonService commonService
    F24Service f24Service
    JasperService jasperService
    IntegrazioneDePagService integrazioneDePagService
    ContribuentiService contribuentiService
    RateazioneService rateazioneService

    ServletContext servletContext
    def sessionFactory
    def springSecurityService

    def dataSource

    static final enum TipoStampa {
        PRATICA,
        ISTANZA_RATEAZIONE,
        LETTERA_GENERICA,
        COMUNICAZIONE,
        SGRAVIO
    }

    static final String TIPO_MODELLO_IST_TRASV = 'IST_TRASV%'
    static final String TIPO_MODELLO_SGRAVIO = 'SGR%'

    private final String SUB_MODEL_REGEX = "\\{SUB=(.*?)\\}"
    private final String SUFFISSO_SOTTOMODELLO_VUOTO = "_VUOTO"
    private final def NOT_EMPTY = "{NOT_EMPTY}"

    def determinaElaborazione(String tipoTributo, def praticaId, def codiceTributo) {

        Integer elaborazione

        if (praticaId > 0) {
            elaborazione = praticaId
        } else {
            elaborazione = integrazioneDePagService.determinaElaborazione(tipoTributo, praticaId, codiceTributo)
        }

        return elaborazione
    }

    def listaModelli(def descrizioneOrd) {
        Modelli.findAllByTipoModelloInListAndFlagSottomodelloIsNullAndFlagWeb(TipiModello.findAllByTipoModelloInList(descrizioneOrd), 'S', [sort: "descrizione"])
    }

    def caricaListaModelli(def params, def filtri, def sortBy = null) {

        params = params ?: [:]
        params.max = params.max ?: 10
        params.activePage = params.activePage ?: 0
        params.offset = params.activePage * params.max

        def lista = Modelli.createCriteria().list(params) {

            createAlias("tipoModello", "tm", CriteriaSpecification.INNER_JOIN)

            projections {
                property('id', 'id')
                property('tipoTributo', 'tipoTributo')
                property('descrizione', 'descrizione')
                property('flagSottomodello', 'flagSottoModello')
                property('flagEditabile', 'flagEditabile')
                property('flagStandard', 'flagStandard')
                property('flagEredi', 'flagEredi')
                property('codiceSottomodello', 'codiceSottomodello')
                property('tm.descrizione', 'tipoModello')
                property('dbFunction', 'dbFunction')
                property('tm.tipoPratica', 'tipoPratica')
            }

            eq("flagWeb", "S")

            // Se impostato il filto modelli o sottomodelli
            switch (filtri?.tipologia) {
                case null: // Nessun filtro
                    break
                case 'M': // Solo i modelli
                    isNull("flagSottomodello")
                    break
                case 'S': // Solo i sottomodelli
                    eq('flagSottomodello', 'S')
                    break
            }

            // Tributo
            if (filtri?.tipoTributo) {
                eq('tipoTributo', filtri.tipoTributo)
            }

            // desc ord
            if (filtri?.tipoModello) {
                eq('tipoModello.tipoModello', filtri.tipoModello)
            }

            // Ricerca di un particolare modello
            if (filtri.idModello) {
                eq('id', filtri.idModello)
            }

            // Ricerca per codice sottomodello
            if (filtri.codiceSottomodello) {
                ilike("codiceSottomodello", "${filtri.codiceSottomodello}%")
            }

            if (sortBy) {
                order(sortBy.property, sortBy.direction)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
        }

        def listaModelli = lista.collect { row ->

            def versioni = ModelliVersione.createCriteria().list {
                projections {
                    property('id', 'id')
                    property('versione', 'versione')
                    property('utente', 'utente')
                    property('dataVariazione', 'dataVariazione')
                    property('note', 'note')
                    property('documento', 'documento')
                }

                eq("modello.id", row.id)

                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            }.collect {
                [
                        note          : it.note,
                        versione      : it.versione,
                        utente        : it.utente,
                        dataVariazione: it.dataVariazione.format("dd/MM/yyyy"),
                        cancellabile  : it.versione > 0,
                        documento     : it.documento
                ]
            }

            [
                    id                : row.id,
                    tipoTributo       : row.tipoTributo,
                    descrizione       : row.descrizione,
                    flagSottomodello  : row.flagSottoModello == 'S',
                    flagEditabile     : row.flagEditabile == 'S',
                    flagStandard      : row.flagStandard == 'S',
                    flagEredi         : row.flagEredi == 'S',
                    codiceSottomodello: row.codiceSottomodello,
                    tipoModello       : row.tipoModello,
                    dbFunction        : row.dbFunction,
                    tipoPratica       : row.tipoPratica,
                    versioni          : versioni.sort { -it.versione },
                    estensione        : versioni != null && !versioni.isEmpty() ?
                            commonService.detectMimeType((versioni.sort { -it.versione })[0].documento).extensions[0] : ""

            ]
        }

        def listaModelliEstensione = []
        def filtroEstensione = ""

        if (filtri.estensione) {
            switch (filtri.estensione) {
                case "Tutti":
                    filtroEstensione = ""
                    break
                case "DOC":
                    filtroEstensione = ".doc"
                    break
                case "DOCX":
                    filtroEstensione = ".docx"
                    break
                case "ODT":
                    filtroEstensione = ".odt"
                    break
            }
        }


        //Filtro impostato su Tutti, nessun filtraggio ulteriore da eseguire
        if (filtroEstensione == "") {
            return [
                    record      : listaModelli,
                    numeroRecord: lista.totalCount
            ]
        }

        listaModelli.each {
            if (it.estensione == filtroEstensione) {
                listaModelliEstensione << it
            }
        }

        return [
                record      : listaModelliEstensione,
                numeroRecord: listaModelliEstensione.size()
        ]

    }

    def eliminaModello(def modello) {

        def modelliPadre = []

        // Se sottomodello si verifica che non sia utilizzato in altri modelli/sottomodelli
        if (modello.flagSottomodello) {

            Modelli.findAllByModelloNotEqual(modello.id).each { mod ->
                def ultimaVersione = mod.versioni.max { ver -> ver.versione }
                if (ultimaVersione && ultimaVersione.documento) {
                    subModels(ModelliCommons.fileBytesToDoc(ultimaVersione.documento)).modello.each {
                        if (it == modello.codiceSottomodello) {
                            modelliPadre << mod.descrizione
                        }
                    }
                }
            }
        }

        if (modelliPadre.isEmpty()) {
            Modelli.get(modello.id).delete(failOnError: true, flush: true)
            return null
        } else {
            return modelliPadre
        }
    }

    def caricaModello(def modello, def file, def note) {

        ModelliVersione nuovaVersione = new ModelliVersione()
        if (modello instanceof ModelliDTO) {
            nuovaVersione.modello = modello.toDomain()
        } else {
            nuovaVersione.modello = modello
        }
        nuovaVersione.documento = file
        nuovaVersione.note = note
        nuovaVersione.versione = nuovaVersioneModello(modello)
        nuovaVersione.save(flush: true, failOnError: true)
        return [
                note          : nuovaVersione.note,
                versione      : nuovaVersione.versione,
                utente        : nuovaVersione.utente,
                dataVariazione: nuovaVersione.dataVariazione.format("dd/MM/yyyy"),
                cancellabile  : nuovaVersione.versione > 0
        ]
    }

    def creaModello(def modello, def file, def note, def dettagli) {
        modello = modello.toDomain().save(flush: true, failOnError: true)

        caricaModello(modello.toDTO(["tipoModello"]), file, note)

        dettagli?.each {
            (new ModelliDettaglio([
                    modello    : modello.modello,
                    testo      : it.testo,
                    parametroId: it.parametroId
            ])).save(flush: true, failOnError: true)
        }
    }

    def eliminaVersione(def modello, def versione) {
        ModelliVersione.findByModelloAndVersione(modello, versione)?.delete(flush: true, failOnerror: true)
    }

    def duplicaModello(def modello) {
        def nuovoModello = modello.toDomain()
        def versione = modello.versioni[0]?.toDomain()
        nuovoModello = nuovoModello.save(flush: true, failOnError: true)

        if (versione) {
            versione.modello = nuovoModello
            versione.save(flush: true, failOnError: true)
        }
        return nuovoModello
    }

    def caricaListaParametri(def params, def filtri, def sortBy = null) {

        params = params ?: [:]
        params.max = params.max ?: 10
        params.activePage = params.activePage ?: 0
        params.offset = params.activePage * params.max

        def lista = TipiModelloParametri.createCriteria().list(params) {

            projections {
                property('parametroId', 'id')
                property('tipoModello', 'tipoModello')
                property('parametro', 'parametro')
                property('descrizione', 'descrizione')
                property('lunghezzaMax', 'lunghezzaMax')
                property('testoPredefinito', 'testoPredefinito')
            }

            // desc ord
            if (filtri?.tipoModello) {
                eq('tipoModello', filtri.tipoModello)
            }

            if (sortBy) {
                order(sortBy.property, sortBy.direction)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
        }

        def dettagli = []

        if (filtri.idModello) {
            dettagli = ModelliDettaglio.findAllByModello(filtri.idModello)
        }

        def listaParametri = lista.collect { row ->
            def dettaglio = dettagli?.find {
                it.parametroId == row.id
            }?.toDTO() ?: new ModelliDettaglioDTO()

            [
                    id              : row.id,
                    tipoModello     : row.tipoModello,
                    parametro       : row.parametro,
                    descrizione     : row.descrizione,
                    lunghezzaMax    : row.lunghezzaMax,
                    testoPredefinito: row.testoPredefinito,
                    dettaglio       : dettaglio
            ]
        }

        return [
                record      : listaParametri,
                numeroRecord: lista.totalCount
        ]
    }

    private def nuovaVersioneModello(def modello) {
        if (modello instanceof Modelli) {
            modello = modello.refresh()
        }
        def ultimaVersione = modello?.versioni?.max { it.versione }?.versione
        if (ultimaVersione != null) {
            return ++ultimaVersione
        } else {
            return 0
        }
    }

    def scaricaCampiUnione(def modello) {
        DataTable dt = eseguiFunzione("${modello.dbFunction}()")
        def numCols = dt.columnsCount

        def columns = [:]
        (0..numCols - 1).each {
            columns << [(dt.getColumnName(it)): '']
        }

        def campi = ""

        // Intestazioni
        campi = columns.sort { it.key }.keySet().join(';')
        campi += ("\n" + (columns.values().join(';')))
        return campi
    }

    // Stampa il modello
    def stampaModello(def params) {

        try {

            def strParams = ""
            def idDocumento = null
            def tipoDocumento = null
            Short annoDocumento = 0

            String tipo = (params.TIPO) ? params.TIPO as String : ''
            String tipoTributo = (params.TIPO_TRIBUTO) ? params.TIPO_TRIBUTO as String : 'CUNI'
            params.dovutoVersato = params.dovutoVersato ?: ''

            if (tipoTributo == 'TRASV') {
                // Tributo Trasversale
                strParams = "(${params.PRATICA})"
                idDocumento = params.PRATICA
                tipoDocumento = 'I'
            } else if (tipo == 'GEN%') {
                // Lettera generica
                strParams = "(${params.NI},'${params.TIPO_TRIBUTO}')"
                tipoDocumento = 'G'
            } else if (tipo == "COM_TARSU%") {
                // Avviso di pagamento TARSU
                strParams = "(-1,'','${params.CF}',${params.RUOLO},${params.MODELLO})"
                idDocumento = params.RUOLO
                tipoDocumento = 'S'
            } else if (tipo in ['DETA%', 'VAR_TARSU%', 'CES_TARSU%']) {
                // Denuncia TARSU
                strParams = "('${params.CF}',${params.PRATICA},${params.MODELLO})"
            } else if (tipo in ['COM_ICI%', 'COM_TASI%']) {
                // Comunicazione ICI e TASI
                strParams = "('${tipoTributo}','${params.CF}','${params.ANNO}','${params.dovutoVersato}',${params.MODELLO})"
                tipoDocumento = 'C'
            } else if (tipo.startsWith("COM_")) {
                // Bollettazione
                if (tipoTributo == 'CUNI') {
                    String gruppoTributo = params.GRUPPO_TRIBUTO ? "'${params.GRUPPO_TRIBUTO}'" : "null"
                    strParams = "(-1,'${tipoTributo}','${params.CF}',${params.RUOLO},${params.MODELLO},${params.ANNO},${params.PRATICA},${gruppoTributo})"
                } else {
                    strParams = "(-1,'${tipoTributo}','${params.CF}',${params.RUOLO},${params.MODELLO},${params.ANNO},${params.PRATICA})"
                }
                annoDocumento = params.ANNO
                idDocumento = params.PRATICA
                tipoDocumento = 'B'
            } else if (tipo == 'SGR%') {
                strParams = "('${tipoTributo}',${params.TRIBUTO},${params.OGGETTO},'${params.CF}',${params.SEQUENZA},${params.SEQUENZA_SGRAVIO},${params.RUOLO},${params.PRATICA},${params.PROGR_SGRAVIO},${params.MODELLO},${params.ANNO})"
                tipoDocumento = 'SGR'
            } else {
                // Pratiche
                if (tipo in ["ACC_CUNI%", "ACC_ICP%", "ACC_TOSAP%"]) {
                    strParams = "(${params.PRATICA},${params.MODELLO}${params.niErede ? ',' + params.niErede : ''})"
                } else if (tipo == "SOL_CUNI%") {
                    strParams = "(${params.PRATICA},${params.MODELLO})"
                } else {
                    if (tipoTributo != 'TARSU') {
                        if (PraticaTributo.get(params.PRATICA)?.tipoPratica == 'L') {
                            strParams = "('${params.CF}',(${params.PRATICA}),${params.MODELLO},${params.MODELLO_RIMB ? params.MODELLO_RIMB : '-1'},${params.niErede ? params.niErede : '-1'})"
                        } else {
                            strParams = "('${params.CF}',(${params.PRATICA}),${params.MODELLO}"
                            if (params.niErede != null) {
                                strParams += ",${params.niErede})"
                            } else {
                                strParams += ")"
                            }
                        }
                    } else {
                        strParams = "('${params.CF}',(${params.PRATICA}),${params.MODELLO}${params.niErede ? ',' + params.niErede : ''})"
                    }
                }

                idDocumento = params.PRATICA
                def tipoPratica = PraticaTributo.get(idDocumento)?.tipoPratica ?: 'D'

                // Nel caso di sollecito il tipoDocumento è T
                tipoDocumento = tipoPratica == 'S' ? 'T' : tipoPratica
            }
            def modello = Modelli.get(params.MODELLO).toDTO(["versioni"])
            def versione = modello.versioni.max { it.versione }

            if (!versione) {
                throw new ModelliException("NO_VERSION_AVALAIBLE", new Throwable("Nessuna versione disponibile per il modello ${modello.descrizione}."))
            }

            def fileBytes = versione.documento

            if (modello.dbFunction) {
                log.info "Generazione modello ${modello.modello} - ${modello.descrizione}"
                fileBytes = popolaModelloConDati(fileBytes, "${modello.dbFunction}${strParams}", false).modello
            }

            def docFinale = null

            def execTime = commonService.timeMe {
                docFinale = elaboraSottomodelli(fileBytes)
            }

            log.info "[Elaborazione modelli] ${execTime}"

            docFinale = eliminaRigheVuote(docFinale)

            docFinale = annullaTags(docFinale, [NOT_EMPTY])

            // Conversione e normalizzazione del documento nel formato finale, prima di concatenare eventuali allegati.
            // La conversione, se richiesta, in pdf va fatta prima di gestire gli allegati perché il numero
            // di pagine potrebbe cambiare.
            docFinale =
                    ModelliCommons.finalizzaPagineDocumento(
                            ModelliCommons.fileDocToBytes(
                                    ModelliCommons.fileBytesToDoc(docFinale), params.FORMAT
                            )
                    )

            // E' richiesto di allegare il/i modelli F24
            if (params.allegaF24) {
                if (tipo in ['COM_ICI%', 'COM_TASI%']) {
                    docFinale = allegaF24ComunicazioneImuTasi(docFinale, params.ANNO, params.TIPO_TRIBUTO, params.CF, params.tipiF24)
                } else if ((params.PRATICA ?: -1) != -1) {
                    docFinale = allegaF24Pratica(docFinale, params.PRATICA, params.tipoF24, params.ridotto)
                } else if (params.RUOLO != null) {
                    def rataUnica = stampaF24RataUnica(params.MODELLO)
                    docFinale = allegaF24Ruolo(docFinale, params.RUOLO, params.CF, rataUnica)
                } else {
                    log.info "F24 non supportato."
                }

            } else {
                if (params.allegaAvvisoAgID) {
                    if ((params.RUOLO ?: -1) != -1) {
                        docFinale = generaAvvisiAgidRuolo(docFinale, idDocumento as Long, params.CF)
                    } else if ((params.PRATICA ?: -1) != -1) {
                        docFinale = generaAvvisiAgidPratica(docFinale, params.PRATICA)
                    } else {
                        docFinale = generaAvvisiAgidImposte(docFinale, params.CF, params.ANNO, params.TIPO_TRIBUTO, params.GRUPPO_TRIBUTO)
                    }
                }
            }

            if (params?.allegaPianoRateizzazione) {
                docFinale = allegaPianoRateizzazione(docFinale, params.PRATICA)
            }

            if (params.salvaDocumentoContribuente) {
                if (!params.nomeFile?.toString()?.trim()) {
                    throw new ModelliException("E' stato richiesto il salvataggio nella documenti_contribuente: specificare il parametro nomeFile")
                }

                if (!params.CF?.trim()) {
                    throw new ModelliException("Specificare il codice fiscale del contribuente")
                }

                def anno = 0
                if (tipoDocumento == 'S') {
                    anno = Ruolo.get(idDocumento).annoRuolo
                }
                if (tipoDocumento == 'B') {
                    anno = annoDocumento
                }

                def docContr = new DocumentoContribuente()
                docContr.contribuente = Contribuente.findByCodFiscale(params.CF)
                docContr.documento = docFinale
                docContr.titolo = params.TITOLO ?: creaTitolo(idDocumento, tipoDocumento)
                docContr.nomeFile = params.nomeFile

                docContr.nomeFile += commonService.detectMimeType(docFinale).extension

                contribuentiService.caricaDocumento(docContr)
            }

            return docFinale
        } catch (Exception e) {
            if (e instanceof ModelliException) {
                throw (e as ModelliException)
            }
            e.printStackTrace()
            throw new Application20999Error("Errore durante l'elaborazione del documento")
        }
    }

    def fileBytesToDoc(def fileBytes) {

        return new Document(new ByteArrayInputStream(fileBytes))
    }

    def fileDocToBytes(def doc, def format = outputFormat()) {

        ByteArrayOutputStream docOutStream = new ByteArrayOutputStream()
        if (format == SaveFormat.PDF) {
            PdfSaveOptions pdfOptions = new PdfSaveOptions()
            pdfOptions.textCompression = PdfTextCompression.FLATE
            pdfOptions.jpegQuality = 60
            doc.save(docOutStream, pdfOptions)
        } else {
            doc.save(docOutStream, format)
        }

        return docOutStream.toByteArray()
    }

    def generaPrototipo(def modello) {
        DataTable dt = eseguiFunzione("${modello.dbFunction}()")
        def numCols = dt.columnsCount

        Document doc = new Document()
        DocumentBuilder builder = new DocumentBuilder(doc)

        Table table = builder.startTable()

        (0..numCols - 1).each {
            builder.insertCell()
            builder.write(dt.getColumnName(it))
            builder.insertCell()
            builder.insertField(" MERGEFIELD ${dt.getColumnName(it)}")
            builder.endRow()
        }

        builder.endTable()

        return ModelliCommons.fileDocToBytes(doc, SaveFormat.DOCX)
    }

    def generaAvvisiAgidRuolo(def doc, Long ruoloId, String cf) {

        return generaAvvisiAgid(doc, integrazioneDePagService.determinaDovutiRuolo(cf, ruoloId))
    }

    def generaAvvisiAgidPratica(def doc, def idPratica) {

        return generaAvvisiAgid(doc,
                integrazioneDePagService.determinaDovutiPratica(idPratica)
        )
    }

    def generaAvvisiAgidPratica(def idPratica) {

        return generaAvvisiAgid(null,
                integrazioneDePagService.determinaDovutiPratica(idPratica)
        )
    }

    def generaAvvisiAgidImposte(def doc, def cf, def anno, def tipoTributo, def gruppoTributo = null) {

        return generaAvvisiAgid(doc,
                integrazioneDePagService.determinaDovutiImposta(cf, anno, tipoTributo, null, 'NP', gruppoTributo)
        )
    }

    def separaAttoAvviso(def doc) {
        if (ModelliCommons.detectType(doc).extension != '.pdf') {
            throw new IllegalArgumentException("Formato documento non supportato")
        }

        def splits = (new PDFTools(doc)).split(TAG_AVVISO_AGID)

        def result = [stampa: splits[0]]
        if (splits.size() > 1) {
            result << [avvisoAgid: splits[1]]
        }

        return result
    }

    def setFlagEredi(def idModello, boolean valore) {

        def modello = Modelli.get(idModello)
        modello.flagEredi = valore ? 'S' : null
        modello.save(failOnError: true, flush: true)
    }

    private def generaAvvisiAgid(def doc, def records) {

        if (records.empty) {
            return "Errore nel recupero dei dovuti."
        }

        def errorMessage = ""
        def docCoAvvisoAgID = null

        // Se non sono rate di una pratica rateizzata
        // Se è presente si stampa la sola rata 0
        // Caso di pratica non rateizzata e rata 0: TARSU20240000000082MRTMRC67A09F205I0-1
        // Caso di pratica rateizzata: ICI   LIQP20230000542905CMPNMR55S67A068R01
        if (!(records.findAll { it.IDBACK ==~ /.*[A-Z\s]0(-[0-9])?$/ }.empty)) {
            records = records.findAll { it.IDBACK ==~ /.*0(-[0-9])?$/ }
        }

        records.each {

            docCoAvvisoAgID = allegaAvvisoAgid(doc, it.SERVIZIO, it.IDBACK)

            if (docCoAvvisoAgID instanceof String) {
                errorMessage += "${docCoAvvisoAgID}\n"
            } else {
                doc = docCoAvvisoAgID
            }
        }

        if (!errorMessage.empty) {
            log.info errorMessage
        }

        return docCoAvvisoAgID
    }

    private allegaAvvisoAgid(def doc, def servizio, def chiave) {

        // Se il documento è nullo si generano solo gli avvisi AgID in formato PDF
        if (doc == null) {
            doc = ModelliCommons.creaPDFVuoto()
        }

        def avvisoAgid = null
        def docConAvviso = null

        def execTime = commonService.timeMe {
            avvisoAgid = integrazioneDePagService.generaAvviso(chiave, servizio)

            // In caso di presenza di errore
            if (avvisoAgid instanceof String) {
                log.info "Errore: ${avvisoAgid}"
                docConAvviso = avvisoAgid
            } else {
                // Abbiamo il pdf
                def execTime1 = commonService.timeMe {
                    docConAvviso = ModelliCommons.allegaDocumentoPdf(doc, avvisoAgid, true, TAG_AVVISO_AGID)
                }

                log.info "[Concatenamento avviso AGID] ${execTime1}"

            }
        }
        log.info "[Recupero avviso AGID] ${execTime}"

        return docConAvviso
    }

    private def elaboraSottomodelli(def fileBytes) {

        def docPadre = fileBytes

        def sottoModelli = subModels(ModelliCommons.fileBytesToDoc(fileBytes))

        sottoModelli.each {

            log.info "Sottomodello : ${it}"

            def modello = Modelli.findByCodiceSottomodello(it.modello.trim())?.toDTO(["versioni"])
            if (!modello) {
                throw new ModelliException("MOD_NOT_EXISTS", new Throwable("Il sottomodello '${it.modello}' non esiste."))
            }

            def versione = modello.versioni.max { it.versione }

            def sottoModellofileBytes = versione.documento

            def unione = [:]
            if (modello.dbFunction) {
                log.info "Generazione modello ${modello.modello} - ${modello.descrizione}"
                unione = popolaModelloConDati(sottoModellofileBytes, "${modello.dbFunction}${it.parametri}")
                //sottoModellofileBytes = unione.modello
                sottoModellofileBytes = gestioneTabelle(unione.modello)
            }

            def sottomodello
            if (!unione.vuoto) {
                sottomodello = elaboraSottomodelli(sottoModellofileBytes)
            }

            // Dopo l'elaborazione si gestiscono i tag di documento alternativo utilizzato se non sono disponibili dati.
            if (modello.dbFunction) {
                if (!unione.vuoto) {
                    docPadre = annullaTags(docPadre, [it.tag.replace("(", SUFFISSO_SOTTOMODELLO_VUOTO + "(")])
                } else {
                    docPadre = annullaTags(docPadre, [it.tag.replace(SUFFISSO_SOTTOMODELLO_VUOTO, "")])
                }
            }

            if (!unione.vuoto) {
                docPadre = includiSottomodello(sottomodello, docPadre, it.tag)
            }
        }

        return docPadre
    }

    private def popolaModelloConDati(def fileBytes, def funzione, def sottomodello = true) {

        Document doc = ModelliCommons.fileBytesToDoc(fileBytes)

        PageSetup docPs = new DocumentBuilder(doc).pageSetup

        DataTable dt = eseguiFunzione(funzione)

        doc.getMailMerge().execute(dt)

        /*
         Nel caso di tabelle, compatta le diverse righe dopo la stampa unione
         che altrimenti sarebbero disposte su più pagine.
         Si applica solo ai sottomodelli, altrimenti eliminerebbe eventuali
         header/footer inseriti in pagina.
         */
        if (sottomodello) {
            Document newDoc = new Document()
            DocumentBuilder builder = new DocumentBuilder(newDoc)
            PageSetup newDocPs = builder.pageSetup
            newDocPs.pageHeight = docPs.pageHeight
            newDocPs.pageWidth = docPs.pageWidth
            newDocPs.leftMargin = docPs.leftMargin
            newDocPs.rightMargin = docPs.rightMargin

            def uuid = UUID.randomUUID().toString()
            builder.write(uuid)
            putDocument(newDoc, doc, uuid)
            doc = newDoc
        }

        return [modello: ModelliCommons.fileDocToBytes(doc), vuoto: dt.getRows().count == 0]
    }

    private def eseguiFunzione(String funzione) {

        def sqlCall =
                """DECLARE
						BEGIN
							? := $funzione;
				END;"""

        log.info """ESECUZIONE
			.........................................................................
                   $sqlCall
                   ........................................................................."""

        Sql sql = new Sql(dataSource)

        DataTable dt = null

        def execTime = commonService.timeMe {
            sql.call(sqlCall, [Sql.resultSet((OracleTypes.CURSOR))]) {
                dt = new DataTable(it, "DUAL")
            }
        }
        log.info "[Esecuzione function] ${execTime}"

        return dt
    }

    private def includiSottomodello(def sorgente, def destinazione, def tag) {

        // Per evitare che FinmaticaMailMerge.putDocument effettui match multipli su tag complessi,
        // si sostituisce il tag con un uuid.

        def uuid = UUID.randomUUID().toString()

        Document doc = ModelliCommons.fileBytesToDoc(destinazione)
        FindReplaceOptions options = new FindReplaceOptions()
        doc.getRange().replace(tag, uuid, options)
        destinazione = putDocument(doc, ModelliCommons.fileBytesToDoc(sorgente), uuid)

        return ModelliCommons.fileDocToBytes(destinazione)
    }

    private def putDocument(destinazione, sorgente, uuid) {

        FindReplaceOptions options = new FindReplaceOptions()
        options.ReplacingCallback = new ReplaceSubModel(sorgente)

        destinazione.getRange().replace(uuid, "", options)

        return destinazione
    }

    private eliminaRigheVuote(def sorgente) {

        Document doc = ModelliCommons.fileBytesToDoc(sorgente)
        FindReplaceOptions options = new FindReplaceOptions()
        options.ReplacingCallback = new ReplaceBlankLine()

        doc.getRange().replace(NOT_EMPTY, "", options)

        return ModelliCommons.fileDocToBytes(doc)
    }

    private def annullaTags(def sorgente, def tags) {

        Document doc = ModelliCommons.fileBytesToDoc(sorgente)
        FindReplaceOptions options = new FindReplaceOptions()

        tags.each {
            doc.getRange().replace(it, "", options)
        }

        return ModelliCommons.fileDocToBytes(doc)
    }

    private def subModels(Document doc) {

        def subModels = []

        FindReplaceOptions options = new FindReplaceOptions()
        options.ReplacingCallback = new ReplaceEvaluatorFind(subModels)

        Pattern regex = Pattern.compile(SUB_MODEL_REGEX)

        doc.getRange().replace(regex, "", options)

        return subModels.collect { scomponiSottomodello(it) }
    }

    private def scomponiSottomodello(def sottomodello) {
        return [
                tag      : sottomodello,
                modello  : (sottomodello =~ /SUB=(.*?)\(/)[0][1],
                parametri: (sottomodello =~ /\((.*?)\)/)[0][0].toString()
                        .replace("‘", '\'')
                        .replace("’", "\'")
        ]
    }

    private gestioneTabelle(def doc) {

        final def TABLE_HEADER = "{HEADER}"
        final def TABLE_FOOTER = "{FOOTER}"

        def newDoc = ModelliCommons.fileBytesToDoc(doc)
        newDoc.getChildNodes(NodeType.TABLE, true).each { tab ->

            def firstRow = 0
            def lastRow = tab.rows.count - 1

            for (i in (0..(tab.rows.count - 1))) {
                if (tab.rows.get(i).firstCell.text.contains(TABLE_HEADER)) {
                    firstRow++
                } else {
                    break
                }
            }

            for (i in ((tab.rows.count - 1)..0)) {
                if (tab.rows.get(i).firstCell.text.contains(TABLE_FOOTER)) {
                    lastRow--
                } else {
                    break
                }
            }

            def rowIndex = 0
            tab.getRows().each { row ->

                // Eliminazione hedar e footer ripetuti
                if ((row.firstCell.text.contains(TABLE_HEADER)
                        || row.firstCell.text.contains(TABLE_FOOTER))
                        && rowIndex in (firstRow..lastRow)) {
                    row.remove()
                } else if (row.firstCell.text.contains(NOT_EMPTY)) {
                    // Eliminazione delle righe vuote se richiesto
                    def isEmpty = true
                    row.cells.each {
                        if (!(it.text - NOT_EMPTY - TABLE_FOOTER - TABLE_HEADER - "\n" - "\r" - "\t" - "\u0007").isEmpty()) {
                            isEmpty = false
                        }
                    }
                    if (isEmpty) {
                        row.remove()
                    }
                }

                rowIndex++
            }
        }

        return annullaTags(ModelliCommons.fileDocToBytes(newDoc), [TABLE_HEADER, TABLE_FOOTER])
    }

    private def allegaF24Pratica(def doc, def pratica, def tipoF24 = null, def ridotto = null) {
        // Creazione del documento contente l'F24
        List f24data

        def execTime = commonService.timeMe {

            def prtr = PraticaTributo.get(pratica)

            if (ridotto != 'TUTTI') {
                f24data = f24Service.caricaDatiF24(prtr, tipoF24 ?: 'V', ridotto == 'SI')
            } else {

                def f24Ridotto = f24Service.caricaDatiF24(prtr, tipoF24 ?: 'V', true)
                def f24NonRidotto = f24Service.caricaDatiF24(prtr, tipoF24 ?: 'V', false)

                f24Ridotto << f24NonRidotto[0]

                f24data = f24Ridotto
            }


        }
        log.info "[Caricamento dati F24] ${execTime}"

        return allegaF24(doc, f24data)
    }

    private def allegaF24Ruolo(def doc, def ruolo, def codFiscale, String rataUnica = 'SI', def tipo = 'COMPLETO') {
        // Creazione del documento contente l'F24
        List f24data = null
        def execTime = commonService.timeMe {
            f24data = f24Service.caricaDatiF24(codFiscale, ruolo, tipo, rataUnica)
        }
        log.info "[Caricamento dati F24] ${execTime}"


        return allegaF24(doc, f24data)

    }

    private def allegaF24ComunicazioneImuTasi(def doc, def anno, def tipoTributo, def codFiscale, def tipiF24) {

        def parametriTipiVersamento = [
                ACCONTO      : [
                        tipoVersamento: 'A',
                        dovutoVersato : ''
                ],
                SALDO_DOVUTO : [
                        tipoVersamento: 'S',
                        dovutoVersato : 'D'
                ],
                SALDO_VERSATO: [
                        tipoVersamento: 'S',
                        dovutoVersato : 'V'
                ],
                UNICO        : [
                        tipoVersamento: 'U',
                        dovutoVersato : ''
                ]
        ]

        if (tipiF24.findAll { k, v -> v }.isEmpty()) {
            return doc
        }

        def tipi = []

        if (tipiF24.unico) {
            tipi << 'UNICO'
        } else {
            if (tipiF24.acconto) {
                tipi << 'ACCONTO'
            }

            if (tipiF24.saldoDovuto) {
                tipi << 'SALDO_DOVUTO'
            }

            if (tipiF24.saldoVersato) {
                tipi << 'SALDO_VERSATO'
            }
        }

        tipi.each {
            List f24data = f24Service.caricaDatiF24(
                    anno as short,
                    tipoTributo,
                    codFiscale,
                    parametriTipiVersamento[it].tipoVersamento,
                    parametriTipiVersamento[it].dovutoVersato
            )

            doc = ModelliCommons.finalizzaPagineDocumento(allegaF24(doc, f24data))
        }

        return doc

    }

    private def allegaF24(def doc, def f24Data) {
        def f24 = null
        def execTime = commonService.timeMe {
            f24 = ModelliCommons.allegaDocumentoPdf(doc, generaF24(f24Data).toByteArray(), true)
        }
        log.info "[Concatenamento F24] ${execTime}"

        f24 = ModelliCommons.finalizzaPagineDocumento(f24)

        return f24

    }

    private def allegaPianoRateizzazione(def doc, def praticaId) {

        def piano = null
        def execTime = commonService.timeMe {
            doc = ModelliCommons.finalizzaPagineDocumento(doc)
            piano = ModelliCommons.allegaDocumentoPdf(doc, jasperService.generateReport(generaPianoRateizzazione(praticaId, null)).toByteArray())
        }
        log.info "[Concatenamento Piano Rateizzazione] ${execTime}"

        piano = ModelliCommons.finalizzaPagineDocumento(piano)

        return piano
    }

    def generaPianoRateizzazione(def praticaId, ParametriRateazione params = null) {

        ParametriRateazione parametriRateazione

        def pratica = PraticaTributo.findById(praticaId)

        if (params != null) {
            parametriRateazione = params
        } else {
            parametriRateazione = new ParametriRateazione()
            popolaRateazione(pratica, parametriRateazione)
        }


        def pianoRimborso = rateazioneService.pianoRimborso(praticaId)


        def listaTributiF24Capitale = rateazioneService.listaTributiF24(
                pratica.tipoTributo.tipoTributo,
                pratica.tipoTributo.getTipoTributoAttuale(pratica.anno),
                'S'
        )

        // Per la stampa dei vecchi modelli (== null) viene visualizzato solo il codice, quindi niente da fare
        // Invece se si tratta dei nuovi modelli (!= null) bisogna visualizzare sia il codice che la descrizione
        if (parametriRateazione.calcoloRate != null) {
            pianoRimborso[0].rate.each { rata ->
                // Imposto la descrizione del tributo
                rata.tributoCapitaleF24 = listaTributiF24Capitale.find {
                    it.key == rata.tributoCapitaleF24
                }?.value
            }
        }

        JasperReportDef reportDef = new JasperReportDef(name: 'pianoRimborso.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: pianoRimborso
                , parameters: [SUBREPORT_DIR      : servletContext.getRealPath('/reports') + "/",
                               CALCOLO_RATE       : parametriRateazione.calcoloRate,
                               INT_RATE_SOLO_ESAVA: parametriRateazione.intRateSoloEvasa])

        return reportDef
    }

    private def popolaRateazione(def pratica, def parametriRateazione) {

        def totImportoCalcolato = 0

        def sanzioniNow = pratica.sanzioniPratica

        for (sp in sanzioniNow) {
            totImportoCalcolato += sp.importoLordo
        }

        totImportoCalcolato = totImportoCalcolato.setScale(2, RoundingMode.HALF_UP)

        parametriRateazione.importoPratica = pratica.tipoTributo.tipoTributo == 'TARSU' ? totImportoCalcolato : pratica.importoTotale
        parametriRateazione.versatoPreRateazione = pratica.versatoPreRate
        parametriRateazione.dataRateazione = pratica.dataRateazione
        parametriRateazione.interessiMora = pratica.mora
        parametriRateazione.numeroRata = pratica.numRata
        parametriRateazione.tipologia = pratica.tipologiaRate == null ? null : pratica.tipologiaRate
        parametriRateazione.importoRata = pratica.importoRate
        parametriRateazione.tassoAnnuo = pratica.aliquotaRate
        parametriRateazione.calcoloRate = pratica.calcoloRate == null ? null : pratica.calcoloRate
        parametriRateazione.intRateSoloEvasa = pratica.flagIntRateSoloEvasa
    }

    private def generaF24(def f24data) {
        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        return jasperService.generateReport(reportDef)
    }

    def pathCampiUnione() {

        def path = ""
        def sql = """
                    select oggetto as "oggetto"
                        from si4_competenze co, si4_abilitazioni ab
                        where co.id_abilitazione = ab.id_abilitazione
                            and ab.id_tipo_oggetto = 2
                            and ab.id_tipo_abilitazione = 2
                            AND co.utente = :userId
                    """
        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        sqlQuery.with {
            setString('userId', springSecurityService.currentUser.id)
            list()
        }.each {
            path = it
        }


        return path
    }

    def creaPathCampiUnione(def path) {

        if (!path.endsWith(File.separator)) {
            path += File.separator
        }

        // Si cerca l'abilitazione
        def idAbilitazione = -1
        def sql = """
                    select ab.id_abilitazione "idAbilitazione"
                        from si4_abilitazioni ab
                        where ab.id_tipo_oggetto = 2
                            and ab.id_tipo_abilitazione = 2
                    """
        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        sqlQuery.with {
            list()
        }.each {
            idAbilitazione = it
        }

        // Se non esiste si crea
        if (idAbilitazione == -1) {
            sessionFactory.currentSession.createSQLQuery("""insert into si4_abilitazioni
                                                             (id_abilitazione, id_tipo_oggetto, id_tipo_abilitazione)
                                                                values
                                                                (null, 2, 2)""").executeUpdate()
            // Si recupera l'id della nuova abilitazione
            sqlQuery.with {
                list()
            }.each {
                idAbilitazione = it
            }
        }

        // Siamo in inserimento
        if (pathCampiUnione().isEmpty()) {
            sessionFactory.currentSession.createSQLQuery(
                    """
            insert into si4_competenze (ID_COMPETENZA, ID_ABILITAZIONE, UTENTE, OGGETTO, ACCESSO)
                values (null, ${idAbilitazione}, '${
                        springSecurityService.currentUser.id
                    }', '${path}', 'S')
            """
            ).executeUpdate()
        } else {
            // Siamo in modifica
            sessionFactory.currentSession.createSQLQuery(
                    """
            update si4_competenze co set co.oggetto = '${path}'
                where co.utente = '${springSecurityService.currentUser.id}'
                 and co.id_abilitazione = ${idAbilitazione}
            """
            ).executeUpdate()
        }
    }

    def mergePdf(def documents, def outputFolder) {

        return ModelliCommons.mergePdf(documents, outputFolder)
    }

    def mergePdf(List<byte[]> documents) {

        return ModelliCommons.mergePdf(documents)
    }

    def decodeFormat(def document) {
        return FileFormatUtil.detectFileFormat(new ByteArrayInputStream(document)).loadFormat
    }

    private creaTitolo(def idDoc, def tipoDocumento) {

        def titolo = ""

        def documento = null

        String td = (tipoDocumento) ? tipoDocumento.toUpperCase() : ''

        switch (td) {
            case 'S':
                documento = Ruolo.get(idDoc)
                titolo += 'Comunicazione Ruolo '
                if (documento.tipoRuolo == 1) {
                    titolo += 'Principale '
                } else {
                    titolo += 'Suppletivo '
                }

                switch (documento.tipoEmissione) {
                    case 'A':
                        titolo += 'Acconto '
                        break
                    case 'S':
                        titolo += 'Saldo '
                        break
                    default:
                        titolo += 'Totale '
                }
                titolo += documento.tipoTributo.getTipoTributoAttuale(documento.annoRuolo) + " "
                titolo += "n. ${documento.id}/${documento.annoRuolo}"

                break
            case 'B':
                titolo += 'Comunicazione '
                break
            case ['I', 'A', 'L']:
                documento = PraticaTributo.get(idDoc)

                if (tipoDocumento in ['A', 'L']) {
                    titolo += 'Avv. '
                } else {
                    titolo += 'Accoglimento Istanza Rateazione '
                }

                switch (documento.tipoPratica) {
                    case 'A':
                        titolo += 'Acc. '
                        switch (documento.tipoEvento.tipoEventoDenuncia) {
                            case 'A':
                                titolo += 'Auto '
                                break
                            case 'T':
                                titolo += 'Totale '
                                break
                            default:
                                titolo += ''
                        }
                        break
                    case 'L':
                        titolo += 'Liq. '
                        break
                    default:
                        titolo += ''
                }

                titolo += documento.tipoTributo.getTipoTributoAttuale(documento.anno) + " "

                if (documento.tipoPratica != 'D') {
                    titolo += "n. ${documento.numero}/${documento.anno} "
                }

                if (tipoDocumento != 'I') {
                    titolo += "del ${documento.data.format("dd/MM/yyyy")} "
                    if (documento.dataNotifica != null) {
                        titolo += "Not. il ${documento.dataNotifica.format("dd/MM/yyyy")}"
                    }
                }

                break
            case 'G':
                titolo += 'Lettera Generica '
                break
            case 'C':
                titolo += 'Comunicazione di pagamento '
                break
            case 'D':
                titolo += 'Denuncia '
                break
            case 'T':
                titolo += 'Sollecito '
                break
            case 'SGR':
                titolo += 'Sgravio '
                break
            default:
                throw new RuntimeException("Tipo documento [${tipoDocumento}] non supportato.")
        }

        return titolo

    }

    private String stampaF24RataUnica(def modello) {
        def md = ModelliDettaglio.findByParametroIdAndModello(124, modello)
        if (md) {
            return md.testo
        } else {
            return 'SI'
        }
    }

    def selectTipiModello(def tipoTributo, def tipoPratica = null, def tipoEvento = null, def rimborso = false, def tipoModello = null) {
        def sql = """
                select distinct timo.tipo_modello tipo_modello
                  from tipi_modello timo, modelli modx
                 where timo.tipo_modello = modx.descrizione_ord
                   and modx.flag_web = 'S'
                   and modx.tipo_tributo = :pTipoTributo
                   ${tipoPratica ?
                "and timo.tipo_pratica = :pTipoPratica" :
                ""
        }
                   ${tipoEvento ?
                "and timo.tipo_evento = :pTipoEvento" :
                ""
        }
                   ${rimborso ?
                "and timo.flag_rimborso = :pFlagRimborso" :
                "and timo.flag_rimborso is null"
        }
                   ${tipoModello ?
                "and timo.tipo_modello like upper('${tipoModello}%')" :
                ""
        }
            """

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            setParameter('pTipoTributo', tipoTributo)

            if (tipoPratica) {
                setParameter('pTipoPratica', tipoPratica)
            }

            if (tipoEvento) {
                setParameter('pTipoEvento', tipoEvento)
            }

            if (rimborso) {
                setParameter('pFlagRimborso', 'S')
            }

            list()
        }
    }

    private outputFormat() {
        def outputFormat = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DOC_FORMAT' }?.valore
        switch (outputFormat) {
            case [null, 'DOCX']:
                return SaveFormat.DOCX
            case 'DOC':
                return SaveFormat.DOC
            case 'ODT':
                return SaveFormat.ODT
            default:
                throw new RuntimeException("Tipo formato output non supportato [${outputFormat}]")
        }
    }

    def fDescrizioneTimp(def numModello, def idParametro) {

        Sql sql = new Sql(dataSource)
        String value

        sql.call('{? = call F_DESCRIZIONE_TIMP(?, ?)}'
                , [Sql.VARCHAR,
                   numModello,
                   idParametro
        ]) { value = it }

        return value
    }

    RuoloDTO getRuolo(def idRuolo) {
        return Ruolo.get(idRuolo as Long)?.toDTO()
    }

    PraticaTributoDTO getPratica(def idPratica) {
        return PraticaTributo.get(idPratica as Long)?.toDTO()
    }

    def generaF24Rate(def pratica, def nomeFile) {

        List f24data

        f24data = f24Service.caricaDatiF24(pratica, "R")

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = ModelliCommons.allegaDocumentoPdf(
                ModelliCommons.creaPDFVuoto(), jasperService.generateReport(reportDef).toByteArray(), true
        )

        AMedia amedia = commonService.fileToAMedia(nomeFile, f24file)
        Filedownload.save(amedia)
    }
}
