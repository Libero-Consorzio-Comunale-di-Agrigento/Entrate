package it.finmatica.tr4.datiesterni.anagrafetributaria

import grails.transaction.Transactional
import it.finmatica.ad4.Ad4ComuneStorico
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.RecapitoSoggetto
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.TipoRecapito
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.servizianagraficimassivi.SamRispostaDTO
import it.finmatica.tr4.dto.servizianagraficimassivi.SamRispostaDittaDTO
import it.finmatica.tr4.dto.servizianagraficimassivi.SamRispostaPartitaIvaDTO
import it.finmatica.tr4.dto.servizianagraficimassivi.SamRispostaRapDTO
import it.finmatica.tr4.servizianagraficimassivi.SamRisposta
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaDitta
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaPartitaIva
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaRap
import org.hibernate.criterion.CriteriaSpecification
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class AnagrafeTributariaService {

    def sessionFactory
    def dataSource
    def springSecurityService


    CommonService commonService

    def listaTipologieCodifica = [
            [codice: '0', descrizione: 'Ante 01/01/2004'],
            [codice: '1', descrizione: 'ATECOFIN 2004'],
            [codice: '2', descrizione: 'ATECO 2007'],        /// (valida dal 1-1-2008)
    ]

    def listaqStatiAttivita = [
            [codice: 'A', descrizione: 'In attivita\''],
            [codice: 'C', descrizione: 'Cessata'],
            [codice: '', descrizione: '-'],
    ]

    Boolean inAnagrafeTributaria(String codFiscale) {

        String codFis = codFiscale ?: ''
        Boolean presente = false

        if (!codFis.isEmpty()) {

            def counter = SamRisposta.createCriteria().count() {
                createAlias("interrogazione", "sami", CriteriaSpecification.INNER_JOIN)
                ilike("sami.codFiscale", codFiscale)
            }
             presente = counter > 0
        }

        return presente
    }

    def getListaRisposte(String codFiscale) {

        List<SamRispostaDTO> sam = SamRisposta.createCriteria().list() {
            createAlias("interrogazione", "sami", CriteriaSpecification.INNER_JOIN)
            ilike("sami.codFiscale", codFiscale)
            order("interrogazione.id")
        }.toDTO(['codiceRitorno', 'interrogazione', 'fonteDomicilio', 'fonteDecesso', 'fonteSedeLegale', 'codiceCarica'])

        def lista = []

        sam.each {

            def record = [:]

            record.id = it.id
            record.codFiscaleInterrogazione = it.interrogazione.codFiscale
            record.codFiscaleIniziale = it.interrogazione.codFiscaleIniziale
            record.codFiscale = it.codFiscale

            record.cognome = it.cognome
            record.nome = it.nome
            record.denominazione = it.denominazione

            record.sesso = it.sesso
            record.dataNascita = it.dataNascita
            record.comuneNascita = it.comuneNascita
            record.provinciaNascita = it.provinciaNascita

            record.comuneDomicilio = it.comuneDomicilio
            record.provinciaDomicilio = it.provinciaDomicilio
            record.capDomicilio = it.capDomicilio
            record.indirizzoDomicilio = it.indirizzoDomicilio
            record.dataDomicilio = it.dataDomicilio

            record.dataDecesso = it.dataDecesso

            record.presenzaEstinzione = (it.presenzaEstinzione ?: '0') == '1'
            record.dataEstinzione = it.dataEstinzione

            record.partitaIva = it.partitaIva
            record.statoPartitaIva = it.statoPartitaIva
            record.codAttivita = it.codAttivita
            record.tipologiaCodifica = it.tipologiaCodifica
            record.dataInizioAttivita = it.dataInizioAttivita
            record.dataFineAttivita = it.dataFineAttivita

            record.comuneSedeLegale = it.comuneSedeLegale
            record.provinciaSedeLegale = it.provinciaSedeLegale
            record.capSedeLegale = it.capSedeLegale
            record.indirizzoSedeLegale = it.indirizzoSedeLegale
            record.dataSedeLegale = it.dataSedeLegale

            record.codFiscaleRap = it.codFiscaleRap
            record.dataDecorrenzaRap = it.dataDecorrenzaRap

            record.fonteDomicilio = it.fonteDomicilio?.fonte ?: ''
            record.fonteDomicilioDescr = it.fonteDomicilio?.descrizione ?: ''
            record.fonteDecesso = it.fonteDecesso?.fonteDecesso ?: ''
            record.fonteDecessoDescr = it.fonteDecesso?.descrizione ?: ''
            record.fonteSedeLegale = it.fonteSedeLegale?.fonte ?: ''
            record.fonteSedeLegaleDescr = it.fonteSedeLegale?.descrizione ?: ''

            record.codiceCarica = it.codiceCarica?.codCarica ?: ''
            record.codiceCaricaDescr = it.codiceCarica?.descrizione ?: ''

            record.statoPartitaIvaDescr = listaqStatiAttivita.find { it.codice == record.statoPartitaIva }?.descrizione ?: ''
            record.tipologiaCodificaDescr = listaTipologieCodifica.find { it.codice == record.tipologiaCodifica }?.descrizione ?: ''

            record.codiceRitorno = it.codiceRitorno?.codRitorno ?: ''
            record.codiceRitornoDescr = it.codiceRitorno?.descrizione ?: ''
            record.codiceRitornoEsito = it.codiceRitorno?.esito ?: ''

            String codiceRitornoEsitoDescr = ""

            switch (record.codiceRitornoEsito) {
                case 'OK':
                    codiceRitornoEsitoDescr = "OK"
                    break
                case 'KO':
                    codiceRitornoEsitoDescr = "KO"
                    break
                case 'NU':
                    codiceRitornoEsitoDescr = "esito OK come riscontro del soggetto, ma il codice fiscale non è utilizzabile"
                    break
                case 'RC':
                    codiceRitornoEsitoDescr = "riciclo"
                    break
                case 'RF':
                    codiceRitornoEsitoDescr = "riciclo dopo correzione errore formale"
                    break
                case 'RI':
                    codiceRitornoEsitoDescr = "riciclo dopo integrazione delle informazioni in input"
                    break
                case 'RZ':
                    codiceRitornoEsitoDescr = "riciclo dopo integrazione/correzione delle informazioni in input"
                    break
            }

            record.codiceRitornoEsitoDescr = codiceRitornoEsitoDescr

            record.documentoId = it.documentoId

            lista << record
        }

        return lista
    }

    def getListaPartiteIVA(Long rispostaId) {

        List<SamRispostaPartitaIvaDTO> sam = SamRispostaPartitaIva.createCriteria().list() {
            eq("risposta.id", rispostaId)
            order("id")
        }.toDTO(['codiceRitorno', 'tipoCessazione'])

        def lista = []

        sam.each {

            def record = [:]

            record.id = it.id
            record.rispostaId = it.risposta.id

            record.partitaIva = it.partitaIva
            record.codAttivita = it.codAttivita
            record.tipologiaCodifica = it.tipologiaCodifica
            record.stato = it.stato
            record.dataCessazione = it.dataCessazione
            record.partitaIvaConfluenza = it.partitaIvaConfluenza
            record.partitaIvaConfluenza = it.partitaIvaConfluenza

            record.tipoCessazione = it.tipoCessazione?.tipoCessazione ?: ''
            record.tipoCessazioneDescr = it.tipoCessazione?.descrizione ?: ''

            record.tipologiaCodificaDescr = listaTipologieCodifica.find { it.codice == record.tipologiaCodifica }?.descrizione ?: ''
            record.statoDescr = listaqStatiAttivita.find { it.codice == record.stato }?.descrizione ?: ''

            record.codiceRitorno = it.codiceRitorno?.codRitorno ?: ''
            record.codiceRitornoEsito = it.codiceRitorno?.esito ?: ''

            lista << record
        }

        return lista
    }

    def getListaDitte(Long rispostaId) {

        List<SamRispostaDittaDTO> sam = SamRispostaDitta.createCriteria().list() {
            eq("risposta.id", rispostaId)
            order("id")
        }.toDTO(['codiceRitorno', 'codiceCarica'])

        def lista = []

        sam.each {

            def record = [:]

            record.id = it.id
            record.rispostaId = it.risposta.id

            record.codFiscaleDitta = it.codFiscaleDitta
            record.dataDecorrenza = it.dataDecorrenza
            record.dataFineCarica = it.dataFineCarica

            record.codiceCarica = it.codiceCarica?.codCarica ?: ''
            record.codiceCaricaDescr = it.codiceCarica?.descrizione ?: ''

            record.codiceRitorno = it.codiceRitorno?.codRitorno ?: ''
            record.codiceRitornoEsito = it.codiceRitorno?.esito ?: ''

            lista << record
        }

        return lista
    }

    def getListaRappresentanti(Long rispostaId) {

        List<SamRispostaRapDTO> sam = SamRispostaRap.createCriteria().list() {
            eq("risposta.id", rispostaId)
            order("id")
        }.toDTO(['codiceRitorno', 'codiceCarica'])

        def lista = []

        sam.each {

            def record = [:]

            record.id = it.id
            record.rispostaId = it.risposta.id

            record.codFiscaleRap = it.codFiscaleRap
            record.dataDecorrenza = it.dataDecorrenza
            record.dataFineCarica = it.dataFineCarica

            record.codiceCarica = it.codiceCarica?.codCarica ?: ''
            record.codiceCaricaDescr = it.codiceCarica?.descrizione ?: ''

            record.codiceRitorno = it.codiceRitorno?.codRitorno ?: ''
            record.codiceRitornoEsito = it.codiceRitorno?.esito ?: ''

            lista << record
        }

        return lista
    }

    def getComune(def denominazioneComune) {

        def parametri = [:]

        parametri << ['p_comune': denominazioneComune]

        def query = """
							select *
							from ad4_comuni comu
							where upper(:p_comune) = comu.denominazione
							and rownum = 1
						   """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }

    def getProvincia(def siglaProvincia) {

        def parametri = [:]

        parametri << ['p_sigla': siglaProvincia]

        def query = """
							select *
							from ad4_province prov
							where prov.sigla = upper(:p_sigla)
							and rownum = 1
						   """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }

    def getSuffissoCivico(def indirizzo) {

        def parametri = [:]

        parametri << ['p_indirizzo': indirizzo]

        def query = """
							select substr(:p_indirizzo,
									  instr(translate(:p_indirizzo, '1234567890', '9999999999'), '9'),
									  decode(sign(4 - (length(substr(:p_indirizzo,
																	 instr(translate(:p_indirizzo,
																					 '1234567890',
																					 '9999999999'),
																		   '9'))) -
												  nvl(length(ltrim(translate(substr(:p_indirizzo,
																						 instr(translate(:p_indirizzo,
																										 '1234567890',
																										 '9999999999'),
																							   '9')),
																				  '1234567890',
																				  '9999999999'),
																		'9')),
														   0))),
											 -1,
											 4,
											 length(substr(:p_indirizzo,
														   instr(translate(:p_indirizzo,
																		   '1234567890',
																		   '9999999999'),
																 '9'))) -
											 nvl(length(ltrim(translate(substr(:p_indirizzo,
																			   instr(translate(:p_indirizzo,
																							   '1234567890',
																							   '9999999999'),
																					 '9')),
																		'1234567890',
																		'9999999999'),
															  '9')),
												 0))) civico,
							   ltrim(substr(:p_indirizzo,
											instr(translate(:p_indirizzo, '1234567890', '9999999999'),
												  '9') + length(substr(:p_indirizzo,
																	   instr(translate(:p_indirizzo,
																					   '1234567890',
																					   '9999999999'),
																			 '9'))) -
											nvl(length(ltrim(translate(substr(:p_indirizzo,
																			  instr(translate(:p_indirizzo,
																							  '1234567890',
																							  '9999999999'),
																					'9')),
																	   '1234567890',
																	   '9999999999'),
															 '9')),
												0),
											5),
									 ' /') suffisso
						   from dual
						   """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }

    def parseIndirizzo(def indirizzoRaw) {
        def words = indirizzoRaw.split("\\s+")

        def result = [indirizzo: '']
        def indexSuffisso
        def indexScala
        def indexInterno

        words.eachWithIndex { word, index ->
            if (!result.civico &&
                    (word.toUpperCase() == 'SNC' || word.isNumber()) &&
                    word.size() <= 6) {
                indexSuffisso = word.toUpperCase() == 'SNC' ? null : index + 1
                result.civico = word
                return
            }
            if (!result.suffisso && index == indexSuffisso &&
                    (word.toUpperCase() ==~ /[A-Z]/ || word.toUpperCase() in ['BIS', 'TRIS', 'QUATER', 'QUINQUIES'])) {
                result.suffisso = word
                return
            }
            if (!result.interno && word.toUpperCase() == 'INT') {
                indexInterno = index + 1
                return
            }
            if (!result.interno && index == indexInterno && word.isNumber()) {
                result.interno = word
                return
            }
            if (!result.scala && word.toUpperCase() == 'SC') {
                indexScala = index + 1
                return
            }
            if (!result.scala && index == indexScala) {
                result.scala = word
                return
            }

            result.indirizzo += word + ' '
        }

        result.indirizzo = result.indirizzo.trim()
        result.civico = result.civico == 'SNC' ? null : result.civico

        return result
    }

    def cambioCodiceFiscale(def oldCodFiscale, def newCodFiscale) {

        def query = """
                    update contribuenti
                    set cod_fiscale = :cod_fiscale_at
                    where cod_fiscale = :old_cod_fiscale
                    """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)

        sqlQuery.setString("cod_fiscale_at", newCodFiscale)
        sqlQuery.setString("old_cod_fiscale", oldCodFiscale)
        sqlQuery.executeUpdate()
    }

    def aggiornaSoggetto(Soggetto soggetto) {
        soggetto.save(failOnError: true, flush: true)
    }

    def storicizzaIndirizzoSoggetto(def oldSoggetto) {

        def dataOdierna = new Date()

        // Ottengo il Tipo Recapito 1 - INDIRIZZO
        def tipoRecapito = TipoRecapito.findById(1)

        // Ottengo la lista di recapiti di tipo INDIRIZZO non chiusi del soggetto
        def listaRecapitiIndirizzo = RecapitoSoggetto.createCriteria().list {
            eq("soggetto.id", oldSoggetto.id)
            eq("tipoRecapito", tipoRecapito)
        }.findAll {
            it.al == null
        }

        // Chiudo ognuno di questi recapiti alla data odierna - 1
        listaRecapitiIndirizzo.each {
            it.al = dataOdierna.minus(1)

            // Aggiorno le note, se erano già presenti vengono concatenate alla fine
            if (it.note == null) {
                it.note = "Agg. automatico da Anagrafe Tributaria del ${dataOdierna.format("dd/MM/yyyy")}"
            } else {
                it.note = "Agg. automatico da Anagrafe Tributaria del ${dataOdierna.format("dd/MM/yyyy")} - " + it.note
            }

            it.save(failOnError: true, flush: true)
        }

        // Creo un nuovo recapito contenente i dati del Soggetto prima dell'aggiornamento
        RecapitoSoggetto newRecapito = new RecapitoSoggetto()
        newRecapito.tipoRecapito = tipoRecapito
        newRecapito.soggetto = oldSoggetto
        newRecapito.dal = dataOdierna.minus(1)
        newRecapito.al = dataOdierna.minus(1)
        newRecapito.tipoTributo = null
        newRecapito.comuneRecapito = oldSoggetto.comuneResidenza
        newRecapito.cap = oldSoggetto.cap
		newRecapito.archivioVie = oldSoggetto.archivioVie
        newRecapito.descrizione = oldSoggetto.denominazioneVia
        newRecapito.numCiv = oldSoggetto.numCiv
        newRecapito.suffisso = oldSoggetto.suffisso
        newRecapito.utente = springSecurityService.currentUser
        newRecapito.note = "Agg. automatico da Anagrafe Tributaria del ${dataOdierna.format("dd/MM/yyyy")}"
        newRecapito.lastUpdated = new Date()

        newRecapito.save(failOnError: true, flush: true)
    }

    def getComuneNascita(def denominazione, def provincia, def dataNascita, Boolean silent = false) {

        def comuneStorico = getComuneStato(denominazione, provincia, dataNascita, false, false)
        if (!comuneStorico) {
            comuneStorico = getComuneStato(denominazione, provincia, dataNascita, true, false)
            if (!comuneStorico) {
                comuneStorico = getComuneStato(denominazione, provincia, dataNascita, false, true)
                if (!comuneStorico) {
                    comuneStorico = getComuneStato(denominazione, provincia, dataNascita, true, true)
                }
            }
        }
        if (!comuneStorico) {
            if(!silent) {
                throw new Exception("Impossibile trovare luogo di nascita con denominazione ${denominazione}, provincia ${provincia}, data di nascita ${dataNascita}")
            }
        }
        return comuneStorico?.comuneTr4?.toDTO()
    }

    def getComuneResidenza(def denominazione, def provincia, Boolean silent = false) {

        def comuneResidenza = null

        def comuni = Ad4ComuneTr4.createCriteria().list {
            createAlias('ad4Comune', 'comu', CriteriaSpecification.INNER_JOIN)
            createAlias('comu.provincia', 'prov', CriteriaSpecification.INNER_JOIN)
            eq('comu.denominazione', denominazione)
            isNull('comu.dataSoppressione')
            if (provincia) {
                eq('prov.sigla', provincia)
            }
        }

        if(comuni.size() > 0) {
            comuneResidenza = comuni[0]
        }

        if (!comuneResidenza) {
            if(!silent) {
                throw new Exception("Impossibile trovare comune di domicilio con denominazione ${denominazione} e provincia ${provincia}")
            }
        }

        return comuneResidenza?.toDTO()
    }

    def getComuneStato(def denominazione, def provinciaStato, def dataRiferimento, Boolean stato, Boolean like) {

        def comune = null
        
        def comuni = Ad4ComuneStorico.createCriteria().list {
            createAlias('comuneTr4', 'comuTr4', CriteriaSpecification.INNER_JOIN)
            createAlias('comuTr4.ad4Comune', 'comu', CriteriaSpecification.INNER_JOIN)

            if(stato) {
                createAlias('comu.stato', 'stat', CriteriaSpecification.INNER_JOIN)
            }
            else {
                createAlias('comu.provincia', 'prov', CriteriaSpecification.INNER_JOIN)
            }

            if(stato) {
                eq('comune', 0)
            }

            if(like) {
			    ilike("comu.denominazione", denominazione + " %")
            }
            else {
                eq('comu.denominazione', denominazione)
            }

            if (dataRiferimento) {
                le('dal', dataRiferimento)
                or {
                    isNull('al')
                    ge('al', dataRiferimento)
                }
            } else {
                isNull('al')
            }
            if (provinciaStato) {
                if(stato) {
                    if(provinciaStato != 'EE') {
                        eq('stat.sigla', provinciaStato)
                    }
                }
                else {
                    eq('prov.sigla', provinciaStato)
                }
            }
            order('al', 'desc')
            order('dal', 'desc')
        }

        if(comuni.size() > 0) {
            comune = comuni[0]
        }

        return comune
    }
}
