package it.finmatica.tr4.datiesterni

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.ContribuenteCcSoggetto
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.dto.TipoOggettoDTO
import org.hibernate.FetchMode
import org.hibernate.transform.AliasToEntityMapResultTransformer

import java.text.DecimalFormat
import java.text.SimpleDateFormat

class CatastoCensuarioService {

    static transactional = false

    def sessionFactory

    def commonService

    def getTerreniCatastoUrbano(def listaFiltri, ricercaEstremiConcatenati = false) {

        FiltroRicercaOggetto fro = listaFiltri[0]

        def filtri = [:]

        String sqlTerreniCatastoUrbano = """
            SELECT DISTINCT TO_NUMBER(FAB.ID_IMMOBILE) AS IDFABBRICATO,
                            TO_NUMBER(FAB.ID_IMMOBILE) AS IDIMMOBILE,
                            FAB.INDIRIZZO AS INDIRIZZO,
                            FAB.INDIRIZZO ||
                            DECODE(FAB.NUM_CIV,
                                   NULL,
                                   '',
                                   ', ' || REPLACE(LTRIM(REPLACE(FAB.NUM_CIV,
                                                                 '0',
                                                                 ' ')),
                                                   ' ',
                                                   '0')) AS INDIRIZZOCOMPLETO,
                            FAB.NUM_CIV AS CIVICO,
                            '' AS SCALA,
                            '' AS INTERNO,
                            '' AS PIANO,
                            '' AS CATEGORIACATASTO,
                            FAB.CLASSE AS CLASSECATASTO,
                            FAB.SEZIONE AS SEZIONE,
                            FAB.FOGLIO AS FOGLIO,
                            FAB.NUMERO AS NUMERO,
                            FAB.SUBALTERNO AS SUBALTERNO,
                            '' AS ZONA,
                            FAB.PARTITA AS PARTITA,
                            0 AS CONSISTENZA,
                            0 AS RENDITA,
                            TO_NUMBER(FAB.REDDITO_DOMINICALE_EURO) AS REDDITODOMINICALE,
                            TO_NUMBER(FAB.REDDITO_AGRARIO_EURO) REDDITOAGRARIO,
                            0 AS SUPERFICIE,
                            FAB.ANNOTAZIONE AS ANNOTAZIONE,
                            FAB.DATA_EFFICACIA AS DATAEFFICACIAINIZIO,
                            FAB.DATA_FINE_EFFICACIA AS DATAEFFICACIAFINE,
                            LPAD(NVL(FAB.NUM_CIV, '0'), 6, '0') AS CIVICOSORT,
                            LPAD(NVL(FAB.SEZIONE, ' '), 3, ' ') ||
                            LPAD(NVL(FAB.FOGLIO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.NUMERO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.SUBALTERNO, ' '), 4, ' ') AS ESTREMICATASTALISORT,
                            'T' AS TIPOOGGETTO
              FROM IMMOBILI_CATASTO_TERRENI FAB,
                   CC_TITOLARITA           TITO,
                   CC_SOGGETTI             SOGG
             WHERE FAB.ID_IMMOBILE = TITO.ID_IMMOBILE(+)
               AND TITO.ID_SOGGETTO = SOGG.ID_SOGGETTO(+)
         """

        if (fro.progressivo != null) {
            sqlTerreniCatastoUrbano += """
                AND FAB.ID_IMMOBILE = ${fro.progressivo}
            """
        } else if (fro.immobile != null) {
            sqlTerreniCatastoUrbano += """
                AND FAB.ID_IMMOBILE = ${fro.immobile}
            """
        }

        // Indirizzo
        if (fro.indirizzo?.trim()) {
            filtri << ['indirizzo': fro.indirizzo + '%']
            sqlTerreniCatastoUrbano += """
                AND UPPER(FAB.INDIRIZZO_RIC) LIKE UPPER(:indirizzo)              
            """
        }

        // Civico
        if (fro.numCiv?.trim()) {
            filtri << ['numCiv': fro.numCiv]
            sqlTerreniCatastoUrbano += """ 
                AND UPPER(FAB.NUM_CIV) = UPPER(:numCiv)
            """
        }

        // Partita
        if (fro.partita?.trim()) {
            filtri << ['partita': fro.partita]
            sqlTerreniCatastoUrbano += """
                AND UPPER(FAB.PARTITA) = UPPER(:partita)
            """
        }

        if (ricercaEstremiConcatenati) {

            if (fro.sezione || fro.foglio || fro.numero || fro.subalterno) {
                def estremiCat = commonService.creaEtremiCatasto(fro.sezione, fro.foglio, fro.numero, fro.subalterno)
                filtri << ['estremiCat': estremiCat]
                sqlTerreniCatastoUrbano += """
                	AND FAB.ESTREMI_CATASTO = :estremiCat
				"""
            }
        } else {

            // Sezione
            if (fro.sezione?.trim()) {
                filtri << ['sezione': fro.sezione]
                sqlTerreniCatastoUrbano += """
	                AND FAB.SEZIONE_RIC LIKE RTRIM(LTRIM(LTRIM(:sezione, ' ')))
	            """
            }

            // Foglio
            if (fro.foglio?.trim()) {
                filtri << ['foglio': fro.foglio]
                sqlTerreniCatastoUrbano += """
	                AND FAB.FOGLIO_RIC LIKE RTRIM(LTRIM(LTRIM(:foglio, ' ')))
	            """
            }

            // Numero
            if (fro.numero) {
                filtri << ['numero': fro.numero]
                sqlTerreniCatastoUrbano += """
	                AND FAB.NUMERO_RIC LIKE RTRIM(LTRIM(LTRIM(:numero, ' ')))
	            """
            }

            // Subalterno
            if (fro.subalterno?.trim()) {
                filtri << ['subalterno': fro.subalterno]
                sqlTerreniCatastoUrbano += """
	                AND FAB.SUBALTERNO_RIC LIKE RTRIM(LTRIM(LTRIM(:subalterno, ' ')))
	            """
            }
        }

        // Data Efficacia Dal
        if (fro.validitaDal) {
            sqlTerreniCatastoUrbano += """
                AND FAB.DATA_EFFICACIA >=  TO_DATE('${fro.validitaDal.format('yyyyMMdd')}', 'YYYYMMDD')
            """
        }

        // Data Efficacia Al
        if (fro.validitaAl) {
            sqlTerreniCatastoUrbano += """
                AND FAB.DATA_EFFICACIA <= TO_DATE('${fro.validitaAl.format('yyyyMMdd')}', 'YYYYMMDD')
            """
        }

        // Rendita da
        if (fro.renditaDa) {
            sqlTerreniCatastoUrbano += """
                AND FAB.REDDITO_DOMINICALE_EURO >=  TO_NUMBER('$fro.renditaDa')
            """
        }

        // Rendita a
        if (fro.renditaA) {
            sqlTerreniCatastoUrbano += """
                AND FAB.REDDITO_DOMINICALE_EURO <=  TO_NUMBER('$fro.renditaA')
            """
        }

        // Note
        if (fro.note?.trim()) {
            filtri << ['note': fro.note + '%']
            sqlTerreniCatastoUrbano += """
               AND upper(FAB.ANNOTAZIONE) like upper(:note)
            """
        }
        sqlTerreniCatastoUrbano += """
                ORDER BY DATAEFFICACIAINIZIO, DATAEFFICACIAFINE
        """

        def results = eseguiQuery(sqlTerreniCatastoUrbano, filtri, null, true)

        results.each {
            it.RENDITAREDDDOM = it.TIPOOGGETTO == 'F' ? it.RENDITA : it.REDDITODOMINICALE
        }

        return results
    }

