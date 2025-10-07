package it.finmatica.tr4.documentale


import groovy.sql.Sql
import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dizionari.Ad4Stato
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.ComunicazioniValidationException
import it.finmatica.tr4.comunicazioni.TipoComunicazione
import it.finmatica.tr4.comunicazioni.payload.builder.*
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.smartpnd.SmartPndService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

import java.text.SimpleDateFormat

class DocumentaleService {

    private static Log log = LogFactory.getLog(DocumentaleService)

    private static final String GDM_SERV = "GDM_SERV"
    private static final String GDM_URL = "GDM_URL"

    static final Byte TIPO_CANALE_EMAIL = 2
    static final Byte TIPO_CANALE_PEC = 3
    static final Byte TIPO_CANALE_PND = 4

    def dataSource
    def springSecurityService
    def sessionFactory
    CommonService commonService
    SmartPndService smartPndService
    IntegrazioneDePagService integrazioneDePagService
    DatiGeneraliService datiGeneraliService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    ContribuentiService contribuentiService

    boolean documentaleAttivo() {
        return InstallazioneParametro.get(GDM_SERV) != null
    }

    def invioDocumento(
            def codFiscale,
            def idDocumento,
            def tipologia,
            def documenti,
            def tipoTributoRif = null,
            def annoRif = null,
            def notifica = [tipoNotifica: SmartPndService.TipoNotifica.NONE],
            def notificationFeePolicy = null,
            def physicalComType = null,
            def clienteId = null,
            TipoComunicazione tipoComunicazione = null,
            def nominativoMittente = null,
            def emailMittente = null,
            def testo = null,
            def destinatari = [],
            def parametriExtra = [:],
            def erede = null
    ) {

        def invioASmartPnd = smartPndService.smartPNDAbilitato()

        if (!documenti?.any { it?.principale }) {
            throw new RuntimeException("Nessun documento principale")
        }

        if (!documenti?.any {
            it?.nomeFile?.toString()?.trim()
        }) {
            throw new RuntimeException("Il nome del file non può essere nullo o vuoto")
        }

        if (documenti?.any { it?.documento == null || it.documento.size() == 0 }) {
            throw new RuntimeException("Contenuto del file non valido")
        }

        if (documenti?.findAll { it?.principale }?.size() > 1) {
            throw new RuntimeException("Non si possono inviare più documenti principali")
        }

        def targetDescription = invioASmartPnd ? SmartPndService.TITOLO_SMART_PND : 'Documentale'

        def principale = documenti?.find { it?.principale }

        log.info "Invio a ${targetDescription} [${erede ? erede?.codFiscale + ' erede di ' : ''}${codFiscale}, ${principale.nomeFile}, ${idDocumento}, ${tipologia}]..."

        def tipoNotifica = notifica?.tipoNotifica
        def anno = 0
        def tipoTributo = null
        def tipoDocumento = null

        def v = null
        DocumentoContribuente.withNewTransaction {

            DocumentoContribuente doco = new DocumentoContribuente()

            // Se pratica
            if (tipologia == 'P') {
                doco.pratica = PraticaTributo.get(idDocumento)
                tipoDocumento = recuperaTipoDocumento(idDocumento, tipologia)
                tipoTributo = doco.pratica?.tipoTributo?.tipoTributo
            } else if (tipologia == 'S') {
                // Comunicazioni a ruolo
                def ruolo = Ruolo.get(idDocumento)
                tipoTributo = ruolo.tipoTributo.tipoTributo
                anno = ruolo.annoRuolo
                tipoDocumento = recuperaTipoDocumento(idDocumento, tipologia)
            } else if (tipologia == 'G') {
                tipoDocumento = recuperaTipoDocumento(idDocumento, tipologia)
                tipoTributo = 'ICI'
            } else if (tipologia == 'I') {
                tipoDocumento = recuperaTipoDocumento(idDocumento, tipologia)
                tipoTributo = "TRASV"
            } else if (tipologia == 'B') {
                tipoTributo = tipoTributoRif
                anno = annoRif
                tipoDocumento = 'C'
            } else if (tipologia == 'T') {
                doco.pratica = PraticaTributo.get(idDocumento)
                tipoDocumento = 'T'
                tipoTributo = doco.pratica?.tipoTributo?.tipoTributo
            }

            // Si crea la documenti_contribuente
            doco.contribuente = Contribuente.findByCodFiscale(codFiscale)
            doco.nomeFile = principale.nomeFile
            doco.documento = principale.documento
            doco.dataInserimento = new Date()
            doco.validitaDal = new Date()
            doco.sequenza = generaSequenzaDocumento(codFiscale)

            if (invioASmartPnd && tipoNotifica != SmartPndService.TipoNotifica.NONE) {
                doco.tipoCanale = getTipoCanaleByTipoNotifica(tipoNotifica)
            }

            doco = doco.save(failOnError: true, flush: true)

            // Si salvano eventuali allegati
            documenti.findAll { !it.principale }.each {
                def docAllegato = new DocumentoContribuente()
                docAllegato.contribuente = doco.contribuente
                docAllegato.sequenzaPrincipale = doco.sequenza
                docAllegato.nomeFile = it.nomeFile
                docAllegato.documento = it.documento
                docAllegato.dataInserimento = new Date()
                docAllegato.validitaDal = new Date()
                docAllegato.sequenza = generaSequenzaDocumento(codFiscale)
                docAllegato.save(failOnError: true, flush: true)

            }

            if (invioASmartPnd) {
                v = invioDocumentoSmartPnd(doco, codFiscale, anno, idDocumento,
                        tipoTributo, tipoDocumento, documenti, notifica,
                        notificationFeePolicy, physicalComType, clienteId, tipoComunicazione,
                        nominativoMittente, emailMittente, testo,
                        destinatari, parametriExtra, erede)
            } else {
                v = invioDocumentoGDM(codFiscale, anno, idDocumento, tipoTributo, tipoDocumento, documenti[0].nomeFile)
            }
        }

        log.info "Risposta ${targetDescription} [${v}]"

        log.info "Invio a ${targetDescription}... completato."

        return v
    }

