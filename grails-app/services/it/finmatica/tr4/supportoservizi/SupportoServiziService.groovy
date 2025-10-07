package it.finmatica.tr4.supportoservizi

import grails.orm.PagedResultList
import groovy.sql.Sql
import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.Ad4Tr4Utente
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.Si4Competenze
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.supportoservizi.SupportoServiziWeb
import it.finmatica.tr4.dto.supportoservizi.SupportoServiziWebDTO
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer

class SupportoServiziService {

    static transactional = false

    def dataSource
    def sessionFactory

    def springSecurityService
    CommonService commonService
    DatiGeneraliService datiGeneraliService
    CompetenzeService competenzeService

    /**
     * Estrae elenco forniture da filtri
     */
    def getListaSupportoServizi(def filtri, int pageSize, int activePage, def sortBy = null) {

        PagedResultList elencoElementi = SupportoServiziWeb.createCriteria().list(max: pageSize, offset: pageSize * activePage) {

            createAlias("tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)
            createAlias("tipoAtto", "tiat", CriteriaSpecification.LEFT_JOIN)
			
			eq('utentePaUt', springSecurityService?.currentUser?.id)

            if (filtri.tipoTributo) {
                eq('tipoTributo.tipoTributo', filtri.tipoTributo)
            }

            if (filtri.annoDa) {
                ge("anno", filtri.annoDa as Short)
            }
            if (filtri.annoA) {
                le("anno", filtri.annoA as Short)
            }

            if (filtri.utenti && !filtri.utenti.empty) {
                and {
                    or {
                        'in'("utenteAssegnato", filtri.utenti)
                        'in'("utenteOperativo", filtri.utenti)
                    }
                }
            }

            if (filtri.oggettiNumDa) {
                ge('numOggetti', filtri.oggettiNumDa)
            }
            if (filtri.oggettiNumA) {
                le('numOggetti', filtri.oggettiNumA)
            }

            if (filtri.tipologia) {
                eq('tipologia', filtri.tipologia)
            }

            if (filtri.segnalazioniIniziali && !filtri.segnalazioniIniziali.empty) {
                'in'('segnalazioneIniziale', filtri.segnalazioniIniziali)
            }
            if (filtri.segnalazioniUltime && !filtri.segnalazioniUltime.empty) {
                'in'('segnalazioneUltima', filtri.segnalazioniUltime)
            }

            if (filtri.tipoImmobili) {
                if (filtri.tipoImmobili == 'F') {
                    eq('flagDiffFabbricatiCatasto', 'S')
                }
                if (filtri.tipoImmobili == 'T') {
                    eq('flagDiffTerreniCatasto', 'S')
                }
            }

            if (filtri.codFiscale) {
                ilike("codFiscale", filtri.codFiscale)
            }
            if (filtri.cognome) {
                ilike("cognomeRic", filtri.cognome)
            }
            if (filtri.nome) {
                ilike("nomeRic", filtri.nome)
            }
            if (filtri.tipoPersona) {
                if (filtri.tipoPersona == 'P.F.') {
                    eq('tipoPersona', 'PersonaFisica')
                }
                if (filtri.tipoPersona == 'P.G.') {
                    eq('tipoPersona', 'PersonaGiuridica')
                }
                if (filtri.tipoPersona == 'I.P.') {
                    eq('tipoPersona', 'IntestazioniParticolari')
                }
            }

            if (filtri.tipiAtto && !filtri.tipiAtto.empty) {
                'in'('tipoAtto.tipoAtto', filtri.tipiAtto)
            }

            if (filtri.differenzaImpostaDa) {
                ge('differenzaImposta', filtri.differenzaImpostaDa)
            }
            if (filtri.differenzaImpostaA) {
                le('differenzaImposta', filtri.differenzaImpostaA)
            }

            if (filtri.minPossessoDa) {
                ge('minPercPossesso', filtri.minPossessoDa)
            }
            if (filtri.minPossessoA) {
                le('minPercPossesso', filtri.minPossessoA)
            }

			if(sortBy && sortBy.size > 0) {
				sortBy.each { k, v ->
					if (v.verso) {
						order("${k}", "${v.verso}")
					}
				}
			}
			else {
				order('annoOrd', 'asc')
				order('tipoTributoOrd', 'asc')
				order('differenzaImpostaOrd', 'desc')
				order('codFiscaleOrd', 'asc')
				order('tipoTributo', 'asc')
				order('anno', 'asc')
			}
        }

        def descrTributi = getDescrizioneTipiTributo()

        def records = []

        String tipoPersona
        String tipoPersonaDescr
        def descrTributo

        elencoElementi.each {

            SupportoServiziWeb serv = it

            def record = [:]
			
			def dto = serv.toDTO(['tipoAtto', 'tipoTributo'])

            record.id = serv.id

            record.dto = dto

            record.tipoTributo = record.dto.tipoTributo.tipoTributo
            record.descrTributo = descrTributi.find { it.annoRif == serv.anno && it.tipoTributo == record.tipoTributo } ?.descrizione 

            record.descrStato = serv.stato?.descrizione ?: ''
            record.descrTipoAtto = serv.tipoAtto?.descrizione ?: ''

            record.descrLiq2Stato = serv.liq2Stato?.descrizione ?: ''
            record.descrLiq2TipoAtto = serv.liq2TipoAtto?.descrizione ?: ''

            switch (serv.tipoPersona) {
                default:
                    tipoPersona = serv.tipoPersona
                    tipoPersonaDescr = tipoPersona
                    break
                case 'PersonaFisica':
                    tipoPersona = 'P.F.'
                    tipoPersonaDescr = 'Persona Fisica'
                    break
                case 'PersonaGiuridica':
                    tipoPersona = 'P.G.'
                    tipoPersonaDescr = 'Persona Giuridica'
                    break
                case 'IntestazioniParticolari':
                    tipoPersona = 'I.P.'
                    tipoPersonaDescr = 'Intestazioni Particolari'
                    break
            }
            record.tipoPersona = tipoPersona
            record.tipoPersonaDescr = tipoPersonaDescr

            records << record
        }

        return [lista: records, totale: elencoElementi.totalCount]
    }

    /**
     * Conta record con utente assegnato
     */
    def conteggioUtentiAssegnati(def filtri) {

        def count = SupportoServizi.createCriteria().count() {

            if (filtri.tipoTributo) {
                if (filtri.tipoTributo != '%') {
                    eq('tipoTributo.tipoTributo', filtri.tipoTributo)
                } else {
                    'in'('tipoTributo.tipoTributo', ['ICI', 'TASI'])
                }
            }

            if (filtri.annoDa) {
                ge("anno", filtri.annoDa as Short)
            }
            if (filtri.annoA) {
                le("anno", filtri.annoA as Short)
            }

            isNotNull("utenteAssegnato")
        }

        return count
    }


    /**
     * Crea elenco descrizione tributi per anno
     */
    def getDescrizioneTipiTributo() {

        String sql = """
				SELECT	ANNO AS ANNO_RIF,
						TIPO_TRIBUTO AS TIPO_TRIBUTO,
						F_DESCRIZIONE_TITR(TIPO_TRIBUTO, ANNO) DESCR_TRIBUTO
				FROM	(SELECT ANNO, TIPO_TRIBUTO
						 FROM SUPPORTO_SERVIZI
						 GROUP BY ANNO, TIPO_TRIBUTO)
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def descrizioni = []

        results.each {

            def descrizione = [:]

            descrizione.annoRif = it['ANNO_RIF'] as Short
            descrizione.tipoTributo = it['TIPO_TRIBUTO'] as String
            descrizione.descrizione = it['DESCR_TRIBUTO'] as String

            descrizioni << descrizione
        }

        return descrizioni
    }

    /**
     * Ricava tipologie in Bonifiche per contribuente
     */
    def getElencoTipologie() {

        String sql = """
				SELECT DISTINCT TIPOLOGIA
				FROM SUPPORTO_SERVIZI
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def elenco = []
        results.each {
            elenco << (it['TIPOLOGIA'] as String)
        }

        return elenco
    }

    /**
     * Ricava Segnalazioni Iniziali in Bonifiche per contribuente
     */
    def getElencoSegnalazioniIni() {

        String sql = """
				SELECT DISTINCT SEGNALAZIONE_INIZIALE
				FROM SUPPORTO_SERVIZI
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def elenco = []
        results.each {
            elenco << (it['SEGNALAZIONE_INIZIALE'] as String)
        }

        return elenco
    }

    /**
     * Ricava Segnalazioni Iniziali in Bonifiche per contribuente
     */
    def getElencoSegnalazioniUlt() {

        String sql = """
				SELECT DISTINCT SEGNALAZIONE_ULTIMA
				FROM SUPPORTO_SERVIZI
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def elenco = []
        results.each {
            elenco << (it['SEGNALAZIONE_ULTIMA'] as String)
        }

        return elenco
    }

    /**
     * Ricava Tipi Atto in Bonifiche per contribuente
     */
    def getElencoTipiAtto() {

        String sql = """
				SELECT DISTINCT SUSE.TIPO_ATTO AS TIPO_ATTO, TIAT.DESCRIZIONE AS DESCRIZIONE
				FROM SUPPORTO_SERVIZI SUSE, TIPI_ATTO TIAT
				WHERE SUSE.TIPO_ATTO = TIAT.TIPO_ATTO
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def elenco = []
        results.each {

            Map elemento = [:]

            elemento.codice = (it['TIPO_ATTO'] as Long)
            elemento.descrizione = (it['DESCRIZIONE'] as String)

            elenco << elemento
        }

        return elenco
    }

    /**
     * Ricava tipi tributo in Bonifiche per contribuente
     */
    def getElencoTributi() {

        return [[codice: 'ICI', descrizione: 'IMU'],
                [codice: 'TASI', descrizione: 'TASI']]
    }

    /**
     * Ricava nomi univoci utenti in Bonifiche per contribuente per tipo tributo e accesso
     *
     * @param tipoTributo
     * @param accesso
     * @return
     */
    def getElencoUtentiPerTipoTributo(String tipoTributo, String accesso) {

        def utentiAbilitati = []

        if (datiGeneraliService.gestioneCompetenzeAbilitata()) {

            utentiAbilitati = Si4Competenze.createCriteria().list {
                createAlias("si4Abilitazioni", "abil", CriteriaSpecification.INNER_JOIN)
                createAlias("abil.si4TipiAbilitazione", "tiab", CriteriaSpecification.INNER_JOIN)

                if (accesso == competenzeService.TIPO_ABILITAZIONE.LETTURA) {
                    'in'("tiab.tipoAbilitazione", [competenzeService.TIPO_ABILITAZIONE.LETTURA, competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO])
                }
                if (accesso == competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO) {
                    eq("tiab.tipoAbilitazione", accesso)
                }
                projections {
                    property("utente.id", "utente")
                }

				if(tipoTributo) {
					eq("oggetto", tipoTributo)
				}
            }
        } else {
            /**
             Non si può fare, manca il campo "importanza" per l'oggetto AD4Utente visto che manca in AD4_V_UTENTI

             def utenti = Ad4Utente.createCriteria().list {
             sqlRestriction("""
             ((lower(utente) like('ads%')) or (importanza = 10))
             """)
             }
             **/
            String sql = """
				SELECT UTENTE
				FROM   AD4_UTENTI
				WHERE (LOWER(UTENTE) LIKE 'ads%') OR (IMPORTANZA = 10)
			"""

            Map filtri = [:]
            def results = eseguiQuery("${sql}", filtri, null, true)

            results.each {
                utentiAbilitati << (it['UTENTE'] as String)
            }
        }

        // Questo forza il filtro sugli utenti in caso di elenco vuoto
        utentiAbilitati << '---'

        List<Ad4Tr4Utente> lista = Ad4Tr4Utente.createCriteria().listDistinct {
            createAlias("dirittiAccesso", "diac", CriteriaSpecification.INNER_JOIN)
            createAlias("diac.tr4Istanza", "ista", CriteriaSpecification.INNER_JOIN)

            eq("tipoUtente", "U")
            eq("ista.userOracle", commonService.istanza)

            if (!utentiAbilitati.empty) {
                'in'("id", utentiAbilitati)
            }
            order("id")
        }

        def elenco = []
        lista.each {
            elenco << it.id
        }

        return elenco
    }

    /**
     * Ricava nomi univoci utenti in Bonifiche per contribuente
     */
    def getElencoUtenti() {

        String sql = """
				SELECT DISTINCT UTENTE
				FROM   (SELECT		UTENTE_ASSEGNATO AS UTENTE
						 FROM		SUPPORTO_SERVIZI
						WHERE		UTENTE_ASSEGNATO IS NOT NULL
						 GROUP BY	UTENTE_ASSEGNATO
						UNION
						SELECT		UTENTE_OPERATIVO AS UTENTE
						 FROM		SUPPORTO_SERVIZI
						WHERE		UTENTE_OPERATIVO IS NOT NULL
						 GROUP BY	UTENTE_OPERATIVO)
				ORDER BY UTENTE
		"""

        Map filtri = [:]
        def results = eseguiQuery("${sql}", filtri, null, true)

        def elenco = []
        results.each {
            elenco << (it['UTENTE'] as String)
        }

        return elenco
    }

    /**
     * Lancia procedura popolamento supporto
     */
    def popolaSupporto(def parametri, String user) {

        def report = [
                result : 0,
                message: null
        ]

        String tipoTributo = parametri.tipoTributo ?: '%'
        Short annoDa = parametri.annoDa ?: 0
        Short annoA = parametri.annoA ?: 9999
        String eliminazioneEP = (parametri.eliminazioneEP == 'S') ? 'S' : null

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call SUPPORTO_SERVIZI_PKG.POPOLA_TABELLONE(?,?,?,?,?,?,?)}',
                    [
                            tipoTributo,
                            annoDa,
                            annoA,
                            eliminazioneEP,
                            user,
                            Sql.DECIMAL,
                            Sql.VARCHAR
                    ],
                    { p_result, p_messaggio ->

                        report.result = p_result
                        report.message = p_messaggio
                    }
            )
        } catch (Exception e) {
            e.printStackTrace()
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20008")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20008: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }

        return report
    }

    /**
     * Lancia procedura assegnazione contribuenti
     */
    def assegnazioneContribuenti(def parametri) {

        def report = [
                result : 0,
                message: null
        ]

        String tipoTributo = parametri.tipoTributo
        String utente = parametri.utente
        Long numeroCasi = parametri.numeroCasi
        Long numOggettiDa = parametri.numOggettiDa
        Long numOggettiA = parametri.numOggettiA
        Double minPossessoDa = parametri.minPossessoDa
        Double minPossessoA = parametri.minPossessoA
		
		String flagLiqNonNot = parametri.flagLiqNonNot		// 'T' : Tutte, 'NN' : Non Numerate, NULL : No
		
		String flagFabbricati = parametri.flagFabbricati	// 'S' : Sì, 'N' : No, NULL : Ininfluente 
		String flagTerreni = parametri.flagTerreni
		String flagAreeFabbr = parametri.flagAreeFabbr
		
		String flagContitolari = parametri.flagContitolari

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call SUPPORTO_SERVIZI_PKG.ASSEGNA_CONTRIBUENTI(?,?,?,?,?,?,?,?,?,?,?,?,?,?)}',
                    [
						//	p_tipo_tributo             varchar2
						tipoTributo,
						//	p_utente                   varchar2
                        utente,
						//	p_numero_casi              number
                        numeroCasi,
						//	p_num_oggetti_da           number
                        numOggettiDa,
						//	p_num_oggetti_a            number
                        numOggettiA,
						//	p_da_perc_possesso         number
                        minPossessoDa,
						//	p_a_perc_possesso          number
                        minPossessoA,
						//	p_liq_da_trattare          varchar2
						flagLiqNonNot,
						//	p_fabbricati               varchar2
						flagFabbricati,
						//	p_terreni                  varchar2
						flagTerreni,
						//	p_aree                     varchar2
						flagAreeFabbr,
						//	p_contitolari              varchar2
						flagContitolari,
						//	p_result                   OUT number
                        Sql.DECIMAL,
						//	p_messaggio                OUT varchar2
						Sql.VARCHAR
                    ],
                    { p_result, p_messaggio ->

                        report.result = p_result
                        report.message = p_messaggio
                    }
            )
        }
        catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                throw e
            }
            report.message = message
            report.result = 2
        }

        return report
    }

    /**
     * Lancia procedura aggiorna posizioni
     */
    def aggiornaAssegnazione(def parametri) {

        def report = [
                result : 0,
                message: null
        ]

        String utente = parametri.utente

        try {

            Sql sql = new Sql(dataSource)
            sql.call('{call SUPPORTO_SERVIZI_PKG.AGGIORNA_ASSEGNAZIONE(?,?,?)}',
                    [
                            utente,
                            Sql.DECIMAL,
                            Sql.VARCHAR
                    ],
                    { p_result, p_messaggio ->

                        report.result = p_result
                        report.message = p_messaggio
                    }
            )
        }
        catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                throw e
            }
            report.message = message
            report.result = 2
        }

        return report
    }
	
	/*
	 * Modifica assegnazione elementi indicati
	 */
	def modificaAssegnazione(def elementi, String nomeUtente) {
		
		def report = [
			result : 0,
			message : null
		]
		
		SupportoServizi supportoServizi
		
		elementi.each {
			
			Long elementoId = it
			
			supportoServizi = SupportoServizi.get(elementoId)
			
			if(supportoServizi) {
				supportoServizi.utenteAssegnato = nomeUtente
				supportoServizi.save(flush: true, failOnError: true)
			}
		}
		
		return report
	}

    /**
     * Esegue query
     */
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
