package it.finmatica.tr4.oggetti

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.RapportoTributo
import org.apache.commons.lang.StringUtils
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.runtime.InvokerHelper
import org.hibernate.FetchMode
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.text.DecimalFormat
import java.text.SimpleDateFormat

class OggettiService {

    private static Log log = LogFactory.getLog(OggettiService)

    static transactional = false
    def springSecurityService
    def dataSource
    def sessionFactory
    CommonService commonService

    DenunceService denunceService

    BigDecimal getMoltiplicatore(short anno, String categoriaCatasto) {
        List<MoltiplicatoreDTO> listaMoltiplicatori = OggettiCache.MOLTIPLICATORI.valore
        BigDecimal m = listaMoltiplicatori.find {
            it.anno == anno && it.categoriaCatasto.categoriaCatasto == categoriaCatasto
        }?.moltiplicatore ?: null
    }

    def listaOggettiAnniPrecedenti(def anno, String codFiscale, String tipoRapporto, String tipoTributo) {
        def oggettiAnniPrec = []
        def filtri = [:]

        filtri << ['p_anno': anno]
        filtri << ['p_codiceFiscale': codFiscale.trim().toUpperCase()]
        filtri << ['p_tipoTributo': tipoTributo]
        if (tipoTributo.equals("TASI") && tipoRapporto != 'E') {
            filtri << ['p_tipo_rapporto': tipoRapporto]
        }

        String query = """
						  SELECT OGGE.OGGETTO,   
                                 OGPR.OGGETTO_PRATICA,   
                                 OGGE.COD_VIA,
                                 OGGE.NUM_CIV,
                                 OGGE.SUFFISSO,
                                 OGGE.INTERNO,
                                 OGGE.INDIRIZZO_LOCALITA,
                                 ARVI.DENOM_UFF,
                                 OGGE.SEZIONE,   
                                 OGGE.FOGLIO,   
                                 OGGE.NUMERO,   
                                 OGGE.SUBALTERNO,   
                                 OGGE.ZONA,   
                                 OGGE.PARTITA,   
                                 OGGE.PROTOCOLLO_CATASTO,   
                                 OGGE.ANNO_CATASTO,   
                                 OGPR.TIPO_OGGETTO,   
                                 F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CA') categoria_catasto,   
                                 F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CL') classe_catasto, 
                                    nvl(to_number(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'RE')),
                                     F_RENDITA(OGPR.VALORE
                                              ,nvl(ogpr.tipo_oggetto,OGGE.TIPO_OGGETTO)
                                              ,:p_anno 
                                                     ,nvl(ogpr.categoria_catasto,OGGE.categoria_catasto)
                                              )
                                    ) rendita,  
                                 nvl(F_VALORE(( to_number(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'RE')) *
                                                decode(OGGE.TIPO_OGGETTO
                                                      ,1,nvl(molt.moltiplicatore,1)
                                                      ,3,nvl(molt.moltiplicatore,1)
                                                      ,1
                                                      )
                                               )
                                             ,  OGGE.TIPO_OGGETTO
                                             , 1996
                                             , :p_anno 
                                             , ' ' 
                                             ,prtr.tipo_pratica
                                             ,ogpr.flag_valore_rivalutato
                                             )
                                    ,F_VALORE( OGPR.VALORE
                                             , nvl(ogpr.tipo_oggetto,OGGE.TIPO_OGGETTO)
                                             , prtr.anno
                                             , :p_anno
                                             ,nvl(ogpr.categoria_catasto,OGGE.categoria_catasto)
                                             ,prtr.tipo_pratica
                                             ,ogpr.flag_valore_rivalutato
                                             )
                                    ) VALORE,   
                                 OGCO.PERC_POSSESSO,   
                                 OGCO.MESI_POSSESSO,   
                                 OGCO.MESI_POSSESSO_1SEM, 
                                 OGCO.MESI_ESCLUSIONE,   
                                 OGCO.MESI_RIDUZIONE,   
                                 OGCO.FLAG_POSSESSO,   
                                 OGCO.FLAG_ESCLUSIONE,   
                                 OGCO.FLAG_RIDUZIONE,   
                                 OGCO.FLAG_AB_PRINCIPALE,   
                                 decode( OGGE.COD_VIA, NULL, INDIRIZZO_LOCALITA, DENOM_UFF||decode( num_civ,NULL,'', ', '||num_civ )
                                    ||decode( suffisso,NULL,'', '/'||suffisso )) indirizzo,   
                                 OGPR.FLAG_PROVVISORIO,   
                                 OGCO.DETRAZIONE,
                                 PRTR.ANNO,
                                 F_ESISTE_DETRAZIONE_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:p_tipoTributo)   DETRAZIONE_OGCO, 
                                 F_ESISTE_ALIQUOTA_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:p_tipoTributo)   ALIQUOTA_OGCO,
                                 ogpr.flag_valore_rivalutato,
                                 prtr.tipo_pratica,
                                 OGCO.TIPO_RAPPORTO,
                                 ogco.perc_detrazione
                            FROM ARCHIVIO_VIE ARVI,   
                                 OGGETTI OGGE,   
                                 MOLTIPLICATORI MOLT,   
                                 PRATICHE_TRIBUTO PRTR,
                                 OGGETTI_PRATICA OGPR,   
                                 OGGETTI_CONTRIBUENTE OGCO  
                           WHERE prtr.tipo_tributo         = :p_tipoTributo and
                                 ogge.cod_via              = arvi.cod_via (+) and  
                                 OGCO.OGGETTO_PRATICA      = OGPR.OGGETTO_PRATICA and
                                 MOLT.ANNO(+)              = :p_anno AND  
                                 MOLT.CATEGORIA_CATASTO(+) = F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CA') AND   
                                 OGPR.PRATICA              = PRTR.PRATICA and  
                                 OGPR.OGGETTO              = OGGE.OGGETTO and  
                                 OGCO.COD_FISCALE          = :p_codiceFiscale and """
        if (tipoTributo.equals("TASI") && tipoRapporto != 'E') {
            query += """ OGCO.TIPO_RAPPORTO LIKE :p_tipo_rapporto and """
        }

        query += """     OGCO.FLAG_POSSESSO        = 'S' and
                                 (OGCO.ANNO||OGCO.TIPO_RAPPORTO||'S') = 
                                 ( SELECT max (OGCO_SUB.ANNO||OGCO_SUB.TIPO_RAPPORTO||OGCO_SUB.FLAG_POSSESSO)  
                                     FROM PRATICHE_TRIBUTO PRTR_SUB,   
                                          OGGETTI_PRATICA OGPR_SUB,   
                                          OGGETTI_CONTRIBUENTE OGCO_SUB
                                    WHERE PRTR_SUB.TIPO_TRIBUTO||''  = :p_tipoTributo and  
                                          (PRTR_SUB.TIPO_PRATICA||'' = 'D' and
                                           PRTR_SUB.DATA_NOTIFICA is null or
                                           PRTR_SUB.TIPO_PRATICA||'' = 'A' and
                                           PRTR_SUB.DATA_NOTIFICA is not null and
                                           nvl(PRTR_SUB.STATO_ACCERTAMENTO,'D') = 'D' and
                                           nvl(PRTR_SUB.FLAG_DENUNCIA,' ') = 'S' and
                                           PRTR_SUB.ANNO <= :p_anno
                                          ) and
                                          PRTR_SUB.PRATICA           = OGPR_SUB.PRATICA and  
                                          OGCO_SUB.ANNO             <= :p_anno          and 
                                          OGCO_SUB.COD_FISCALE       = OGCO.COD_FISCALE and
                                          OGCO_SUB.OGGETTO_PRATICA   = OGPR_SUB.OGGETTO_PRATICA and  
                                          OGPR_SUB.OGGETTO         = OGPR.OGGETTO
                                 )
                            UNION
                          SELECT OGGE.OGGETTO,   
                                 OGPR.OGGETTO_PRATICA,   
                                 OGGE.COD_VIA,
                                 OGGE.NUM_CIV,
                                 OGGE.SUFFISSO,
                                 OGGE.INTERNO,
                                 OGGE.INDIRIZZO_LOCALITA,
                                 ARVI.DENOM_UFF,
                                 OGGE.SEZIONE,   
                                 OGGE.FOGLIO,   
                                 OGGE.NUMERO,   
                                 OGGE.SUBALTERNO,   
                                 OGGE.ZONA,   
                                 OGGE.PARTITA,   
                                 OGGE.PROTOCOLLO_CATASTO,   
                                 OGGE.ANNO_CATASTO,   
                                 OGGE.TIPO_OGGETTO,   
                                 F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CA') categoria_catasto,   
                                 F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CL') classe_catasto,   
                                    nvl(to_number(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'RE')),
                                     F_RENDITA(OGPR.VALORE
                                              ,nvl(ogpr.tipo_oggetto,OGGE.TIPO_OGGETTO)
                                              ,:p_anno 
                                                     ,nvl(ogpr.categoria_catasto,OGGE.categoria_catasto)
                                              )
                                    ) rendita,  
                                 nvl(F_VALORE(( to_number(F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'RE')) *
                                                decode(OGGE.TIPO_OGGETTO
                                                      ,1,nvl(molt.moltiplicatore,1)
                                                      ,3,nvl(molt.moltiplicatore,1)
                                                      ,1
                                                      )
                                               )
                                             ,  OGGE.TIPO_OGGETTO
                                             , 1996
                                             , :p_anno 
                                             ,' ' 
                                             ,prtr.tipo_pratica
                                             ,ogpr.flag_valore_rivalutato
                                             )
                                    ,F_VALORE( OGPR.VALORE, nvl(ogpr.tipo_oggetto,OGGE.TIPO_OGGETTO)
                                             , prtr.anno
                                             , :p_anno
                                             , nvl(ogpr.categoria_catasto,OGGE.categoria_catasto)
                                             ,prtr.tipo_pratica
                                             ,ogpr.flag_valore_rivalutato
                                             )
                                    ) VALORE,  
                                 OGCO.PERC_POSSESSO,   
                                 OGCO.MESI_POSSESSO,   
                                 OGCO.MESI_POSSESSO_1SEM,
                                 OGCO.MESI_ESCLUSIONE,   
                                 OGCO.MESI_RIDUZIONE,   
                                 OGCO.FLAG_POSSESSO,   
                                 OGCO.FLAG_ESCLUSIONE,   
                                 OGCO.FLAG_RIDUZIONE,   
                                 OGCO.FLAG_AB_PRINCIPALE,   
                                 decode( OGGE.COD_VIA, NULL, INDIRIZZO_LOCALITA, DENOM_UFF||decode( num_civ,NULL,'', ', '||num_civ )
                                    ||decode( suffisso,NULL,'', '/'||suffisso )||decode( interno,NULL, '',' int. '||interno)),   
                                 OGPR.FLAG_PROVVISORIO,   
                                 OGCO.DETRAZIONE,
                                 PRTR.ANNO,
                                 F_ESISTE_DETRAZIONE_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:p_tipoTributo) , 
                                 F_ESISTE_ALIQUOTA_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:p_tipoTributo),
                                 ogpr.flag_valore_rivalutato,
                                 prtr.tipo_pratica, 
                                 OGCO.TIPO_RAPPORTO,
                                 ogco.perc_detrazione
                            FROM ARCHIVIO_VIE ARVI,   
                                 MOLTIPLICATORI MOLT,   
                                 OGGETTI OGGE,   
                                 PRATICHE_TRIBUTO PRTR,   
                                 OGGETTI_PRATICA OGPR,   
                                 OGGETTI_CONTRIBUENTE OGCO  
                           WHERE ogge.cod_via              = arvi.cod_via (+) AND
                                 MOLT.ANNO(+)              = :p_anno AND  
                                 MOLT.CATEGORIA_CATASTO(+) = F_MAX_RIOG(OGPR.OGGETTO_PRATICA,:p_anno,'CA') AND  
                                 OGCO.OGGETTO_PRATICA      = OGPR.OGGETTO_PRATICA AND
                                 OGPR.PRATICA              = PRTR.PRATICA AND
                                 OGPR.OGGETTO              = OGGE.OGGETTO AND """

        if (tipoTributo.equals("TASI") && tipoRapporto != 'E') {
            query += """ OGCO.TIPO_RAPPORTO LIKE :p_tipo_rapporto and """
        }

        query += """     PRTR.TIPO_TRIBUTO||''     = :p_tipoTributo AND
                                 PRTR.TIPO_PRATICA||''  in ('V','D') AND
                                 OGCO.FLAG_POSSESSO     IS NULL AND
                                 OGCO.COD_FISCALE          = :p_codiceFiscale AND
                                 OGCO.ANNO                 = :p_anno
                           ORDER BY  
                                 9,10,11,12,1 ASC """

        def results = eseguiQuery("${query}", filtri, null, true)

        results.each {
            long idOggettoPratica = it['OGGETTO_PRATICA']
            def tr = it['TIPO_RAPPORTO']

            OggettoContribuenteDTO ogco = OggettoContribuente.createCriteria().get {
                createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
                createAlias("aliquoteOgco", "alog", CriteriaSpecification.LEFT_JOIN)
                createAlias("detrazioniOgco", "deog", CriteriaSpecification.LEFT_JOIN)
                createAlias("deog.motivoDetrazione", "mode", CriteriaSpecification.LEFT_JOIN)
                createAlias("attributiOgco", "atog", CriteriaSpecification.LEFT_JOIN)
                createAlias("atog.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)

                eq("contribuente.codFiscale", codFiscale)
                eq("ogpr.id", idOggettoPratica)

            }?.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])

            oggettiAnniPrec << ogco
        }

