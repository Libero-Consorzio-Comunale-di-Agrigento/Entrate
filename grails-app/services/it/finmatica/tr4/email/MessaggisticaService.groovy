package it.finmatica.tr4.email

import grails.transaction.Transactional
import groovy.json.JsonOutput
import it.finmatica.cim.*
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.payload.builder.ComunicazionePayloadBuilder
import it.finmatica.tr4.comunicazioni.payload.builder.FlagSospeso
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.comunicazioni.DettaglioComunicazioneDTO
import it.finmatica.tr4.smartpnd.SmartPndService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.criterion.CriteriaSpecification
import wslite.http.auth.HTTPBasicAuthorization
import wslite.soap.SOAPClient
import wslite.soap.SOAPVersion

import java.util.zip.GZIPInputStream
import java.util.zip.GZIPOutputStream

@Transactional
class MessaggisticaService {
    private static Log log = LogFactory.getLog(MessaggisticaService)

    private static final EMAIL_PARAM = "SI4CS_MAIL"
    private static final APP_IO_PARAM = "SI4CS_IO"
    private static final ID_PARAMETRO_EMAIL = "EMAIL"
    private static final ID_PARAMETRO_FIRMA = "FIRMA"

    public static final EMAIL_TIPO_TRIBUTO = 'TRASV'
    public static final EMAIL_TIPO_COMUNICAZIONE = 'LGE'
    public static final EMAIL_TIPOLOGIA_DOCUMENTALE = 'G'
    public static final APPLICATIVO = "WEB"
    public static final Integer MAX_LENGTH = 10000
    public static final LABEL_NON_DEFINITO = "[Non definito]"

    def springSecurityService
    DatiGeneraliService datiGeneraliService
    ComunicazioniTestiService comunicazioniTestiService
    SmartPndService smartPndService
    ContribuentiService contribuentiService
    CommonService commonService
    DocumentaleService documentaleService
    def dataSource


    def caricaIndirizziMittente() {

        def indirizziMittente = []

        def tipoParametroEmail = TipoParametro.findByIdAndApplicativo(ID_PARAMETRO_EMAIL, APPLICATIVO)
        def indirizzoParametriUtente = ParametroUtente.findByTipoParametroAndUtente(
                tipoParametroEmail, springSecurityService.currentUser.id
        )

        indirizziMittente << [indirizzo         : indirizzoParametriUtente?.valore ?: LABEL_NON_DEFINITO,
                              origine           : 'PU',
                              descrizioneOrigine: 'Parametri Utente']

        def indirizzoInstallazioneParametri = InstallazioneParametro.get(ID_PARAMETRO_EMAIL)

        indirizziMittente << [indirizzo         : indirizzoInstallazioneParametri?.valore ?: LABEL_NON_DEFINITO,
                              origine           : 'IP',
                              descrizioneOrigine: 'Installazione Parametri']
    }

    def caricaIndirizziMittenteEscludiNonDefiniti() {
        def indirizziMittente = caricaIndirizziMittente()

        indirizziMittente.each {
            if (it.indirizzo == LABEL_NON_DEFINITO) {
                indirizziMittente = indirizziMittente - it
            }
        }

        return indirizziMittente
    }

    def inserisciModificaIndirizzo(def indirizzo) {
        if (indirizzo.origine == 'PU') {
            def tipoParametroEmail = TipoParametro.findByIdAndApplicativo(ID_PARAMETRO_EMAIL, APPLICATIVO)
            def pu = ParametroUtente
                    .findByTipoParametroAndUtente(tipoParametroEmail, springSecurityService.currentUser.id) ?:
                    new ParametroUtente(
                            utente: springSecurityService.currentUser.id,
                            dataVariazione: new Date(),
                            tipoParametro: tipoParametroEmail
                    )

            pu.valore = indirizzo.indirizzo
            pu.save(failOnError: true, flush: true)
        } else if (indirizzo.origine == 'IP') {
            new InstallazioneParametro(
                    parametro: ID_PARAMETRO_EMAIL,
                    valore: indirizzo.indirizzo
            ).save(failOnError: true, flush: true)
        }
    }