    def getImmobiliCatastoUrbano(def listaFiltri, def ricercaEstremiConcatenati = false) {

        FiltroRicercaOggetto fro = listaFiltri[0]

        def filtri = [:]

        String sqlImmobiliCatastoUrbano = """
            SELECT DISTINCT TO_NUMBER(FAB.CONTATORE) AS IDFABBRICATO,
                            TO_NUMBER(FAB.CONTATORE) AS IDIMMOBILE,
                            FAB.INDIRIZZO AS INDIRIZZO,
                            FAB.INDIRIZZO ||
                            DECODE(FAB.NUM_CIV,
                                   NULL,
                                   '',
                                   ', ' || REPLACE(LTRIM(REPLACE(FAB.NUM_CIV, '0', ' ')),
                                                   ' ',
                                                   '0')) ||
                            DECODE(FAB.SCALA,
                                   NULL,
                                   '',
                                   ' Sc:' ||
                                   REPLACE(LTRIM(REPLACE(FAB.SCALA, '0', ' ')), ' ', '0')) ||
                            DECODE(FAB.PIANO,
                                   NULL,
                                   '',
                                   ' P:' ||
                                   REPLACE(LTRIM(REPLACE(FAB.PIANO, '0', ' ')), ' ', '0')) ||
                            DECODE(FAB.INTERNO,
                                   NULL,
                                   '',
                                   ' In:' || REPLACE(LTRIM(REPLACE(FAB.INTERNO, '0', ' ')),
                                                     ' ',
                                                     '0')) AS INDIRIZZOCOMPLETO,
                            FAB.NUM_CIV AS CIVICO,
                            FAB.SCALA AS SCALA,
                            FAB.INTERNO AS INTERNO,
                            FAB.PIANO AS PIANO,
                            FAB.CATEGORIA AS CATEGORIACATASTO,
                            FAB.CLASSE AS CLASSECATASTO,
                            FAB.SEZIONE AS SEZIONE,
                            FAB.FOGLIO AS FOGLIO,
                            FAB.NUMERO AS NUMERO,
                            FAB.SUBALTERNO AS SUBALTERNO,
                            FAB.ZONA AS ZONA,
                            FAB.PARTITA AS PARTITA,
                            TO_NUMBER(FAB.CONSISTENZA) AS CONSISTENZA,
                            TO_NUMBER(FAB.RENDITA_EURO) AS RENDITA,
                            TO_NUMBER(FAB.RENDITA_EURO) as REDDITODOMINICALE,
                            0 AS REDDITOAGRARIO,
                            TO_NUMBER(FAB.SUPERFICIE) AS SUPERFICIE,
                            FAB.NOTE AS ANNOTAZIONE,
                            FAB.DATA_EFFICACIA AS DATAEFFICACIAINIZIO,
                            FAB.DATA_FINE_EFFICACIA AS DATAEFFICACIAFINE,                            
                            LPAD(NVL(FAB.NUM_CIV, '0'), 6, '0') AS CIVICOSORT,
                            LPAD(NVL(FAB.SEZIONE, ' '), 3, ' ') ||
                            LPAD(NVL(FAB.FOGLIO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.NUMERO, ' '), 5, ' ') ||
                            LPAD(NVL(FAB.SUBALTERNO, ' '), 4, ' ') ||
                            LPAD(NVL(FAB.ZONA, ' '), 3, '') AS ESTREMICATASTALISORT,
                            'F' AS TIPOOGGETTO,
                            FAB.progr_identificativo AS PROGRIDENTIFICATIVO,
                            (select distinct nvl(FAB1.SEZIONE || '/', ' /') ||
                                NVL(FAB1.FOGLIO || '/', ' /') ||
                                NVL(FAB1.NUMERO || '/', ' /') ||
                                NVL(FAB1.SUBALTERNO, '')
                                 from IMMOBILI_CATASTO_URBANO fab1
                                where fab1.progr_identificativo = 1
                                and fab1.contatore = fab.contatore
                                and fab.progr_identificativo != 1) PRINCIPALE
                                FROM IMMOBILI_CATASTO_URBANO FAB, CC_TITOLARITA TITO, CC_SOGGETTI SOGG
                                 WHERE FAB.CONTATORE = TITO.ID_IMMOBILE (+)
                                   AND TITO.ID_SOGGETTO = SOGG.ID_SOGGETTO (+)
                               AND FAB.TIPO_IMMOBILE = 'F'
        """

        // IMMOBILE
        if (fro.immobile != null) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.CONTATORE = ${fro.immobile}
            """
        } else if (fro.progressivo != null) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.CONTATORE = ${fro.progressivo}
            """
        }

        // Indirizzo
        if (fro.indirizzo?.trim()) {
            filtri << ['indirizzo': fro.indirizzo + '%']
            sqlImmobiliCatastoUrbano += """
                AND UPPER(FAB.INDIRIZZO) LIKE UPPER(:indirizzo)
            """
        }

        // Civico
        if (fro.numCiv?.trim()) {
            filtri << ['numCiv': fro.numCiv]
            sqlImmobiliCatastoUrbano += """ 
                AND UPPER(FAB.NUM_CIV) = UPPER(:numCiv) 
            """
        }

        // Scala
        if (fro.scala?.trim()) {
            filtri << ['scala': fro.scala]
            sqlImmobiliCatastoUrbano += """
                AND UPPER(FAB.SCALA) = UPPER(:scala)
            """
        }

