package it.finmatica.tr4.depag

import groovy.sql.Sql
import groovy.xml.DOMBuilder
import groovy.xml.XmlUtil
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.wslog.WsLogService
import org.apache.commons.codec.binary.Base64
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import wslite.http.HTTPRequest
import wslite.http.HTTPResponse
import wslite.http.auth.HTTPBasicAuthorization
import wslite.soap.SOAPClient
import wslite.soap.SOAPClientException
import wslite.soap.SOAPResponse

import java.text.SimpleDateFormat
import java.util.regex.Matcher
import java.util.regex.Pattern

class IntegrazioneDePagService {

    static String TITOLO_DEPAG = 'PagoPA'

    def STATI_DEPAG = [
            ACQUISITO        : [codice: "A", descrizione: "Da inviare a PT", immagine: "/images/afc/16x16/exit.png"],
            SPEDITO_IN_ATTESA: [codice: "S", descrizione: "In corso di invio a PT", immagine: "/images/afc/16x16/db_export.png"],
            RICEVUTO_OK      : [codice: "R", descrizione: "Disponibile al pagamento", immagine: "/images/afc/16x16/cash_register.png"],
            RESPINTO         : [codice: "E", descrizione: "Respinto (con anomalie)", immagine: "/images/afc/16x16/error.png"],
            IN_PAGAMENTO     : [codice: "I", descrizione: "In corso di pagamento", immagine: "/images/afc/16x16/elaboration.png"],
            PAGATO           : [codice: "P", descrizione: "Pagato con successo", immagine: "/images/afc/16x16/right.png"],
            TRATTATO         : [codice: "T", descrizione: "Pagato e rendicontato", immagine: "/images/afc/16x16/right_r.png"],
            PAGAMENTO_FALLITO: [codice: "F", descrizione: "Pagamento fallito", immagine: "/images/afc/16x16/cancel.png"]
    ]

    def dataSource
    def sessionFactory
    CommonService commonService
    WsLogService wsLogService

    private static Log log = LogFactory.getLog(IntegrazioneDePagService)

    public final static def DEPAG_NO = 0

    private final def ESITO_OPERAZIONE_ERROR = "<ESITO_OPERAZIONE>ERROR</ESITO_OPERAZIONE>"
    private final def DESCRIZIONE_ERRORE = "DESCRIZIONE_ERRORE"

    private final def PAGONLINE = "PAGONLINE"
    private final def DEPA_URL = "DEPA_URL"
    private def DEPA_SERVIZIO = "DEPA_"
    private final def DEPA_CE = "DEPA_CE"
    private final def DEPA_USER = "DEPA_USER"
    private final def DEPA_PASS = "DEPA_PASS"