        return oggettiAnniPrec
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

    // Ricava vaqlore dichiarato Oggetto Pratica
    def getValoreOgPrDic(String tipoTributo, String codFiscale, Short anno, Long oggettoPratica) {

        if (!tipoTributo in ['ICI', 'TASI']) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]
        filtri << ['oggettoPratica': oggettoPratica]

        String sql

        if (tipoTributo in ['ICI', 'TASI']) {
            sql = """
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					nvl(to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')),
						F_RENDITA(OGPR.VALORE
								,nvl(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								,OGPR.ANNO
								,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
							  )
					) AS RENDITA,
					nvl(F_VALORE((to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')) *
								decode(OGGE.TIPO_OGGETTO
									  ,1,nvl(molt.moltiplicatore,1)
									  ,3,nvl(molt.moltiplicatore,1)
									  ,1
									  )
							   )
							 , OGGE.TIPO_OGGETTO
							 , 1996
							 , :anno
							 , ' '
							 ,PRAT.TIPO_PRATICA
							 ,OGPR.FLAG_VALORE_RIVALUTATO
							 )
						, F_VALORE(OGPR.VALORE
								 , NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								 , PRAT.ANNO
								 , :anno
								 ,NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
								 ,PRAT.TIPO_PRATICA
								 ,OGPR.FLAG_VALORE_RIVALUTATO
								 )
					) AS VALORE
				FROM
					OGGETTI OGGE,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					PRATICHE_TRIBUTO PRAT,
					MOLTIPLICATORI MOLT
				WHERE
					OGGE.OGGETTO = OGPR.OGGETTO AND
					OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND
					OGPR.ANNO = OGCO.ANNO AND
					PRAT.PRATICA = OGPR.PRATICA AND
					OGPR.OGGETTO_PRATICA = :oggettoPratica AND
					MOLT.ANNO(+) = :anno AND
					MOLT.CATEGORIA_CATASTO(+) = f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') AND
					OGCO.COD_FISCALE = :codFiscale
		"""
        }

        def results = eseguiQuery("${sql}", filtri, null, true)
        def valore = [:]

        if (results.size() > 0) {
            valore = getDatiValoreFromRow(results[0])
        }

