package it.finmatica.tr4.bonificaDati.nonDichiarati

import grails.transaction.Transactional
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.oggetti.OggettiService
import org.hibernate.transform.AliasToEntityMapResultTransformer

import java.text.DecimalFormat

@Transactional
class BonificaNonDichiaratiService {

    static transactional = false

    def dataSource

    def sessionFactory

    def springSecurityService
    OggettiService oggettiService

    ///
    /// *** Elabora lista immobili
    ///
    def impostaRenditaImmobili(def listaImmobili, def cessatiDopo, def seCessati, boolean sovrascriviIntersecati) {

        def flagCessatti = seCessati ? 'S' : 'N'

        listaImmobili.each {

            if ((it.status == 0) ||
                    ((sovrascriviIntersecati != false) && (it.status == 1))) {

                impostaRenditaImmobile(it, cessatiDopo, flagCessatti, sovrascriviIntersecati)
            }
        }
    }

    private impostaRenditaImmobile(def immobile, def cessatiDopo, def flagCessatti, boolean sovrascriviIntersecati) {

        try {

            def controllo = oggettiService.controlloRiog(immobile.idImmobile, immobile.idOggetto, immobile.tipoImmobile)
            if ((controllo == 1) && sovrascriviIntersecati) {
                controllo = 0
            }

            switch (controllo) {
                default:
                    break
                case 0:
                    def result = oggettiService.inserimentoOggettiRendite(immobile.idImmobile, immobile.idOggetto, immobile.tipoImmobile, cessatiDopo, flagCessatti)
                    ///
                    if (result == null) {
                        immobile.status = 9
                        immobile.message = ""
                    } else {
                        immobile.status = 2
                        immobile.message = result.toString()
                    }
                    break
                case 1:
                    immobile.status = 1
                    immobile.message = "Esistono periodi intersecati"
                    break
                case 2:
                    immobile.status = 2
                    immobile.message = "Non esistono dati da acquisire"
                    break
            }
        }
        catch (Exception e) {

            if (e instanceof Application20999Error) {

                immobile.status = 2
                immobile.message = e.getMessage()
            } else {
                immobile.status = 3
                immobile.message = e.getMessage()
            }
        }
    }

    ///
    /// *** Prepara lista immobili da parametri ricerca
    ///
    def preparaListaImmobili(def parametriRicerca, def listaSoggetti) {

        def parametriNow = parametriRicerca.clone()
        parametriNow.sintesi = true

        def elencoOggetti = getOggettiNonDichiarati(parametriNow)
        def oggettiDaElaborare = elencoOggetti.records

        def listaImmobili = []

        oggettiDaElaborare.each {

            def idSoggetto = (it.idSoggetto as BigDecimal)

            def idImmobile = (it.idImmobile as BigDecimal)
            def tipoImmobile = it.tipoImmobile

            def inList = listaImmobili.findAll { it.idImmobile == idImmobile && it.tipoImmobile == tipoImmobile }

            if (inList.size() == 0) {

                def immobile = [:]

                immobile.idImmobile = idImmobile
                immobile.tipoImmobile = tipoImmobile

                immobile.idOggetto = (it.idOggetto != 0) ? it.idOggetto : null
                immobile.idSoggetto = idSoggetto

                immobile.estremiCatasto = it.estremiCatasto.replaceAll(/ *$/, '')
                immobile.sezione = it.sezione
                immobile.foglio = it.foglio
                immobile.numero = it.numero
                immobile.subalterno = it.subalterno

                immobile.categoria = it.categoria
                immobile.classe = it.classe
                immobile.rendita = it.rendita


                immobile.codFiscale = listaSoggetti.find { it.idSoggetto == idSoggetto }?.codFiscale

                immobile.dirittoEsteso = it.dirittoEsteso

                immobile.status = 0
                immobile.message = null

                listaImmobili << immobile
            }
        }

        return [totaleImmobili: oggettiDaElaborare.size, listaImmobili: listaImmobili]
    }

    ///
    /// Prepara lista immobili da elenco oggetti
    ///
    def preparaListaImmobiliDaOggetti(def parametriRicerca) {

        def elencoOggetti = getElencoImmobiliDaOggetti(parametriRicerca)
        def oggettiDaElaborare = elencoOggetti.records

        def listaImmobili = []

        oggettiDaElaborare.each {

            if (it.idOggetto != 0) {

                def immobile = [:]

                def idSoggetto = (it.idSoggetto as BigDecimal)

                immobile.idImmobile = it.idImmobile
                immobile.idOggetto = it.idOggetto
                immobile.idSoggetto = idSoggetto

                immobile.estremiCatasto = it.estremiCatasto.replaceAll(/ *$/, '')
                immobile.sezione = it.sezione
                immobile.foglio = it.foglio
                immobile.numero = it.numero
                immobile.subalterno = it.subalterno

                immobile.categoria = it.categoria
                immobile.classe = it.classe
                immobile.rendita = it.rendita

                immobile.tipoImmobile = it.tipoImmobile

                immobile.codFiscale = ""
                immobile.dirittoEsteso = ""

                immobile.status = 0
                immobile.message = null

                listaImmobili << immobile
            }
        }

        return [totaleImmobili: oggettiDaElaborare.size, listaImmobili: listaImmobili]
    }