    def caricaFirme(def escludiNonDefiniti = false) {
        def firme = []

        def tipoParametroFirma = TipoParametro.findByIdAndApplicativo(ID_PARAMETRO_FIRMA, APPLICATIVO)
        def firmaParametriUtente = ParametroUtente.findByTipoParametroAndUtente(
                tipoParametroFirma, springSecurityService.currentUser.id
        )

        firme << [firma             : firmaParametriUtente?.valore ?: LABEL_NON_DEFINITO,
                  origine           : 'PU',
                  descrizioneOrigine: 'Parametri Utente']

        def firmaInstallazioneParametri = InstallazioneParametro.get(ID_PARAMETRO_FIRMA)

        firme << [firma             : firmaInstallazioneParametri?.valore ?: LABEL_NON_DEFINITO,
                  origine           : 'IP',
                  descrizioneOrigine: 'Installazione Parametri']

        if (!escludiNonDefiniti) {
            return firme
        } else {
            return firme.findAll { it.firma != LABEL_NON_DEFINITO }
        }
    }

    def inserisciModificaFirma(def firma) {
        if (firma.origine == 'PU') {
            def tipoParametroFirma = TipoParametro.findByIdAndApplicativo(ID_PARAMETRO_FIRMA, APPLICATIVO)
            def pu = ParametroUtente
                    .findByTipoParametroAndUtente(tipoParametroFirma, springSecurityService.currentUser.id) ?:
                    new ParametroUtente(
                            utente: springSecurityService.currentUser.id,
                            dataVariazione: new Date(),
                            tipoParametro: tipoParametroFirma
                    )

            pu.valore = firma.firma
            pu.save(failOnError: true, flush: true)
        } else if (firma.origine == 'IP') {
            new InstallazioneParametro(
                    parametro: ID_PARAMETRO_FIRMA,
                    valore: firma.firma
            ).save(failOnError: true, flush: true)
        }
    }