        // Interno
        if (fro.interno?.trim()) {
            filtri << ['interno': fro.interno]
            sqlImmobiliCatastoUrbano += """
                AND UPPER(FAB.INTERNO) = UPPER(:interno)
            """
        }
        // Partita
        if (fro.partita?.trim()) {
            filtri << ['partita': fro.partita]
            sqlImmobiliCatastoUrbano += """
                AND UPPER(FAB.PARTITA) = UPPER(:partita)
            """
        }

        if (ricercaEstremiConcatenati) {

            if (fro.sezione || fro.foglio || fro.numero || fro.subalterno) {
                def estremiCat = commonService.creaEtremiCatasto(fro.sezione, fro.foglio, fro.numero, fro.subalterno)
                filtri << ['estremiCat': estremiCat]
                sqlImmobiliCatastoUrbano += """
					AND FAB.ESTREMI_CATASTO = :estremiCat
				"""
            }
        } else {

            // Sezione
            if (fro.sezione?.trim()) {
                filtri << ['sezione': fro.sezione]
                sqlImmobiliCatastoUrbano += """
	                AND FAB.SEZIONE_RIC LIKE RTRIM(LTRIM(LTRIM(:sezione, ' ')))
	            """
            }

            // Foglio
            if (fro.foglio?.trim()) {
                filtri << ['foglio': fro.foglio]
                sqlImmobiliCatastoUrbano += """
	                AND FAB.FOGLIO_RIC LIKE RTRIM(LTRIM(LTRIM(:foglio, ' ')))
	            """
            }

            // Numero
            if (fro.numero) {
                filtri << ['numero': fro.numero]
                sqlImmobiliCatastoUrbano += """
	                AND FAB.NUMERO_RIC LIKE RTRIM(LTRIM(LTRIM(:numero, ' ')))
	            """
            }

            // Subalterno
            if (fro.subalterno?.trim()) {
                filtri << ['subalterno': fro.subalterno]
                sqlImmobiliCatastoUrbano += """
		                AND FAB.SUBALTERNO_RIC LIKE RTRIM(LTRIM(LTRIM(:subalterno, ' ')))
		            """
            }
        }

        // Zona
        if (fro.zona) {
            filtri << ['zona': fro.zona]
            sqlImmobiliCatastoUrbano += """
                AND UPPER(FAB.ZONA) = UPPER(:zona)
            """
        }