    def getSoggettiLegatiNonDichiarati(def parametriRicerca, def codiceFiscale, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        String sql = ""
        String sqlTotali = ""
        String sqlLista = ""
        String sqlFiltri = ""
        String sqlListaFiltri = ""

        def filtri = [:]

        filtri << ['anno': (parametriRicerca.anno as String)]

        if (parametriRicerca.diritti) {
            def diritti = ""
            parametriRicerca.diritti.each() {
                if (diritti.length() > 0) diritti += ", "
                diritti += "'" + it + "'"
            }
            sqlFiltri += " AND ICUR.COD_TITOLO IN(${diritti})"
        }

        if (codiceFiscale) {
            filtri << ['codFiscale': codiceFiscale.trim().toUpperCase()]
            sqlFiltri += " AND COSO.COD_FISCALE LIKE(:codFiscale)"
        }

        switch (parametriRicerca.tipoSoggetto) {
            default:
                break
            case -1:
                break
            case 0:
                sqlListaFiltri = " AND (NVL(CONT_SOGG.NI,0)) = 0"
                break
            case 1:
                sqlListaFiltri = " AND (NVL(CONT_SOGG.NI,0)) <> 0"
                break
        }

        sql = """
				    SELECT  ANAG.ID_SOGGETTO_RIC,
							ANAG.COGNOME_NOME_RIC,
							ANAG.COD_FISCALE_RIC,
							(SELECT CSCC.COD_FISCALE 
									FROM CONTRIBUENTI_SOGGETTI_CC CSCC 
								   WHERE CSCC.COD_FISCALE_ABB = COSO.COD_FISCALE 
									 AND CSCC.COD_FISCALE <> CSCC.COD_FISCALE_ABB) COD_FISCALE_CONTR,ANAG.DATA_NASCITA DATA_NASCITA,
							ANAG.LUOGO_NASCITA,
							ANAG.SEDE,
							ANAG.DES_COMUNE_NAS,
							ANAG.SIGLA_PROVINCIA_NAS,
							ANAG.DES_COMUNE_SEDE,
							ANAG.SIGLA_PROVINCIA_SEDE,
							0 NI_SOGG,
							0 NI_CONT
				     FROM
                         IMMOBILI_SOGGETTO_CC ICUR,
                         CC_SOGGETTI SOGG,
                         PROPRIETARI_ANAGRAFE_CATASTO ANAG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE
                           ICUR.PROPRIETARIO   = SOGG.ID_SOGGETTO_RIC
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                           AND COSO.COD_FISCALE_ABB  = NVL(ANAG.COD_FISCALE_RIC,ANAG.ID_SOGGETTO_RIC)
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL 
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
                           AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')  
						   ${sqlFiltri}
				UNION
					SELECT 	ANAG.ID_SOGGETTO_RIC,
							ANAG.COGNOME_NOME_RIC,
							ANAG.COD_FISCALE_RIC,
							(SELECT CSCC.COD_FISCALE 
										FROM CONTRIBUENTI_SOGGETTI_CC CSCC 
									   WHERE CSCC.COD_FISCALE_ABB = COSO.COD_FISCALE 
										 AND CSCC.COD_FISCALE <> CSCC.COD_FISCALE_ABB) COD_FISCALE_CONTR,ANAG.DATA_NASCITA DATA_NASCITA,
							ANAG.LUOGO_NASCITA,
							ANAG.SEDE,
							ANAG.DES_COMUNE_NAS,
							ANAG.SIGLA_PROVINCIA_NAS,
							ANAG.DES_COMUNE_SEDE,
							ANAG.SIGLA_PROVINCIA_SEDE,
							0 NI_SOGG,
							0 NI_CONT
					 FROM
							IMMOBILI_CATASTO_TERRENI ICUR,
						 	CC_SOGGETTI SOGG,
						 	PROPRIETARI_ANAGRAFE_CATASTO ANAG,
						 	CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE  ICUR.ID_SOGGETTO = SOGG.ID_SOGGETTO                               
                            AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                            AND COSO.COD_FISCALE_ABB = NVL(ANAG.COD_FISCALE_RIC,ANAG.ID_SOGGETTO_RIC)
                            AND ICUR.ESTREMI_CATASTO IS NOT NULL
                               AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
							AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                            AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                            AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                            AND  ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                            AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy') 
					${sqlFiltri}
			"""

        sqlLista = """
				SELECT 	ID_SOGGETTO_RIC,
						COGNOME_NOME_RIC,
						COD_FISCALE_RIC,
						COD_FISCALE_CONTR,
						DATA_NASCITA,
						LUOGO_NASCITA,
						SEDE,
						DES_COMUNE_NAS,
						SIGLA_PROVINCIA_NAS,
						DES_COMUNE_SEDE,
						SIGLA_PROVINCIA_SEDE,
						NVL(CONT_SOGG.NI,0) NI_SOGG,
						NVL(CONT_CONT.NI,0) NI_CONT
				FROM
					($sql),
					CONTRIBUENTI CONT_SOGG,
					CONTRIBUENTI CONT_CONT
				WHERE
					COD_FISCALE_RIC = CONT_SOGG.COD_FISCALE(+) AND
					COD_FISCALE_CONTR = CONT_CONT.COD_FISCALE(+)
					${sqlListaFiltri}
				ORDER BY
					COGNOME_NOME_RIC,
					COD_FISCALE_RIC
		"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def results = eseguiQuery("${sqlLista}", filtri, params)
        def records = []
        String prov

        results.each {

            def record = [:]

            record.idSoggetto = it['ID_SOGGETTO_RIC']
            record.codFiscale = it['COD_FISCALE_RIC']
            record.codFiscaleContr = it['COD_FISCALE_CONTR']
            record.cognomeNome = it['COGNOME_NOME_RIC']
            record.sede = it['SEDE']
            record.dataNascita = it['DATA_NASCITA']?.format("dd/MM/yyyy")
            record.luogoNascita = it['LUOGO_NASCITA']

            record.desLuogoNascita = it['DES_COMUNE_NAS'] ?: ''
            prov = it['SIGLA_PROVINCIA_NAS']
            if (prov) {
                record.desLuogoNascita += ' (' + prov.toString() + ')'
            }

            record.desSede = it['DES_COMUNE_SEDE'] ?: ''
            prov = it['SIGLA_PROVINCIA_SEDE']
            if (prov) {
                record.desSede += ' (' + prov.toString() + ')'
            }

            record.niSogg = it['NI_SOGG']
            record.niCont = it['NI_CONT']
            record.ni = record.niSogg
            record.contribuente = (record.ni != 0) ? 'S' : 'N'

            records << record
        }

        def totals = [
                totalCount: records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    ///
    /// *** Estra elenco soggetti con immobili non dichiarati
    ///
    def getSoggettiConNonDichiarati(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        String sql = ""
        String sqlTotali = ""
        String sqlLista = ""
        String sqlFiltri = ""
        String sqlFiltriFabbricato = ""
        String sqlFiltriTerreno = ""

        String sqlFiltriCU = ""
        String sqlFiltriCT = ""
        String sqlListaFiltri = ""

        def filtri = [:]

        filtri << ['anno': (parametriRicerca.anno as String)]

        if (parametriRicerca.tipoImmobile == 'T'){
            sqlFiltriTerreno += " AND 1 = 0 "
        }

        if (parametriRicerca.tipoImmobile == 'F'){
            sqlFiltriFabbricato += " AND 1 = 0 "
        }

        if (parametriRicerca.diritti) {
            def diritti = ""
            parametriRicerca.diritti.each() {

                if (diritti.length() > 0) diritti += ", "
                diritti += "'" + it + "'"
            }
            sqlFiltri += " AND ICUR.COD_TITOLO IN(${diritti})"
        }

        if (parametriRicerca.idSoggetto) {
            filtri << ['idSoggetto': parametriRicerca.idSoggetto]
            sqlFiltri += " AND NVL(SOGG.ID_SOGGETTO_RIC,0) = :idSoggetto"
        }
        if (parametriRicerca.cognome) {
            filtri << ['cognome': parametriRicerca.cognome.trim().toUpperCase()]
            sqlFiltri += " AND ANAG.COGNOME LIKE(:cognome)"
        }
        if (parametriRicerca.nome) {
            filtri << ['nome': parametriRicerca.nome.trim().toUpperCase()]
            sqlFiltri += " AND ANAG.NOME LIKE(:nome)"
        }
        if (parametriRicerca.codFiscale) {
            filtri << ['codFiscale': parametriRicerca.codFiscale.trim().toUpperCase()]
            sqlFiltri += " AND COSO.COD_FISCALE LIKE(:codFiscale)"
        }

        switch (parametriRicerca.tipoSoggetto) {
            default:
                break
            case -1:
                break
            case 0:
                sqlListaFiltri = " AND (NVL(CONT_SOGG.NI,0)) = 0"
                break
            case 1:
                sqlListaFiltri = " AND (NVL(CONT_SOGG.NI,0)) <> 0"
                break
        }

        sql = """
					 SELECT  ANAG.ID_SOGGETTO_RIC,
							 ANAG.COGNOME_NOME_RIC,
							 ANAG.COD_FISCALE_RIC,
							 (SELECT CSCC.COD_FISCALE 
                                FROM CONTRIBUENTI_SOGGETTI_CC CSCC 
                               WHERE CSCC.COD_FISCALE_ABB = COSO.COD_FISCALE 
                                 AND CSCC.COD_FISCALE <> CSCC.COD_FISCALE_ABB) COD_FISCALE_CONTR,
							 ANAG.DATA_NASCITA DATA_NASCITA,
							 ANAG.LUOGO_NASCITA,
							 ANAG.SEDE,
							 ANAG.DES_COMUNE_NAS,
							 ANAG.SIGLA_PROVINCIA_NAS,
							 ANAG.DES_COMUNE_SEDE,
							 ANAG.SIGLA_PROVINCIA_SEDE,
							 0 NI_SOGG,
							 0 NI_CONT
					 FROM
                         IMMOBILI_SOGGETTO_CC ICUR,
                         CC_SOGGETTI SOGG,
                         PROPRIETARI_ANAGRAFE_CATASTO ANAG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
					 WHERE ICUR.PROPRIETARIO       = SOGG.ID_SOGGETTO_RIC
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC)    = COSO.COD_FISCALE_ABB
                           AND COSO.COD_FISCALE     = NVL(ANAG.COD_FISCALE_RIC,ANAG.ID_SOGGETTO_RIC)
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
						   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
						   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')  
						   ${sqlFiltri}
                           ${sqlFiltriTerreno} 
					 UNION
						 SELECT  ANAG.ID_SOGGETTO_RIC,
								 ANAG.COGNOME_NOME_RIC,
								 ANAG.COD_FISCALE_RIC,
								 (SELECT CSCC.COD_FISCALE 
									FROM CONTRIBUENTI_SOGGETTI_CC CSCC 
								   WHERE CSCC.COD_FISCALE_ABB = COSO.COD_FISCALE 
									 AND CSCC.COD_FISCALE <> CSCC.COD_FISCALE_ABB) COD_FISCALE_CONTR,
								 ANAG.DATA_NASCITA DATA_NASCITA,
								 ANAG.LUOGO_NASCITA,
								 ANAG.SEDE,
								 ANAG.DES_COMUNE_NAS,
								 ANAG.SIGLA_PROVINCIA_NAS,
								 ANAG.DES_COMUNE_SEDE,
								 ANAG.SIGLA_PROVINCIA_SEDE,
								 0 NI_SOGG,
								 0 NI_CONT
					 	FROM
                             IMMOBILI_CATASTO_TERRENI ICUR,
                             CC_SOGGETTI SOGG,
                             PROPRIETARI_ANAGRAFE_CATASTO ANAG,
                             CONTRIBUENTI_SOGGETTI_CC COSO
                         WHERE ICUR.ID_SOGGETTO = SOGG.ID_SOGGETTO                               
                               AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                               AND COSO.COD_FISCALE     = NVL(ANAG.COD_FISCALE_RIC,ANAG.ID_SOGGETTO_RIC)
                               AND ICUR.ESTREMI_CATASTO IS NOT NULL
                               AND ICUR.ESTREMI_CATASTO NOT IN
                               (SELECT DISTINCT O.ESTREMI_CATASTO
								  FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
								  WHERE
									 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
									 OGIM.TIPO_TRIBUTO = 'ICI' AND
									 OGPR.OGGETTO = O.OGGETTO AND
									 OGIM.ANNO = :anno AND
									 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
							   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
							   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                               AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                               AND  ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                               AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy') 
					           ${sqlFiltri}
                               ${sqlFiltriFabbricato}
		 """

        sqlLista = """
						 SELECT  ID_SOGGETTO_RIC,
								 COGNOME_NOME_RIC,
								 COD_FISCALE_RIC,
								 COD_FISCALE_CONTR,
								 DATA_NASCITA,
								 LUOGO_NASCITA,
								 SEDE,
								 DES_COMUNE_NAS,
								 SIGLA_PROVINCIA_NAS,
								 DES_COMUNE_SEDE,
								 SIGLA_PROVINCIA_SEDE,
								 NVL(CONT_SOGG.NI,0) NI_SOGG,
								 NVL(CONT_CONT.NI,0) NI_CONT
						 FROM
							 ($sql),
							 CONTRIBUENTI CONT_SOGG,
							 CONTRIBUENTI CONT_CONT
						 WHERE
							 COD_FISCALE_RIC = CONT_SOGG.COD_FISCALE(+) AND
							 COD_FISCALE_CONTR = CONT_CONT.COD_FISCALE(+)
							 ${sqlListaFiltri}
						 ORDER BY
						 COGNOME_NOME_RIC,
						 COD_FISCALE_RIC
						 """

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def results = eseguiQuery("${sqlLista}", filtri, params, true)

        def records = []

        String prov

        results.each {

            def record = [:]

            record.idSoggetto = it['ID_SOGGETTO_RIC']
            record.codFiscale = it['COD_FISCALE_RIC']
            record.codFiscaleContr = it['COD_FISCALE_CONTR']
            record.cognomeNome = it['COGNOME_NOME_RIC']
            record.sede = it['SEDE']
            record.dataNascita = it['DATA_NASCITA']?.format("dd/MM/yyyy")
            record.luogoNascita = it['LUOGO_NASCITA']

            record.desLuogoNascita = it['DES_COMUNE_NAS'] ?: ''
            prov = it['SIGLA_PROVINCIA_NAS']
            if (prov) {
                record.desLuogoNascita += ' (' + prov.toString() + ')'
            }

            record.desSede = it['DES_COMUNE_SEDE'] ?: ''
            prov = it['SIGLA_PROVINCIA_SEDE']
            if (prov) {
                record.desSede += ' (' + prov.toString() + ')'
            }

            record.niSogg = it['NI_SOGG']
            record.niCont = it['NI_CONT']

            record.ni = record.niSogg
            /// A qualcuno crea confusione, prendo solo l'NI dal match con il CF soggetto
            record.contribuente = (record.ni != 0) ? 'S' : 'N'

            records << record
        }

        def totals = [
                totalCount: records.size(),
        ]
        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    ///
    /// *** Estrae elenco immobili non dichiarati per CF
    ///
    def getOggettiNonDichiarati(def parametriRicerca, def soggettoSelezionato = null, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        String sql = ""
        String sqlTotali = ""
        String sqlFiltriCU = ""
        String sqlFiltriCT = ""

        String filtroElementi

        def sintesi = (parametriRicerca.sintesi != null) ? parametriRicerca.sintesi : false

        def filtri = [:]

        filtri << ['anno': (parametriRicerca.anno as String)]

        if (parametriRicerca.idSoggetti) {

            filtroElementi = preparaElencoID(parametriRicerca.idSoggetti, "SOGG.ID_SOGGETTO_RIC")
            sqlFiltriCU += " AND (" + filtroElementi + ") "
            sqlFiltriCT += " AND (" + filtroElementi + ") "
        }

        if (parametriRicerca.immobili) {

            filtroElementi = preparaElencoID(parametriRicerca.immobili, "ICUR.CONTATORE")
            sqlFiltriCU += " AND (" + filtroElementi + ") "
        }
        if (parametriRicerca.immobili) {

            filtroElementi = preparaElencoID(parametriRicerca.immobili, "ICUR.ID_IMMOBILE")
            sqlFiltriCT += " AND (" + filtroElementi + ") "
        }

        if (parametriRicerca.diritti) {

            def diritti = ""
            parametriRicerca.diritti.each() {

                if (diritti.length() > 0) diritti += ", "
                diritti += "'" + it + "'"
            }
            sqlFiltriCU += " AND ICUR.COD_TITOLO IN(${diritti})"
            sqlFiltriCT += " AND ICUR.COD_TITOLO IN(${diritti})"
        }
        /*
        if(parametriRicerca.idSoggetto != null) {
            filtri << ['idSoggetto': parametriRicerca.idSoggetto]
            sqlFiltriCU += " AND ANAG.ID_SOGGETTO_RIC = :idSoggetto";
            sqlFiltriCT += " AND ANAG.ID_SOGGETTO_RIC = :idSoggetto";
        }
        */
        if (parametriRicerca.idSoggetto != null) {
            sqlFiltriCU += " AND SOGG.ID_SOGGETTO_RIC in (" + parametriRicerca.idSoggetto + ")"
            sqlFiltriCT += " AND SOGG.ID_SOGGETTO_RIC in (" + parametriRicerca.idSoggetto + ")"
        }
        if (parametriRicerca.immobile) {
            filtri << ['immobile': parametriRicerca.immobile]
            sqlFiltriCU += " AND ICUR.CONTATORE = :immobile"
            sqlFiltriCT += " AND ICUR.ID_IMMOBILE = :immobile"
        }

        if (parametriRicerca.indirizzo) {
            filtri << ['indirizzo': parametriRicerca.indirizzo + ""]
            sqlFiltriCU += " AND LTRIM(RTRIM(ICUR.INDIRIZZO)) LIKE (:indirizzo)"
            sqlFiltriCT += " AND LTRIM(RTRIM(ICUR.INDIRIZZO)) LIKE (:indirizzo)"
        }
        if (parametriRicerca.numCivTipo == 'P') {
            sqlFiltriCU += " AND MOD(NVL((CASE WHEN TRIM(TRANSLATE(NVL(ICUR.NUM_CIV,'Z'),'0123456789,.',' ')) IS NULL THEN TO_NUMBER(ICUR.NUM_CIV) ELSE NULL END),0),2) = 0"
            sqlFiltriCT += " AND MOD(NVL((CASE WHEN TRIM(TRANSLATE(NVL(ICUR.NUM_CIV,'Z'),'0123456789,.',' ')) IS NULL THEN TO_NUMBER(ICUR.NUM_CIV) ELSE NULL END),0),2) = 0"
        }
        if (parametriRicerca.numCivTipo == 'D') {
            sqlFiltriCU += " AND MOD(NVL((CASE WHEN TRIM(TRANSLATE(NVL(ICUR.NUM_CIV,'Z'),'0123456789,.',' ')) IS NULL THEN TO_NUMBER(ICUR.NUM_CIV) ELSE NULL END),0),2) = 1"
            sqlFiltriCT += " AND MOD(NVL((CASE WHEN TRIM(TRANSLATE(NVL(ICUR.NUM_CIV,'Z'),'0123456789,.',' ')) IS NULL THEN TO_NUMBER(ICUR.NUM_CIV) ELSE NULL END),0),2) = 1"
        }
        if (parametriRicerca.numCivDa) {
            filtri << ['numCivDa': parametriRicerca.numCivDa]
            sqlFiltriCU += " AND LPAD(LTRIM(RTRIM(ICUR.NUM_CIV)),20) >=  LPAD(LTRIM(RTRIM(:numCivDa)),20)"
            sqlFiltriCT += " AND LPAD(LTRIM(RTRIM(ICUR.NUM_CIV)),20) >=  LPAD(LTRIM(RTRIM(:numCivDa)),20)"
        }
        if (parametriRicerca.numCivA) {
            filtri << ['numCivA': parametriRicerca.numCivA]
            sqlFiltriCU += " AND LPAD(LTRIM(RTRIM(ICUR.NUM_CIV)),20) <=  LPAD(LTRIM(RTRIM(:numCivA)),20)"
            sqlFiltriCT += " AND LPAD(LTRIM(RTRIM(ICUR.NUM_CIV)),20) <=  LPAD(LTRIM(RTRIM(:numCivA)),20)"
        }

        if (parametriRicerca.renditaDa) {
            filtri << ['renditaDa': parametriRicerca.renditaDa]
            sqlFiltriCU += " AND ICUR.RENDITA_EURO >= :renditaDa"
        }
        if (parametriRicerca.renditaA) {
            filtri << ['renditaA': parametriRicerca.renditaA]
            sqlFiltriCU += " AND ICUR.RENDITA_EURO <= :renditaA"
        }

        if (parametriRicerca.sezione) {
            filtri << ['sezione': (parametriRicerca.sezione as String)]
            sqlFiltriCU += " AND LTRIM(RTRIM(ICUR.SEZIONE_RIC)) = :sezione"
            sqlFiltriCT += " AND LTRIM(RTRIM(ICUR.SEZIONE_RIC)) = :sezione"
        }
        if (parametriRicerca.foglio) {
            filtri << ['foglio': (parametriRicerca.foglio as String)]
            sqlFiltriCU += " AND ICUR.FOGLIO_RIC = :foglio"
            sqlFiltriCT += " AND ICUR.FOGLIO_RIC = :foglio"
        }
        if (parametriRicerca.numero) {
            filtri << ['numero': (parametriRicerca.numero as String)]
            sqlFiltriCU += " AND ICUR.NUMERO_RIC = :numero"
            sqlFiltriCT += " AND ICUR.NUMERO_RIC = :numero"
        }
        if (parametriRicerca.subalterno) {
            filtri << ['subalterno': (parametriRicerca.subalterno as String)]
            sqlFiltriCU += " AND ICUR.SUBALTERNO_RIC = :subalterno"
            sqlFiltriCT += " AND ICUR.SUBALTERNO_RIC = :subalterno"
        }
        if (parametriRicerca.partita) {
            filtri << ['partita': (parametriRicerca.partita as String)]
            sqlFiltriCU += " AND ICUR.PARTITA_RIC = LPAD(:partita,6,'0')"
            sqlFiltriCT += " AND ICUR.PARTITA = LPAD(:partita,6,'0')"
        }
        if (parametriRicerca.zona) {
            filtri << ['zona': (parametriRicerca.zona as String)]
            sqlFiltriCU += " AND ICUR.ZONA_RIC = :zona"
        }
        if (parametriRicerca.categoria) {
            filtri << ['categoria': (parametriRicerca.categoria as String)]
            sqlFiltriCU += " AND ICUR.CATEGORIA_RIC = :categoria"
        }
        if (parametriRicerca.classe) {
            filtri << ['classe': (parametriRicerca.classe as String)]
            sqlFiltriCU += " AND LTRIM(RTRIM(ICUR.CLASSE)) = :classe"
        }

        if (parametriRicerca.tipoImmobile != 'E') {
            filtri << ['tipoImmobile': (parametriRicerca.tipoImmobile)]
            sqlFiltriCU += " AND ICUR.TIPO_IMMOBILE = :tipoImmobile"
            sqlFiltriCT += " AND :tipoImmobile in ('E', 'T')"
        }

        if (sintesi) {
            sql = """
					SELECT 
						0 AS COD_TITOLO,
						'' AS DES_TITOLO,
						'' AS DES_DIRITTO,
						0 AS NUMERATORE,
						0 AS DENOMINATORE,
						'' AS INDIRIZZO,
						'' AS PARTITA,
						ICUR.SEZIONE,
						ICUR.FOGLIO,
						ICUR.NUMERO,
						ICUR.SUBALTERNO,
						ICUR.ESTREMI_CATASTO,
						'' AS ZONA,
						'' AS DESCRIZIONE,
						'' AS LOTTO,
						'' AS EDIFICIO,
						'' AS SCALA,
						'' AS INTERNO,
						'' AS PIANO,
						CASE WHEN ICUR.CONSISTENZA IS NOT NULL THEN TO_NUMBER(ICUR.CONSISTENZA) ELSE NULL END CONSISTENZA,
						'' AS INDIRIZZO_O,
						'' AS NUM_CIV_O,
						LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
						LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
						LPAD(ICUR.NUMERO, 5) NUMERO_O,
						LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
						'' AS ZONA_O,
						NULL AS CATEGORIA,
						NULL AS CLASSE,
						TO_NUMBER(ICUR.RENDITA) / DECODE(DAGE.FASE_EURO,1,1,DECODE(DAGE.FLAG_CATASTO_CU,'S',100, 1)) RENDITA,
						NULL AS DATA_EFFICACIA,
						NULL AS DATA_FINE_EFFICACIA,
						NULL AS DATA_VALIDITA,
						NULL AS DATA_FINE_VALIDITA,
						ICUR.TIPO_IMMOBILE,
						ICUR.CONTATORE,
						(SELECT MIN(OGGE.OGGETTO) FROM OGGETTI OGGE WHERE OGGE.ESTREMI_CATASTO = ICUR.ESTREMI_CATASTO) OGGETTO,
						SOGG.ID_SOGGETTO,
						to_number(ICUR.SUPERFICIE) AS SUPERFICIE,
  						SOGG.COD_FISCALE_RIC
					  FROM IMMOBILI_SOGGETTO_CC ICUR,
                         DATI_GENERALI DAGE,
                         PROPRIETARI_ANAGRAFE_CATASTO SOGG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE ICUR.PROPRIETARIO    = SOGG.ID_SOGGETTO_RIC
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
						   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')              
							${sqlFiltriCU}
					UNION
					SELECT  0 AS COD_TITOLO,
							'' AS DES_TITOLO,
							'' AS DES_DIRITTO,
							0 AS NUMERATORE,
							0 AS DENOMINATORE,
							'' AS INDIRIZZO,
							'' AS PARTITA,
							ICUR.SEZIONE,
							ICUR.FOGLIO,
							ICUR.NUMERO,
							ICUR.SUBALTERNO,
							ICUR.ESTREMI_CATASTO,
							'' AS ZONA,
							'' AS DESCRIZIONE,
							'' AS LOTTO,
							'' AS EDIFICIO,
							'' AS SCALA,
							'' AS INTERNO,
							'' AS PIANO,
							NULL AS CONSISTENZA,
							'' AS INDIRIZZO_O,
							'' AS NUM_CIV_O,
							LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
							LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
							LPAD(ICUR.NUMERO, 5) NUMERO_O,
							LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
							'' AS ZONA_O,
							NULL AS CATEGORIA,
							NULL AS CLASSE,
							NULL AS RENDITA,
							NULL AS DATA_EFFICACIA,
							NULL AS DATA_FINE_EFFICACIA,
							NULL AS DATA_VALIDITA,
							NULL AS DATA_FINE_VALIDITA,
							'T' AS TIPO_IMMOBILE,
							ICUR.ID_IMMOBILE AS CONTATORE,
							(SELECT MIN(OGGE.OGGETTO) FROM OGGETTI OGGE WHERE OGGE.ESTREMI_CATASTO = ICUR.ESTREMI_CATASTO) OGGETTO,
							SOGG.ID_SOGGETTO,
							null AS SUPERFICIE,
							SOGG.COD_FISCALE_RIC
					   FROM IMMOBILI_CATASTO_TERRENI ICUR,
                         PROPRIETARI_ANAGRAFE_CATASTO SOGG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE ICUR.ID_SOGGETTO = SOGG.ID_SOGGETTO
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
                            AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                            AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'DDMMYYYY') 
                            AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','DDMMYYYY')) >= TO_DATE('0101' || :anno,'DDMMYYYY')
                            AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'DDMMYYYY') 
                            AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','DDMMYYYY')) >= TO_DATE('0101' || :anno,'DDMMYYYY')      
							${sqlFiltriCT}
					ORDER BY
		        	   ESTREMI_CATASTO,
                       DATA_EFFICACIA,
                       CONTATORE 
			"""
        } else {

            sql = """
					SELECT 
						ICUR.COD_TITOLO COD_TITOLO,
						ICUR.DES_TITOLO DES_TITOLO,
						ICUR.DES_DIRITTO DES_DIRITTO,
						TO_NUMBER(NVL(ICUR.NUMERATORE,0)) NUMERATORE,
						TO_NUMBER(NVL(ICUR.DENOMINATORE,0)) DENOMINATORE,
						ICUR.INDIRIZZO || DECODE(ICUR.NUM_CIV, NULL, '', ', ' || ICUR.NUM_CIV) INDIRIZZO,
						ICUR.PARTITA,
						ICUR.SEZIONE,
						ICUR.FOGLIO,
						ICUR.NUMERO,
						ICUR.SUBALTERNO,
						ICUR.ESTREMI_CATASTO,
						ICUR.ZONA,
						ICUR.DESCRIZIONE,
						ICUR.LOTTO,
						ICUR.EDIFICIO,
						ICUR.SCALA,
						ICUR.INTERNO,
						ICUR.PIANO,
						CASE WHEN ICUR.CONSISTENZA IS NOT NULL THEN TO_NUMBER(ICUR.CONSISTENZA) ELSE NULL END CONSISTENZA,
						ICUR.INDIRIZZO INDIRIZZO_O,
						LPAD(ICUR.NUM_CIV, 20) NUM_CIV_O,
						LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
						LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
						LPAD(ICUR.NUMERO, 5) NUMERO_O,
						LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
						LPAD(ICUR.ZONA, 4) ZONA_O,
						ICUR.CATEGORIA,
						ICUR.CLASSE,
						TO_NUMBER(ICUR.RENDITA) / DECODE(DAGE.FASE_EURO,1,1,DECODE(DAGE.FLAG_CATASTO_CU,'S',100, 1)) RENDITA,
						NULL AS REDDITODOMINICALE,
						NULL AS REDDITOAGRARIO,
						ICUR.DATA_EFFICACIA,
						ICUR.DATA_FINE_EFFICACIA,
						ICUR.DATA_VALIDITA DATA_VALIDITA,
						ICUR.DATA_FINE_VALIDITA DATA_FINE_VALIDITA,
						ICUR.TIPO_IMMOBILE,
						ICUR.CONTATORE,
						(SELECT MIN(OGGE.OGGETTO) FROM OGGETTI OGGE WHERE OGGE.ESTREMI_CATASTO = ICUR.ESTREMI_CATASTO) OGGETTO,
						SOGG.ID_SOGGETTO_RIC,
 						TO_NUMBER(ICUR.SUPERFICIE) AS SUPERFICIE,
						SOGG.COD_FISCALE_RIC
					FROM IMMOBILI_SOGGETTO_CC ICUR,
                         DATI_GENERALI DAGE,
                         PROPRIETARI_ANAGRAFE_CATASTO SOGG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE ICUR.PROPRIETARIO    = SOGG.ID_SOGGETTO_RIC
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
						   AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')
                           AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'ddmmyyyy') 
                           AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy')               
							${sqlFiltriCU}
					UNION
					SELECT  ICUR.COD_TITOLO COD_TITOLO,
							ICUR.DES_TITOLO DES_TITOLO,
							ICUR.DES_DIRITTO DES_DIRITTO,
							TO_NUMBER(NVL(ICUR.NUMERATORE,0)) NUMERATORE,
							TO_NUMBER(NVL(ICUR.DENOMINATORE,0)) DENOMINATORE,
							ICUR.INDIRIZZO || DECODE(ICUR.NUM_CIV, NULL, '', ', ' || ICUR.NUM_CIV) INDIRIZZO,
							ICUR.PARTITA,
							ICUR.SEZIONE,
							ICUR.FOGLIO,
							ICUR.NUMERO,
							ICUR.SUBALTERNO,
							ICUR.ESTREMI_CATASTO,
							'' AS ZONA,
							'' AS DESCRIZIONE,
							'' AS LOTTO,
							'' AS EDIFICIO,
							'' AS SCALA,
							'' AS INTERNO,
							'' AS PIANO,
							NULL AS CONSISTENZA,
							ICUR.INDIRIZZO INDIRIZZO_O,
							LPAD(ICUR.NUM_CIV, 20) NUM_CIV_O,
							LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
							LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
							LPAD(ICUR.NUMERO, 5) NUMERO_O,
							LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
							'' AS ZONA_O,
							NULL AS CATEGORIA,
							ICUR.CLASSE,
							NULL AS RENDITA,
							TO_CHAR(ROUND(ICUR.REDDITO_DOMINICALE_EURO,2)) REDDITODOMINICALE, 
							ICUR.REDDITO_AGRARIO_EURO REDDITOAGRARIO,
							ICUR.DATA_EFFICACIA,
							ICUR.DATA_FINE_EFFICACIA,
							ICUR.DATA_VALIDITA,
							ICUR.DATA_FINE_VALIDITA,
							'T' AS TIPO_IMMOBILE,
							ICUR.ID_IMMOBILE AS CONTATORE,
							(SELECT MIN(OGGE.OGGETTO) FROM OGGETTI OGGE WHERE OGGE.ESTREMI_CATASTO = ICUR.ESTREMI_CATASTO) OGGETTO,
							SOGG.ID_SOGGETTO_RIC,
							null AS SUPERFICIE,
							SOGG.COD_FISCALE_RIC
					 FROM IMMOBILI_CATASTO_TERRENI ICUR,
                         PROPRIETARI_ANAGRAFE_CATASTO SOGG,
                         CONTRIBUENTI_SOGGETTI_CC COSO
                     WHERE ICUR.ID_SOGGETTO = SOGG.ID_SOGGETTO
                           AND NVL(SOGG.COD_FISCALE_RIC,SOGG.ID_SOGGETTO_RIC) = COSO.COD_FISCALE_ABB
                           AND ICUR.ESTREMI_CATASTO IS NOT NULL
                           AND ICUR.ESTREMI_CATASTO NOT IN
                             (SELECT DISTINCT O.ESTREMI_CATASTO
                              FROM OGGETTI O, OGGETTI_IMPOSTA OGIM, OGGETTI_PRATICA OGPR
                              WHERE
                                 OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
                                 OGIM.TIPO_TRIBUTO = 'ICI' AND
                                 OGPR.OGGETTO = O.OGGETTO AND
                                 OGIM.ANNO = :anno AND
                                 OGIM.COD_FISCALE = SOGG.COD_FISCALE_RIC)
							AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'ddmmyyyy')
                            AND ICUR.DATA_VALIDITA <= TO_DATE('3112' || :anno,'DDMMYYYY') 
                            AND NVL(ICUR.DATA_FINE_VALIDITA,TO_DATE('31129999','DDMMYYYY')) >= TO_DATE('0101' || :anno,'DDMMYYYY')
                            AND ICUR.DATA_EFFICACIA <= TO_DATE('3112' || :anno,'DDMMYYYY') 
                            AND NVL(ICUR.DATA_FINE_EFFICACIA,TO_DATE('31129999','DDMMYYYY')) >= TO_DATE('0101' || :anno,'DDMMYYYY')                 
							${sqlFiltriCT}
					ORDER BY
 						ESTREMI_CATASTO,
                       	DATA_EFFICACIA,
                       	CONTATORE 
			"""
        }

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def results = eseguiQuery("${sql}", filtri, params, true)

        def records = []

        String format = "#,###.00"
        DecimalFormat formatter = new DecimalFormat(format)

        results.each {

            def record = [:]

            record.idImmobile = it['CONTATORE'] as BigDecimal
            record.idOggetto = it['OGGETTO'] as BigDecimal
            record.idSoggetto = it['ID_SOGGETTO_RIC'] as BigDecimal
            record.codFiscale = it['COD_FISCALE_RIC']
            record.indirizzo = it['INDIRIZZO']
            record.partita = it['PARTITA']
            record.sezione = it['SEZIONE']
            record.foglio = it['FOGLIO']
            record.numero = it['NUMERO']
            record.subalterno = it['SUBALTERNO']
            record.estremiCatasto = it['ESTREMI_CATASTO']
            record.zona = it['ZONA']
            record.descrizione = it['DESCRIZIONE']
            record.lotto = it['LOTTO']
            record.edificio = it['EDIFICIO']
            record.scala = it['SCALA']
            record.interno = it['INTERNO']
            record.piano = it['PIANO']
            record.consistenza = it['CONSISTENZA']
            record.superficie = it['SUPERFICIE']
            record.codTitolo = it['COD_TITOLO']
            record.desTitolo = it['DES_TITOLO']
            record.desDiritto = it['DES_DIRITTO']
            record.numeratore = it['NUMERATORE']
            record.denominatore = it['DENOMINATORE']
            record.diritto = record.codTitolo + "-" + record.desDiritto
            record.dirittoEsteso = record.desDiritto
            if ((record.numeratore != 0) || (record.denominatore != 0)) {

                String porzione = ""
                if (record.denominatore != 0) {
                    Double percentuale = 100.0 * ((record.numeratore as Double) / (record.denominatore as Double))
                    porzione = formatter.format(percentuale)
                }
                record.dirittoEsteso += " " + (record.numeratore as String) + "/" + (record.denominatore as String) + " (" + porzione + "%)"
                record.possesso = (record.numeratore as String) + "/" + (record.denominatore as String) + " (" + porzione + ")"
            }
            record.indirizzoOrd = it['INDIRIZZO_O']
            record.numCivOrd = it['NUM_CIV_O']
            record.sezioneOrd = it['SEZIONE_O']
            record.foglioOrd = it['FOGLIO_O']
            record.numeroOrd = it['NUMERO_O']
            record.subalternoOrd = it['SUBALTERNO_O']
            record.zonaOrd = it['ZONA_O']
            record.categoria = it['CATEGORIA']
            record.classe = it['CLASSE']
            record.redditodominicale = it['REDDITODOMINICALE'] ? (it['REDDITODOMINICALE'].replace(',', '.') as BigDecimal) : null
            record.redditoagrario = it['REDDITOAGRARIO'] ? it['REDDITOAGRARIO'].replace(',', '.') as BigDecimal : null
            record.tipoImmobile = it['TIPO_IMMOBILE']
            record.dataEfficacia = it['DATA_EFFICACIA']?.format("dd/MM/yyyy")
            record.dataFineEfficacia = it['DATA_FINE_EFFICACIA']?.format("dd/MM/yyyy")
            record.dataValidita = it['DATA_VALIDITA']?.format("dd/MM/yyyy")
            record.dataFineValidita = it['DATA_FINE_VALIDITA']?.format("dd/MM/yyyy")

            if (soggettoSelezionato) {
                record.soggettoCollegato = (soggettoSelezionato.codFiscale.equals(it['COD_FISCALE_RIC']) ? false : true)
            }


            records << record
        }

        def totals = [
                totalCount: records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }


    ///
    /// *** Estra elenco immobili collegati ad oggetti in elenco
    ///
    def getElencoImmobiliDaOggetti(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        String sql = ""

        def filtri = [:]
        String sqlTotali = ""
        String sqlFiltri = ""

        ///
        /// Gestionte elenco Soggetti e/o Immobili con più di 1000 elementi in lista (Limite di Oracle !)
        ///
        if (parametriRicerca.idOggetti) {

            Integer contatore = 0
            Integer chunck = 0
            String filtroElementi = ""
            String elementi = ""
            String campoFiltro = "OGGE.OGGETTO"

            parametriRicerca.idOggetti.each() {

                if (elementi.length() > 0) elementi += ", "
                elementi += (it as String)

                if (++contatore > 999) {

                    if (chunck != 0) filtroElementi += " OR "
                    filtroElementi += "(" + campoFiltro + " IN (${elementi}))"

                    elementi = ""
                    contatore = 0
                    chunck++
                }
            }
            if (contatore != 0) {

                if (chunck != 0) filtroElementi += " OR "
                filtroElementi += "(" + campoFiltro + " IN (${elementi}))"
            }

            sqlFiltri += " AND (" + filtroElementi + ") "
        }

        sql = """
			SELECT * FROM (
				SELECT DISTINCT
					ICUR.SEZIONE,
					ICUR.FOGLIO,
					ICUR.NUMERO,
					ICUR.SUBALTERNO,
					ICUR.ESTREMI_CATASTO,
					ICUR.ZONA,
					ICUR.DESCRIZIONE,
					NULL AS CONSISTENZA,
			/**		CASE WHEN ICUR.CONSISTENZA IS NOT NULL THEN TO_NUMBER(ICUR.CONSISTENZA) ELSE NULL END CONSISTENZA, **/
					LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
					LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
					LPAD(ICUR.NUMERO, 5) NUMERO_O,
					LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
					LPAD(ICUR.ZONA, 4) ZONA_O,
					NULL AS CATEGORIA,
					NULL AS CLASSE,
					NULL AS RENDITA,
			/**		TO_NUMBER(ICUR.RENDITA) / DECODE(DAGE.FASE_EURO,1,1,DECODE(DAGE.FLAG_CATASTO_CU,'S',100, 1)) RENDITA, **/
					ICUR.TIPO_IMMOBILE,
					ICUR.CONTATORE,
					OGGE.OGGETTO AS OGGETTO,
					0 AS ID_SOGGETTO_RIC
		        FROM
					IMMOBILI_CATASTO_URBANO ICUR,
					OGGETTI OGGE,
					DATI_GENERALI DAGE
		        WHERE
					OGGE.ESTREMI_CATASTO(+) = ICUR.ESTREMI_CATASTO AND
					ICUR.ESTREMI_CATASTO IS NOT NULL AND
					NVL(ICUR.PARTITA,'-') NOT IN ('C')
					${sqlFiltri}
			UNION
		        SELECT DISTINCT
					ICUR.SEZIONE,
					ICUR.FOGLIO,
					ICUR.NUMERO,
					ICUR.SUBALTERNO,
					ICUR.ESTREMI_CATASTO,
					NULL AS ZONA,
					NULL AS DESCRIZIONE,
					NULL AS CONSISTENZA,
					LPAD(ICUR.SEZIONE, 3) SEZIONE_O,
					LPAD(ICUR.FOGLIO, 5) FOGLIO_O,
					LPAD(ICUR.NUMERO, 5) NUMERO_O,
					LPAD(ICUR.SUBALTERNO, 4) SUBALTERNO_O,
					'' AS ZONA_O,
					NULL AS CATEGORIA,
					NULL AS CLASSE,
					NULL AS RENDITA,
					'T' AS TIPO_IMMOBILE,
					ICUR.ID_IMMOBILE AS CONTATORE,
					OGGE.OGGETTO AS OGGETTO,
					0 AS ID_SOGGETTO_RIC
		        FROM
					IMMOBILI_CATASTO_TERRENI ICUR,
					OGGETTI OGGE,
					DATI_GENERALI DAGE
		        WHERE
					OGGE.ESTREMI_CATASTO(+) = ICUR.ESTREMI_CATASTO AND
					ICUR.ESTREMI_CATASTO IS NOT NULL AND
					NVL(ICUR.PARTITA,'-') NOT IN ('C')
					${sqlFiltri}
			)
			ORDER BY
				TIPO_IMMOBILE,
				SEZIONE_O,
				FOGLIO_O,
				NUMERO_O,
				SUBALTERNO_O
		"""

        sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
		"""

        int totalCount = 0
        int pageCount = 0

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali = eseguiQuery("${sqlTotali}", filtri, params, true)[0]

        def totals = [
                totalCount: totali.TOT_COUNT,
        ]

        def results = eseguiQuery("${sql}", filtri, params)

        def records = []

        String format = "#,###.00"
        DecimalFormat formatter = new DecimalFormat(format)

        results.each {

            def record = [:]

            record.idImmobile = it['CONTATORE'] as BigDecimal
            record.idOggetto = it['OGGETTO'] as BigDecimal
            record.idSoggetto = it['ID_SOGGETTO_RIC'] as BigDecimal

            record.sezione = it['SEZIONE']
            record.foglio = it['FOGLIO']
            record.numero = it['NUMERO']
            record.subalterno = it['SUBALTERNO']
            record.estremiCatasto = it['ESTREMI_CATASTO']
            record.zona = it['ZONA']
            record.descrizione = it['DESCRIZIONE']
            record.consistenza = it['CONSISTENZA']

            record.categoria = it['CATEGORIA']
            record.classe = it['CLASSE']
            record.rendita = it['RENDITA']
            record.tipoImmobile = it['TIPO_IMMOBILE']

            records << record
        }

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    ///
    /// *** Prepara query per ID, anche più di 1000 per arginare limite di Oracle
    ///
    String preparaElencoID(def identificativi, String campoFiltro) {

        Integer contatore = 0
        Integer chunck = 0
        String filtroElementi = ""
        String elementi = ""

        identificativi.each() {

            if (elementi.length() > 0) elementi += ", "
            elementi += (it as String)

            if (++contatore > 999) {

                if (chunck != 0) filtroElementi += " OR "
                filtroElementi += "(" + campoFiltro + " IN (${elementi}))"

                elementi = ""
                contatore = 0
                chunck++
            }
        }
        if (contatore != 0) {

            if (chunck != 0) filtroElementi += " OR "
            filtroElementi += "(" + campoFiltro + " IN (${elementi}))"
        }

        return filtroElementi
    }

    ///
    /// *** Crea elenco Codici Diritto
    ///
    def getCodiciDiritto() {

        String sql = ""

        sql = """
				SELECT
					CC.COD_DIRITTO,
				/*	CC.COD_DIRITTO_FIXED,	*/
				/*	DI.COD_DIRITTO COD_DIRITTO_LEG,	*/
					DI.ORDINAMENTO,
					CC.DESCRIZIONE,
					DECODE(DI.ECCEZIONE,NULL,1,0) PRE_CHECKED
				FROM
					CODICI_DIRITTO DI,
					(SELECT
						DESCRIZIONE,
						CODICE_DIRITTO COD_DIRITTO,
						CASE WHEN TRIM(TRANSLATE(NVL(CODICE_DIRITTO,'Z'),'0123456789-,.',' ')) IS NULL AND (TO_NUMBER(CODICE_DIRITTO) BETWEEN 10 AND 100)
						THEN 
							SUBSTR(CODICE_DIRITTO,1,LENGTH(CODICE_DIRITTO)-1)
						ELSE
							CASE WHEN TRIM(TRANSLATE(TRIM(NVL(CODICE_DIRITTO,'Z')),'0123456789-,.',' ')) IS NULL
							THEN CASE WHEN (TO_NUMBER(TRIM(CODICE_DIRITTO)) BETWEEN 12 AND 99) THEN TRIM(CODICE_DIRITTO) ELSE CODICE_DIRITTO END
							ELSE CODICE_DIRITTO
							END
						END AS COD_DIRITTO_FIXED
					FROM 
						CC_DIRITTI DI) CC
				WHERE
					UPPER(CC.COD_DIRITTO_FIXED) = DI.COD_DIRITTO
				ORDER BY
					DI.ORDINAMENTO
				"""

        def results = eseguiQuery("${sql}", null, null, true)

        def records = []

        results.each {

            def record = [:]

            record.codDiritto = it['COD_DIRITTO']
            record.descrizione = it['DESCRIZIONE']
            record.preChecked = it['PRE_CHECKED']
            record.ordinamento = it['ORDINAMENTO']

            records << record
        }

        return records
    }

    ///
    /// *** Esegue query
    ///
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