    def indirizziDestinatario(def codFiscale) {

        return RecapitoSoggetto.createCriteria().list {

            createAlias("tipoRecapito", "tire", CriteriaSpecification.INNER_JOIN)
            createAlias("soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("sogg.contribuenti", "conx", CriteriaSpecification.INNER_JOIN)

            projections {
                property("descrizione", "indirizzo")
                property("tire.descrizione", "tipoIndirizzoDescrizione")
            }

            eq("conx.codFiscale", codFiscale)
            'in'("tire.id", [2L, 3L])

        }.collect { [indirizzo: it[0], tipoIndirizzoDescrizione: it[1]] }
    }

    def haIndirizzi(def codFiscale) {
        return !indirizziDestinatario(codFiscale).empty
    }

    def splitIndirizzi(def indirizzi) {
        if (!indirizzi?.trim()) {
            return []
        }
        return indirizzi.split(",")*.trim()
    }

    def validaIndirizzo(def indirizzo) {
        def emailPattern = /[_A-Za-z0-9-]+(.[_A-Za-z0-9-]+)*@[A-Za-z0-9]+(.[A-Za-z0-9]+)*(.[A-Za-z]{2,})/

        return (indirizzo ==~ emailPattern)
    }

    def zip(String s) {
        def targetStream = new ByteArrayOutputStream()
        def zipStream = new GZIPOutputStream(targetStream)
        zipStream.write(s.getBytes('UTF-8'))
        zipStream.close()
        def zippedBytes = targetStream.toByteArray()
        targetStream.close()
        return zippedBytes.encodeBase64().toString().getBytes()
    }

    def unzip(byte[] compressed) {

        def inflaterStream = new GZIPInputStream(new ByteArrayInputStream(new String(compressed).decodeBase64()))
        def uncompressedStr = inflaterStream.getText('UTF-8')
        return uncompressedStr
    }

    def inviaEmail(Messaggio messaggio, def codFiscale, def note, DettaglioComunicazioneDTO dettaglioComunicazione, def inviaEmailSmartPndParams) {
        def contribuente = Contribuente.findByCodFiscale(codFiscale)

        if (smartPndService.smartPNDAbilitato()) {
            inviaEmailSmartPnd(messaggio, contribuente, dettaglioComunicazione, inviaEmailSmartPndParams)
        } else {

            def documentoContribuente = new DocumentoContribuente(
                    titolo: "Email a ${estraiIndirizzo(messaggio.destinatario)}",
                    documento: zip(JsonOutput.toJson(messaggio)),
                    contribuente: contribuente,
                    note: note
            )
            def nomeDestinatario = "${contribuente.soggetto.cognome} ${contribuente.soggetto.nome ?: ''}"?.trim()
            def msgId = inviaEmailCim(
                    [nome: '', email: messaggio.mittente.indirizzo],
                    [nome: nomeDestinatario, email: estraiIndirizzo(messaggio.destinatario)],
                    splitIndirizzi(messaggio.copiaConoscenza),
                    splitIndirizzi(messaggio.copiaConoscenzaNascosta),
                    messaggio.oggetto,
                    getTestoAndFirma(messaggio),
                    messaggio.allegati)
            documentoContribuente.idMessaggio = msgId
            log.info "Salvataggio in documenti_contribuente"
            contribuentiService.caricaDocumento(documentoContribuente)
        }
    }

    private getTestoAndFirma(def messaggio) {
        if (messaggio.firma?.trim()) {
            return "$messaggio.testo\n\n$messaggio.firma" as String
        } else {
            return messaggio.testo
        }
    }

    def estraiIndirizzo(String indirizzo) {
        if (indirizzo?.trim()?.empty) {
            return ''
        } else {
            def email = indirizzo
            if (email.indexOf(' - ') > 0) {
                email = indirizzo.trim().substring(0, indirizzo.indexOf(' -'))
            }

            return email
        }
    }

    void inviaEmailSmartPnd(Messaggio messaggio, Contribuente contribuente, DettaglioComunicazioneDTO dettaglioComunicazione, def inviaEmailSmartPndParams) {
        def allegatiComunicazione = messaggio.allegati.collect {
            [nomeFile: it.nome as String, documento: it.contenuto, principale: it.principale]
        }
        def listaTipoComunicazione = smartPndService.listaTipologieComunicazione().findAll { it.tagMail }
        def tipoComunicazionePnd = listaTipoComunicazione.find { it.tipoComunicazione == dettaglioComunicazione?.tipoComunicazionePnd }
        def response = documentaleService.invioDocumento(
                contribuente.codFiscale ?: contribuente.soggetto.partitaIva,
                inviaEmailSmartPndParams.pratica?.id ?: inviaEmailSmartPndParams.ruolo?.id,
                inviaEmailSmartPndParams.tipologia,
                allegatiComunicazione,
                inviaEmailSmartPndParams.tipoTributo,
                inviaEmailSmartPndParams.anno,
                [tipoNotifica: SmartPndService.TipoNotifica.EMAIL, oggetto: messaggio.oggetto, email: messaggio.destinatario],
                null,
                null,
                null,
                tipoComunicazionePnd,
                null,
                messaggio.mittente.indirizzo,
                getTestoAndFirma(messaggio),
                []
        )
        if (!response.isNumber()) {
            throw new Exception(response)
        }
    }

    private def inviaEmailCim(def mittente, def destinatario, def cc, def bcc, def oggetto, def testo, def allegati) {
        def alias = InstallazioneParametro.get(EMAIL_PARAM)?.valore

        if (!alias?.trim()) {
            throw new RuntimeException("Parametro ${EMAIL_PARAM} non definito nella tabella INSTALLAZIONE_PARAMETRI.")
        }

        log.info "Invio email (${alias}, ${mittente}, ${destinatario})..."

        GenericMessage gm = Creator.create(alias)
        Sender sender = new Sender()

        // Mittente
        Contact contattoMittente = creaContatto(mittente.nome, mittente.email)
        sender.contact = contattoMittente
        gm.sender = sender

        // Destinatario
        gm.addRecipient(creaContatto(destinatario.nome, destinatario.email))

        // cc
        cc.each {
            gm.addCc(creaContatto('', it))
        }

        // ccn
        bcc.each {
            gm.addBcc(creaContatto('', it))
        }

        // Oggetto
        gm.subject = oggetto

        // Testo
        gm.text = testo

        // Allegati
        allegati.each {
            gm.addAttachment(new Attachment(it.contenuto, it.nome))
        }

        int msgId = gm.send()
        if (msgId != 0) {
            log.error("Si e' verificato un errore nella spedizione della email. Valore di ritorno metodo send: ${msgId}")
            throw new Exception("Si e' verificato un errore nella spedizione email [${msgId}]")
        }

        log.info "Email inviata. Valore di ritorno metodo send: ${gm.lastMessageDbIndex}"
        return gm.lastMessageDbIndex

    }

    def inviaAppIO(def destinatario, def oggetto, def testo, def tag = null, def tipoComunicazionePnd = null, def parametri = null) {
        if (smartPndService.smartPNDAbilitato()) {
            inviaAppIOSmartPnd(destinatario, oggetto, testo, tipoComunicazionePnd, parametri)
        } else {
            inviaAppIOCim(destinatario, oggetto, testo, tag)
        }
    }

    def inviaAppIOCim(def destinatario, def oggetto, def testo, def tag) {

        def alias = tag ?: InstallazioneParametro.get(APP_IO_PARAM)?.valore

        if (!(alias?.trim() as Boolean)) {
            throw new RuntimeException("Parametro ${APP_IO_PARAM} non definito nella tabella INSTALLAZIONE_PARAMETRI.")
        }

        GenericMessage gm = Creator.create(alias)
        gm.text = testo
        gm.subject = oggetto

        //impostazioni mittente = null
        Sender sender = new Sender()
        sender.contact = new Contact()
        gm.sender = sender

        //impostazioni destinatario = cf
        gm.addRecipient(creaContatto(null, destinatario))

        int msgId = gm.send()
        if (msgId != 0) {
            log.error("Si è verificato un errore nell'invio del messaggio ad AppIO'. Valore di ritorno metodo send: ${msgId}")
            throw new RuntimeException("Si è verificato un errore nell'invio del messaggio ad AppIO [${msgId}]")
        }

        log.info("Messaggio inviato ad AppIO. Valore di ritorno metodo send: ${gm.lastMessageDbIndex}")
        return gm.getLastMessageDbIndex()

    }

    def inviaAppIOSmartPnd(def destinatario, def oggettoMessaggio, def testoMessaggio, def tipoComunicazionePnd, def parametri) {
        def contribuente = Contribuente.findByCodFiscale(destinatario)

        def payload = (new ComunicazionePayloadBuilder(
                datiGeneraliService.extractDatiGenerali().codAzienda,
                UUID.randomUUID().toString(),
                contribuente.soggetto.cognome,
                contribuente.codFiscale,
                oggettoMessaggio,
                tipoComunicazionePnd
        )).crea {
            applicativo(SmartPndService.APPLICATIVO_TR4)
            inSospeso(FlagSospeso.YES)
            nome(parametri.NOME)
            tipoPratica(parametri.DESCRIZIONE)
            dataPratica(parametri.DATA_PRATICA)
            labelPratica(parametri.LABEL_PRATICA)
            annoPratica(parametri.ANNO_TR4)
            numeroPratica(parametri.NUMERO_TR4?.trim() ?: parametri.NUMERO_PRATICA)

            invioAppIO {
                oggetto(oggettoMessaggio)
                codFiscale(contribuente.codFiscale)
                testo(testoMessaggio)
            }
        }

        try {
            smartPndService.creaComunicazione(payload)
        } catch (Exception e) {
            log.error('Impossibile creare comunicazione', e)
            throw new Exception("Impossibile creare comunicazione - ${e.localizedMessage}", e)
        }
    }

    def getStatoMessaggio(Long idMessaggio) {

        def wsUrl = InstallazioneParametro.get('SI4CS_URL')?.valore
        if (!wsUrl?.trim()) {
            throw new RuntimeException("URL non dedinita nella tabella INSTALLAZIONE_PARAMETRI")
        }

        def messaggioXML = """<?xml version='1.0' encoding='UTF-8'?>
            <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ws="ws.si4cs.finmatica.it">
                <soap:Header/>
                <soap:Body>
                    <ws:getStatoMessaggio>
                        <ws:idMessaggioInviato>${idMessaggio}</ws:idMessaggioInviato>
                    </ws:getStatoMessaggio>
                </soap:Body>
            </soap:Envelope>"""

        def client = new SOAPClient(wsUrl)

        client.authorization = new HTTPBasicAuthorization('si4cs', null)
        def response = client.send(SOAPVersion.V1_1, messaggioXML)
    }

    def generaMessaggio(def tipo,
                        def comunicazioneTesti,
                        def codFiscale,
                        def anno,
                        def pratica,
                        def ruolo,
                        def niErede = null,
                        def massiva = false) {
        Messaggio messaggio = new Messaggio([tipo: tipo])


        if (comunicazioneTesti) {
            messaggio.oggetto = comunicazioneTesti.oggetto

            if (tipo != Messaggio.TIPO.APP_IO) {
                messaggio.allegati = convertToAllegatiMessaggio(comunicazioniTestiService.getListaAllegatiTesto(comunicazioneTesti))
            }

            if (massiva) {
                messaggio.testo = comunicazioneTesti.testoModificato ?: comunicazioneTesti.testo
            } else {
                def parametri = [:]
                if (comunicazioneTesti.tipoComunicazione == 'LCO') {
                    parametri = [
                            TIPO_TRIBUTO: comunicazioneTesti.tipoTributo,
                            COD_FISCALE : codFiscale,
                            ANNO        : anno,
                    ]
                } else if (comunicazioneTesti.tipoTributo == 'TARSU' &&
                        comunicazioneTesti.tipoComunicazione == 'APA') {
                    parametri = [COD_FISCALE: codFiscale,
                                 RUOLO      : ruolo
                    ]
                } else if (comunicazioneTesti.tipoComunicazione == 'LGE') {
                    parametri = [
                            COD_FISCALE : codFiscale,
                            TIPO_TRIBUTO: comunicazioneTesti.tipoTributo
                    ]
                } else {
                    // Pratiche
                    parametri = [
                            COD_FISCALE : codFiscale,
                            PRATICA     : pratica,
                            TIPO_TRIBUTO: comunicazioneTesti.tipoTributo,
                            NI_EREDE    : niErede
                    ]
                }

                messaggio.testo = comunicazioniTestiService.mailMerge(
                        comunicazioneTesti.tipoTributo,
                        comunicazioneTesti.tipoComunicazione,
                        comunicazioneTesti.testoModificato ?: comunicazioneTesti.testo,
                        parametri
                )
            }
        } else {
            messaggio.oggetto = ""
            messaggio.testo = ""
        }

        return messaggio
    }


    def convertToAllegatiMessaggio(def allegatiTesti) {
        allegatiTesti.collect {
            [nome       : it.nomeFile,
             contenuto  : it.documento,
             dimensione : commonService.humanReadableSize(it.documento.size()),
             descrizione: it.descrizione]
        }
    }

    private def creaContatto(def nome, def email) {
        Contact contact = new Contact()
        contact.name = nome
        contact.email = email

        return contact
    }

}