        // Categoria
        if (fro.categoriaCatasto?.categoriaCatasto?.trim()) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.CATEGORIA = '${fro.categoriaCatasto.categoriaCatasto}'
            """
        }

        // Codice fiscale
        if (fro.filtriSoggetto.codFiscale?.trim()) {
            filtri << ['codFiscale': fro.filtriSoggetto.codFiscale + '%']
            sqlImmobiliCatastoUrbano += """
                AND UPPER(SOGG.CODICE_FISCALE) LIKE UPPER(:codFiscale)
            """
        }

        // Data Efficacia Dal
        if (fro.validitaAl) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.DATA_EFFICACIA <=  TO_DATE(${fro.validitaAl.format('yyyyMMdd')}, 'YYYYMMDD')
            """
        }

        // Data Efficacia Al
        if (fro.validitaDal) {
            sqlImmobiliCatastoUrbano += """
             and nvl(fab.data_fine_efficacia,
                       decode(fab.partita,
                              'C',
                              fab.data_efficacia,
                              to_date('31129999', 'ddmmyyyy'))) >=
                   to_date(${fro.validitaDal.format('yyyyMMdd')}, 'YYYYMMDD')   
            """
        }

        // Rendita da
        if (fro.renditaDa) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.RENDITA_EURO >=  $fro.renditaDa
            """
        }

        // Rendita a
        if (fro.renditaA) {
            sqlImmobiliCatastoUrbano += """
                AND FAB.RENDITA_EURO <=  $fro.renditaA
            """
        }

        // Note
        if (fro.note?.trim()) {
            filtri << ['note': fro.note + '%']
            sqlImmobiliCatastoUrbano += """
               AND upper(FAB.NOTE) like upper(:note)
            """
        }

        sqlImmobiliCatastoUrbano += """
                ORDER BY TO_NUMBER(FAB.CONTATORE), DATAEFFICACIAINIZIO, DATAEFFICACIAFINE
        """

        def results = eseguiQuery(sqlImmobiliCatastoUrbano, filtri, null, true)

        results.each {
            it.RENDITAREDDDOM = it.TIPOOGGETTO == 'F' ? it.RENDITA : it.REDDITODOMINICALE
            it.isGraffato = it.PROGRIDENTIFICATIVO != 1
        }

        return results
    }

    def getProprietariCatastoCensuario(def immobile, def tipoOggetto = null) {

        def tipoOggettoCondition = tipoOggetto ?
                "PROPRIETARI_CATASTO_URBANO.TIPO_IMMOBILE = '$tipoOggetto' AND" :
                ""

        String sqlProprietari = """
            select * from (
            SELECT DISTINCT PROPRIETARI_CATASTO_URBANO.DES_COM_SEDE sede,
                            PROPRIETARI_CATASTO_URBANO.SIGLA_PRO_SEDE provinciaSede,
                            PROPRIETARI_CATASTO_URBANO.COD_FISCALE codFiscale,
                            PROPRIETARI_CATASTO_URBANO.DES_COM_NAS luogoNascita,
                            PROPRIETARI_CATASTO_URBANO.SIGLA_PRO_NAS provinciaNascita,
                            PROPRIETARI_CATASTO_URBANO.DATA_NAS dataNascita,
                            TRANSLATE(PROPRIETARI_CATASTO_URBANO.COGNOME_NOME, '/', ' ') cognomeNome,
                            PROPRIETARI_CATASTO_URBANO.ID_SOGGETTO,
                            TO_NUMBER(${immobile}) ID_IMMOBILE,
                            nvl(PROPRIETARI_CATASTO_URBANO.DATA_VALIDITA, TO_DATE('01011800', 'DDMMYYYY')) dataInizio,
                            nvl(PROPRIETARI_CATASTO_URBANO.DATA_FINE_VALIDITA, TO_DATE('31129999', 'DDMMYYYY')) dataFine,
                            PROPRIETARI_CATASTO_URBANO.COD_TITOLO || ' - ' ||
                                PROPRIETARI_CATASTO_URBANO.DES_DIRITTO diritto,
                            PROPRIETARI_CATASTO_URBANO.DES_TITOLO titoloNonCodificato,
                            PROPRIETARI_CATASTO_URBANO.NUMERATORE || '/' ||
                            PROPRIETARI_CATASTO_URBANO.DENOMINATORE possesso,
                            c.ni
              FROM PROPRIETARI_CATASTO_URBANO, contribuenti c
             WHERE PROPRIETARI_CATASTO_URBANO.cod_fiscale = c.cod_fiscale(+) and 
                   $tipoOggettoCondition               
               PROPRIETARI_CATASTO_URBANO.ID_IMMOBILE = ${immobile}
                )
             ORDER BY datainizio, datafine, cognomeNome
        """

        def results = sessionFactory.currentSession.createSQLQuery(sqlProprietari).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

    def trasformaTipoOggetto(def tipoOggetto) {
        if (tipoOggetto instanceof String || tipoOggetto instanceof Character) {
            switch (tipoOggetto) {
                case "F":
                    return TipoOggetto.get(3).toDTO()
                case "T":
                    return TipoOggetto.get(1).toDTO()
                default:
                    return TipoOggetto.get(3).toDTO()
            }
        } else if (tipoOggetto instanceof TipoOggettoDTO) {
            // Decodifica del tipo oggetto
            switch (tipoOggetto.tipoOggetto) {
                case [1, 2, 55]:
                    return "T"
                case [3, 4]:
                    return "F"
                default:
                    // Come default si imposta fabbricato
                    return "F"
            }
        }

        return "F"
    }

    def getOggettiCatastoUrbano(def filtri) {

        String idSoggettoFilter = ""
        String idSoggettoFilterTer = ""
        String idSoggettoFilterUrb = ""

        if (filtri.soggettiCatastoCollegati) {

            for (s in filtri.soggettiCatastoCollegati) {
                if (idSoggettoFilter != "") idSoggettoFilter += ","
                idSoggettoFilter += s.toString()
            }
            idSoggettoFilterUrb = " OR (immobili_soggetto_cc.proprietario IN (${idSoggettoFilter}))"
            idSoggettoFilterTer = " OR (immobili_catasto_terreni.id_soggetto IN (${idSoggettoFilter}))"
        }

        String sqlTerreniCatastoUrbano = """
				select * from (
						select distinct immobili_soggetto_cc.contatore idfabbricato,
				                        immobili_soggetto_cc.contatore idimmobile,
				                        '' indirizzo,
				                        immobili_soggetto_cc.indirizzo indirizzocompleto,
				                        immobili_soggetto_cc.num_civ civico,
				                        immobili_soggetto_cc.scala scala,
				                        immobili_soggetto_cc.interno interno,
				                        immobili_soggetto_cc.piano piano,
				                        immobili_soggetto_cc.categoria categoriacatasto,
				                        immobili_soggetto_cc.classe classecatasto,
				                        lpad(sezione, 3) sezione,
				                        lpad(foglio, 5) foglio,
				                        lpad(numero, 5) numero,
				                        lpad(subalterno, 4) subalterno,
				                        lpad(zona, 3) zona,
				                        immobili_soggetto_cc.partita partita,
				                        to_number(immobili_soggetto_cc.consistenza) consistenza,
				                        to_number(rtrim(ltrim(immobili_soggetto_cc.rendita))) /
				                        decode(dati_generali.fase_euro,
				                               1,
				                               1,
				                               decode(dati_generali.flag_catasto_cu,
				                                      'S',
				                                      100,
				                                      1)) rendita,
				                        null redditodominicale,
				                        null redditoagrario,
				                        to_number(immobili_soggetto_cc.superficie) superficie,
				                        immobili_soggetto_cc.note annotazione,
				                        immobili_soggetto_cc.data_efficacia dataefficaciainizio,
				                        immobili_soggetto_cc.data_fine_efficacia dataefficaciafine,
				                        immobili_soggetto_cc.tipo_immobile tipooggetto,
				                        to_number(immobili_soggetto_cc.proprietario) idsoggetto,
				                        immobili_soggetto_cc.numeratore numeratore,
				                        immobili_soggetto_cc.denominatore denominatore,
				                        immobili_soggetto_cc.data_validita datainiziovalidita,
				                        immobili_soggetto_cc.data_fine_validita datafinevalidita,
				                        immobili_soggetto_cc.inizio_validita_ogco iniziovaliditaogco,
				                        immobili_soggetto_cc.cod_titolo || '-' ||
				                        immobili_soggetto_cc.des_diritto diritto,
				                        immobili_soggetto_cc.des_titolo titolo,
				                        decode(immobili_soggetto_cc.numeratore,
				                               null,
				                               '',
				                               immobili_soggetto_cc.numeratore || '/' ||
				                               immobili_soggetto_cc.denominatore) possesso,
				                        immobili_soggetto_cc.estremi_catasto estremicatasto,
				                        immobili_soggetto_cc.cod_fiscale_ric cod_fiscale
				        from immobili_soggetto_cc, dati_generali
						where (immobili_soggetto_cc.cod_fiscale_ric = :pCodFis ${idSoggettoFilterUrb})

                         ${filtri.anno != "Tutti" ?
                """and immobili_soggetto_cc.data_efficacia <=
				               to_date('3112' || :pAnno, 'ddmmyyyy')
				           and nvl(immobili_soggetto_cc.data_fine_efficacia,
				                   decode(immobili_soggetto_cc.partita,
				                          'C',
				                          immobili_soggetto_cc.data_efficacia,
				                          to_date('31129999', 'ddmmyyyy'))) >=
				               to_date('0101' || :pAnno, 'ddmmyyyy')
				           and immobili_soggetto_cc.data_validita <=
				               to_date('3112' || :pAnno, 'ddmmyyyy')
				           and nvl(immobili_soggetto_cc.data_fine_validita,
				                   decode(immobili_soggetto_cc.partita,
				                          'C',
				                          immobili_soggetto_cc.data_validita,
				                          to_date('31129999', 'ddmmyyyy'))) >=
				               to_date('0101' || :pAnno, 'ddmmyyyy') """ : ""}
				           and immobili_soggetto_cc.progr_identificativo = 1
				           ${filtri.tipoOggetto == 'CT' ? 'and 1 = 0' : ''}
				        union
				        select immobili_catasto_terreni.id_immobile idfabbricato,
				               immobili_catasto_terreni.id_immobile idimmobile,
				               '' indirizzo,
				               immobili_catasto_terreni.indirizzo indirizzocompleto,
				               lpad(immobili_catasto_terreni.num_civ, 20) civico,
				               '' as scala,
				               '' as interno,
				               '' as piano,
				               '' as categoriacatasto,
				               immobili_catasto_terreni.classe classecatasto,
				               immobili_catasto_terreni.sezione,
				               immobili_catasto_terreni.foglio,
				               immobili_catasto_terreni.numero,
				               immobili_catasto_terreni.subalterno,
				               '' zona,
				               immobili_catasto_terreni.partita partita,
				               null as consistenza,
				               null as rendita,
				               to_char(round(immobili_catasto_terreni.reddito_dominicale_euro,
				                             2)) redditodominicale,
				               immobili_catasto_terreni.reddito_agrario_euro redditoagrario,
				               null superficie,
				               '' as annotazione,
				               immobili_catasto_terreni.data_efficacia dataefficaciainizio,
				               immobili_catasto_terreni.data_fine_efficacia dataefficaciafine,
				               'T' tipooggetto,
				               immobili_catasto_terreni.id_soggetto idsoggetto,
				               immobili_catasto_terreni.numeratore numeratore,
				               immobili_catasto_terreni.denominatore denominatore,
				               immobili_catasto_terreni.data_validita datainiziovalidita,
				               immobili_catasto_terreni.data_fine_validita datafinevalidita,
				               immobili_catasto_terreni.inizio_validita_ogco iniziovaliditaogco,
				               immobili_catasto_terreni.cod_titolo || '-' ||
				               immobili_catasto_terreni.des_diritto diritto,
				               immobili_catasto_terreni.des_titolo titolo,
				               decode(immobili_catasto_terreni.numeratore,
				                      null,
				                      '',
				                      immobili_catasto_terreni.numeratore || '/' ||
				                      immobili_catasto_terreni.denominatore) possesso,
				               immobili_catasto_terreni.estremi_catasto estremicatasto,
				               immobili_catasto_terreni.cod_fiscale_ric cod_fiscale
				          from immobili_catasto_terreni,
				               tipi_qualita
				         where (immobili_catasto_terreni.cod_fiscale_ric = :pCodFis ${idSoggettoFilterTer})
				           and tipi_qualita.tipo_qualita(+) =
				               immobili_catasto_terreni.qualita
				               
				        ${filtri.anno != "Tutti" ?
                """and immobili_catasto_terreni.data_efficacia <=
				               to_date('3112' || :pAnno, 'ddmmyyyy')
				           and nvl(immobili_catasto_terreni.data_fine_efficacia,
				                   decode(immobili_catasto_terreni.partita,
				                          'C',
				                          immobili_catasto_terreni.data_efficacia,
				                          to_date('31129999', 'ddmmyyyy'))) >=
				               to_date('0101' || :pAnno, 'ddmmyyyy')
				           and immobili_catasto_terreni.data_validita <=
				               to_date('3112' || :pAnno, 'ddmmyyyy')
				           and nvl(immobili_catasto_terreni.data_fine_validita,
				                   decode(immobili_catasto_terreni.partita,
				                          'C',
				                          to_date(immobili_catasto_terreni.data_fine_validita,
				                                  'DD/MM/YYYY'),
				                          to_date('31129999', 'ddmmyyyy'))) >=
				               to_date('0101' || :pAnno, 'ddmmyyyy')""" : ""}
				                ${filtri.tipoOggetto == 'CF' ? 'and 1 = 0' : ''}
				               )
				 order by estremicatasto,
				          dataefficaciainizio,
				          iniziovaliditaogco,
				          idfabbricato
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sqlTerreniCatastoUrbano).with {

            setParameter("pCodFis", filtri.codFis)
            if (filtri.anno != "Tutti") {
                setParameter("pAnno", filtri.anno ?: '9999')
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        String patternNumero = "#,###.00"
        DecimalFormat numero = new DecimalFormat(patternNumero)
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")
        def contatore = 1
        results.each {

            it.REDDITODOMINICALE = it.REDDITODOMINICALE ? (it.REDDITODOMINICALE.replace(',', '.') as BigDecimal) : null

            it.REDDITOAGRARIO = it.REDDITOAGRARIO ? it.REDDITOAGRARIO.replace(',', '.') as BigDecimal : null

            it.RIGA = contatore++
            it.RIGA_IMMOBILE = "${it.IDIMMOBILE}-${it.RIGA}"

            it.POSSESSOPERC = null
            if (it.NUMERATORE?.trim()?.isNumber() && it.DENOMINATORE?.trim()?.isNumber() && (it.DENOMINATORE.trim() as Integer) > 0) {
                it.POSSESSO += "(${numero.format(((it.NUMERATORE.trim() as BigDecimal) / (it.DENOMINATORE.trim() as BigDecimal)) * 100)})"
                it.POSSESSOPERC = ((it.NUMERATORE.trim() as BigDecimal) / (it.DENOMINATORE.trim() as BigDecimal)) * 100
            }
        }
    }

    def getProprietari(def filtro, def params = [:], def order = "alfabetico", def recuperaPartita = true) {

        def filtri = [:]

        def where = ""
        def whereQueryInterna = ""

        filtro.cognomeNome = null

        if (filtro.cognome && filtro.nome) {
            filtro.cognomeNome = filtro.cognome + "%/" + filtro.nome
        } else if (filtro.cognome && !filtro.nome) {
            filtro.cognomeNome = filtro.cognome + "%"
        } else if (!filtro.cognome && filtro.nome) {
            filtro.cognomeNome = "%/" + filtro.nome
        }

        if (filtro?.cognomeNome) {
            filtri << ['cognomeNome': filtro.cognomeNome.toUpperCase() + '%']
            where += """ AND COGNOMENOMERIC like :cognomeNome """
        }
        if (filtro.codiceFiscale) {
            filtri << ['codiceFiscale': filtro.codiceFiscale.toUpperCase() + '%']
            where += """ AND CODFISCALE like :codiceFiscale """
        }
        if (recuperaPartita && filtro.partita) {
            filtri << ['partita': filtro.partita.toUpperCase() + '%']
            where += """ AND PARTITA like :partita """
        }
        if (filtro.validitaDal) {
            whereQueryInterna += """ AND nvl(data_fine_validita, to_date('20991231', 'YYYYMMDD')) >= TO_DATE('${filtro.validitaDal.format('yyyyMMdd')}', 'YYYYMMDD')"""
        }
        if (filtro.validitaAl) {
            whereQueryInterna += """ AND DATA_VALIDITA <= TO_DATE('${filtro.validitaAl.format('yyyyMMdd')}', 'YYYYMMDD')"""
        }

        def orderBy = ""

        if (order == "alfabetico") {
            orderBy = "order by translate(COGNOMENOME, '/', ' '), DATANASCITA, CODFISCALE"
        } else {
            orderBy = "order by CODFISCALE"
        }

        String sql = """
                 select *
                      from (select distinct prop.des_com_sede SEDE,
                                            prop.sigla_pro_sede PROVINCIASEDE,
                                            prop.cod_fiscale CODFISCALE,
                                            prop.des_com_nas LUOGONASCITA,
                                            prop.sigla_pro_nas PROVINCIANASCITA,
                                            prop.data_nas DATANASCITA,
                                            prop.cognome_nome_ric COGNOMENOMERIC,
                                            translate(prop.cognome_nome, '/', ' ') COGNOMENOME,
                                            prop.cognome_nome nominativo,
                                            prop.id_soggetto "idSoggetto",
                                            ${recuperaPartita ? 'prop.partita PARTITA,' : ''}
                                            substr(prop.cognome_nome,
                                                   1,
                                                   instr(prop.cognome_nome, '/') - 1) COGNOME,
                                            substr(prop.cognome_nome,
                                                   instr(prop.cognome_nome, '/') + 1) NOME,
                                            c.ni
                              from proprietari_catasto_urbano prop, contribuenti c
                              where nvl(prop.cod_fiscale, 0) = nvl(c.cod_fiscale(+), 0)
                                ${whereQueryInterna})
                     where 1 = 1
                        ${where}
                        ${orderBy}
        """

        String sqlTotali = "select count(*) as total_count from (${sql})"

        def totalCount = eseguiQuery(sqlTotali, filtri, null, true)[0].TOTAL_COUNT

        params.max = params?.pageSize ?: 30
        params.activePage = params?.activePage ?: 0
        params.offset = params.activePage * params.pageSize

        def results = eseguiQuery(sql, filtri, params, false)

        return [data: results, totalCount: totalCount]
    }

    def getImmobiliDaProprietario(def filtro, def params = [:]) {

        params.pageSize = params?.pageSize ?: 30
        params.activePage = params?.activePage ?: 0
        params.offset = params.activePage * params.pageSize

        def sql = """
                 select *
                      from (select distinct 'F' TIPOOGGETTO,
                                            immobili_soggetto_cc.indirizzo INDIRIZZOCOMPLETO,
                                            immobili_soggetto_cc.partita,
                                            immobili_soggetto_cc.sezione,
                                            immobili_soggetto_cc.foglio,
                                            immobili_soggetto_cc.numero,
                                            immobili_soggetto_cc.subalterno,
                                            immobili_soggetto_cc.zona,
                                            immobili_soggetto_cc.num_civ NUMCIV,
                                            lpad(sezione, 3) sezione_o,
                                            lpad(foglio, 5) foglio_o,
                                            lpad(numero, 5) numero_o,
                                            lpad(subalterno, 4) subalterno_o,
                                            lpad(zona, 3) zona_o,
                                            immobili_soggetto_cc.categoria CATEGORIACATASTO,
                                            immobili_soggetto_cc.classe CLASSECATASTO,
                                            lpad(immobili_soggetto_cc.num_civ, 20) n_civ,
                                            to_char(to_number(rtrim(ltrim(immobili_soggetto_cc.rendita))) /
                                            decode(dati_generali.fase_euro,
                                                   1,
                                                   1,
                                                   decode(dati_generali.flag_catasto_cu,
                                                          'S',
                                                          100,
                                                          1))) rendita,
                                            immobili_soggetto_cc.scala,
                                            immobili_soggetto_cc.interno,
                                            immobili_soggetto_cc.piano,
                                            immobili_soggetto_cc.contatore IDFABBRICATO,
                                            to_number(:p_id_soggetto) id_soggetto,
                                            immobili_soggetto_cc.numeratore numeratore,
                                            immobili_soggetto_cc.denominatore denominatore,
                                            null are,
                                            null centiare,
                                            immobili_soggetto_cc.rendita_euro redditodominicale,
                                            null redditoagrario,
                                            null qualita,
                                            immobili_soggetto_cc.data_efficacia DATAEFFICACIAINIZIO,
                                            immobili_soggetto_cc.data_fine_efficacia DATAEFFICACIAFINE,
                                            immobili_soggetto_cc.data_validita DATAVALIDITAINIZIO,
                                            immobili_soggetto_cc.data_fine_validita DATAVALIDITAFINE,
                                            null descrizione,
                                            immobili_soggetto_cc.cod_titolo || ' - ' ||
                                            immobili_soggetto_cc.des_diritto DESDIRITTO,
                                            immobili_soggetto_cc.des_titolo TITOLO,
                                            immobili_soggetto_cc.note,
                                            immobili_soggetto_cc.consistenza,
                                            immobili_soggetto_cc.superficie,
                                            decode(immobili_soggetto_cc.numeratore,
                                                   null,
                                                   '',
                                                   immobili_soggetto_cc.numeratore || '/' ||
                                                   immobili_soggetto_cc.denominatore) possesso,
                                            null ettari,
                                            immobili_soggetto_cc.progr_identificativo,
                                            (select distinct nvl(FAB1.SEZIONE || '/', ' /') ||
                                                NVL(FAB1.FOGLIO || '/', ' /') ||
                                                NVL(FAB1.NUMERO || '/', ' /') ||
                                                NVL(FAB1.SUBALTERNO, '')
                                                 from immobili_soggetto_cc fab1
                                                where fab1.progr_identificativo = 1
                                                and fab1.cod_fiscale_ric = immobili_soggetto_cc.cod_fiscale_ric 
                                                and fab1.contatore = immobili_soggetto_cc.contatore
                                                and immobili_soggetto_cc.progr_identificativo != 1) PRINCIPALE
                              from immobili_soggetto_cc, dati_generali
                             where immobili_soggetto_cc.tipo_immobile = 'F'
                               and immobili_soggetto_cc.proprietario = :p_id_soggetto
                               and immobili_soggetto_cc.data_efficacia <=
                                   to_date(:p_data_a, 'ddmmyyyy')
                               and nvl(immobili_soggetto_cc.data_fine_efficacia,
                                       decode(immobili_soggetto_cc.partita,
                                              'C',
                                              immobili_soggetto_cc.data_efficacia,
                                              to_date('31129999', 'ddmmyyyy'))) >=
                                   to_date(:p_data_da, 'ddmmyyyy')
                            union all
                            select 'T' tipo_immobile,
                                   immobili_catasto_terreni.indirizzo,
                                   immobili_catasto_terreni.partita,
                                   null sezione,
                                   immobili_catasto_terreni.foglio,
                                   immobili_catasto_terreni.numero,
                                   immobili_catasto_terreni.subalterno,
                                   null zona,
                                   immobili_catasto_terreni.num_civ,
                                   null sezione_o,
                                   lpad(foglio, 5) foglio_o,
                                   lpad(numero, 5) numero_o,
                                   lpad(subalterno, 4) subalterno_o,
                                   null zona_o,
                                   null categoria,
                                   immobili_catasto_terreni.classe,
                                   lpad(immobili_catasto_terreni.num_civ, 20) n_civ,
                                   null rendita,
                                   null scala,
                                   null interno,
                                   null piano,
                                   immobili_catasto_terreni.id_immobile IDFABBRICATO,
                                   to_number(:p_id_soggetto) id_soggetto,
                                   proprietari_catasto_urbano.numeratore numeratore,
                                   proprietari_catasto_urbano.denominatore denominatore,
                                   immobili_catasto_terreni.are,
                                   immobili_catasto_terreni.centiare,
                                   immobili_catasto_terreni.reddito_dominicale_euro,
                                   immobili_catasto_terreni.reddito_agrario_euro,
                                   immobili_catasto_terreni.qualita,
                                   immobili_catasto_terreni.data_efficacia,
                                   immobili_catasto_terreni.data_fine_efficacia,
                                   proprietari_catasto_urbano.data_validita,
                                   proprietari_catasto_urbano.data_fine_validita,
                                   tipi_qualita.descrizione qualitades,
                                   null des_diritto,
                                   null des_titolo,
                                   null note,
                                   null consistenza,
                                   null superficie,
                                   decode(proprietari_catasto_urbano.numeratore,
                                          null,
                                          '',
                                          proprietari_catasto_urbano.numeratore || '/' ||
                                          proprietari_catasto_urbano.denominatore) possesso,
                                   immobili_catasto_terreni.ettari,
                                   1    progr_identificativo,
                                   ''
                              from immobili_catasto_terreni,
                                   proprietari_catasto_urbano,
                                   tipi_qualita
                             where proprietari_catasto_urbano.tipo_immobile = 'T'
                               and proprietari_catasto_urbano.id_soggetto = :p_id_soggetto
                               and proprietari_catasto_urbano.id_immobile =
                                   immobili_catasto_terreni.id_immobile
                               and proprietari_catasto_urbano.id_soggetto =
                                   immobili_catasto_terreni.id_soggetto
                               and tipi_qualita.tipo_qualita(+) =
                                   immobili_catasto_terreni.qualita
                               and immobili_catasto_terreni.data_efficacia <=
                                   to_date(:p_data_a, 'ddmmyyyy')
                               and nvl(immobili_catasto_terreni.data_fine_efficacia,
                                       decode(immobili_catasto_terreni.partita,
                                              '0000000',
                                              immobili_catasto_terreni.data_efficacia,
                                              to_date('31129999', 'ddmmyyyy'))) >=
                                   to_date(:p_data_da, 'ddmmyyyy'))
                     order by IDFABBRICATO,
                              DATAEFFICACIAINIZIO,
                              DATAEFFICACIAFINE,
                              DATAVALIDITAINIZIO,
                              DATAVALIDITAFINE,
                              lpad(sezione, 3),
                              lpad(foglio, 5),
                              lpad(numero, 5),
                              lpad(subalterno, 4),
                              lpad(zona, 3)
        """

        def totalCount = params.pageSize == Integer.MAX_VALUE ? 0 :
                sessionFactory.currentSession.createSQLQuery("select count(*) from (${sql})").with {
                    setLong('p_id_soggetto', filtro.idSoggetto as Long)
                    setString('p_data_da', filtro.dataDa)
                    setString('p_data_a', filtro.dataA)
                    list()
                }[0]

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setLong('p_id_soggetto', filtro.idSoggetto as Long)
            setString('p_data_da', filtro.dataDa)
            setString('p_data_a', filtro.dataA)

            setFirstResult(params.offset)
            setMaxResults(params.pageSize)
            list()
        }

        results.each {
            it.REDDITODOMINICALE = it.REDDITODOMINICALE ? it.REDDITODOMINICALE.replace(',', '.') as BigDecimal : null
            it.REDDITOAGRARIO = it.REDDITOAGRARIO ? it.REDDITOAGRARIO.replace(',', '.') as BigDecimal : null
            it.RENDITA = it.RENDITA ? it.RENDITA.replace(',', '.') as BigDecimal : null
            it.CONSISTENZA = it.CONSISTENZA ? it.CONSISTENZA.replace(',', '.') as BigDecimal : null
            it.SUPERFICIE = it.SUPERFICIE ? it.SUPERFICIE.replace(',', '.') as BigDecimal : null
            it.ETTARI = it.ETTARI ? it.ETTARI.replace(',', '.') as BigDecimal : null
            it.ARE = it.ARE ? it.ARE.replace(',', '.') as BigDecimal : null
            it.CENTIARE = it.CENTIARE ? it.CENTIARE.replace(',', '.') as BigDecimal : null

            it.RENDITAREDDDOM = it.TIPOOGGETTO == 'F' ? it.RENDITA : it.REDDITODOMINICALE

            it.isGraffato = it.PROGR_IDENTIFICATIVO != 1
        }

        return [data: results, totalCount: totalCount]
    }

    // Riporta elenco propietari catastali da CF Contribuente tramite CONTRIBUENTI_CC_SOGGETTI
    def getProprietariDaCFContribuente(def filtro, def params = [:], def order = "alfabetico") {

        params.pageSize = params?.pageSize ?: 30
        params.activePage = params?.activePage ?: 0
        params.offset = params.activePage * params.pageSize

        def where = ""
        if (filtro.codiceFiscaleContribuente) {
            where += """ AND COCS.COD_FISCALE = '${filtro.codiceFiscaleContribuente.toUpperCase()}'"""
        }

        def orderBy = ""
        if (order == "alfabetico") {
            orderBy = "order by translate(COGNOMENOME, '/', ' '), DATANASCITA, CODFISCALE"
        } else {
            orderBy = "order by CODFISCALE"
        }

        def sql = """
			        SELECT * FROM
			              (
			              	SELECT DISTINCT
				                PRCU.COD_FISCALE_RIC CODFISCALE,
				                PRCU.DES_COM_SEDE SEDE,
				                PRCU.SIGLA_PRO_SEDE PROVINCIASEDE,
				                PRCU.DES_COM_NAS LUOGONASCITA,
				                PRCU.SIGLA_PRO_NAS PROVINCIANASCITA,
				                PRCU.DATA_NAS DATANASCITA,
				                TRANSLATE(PRCU.COGNOME_NOME_RIC, '/', ' ') COGNOMENOME,
				            /*	PRCU.COGNOME_NOME_RIC NOMINATIVO, */
				                PRCU.ID_SOGGETTO IDSOGGETTO,
				            /*	SUBSTR(PRCU.COGNOME_NOME_RIC,1,INSTR(PRCU.COGNOME_NOME_RIC, '/') - 1) COGNOME, */
				            /*  SUBSTR(PRCU.COGNOME_NOME_RIC,INSTR(PRCU.COGNOME_NOME_RIC, '/') + 1) NOME, */
								COCS.NOTE NOTE_SEQUENZA,
				                COCS.COD_FISCALE CODFISCALE_CONTR,
				                COCS.ID IDSEQUENZA
			              	FROM PROPRIETARI_CATASTO_URBANO PRCU,
								CONTRIBUENTI_CC_SOGGETTI COCS
			              	WHERE PRCU.ID_SOGGETTO = COCS.ID_SOGGETTO
	                        	${where}
			              )
			        WHERE 1 = 1
                        ${orderBy}
        """

        def totalCount =
                sessionFactory.currentSession.createSQLQuery("SELECT COUNT(*) FROM (${sql})").with {
                    list()
                }[0]

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setFirstResult(params.offset)
            setMaxResults(params.pageSize)
            list()
        }

        return [data: results, totalCount: totalCount]
    }

    // Riporta elenco ID propietari catastali da CF Contribuente tramite CONTRIBUENTI_CC_SOGGETTI
    def getIDProprietariDaCFContribuente(String codiceFiscaleContribuente) {

        def where = """ AND COCS.COD_FISCALE like '${codiceFiscaleContribuente.toUpperCase()}%'"""

        def sql = """
					SELECT DISTINCT
						PRCU.ID_SOGGETTO IDSOGGETTO
					FROM PROPRIETARI_CATASTO_URBANO PRCU,
						CONTRIBUENTI_CC_SOGGETTI COCS
					WHERE PRCU.ID_SOGGETTO = COCS.ID_SOGGETTO
	                	${where}
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return [data: results]
    }

    // Riporta elenco propietari catastali escluso corrispondenza CF
    def getProprietariNoCF(def filtro, def params = [:], def order = "alfabetico") {

        params.pageSize = params?.pageSize ?: 30
        params.activePage = params?.activePage ?: 0
        params.offset = params.activePage * params.pageSize

        def whereIn = ""
        def whereOut = ""
        if (filtro.cognome) {
            whereOut += """ AND COGNOME_NOME like '${filtro.cognome.toUpperCase()}%'"""
        }
        if (filtro.nome) {
            whereOut += """ AND NOME like '${filtro.nome.toUpperCase()}%'"""
        }
        if (filtro.codiceFiscale) {
            whereIn += """ AND COD_FISCALE_RIC like '${filtro.codiceFiscale.toUpperCase()}%'"""
        }
        if (filtro.codiceFiscaleEscluso) {
            whereIn += """ AND COD_FISCALE_RIC != '${filtro.codiceFiscaleEscluso.toUpperCase()}'"""
        }

        def orderBy = ""

        if (order == "alfabetico") {
            orderBy = "order by COGNOME_NOME, DATA_NAS, COD_FISCALE"
        } else {
            orderBy = "order by COD_FISCALE"
        }

        def sql = """
					SELECT * FROM
						  (
							SELECT 
								PRCU.COD_FISCALE_RIC COD_FISCALE,
								PRCU.DES_COM_SEDE DES_COM_SEDE,
								PRCU.SIGLA_PRO_SEDE SIGLA_PRO_SEDE,
								PRCU.DES_COM_NAS DES_COM_NAS,
								PRCU.SIGLA_PRO_NAS SIGLA_PRO_NAS,
								PRCU.DATA_NAS DATA_NAS,
								TRANSLATE(PRCU.COGNOME_NOME_RIC,'/',' ') COGNOME_NOME,
							/*	PRCU.COGNOME_NOME_RIC NOMINATIVO, */
				                SUBSTR(PRCU.COGNOME_NOME_RIC,1,INSTR(PRCU.COGNOME_NOME_RIC, '/') - 1) COGNOME,
				                SUBSTR(PRCU.COGNOME_NOME_RIC,INSTR(PRCU.COGNOME_NOME_RIC, '/') + 1) NOME,
								PRCU.ID_SOGGETTO
							FROM PROPRIETARI_CATASTO_URBANO PRCU
							WHERE 1 = 1
								${whereIn}
							GROUP BY
								COD_FISCALE_RIC, COGNOME_NOME_RIC, DES_COM_SEDE, SIGLA_PRO_SEDE,
								DES_COM_NAS, SIGLA_PRO_NAS, DATA_NAS, ID_SOGGETTO
						  )
					WHERE 1 = 1
						${whereOut}
						${orderBy}
		"""

        def totalCount =
                sessionFactory.currentSession.createSQLQuery("SELECT COUNT(*) FROM (${sql})").with {
                    list()
                }[0]

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setFirstResult(params.offset)
            setMaxResults(params.pageSize)
            list()
        }

        return [data: results, totalCount: totalCount]
    }

    // Crea Assegnazioni Soggetto Catasto nel database
    def creaAssegnazioniSoggettoCatasto(String cfContribuente, Long idCCSoggetto) {

        ContribuenteCcSoggetto cccSoggetto = new ContribuenteCcSoggetto()

        cccSoggetto.contribuente = Contribuente.findByCodFiscale(cfContribuente)
        cccSoggetto.id_soggetto = idCCSoggetto

        cccSoggetto.note = null

        cccSoggetto.save(failOnError: true, flush: true)
    }

    // Modifica Assegnazioni Soggetto Catasto dal database
    def modificaAssegnazioniSoggettoCatasto(Long idSequenza, String note) {

        ContribuenteCcSoggetto cccSoggetto = ContribuenteCcSoggetto.get(idSequenza)

        cccSoggetto.note = note

        cccSoggetto.save(failOnError: true, flush: true)
    }

    // Elimina Assegnazioni Soggetto Catasto dal database
    def eliminaAssegnazioniSoggettoCatasto(Long idSequenza) {

        ContribuenteCcSoggetto cccSoggetto = ContribuenteCcSoggetto.get(idSequenza)
        cccSoggetto.delete(flush: true)
    }

    // Crea la lista delle assegnazioni soggetti e contribuenti
    def getListaAssegnazioniSoggettoCatasto() {

        def lista = ContribuenteCcSoggetto.createCriteria().list {
            fetchMode("contribuente", FetchMode.JOIN)
        }
        return lista

    }

    // Esegue query
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