    private def getTipoCanaleByTipoNotifica(SmartPndService.TipoNotifica tipoNotifica) {
        if (tipoNotifica == SmartPndService.TipoNotifica.PEC) {
            return TIPO_CANALE_PEC
        }
        if (tipoNotifica == SmartPndService.TipoNotifica.PND) {
            return TIPO_CANALE_PND
        }
        if (tipoNotifica == SmartPndService.TipoNotifica.EMAIL) {
            return TIPO_CANALE_EMAIL
        }
    }

    def invioDocumentoGDM(def codFiscale, def anno, def idDocumento, def tipoTributo, def tipoDocumento, def nomeFile) {

        def verifica = verificaInvio(codFiscale, nomeFile)
        if (!verifica.empty) {
            return verifica
        }

        def v = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call TR4_TO_GDM.INVIO_DOCUMENTO(?, ?, ?, ?, ?, ?, ?, ?)}',
                [Sql.VARCHAR,
                 codFiscale,
                 anno,
                 idDocumento,
                 tipoTributo,
                 tipoDocumento,
                 null,
                 null,
                 nomeFile?.toString()
                ]) { v = it }
        return v
    }

    def invioDocumentoSmartPnd(def doco, def codFiscale, def anno, def idDocumento, def tipoTributo,
                               def tipoDocumento, def documenti, def notifica,
                               def notificationFeePolicyValue, def physicalComTypeValue,
                               def clienteId, TipoComunicazione tipoComunicazione,
                               def nomeMittente, def emailMittente, def testo,
                               def destinatari = [], def parametriExtra = [:], erede = null) {

        try {

            def principale = documenti.find { it.principale }

            def tipoNotifica = notifica?.tipoNotifica
            def emailPrincipale = notifica?.email


            def parametriPnd = generaParametriPnd(codFiscale, anno, idDocumento, tipoTributo ?: 'TRASV', tipoDocumento ?: 'ND', null, erede?.id) + parametriExtra

            if (!parametriPnd || parametriPnd.isEmpty() || parametriPnd.ERRORE) {
                throw new Exception(parametriPnd.ERRORE)
            }

            def contribuente = doco.contribuente
            def tipoComunicazionePnd = tipoComunicazione.tipoComunicazione
            def codFiscaleCreditore = datiGeneraliService.getDatiSoggettoCorrente(clienteId ?: -1)?.codiceFiscale
            def dovutiPratica
            if (tipoDocumento in ['A', 'L', 'T']) {
                dovutiPratica = integrazioneDePagService.determinaDovutiPratica(idDocumento)
            } else if (tipoDocumento == 'S') {
                dovutiPratica = integrazioneDePagService.determinaDovutiRuolo(contribuente.codFiscale, idDocumento)
            } else if (tipoDocumento == 'C') {
                dovutiPratica = integrazioneDePagService.determinaDovutiImposta(codFiscaleCreditore, anno, tipoTributo, null)
            }

            def tassonomiaConPagamento = smartPndService.tassonomiaConPagamento(tipoComunicazione?.codiceTassonomia)
            def codAvviso = null
            def chiavePagamento = null
            def causaleVersamentoAvviso = null
            def dataScadenzaAvviso = null
            def importoDovuto = null
            if (tassonomiaConPagamento) {
                if (dovutiPratica?.size() > 1) {
                    throw new RuntimeException("Il contribuente ha più di un dovuto, modalità non supportata.")
                } else if (dovutiPratica?.size() == 1) {
                    codAvviso = dovutiPratica.first().CODICE_AVVISO
                    causaleVersamentoAvviso = dovutiPratica.first().CAUSALE_VERSAMENTO
                    dataScadenzaAvviso = new SimpleDateFormat("dd/MM/yyyy").format(dovutiPratica.first().DATA_SCADENZA_AVVISO)
                    importoDovuto = dovutiPratica.first().IMPORTO_DOVUTO
                    chiavePagamento = "TR4_PAG_" + (sessionFactory.currentSession.createSQLQuery("select SPND_PAG_SEQ.nextval from dual").list()[0] as String)
                }
            }

            def nominativoMittente = nomeMittente ?: tipoComunicazione.nominativoMittente ?: datiGeneraliService.getDatiSoggettoCorrente(clienteId ?: -1)?.cognome

            def oggettoComunciazione = (tipoNotifica != SmartPndService.TipoNotifica.NONE ? (notifica.oggetto ?: parametriPnd.OGGETTO_STANDARD) : null) ?:
                    parametriPnd.OGGETTO


            doco.titolo = oggettoComunciazione
            doco.save(failOnError: true, flush: true)

            def statoDest = ""
            def statoSiglaDest = ""
            if (parametriPnd.PROVINCIA_DEST.length() > 2) {
                statoDest = contribuentiService.getSiglaStato(parametriPnd.PROVINCIA_DEST)
                statoSiglaDest = Ad4Stato.findByDenominazione(parametriPnd.PROVINCIA_DEST)?.sigla
            }

            def payload = (new ComunicazionePayloadBuilder(
                    datiGeneraliService.extractDatiGenerali().codAzienda,
                    UUID.randomUUID().toString(),
                    parametriPnd.COGNOME,
                    parametriPnd.CODICE_FISCALE,
                    oggettoComunciazione,
                    tipoComunicazionePnd
            )).crea {
                applicativo(SmartPndService.APPLICATIVO_TR4)
                inSospeso(FlagSospeso.YES)
                nome(parametriPnd.NOME)
                tipoPratica(parametriPnd.DESCRIZIONE)
                dataPratica(parametriPnd.DATA_PRATICA)
                labelPratica(parametriPnd.LABEL_PRATICA)
                annoPratica(parametriPnd.ANNO_TR4)
                numeroPratica(parametriPnd.NUMERO_PRATICA)

                if (tassonomiaConPagamento && codAvviso) {
                    codiceIUV(codAvviso)
                }

                allegato {
                    descrizione(principale.nomeFile as String)
                    filename(principale.nomeFile as String)
                    firmare(tipoComunicazione.daFirmare == 'NF' ? 'N' : 'Y')
                }

                // Allegati secondari
                documenti.findAll { !it.principale }.each { a ->
                    allegato {
                        descrizione(a.nomeFile as String)
                        filename(a.nomeFile as String)
                        if (a.allegatoPagamento) {
                            allegatoPagamento("Y")
                        } else {
                            firmare(tipoComunicazione.daFirmare == 'NF' ? 'N' : 'Y')
                        }
                    }
                }

                def parametri = ['PROGRESSIVO_TR4', 'ID_ELABORAZIONE_MASSIVA', 'ID_ATTIVITA_MASSIVA']
                parametri.each { p ->
                    if (parametriPnd[p] != null) {
                        dettaglioExtra {
                            campo(p)
                            valore(parametriPnd[p] as String)
                            url('N')
                        }
                    }
                }

                if (tipoNotifica == SmartPndService.TipoNotifica.PEC ||
                        tipoNotifica == SmartPndService.TipoNotifica.EMAIL) {
                    invioMail {
                        oggetto(oggettoComunciazione)
                        delegate.nominativoMittente(nominativoMittente)

                        if (emailMittente?.trim()) {
                            mailMittente(emailMittente)
                        }
                        if (testo?.trim()) {
                            delegate.testo(testo)
                        }

                        destinatario {
                            mail(emailPrincipale ?: ((tipoNotifica == SmartPndService.TipoNotifica.PEC) ? parametriPnd.PEC_DESTINAZIONE : parametriPnd.EMAIL_DESTINAZIONE))
                            nome(parametriPnd.NOME)
                            cognome(parametriPnd.COGNOME)
                            cognomeRgs(parametriPnd.COGNOME)
                            cfiscPiva(parametriPnd.CODICE_FISCALE)
                            comune(parametriPnd.COMUNE_DEST)
                            cap(parametriPnd.CAP_DEST)
                            indirizzo(parametriPnd.INDIRIZZO_DEST)
                            tipoDestinatario(parametriPnd.TIPO_PERSONA_DEST == '0' ? FlagTipoDestinatario.PERSONA_FISICA : parametriPnd.TIPO_PERSONA_DEST == '1' ? FlagTipoDestinatario.AZIENDA : null)
                            cfiscPivaCreditore(codFiscaleCreditore)
                        }
                    }
                }

                if (tipoNotifica == SmartPndService.TipoNotifica.PND) {
                    invioPND {
                        oggetto(oggettoComunciazione)
                        if (notificationFeePolicyValue) {
                            notificationFeePolicy(FlagNotificationFeePolicy.findByValue(notificationFeePolicyValue))
                        }
                        if (physicalComTypeValue) {
                            physicalCommunicationType(FlagPhysicalCommunicationType.findByValue(physicalComTypeValue))
                        }

                        // La lista dei destinatari è attualmente utilizzata solo per la gestione degli eredi,
                        // se non è vuota non si invia la notifica al deceduto.
                        // Se destinatari verrà utilizzato per altri casi d'uso sarà necessario determinare in qualche
                        // modo se siamo in presenza della gestione degli eredi.
                        if (destinatari.isEmpty()) {
                            destinatario {
                                email(parametriPnd.PEC_DESTINAZIONE)
                                nome(parametriPnd.NOME)
                                cognome(parametriPnd.COGNOME)
                                cognomeRgs(parametriPnd.COGNOME)
                                cfiscPiva(parametriPnd.CODICE_FISCALE)
                                comune(parametriPnd.COMUNE_DEST)
                                cap(parametriPnd.CAP_DEST)
                                indirizzo(parametriPnd.INDIRIZZO_PND_DEST)
                                tipoDestinatario(parametriPnd.TIPO_PERSONA_DEST == '0' ? FlagTipoDestinatario.PERSONA_FISICA : parametriPnd.TIPO_PERSONA_DEST == '1' ? FlagTipoDestinatario.AZIENDA : null)

                                // Stato estero, provo a recuperarne la sigla
                                if (!statoDest.empty) {
                                    provincia(statoDest)
                                    stato(statoSiglaDest)
                                } else {
                                    provincia(parametriPnd.PROVINCIA_DEST)
                                }

                                if (tassonomiaConPagamento && codAvviso) {
                                    cfiscPivaCreditore(codFiscaleCreditore)
                                    codiceAvviso(codAvviso)
                                }
                            }
                        }

                        destinatari.each { d ->

                            def pDest = this.generaParametriPnd(codFiscale, anno, idDocumento, tipoTributo, tipoDocumento, null, d.id)

                            destinatario {
                                email(pDest.PEC_DESTINAZIONE)
                                nome(pDest.NOME)
                                cognome(pDest.COGNOME)
                                cognomeRgs(pDest.COGNOME)
                                cfiscPiva(pDest.CODICE_FISCALE)
                                comune(pDest.COMUNE_DEST)
                                cap(pDest.CAP_DEST)
                                indirizzo(pDest.INDIRIZZO_PND_DEST)
                                tipoDestinatario(pDest.TIPO_PERSONA_DEST == '0' ? FlagTipoDestinatario.PERSONA_FISICA : pDest.TIPO_PERSONA_DEST == '1' ? FlagTipoDestinatario.AZIENDA : null)

                                // Stato estero, provo a recuperarne la sigla
                                if (!statoDest.empty) {
                                    provincia(statoDest)
                                    stato(statoSiglaDest)
                                } else {
                                    provincia(parametriPnd.PROVINCIA_DEST)
                                }

                                if (tassonomiaConPagamento && codAvviso) {
                                    cfiscPivaCreditore(codFiscaleCreditore)
                                    codiceAvviso(codAvviso)
                                }
                            }
                        }
                    }
                }

                // Pagamenti
                if (tassonomiaConPagamento && codAvviso) {
                    pagamento {
                        chiave(chiavePagamento)
                        tipoPagatore(parametriPnd.TIPO_PERSONA_DEST == '0' ? 'F' : parametriPnd.TIPO_PERSONA_DEST == '1' ? 'G' : null)
                        codicePagatore(parametriPnd.CODICE_FISCALE)
                        anagraficaPagatore("${parametriPnd.COGNOME}${parametriPnd.NOME?.trim() ? ' ' + parametriPnd.NOME : ''}".toString())
                        causaleVersamento(causaleVersamentoAvviso)
                        codiceIuv(codAvviso)
                        dataScadenza(dataScadenzaAvviso)
                        importoTotale(importoDovuto)
                        versamenti([])
                    }
                }
            }

            def idComunicazione = smartPndService.creaComunicazione(payload)
            log.info("Creata Comunicazione $idComunicazione")

            doco.idComunicazionePnd = idComunicazione
            doco.note = "Inviato a ${SmartPndService.TITOLO_SMART_PND}"
            doco.validitaAl = null
            doco.save(failOnError: true, flush: true)

            documenti.each {
                def idComunicazioneUpload = smartPndService.uploadFileComunicazione(idComunicazione, it.nomeFile, it.documento)
                log.info("File $doco.nomeFile caricato su Comunicazione $idComunicazioneUpload")
            }

            // svuota blob documento dopo upload file
            doco.documento = null
            doco = doco.save(failOnError: true, flush: true)

            return idComunicazione as String

        } catch (Exception e) {
            log.error('Impossibile creare comunicazione', e)
            doco.delete(flush: true)

            // TODO: questa logica dovrà essere riportata nel metodo CommonService.extractOraMessage
            def message = e?.message ?: e?.cause?.message ?: e?.cause?.cause?.message ?: ""

            def oraError = "ORA-20999"
            if (message.contains(oraError)) {
                def startIndex = message.indexOf(oraError) + "$oraError: ".length()
                message = message.substring(startIndex, message.indexOf('\n'))
            } else if (e instanceof ComunicazioniValidationException) {
                message = e.message
            } else {
                message = "errore generico"
            }

            return "Impossibile creare comunicazione - $message"
        }
    }

    def generaParametriPnd(def codFiscale, def anno, def idDocumento, def tipoTributo, def tipoDocumento, def nomeFile, def niErede = null) {
        def parametriCursor = commonService.refCursorToCollection("TR4_TO_GDM.GENERA_PARAMETRI_PND('${codFiscale}',${anno},${idDocumento},'${tipoTributo}','${tipoDocumento}',${nomeFile ? "'" + nomeFile?.toString() + "'" : null}${niErede ? ",$niErede" : ''})")
        def parametri = parametriCursor.collectEntries {
            [(it.NOME): it.VALORE]
        }
        if (!parametri || parametri.isEmpty() || parametri.ERRORE) {
            throw new Exception((String) parametri.ERRORE)
        }
        return parametri
    }

    def urlInGDM(def idDoc) {
        return "${InstallazioneParametro.get(GDM_URL).valore}idDoc=${idDoc}&utente=${springSecurityService.currentUser?.id}"
    }

    def recuperaTipoDocumento(def idDocumento, def tipologia) {
        def tipoDocumento = ""

        if (tipologia == 'P') {
            def pratica = PraticaTributo.get(idDocumento)
            tipoDocumento = pratica.tipoPratica == 'S' ? 'T' : pratica.tipoPratica
        } else if (tipologia == 'S') {
            tipoDocumento = tipologia
        } else if (tipologia == 'G') {
            tipoDocumento = tipologia
        } else if (tipologia == 'I') {
            tipoDocumento = tipologia
        } else if (tipologia == 'C') {
            tipoDocumento = tipologia
        } else if (tipologia == 'T') {
            tipoDocumento = tipologia
        }

        return tipoDocumento
    }

    private verificaInvio(def codFiscale, def nomeFile) {
        return verificaInvioMsg(codFiscale, nomeFile, null, null)

    }

    def verificaInvioMsg(def codFiscale, def nomeFile, def tipoNotifica, def pratica) {

        log.info "Verifica invio GDM [${codFiscale}, ${nomeFile}]"

        // Integrazione con GDM via SmartPND
        if (smartPndService.smartPNDAbilitato()) {
            if (tipoNotifica == SmartPndService.TipoNotifica.PND && esisteComunicazioneConNotificaPnd(nomeFile, codFiscale, pratica)) {
                return "Documento già inviato con notifica PND."
            } else if (tipoNotifica == SmartPndService.TipoNotifica.PEC && (esisteComunicazioneConNotificaPnd(nomeFile, codFiscale, pratica)
                    || esisteComunicazioneConNotificaPec(nomeFile, codFiscale, pratica))) {
                return "Documento già inviato con notifica PND o PEC."
            } else {
                return ""
            }
        }

        // Integrazione con GDM senza SmartPND
        def v
        def msg = ''
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)

        try {
            sql.call('{? = call TR4_TO_GDM.VERIFICA_INVIO_GDM(?, ?)}',
                    [Sql.NUMERIC,
                     codFiscale as String,
                     nomeFile as String]) {
                v = it
            }
        } catch (Exception ex) {
            log.error ex
            if (ex?.message?.startsWith("ORA-01422")) {
                throw new Application20999Error(ex.message)
            } else if (ex?.cause?.cause?.message?.startsWith("ORA-01422")) {
                throw new Application20999Error(ex.message)
            }
        }

        switch (v) {
            case 1:
                msg = "Documento già inviato a GDM."
                break
            case 2:
                msg = "Documento protocollato."
                break
            case 3:
                msg = "PEC inviata."
                break
            case 4:
                msg = "PEC ricevuta."
                break

        }

        return msg
    }

    def getDocumentoContribuenteByIdComunicazionePnd(def idComunicazionePnd) {
        return DocumentoContribuente.findByIdComunicazionePnd(idComunicazionePnd as Long)?.toDTO()
    }

    def aggiornaProtocollo(def documentoContribuente, def annoProtocollo, def numeroProtocollo, def user = null) {

        if (documentoContribuente.annoProtocollo == null && documentoContribuente.numeroProtocollo == null) {

            log.info("Ricevuto protocollo: ${numeroProtocollo}/${annoProtocollo}")

            def loggedUser = user ? (Ad4Utente.get(user)?.toDTO() ?: springSecurityService?.currentUser?.toDTO()) : springSecurityService?.currentUser?.toDTO()

            documentoContribuente.annoProtocollo = annoProtocollo as Short
            documentoContribuente.numeroProtocollo = numeroProtocollo as Long
            documentoContribuente.informazioni = "${documentoContribuente.informazioni ? documentoContribuente.informazioni + ' - ' : ''}Prot. n. ${numeroProtocollo}/${annoProtocollo}"
            documentoContribuente.utente = loggedUser
            documentoContribuente.toDomain().save(failOnError: true, flush: true)
        } else {
            log.info("Ricevuto protocollo: ${numeroProtocollo}/${annoProtocollo}. Documento già protocollato, nulla da fare.")
        }
    }

    def aggiornaInvio(def documentoContribuente, def dataSped, def param, Long tipoNotifica, def utente, def canale) {
        def formatoData = 'dd/MM/yyyy'
        def loggedUser = utente ? (Ad4Utente.get(utente)?.toDTO() ?: springSecurityService?.currentUser?.toDTO()) : springSecurityService?.currentUser?.toDTO()

        // PEC
        if (canale == TipiCanaleDTO.PEC) {
            documentoContribuente.dataInvioPec = dataSped?.format(formatoData)
            documentoContribuente.dataRicezionePec = param?.format(formatoData)
            documentoContribuente.informazioni = "${documentoContribuente.informazioni ? documentoContribuente.informazioni + ' - ' : ''}Not. il ${dataSped?.format(formatoData) ?: param?.format(formatoData)}"
        } else if (canale == TipiCanaleDTO.PND) {
            // PND
            documentoContribuente.dataSpedizionePnd = dataSped?.format(formatoData)
            documentoContribuente.statoPnd = param
            documentoContribuente.informazioni = "${documentoContribuente.informazioni ? documentoContribuente.informazioni + ' - ' : ''}Not. il ${dataSped?.format(formatoData)}"
        } else {
            throw new RuntimeException("Tipo notifica ${canale} non previsto")
        }

        documentoContribuente.utente = loggedUser
        documentoContribuente.toDomain().save(failOnError: true, flush: true)

        // Si utilizza una query nativa perché con le entity la data_notifica non veniva aggiornata
        if (documentoContribuente.pratica) {
            def pratica = PraticaTributo.get(documentoContribuente.pratica.id).refresh()

            // Se il documento si riferisce ad una pratica NON rateizzata, si aggiorna la data di notifica
            if (pratica && (!pratica.dataNotifica || !pratica.tipoNotifica) && documentoContribuente.nomeFile.substring(1, 3) != 'RAI') {
                def query = """
                    update pratiche_tributo prtr
                        set 
                        ${dataSped ? 'data_notifica = trunc(:dataNotifica),' : ''}
                        ${tipoNotifica ? 'tipo_notifica = :tipoNotifica,' : ''} 
                            utente = :utente
                    where prtr.pratica = :idPratica
                    """

                def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)

                if (dataSped) {
                    sqlQuery.setDate("dataNotifica", dataSped)
                }
                sqlQuery.setLong("idPratica", documentoContribuente.pratica.id)
                if (tipoNotifica) {
                    sqlQuery.setLong("tipoNotifica", tipoNotifica)
                }
                sqlQuery.setParameter("utente", loggedUser?.id)
                sqlQuery.executeUpdate()
            }
        }
    }

    def annullaDocumento(def documentoContribuente) {

        if (documentoContribuente.sequenza != null) {
            DocumentoContribuente.findAllBySequenzaPrincipaleAndContribuente(documentoContribuente.sequenza, documentoContribuente.contribuente?.toDomain()).each {
                it.delete(failOnError: true, flush: true)
            }
        }

        documentoContribuente.toDomain().delete(failOnError: true, flush: true)
    }

    def aggiornaCostoPnd(def comunicazione, def costo, def user) {

        def prtr = DocumentoContribuente.findByIdComunicazionePnd(comunicazione as Long)?.pratica

        log.info("Ricevuto costo PND [${costo}]")

        if (!prtr.sanzioniPratica.find { it.sanzione.codSanzione == 9000 }) {
            log.info("Inserito costo PND [${costo}]")
            liquidazioniAccertamentiService.executeInserimentoSanzione(9000,
                    prtr?.tipoTributo?.tipoTributo,
                    prtr?.id,
                    null, null,
                    costo as BigDecimal,
                    1,
                    user)
        } else {
            log.info("Costo già presente. Nulla da fare.")
        }


    }

    private def verificaComunicazioneConNotifica(def filter) {

        def result = DocumentoContribuente.createCriteria().count() {
            eq("contribuente.codFiscale", filter.codFiscale)
            if (!filter.pratica) {
                like("nomeFile", "${filter.nomeFile}%")
            } else {
                eq("pratica.id", filter.pratica.id)
            }

            eq("tipoCanale", filter.tipoCanale)
        }
        return result > 0
    }

    def esisteComunicazioneConNotificaPec(def nomeFile, def codFiscale, def pratica) {
        return verificaComunicazioneConNotifica([
                "codFiscale": codFiscale,
                "nomeFile"  : nomeFile,
                "pratica"   : pratica,
                "tipoCanale": TIPO_CANALE_PEC
        ])
    }

    def esisteComunicazioneConNotificaPnd(def nomeFile, def codFiscale, def pratica) {
        return verificaComunicazioneConNotifica([
                "codFiscale": codFiscale,
                "nomeFile"  : nomeFile,
                "pratica"   : pratica,
                "tipoCanale": TIPO_CANALE_PND
        ])
    }

    private Short generaSequenzaDocumento(String codFiscale) {

        Short sequenza = 0

        Sql sql = new Sql(dataSource)
        sql.call('{call DOCUMENTI_CONTRIBUENTE_NR(?, ?)}',
                [
                        codFiscale,
                        Sql.NUMERIC
                ],
                { sequenza = it }
        )

        return sequenza
    }

}