    private WS_URL = { -> OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == DEPA_URL }?.valore }
    private WS_USER = { -> OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == DEPA_USER }?.valore }
    private WS_PASS = { ->
        OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == DEPA_PASS }?.valore ?: ""
    }
    private COD_ENTE = { -> OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == DEPA_CE }?.valore }

    def generaAvviso(def chiave, def servizio) {

        def WEB_SERVICE = "generaAvviso"


        def response = ""
        def param = ""

        param = """
                <GENERA_AVVISO>
                    <CHIAVE>${chiave}</CHIAVE>
                </GENERA_AVVISO>
                """

        log.info "Parametri di chiamata: ${param}"

        param = Base64.encodeBase64String(param.getBytes())

        def callLogDetails = [idBack: chiave, servizio: servizio]
        response = inviaRichiestaSoap(soapXml(WEB_SERVICE, COD_ENTE(), servizio, param), callLogDetails)

        if (response.indexOf("<DATI>") > 0) {
            log.info "Risposta: ${response.substring(0, response.indexOf("<DATI>"))}"
        } else {
            log.info "Risposta: ${response}"
        }

        if (wsError(response)) {
            response = retrieveValue(response, DESCRIZIONE_ERRORE)
        } else {
            // PDF in BASE64
            response = Base64.decodeBase64(retrieveValue(response, "AVVISO"))
        }

        return response
    }

    def passaPraticaAPagoPA(def idPratica, def determina = false) {

        // Valore non nullo, di tipo Long
        if (idPratica == null || !(idPratica instanceof Long)) {
            throw new RuntimeException("Valore [$idPratica] non valido per idPratica")
        }

        // La pratica deve esistere
        def pratica = PraticaTributo.get(idPratica)
        if (!pratica) {
            throw new RuntimeException("La pratica non esiste [$idPratica]")
        }

        // Se pratica di sollecito si annullano gli avvisi dei dovuti ordinari
        if (pratica.tipoPratica in ['S', 'V']) {
            eliminaDovutoPratica(pratica)
        }

        def message = ""
        def inviato = false

        message = aggiornaDovutiPratica(pratica.id, determina)

        if (message.replace("\n", "").empty) {
            pratica.flagDePag = 'S'
            inviato = true
            pratica.save(failOnError: true, flush: true)
        }

        return [messaggio: message, inviato: inviato]

    }

    def passaPraticaAPagoPAConNotifica(def idPratica, def window, def determina = false) {
        def pratica = PraticaTributo.findById(idPratica)
        def response = passaPraticaAPagoPA(idPratica, determina)
        def esito = [
                pratica : pratica,
                response: response
        ]

        commonService.creaPopup("/depag/esitoDePag.zul", window, [
                listaEsiti: [esito]
        ])

        return response
    }

    def passaPraticheAPagoPAConNotifica(List<Long> listaPratiche, def window, def determina = false) {
        def responses = []
        def esiti = []

        def pratiche = PraticaTributo.createCriteria().list {
            createAlias('contribuente', 'cont', CriteriaSpecification.INNER_JOIN)
            createAlias('cont.soggetto', 'sogg', CriteriaSpecification.INNER_JOIN)

            inList('id', listaPratiche)
        }

        pratiche.each {
            def response = passaPraticaAPagoPA(it.id)
            responses << response

            def esito = [
                    pratica : it.toDTO(),
                    response: response
            ]
            esiti << esito
        }

        commonService.creaPopup("/depag/esitoDePag.zul", window, [
                listaEsiti: esiti
        ])

        return responses
    }

    def eliminaDovutoPratica(def pratica) {

        def message = ""
        def posizioniTrovate = 0

        // Ravvedimenti: trattati solo TARSU e CUNI
        if (pratica.tipoPratica == 'V') {
            if (!pratica.tipoTributo.tipoTributo in ['TARSU', 'CUNI']) {
                throw new RuntimeException("Tipo tributo non supportato")
            } else {
                determinaDovutiPratica(pratica.id).each {
                    posizioniTrovate++
                    if (message.replace("\n", "").empty) {
                        message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                    }
                }
            }
        } else if (pratica.tipoTributo.tipoTributo == 'TARSU') {
            // TARSU

            RuoloContribuente.createCriteria().list {
                eq("contribuente.codFiscale", pratica.contribuente.codFiscale)
            }.findAll { it.ruolo.annoRuolo == pratica.anno }.each {
                determinaDovutiRuolo(pratica.contribuente.codFiscale, it.ruolo.id).each {
                    posizioniTrovate++
                    if (message.replace("\n", "").empty) {
                        message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                    }
                }
            }

            determinaDovutiPratica(pratica.id).each {
                posizioniTrovate++
                if (message.replace("\n", "").empty) {
                    message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                }
            }
        } else if (pratica.tipoTributo.tipoTributo == 'CUNI') {
            // CUNI

            determinaDovutiImposta(pratica.contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo, null)
                    .each {
                        posizioniTrovate++
                        if (message.replace("\n", "").empty) {
                            message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                        }
                    }

            determinaDovutiPratica(pratica.id).each {
                posizioniTrovate++
                if (message.replace("\n", "").empty) {
                    message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                }
            }

        } else {

            determinaDovutiPratica(pratica.id).each {
                posizioniTrovate++
                if (message.replace("\n", "").empty) {
                    message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                }
            }
        }

        if (message.replace("\n", "").empty) {

            if (posizioniTrovate == 0) {
                return "Nessuna posizione debitoria da eliminare"
            } else {
                pratica.flagDePag = null
                pratica.save(failOnError: true, flush: true)
                return ""
            }
        } else {
            return message
        }
    }

    def aggiornaDovutoRuolo(def codFiscale, def ruolo) {

        def message = """"""

        def dovuti = determinaDovutiRuolo(codFiscale, ruolo)

        if (dovuti.isEmpty()) {
            return "Non sono presenti informazioni da passare a PagoPA."
        }

        def progressivo = 1
        dovuti.each {

            // Se si è verificato un errore nella chiamata non si effettuano le successive
            if (message.replace("\n", "").empty) {
                if (it.AZIONE != 'A') {
                    message += aggiornaDovuto(it, it.SERVIZIO, progressivo++) + "\n"
                } else {
                    // Elimina dovuto
                    message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
                }
            }
        }

        if (message.replace("\n", "").empty) {
            return ""
        } else {
            return message
        }

    }

    def eliminaDovuto(def idBack, def servizio) {

        def WEB_SERVICE = "eliminaDovuto"

        def param = """
                        <ELIMINA_DOVUTO>
                            <CHIAVE>${idBack}</CHIAVE>
                        </ELIMINA_DOVUTO>
                    """

        log.info "Parametri di chiamata: ${param}"
        log.info "Servizio: ${servizio}"

        param = Base64.encodeBase64String(param.getBytes())

        def callLogDetails = [idBack: idBack, servizio: servizio]
        def response = inviaRichiestaSoap(soapXml(WEB_SERVICE, COD_ENTE, servizio, param), callLogDetails)

        log.info "Risposta: ${response}"

        if (wsError(response)) {
            return retrieveValue(response, DESCRIZIONE_ERRORE)
        } else {
            return ""
        }
    }

    def aggiornaDovuto(def dovuto, def servizio, def progressivo = 1) {

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd")

        def WEB_SERVICE = "aggiornaDovuto"

        def causaleVersamento =
                XmlUtil.escapeXml(dovuto['CAUSALE_VERSAMENTO'].substring(0, dovuto['CAUSALE_VERSAMENTO'].length() > 140 ? 140 : dovuto['CAUSALE_VERSAMENTO'].length()))
        def dataScadenzaAvviso = dovuto['DATA_SCADENZA_AVVISO'] ?
                "<DATA_SCADENZA_AVVISO>${sdf.format(dovuto['DATA_SCADENZA_AVVISO'])}</DATA_SCADENZA_AVVISO>" : ""

        def datiRiscossione =
                XmlUtil.escapeXml(dovuto['DATI_RISCOSSIONE']) ? "<DATI_RISCOSSIONE>${XmlUtil.escapeXml(dovuto['DATI_RISCOSSIONE'])}</DATI_RISCOSSIONE>" : ""

        def dicituraScadenza = dovuto['DICITURA_SCADENZA']?.trim() ? "<DICITURA_SCADENZA>${XmlUtil.escapeXml(dovuto['DICITURA_SCADENZA'])}</DICITURA_SCADENZA>" : ''

        String quoteMB = dovuto['QUOTE_MB']
        String nomeServizio = XmlUtil.escapeXml(dovuto['SERVIZIO'] ?: servizio)
        if (quoteMB) {
            quoteMB = elaboraQuoteMB(quoteMB, nomeServizio, dovuto)
        } else {
            quoteMB = """
				<QUOTE_MB>NO</QUOTE_MB>
				<SINGOLO_VERSAMENTO>
					<PROGRESSIVO>${progressivo}</PROGRESSIVO>
					<SERVIZIO>${nomeServizio}</SERVIZIO>
					<CAUSALE>${XmlUtil.escapeXml(causaleVersamento)}</CAUSALE>
					<IMPORTO>${XmlUtil.escapeXml(dovuto['IMPORTO_DOVUTO']?.toString())}</IMPORTO>
					<COMMISSIONE_CARICO_PA>${XmlUtil.escapeXml(dovuto['COMMISSIONE_CARICO_PA']) ?: ''}</COMMISSIONE_CARICO_PA>
					${datiRiscossione}
					<ACCERTAMENTO>${XmlUtil.escapeXml(dovuto['ACCERTAMENTO'])}</ACCERTAMENTO>
					<BILANCIO>${XmlUtil.escapeXml(dovuto['BILANCIO'])}</BILANCIO>
				</SINGOLO_VERSAMENTO>"""
        }

        String metadata = dovuto['METADATA']
        if (metadata) {
            metadata = elaboraMetadata(metadata)
        } else {
            metadata = ''
        }

        def param = """
                <AGGIORNA_DOVUTO>
                    <CHIAVE>${dovuto['IDBACK']}</CHIAVE>
                    <TIPO_PAGATORE>${dovuto['TIPO_IDENT_PAGATORE']}</TIPO_PAGATORE>
                    <CODICE_PAGATORE>${dovuto['CODICE_IDENT_PAGATORE']}</CODICE_PAGATORE>
                    <ANAGRAFICA_PAGATORE>${XmlUtil.escapeXml(dovuto['ANAG_PAGATORE'])}</ANAGRAFICA_PAGATORE>

                    <INDIRIZZO_PAGATORE>${XmlUtil.escapeXml(dovuto['INDIRIZZO_PAGATORE'])}</INDIRIZZO_PAGATORE>
                    <CIVICO_PAGATORE>${XmlUtil.escapeXml(dovuto['CIVICO_PAGATORE'])}</CIVICO_PAGATORE>
                    <CAP_PAGATORE>${XmlUtil.escapeXml(dovuto['CAP_PAGATORE'])}</CAP_PAGATORE>
                    <LOCALITA_PAGATORE>${XmlUtil.escapeXml(dovuto['LOCALITA_PAGATORE'])}</LOCALITA_PAGATORE>
                    <PROVINCIA_PAGATORE>${XmlUtil.escapeXml(dovuto['PROV_PAGATORE'])}</PROVINCIA_PAGATORE>
                    <NAZIONE_PAGATORE>${XmlUtil.escapeXml(dovuto['NAZ_PAGATORE'])}</NAZIONE_PAGATORE>
                    <EMAIL_PAGATORE>${XmlUtil.escapeXml(dovuto['EMAIL_PAGATORE'])}</EMAIL_PAGATORE>

                    <TIPO_DOVUTO>${XmlUtil.escapeXml(dovuto['TIPO_DOVUTO'])}</TIPO_DOVUTO>
                    <TIPO_VERSAMENTO>${XmlUtil.escapeXml(dovuto['TIPO_VERSAMENTO'])}</TIPO_VERSAMENTO>
                    <CAUSALE_VERSAMENTO>${XmlUtil.escapeXml(dovuto['CAUSALE_VERSAMENTO'])}</CAUSALE_VERSAMENTO>
                    <DATA_SCADENZA>${sdf.format(dovuto['DATA_SCADENZA'])}</DATA_SCADENZA>
                    ${dataScadenzaAvviso}
                    $dicituraScadenza
                    <IMPORTO_TOTALE>${XmlUtil.escapeXml(dovuto['IMPORTO_DOVUTO']?.toString())}</IMPORTO_TOTALE>

                    ${quoteMB}
                    ${metadata}

                </AGGIORNA_DOVUTO>
        """

        log.info "Parametri di chiamata: ${param}"

        param = Base64.encodeBase64String(param.getBytes())

        def callLogDetails = [idBack: dovuto['IDBACK'], codFiscale: dovuto['CODICE_IDENT_PAGATORE'], servizio: servizio]
        def response = inviaRichiestaSoap(soapXml(WEB_SERVICE, COD_ENTE, servizio, param), callLogDetails)

        log.info "Risposta: ${response}"

        if (wsError(response)) {
            return retrieveValue(response, DESCRIZIONE_ERRORE)
        } else {
            return ""
        }
    }

    /// Elabora quote di depag_dovuti per WS
    String elaboraQuoteMB(String originale, String servizio, def dovuto) {

        String quote = ""
        String quota
        String result = ""

        def metaDataContext = DOMBuilder.parse(new StringReader(originale)).documentElement
        def nodes = metaDataContext.getChildNodes()

        String nomeNodo = metaDataContext.getNodeName()

        if (nomeNodo == 'QUOTE_MB') {

            int numQuote = 0

            nodes.each { node ->

                def nodeCtx = estraiattributiNodo(node)
                if (nodeCtx._nomeNodo == 'QUOTA') {

                    quota = '<SINGOLO_VERSAMENTO>'

                    quota += '<PROGRESSIVO>' + nodeCtx.NUM + '</PROGRESSIVO>'
                    quota += '<SERVIZIO>' + servizio + '</SERVIZIO>'
                    quota += '<CF_BENEFICIARIO>' + nodeCtx.CF + '</CF_BENEFICIARIO>'
                    quota += '<IMPORTO>' + nodeCtx.IMPORTO + '</IMPORTO>'
                    quota += '<CAUSALE>' + nodeCtx.CAUSALE + '</CAUSALE>'
                    quota += '<IBAN>' + nodeCtx.IBAN + '</IBAN>'
                    quota += '<TASSONOMIA>' + nodeCtx.TASSONOMIA + '</TASSONOMIA>'

					/// Questi dati li anggiunge SOLO alla prima voce (Imposta)
					if(numQuote == 0) {
					    if (dovuto['COMMISSIONE_CARICO_PA']) quota += "<COMMISSIONE_CARICO_PA>${XmlUtil.escapeXml(dovuto['COMMISSIONE_CARICO_PA'])}</COMMISSIONE_CARICO_PA>"
                        if (dovuto['DATI_RISCOSSIONE']) quota += "<DATI_RISCOSSIONE>${XmlUtil.escapeXml(dovuto['DATI_RISCOSSIONE'])}</DATI_RISCOSSIONE>"
					    if (dovuto['ACCERTAMENTO']) quota += "<ACCERTAMENTO>${XmlUtil.escapeXml(dovuto['ACCERTAMENTO'])}</ACCERTAMENTO>"
					    if (dovuto['BILANCIO']) quota += "<BILANCIO>${XmlUtil.escapeXml(dovuto['BILANCIO'])}</BILANCIO>"
					}

                    quota += '</SINGOLO_VERSAMENTO>\n'

                    quote += quota
                    numQuote++
                }
            }

            if (numQuote > 0) {
                result = '<QUOTE_MB>'
                result += (numQuote > 1) ? 'SI' : 'NO'
                result += '</QUOTE_MB>\n'
                result += quote
            }
        }

        return result
    }

    /// Elabora metadata di depag_dovuti per WS
    String elaboraMetadata(String originale) {

        String result = ""

        def metaDataContext = DOMBuilder.parse(new StringReader(originale)).documentElement
        def nodes = metaDataContext.getChildNodes()

        String nomeNodo = metaDataContext.getNodeName()

        if (nomeNodo == 'metadata') {

            nodes.each { node ->

                def nodeCtx = estraiattributiNodo(node)
                if (nodeCtx._nomeNodo == 'mapEntry') {
                    result += "<MAPENTRY><KEY>${nodeCtx.key}</KEY><VALUE>${nodeCtx.value}</VALUE></MAPENTRY>\n"
                }
            }

            if (!result.isEmpty()) {
                result = '<METADATA>\n' + result + '</METADATA>'
            }
        }

        return result
    }

    def estraiattributiNodo(def node) {

        String subNodeName
        String value

        def attributi = [:]
        attributi._nomeNodo = node.getNodeName()

        def childNodes = node.getChildNodes()
        childNodes.each { subNode ->

            subNodeName = subNode.getNodeName()
            value = subNode.getTextContent()
            attributi[subNodeName] = value
        }

        return attributi
    }

    // Determina numero elaborazione.
    // 	Solo per CUNI, legge numero di conto corrente se descrizione non nulla.
    def determinaElaborazione(String tipoTributo, def praticaId, def codiceTributo = null) {

        CodiceTributo codiceTributoObj = null

        Integer elaborazione = 0

        if ((praticaId ?: 0) > 0) {
            PraticaTributo praticaTributo = PraticaTributo.get(praticaId)
            if (praticaTributo != null) {
                SortedSet<OggettoPratica> oggettiPratica = praticaTributo.oggettiPratica
                oggettiPratica.each {
                    codiceTributo = it.codiceTributo.id
                }
            }
        }

        if (tipoTributo == 'CUNI') {
            if ((codiceTributo ?: 0) > 0) {
                codiceTributoObj = CodiceTributo.findById(codiceTributo)
            }
            if (codiceTributoObj == null) {
                List<CodiceTributo> codiciTributoObj = CodiceTributo.findAll { (id >= 8600) && (id <= 8699) && (flagRuolo == null) }
                if (codiciTributoObj.size() > 0) {
                    codiciTributoObj.sort { it.id }
                    codiceTributoObj = codiciTributoObj[0]
                }
            }
            if (codiceTributoObj != null) {
                if (!((codiceTributoObj.descrizioneCc ?: '').isEmpty())) {
                    elaborazione = codiceTributoObj.contoCorrente
                }
            }
        }

        return elaborazione
    }

    def determinaTipoOccupazione(def codFiscale, def tipoTributo, def anno) {
        def sql = """
                select DISTINCT ogpr.TIPO_OCCUPAZIONE "tipoOccupazione"
                  from web_oggetti_pratica  ogpr,
                       oggetti_contribuente ogco,
                       web_oggetti_imposta  ogim,
                       contribuenti         con,
                       soggetti             sogg
                 where ogpr.oggetto_pratica = ogco.oggetto_pratica
                   and ogco.cod_fiscale = ogim.cod_fiscale
                   and ogco.oggetto_pratica = ogim.oggetto_pratica
                   and ogco.cod_fiscale = con.cod_fiscale
                   and con.ni = sogg.ni
                   and ogco.cod_fiscale = :pCodFiscale
                   and ogim.tipo_tributo = :pTipoTributo
                   and ogim.anno = :pAnno
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setInteger('pAnno', anno as Integer)
            setString('pTipoTributo', tipoTributo)
            setString('pCodFiscale', codFiscale)

            list()
        }

        return results[0]?.tipoOccupazione ?: 'P'
    }

	/// Riporta elenco servizi univoci per tipo tributo
	def getElencoServizi(String tipoTributo) {
		
		def filtri = [:]
		
		filtri << ['tipoTributo': tipoTributo]
		
		String sql = """
				select 
				  grtr.gruppo_tributo as cod_gruppo_tributo, 
				  grtr.descrizione as des_gruppo_tributo,
				  tpoc.tipo_occupazione as cod_tipo_occupazione,
				  tpoc.descrizione as des_tipo_occupazione,
				  f_depag_servizio(grtr.descrizione,tpoc.tipo_occupazione) as servizio
				from
				  gruppi_tributo grtr,
				  (select 'P' tipo_occupazione, 'Permanente' as descrizione from dual
				   union
				   select 'T' tipo_occupazione, 'Temporanea' as descrizione from dual
				  ) tpoc
				where
				  grtr.tipo_tributo = :tipoTributo
				order by
				  grtr.gruppo_tributo,
				  tpoc.tipo_occupazione
		"""
		
		def results = eseguiQuery("${sql}", filtri, null, true)
		
		def records = []

		results.each {

			def record = [:]

			record.codGruppoTributo = it['COD_GRUPPO_TRIBUTO'] as String
			record.desGruppoTributo = it['DES_GRUPPO_TRIBUTO'] as String
			record.codOccupazione = it['COD_TIPO_OCCUPAZIONE'] as String
			record.desOccupazione = it['DES_TIPO_OCCUPAZIONE'] as String
			
			record.servizio = it['SERVIZIO'] as String
			record.descrizione = record.desGruppoTributo + " - " + record.desOccupazione
			
			records << record
		}
		
		return records
	}

	/// Riporta elenco gruppi tributo degli oggetti di una pratica
	def getGruppiTributoPratica(Long praticaId) {
		
		def filtri = [:]
		
		filtri << ['praticaId': praticaId]

		String sql = """
                select distinct
                  grtr.gruppo_tributo,
                  grtr.descrizione,
                  ogpr.tipo_occupazione
                from
                  gruppi_tributo grtr,
                  codici_tributo cotr,
                  oggetti_pratica ogpr,
                  pratiche_tributo prtr
                where ogpr.pratica = prtr.pratica
                  and ogpr.tributo = cotr.tributo
                  and cotr.gruppo_tributo = grtr.gruppo_tributo(+)
                  and prtr.pratica = :praticaId
                order by
                 grtr.gruppo_tributo
        """
		
		def results = eseguiQuery("${sql}", filtri, null, true)
		
		def gruppi = []

		results.each {

			def gruppo = [:]

            gruppo.gruppoTributo = it['GRUPPO_TRIBUTO'] as String
            gruppo.descrizione = it['DESCRIZIONE'] as String
            gruppo.tipoOccupazione = it['TIPO_OCCUPAZIONE'] as String
			
			gruppi << gruppo
		}

        return gruppi
    }
		
    def aggiornaDovutiPratica(def idPratica, def determina = false) {

        def message = ""

        // Esistono già i dovuti per la pratica
        def dovuti

        if (determina) {
            dovuti = determinaDovutiPratica(idPratica)
        } else {
            dovuti = commonService.refCursorToCollection("pagonline_tr4.aggiorna_dovuti_pratica(${idPratica})")
        }

        if (dovuti.isEmpty()) {
            return "Non sono presenti informazioni da passare a PagoPA."
        }

        dovuti.each {
            if (message.replace("\n", "").empty) {
                message += aggiornaDovuto(it, it.SERVIZIO) + "\n"
            }
        }

        if (message.replace("\n", "").empty) {
            return ""
        } else {
            return message
        }
    }

    def determinaDovutiRuolo(def codFiscale, def ruolo, def tipoDovuto = 'NP', def numRataMax = null) {

        Ruolo r = Ruolo.get(ruolo)

        def tipoTributo = r.tipoTributo.tipoTributo
        def anno = r.annoRuolo

        tipoDovuto = tipoDovuto != null ? ",'$tipoDovuto'" : ', null'
        String rataMax = numRataMax != null ? ',' + numRataMax : ', null'

        return commonService.refCursorToCollection("pagonline_tr4.determina_dovuti_ruolo('${tipoTributo}', '${codFiscale}', ${anno}, ${ruolo} ${tipoDovuto} ${rataMax})")
    }

    def determinaDovutiPratica(def idPratica, def tipoDovuto = 'NP') {

        tipoDovuto = tipoDovuto != null ? ",'$tipoDovuto'" : ''

        return commonService.refCursorToCollection("pagonline_tr4.determina_dovuti_pratica($idPratica $tipoDovuto)")
    }

    def determinaDovutiImposta(def codFiscale, def anno, def tipoTributo, def rata, def tipoDovuto = 'NP', def gruppoTributo = null) {

        def tipoOccupazione = determinaTipoOccupazione(codFiscale, tipoTributo, anno)

        return determinaDovutiImposta(codFiscale, anno, tipoTributo, rata, tipoDovuto, gruppoTributo, tipoOccupazione)
    }

    def determinaDovutiImposta(def codFiscale, def anno, def tipoTributo, def rata, def tipoDovuto, def gruppoTributo, def tipoOccupazione) {

        tipoDovuto = tipoDovuto != null ? "'$tipoDovuto'" : null
		gruppoTributo = gruppoTributo != null ? "'$gruppoTributo'" : null
        tipoOccupazione = tipoOccupazione != null ? "'$tipoOccupazione'" : null

        return commonService.refCursorToCollection("pagonline_tr4.determina_dovuti_imposta('${tipoTributo}', '${codFiscale}', ${anno}, " + 
																				    "$tipoOccupazione, $rata, $tipoDovuto, $gruppoTributo)")
    }

    def determinaDovutiSoggetto(def codFiscale, def filtroStato = 'D') {

        return commonService.refCursorToCollection("pagonline_tr4.determina_dovuti_soggetto('${codFiscale}','${filtroStato}')")
    }

    def aggiornaDovutiSoggetto(String codFiscale) {

        String message = '';
        String messageNow;
        int result = 0
        
        log.info "Eseguo aggiornaDovutiSoggetto di ${codFiscale}"

        try {
            def dovuti = determinaDovutiSoggetto(codFiscale, 'D') // D = Da Pagara, P = Pagato, T = Tutto
            dovuti.each { 

                messageNow = aggiornaDovuto(it, it.SERVIZIO)

                if(!messageNow.empty) {
                    messageNow = "IUV: ${it.COD_IUV}\nIDBACK: ${it.IDBACK}\n" + messageNow
                    message += messageNow + "\n\n"

                    log.error "Errore in aggiornaDovutiSoggetto di ${codFiscale} ${messageNow}"
                }
            }

            if (message.replace("\n", "").empty) {
                message =  ""
            }
            else {
                message = "Errore di allineamento al PT durante aggiorna dovuto di ${codFiscale}:\n\n" + message
                result = 1
            }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                message = "Errore: " + e?.message
                result = 2
            }
        }

        return [result: result, message: message]
    }

    def eliminaDovutiAnnullatiSoggetto(String codFiscale, String tipoTributo = null, String codFiscaleNuovo = null) {

        String message = '';
        String messageNow;
        int result = 0

        def elencoServizi = []
        def elencoIUV = []
        
        log.info "Eseguo eliminaDovutiAnnullatiSoggetto di ${codFiscale} per tributo ${tipoTributo ?: 'TUTTI'}"

        try {
            if(tipoTributo) {
                def listaServizi = getElencoServizi(tipoTributo)
                elencoServizi = listaServizi.collect { it.servizio }
            }

            if(codFiscaleNuovo) {
                /// Prima di tutto ricava i dovuti del soggeto che sostituisce
                def listaRiferimenti =  determinaDovutiSoggetto(codFiscaleNuovo, 'D')
                elencoIUV = listaRiferimenti.collect { it.COD_IUV }
                /// L'elenco non può essere vuoto senno elimina sempre, quindi ne aggiungiamo uno ""finto""
                elencoIUV << 'XXXXXXXXXXXXXXXXX'
            }

            def dovuti = determinaDovutiSoggetto(codFiscale, 'D')   /// D = Da Pagara, P = Pagato, T = Tutto
            dovuti.each {

                /// Da eliminare
                if (it.AZIONE == 'A') { 

                    /// Se specificato tributo deve coincidere con uno dei servizi
                    if (elencoServizi.isEmpty() || it.SERVIZIO in elencoServizi) {

                        /// Se specificato nuovo C.F. deve esserci uno IUV corrispondente (o vuoto)
                        if(it.COD_IUV == null || elencoIUV.isEmpty() || it.COD_IUV in elencoIUV) {
                            messageNow = eliminaDovuto(it.IDBACK, it.SERVIZIO)
                        }
                        else {
                            messageNow = "Non eliminato e non aggiornato/sostituito: verificare in DEPAG"
                        }

                        if(!messageNow.empty) {
                            messageNow = "IUV: ${it.COD_IUV}\nIDBACK: ${it.IDBACK}\n" + messageNow
                            message += messageNow + "\n\n"

                            log.error "Errore in eliminaDovutiAnnullatiSoggetto di ${codFiscale} ${messageNow}"
                        }
                    }
                }
            }

            if (message.replace("\n", "").empty) {
                message =  ""
            }
            else {
                message = "Errore di allineamento al PT durante elimina dovuto di ${codFiscale}:\n\n" + message
                result = 1
            }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                message = "Errore: " + e?.message
                result = 2
            }
        }

        return [result: result, message: message]
    }

    def aggiornaDovutoPagoPa(def codFiscale, def ruolo) {

        Ruolo r = Ruolo.get(ruolo)

        def tipoTributo = r.tipoTributo.tipoTributo
        def anno = r.annoRuolo

        def sqlCall = """
					DECLARE
						BEGIN
							? := pagonline_tr4.aggiorna_dovuto_pagopa('${tipoTributo}', '${codFiscale}', ${anno}, ${ruolo});
						END;
				 """

        Sql sql = new Sql(dataSource)

        def msg = ""
        sql.call(sqlCall, [Sql.VARCHAR]) {
            msg = it ?: ''
        }

        return msg
    }

    def ricavaDovutiSoggetto(String codFiscale, String filtroStato) {

        def WEB_SERVICE = "ricercaDovutiSoggetto"

        def response = ""
        def param = ""

        param = "<RICERCA_DOVUTI_SOGGETTO>"

        switch(filtroStato ?: 'D') {     // D = Da Pagara, P = Pagato, T = Tutto
            default :
                break;
            case 'T' :
                break;
            case 'D' :
                param += "<STATO>DA_PAGARE</STATO>"
                break;
            case 'P' :
                param += "<STATO>PAGATO</STATO>"
                break;
        }
        param += "<ORDER>ASC</ORDER>"
        param += "</RICERCA_DOVUTI_SOGGETTO>"

        log.info "Parametri di chiamata: ${param}"

        param = Base64.encodeBase64String(param.getBytes())

        def callLogDetails = [codFiscale: codFiscale]
        response = inviaRichiestaSoap(soapXmlCodSoggetto(WEB_SERVICE, COD_ENTE(), codFiscale, param), callLogDetails)

        if (response.indexOf("<DATI>") > 0) {
            log.info "Risposta: ${response.substring(0, response.indexOf("<DATI>"))}"
        } else {
            log.info "Risposta: ${response}"
        }

        if (wsError(response)) {
            response = retrieveValue(response, DESCRIZIONE_ERRORE)
        }
        else {
            def datiStart = response.indexOf("<DATI>")
            def datiEnd = response.indexOf("</DATI>")
            if ((datiStart > 0) && (datiEnd > 0)) {
                response = response.substring(datiStart, datiEnd + 7)
            }
            else {
                response = ""
            }
        }

        return response
    }

    def leggiDovuto(String servizio, String idback) {

        def WEB_SERVICE = "leggiDovuto"

        def response = ""
        def param = ""

        param = "<LEGGI_DOVUTO>"
        param += "<CHIAVE>${idback}</CHIAVE>"
        param += "</LEGGI_DOVUTO>"

        log.info "Parametri di chiamata: ${param}"

        param = Base64.encodeBase64String(param.getBytes())

        def callLogDetails = [idBack: idback, servizio: servizio]
        response = inviaRichiestaSoap(soapXml(WEB_SERVICE, COD_ENTE(), servizio, param), callLogDetails)

        if (response.indexOf("<DATI>") > 0) {
            log.info "Risposta: ${response.substring(0, response.indexOf("<DATI>"))}"
        } else {
            log.info "Risposta: ${response}"
        }

        if (wsError(response)) {
            response = retrieveValue(response, DESCRIZIONE_ERRORE)
        }
        else {
            def datiStart = response.indexOf("<DATI>")
            def datiEnd = response.indexOf("</DATI>")
            if ((datiStart > 0) && (datiEnd > 0)) {
                response = response.substring(datiStart, datiEnd + 7)
            }
            else {
                response = ""
            }
        }

        return response
    }

    def dePagAbilitato() {
        return OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == PAGONLINE }?.valore == 'S'
    }

    def iuvValorizzatoRuolo(def codFiscale, def ruolo) {
        return iuvValorizzato(determinaDovutiRuolo(codFiscale, ruolo, null))
    }

    def iuvValorizzatoPratica(def idPratica) {
        return iuvValorizzato(determinaDovutiPratica(idPratica, null))
    }

    def iuvValorizzatoImposta(def codFiscale, def anno, def tipoTributo, def rata = null) {
        return iuvValorizzato(determinaDovutiImposta(codFiscale, anno, tipoTributo, rata, null))
    }

    def iuvSingoloRuolo(def codFiscale, def ruolo) {
        return iuvSingolo(determinaDovutiRuolo(codFiscale, ruolo, null))
    }

    def iuvSingoloPratica(def idPratica) {
        return dePagAbilitato() && iuvSingolo(determinaDovutiPratica(idPratica, null))
    }

    def iuvSingoloImposta(def codFiscale, def anno, def tipoTributo, def rata = null) {
        return dePagAbilitato() && iuvSingolo(determinaDovutiImposta(codFiscale, anno, tipoTributo, rata, null))
    }

    def recuperaStatoDePagRuolo(def codFiscale, def ruolo) {
        return recuperaStatoDePag(determinaDovutiRuolo(codFiscale, ruolo, null))
    }

    def recuperaStatoDePagPratica(def idPratica) {
        return recuperaStatoDePag(determinaDovutiPratica(idPratica, null))
    }

    def recuperaStatoDePagImposta(def codFiscale, def anno, def tipoTributo, def rata = null) {
        return recuperaStatoDePag(determinaDovutiImposta(codFiscale, anno, tipoTributo, rata, null))
    }

    def eliminaDovutoImposta(def codFiscale, def anno, def tipoTributo, def rata = null, def gruppoTributo = null, 
                                                                                                    def tipoOccupazione = 'P') {

        def message = ""

    /// def dovutiImposta = determinaDovutiImposta(codFiscale, anno, tipoTributo, rata)
        def dovutiImposta = determinaDovutiImposta(codFiscale, anno, tipoTributo, rata, 'NP', gruppoTributo, tipoOccupazione)

        dovutiImposta.each {
            if (message.replace("\n", "").empty) {
                message += (eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n")
            }
        }

        if (message.replace("\n", "").empty) {
            return ""
        } else {
            return message
        }
    }

    def eliminaDovutoRuolo(def codFiscale, def ruolo, def numRataMax = null) {

        def message = ""

        def dovutiRuolo = determinaDovutiRuolo(codFiscale, ruolo, 'NP', numRataMax)

        dovutiRuolo.each {
            if (message.replace("\n", "").empty) {
                message += eliminaDovuto(it.IDBACK, it.SERVIZIO) + "\n"
            }
        }

        if (message.replace("\n", "").empty) {
            return ""
        } else {
            return message
        }
    }

    def aggiornaDovutoImposta(def codFiscale, def anno, def tipoTributo, def rata = null) {

        def message = ""

        def dovuti = determinaDovutiImposta(codFiscale, anno, tipoTributo, rata)

        if (dovuti.isEmpty()) {
            return "Non sono presenti informazioni da passare a PagoPA.."
        }

        dovuti.each {
            if (message.replace("\n", "").empty) {
                message += aggiornaDovuto(it, it.SERVIZIO) + "\n"
            }
        }

        if (message.replace("\n", "").empty) {
            return ""
        } else {
            return message
        }
    }

    private recuperaStatoDePag(def records) {

        def totRecords = records?.size() ?: 0

        if (totRecords == 0) {
            // Non sono presenti record
            return null
        }

        // Se lo stato è uguale per tutti i record si restituisce lo stato
        def statiPresenti = records.collect { it.STATO_INVIO_RICEZIONE }.unique()
        if (statiPresenti.size() == 1) {
            def stato = STATI_DEPAG.find { k, v -> v.codice == statiPresenti[0] }
            if (stato == null) {
                throw new RuntimeException("Stato [${statiPresenti[0]}] non supportato.")
            } else {
                return [stato]
            }
        } else {
            // Nel caso di stati multipli si restituisce un vettore degli stati
            return statiPresenti.collectEntries {
                STATI_DEPAG.find { k, v -> v.codice == it }
            }
        }
    }

    private iuvValorizzato(def records) {
        // Devono essere presenti record e tutti devono avere lo iuv valorizzato.
        return records != null &&
                !records.empty &&
                records.count { it.COD_IUV == null } == 0
    }

    private iuvSingolo(def records) {
        // Deve essere presente un solo record e deve avere lo iuv valorizzato.
        return records != null && records.size() == 1 && records.first().COD_IUV != null
    }

    private inviaRichiestaSoap(def chiamata, def callLogDetails) {

        log.info "Invio chiamata..."
        log.info chiamata

        def response = null
        try {
            def client = new SOAPClient(WS_URL())
            client.authorization = new HTTPBasicAuthorization(WS_USER(), WS_PASS())
            response = client.send(chiamata)

            def value = retrieveValue(response.text, "param")

            def result = new String(Base64.decodeBase64(value), "UTF-8")

            logSuccess(response, callLogDetails)

            return result

        } catch (SOAPClientException e) {
            logError(e.request, e.response, e, callLogDetails)
            throw e
        } catch (Exception e) {
            logError(response?.httpRequest, response?.httpResponse, e, callLogDetails)
            throw e
        }
    }

    private logSuccess(SOAPResponse response, def callLogDetails = [:]) {
        wsLogService.saveDepagLog([
                requestMethod  : response.httpRequest.method,
                requestUrl     : response.httpRequest.url,
                requestContent : response.httpRequest.contentAsString,
                responseContent: response.text,
                idBack         : callLogDetails.idBack,
                codIuv         : callLogDetails.codIuv,
                codFiscale     : callLogDetails.codFiscale,
                servizio       : callLogDetails.servizio
        ])
    }

    private logError(HTTPRequest request, HTTPResponse response, Exception e, def callLogDetails = [:]) {
        log.error(e)
        wsLogService.saveDepagLog([
                requestMethod  : request?.method,
                requestUrl     : request?.url,
                requestContent : request?.contentAsString,
                exception      : e,
                responseContent: response?.contentAsString,
                idBack         : callLogDetails.idBack,
                codIuv         : callLogDetails.codIuv,
                codFiscale     : callLogDetails.codFiscale,
                servizio       : callLogDetails.servizio])
    }

    private def soapXml(def webService, def ente, def servizio, def param) {

        return """
            <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ws="ws.depag.finmatica.it">
            <soap:Header/>
                <soap:Body>
                    <ws:${webService}>
                        <ws:ente>${ente}</ws:ente>
                        <ws:servizio>${servizio}</ws:servizio>
                        <ws:param>${param}</ws:param>
                    </ws:${webService}>
                </soap:Body>
            </soap:Envelope>
        """
    }

    private def soapXmlCodSoggetto(def webService, def ente, def codSoggetto, def param) {

        return """
            <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ws="ws.depag.finmatica.it">
            <soap:Header/>
                <soap:Body>
                    <ws:${webService}>
                        <ws:ente>${ente}</ws:ente>
                        <ws:codiceSoggetto>${codSoggetto}</ws:codiceSoggetto>
                        <ws:param>${param}</ws:param>
                    </ws:${webService}>
                </soap:Body>
            </soap:Envelope>
        """
    }

    private def retrieveValue(def text, def tag) {

        final Pattern pattern = Pattern.compile("<${tag}>(.+?)</${tag}>", Pattern.DOTALL)
        final Matcher matcher = pattern.matcher(text)
        matcher.find()

        def value = matcher.group(1)

        return value

    }

    private def wsError(def response) {
        return response.contains(ESITO_OPERAZIONE_ERROR)
    }

    private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

        filtri = filtri ?: [:]

        if (!query || query.isEmpty()) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }
}