        return valore
    }

    // Ricava valore Liquidazione Oggetto Pratica
    def getValoreOgPrLiq(String tipoTributo, String codFiscale, Short anno, Long oggettoPratica) {

        if (!(tipoTributo in ['ICI', 'TASI'])) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        def filtri = [:]

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]
        filtri << ['oggettoPratica': oggettoPratica]

        String sql

        if (tipoTributo in ['ICI', 'TASI']) {
            sql = """
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.VALORE AS VALORE,
					f_rendita(OGPR.VALORE,nvl(OGPR.tipo_oggetto,OGGE.TIPO_OGGETTO),:anno,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)) AS RENDITA 
				FROM
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					OGGETTI_IMPOSTA OGIM,
					PRATICHE_TRIBUTO PRAT
				WHERE
					PRAT.TIPO_PRATICA = 'L' AND
					PRAT.TIPO_EVENTO = 'U' AND
					PRAT.ANNO = :anno AND
					PRAT.PRATICA = OGPR.PRATICA AND
					PRAT.DATA_NOTIFICA IS NOT NULL AND
					OGIM.ANNO(+) = :anno AND
					OGIM.COD_FISCALE(+) = OGCO.COD_FISCALE AND
					OGIM.OGGETTO_PRATICA(+) = OGCO.OGGETTO_PRATICA AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.OGGETTO = OGGE.OGGETTO AND
					OGPR.OGGETTO_PRATICA_RIF = :oggettoPratica AND
					(NOT EXISTS
						(SELECT 1 
						 FROM
							OGGETTI_CONTRIBUENTE OGCO_LIQ, 
							OGGETTI_PRATICA OGPR_LIQ, 
							OGGETTI_IMPOSTA OGIM_LIQ,
							PRATICHE_TRIBUTO PRTR_LIQ
						WHERE
							PRTR_LIQ.TIPO_PRATICA = 'L' AND 
							PRTR_LIQ.TIPO_EVENTO = 'R' AND
							PRTR_LIQ.ANNO = :anno AND
							PRTR_LIQ.PRATICA = OGPR_LIQ.PRATICA AND 
							PRTR_LIQ.DATA_NOTIFICA IS NOT NULL AND 
							OGIM_LIQ.ANNO(+) = :anno AND
							OGIM_LIQ.COD_FISCALE(+) = OGCO_LIQ.COD_FISCALE AND
							OGIM_LIQ.OGGETTO_PRATICA(+) = OGCO_LIQ.OGGETTO_PRATICA AND 
							OGCO_LIQ.COD_FISCALE = :codFiscale AND
							OGCO_LIQ.OGGETTO_PRATICA = OGPR_LIQ.OGGETTO_PRATICA AND 
							OGPR_LIQ.OGGETTO_PRATICA_RIF = :oggettoPratica
						)
					) 
				UNION
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.VALORE AS VALORE,
					f_rendita(OGPR.VALORE,nvl(OGPR.tipo_oggetto,OGGE.TIPO_OGGETTO),:anno,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)) AS RENDITA 
				FROM
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					OGGETTI_IMPOSTA OGIM,
					PRATICHE_TRIBUTO PRAT
				WHERE
					PRAT.TIPO_PRATICA = 'L' AND
					PRAT.TIPO_EVENTO = 'R' AND
					PRAT.ANNO = :anno AND
					PRAT.PRATICA = OGPR.PRATICA AND
					PRAT.DATA_NOTIFICA IS NOT NULL AND
					OGIM.ANNO(+) = :anno AND
					OGIM.COD_FISCALE(+) = OGCO.COD_FISCALE AND
					OGIM.OGGETTO_PRATICA(+) = OGCO.OGGETTO_PRATICA AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.OGGETTO = OGGE.OGGETTO AND
					OGPR.OGGETTO_PRATICA_RIF = :oggettoPratica
			"""
        }

        def results = eseguiQuery("${sql}", filtri, null, true)
        def valore = [:]

        if (!results.empty) {
            valore = getDatiValoreFromRow(results[0])
        }

        return valore
    }

    // Estrae valore Oggetti Pratica da row del dataset
    def getDatiValoreFromRow(def row) {

        def oggetto = [:]

        oggetto.id = row['OGGETTO_PRATICA'] as Long

        oggetto.rendita = row['RENDITA'] as Double
        oggetto.valore = row['VALORE'] as Double

        return oggetto
    }

    /**
     * Esegue la funzione f_valore
     *
     * @param valore
     * @param tipoOggetto
     * @param annoDic
     * @param anno
     * @param categoriaCatasto
     * @param tipoPratica
     * @param flagRivalutato
     * @return
     */
    BigDecimal getFValore(BigDecimal valore, long tipoOggetto, short annoDic, short anno, String categoriaCatasto, String tipoPratica, boolean flagRivalutato) {
        BigDecimal v
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_valore(?, ?, ?, ?, ?, ?, ?)}'
                , [
                Sql.DECIMAL
                ,
                valore
                ,
                tipoOggetto
                ,
                annoDic
                ,
                anno
                ,
                categoriaCatasto
                ,
                tipoPratica
                ,
                flagRivalutato ? 'S' : null
        ]) { v = it }
        return v
    }

    /**
     * Esegue la f_max_riog per ritornare il valore??? relativo all'oggetto
     *
     * @param idOggettoPratica
     * @param anno
     * @param dato CA = categoria catasto, CL = classe catasto, RE = rendita
     * @return
     */
    String getMaxRiog(long idOggettoPratica, short anno, String dato) {
        String maxRiog
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_max_riog(?, ?, ?)}'
                , [
                Sql.VARCHAR
                ,
                idOggettoPratica
                ,
                anno
                ,
                dato
        ]) { maxRiog = it }
        return maxRiog
    }

    /**
     * Calcola la rendita di un OggettoPratica
     * @param valore
     * @param tipoOggetto
     * @param anno
     * @param categoriaCatasto
     * @return
     */
    BigDecimal getRenditaOggettoPratica(def valore, def tipoOggetto, def anno, def categoriaCatasto) {

        def ct = (categoriaCatasto instanceof CategoriaCatastoDTO) ? categoriaCatasto.categoriaCatasto : categoriaCatasto

        BigDecimal r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_rendita(?, ?, ?, ?)}'
                , [
                Sql.DECIMAL,
                valore,
                tipoOggetto,
                anno,
                ct
        ]) { r = it }
        return r as BigDecimal
    }

    /**
     * Restituisce la rendita da riferimenti_oggetto (RIOG) per
     * l'oggetto e l'anno indicati.
     * In presenza di più rendite valide per anno, restituisce
     * quella avente data di inizio validita' minore.
     * @param idOggetto
     * @param anno
     * @return
     */
    BigDecimal getRenditaDaRiferimentiOggetto(def idOggetto, def anno) {

        BigDecimal r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_GET_RENDITA_RIOG(?, ?)}'
                , [
                Sql.DECIMAL,
                idOggetto,
                anno
        ]) { r = it }
        return r as BigDecimal
    }
    // legge dati di classificazione catastale da riferimenti oggetto
    def getClassificazioneDaRiferimentiOggetto(def idOggetto, def anno) {

        String categoria
        String classe

        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_GET_RIOG_DATA(?, ?, ?, ?)}'
                , [
                Sql.VARCHAR,
                idOggetto,
                null,
                'CA',
                anno
        ]) { categoria = it }

        sql = new Sql(dataSource)
        sql.call('{? = call F_GET_RIOG_DATA(?, ?, ?, ?)}'
                , [
                Sql.VARCHAR,
                idOggetto,
                null,
                'CL',
                anno
        ]) { classe = it }

        return [categoria: categoria, classe: classe]
    }

    def listaOggetti(def listaFiltri, int pageSize, int activePage, def listaFetch) {

        def whereConditionClosure = { filtri ->
            createAlias("archivioVie", "via", CriteriaSpecification.LEFT_JOIN)
            createAlias("tipoOggetto", "tipoOggetto", CriteriaSpecification.LEFT_JOIN)
            createAlias("categoriaCatasto", "cat", CriteriaSpecification.LEFT_JOIN)

            //Nel caso di condizioni multiple bisogna definire una volta sola il createAlias
            boolean inserito = false
            for (FiltroRicercaOggetto filtro in filtri) {
                if (filtro.inPratica && !inserito) {
                    createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
                    createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                    createAlias("prtr.tipoTributo", "ttr", CriteriaSpecification.INNER_JOIN)
                    inserito = true
                }
            }

            or {
                for (FiltroRicercaOggetto filtro in filtri) {
                    and {
                        if (filtro.progressivo) {
                            eq("id", filtro.progressivo)
                        }
                        if (filtro.descrizione) {
			                ilike("descrizione", filtro.descrizione)
                        }
                        if (filtro.indirizzo) {
                            if (filtro.numCiv && filtro.numCiv =~ /%$/) {
                                sqlRestriction("LOWER(COALESCE({alias}.indirizzo_localita, via1_.denom_uff)) || ' ' || {alias}.num_civ like '" + filtro.indirizzo + " " + filtro.numCiv + "'")
                            } else {
                                or {
                                    ilike("indirizzoLocalita", filtro.indirizzo)
                                    ilike("via.denomUff", filtro.indirizzo)
                                }
                            }
                        }
                        if (filtro.numCiv && !(filtro.numCiv =~ /%$/)) {
                            eq("numCiv", Integer.valueOf(filtro.numCiv))
                        }
                        if (filtro.suffisso) {
                            eq("suffisso", filtro.suffisso)
                        }
                        if (filtro.codEcografico) {
                            eq("codEcografico", filtro.codEcografico)
                        }
                        if (filtro.interno) {
                            eq("interno", (short) filtro.interno)
                        }
                        if (filtro.tipoOggetto) {
                            eq("tipoOggetto.tipoOggetto", filtro.tipoOggetto.tipoOggetto)
                        }
                        if (filtro.foglio) {
                            eq("foglio", filtro.foglio)
                        }
                        if (filtro.subalterno) {
                            eq("subalterno", filtro.subalterno)
                        }
                        if (filtro.zona) {
                            eq("zona", filtro.zona)
                        }
                        if (filtro.partita) {
                            eq("partita", filtro.partita)
                        }
                        if (filtro.sezione) {
                            eq("sezione", filtro.sezione)
                        }
                        if (filtro.numero) {
                            eq("numero", filtro.numero)
                        }
                        if (filtro.cessato == "s") {
                            isNotNull("dataCessazione")
                        }
                        if (filtro.dataCessazioneDal) {
                            ge("dataCessazione", filtro.dataCessazioneDal)
                        }
                        if (filtro.dataCessazioneAl) {
                            le("dataCessazione", filtro.dataCessazioneAl)
                        }
                        if (filtro.categoriaCatasto) {
                            ilike("categoriaCatasto.categoriaCatasto", filtro.categoriaCatasto.categoriaCatasto)
                        }
                        if (filtro.classeCatasto) {
                            eq("classeCatasto", filtro.classeCatasto)
                        }
                        if (filtro.fonte) {
                            createAlias("fonte", "fonte", CriteriaSpecification.INNER_JOIN)
                            eq("fonte.fonte", filtro.fonte.fonte)
                        }

                        if (filtro.consistenzaDa || filtro.consistenzaA) {
                            isNotNull("consistenza")
                            between("consistenza", filtro.consistenzaDa ?: 0, filtro.consistenzaA ?: BigDecimal.HALF_LONG_MAX_VALUE)
                        }

                        if (filtro.latitudineDa || filtro.latitudineA) {
                            isNotNull("latitudine")
                            between("latitudine", filtro.latitudineDa ?: -90.0, filtro.latitudineA ?: 90.0)
                        }
                        if (filtro.longitudineDa || filtro.longitudineA) {
                            isNotNull("longitudine")
                            between("longitudine", filtro.longitudineDa ?: -180.0, filtro.longitudineA ?: 180.0)
                        }
                        if (filtro.aLatitudineDa || filtro.aLatitudineA) {
                            isNotNull("aLatitudine")
                            between("aLatitudine", filtro.aLatitudineDa ?: -90.0, filtro.aLatitudineA ?: 90.0)
                        }
                        if (filtro.aLongitudineDa || filtro.aLongitudineA) {
                            isNotNull("aLongitudine")
                            between("aLongitudine", filtro.aLongitudineDa ?: -180.0, filtro.aLongitudineA ?: 180.0)
                        }

                        if (filtro.inPratica) {
                            //createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)

                            if (filtro.valoreDa || filtro.valoreA) {
                                between("ogpr.valore", filtro.valoreDa ?: 0, filtro.valoreA ?: BigDecimal.HALF_LONG_MAX_VALUE)
                            }

                            //createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                            def tipiTributo = []
                            filtro.cbTributi.each {
                                if (it.value) {
                                    tipiTributo << (it.key == 'TARI' ? 'TARSU' : it.key)
                                }
                            }
                            if (tipiTributo) {
                                //createAlias("prtr.tipoTributo", "ttr", CriteriaSpecification.INNER_JOIN)

                                if (tipiTributo.indexOf("IMU") != -1) {
                                    tipiTributo.add("ICI")
                                }
                                'in'("ttr.tipoTributo", tipiTributo)
                            }

                            def tipiPratica = []
                            filtro.cbTipiPratica.each {
                                if (it.value) {
                                    tipiPratica << it.key
                                }
                            }
                            if (tipiPratica) {
                                'in'("prtr.tipoPratica", tipiPratica)
                            }
                        }

                        if (filtro.filtriSoggetto.codFiscale) {
                            // Se non è richiesto il filtro sulla pratica si deve sreare l'alias
                            // altimenti è creato nell'if precedente
                            if (!filtro.inPratica) {
                                createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
                            }
                            createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                            ilike("ogco.contribuente.codFiscale", filtro.filtriSoggetto.codFiscale + '%')
                        }
                    }
                }
            }
        }

        def elencoOggetti = Oggetto.createCriteria().list() {

            whereConditionClosure.delegate = delegate
            whereConditionClosure(listaFiltri)
            //
            projections {
                groupProperty("id")                    //0
                groupProperty("categoriaCatasto")    //1
                groupProperty("tipoOggetto")        //2
                groupProperty("tipoOggetto.descrizione") //3
                groupProperty("classeCatasto")        //4
                groupProperty("indirizzoLocalita")    //5
                groupProperty("archivioVie")        //6
                groupProperty("numCiv")                //7
                groupProperty("suffisso")            //8
                groupProperty("fonte")                //9
                groupProperty("foglio")                //10
                groupProperty("numero")                //11
                groupProperty("subalterno")            //12
                groupProperty("sezione")            //13
                groupProperty("partita")            //14
                groupProperty("protocolloCatasto")    //15
                groupProperty("annoCatasto")        //16
                groupProperty("zona")                //17
                groupProperty("dataCessazione")        //18
                groupProperty("scala")                //19
                groupProperty("piano")                //20
                groupProperty("interno")            //21
                groupProperty("consistenza")            //22
                groupProperty("descrizione")            //23
                groupProperty("latitudine")             //24
                groupProperty("longitudine")            //25
                groupProperty("aLatitudine")            //26
                groupProperty("aLongitudine")           //27
            }

            order("id", "asc")

            if (pageSize > 0) {
                firstResult(pageSize * activePage)
                maxResults(pageSize)
            }
        }.collect { row ->
            [id                  : row[0]
             , categoriaCatasto  : row[1]?.toDTO()
             , tipoOggetto       : row[2]?.toDTO()
             , descrizione       : row[23]
             , classeCatasto     : row[4]
             , indirizzo         : (row[6] ? row[6].denomUff : row[5] ?: "") +
                    (row[7] != null ? ", " + row[7] : "") +    // Numero civico
                    (row[8] != null ? "/" + row[8] : "") +    // Suffisso
                    (row[19] != null ? " Sc:" + row[19] : "") +    // Scala
                    (row[20] != null ? " P:" + row[20] : "") +    // Piano
                    (row[21] != null ? " In:" + row[21] : "")    // Interno
             , fonte             : row[9]?.toDTO()
             , foglio            : row[10]
             , numero            : row[11]
             , subalterno        : row[12]
             , sezione           : row[13]
             , partita           : row[14]
             , protocolloCatasto : row[15]
             , annoCatasto       : row[16]
             , zona              : row[17]
             , dataCessazione    : row[18]
             , estremiCatastoSort: (row[13] != null ? row[13].padLeft(3, '0') : " ".padLeft(3, '0')) +
                    (row[10] != null ? row[10].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[11] != null ? row[11].padLeft(5, '0') : " ".padLeft(5, '0')) +
                    (row[12] != null ? row[12].padLeft(4, '0') : " ".padLeft(4, '0')) +
                    (row[14] != null ? row[14].padLeft(3, '0') : " ".padLeft(3, '0'))
             , consistenza       : row[22]
             , latitudine        : row[24]
             , longitudine       : row[25]
             , latSessages       : formatCoordinateSexagesimalNS(row[24] as Double)
             , lonSessages       : formatCoordinateSexagesimalNS(row[25] as Double)
             , aLatitudine       : row[26]
             , aLongitudine      : row[27]
             , aLatSessages      : formatCoordinateSexagesimalNS(row[26] as Double)
             , aLonSessages      : formatCoordinateSexagesimalNS(row[27] as Double)
            ]
        }

        def totale = Oggetto.createCriteria().get() {
            whereConditionClosure.delegate = delegate
            whereConditionClosure(listaFiltri)

            projections { countDistinct("id") }
        }

        return [lista: elencoOggetti, totale: totale]
    }

    @Transactional
    def salvaOggettoContribuente(OggettoContribuenteDTO oggCoDTO, String tipoRapporto = null, String tipoTributo = "", boolean isCreaOggettoContitolare = false, def pratica = null) {

        def oggCo = oggCoDTO.toDomain()

        oggCo.utente = oggCo.utente ?: springSecurityService.currentUser?.id
        if (oggCo.contribuente == null) {
            def cont = Contribuente.findBySoggetto(oggCoDTO.contribuente.toDomain().soggetto)
            oggCo.contribuente = (cont) ? cont : oggCoDTO.contribuente.toDomain().save(failOnError: true, flush: true)
        }

        oggCo?.oggettoPratica = oggCoDTO.oggettoPratica.toDomain().save(failOnError: true, flush: true)

        if (oggCoDTO?.oggettoPratica?.oggettoPraticaRendita) {
            oggCo?.oggettoPratica?.oggettoPraticaRendita = oggCoDTO?.oggettoPratica?.oggettoPraticaRendita?.toDomain()?.save(failOnError: true, flush: true)
        }

        if (oggCoDTO?.oggettoPratica?.tipoQualita) {
            oggCo?.oggettoPratica?.tipoQualita = TipoQualita.get(oggCoDTO?.oggettoPratica?.tipoQualita)?.id
        }
        if (oggCoDTO?.oggettoPratica?.qualita) {
            oggCo?.oggettoPratica?.qualita = oggCoDTO?.oggettoPratica?.qualita
        }

        if (tipoTributo == "TASI") {
            oggCo.tipoRapporto = (oggCo.tipoRapporto) ? oggCo.tipoRapporto : tipoRapporto
        } else {
            if (!isCreaOggettoContitolare) {
                oggCo.tipoRapporto = tipoRapporto
            } else {
                oggCo.tipoRapporto = "C"
            }

            if (isCreaOggettoContitolare) {
                //Controllo Rapporti tributo
                def ratr = RapportoTributo.createCriteria().get {
                    eq('tipoRapporto', 'C')
                    eq('pratica.id', pratica.id)
                    eq('contribuente.codFiscale', oggCo?.contribuente?.codFiscale)
                }
                //Se non esiste viene creato uno nuovo
                if (!ratr) {
                    ratr = new RapportoTributo()
                    ratr.tipoRapporto = "C"
                    ratr.contribuente = oggCo.contribuente
                    ratr.pratica = pratica.getDomainObject()
                    ratr.save(failOnError: true, flush: true)
                }
            }
        }
        oggCo.save(failOnError: true, flush: true)

        for (AliquotaOgcoDTO aliOgcoDTO in oggCoDTO.aliquoteOgco) {
            AliquotaOgco aliquotaOgco = aliOgcoDTO.getDomainObject() ?: new AliquotaOgco()
            aliquotaOgco.tipoAliquota = aliOgcoDTO.tipoAliquota.getDomainObject()
            aliquotaOgco.dal = aliOgcoDTO.dal
            aliquotaOgco.al = aliOgcoDTO.al
            aliquotaOgco.note = aliOgcoDTO.note

            oggCo.addToAliquoteOgco(aliquotaOgco)
            aliquotaOgco.save(failOnError: true)
        }

        def aliqDaRimuovere = []
        oggCo.aliquoteOgco?.each {
            def eliminato = oggCoDTO.aliquoteOgco.findAll { alog -> alog.dal == it.dal }.isEmpty()
            if (eliminato) {
                aliqDaRimuovere << it
            }
        }
        aliqDaRimuovere.each {
            oggCo.aliquoteOgco.remove(it)
            it.delete(flush: true)
        }

        for (DetrazioneOgcoDTO detrazioneOgcoDTO in oggCoDTO.detrazioniOgco) {
            DetrazioneOgco detrazioneOgco = detrazioneOgcoDTO.getDomainObject() ?: new DetrazioneOgco()
            detrazioneOgco.motivoDetrazione = detrazioneOgcoDTO.motivoDetrazione.getDomainObject()
            detrazioneOgco.anno = detrazioneOgcoDTO.anno
            detrazioneOgco.detrazione = detrazioneOgcoDTO.detrazione
            detrazioneOgco.note = detrazioneOgcoDTO.note
            detrazioneOgco.detrazioneAcconto = detrazioneOgcoDTO.detrazioneAcconto

            oggCo.addToDetrazioniOgco(detrazioneOgco)
            detrazioneOgco.save(failOnError: true, flush: true)
        }

        def detDaRimuovere = []
        oggCo.detrazioniOgco?.each {
            def eliminato = oggCoDTO.detrazioniOgco.findAll { deog -> deog.anno == it.anno }.isEmpty()
            if (eliminato) {
                detDaRimuovere << it
            }
        }
        detDaRimuovere.each {
            oggCo.detrazioniOgco.remove(it)
            it.delete(flush: true)
        }

        oggCo.save(failOnError: true, flush: true)

        oggCo.oggettoPratica*.refresh()

        return oggCo.toDTO([
                "aliquoteOgco",
                "detrazioniOgco",
                "oggettoPratica",
                "oggettoPratica.oggetto",
                "oggettoPratica.oggetto.riferimentiOggetto",
                "oggettoPratica.oggetto.archivioVie",
                "oggettoPratica.categoriaCatasto",
                "oggettoPratica.oggettoPraticaRendita",
                "attributiOgco",
                "attributiOgco.ad4Comune",
                "contribuente",
                "contribuente.soggetto"
        ])
    }

    def salvaOggettoContribuenteTarsu(OggettoContribuenteDTO ogCoTarsu, List<PartizioneOggettoPraticaDTO> partizioniNew = []) {

        // Salvataggio ogpr
        OggettoPratica ogpr = ogCoTarsu.oggettoPratica.toDomain()
        ogpr = ogpr.save(failOnError: true, flush: true)

        // Salvataggio ogco
        def ogco = ogCoTarsu.toDomain()

        ogco.oggettoPratica = ogpr
        ogco = ogco.save(failOnError: true, flush: true)

        // Gestione partizioni

        // Recupero la configurazione precedente
        List<PartizioneOggettoPraticaDTO> partizioniOld = denunceService.getPartizioni(ogpr.id)

        // Se la partizione è stata eliminata dalla lista si effettua la delete
        partizioniOld.each { partOld ->
            if (!partizioniNew.find { partNew -> partNew.sequenza != null && partOld.sequenza == partNew.sequenza })
                partOld.toDomain().delete(flush: true)
        }

        // Aggiunte/modificate
        partizioniNew.each {
            def newPart = it.toDomain()
            newPart.oggettoPratica = newPart.oggettoPratica ?: ogpr
            newPart.save(failOnError: true, flush: true)
        }

        return ogco.toDTO(['oggettoPratica', 'contribuente'])
    }

    def creaOggettoContribuenteTarsuDaLocazioniCessate(Long praticaId, def locazioni, def data1, def data2) {
        if (!praticaId) {
            throw new RuntimeException("Id della pratica non specificato.")
        }

        if (!locazioni) {
            throw new RuntimeException("Lista delle locazioni vuota o nulla.")
        }

        PraticaTributoDTO pratica = PraticaTributo.get(praticaId)?.toDTO()
        if (!pratica) {
            throw new RuntimeException("La pratica con id #${praticaId} non esiste.")
        }

        TipoOccupazione tipoOccupazione

        def ogprCreate = []
        locazioni.each {

            OggettoPraticaDTO ogpr = new OggettoPraticaDTO()
            ogpr.pratica = pratica

            if (pratica.tipoEvento in [TipoEventoDenuncia.C, TipoEventoDenuncia.V]) {
                ogpr.oggettoPraticaRif = OggettoPratica.get(it.ogprRif).toDTO()
            }

            ogpr.fonte = Fonte.get(4L).toDTO()
            ogpr.oggetto = Oggetto.get(it.oggetto).toDTO()
            ogpr.codiceTributo = CodiceTributo.get(it.tributo).toDTO()
            ogpr.categoria = Categoria.findByCategoriaAndCodiceTributo(it.categoria, ogpr.codiceTributo.toDomain()).toDTO()
            ogpr.anno = pratica.anno
            // Per le tariffe è stato creato un id fittizio, si deve associare la tariffa con l'anno preso dalla pratica
            // e non con l'anno proveniente dalla locazione selezionata
            ogpr.tariffa = Tariffa.get((it.tariffa as String).replaceFirst((it.tariffa as String)[0..3], (pratica.anno as String)) as BigDecimal)?.toDTO()
            ogpr.consistenza = it.consistenza

            if (pratica.tipoPratica == TipoPratica.A.tipoPratica) {
                tipoOccupazione = (it.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) ? TipoOccupazione.T : TipoOccupazione.P
            } else {
                tipoOccupazione = pratica.tipoEvento == TipoEventoDenuncia.U ? TipoOccupazione.T : TipoOccupazione.P
            }
            ogpr.tipoOccupazione = tipoOccupazione

            ogpr.numeroFamiliari = it.numeroFamiliari
            ogpr.titoloOccupazione = it.titoloOccupazione ? TitoloOccupazione.getById(it.titoloOccupazione as int) : null
            ogpr.naturaOccupazione = it.naturaOccupazione ? NaturaOccupazione.getById(it.naturaOccupazione as int) : null
            ogpr.destinazioneUso = it.destinazioneUso ? DestinazioneUso.getById(it.destinazioneUso as int) : null
            ogpr.assenzaEstremiCatasto = it.assenzaEstremiCatasto ? AssenzaEstremiCatasto.getById(it.assenzaEstremiCatasto as int) : null
            ogpr.flagDatiMetrici = it.flagDatiMetrici
            ogpr.percRiduzioneSup = it.percRiduzioneSup

            OggettoContribuenteDTO ogco = new OggettoContribuenteDTO()
            ogco.oggettoPratica = ogpr
            ogco.contribuente = pratica.contribuente
            ogco.anno = pratica.anno
            ogco.tipoRapporto = 'D'
            ogco.flagPuntoRaccolta = it.flagPuntoRaccolta == 'S'

            if (pratica.tipoPratica == TipoPratica.A.tipoPratica) {
                ogco.inizioOccupazione = data1
                ogco.dataDecorrenza = data2
            } else {
                if (pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.V]) {
                    ogco.inizioOccupazione = data1
                    ogco.dataDecorrenza = data2
                } else if (pratica.tipoEvento == TipoEventoDenuncia.C) {
                    ogco.fineOccupazione = data1
                    ogco.dataCessazione = data2
                } else if (pratica.tipoEvento == TipoEventoDenuncia.U) {
                    ogco.dataDecorrenza = data1
                    ogco.dataCessazione = data2
                }
            }

            ogco.percPossesso = it.percPossesso
            ogco.flagAbPrincipale = it.flagAbPrincipale == 'S'

            def copiaPartizioni = []
            OggettoPratica.get(it.oggettoPratica).toDTO(['partizioniOggettoPratica']).partizioniOggettoPratica.each { part ->
                def copiaPart = new PartizioneOggettoPraticaDTO(commonService.getObjProperties(part))
                copiaPart.oggettoPratica = ogpr
                copiaPartizioni << copiaPart
            }

            ogprCreate << salvaOggettoContribuenteTarsu(ogco, copiaPartizioni)
        }

        return ogprCreate
    }

    def creaOggettoContribuenteDaEsistente(Long praticaDestinazione, Long oggettoPraticaOrigine) {

        OggettoContribuenteDTO oggettoCreato = null

        PraticaTributo praticaRaw = PraticaTributo.get(praticaDestinazione)
        if (!praticaRaw) {
            throw new RuntimeException("La pratica con id #${praticaDestinazione} non esiste.")
        }
        PraticaTributoDTO pratica = praticaRaw.toDTO()

        String tipoTributo = praticaRaw.tipoTributo.tipoTributo

        Contribuente contribuenteRaw = praticaRaw.contribuente
        ContribuenteDTO contribuente = pratica.contribuente

        OggettoPratica oggPrOriginaleRaw = OggettoPratica.get(oggettoPraticaOrigine)
        if (!oggPrOriginaleRaw) {
            throw new RuntimeException("L'oggetto pratica con id #${oggettoPraticaOrigine} non esiste.")
        }
        OggettoPraticaDTO oggPrOriginale = oggPrOriginaleRaw.toDTO(['partizioniOggettoPratica'])

        PraticaTributo praticaOriginaleRaw = oggPrOriginaleRaw.pratica
        TipoEventoDenuncia tePrOriginale = praticaOriginaleRaw.tipoEvento
        Short annoOriginale = praticaOriginaleRaw.anno

        OggettoContribuente oggCoOriginaleRaw = OggettoContribuente.findByOggettoPraticaAndContribuente(oggPrOriginaleRaw, contribuenteRaw)
        if (!oggCoOriginaleRaw) {
            throw new RuntimeException("L'oggetto pratica con id #${oggettoPraticaOrigine} non esiste.")
        }
        OggettoContribuenteDTO oggCoOriginale = oggCoOriginaleRaw.toDTO()

        try {
            OggettoPraticaDTO ogpr = new OggettoPraticaDTO()
            ogpr.pratica = pratica

            OggettoPraticaDTO oggPrRif = oggPrOriginale.oggettoPraticaRif ?: oggPrOriginale
            OggettoPraticaDTO oggPrRifV = (tePrOriginale == TipoEventoDenuncia.V) ? oggPrOriginale : null
            ogpr.oggettoPraticaRif = oggPrRif
            ogpr.oggettoPraticaRifV = oggPrRifV

            ogpr.anno = pratica.anno
            ogpr.fonte = oggPrOriginale.fonte
            ogpr.oggetto = oggPrOriginale.oggetto
            ogpr.codiceTributo = oggPrOriginale.codiceTributo
            ogpr.categoria = oggPrOriginale.categoria
            ogpr.consistenza = oggPrOriginale.consistenza

            def numero = denunceService.calcolaNumeroOrdine(pratica.id)
            ogpr.numOrdine = numero

            if (oggPrOriginale.tariffa?.id) {
                String tariffaStr = oggPrOriginale.tariffa.id as String
                String annoStr = pratica.anno as String
                ogpr.tariffa = Tariffa.get(tariffaStr.replaceFirst(tariffaStr[0..3], annoStr) as BigDecimal)?.toDTO()
            }

            ogpr.tipoOccupazione = oggPrOriginale.tipoOccupazione

            ogpr.numeroFamiliari = oggPrOriginale.numeroFamiliari
            ogpr.titoloOccupazione = oggPrOriginale.titoloOccupazione
            ogpr.naturaOccupazione = oggPrOriginale.naturaOccupazione
            ogpr.destinazioneUso = oggPrOriginale.destinazioneUso
            ogpr.assenzaEstremiCatasto = oggPrOriginale.assenzaEstremiCatasto
            ogpr.flagDatiMetrici = oggPrOriginale.flagDatiMetrici
            ogpr.percRiduzioneSup = oggPrOriginale.percRiduzioneSup

            ogpr.tipoOggetto = oggPrOriginale.tipoOggetto
            ogpr.categoriaCatasto = oggPrOriginale.categoriaCatasto
            ogpr.classeCatasto = oggPrOriginale.classeCatasto

            if (pratica.tipoPratica == TipoPratica.A.tipoPratica) {

                if (tipoTributo in ['ICI', 'TASI']) {
                    def valore = getValoreOgPrLiq(tipoTributo, contribuente.codFiscale, pratica.anno, oggPrOriginale.id)
                    if (!valore.valore) {
                        valore = getValoreOgPrDic(tipoTributo, contribuente.codFiscale, pratica.anno, oggPrOriginale.id)
                    }
                    if (!valore.valore) {
                        String catCat = ogpr.categoriaCatasto?.categoriaCatasto ?: ogpr.oggetto.categoriaCatasto?.categoriaCatasto ?: ''
                        valore.valore = getFValore(oggPrOriginale.valore, ogpr.tipoOggetto.tipoOggetto, annoOriginale, pratica.anno, catCat, 'D', true)
                    }
                    ogpr.valore = valore.valore
                }
                ogpr.flagValoreRivalutato = true
            } else {
                ogpr.valore = oggPrOriginale.valore
            }

            ogpr.immStorico = oggPrOriginale.immStorico
            ogpr.flagProvvisorio = oggPrOriginale.flagProvvisorio
            ogpr.tipoQualita = oggPrOriginale.tipoQualita
            ogpr.qualita = oggPrOriginale.qualita
            ogpr.titolo = oggPrOriginale.titolo
            ogpr.estremiTitolo = oggPrOriginale.estremiTitolo
            ogpr.modello = oggPrOriginale.modello
            ogpr.note = oggPrOriginale.note

            OggettoContribuenteDTO ogco = new OggettoContribuenteDTO()
            ogco.oggettoPratica = ogpr
            ogco.contribuente = contribuente
            ogco.anno = pratica.anno
            ogco.tipoRapporto = 'D'

            ogco.dataDecorrenza = oggCoOriginale.dataDecorrenza
            ogco.dataCessazione = oggCoOriginale.dataCessazione
            ogco.inizioOccupazione = oggCoOriginale.inizioOccupazione
            ogco.fineOccupazione = oggCoOriginale.fineOccupazione

            if (annoOriginale != pratica.anno) {
                ogco.mesiPossesso = 12
                ogco.mesiPossesso1sem = 6
                ogco.daMesePossesso = 1

                ogco.mesiEsclusione = (oggCoOriginale.flagEsclusione) ? 12 : null
                ogco.mesiRiduzione = (oggCoOriginale.flagRiduzione) ? 12 : null
            } else {
                ogco.mesiPossesso = oggCoOriginale.mesiPossesso
                ogco.mesiPossesso1sem = oggCoOriginale.mesiPossesso1sem
                ogco.daMesePossesso = oggCoOriginale.daMesePossesso

                ogco.mesiEsclusione = oggCoOriginale.mesiEsclusione
                ogco.mesiRiduzione = oggCoOriginale.mesiRiduzione
            }

            ogco.mesiAliquotaRidotta = oggCoOriginale.mesiAliquotaRidotta
            ogco.mesiOccupato = oggCoOriginale.mesiOccupato
            ogco.mesiOccupato1sem = oggCoOriginale.mesiOccupato1sem

            Boolean togliflagPERA = false

            if (pratica.tipoPratica == TipoPratica.A.tipoPratica) {
                if (tipoTributo in ['ICI', 'TASI']) {
                    if (!pratica.flagDenuncia) {
                        togliflagPERA = true        // Accertamentio ICI/IMU/TASI non denuncia non permette i flag PERA
                    };
                };
            };

            if (togliflagPERA) {
                ogco.flagPossesso = false
                ogco.flagEsclusione = false
                ogco.flagAlRidotta = false
                ogco.flagAbPrincipale = false
            } else {
                ogco.flagPossesso = oggCoOriginale.flagPossesso
                ogco.flagEsclusione = oggCoOriginale.flagEsclusione
                ogco.flagAlRidotta = oggCoOriginale.flagAlRidotta
                ogco.flagAbPrincipale = oggCoOriginale.flagAbPrincipale
            }

            ogco.flagRiduzione = oggCoOriginale.flagRiduzione

            ogco.percPossesso = oggCoOriginale.percPossesso

            ogco.dataEvento = oggCoOriginale.dataEvento

            def copiaPartizioni = []
            oggPrOriginale.partizioniOggettoPratica.each { part ->
                def copiaPart = new PartizioneOggettoPraticaDTO(commonService.getObjProperties(part))
                copiaPart.oggettoPratica = ogpr
                copiaPartizioni << copiaPart
            }

            oggettoCreato = salvaOggettoContribuenteTarsu(ogco, copiaPartizioni)
        }
        catch (Exception e) {
            throw e
        }

        return oggettoCreato
    }

    def getOggetto(long idOggetto) {
        Oggetto.get(idOggetto).toDTO([
                "civiciOggetto"
                ,
                "civiciOggetto.archivioVie"
                ,
                "archivioVie"
                ,
                "fonte"
                ,
                "edificio"
                ,
                "tipoUso"
                ,
                "tipoOggetto"
                ,
                "civiciOggetto"
                ,
                "civiciOggetto.archivioVie"
                ,
                "partizioniOggetto"
                ,
                "riferimentiOggetto"
                ,
                "notificheOggetto"
                ,
                "utilizziOggetto"
                ,
                "utilizziOggetto.soggetto"
                ,
                "partizioniOggetto.consistenzeTributo"
                ,
                "partizioniOggetto.tipoArea"
        ])
    }

    def listaCivici(long idOggetto) {
        def l = CivicoOggetto.createCriteria().list {
            fetchMode("archivioVie", FetchMode.JOIN)
            eq("oggetto.id", idOggetto)
            order("sequenza", "asc")
        }
    }

    def listaUtilizzi(long idOggetto) {
        UtilizzoOggetto.createCriteria().list {
            fetchMode("soggetto", FetchMode.JOIN)

            eq("oggetto.id", idOggetto)
            order("anno", "asc")
            order("tipoUtilizzo", "asc")
            order("dataScadenza", "asc")
        }
    }

    def listaPartizioni(long idOggetto) {
        def listPartizioni = PartizioneOggetto.createCriteria().list {
            fetchMode("tipoArea", FetchMode.JOIN)
            fetchMode("consistenzeTributo", FetchMode.JOIN)
            eq("oggetto.id", idOggetto)
            order("tipoArea", "asc")
            order("consistenza", "asc")
        }.toDTO()

        return listPartizioni
    }

    def listaRiferimenti(long idOggetto) {
        RiferimentoOggetto.createCriteria().list {

            eq("oggetto.id", idOggetto)
            order("inizioValidita", "asc")
        }
    }

    def listaNotifiche(long idOggetto) {

        /* è necessario passare i parametri nel DTO altrimenti nella maschera non riesce a visualizzare la proprietà cognomeNome
         e si evita inoltre di dover fare la query in HQL */

        NotificaOggetto.createCriteria().list { eq("oggetto.id", idOggetto) }.toDTO([
                "contribuente",
                "contribuente.soggetto"
        ])

    }

    def listaAnomalie(def idOggetto) {
        def parametri = [:]
        parametri.pIdOggetto = idOggetto.longValue()

        String sql = """
					SELECT DISTINCT new Map(
								anpa.anno AS anno,
								anpa.tipoAnomalia.tipoAnomalia AS tipoAnomalia,
								anpa.tipoAnomalia.descrizione AS descrizione,
								f_descrizione_titr(anpa.tipoTributo.tipoTributo, anpa.anno) as tipoTributo,
								anpa.flagImposta AS flagImposta,
								anpa.dateCreated as dataCreazione,
								anpa.scarto as scarto,
								anpa.renditaDa as renditaDa,
								anpa.renditaA as renditaA
							)
					FROM Anomalia anom
						INNER JOIN anom.anomaliaParametro anpa
					WHERE anom.oggetto.id = :pIdOggetto
					ORDER BY  anpa.anno, anpa.tipoAnomalia.tipoAnomalia
				"""

        return Anomalia.executeQuery(sql, parametri)
    }

    /* RIFERIMENTI_OGGETTO_BK */

    def listaRiferimentiOggettBk(long idOggetto) {
        RiferimentoOggettoBk.createCriteria().list {
            eq("oggetto.id", idOggetto)
            order("dataOraVariazione", "asc")
        }
    }

    def listaRiferimentiOggettBk(long idOggetto, String dataSelezionata) {
        SimpleDateFormat sdformat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss")
        java.util.Date data = sdformat.parse(dataSelezionata)

        java.sql.Date sqlDate = new java.sql.Date(data.getTime())

        RiferimentoOggettoBk.createCriteria().list {
            eq("oggetto.id", idOggetto)
            eq("dataOraVariazione", data)
            order("dataOraVariazione", "asc")
        }
    }

    def listaDateRiferimentiOggettBk(def idOggetto) {
        def parametri = [:]
        parametri.pIdOggetto = idOggetto.longValue()

        String sql = """
					SELECT DISTINCT TO_CHAR (data_ora_variazione, 'dd/mm/yyyy hh24:mi:ss')  DATA_ORA_VAR
					FROM riferimenti_oggetto_bk 						
					WHERE oggetto = :P_OGGETTO
					ORDER BY  1
				"""
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_OGGETTO', idOggetto)

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.dataOraVariazione = it['DATA_ORA_VAR']
            records << record
        }

        return records
    }

    def ripristinoRendite(Long idOggetto, def dataSelezionata) {
        try {
            SimpleDateFormat sdformat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss")
            java.util.Date data = sdformat.parse(dataSelezionata)
            Sql sql = new Sql(dataSource)
            sql.call('{call RIOB_TO_RIOG(?,?)}', [idOggetto, new java.sql.Timestamp(data.getTime())])

            return ''
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
    }

    @Transactional
    OggettoDTO duplica(OggettoDTO oggetto) {

        OggettoDTO oggettoDuplicato = new OggettoDTO()
        InvokerHelper.setProperties(oggettoDuplicato, oggetto.properties)
        oggettoDuplicato.id = null

        //Civici oggetto
        for (CivicoOggettoDTO civOggDTO in oggetto.civiciOggetto) {
            def civicoOggetto = new CivicoOggettoDTO()
            def archivioVie = new ArchivioVieDTO()
            civicoOggetto.archivioVie = archivioVie
            InvokerHelper.setProperties(civicoOggetto, civOggDTO.properties)
            civicoOggetto.oggetto.id = null
            oggettoDuplicato.addToCiviciOggetto(civicoOggetto)
        }

        //Utilizzi
        for (UtilizzoOggettoDTO utiOggDTO in oggetto.utilizziOggetto) {
            def utilizzo = new UtilizzoOggettoDTO()
            InvokerHelper.setProperties(utilizzo, utiOggDTO.properties)
            oggettoDuplicato.addToUtilizziOggetto(utilizzo)
        }

        //Partizioni
        for (PartizioneOggettoDTO partOggDTO in oggetto.partizioniOggetto) {
            def partizione = new PartizioneOggettoDTO()
            InvokerHelper.setProperties(partizione, partOggDTO.properties)
            oggettoDuplicato.addToPartizioniOggetto(partizione)
        }

        //Riferimenti
        for (RiferimentoOggettoDTO rifOggDTO in oggetto.riferimentiOggetto) {
            def riferimento = new RiferimentoOggettoDTO()
            InvokerHelper.setProperties(riferimento, rifOggDTO.properties)
            oggettoDuplicato.addToRiferimentiOggetto(riferimento)
        }

        //Notifiche
        for (NotificaOggettoDTO notOggDTO in oggetto.notificheOggetto) {
            def notifica = new NotificaOggettoDTO()
            InvokerHelper.setProperties(notifica, notOggDTO.properties)
            oggettoDuplicato.addToNotificheOggetto(notifica)
        }

        return oggettoDuplicato
    }


    @Transactional
    OggettoDTO salvaOggetto(OggettoDTO oggDTO, CivicoOggettoDTO civicoRiferimento, boolean modifica) {
        Oggetto oggetto = oggDTO.getDomainObject() ?: new Oggetto()

        oggetto.tipoOggetto = TipoOggetto.get(oggDTO.tipoOggetto?.tipoOggetto)
        oggetto.archivioVie = ArchivioVie.get(oggDTO.archivioVie?.id)
        oggetto.categoriaCatasto = CategoriaCatasto.get(oggDTO.categoriaCatasto?.categoriaCatasto)
        oggetto.edificio = Edificio.get(oggDTO.edificio?.id)
        oggetto.tipoUso = TipoUso.get(oggDTO.tipoUso?.id)
        oggetto.fonte = Fonte.get(oggDTO.fonte?.fonte)
        oggetto.tipoQualita = TipoQualita.get(oggDTO.tipoQualita?.id)

        oggetto.numCiv = oggDTO.numCiv
        oggetto.suffisso = oggDTO.suffisso
        oggetto.interno = oggDTO.interno
        oggetto.scala = oggDTO.scala
        oggetto.piano = oggDTO.piano
        oggetto.interno = oggDTO.interno
        oggetto.descrizione = oggDTO.descrizione
        oggetto.partita = oggDTO.partita
        oggetto.progrPartita = oggDTO.progrPartita
        oggetto.numero = oggDTO.numero
        oggetto.sezione = oggDTO.sezione
        oggetto.zona = oggDTO.zona
        oggetto.foglio = oggDTO.foglio
        oggetto.subalterno = oggDTO.subalterno
        oggetto.latitudine = oggDTO.latitudine
        oggetto.longitudine = oggDTO.longitudine
        oggetto.aLatitudine = oggDTO.aLatitudine
        oggetto.aLongitudine = oggDTO.aLongitudine
        oggetto.protocolloCatasto = oggDTO.protocolloCatasto
        oggetto.annoCatasto = oggDTO.annoCatasto
        oggetto.classeCatasto = oggDTO.classeCatasto
        oggetto.flagSostituito = oggDTO.flagSostituito
        oggetto.dataCessazione = oggDTO.dataCessazione
        oggetto.consistenza = oggDTO.consistenza
        oggetto.vani = oggDTO.vani
        oggetto.centiare = oggDTO.centiare
        oggetto.are = oggDTO.are
        oggetto.ettari = oggDTO.ettari
        oggetto.superficie = oggDTO.superficie
        oggetto.indirizzoLocalita = oggDTO.indirizzoLocalita
        oggetto.note = oggDTO.note
        oggetto.qualita = oggDTO.qualita

        oggetto.save(failOnError: true, flush: true)

        //Civici Oggetto
        if (oggetto?.civiciOggetto) {
            List<CivicoOggetto> civiciOggetto = []
            civiciOggetto += oggetto?.civiciOggetto
            for (CivicoOggetto civ in civiciOggetto) {
                if (civicoRiferimento && civ?.sequenza != civicoRiferimento.sequenza
                        && (civ?.indirizzoLocalita != civicoRiferimento?.indirizzoLocalita
                        || civ?.archivioVie?.id != civicoRiferimento?.archivioVie?.id
                        || civ?.numCiv != civicoRiferimento?.numCiv
                        || civ?.suffisso != civicoRiferimento?.suffisso)
                ) {
                    /*Bisogna fare in sequenza prima la delete e poi la removeFrom..
                 così prima cancello l'oggetto e poi tolgo il riferimento altrimenti la removeFrom fallisce */
                    civ.delete(failOnError: true, flush: true)
                    oggetto.removeFromCiviciOggetto(civ)
                }
            }
        }
        for (CivicoOggettoDTO civOggDTO in oggDTO.civiciOggetto) {
            if (!modifica) {
                CivicoOggetto civOgg = civOggDTO.getDomainObject() ?: new CivicoOggetto()
                civOgg.sequenza = civOggDTO.sequenza
                civOgg.indirizzoLocalita = civOggDTO.indirizzoLocalita
                civOgg.archivioVie = civOggDTO.archivioVie?.getDomainObject()
                civOgg.numCiv = civOggDTO.numCiv
                civOgg.suffisso = civOggDTO.suffisso

                oggetto.addToCiviciOggetto(civOgg)
                civOgg.save(failOnError: true, flush: true)
            } else {
                if (civicoRiferimento && civOggDTO.sequenza != civicoRiferimento.sequenza
                        && (civOggDTO?.indirizzoLocalita != civicoRiferimento?.indirizzoLocalita
                        || civOggDTO?.archivioVie?.id != civicoRiferimento?.archivioVie?.id
                        || civOggDTO?.numCiv != civicoRiferimento?.numCiv
                        || civOggDTO?.suffisso != civicoRiferimento?.suffisso)) {
                    CivicoOggetto civOgg = civOggDTO.getDomainObject() ?: new CivicoOggetto()
                    civOgg.sequenza = civOggDTO.sequenza
                    civOgg.indirizzoLocalita = civOggDTO.indirizzoLocalita
                    civOgg.archivioVie = civOggDTO.archivioVie?.getDomainObject()
                    civOgg.numCiv = civOggDTO.numCiv
                    civOgg.suffisso = civOggDTO.suffisso

                    oggetto.addToCiviciOggetto(civOgg)
                    civOgg.save(failOnError: true, flush: true)
                }
            }
        }
        //Utilizzi Oggetto
        oggetto.utilizziOggetto?.clear()
        for (UtilizzoOggettoDTO utiOggDTO in oggDTO.utilizziOggetto) {
            UtilizzoOggetto utiOgg = utiOggDTO.getDomainObject() ?: new UtilizzoOggetto()
            utiOgg.tipoTributo = utiOggDTO.tipoTributo?.getDomainObject()
            utiOgg.anno = utiOggDTO.anno
            utiOgg.tipoUtilizzo = utiOggDTO.tipoUtilizzo?.getDomainObject()
            utiOgg.sequenza = utiOggDTO.sequenza
            utiOgg.soggetto = utiOggDTO.soggetto?.getDomainObject()
            utiOgg.mesiAffitto = utiOggDTO.mesiAffitto
            utiOgg.dataScadenza = utiOggDTO.dataScadenza
            utiOgg.intestatario = utiOggDTO.intestatario
            utiOgg.note = utiOggDTO.note
            utiOgg.dal = utiOggDTO.dal
            utiOgg.al = utiOggDTO.al
            utiOgg.tipoUso = utiOggDTO.tipoUso?.getDomainObject()
            utiOgg.oggetto = oggetto
            oggetto.addToUtilizziOggetto(utiOgg)
            log.info oggetto.utilizziOggetto.size()
        }

        //Partizioni Oggetto
        oggetto.partizioniOggetto?.clear()
        for (PartizioneOggettoDTO partOggDTO in oggDTO.partizioniOggetto) {
            PartizioneOggetto partOgg = partOggDTO.getDomainObject() ?: new PartizioneOggetto()
            partOgg.sequenza = partOggDTO.sequenza
            partOgg.tipoArea = partOggDTO.tipoArea?.getDomainObject()
            partOgg.numero = partOggDTO.numero
            partOgg.consistenza = partOggDTO.consistenza
            partOgg.note = partOggDTO.note
            partOgg.oggetto = oggetto

            partOgg.consistenzeTributo?.clear()
            for (ConsistenzaTributoDTO consDTO in partOggDTO.consistenzeTributo) {
                ConsistenzaTributo consPart = consDTO.getDomainObject() ?: new ConsistenzaTributo()
                consPart.tipoTributo = consDTO.tipoTributo?.getDomainObject()
                consPart.partizioneOggetto = partOgg
                consPart.consistenza = consDTO.consistenza
                consPart.flagEsenzione = consDTO.flagEsenzione
                partOgg.addToConsistenzeTributo(consPart)
            }
            oggetto.addToPartizioniOggetto(partOgg)
        }

        oggetto.riferimentiOggetto?.clear()
        for (RiferimentoOggettoDTO rifOggDTO in oggDTO.riferimentiOggetto) {
            SimpleDateFormat df = new SimpleDateFormat("yyyy")
            Short daAnno = Short.valueOf(df.format(rifOggDTO.inizioValidita))
            Short aAnno = Short.valueOf(df.format(rifOggDTO.fineValidita))

            RiferimentoOggetto rifOgg = rifOggDTO.getDomainObject() ?: new RiferimentoOggetto()
            rifOgg.inizioValidita = rifOggDTO.inizioValidita
            rifOgg.fineValidita = rifOggDTO.fineValidita
            rifOgg.daAnno = daAnno
            rifOgg.aAnno = aAnno
            rifOgg.rendita = rifOggDTO.rendita
            rifOgg.annoRendita = rifOggDTO.annoRendita
            rifOgg.categoriaCatasto = rifOggDTO.categoriaCatasto?.getDomainObject()
            rifOgg.classeCatasto = rifOggDTO.classeCatasto
            rifOgg.dataReg = rifOggDTO.dataReg
            rifOgg.dataRegAtti = rifOggDTO.dataRegAtti
            rifOgg.note = rifOggDTO.note
            rifOgg.oggetto = oggetto
            oggetto.addToRiferimentiOggetto(rifOgg)
        }

        //Notifiche Oggetto
        oggetto.notificheOggetto?.clear()
        for (NotificaOggettoDTO notOggDTO in oggDTO.notificheOggetto) {
            NotificaOggetto notOgg = notOggDTO.getDomainObject() ?: new NotificaOggetto()
            notOgg.contribuente = notOggDTO.contribuente?.getDomainObject()
            notOgg.annoNotifica = notOggDTO.annoNotifica
            notOgg.pratica = notOggDTO.pratica?.getDomainObject()
            notOgg.note = notOggDTO.note
            notOgg.oggetto = oggetto
            oggetto.addToNotificheOggetto(notOgg)
        }
        oggetto.save(failOnError: true, flush: true)

        return oggetto.toDTO([
                "civiciOggetto",
                "civiciOggetto.archivioVie"
        ])
    }

    void eliminaOggetto(Long idOggetto) {
        Oggetto ogg = Oggetto.get(idOggetto)
        ogg.delete(failOnError: true, flush: true)
    }

    String elimina(def oggetto) {

        def esito = eliminabile(oggetto)

        if (esito.isEmpty()) {
            try {
                eliminaOggetto(oggetto.id)
            } catch (Exception e) {
                commonService.serviceException(e)
            }
        }
        return esito
    }

    def eliminabile(def oggetto) {
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call OGGETTI_PD(?)}', [oggetto.id])

            return ''

        } catch (Exception e) {
            e.printStackTrace()
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    def listaTipiOggetto(def tipoTributo) {
        def lista = TipoOggetto.createCriteria().list {
            createAlias("oggettiTributo", "ogtr", CriteriaSpecification.INNER_JOIN)
            eq("ogtr.tipoTributo.tipoTributo", tipoTributo)
            order("tipoOggetto", "asc")
        }.toDTO()
    }

    @Transactional
    boolean oggettoModificabile(String tipoTributo, long oggettoPratica, String codiceFiscale) {

        log.info oggettoPratica

        log.info codiceFiscale

        return PraticaTributo.createCriteria().list {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)

            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("tipoPratica", "A")
            or {
                isNull("tipoStato")
                eq("tipoStato.tipoStato", "A")
                eq("tipoStato.tipoStato", "R")
            }
            eq("ogpr.oggettoPraticaRif.id", oggettoPratica)
            eq("ogco.contribuente.codFiscale", codiceFiscale)
        }.size == 0
    }

    @Transactional
    String tipoOggettoModificabile(Long oggetto) {

        int size = PraticaTributo.createCriteria().list {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)

            or {
                eq("tipoTributo.tipoTributo", 'ICI')
                eq("tipoTributo.tipoTributo", 'TASI')
            }
            eq("ogpr.oggetto.id", oggetto)
            ne("tipoPratica", 'D')
            ne("tipoPratica", "K")
        }.size

        if (size > 0) {
            return "Impossibile Sostituire: Esistono Liquidazioni o Accertamenti ICI/TASI."
        }

        return ""
    }

    @Transactional
    String tipoOggettoModificabileOgCo(String tipoTributo, def oggettoPratica) {

        // Oggetto già liquidato
        def pratiche = PraticaTributo.createCriteria().list {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)

            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("ogpr.oggettoPraticaRif.id", oggettoPratica.id)
            eq("tipoPratica", 'L')
        }

        if (pratiche.size > 0) {
            return "Oggetto già Liquidato - Non è Possibile Cambiarne il Tipo."
        }

        // Più di una pertinenza
        pratiche = OggettoPratica.createCriteria().list {
            eq('oggettoPraticaRifAp.id', oggettoPratica.id)
        }

        if (pratiche.size == 1) {
            return " Esiste una Pertinenza (Ogg:" + pratiche[0].oggetto.id + ") collegata all'oggetto " + oggettoPratica.oggetto.id +
                    "\nNon è possibile modificare il Tipo dell'oggetto."
        } else if (pratiche.size > 1) {
            return "Esiste più di una Pertinenza collegata all'oggetto "
            +oggettoPratica.oggetto.id +
                    "\nNon è possibile modificare il Tipo dell'oggetto."
        }

        return ""
    }

    def valoreDaRendita(def rendita, def tipoOggetto, def anno, def categoriaCatasto, def immobileStorico) {

        def r
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_valore_da_rendita(?, ?, ?, ?, ?)}'
                , [Sql.NUMERIC
                   , rendita
                   , tipoOggetto
                   , anno
                   , categoriaCatasto
                   , immobileStorico
        ]) { r = it }

        return r
    }

    @Transactional
    def inserimentoOggettiRendite(def immobile, def oggetto, def tipoImmobile, def cessatiDopo, def seCessati) {

        try {
            String r

            Calendar cal = Calendar.getInstance()
            cal.setTime(cessatiDopo)
            cal.set(Calendar.MILLISECOND, 0)

            Sql sql = new Sql(dataSource)
            sql.call("{call INSERIMENTO_RENDITE_PKG.INSERIMENTO_RENDITE(?, ?, ?, ?, ?, ?, ?)}"
                    , [immobile,
                       tipoImmobile,
                       new java.sql.Timestamp(cessatiDopo.getTime()),
                       seCessati,
                       springSecurityService.currentUser?.id,
                       oggetto,
                       Sql.VARCHAR]) {
                r = it
            }

            return r
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    @Transactional
    def controlloRiog(def idImmobile, def oggetto, def tipoImmobile) {

        def r

        Sql sql = new Sql(dataSource)
        sql.call("{? = call INSERIMENTO_RENDITE_PKG.F_CONTROLLO_RIOG(?, ?, ?)}"
                , [Sql.NUMERIC, idImmobile, tipoImmobile, oggetto]) {
            r = it
        }

        return r
    }

    def findUtilizzi(def oggetto, def tipoTributo, def anno = null) {

        def utilizzi = Oggetto.get(oggetto).utilizziOggetto.findAll {
            it.tipoTributo.tipoTributo == tipoTributo
        }

        if (anno) {
            def data = new SimpleDateFormat("yyyy")
            utilizzi = utilizzi.findAll {
                ((it.anno as String) <= anno) && (anno <= (it.dataScadenza ? data.format(it.dataScadenza) : '9999'))
            }
        }

        return utilizzi.sort { u1, u2 -> u1.dal <=> u2.dal ?: u1.al <=> u2.al ?: u1.dataScadenza <=> u2.dataScadenza }
    }

    def findAlOg(def oggettoPratica, def codFiscale, def anno = null) {
        def alog = OggettoContribuente.findByOggettoPraticaAndContribuente(
                OggettoPratica.get(oggettoPratica), Contribuente.findAllByCodFiscale(codFiscale)
        ).aliquoteOgco.findAll {
            it.dal[Calendar.YEAR] <= anno && anno <= it.al[Calendar.YEAR]
        }

        return alog.sort {
            a1, a2 -> a1.dal <=> a2.dal ?: a1.al <=> a2.al
        }
    }

    def tooltipUtilizzi(def oggetto, def tipoTributo, def anno = null) {
        def sdf = new SimpleDateFormat("dd/MM/yyyy")
        def utilizziText = """"""
        findUtilizzi(oggetto, tipoTributo, anno).each {
            utilizziText += "${it.tipoUtilizzo.id} - ${it.tipoUtilizzo.descrizione}"
            utilizziText += " Anno: ${it.anno}"
            utilizziText += it.mesiAffitto ? " Mesi: ${it.mesiAffitto}" : " Mesi: 12"
            utilizziText += it.dataScadenza ? " fino al ${sdf.format(it.dataScadenza)}" : " fino al 31/12/9999"
            utilizziText += "\n"
        }

        return utilizziText
    }

    def tooltipAlOg(def oggettoPratica, def codFiscale, def anno = null) {
        def sdf = new SimpleDateFormat("dd/MM/yyyy")
        def alogText = """"""
        findAlOg(oggettoPratica, codFiscale, anno).each {
            alogText += "${it.tipoAliquota.tipoAliquota} - ${it.tipoAliquota.descrizione}"
            alogText += " Dal ${sdf.format(it.dal)} al ${sdf.format(it.al)}"
            alogText += "\n"
        }

        return alogText
    }

    def tooltipPertinenzaDi(def oggettoPratica) {
        def ogpr = OggettoPratica.get(oggettoPratica)
        def pertinenzaDiText = "Pertinenza di: ${ogpr.oggetto?.id} - ${formattaStremiCasto(ogpr.oggetto)} - ${ogpr.categoriaCatasto?.categoriaCatasto ?: ogpr.oggetto?.categoriaCatasto?.categoriaCatasto}"

        return pertinenzaDiText

    }

    def tooltipFamiliari(def codFiscale, def anno) {
        def faso = FamiliareSoggetto
                .findAllBySoggettoAndAnno(Contribuente.findByCodFiscale(codFiscale).soggetto, anno as Short)
                .sort { it.dal }

        def sdf = new SimpleDateFormat("dd/MM/yyyy")
        def familiariText = ""

        faso.each {
            def dal = sdf.format(it.dal)
            def al = ""
            if (it.al) {
                al = " al ${sdf.format(it.al)}"
            }
            familiariText += "Numero familiari ${it.numeroFamiliari} dal ${dal}${al} \n"
        }

        return familiariText

    }

    def tooltipAltriContribuenti(String tipoTributo, String codFiscale, Integer anno, Long oggetto) {

        def altriContribuentiText = """"""

        def sql = """
        select peog.tipo_tributo,
               peog.cod_fiscale,
               translate(sogg.cognome_nome, '/', ' ') cognome_nome
          from periodi_ogco peog
             , contribuenti cont
             , soggetti sogg
         where peog.tipo_tributo = :tipo_tributo
           and peog.cod_fiscale <> :cod_fiscale
           and peog.inizio_validita <= to_date('3112' || :anno, 'ddmmyyyy')
           and peog.fine_validita >= to_date('0101' || :anno, 'ddmmyyyy')
           and peog.oggetto = :oggetto
           and peog.cod_fiscale = cont.cod_fiscale
           and cont.ni = sogg.ni
        union
        select peot.tipo_tributo,
               peot.cod_fiscale,
               translate(sogg.cognome_nome, '/', ' ') cognome_nome
          from periodi_ogco_tarsu peot
             , contribuenti cont
             , soggetti sogg
         where peot.tipo_tributo = :tipo_tributo
           and peot.cod_fiscale = :cod_fiscale
           and nvl(peot.inizio_validita, to_date('01011900', 'ddmmyyyy')) <=
               to_date('3112' || :anno, 'ddmmyyyy')
           and nvl(peot.fine_validita, to_date('3112' || :anno, 'ddmmyyyy')) >=
               to_date('0101' || :anno, 'ddmmyyyy')
           and peot.oggetto = :oggetto
           and peot.cod_fiscale = cont.cod_fiscale
           and cont.ni = sogg.ni
         order by 2
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            setInteger('anno', anno)
            setLong('oggetto', oggetto)
            setString('tipo_tributo', tipoTributo)
            setString('cod_fiscale', codFiscale)

            list()
        }

        results.each {
            altriContribuentiText += "${it.codFiscale} - ${it.cognomeNome}\n"
        }

        return altriContribuentiText
    }

    def tooltipSvuotamenti(def codFiscale, def oggetto) {
        def altriContribuentiText = """"""

        def sql = """
            select corf.cod_rfid,
                   cont.capienza,
                   corf.data_consegna,
                   corf.data_restituzione,
                   cont.unita_di_misura
              from codici_rfid corf, contenitori cont
             where corf.cod_contenitore = cont.cod_contenitore
               and corf.oggetto = :oggetto
               and corf.cod_fiscale = :cod_fiscale
             order by corf.data_consegna, corf.data_restituzione
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            setString('cod_fiscale', codFiscale)
            setLong('oggetto', oggetto as Long)

            list()
        }

        String pattern = "#,###.00"
        DecimalFormat numeroFormat = new DecimalFormat(pattern)

        results.each {
            altriContribuentiText += """${it.codRfid} - (${it.capienza ? numeroFormat.format(it.capienza) : '-'} ${it.unitaDiMisura ?: ''}) ${it.dataConsegna?.format('dd/MM/yyyyy') ?: ''} - ${it.dataRestituzione?.format('dd/MM/yyyyy') ?: ''})\n"""
        }

        return altriContribuentiText
    }

    def formattaStremiCasto(def oggetto) {
        def estremiCatasto = ""

        estremiCatasto += oggetto.sezione != null ? "${oggetto.sezione}/" : ""
        estremiCatasto += oggetto.foglio != null ? "${oggetto.foglio}/" : ""
        estremiCatasto += oggetto.numero != null ? "${oggetto.numero}/" : ""
        estremiCatasto += oggetto.subalterno != null ? oggetto.subalterno : ""

        return estremiCatasto
    }

    def anniOggettiContribuente(Long oggetto, def anniPrescrizione = false) {
        def listaAnni = OggettoContribuente.createCriteria().list {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)

            projections { property("anno") }

            isNull('prtr.flagAnnullamento')
            'in'('prtr.tipoPratica', ['D', 'A', 'L'])
            eq("ogpr.oggetto.id", oggetto)

        }.collect { it }

        def parametroAnni = "LISTA_ANNI"
        def numAnniStr = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == parametroAnni }?.valore

        def numAnni = 5

        if (!numAnniStr?.empty) {
            numAnni = numAnniStr.replace('+', '') as Integer
        }

        if (anniPrescrizione) {
            def annoCorrente = (new Date()).getYear() + 1900
            def ultimiNAnni = (annoCorrente..annoCorrente - numAnni)

            // Li trasformo in short per avere un tipo univoco nella lista. Laq query restituisce un elenco di short.
            ultimiNAnni = ultimiNAnni.collect { it as Short }
            listaAnni += ultimiNAnni
        }

        listaAnni.unique().sort { -it }

        listaAnni << "Tutti"
        return listaAnni
    }

    def anniContribuentiSuOggetto(def idOggetto) {

        def parametri = [:]

        parametri << ['p_idOgg': idOggetto]

        def query = """
                            SELECT DISTINCT c.oggetto, a.anno_rif
                            FROM (SELECT oggetto,
                                    min(to_char(inizio_validita, 'yyyy')) anno_min,
                                    least(to_char(sysdate, 'yyyy'),
                                    max(to_char(fine_validita, 'yyyy'))) anno_max
                                    FROM contribuenti_oggetto_anno
                                    GROUP BY oggetto) c,
                                    (SELECT 1900 + rownum anno_rif
                                     FROM oggetti
                                     WHERE rownum <= to_char(sysdate, 'yyyy') - 1900) a
                            WHERE a.anno_rif between c.anno_min and c.anno_max
                            AND c.oggetto = :p_idOgg
                            ORDER BY a.anno_rif desc
                          """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }.collect { it.annoRif }
    }

    List<OggettoContribuenteDTO> listaOggettiContribuente(def filter = []) {
        return OggettoContribuente.createCriteria().list {
            createAlias('oggettoPraticaId', 'ogpr', CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)

            if (filter.oggetto) {
                eq('ogpr.oggetto.id', filter.oggetto)
            }
            if (filter.tipoTributo) {
                eq('prtr.tipoTributo.tipoTributo', filter.tipoTributo as String)
            }
        }.toDTO(['oggettoPratica'])
    }

    // Formatta la coordinata in formato sessagesimale - Gestisce i null
    def formatCoordinateSexagesimalNS(Double coord) {

        String formatted

        if (coord != null) {
            formatted = formatCoordinateSexagesimal(coord as Double)
        } else {
            formatted = ''
        }

        return formatted
    }

     // Formatta la coordinata in formato sessagesimale
    def formatCoordinateSexagesimal(Double coord) {

        DecimalFormat intFormatter = new DecimalFormat("###")
        DecimalFormat secFormatter = new DecimalFormat("##.00")

        String sign = (coord > 0.0) ? '' : '-'

        Double abs = Math.abs(coord)
        Double deg = Math.floor(abs)
        abs = (abs - deg) * 60.0
        Double fir = Math.floor(abs)
        Double sec = (abs - fir) * 60.0

        String firStr = intFormatter.format(fir).padLeft(2, "0")
        String secStr = secFormatter.format(sec).padLeft(5, "0")

        return sign + intFormatter.format(deg) + "°" + firStr + "'" + secStr + "\""
    }

    // determina url di google maps per l'oggetto della concessione
    def getGoogleMapshUrl(String type, double latitude, double longitude) {

        String url

        if ((type == null) || (type.isEmpty())) type = "DEF"

        if (type == 'DEF') {
            url = "https://www.google.it/maps/place/"
        } else {  // TBD
            url = "https://www.google.it/maps/place/"
        }

        url += formatCoordinateGoogleMaps(latitude, 'LAT')
        url += '+'
        url += formatCoordinateGoogleMaps(longitude, 'LON')

        return url
    }

    // formatta coordinata formato google maps
    def formatCoordinateGoogleMaps(Double coord, String type) {

        String plus
        String minus

        if (type == 'LAT') {
            plus = 'N'
            minus = 'S'
        } else {
            plus = 'E'
            minus = 'W'
        }

        DecimalFormat formatter = new DecimalFormat("##0.00000000")
        String number

        double val = coord ?: 0
        double abs = Math.abs(val)

        number = formatter.format(abs)
        number = number.replace(',', '.')

        return number + ((val >= 0.0) ? plus : minus)
    }

    // Valida e elabora coordinate formato testo
    def parseCoordinates(String coordinates) {

        String coord
        Double latitudine
        Double longitudine

        def report = [
                result     : 1,
                latitudine : null,
                longitudine: null
        ]

        coordinates = (coordinates ?: '')

        def coords = []
        def commas
        def spaces
        def dots

        try {
            coordinates = coordinates.replace('  ', ' ')
            coordinates = coordinates.replace(', ', ' ')        // NNN.any, NNN.any ->   NNN.any NNN.any

            commas = countChars(coordinates, ',')
            dots = countChars(coordinates, '.')
            spaces = countChars(coordinates, ' ')

            if ((commas == 2) && (dots == 0) && (spaces > 0)) {  // NNN,any NNN,any ->   NNN.any NNN.any
                coordinates = coordinates.replace(',', '.')
                commas = 0
            }

            if (commas == 1) {
                coords = coordinates.tokenize(',')              // NNN.any,NNN.any
            } else {
                coords = coordinates.tokenize(' ')              // NNN.any NNN.any
            }

            if (coords.size == 2) {

                latitudine = parseCoordinate(coords[0])
                longitudine = parseCoordinate(coords[1])

                if ((latitudine != null) && (longitudine != null) &&
                        (Math.abs(latitudine) < 90) && (Math.abs(longitudine) < 180)) {

                    report.latitudine = Math.floor((latitudine * 100000000) + 0.5) * 0.00000001
                    report.longitudine = Math.floor((longitudine * 100000000) + 0.5) * 0.00000001
                    report.result = 0
                }
            }
        }
        catch (Exception e) {
            //  println"Parse Error : ${e.message}"
            report.result = 2
        }

        if (report.result != 0) {

            String message = coordinates.substring(0, Math.min(coordinates.length(), 100))
            message = message.replace('\n', ' ')
            message = message.replace('\t', ' ')

            message = 'Impossibile elaborare le coordinate : "' + message + '"'
            report.message = message
        }

        return report
    }

    // converte testo coordinata - Se errore restituisce null
    def tryParseCoordinate(String coordinate) {

        Double result = null

        try {
            result = parseCoordinate(coordinate)
        }
        catch (Exception e) {
            result = null
        }

        return result
    }

    // converte testo coordinata
    def parseCoordinate(String coordinate) {

        String coord
        String deg
        String fir
        String sec

        def idx

        Double result = null

        coord = coordinate.replaceAll(",", ".")

        if ((idx = coord.indexOf('°')) > 0) {

            deg = coord.substring(0, idx)

            fir = coord.substring(idx + 1)

            idx = fir.indexOf('\'')
            if (idx > 0) {
                sec = fir.substring(idx + 1)
                fir = fir.substring(0, idx)
            } else {
                sec = fir;
                fir = '0'
            }

            idx = sec.indexOf('\"')
            if (idx > 0) {
                sec = sec.substring(0, idx)
            }
            if (sec.isEmpty()) sec = '0'

            result = Double.parseDouble(deg) + (Double.parseDouble(fir) / 60.0) + (Double.parseDouble(sec) / 3600.0)
        } else {
            result = Double.parseDouble(coord)
        }

        return result
    }

    def countChars(String text, String toMatch) {

        def count = 0

        def length = text.length()
        def ptr = 0
        def idx

        while (ptr < length) {
            idx = text.indexOf(toMatch, ptr)
            if (idx < 0)
                break;
            count++
            ptr = idx + 1
        }

        return count
    }
}
