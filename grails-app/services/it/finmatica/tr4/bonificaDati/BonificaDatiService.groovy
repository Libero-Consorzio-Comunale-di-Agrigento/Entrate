package it.finmatica.tr4.bonificaDati

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.anomalie.AnomaliaPratica
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica

@Transactional
class BonificaDatiService {
    def dataSource
    def sessionFactory

    def DenunceService denunceService
    AnomaliaMuiService anomaliaMuiService

    def getAnomalie(short idAnomalia, def anno) {
        def lista = []
        def parametriQuery = [:]
        (idAnomalia == 0) ?: (parametriQuery.pIdAnomalia = idAnomalia)
        (anno == null) ?: (parametriQuery.pAnno = (short) anno)

        String sql = """
						SELECT new Map(
							anpa.categorie as categorie, 
							anpa.lastUpdated as dataVariazione, 
							anpa.flagImposta as flagImposta, 
							anpa.flagSistemate as flagSistemate, 
							anpa.renditaDa as renditaDa, 
							anpa.renditaA as renditaA,
							anpa.scarto as scarto, 
							anpa.tipiTributo as tipiTributo, 
                            uten.id as utente,
							uten.nominativo as nominativoUtente,
							anomIci.tipoAnomalia.tipoAnomalia as tipoAnomalia,
							tipoAnom.descrizione as descrizione,
							anpa.anno as anno,
							anpa.renditaMassima as renditaMassima,
							anpa.renditaMedia as renditaMedia,
							(SELECT count(ai)
                             FROM Anomalia as ai
                             WHERE ai.anno = anpa.anno
                               AND ai.tipoAnomalia.tipoAnomalia = anomIci.tipoAnomalia.tipoAnomalia) as numOggetti)
						FROM
							AnomaliaParametro as anpa
						INNER JOIN
							anpa.utente AS uten	
						INNER JOIN
							anpa.anomalie AS anomIci						
						INNER JOIN
							anomIci.tipoAnomalia AS tipoAnom
						INNER JOIN 
							anomIci.oggetto AS ogg
						INNER JOIN
							ogg.oggettiPratica AS oggPrt
						INNER JOIN
							oggPrt.pratica prtr
					"""
        if (idAnomalia != 0 && anno != null) {
            sql += """	WHERE anomIci.tipoAnomalia.tipoAnomalia = :pIdAnomalia AND anpa.anno = :pAnno"""
        } else if (idAnomalia != 0 || anno != null) {
            sql += """	WHERE """
            (idAnomalia == 0) ?: (sql += """ anomIci.tipoAnomalia.tipoAnomalia = :pIdAnomalia""")
            (anno == null) ?: (sql += """ anpa.anno = :pAnno""")
        }

        sql += """"
				AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo 
			"""

        sql += """	GROUP BY
									anpa.categorie, 
									anpa.lastUpdated, 
									anpa.flagImposta, 
									anpa.flagSistemate, 
									anpa.renditaDa, 
									anpa.renditaA,
									anpa.scarto, 
									anpa.tipiTributo, 
									uten.nominativo,
									anomIci.tipoAnomalia.tipoAnomalia,
									tipoAnom.descrizione,
									anpa.anno,
									anpa.renditaMassima,
									anpa.renditaMedia"""
        lista = Anomalia.executeQuery(sql, parametriQuery)
        return lista
    }

    def getAnomalieIn(List idAnomalia, def anno, def tributi, String tipoControllo, def oggetto = null) {
        def lista = []
        def listaAnomalie = []
        def listaAnomalieMui = []
        def parametriQuery = [:]
        def tipiTributo = []
        String condizioneTipoControllo = ""
        (idAnomalia == null || idAnomalia.size() == 0) ?: (parametriQuery.pIdAnomalia = idAnomalia)
        (anno == null) ?: (parametriQuery.pAnno = (short) anno)
        (oggetto == null) ?: (parametriQuery.pOggetto = oggetto)
        if (tipoControllo == "I") {
            condizioneTipoControllo = " AND anpa.flagImposta = 'S' "
        }
        // Gestione tipi tributo
        if (tributi.ICI) {
            tipiTributo << 'ICI'
        }
        if (tributi.TASI) {
            tipiTributo << 'TASI'
        }
        if (!tributi.ICI && !tributi.TASI) {
            tipiTributo << 'X' // Tipo tributo non selezionato. Non si estraggono record.
        }

        if (tipoControllo == "D") {
            condizioneTipoControllo = " AND anpa.flagImposta = 'N' "
        }
        parametriQuery.pTipiTributo = tipiTributo

        String sql = """
						SELECT new Map(
						    anpa.id as id,
						    anpa.valoreMassimo as valoreMassimo,
						    anpa.valoreMedio as valoreMedio,
							anpa.categorie as categorie, 
							anpa.lastUpdated as dataVariazione, 
							anpa.flagImposta as flagImposta, 
							anpa.renditaDa as renditaDa, 
							anpa.renditaA as renditaA,
							anpa.scarto as scarto, 
							f_descrizione_titr(anpa.tipoTributo.tipoTributo, anpa.anno) as tipoTributo,
							anpa.tipoTributo.tipoTributo as tipoTributoOrg,
                            uten.id as utente,
							uten.nominativo as nominativoUtente,
							tipoAnom.tipoIntervento as tipoIntervento,	
							tipoAnom.tipoAnomalia as tipoAnomalia,
							tipoAnom.descrizione as descrizione,
							tipoAnom.zul as pannello,
							anpa.anno as anno,
							anpa.renditaMassima as renditaMassima,
							anpa.renditaMedia as renditaMedia,
							(SELECT count(ai)
                             FROM Anomalia as ai                           
                             WHERE ai.anomaliaParametro = anpa
                               AND ai.flagOk = 'N') as numOggetti,
							(SELECT count(ai)
                             FROM Anomalia as ai                           
                             WHERE ai.anomaliaParametro = anpa) as numTotOggetti,
                            1 as visibile)
						FROM
							AnomaliaParametro as anpa
						INNER JOIN
							anpa.utente AS uten	
						INNER JOIN
							anpa.anomalie AS anomIci						
						INNER JOIN
							anpa.tipoAnomalia AS tipoAnom
						INNER JOIN 
							anomIci.oggetto AS ogg
						INNER JOIN
							ogg.oggettiPratica AS oggPrt
						INNER JOIN
							oggPrt.oggettiContribuente oggCnt
						INNER JOIN
							oggPrt.pratica prtr
					"""
        if (idAnomalia != null && idAnomalia.size() > 0 && anno != null) {
            sql += """	WHERE tipoAnom.tipoAnomalia in (:pIdAnomalia) AND anpa.anno = :pAnno"""
        } else if ((idAnomalia != null && idAnomalia.size() > 0) || anno != null) {
            sql += """	WHERE """
            (idAnomalia == null || idAnomalia.size() == 0) ?: (sql += """ tipoAnom.tipoAnomalia in ( :pIdAnomalia )""")
            (anno == null) ?: (sql += """ anpa.anno = :pAnno""")
        }

        if (oggetto) {
            sql += """ AND ogg.id = :pOggetto """
        }

        sql += condizioneTipoControllo + """
											AND oggCnt.tipoRapporto = 'D'
											"""
        sql += """
				AND anpa.tipoTributo.tipoTributo IN (:pTipiTributo)
				AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo 
				"""
        sql += """	GROUP BY
									anpa.categorie, 
									anpa.lastUpdated, 
									anpa.flagImposta, 
									anpa.renditaDa, 
									anpa.renditaA,
									anpa.scarto, 
									anpa.tipoTributo.tipoTributo,
									uten.id,
									uten.nominativo,
									tipoAnom.tipoIntervento,
									tipoAnom.tipoAnomalia,
									tipoAnom.descrizione,
									tipoAnom.zul,
									anpa.anno,
									anpa.id,
									anpa.renditaMassima,
									anpa.renditaMedia,
									anpa.valoreMassimo,
                                    anpa.valoreMedio
									"""

        listaAnomalie = Anomalia.executeQuery(sql, parametriQuery)
        lista.addAll(listaAnomalie)

        // Anomalie Ici per caricamento MUI
        List<Short> tipiAnomalieMui = idAnomalia.findAll { isTipoAnomaliaForMui(it) }

        if (!tipiAnomalieMui.empty && !tipiTributo.empty && tipoControllo in ['T', 'D']) {
            def filter = [
                    tipiAnomalia : tipiAnomalieMui,
                    anno         : anno,
                    tipoControllo: tipoControllo,
                    tipiTributo  : tipiTributo,
                    oggetti      : oggetto ? [oggetto] : null]

            listaAnomalieMui = anomaliaMuiService.getAnomalieMUI(filter)

            lista.addAll(listaAnomalieMui)
        }

        lista.sort { a, b -> a.anno <=> b.anno ?: a.tipoAnomalia <=> b.tipoAnomalia }

        return lista
    }

    def getDettagli(short tipoAnomalia, short anno, String flagImposta, String tipoTributo,
                    def filtri, def ordinamento, int pageSize, int activePage) {
        def lista = []
        def listaOggettiSostituiti = []
        def parametriQuery = [:]
        parametriQuery.pTipoAnomalia = tipoAnomalia
        parametriQuery.pAnno = anno
        parametriQuery.pFlagImposta = flagImposta
        parametriQuery.pTipoTributo = tipoTributo == 'IMU' ? 'ICI' : tipoTributo

        String sql = """
						SELECT new Map(
                            anomIci.valoreMedio                 as valoreMedio,
                            anomIci.valoreMassimo               as valoreMassimo,
							anomIci.id 							as idAnomalia,
							anpa.tipoAnomalia.tipoAnomalia 	  	as tipoAnomalia,
							anpa.anno 					  	  	as anno,
							anomIci.flagOk 					  	as stato,
							ogg.id 							  	as idOggetto,
							vie.id				  			  	as codVia,
							vie.denomUff 					  	as denomUff,
							ogg.indirizzoLocalita			  	as indirizzoLocalita,
							ogg.numCiv						  	as numCiv,
							anomIci.renditaMassima as renditaMassima,
							anomIci.renditaMedia as renditaMedia,
							ogg.categoriaCatasto.categoriaCatasto	as categoria,
							ogg.classeCatasto						as classe,
							ogg.sezione								as sezione,
							ogg.foglio								as foglio,
							ogg.numero								as numero,
							ogg.subalterno							as subalterno,
							ogg.zona								as zona,
							ogg.partita                             as partita,
							ogg.tipoOggetto.tipoOggetto				as tipoOggetto,
							anpa.flagImposta						as flagImposta,
							anpa.categorie							as categorie,
							ogg.estremiCatasto						as estremiCatasto,
							ogg.protocolloCatasto					as protocolloCatasto,
							ogg.annoCatasto							as annoCatasto,
							nvl(vie.denomUff, ogg.indirizzoLocalita) ||
							(case
								when ogg.numCiv is not null then ','
								else ''
							end) || nvl(ogg.numCiv, '')
																	as indirizzoCompleto,
							lpad(nvl(ogg.sezione, ' '), 3, ' ') || 
								lpad(nvl(ogg.foglio, ' '), 5, ' ') || 
								lpad(nvl(ogg.numero, ' '), 5, ' ') ||
							    lpad(nvl(ogg.subalterno, ' '), 4, ' ') ||
							    lpad(nvl(ogg.zona, ' '), 3, ' ') as estremiCatastoOrdinamento,
								ogg.tipoOggetto.tipoOggetto,
							nvl(vie.denomUff, nvl(ogg.indirizzoLocalita, ' ')) || 
								 decode(ogg.numCiv, null, '', ', ' || ogg.numCiv) ||
								 decode(ogg.suffisso, null, '', '/' || ogg.suffisso) ||
								 decode(ogg.scala, null, '', ' Sc:' || ogg.scala) ||
								 decode(ogg.piano, null, '', ' P:' || ogg.piano) ||
								 decode(ogg.interno, null, '', ' int. ' || ogg.interno) as indirizzo
						)
						FROM
							Anomalia as anomIci
						INNER JOIN
							anomIci.anomaliaParametro AS anpa
						INNER JOIN
							anomIci.oggetto AS ogg
						INNER JOIN
							ogg.oggettiPratica AS oggPrt
						INNER JOIN
							oggPrt.oggettiContribuente oggCnt
						LEFT JOIN
							ogg.archivioVie AS vie
						INNER JOIN
							oggPrt.pratica prtr
						WHERE
							anpa.tipoAnomalia.tipoAnomalia = :pTipoAnomalia and
							anpa.anno = :pAnno and 
					        anpa.flagImposta = :pFlagImposta and
							oggCnt.tipoRapporto = 'D'
							AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo 
							AND anpa.tipoTributo.tipoTributo = :pTipoTributo
						"""


        String sqlOggettiSostituiti = """
						    SELECT new Map(
						    0 as valoreMassimo,
                            0 as valoreMedio,
							anomIci.id 							as idAnomalia,
							anpa.tipoAnomalia.tipoAnomalia 	  	as tipoAnomalia,
							anpa.anno 					  	  	as anno,
							anomIci.flagOk 					  	as stato,
							ogg.id 							  	as idOggetto,
							vie.id				  			  	as codVia,
							vie.denomUff 					  	as denomUff,
							ogg.indirizzoLocalita			  	as indirizzoLocalita,
							ogg.numCiv						  	as numCiv,
							0 as renditaMedia,
							0 as renditaMassima,
							ogg.categoriaCatasto.categoriaCatasto	as categoria,
							ogg.classeCatasto						as classe,
							ogg.sezione								as sezione,
							ogg.foglio								as foglio,
							ogg.numero								as numero,
							ogg.subalterno							as subalterno,
							ogg.zona								as zona,
							ogg.partita                             as partita,
							ogg.tipoOggetto.tipoOggetto				as tipoOggetto,
							anpa.flagImposta						as flagImposta,
							anpa.categorie							as categorie,
							ogg.estremiCatasto						as estremiCatasto,
							ogg.protocolloCatasto					as protocolloCatasto,
							ogg.annoCatasto							as annoCatasto,
							nvl(vie.denomUff, ogg.indirizzoLocalita) ||
							(case
								when ogg.numCiv is not null then ','
								else ''
							end) || nvl(ogg.numCiv, '')
																	as indirizzoCompleto,
							lpad(nvl(ogg.sezione, ' '), 3, ' ') || 
								lpad(nvl(ogg.foglio, ' '), 5, ' ') || 
								lpad(nvl(ogg.numero, ' '), 5, ' ') ||
							    lpad(nvl(ogg.subalterno, ' '), 4, ' ') ||
							    lpad(nvl(ogg.zona, ' '), 3, ' ') as estremiCatastoOrdinamento,
							nvl(vie.denomUff, nvl(ogg.indirizzoLocalita, ' ')) || 
								 decode(ogg.numCiv, null, '', ', ' || ogg.numCiv) ||
								 decode(ogg.suffisso, null, '', '/' || ogg.suffisso) ||
								 decode(ogg.scala, null, '', ' Sc:' || ogg.scala) ||
								 decode(ogg.piano, null, '', ' P:' || ogg.piano) ||
								 decode(ogg.interno, null, '', ' int. ' || ogg.interno) as indirizzo
						)
						FROM
							Anomalia as anomIci
						INNER JOIN
							anomIci.anomaliaParametro AS anpa
						INNER JOIN
							anomIci.oggetto AS ogg
						LEFT JOIN
							ogg.archivioVie AS vie
						WHERE
							anpa.tipoAnomalia.tipoAnomalia = :pTipoAnomalia and
							anpa.anno = :pAnno and 
					        anpa.flagImposta = :pFlagImposta and
							anomIci.flagOk = 'S'
						"""

        // Tipo oggetto
        if (filtri?.tipoOggettoSelezionato != null) {
            parametriQuery.pTipoOggetto = filtri?.tipoOggettoSelezionato?.tipoOggetto
            sql += """	AND ogg.tipoOggetto.tipoOggetto = :pTipoOggetto"""
            sqlOggettiSostituiti += """	AND ogg.tipoOggetto.tipoOggetto = :pTipoOggetto"""
        }

        // Stato dell'anomalia
        if (filtri?.stato == "2") {
            parametriQuery.pStato = 'S'
            sql += """	AND anomIci.flagOk = :pStato"""
            sqlOggettiSostituiti += """	AND anomIci.flagOk = :pStato"""
        } else if (filtri?.stato == "1") {
            parametriQuery.pStato = 'N'
            sql += """	AND anomIci.flagOk = :pStato"""
            sqlOggettiSostituiti += """	AND anomIci.flagOk = :pStato"""
        }

        // Oggetto
        if (filtri?.idOggetto != null) {
            parametriQuery.pIdOggetto = filtri?.idOggetto
            sql += """	AND ogg.id = :pIdOggetto"""
            sqlOggettiSostituiti += """	AND ogg.id = :pIdOggetto"""
        }

        if (filtri?.categoriaCatasto) {
            parametriQuery.pCategoriaCatasto = filtri.categoriaCatasto.categoriaCatasto
            sql += """
                AND ogg.categoriaCatasto.categoriaCatasto || '' = :pCategoriaCatasto
            """
            sqlOggettiSostituiti += """
                AND ogg.categoriaCatasto.categoriaCatasto || '' = :pCategoriaCatasto
            """
        }

        sql += """	GROUP BY
						anomIci.id,
						anpa.tipoAnomalia.tipoAnomalia,
						anpa.anno,
						anomIci.flagOk,
						ogg.id,
						vie.id,
						vie.denomUff, 
						ogg.indirizzoLocalita,
						ogg.numCiv,
						ogg.categoriaCatasto.categoriaCatasto,
						ogg.classeCatasto,
						ogg.sezione,
						ogg.foglio,
						ogg.numero,
						ogg.subalterno,
						ogg.zona,
						ogg.tipoOggetto.tipoOggetto,
						ogg.estremiCatasto,
						ogg.protocolloCatasto,
						ogg.annoCatasto,
						ogg.suffisso,
						ogg.piano,
						ogg.scala,
						ogg.interno,
						anpa.flagImposta,
						anpa.categorie,
						anomIci.renditaMassima,
						anomIci.renditaMedia, 
						anomIci.valoreMassimo,
                        anomIci.valoreMedio,
						ogg.partita"""

        lista = Anomalia.executeQuery(sql, parametriQuery)
        parametriQuery.remove('pTipoTributo')
        listaOggettiSostituiti = Anomalia.executeQuery(sqlOggettiSostituiti, parametriQuery)

        def listaTemporanea = []

        listaOggettiSostituiti.each { newOgg ->
            if (!lista.find { it.idOggetto == newOgg.idOggetto }) {
                listaTemporanea.push(newOgg)
            }
        }

        lista += listaTemporanea

        ordinamento.each { k, v ->
            if (v.verso) {
                if (k in ['renditaMedia', 'idOggetto', 'renditaMassima', 'indirizzo', 'categoria', 'classe', 'valoreMedio', 'valoreMassimo']) {
                    lista = lista.sort { o1, o2 -> (v.verso == 'A' ? 1 : -1) * (o1[k] <=> o2[k]) }
                } else if (k in ['subalterno', 'numero', 'foglio', 'sezione']) {
                    lista = lista.sort { o1, o2 -> (v.verso == 'A' ? 1 : -1) * (((o1[k] ?: "") + "").padLeft(50, "0") <=> ((o2[k] ?: "") + "").padLeft(50, "0")) }
                }
            }
        }

        // La paginazione viene eseguita dopo la query per gestire la UNION
        int pages = lista.size / pageSize
        int delta = lista.size % pageSize
        int calculatedPageSize = 0

        if (pages == 0) {
            activePage = 0
        } else {
            if (delta > 0 && pages == activePage) {
                calculatedPageSize = delta - 1
            } else if (lista.size > 0) {
                if (lista.size > pageSize) {
                    calculatedPageSize = pageSize - 1
                } else {
                    calculatedPageSize = lista.size - 1
                }
            }

            // Se eravamo sull'ultima pagina ed eliminiamo l'ultimo oggetto ci spostiamo sulla pagina precedente
            if ((activePage + 1) > Math.ceil(lista.size / pageSize)) {
                activePage -= 1
            }
        }

        return [list: (lista.size > 0 && lista.size > pageSize) ? lista[pageSize * activePage..pageSize * activePage + calculatedPageSize] : lista, total: lista.size, activePage: activePage]
    }

    def getDettagliAnomaliaPratica(short tipoAnomalia, short anno, String flagImposta,
                                   def filtri, List tipiTributo, List tipiPratiche,
                                   def ordinamento, int pageSize, int activePage) {
        if (isTipoAnomaliaForMui(tipoAnomalia)) {
            def filter = [
                    tipiAnomalia: [tipoAnomalia],
                    anno            : anno,
                    tipiTributo     : tipiTributo,
                    tipiPratiche    : tipiPratiche,
                    ordinamento     : ordinamento,
                    tipoOggetto     : filtri.tipoOggettoSelezionato?.tipoOggetto,
                    categoriaCatasto: filtri.categoriaCatasto?.categoriaCatasto,
                    stato       : filtri.stato,
                    oggetti     : filtri.idOggetto ? [filtri.idOggetto] : null,
                    pageSize        : pageSize,
                    activePage      : activePage
            ]

            return anomaliaMuiService.getDettagliAnomaliaOggettiAndPratiche(filter)
        }

        def lista = []
        def totale

        def parametriQuery = [:]

        parametriQuery.pTipoAnomalia = tipoAnomalia
        parametriQuery.pAnno = anno
        parametriQuery.pFlagImposta = flagImposta

        String queryTot = """SELECT COUNT(distinct anic) 
							 FROM Anomalia anic
						  INNER JOIN anic.anomaliaParametro anpa
						  INNER JOIN anic.anomaliePratiche anpr
						  INNER JOIN anpr.oggettoContribuente ogco
						  INNER JOIN ogco.oggettoPratica ogpr
						  INNER JOIN ogpr.pratica prtr 
						  INNER JOIN anic.oggetto anicOgge """
        String query = """
							SELECT distinct new Map(
								anic.flagOk as flagOk,
								anic.id	as idAnomalia,
								anicOgge.tipoOggetto.tipoOggetto as tipoOggetto,
								anicOgge.id as idOggetto,   
							    nvl(arvi.denomUff, nvl(anicOgge.indirizzoLocalita, ' ')) || 
									 decode(anicOgge.numCiv, null, '', ', ' || anicOgge.numCiv) ||
									 decode(anicOgge.suffisso, null, '', '/' || anicOgge.suffisso) ||
									 decode(anicOgge.scala, null, '', ' Sc:' || anicOgge.scala) ||
								     decode(anicOgge.piano, null, '', ' P:' || anicOgge.piano) ||
								     decode(anicOgge.interno, null, '', ' int. ' || anicOgge.interno) as indirizzo,
								anicOgge.categoriaCatasto.categoriaCatasto as categoriaCatasto,
								anicOgge.classeCatasto as classeCatasto,
								anicOgge.sezione as sezione,
								anicOgge.foglio as foglio,
								anicOgge.numero as numero,
								anicOgge.zona as zona,
								anicOgge.subalterno as subalterno,
								anicOgge.zona as zona,
								anicOgge.protocolloCatasto  as protocolloCatasto,
								anicOgge.annoCatasto as annoCatasto,
								anicOgge.partita as partita,								
								anic.valoreMassimo as valoreMassimo,
                                anic.valoreMedio as valoreMedio,
                                anic.renditaMassima as renditaMassima,
                                anic.renditaMedia as renditaMedia                                 
							)
							FROM
								Anomalia as anic
								INNER JOIN anic.anomaliaParametro anpa
							  	INNER JOIN anic.anomaliePratiche anpr
							  	INNER JOIN anpr.oggettoContribuente ogco
							  	INNER JOIN ogco.oggettoPratica ogpr
							  	INNER JOIN ogpr.pratica prtr 
							  	INNER JOIN anic.oggetto anicOgge
								LEFT JOIN anicOgge.archivioVie AS arvi
							"""
        String where = """						  
				   WHERE
				       anpa.tipoAnomalia.tipoAnomalia = :pTipoAnomalia and
					   anpa.anno = :pAnno and 
					   anpa.flagImposta = :pFlagImposta
					   AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo
		"""
        String group = """
            GROUP BY
            anic.flagOk,
            anic.id,
            anicOgge.tipoOggetto.tipoOggetto,
            anicOgge.id,
            arvi.denomUff,
            anicOgge.indirizzoLocalita,
            anicOgge.numCiv,
            anicOgge.suffisso,
            anicOgge.scala,
            anicOgge.piano,
            anicOgge.interno,
            anicOgge.categoriaCatasto.categoriaCatasto,
            anicOgge.classeCatasto,
            anicOgge.sezione,
            anicOgge.foglio,
            anicOgge.numero,
            anicOgge.zona,
            anicOgge.subalterno,
            anicOgge.zona,
            anicOgge.protocolloCatasto,
            anicOgge.annoCatasto,
            anicOgge.partita,
            anic.renditaMedia,
            anic.renditaMassima,
            anic.valoreMedio,
            anic.valoreMassimo
        """

        String queryDettaglio = """
					SELECT DISTINCT new Map(
									anic.id as idAnomalia,
									anicOgge.id as idOggetto,
									anpr.flagOk as flagOk,
									ogpr.tipoOggetto.tipoOggetto as tipoOggetto,
									prtr.id as idPratica,
									ogpr.numOrdine as numOrdine,
									prtr.tipoTributo.tipoTributo as tipoTributo,
									prtr.anno as anno,
									ogco.tipoRapporto as tipoRapporto,
									ogco.contribuente.soggetto.cognomeNome as cognomeNome,
									ogco.contribuente.codFiscale as codFiscale,
									ogpr.categoriaCatasto.categoriaCatasto as categoriaCatasto,
									ogpr.classeCatasto as classeCatasto,
									ogco.mesiPossesso as mesiPossesso,
									ogco.percPossesso as percPossesso,
									ogco.flagPossesso as flagPossesso,
									ogco.flagEsclusione as flagEsclusione,
									anpr.valore as valore,
									anpr.rendita as rendita,
									ogpr.id	as idOggettoPratica,
									anpr.id	as idAnomaliaPratica,
									ogco.contribuente.soggetto.codFiscale
							)
							FROM
								Anomalia as anic
								INNER JOIN anic.anomaliaParametro anpa
							  	INNER JOIN anic.anomaliePratiche anpr
							  	INNER JOIN anpr.oggettoContribuente ogco
							  	INNER JOIN ogco.oggettoPratica ogpr
							  	INNER JOIN ogpr.pratica prtr
								INNER JOIN prtr.rapportiTributo ratr
							  	INNER JOIN anic.oggetto anicOgge
								LEFT JOIN anicOgge.archivioVie AS arvi
					WHERE anic.id = :pIdAnomalia
			"""

        switch (tipoAnomalia) {
            case 1:
                queryDettaglio += """
							ORDER BY prtr.anno, ogco.contribuente.soggetto.codFiscale
						  """
                break
                queryDettaglio += """
							ORDER BY ogco.contribuente.soggetto.codFiscale, prtr.anno, prtr.id
						  """
            case 4:

                break

            default:
                queryDettaglio += """
							ORDER BY prtr.anno, ogco.contribuente.soggetto.codFiscale
						  """
        }

        if (filtri?.idOggetto) {
            parametriQuery.idOggetto = filtri.idOggetto
            where += """	AND anicOgge.id = :idOggetto """
        }
        if (filtri?.stato == "2") {
            where += """	AND anic.flagOk = 'S' """
        } else if (filtri?.stato == "1") {
            where += """	AND anic.flagOk = 'N' """
        }

        if (filtri?.tipoOggettoSelezionato) {
            parametriQuery.pTipoOggetto = filtri?.tipoOggettoSelezionato.tipoOggetto
            where += """ AND anicOgge.tipoOggetto.tipoOggetto = :pTipoOggetto  """
        }

        if (tipiTributo.size() > 0) {
            parametriQuery.pTipiTributo = tipiTributo
            where += """ AND prtr.tipoTributo.tipoTributo IN (:pTipiTributo) """
        }

        if (tipiPratiche.size() > 0) {
            parametriQuery.pTipiPratiche = tipiPratiche
            where += """ AND prtr.tipoPratica IN (:pTipiPratiche) """
        }

        if (filtri?.categoriaCatasto) {
            parametriQuery.pCategoriaCatasto = filtri.categoriaCatasto.categoriaCatasto
            where += """	AND anicOgge.categoriaCatasto.categoriaCatasto = :pCategoriaCatasto """
        }

        String order = ""

        ordinamento.each { k, v ->
            if (v.verso) {
                if (!order) {
                    order = """
						ORDER BY 
					"""
                }

                if (k == 'indirizzo') {
                    k = """nvl(arvi.denomUff, nvl(anicOgge.indirizzoLocalita, ' ')) || 
									 decode(anicOgge.numCiv, null, '', ', ' || anicOgge.numCiv) ||
									 decode(anicOgge.suffisso, null, '', '/' || anicOgge.suffisso) ||
									 decode(anicOgge.scala, null, '', ' Sc:' || anicOgge.scala) ||
								     decode(anicOgge.piano, null, '', ' P:' || anicOgge.piano) ||
								     decode(anicOgge.interno, null, '', ' int. ' || anicOgge.interno)"""
                }

                if (k in ["anic.renditaMedia", "anic.renditaMassima", "anic.valoreMedio", "anic.valoreMassimo"]) {
                    order += """ NVL($k, 0) """
                } else {
                    order += """ LPAD(NVL($k, '0'), 50, '0') """
                }

                order += (v.verso == 'A' ? 'ASC' : 'DESC') + ""","""
            }
        }

        // Elimino l'ultima virgola
        order = order ? order.substring(0, order.length() - 1) : ""

        totale = Anomalia.executeQuery(queryTot + where, parametriQuery)
        lista = Anomalia.executeQuery(query + where + group + order, parametriQuery, [max: pageSize, offset: pageSize * activePage])
        if (activePage > 0 && lista.size() == 0) {
            activePage -= 1
            lista = Anomalia.executeQuery(query + where + order, parametriQuery, [max: pageSize, offset: pageSize * activePage])
        }

        lista.each { anom ->
            // Pratiche
            anom.dettagli = Anomalia.executeQuery(queryDettaglio, [pIdAnomalia: anom.idAnomalia])
            // Stato di elaborazione dell'anomalia
            anom.praticheCorrette = Anomalia.executeQuery("""SELECT count(*)
															 FROM Anomalia AS anom
															 INNER JOIN anom.anomaliePratiche AS anpr
														     WHERE anom.id = :pIdAnomalia
																   AND anpr.flagOk = 'S' """, [pIdAnomalia: anom.idAnomalia])[0]
        }
        return [list: lista, total: totale[0]]
    }

    def getPratiche(long idOggetto, int pageSize, int activePage, List tipiTributo, List tipiPratiche,
                    def annoPratica) {
        def lista = []
        def totale
        def parametriQuery = [:]
        parametriQuery.pIdOggetto = idOggetto

        String sql = """
						SELECT new Map(
							prt.id as idPratica,
                            prt.tipoTributo.tipoTributo as tipoTributo,
							prt.tipoPratica as tipoPratica,
                            prt.anno as anno,
                            oggCo.tipoRapporto as tipoRapporto,
							oggCo.contribuente.soggetto.cognomeNome as contribuente,
							oggCo.contribuente.codFiscale as codFiscale,
                            oggCo.mesiPossesso as mesiPossesso,
                            oggCo.percPossesso as percPossesso,
							f_valore( oggPrt.valore,
                             COALESCE(oggPrt.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto),
                             prt.anno,
                             prt.anno,
                             COALESCE(oggPrt.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto),
                             prt.tipoPratica,
                             oggPrt.flagValoreRivalutato) as valore, 
							(CASE WHEN oggPrt.tipoOggetto.tipoOggetto != 4 THEN
								F_RENDITA(oggPrt.valore, 
									NVL(oggPrt.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto),
								 	prt.anno,
								 	NVL(oggPrt.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto))
							ELSE oggPrt.valore
							END
								) as rendita,
                            ogge.tipoOggetto as tipoOggetto
							)
						FROM
							OggettoContribuente as oggCo
							INNER JOIN oggCo.oggettoPratica as oggPrt
							INNER JOIN oggPrt.pratica as prt
							INNER JOIN oggPrt.oggetto as ogge
						WHERE
							oggPrt.oggetto.id = :pIdOggetto
						AND prt.tipoPratica != 'K'
		"""

        if (annoPratica != null) {
            parametriQuery.pAnnoPratica = annoPratica
            sql += """ AND prt.anno = :pAnnoPratica"""
        }

        if (tipiTributo.size() > 0) {
            parametriQuery.pTipiTributo = tipiTributo
            sql += """ AND prt.tipoTributo.tipoTributo NOT IN (:pTipiTributo)"""
        }

        if (tipiPratiche.size() > 0) {
            parametriQuery.pTipiPratiche = tipiPratiche
            sql += """ AND prt.tipoPratica NOT IN (:pTipiPratiche)"""
        }

        sql += """
				ORDER BY oggCo.contribuente.codFiscale,
						 prt.tipoTributo.tipoTributo,
						 prt.tipoPratica,
						 prt.anno desc,
						 prt.data desc
					"""

        totale = OggettoContribuente.executeQuery(sql, parametriQuery)
        lista = OggettoContribuente.executeQuery(sql, parametriQuery, [max: pageSize, offset: pageSize * activePage])

        return [list: lista, total: totale.size]
    }

    def pratichePerAnni(long idOggetto) {
        List listaAnni = []
        def parametriQuery = [:]
        parametriQuery.pIdOggetto = idOggetto
        String sqlAnni = """
						SELECT DISTINCT
							prt.anno
						FROM
							OggettoContribuente as oggCo
						INNER JOIN
							oggCo.oggettoPratica as oggPrt
						INNER JOIN
							oggPrt.pratica as prt
						WHERE
							oggPrt.oggetto.id = :pIdOggetto"""

        listaAnni = OggettoContribuente.executeQuery(sqlAnni, parametriQuery)

        return listaAnni
    }

    String eliminaOgcoDuplicati(AnomaliaPraticaDTO principale) {
        String message = ""

        Sql sql = new Sql(dataSource)

        def results = sql.rows("""
						SELECT DISTINCT TIAN.DESCRIZIONE AS descrizione,
										ANPA1.ID_ANOMALIA_PARAMETRO as id,
                                        ANPA1.ID_TIPO_ANOMALIA as tipoAnomalia,
										ANPA1.ANNO as anno,
										ANPA1.TIPO_TRIBUTO as tipoTributo,
										ANPA1.FLAG_IMPOSTA as flagImposta
						  FROM ANOMALIE_PARAMETRI ANPA1,
							   ANOMALIE           ANOM1,
							   ANOMALIE_PRATICHE  ANPR1,
							   TIPI_ANOMALIA      TIAN
						 WHERE ANPA1.ID_ANOMALIA_PARAMETRO = ANOM1.ID_ANOMALIA_PARAMETRO
						   AND ANOM1.ID_ANOMALIA = ANPR1.ID_ANOMALIA
						   AND ANPA1.ID_TIPO_ANOMALIA = TIAN.TIPO_ANOMALIA
						   AND ANPR1.OGGETTO_PRATICA IN
							   (SELECT ANPR.OGGETTO_PRATICA
								  FROM ANOMALIE_PARAMETRI ANPA,
									   ANOMALIE           ANOM,
									   ANOMALIE_PRATICHE  ANPR
								 WHERE ANPA.ID_ANOMALIA_PARAMETRO = ANOM.ID_ANOMALIA_PARAMETRO
								   AND ANOM.ID_ANOMALIA = ANPR.ID_ANOMALIA
								   AND ANPR.ANOMALIA_PRATICA_RIF = ${principale.id})
								   AND ANPR1.ANOMALIA_PRATICA_RIF != ${principale.id}
						""")

        if (results.size() > 0) {
            message = 'Oggetti pratica presenti in più anomalie:\n'
            for (def r : results) {
                message += "\n${r.anno} ${r.tipoAnomalia}-${r.descrizione} ${r.tipoTributo}" + (r.flagImposta == 'S' ? ' Da Imposta' : '')
            }

            return message
        }

        List<AnomaliaPratica> duplicati = AnomaliaPratica.findAllByAnomaliaPraticaRif(principale.getDomainObject())
        //se sono contitolari si cancella l'ogco
        //se sono titolari si cancella l'ogpr
        for (duplicato in duplicati) {
            if (message && !message.isEmpty()) {
                message += "\n"
            }
            message = denunceService.eliminaOgCo(duplicato.oggettoContribuente)
        }

        return message

    }

    def annullaFlagPossesso(AnomaliaPraticaDTO principale) {

        String message = ""

        String sqlOgPrRifC = """
                SELECT ogpr
                FROM OggettoPratica ogpr
                INNER JOIN ogpr.oggettiContribuente ogco
                WHERE (ogpr.oggettoPraticaRif.id = :pIdOgPrRif OR
                      ogpr.oggettoPraticaRifAp.id = :pIdOgPrRifAp) AND
                      ogco.contribuente.codFiscale = :pCodFiscale
			"""

        List<AnomaliaPratica> duplicati = AnomaliaPratica.findAllByAnomaliaPraticaRif(principale.getDomainObject())
        //se sono contitolari si cancella l'ogco
        //se sono titolari si cancella l'ogpr
        //alla fine si verifica se le pratiche sono rimaste vuote per eliminarle
        for (duplicato in duplicati) {
            if (OggettoPratica.executeQuery(sqlOgPrRifC, [pIdOgPrRif  : duplicato.oggettoContribuente.oggettoPratica.id,
                                                          pIdOgPrRifAp: duplicato.oggettoContribuente.oggettoPratica.id,
                                                          pCodFiscale : duplicato.oggettoContribuente.contribuente.codFiscale]).isEmpty()) {
                OggettoContribuente oggetto = duplicato.oggettoContribuente
                oggetto.flagPossesso = false
                oggetto.save(flush: true, failOnError: true)
            } else {
                if (message && !message.isEmpty()) {
                    message += "\n"
                }
                message = "Impossibile disabilitare il possesso.\nEsistono pratiche successive."
            }
        }

        return message

    }

    def cambiaStatoAnomaliaPratica(long idAnomaliaPratica, String nuovoStato = 'S') {

        AnomaliaPratica anpr = AnomaliaPratica.get(idAnomaliaPratica)

        anpr.flagOk = nuovoStato
        anpr.save(flush: true, failOnError: true)
        return anpr
    }

    def cambiaStatoAnomaliaOggetto(long idAnomalia, String nuovoStato = 'S') {
        Anomalia anomaliaSelezionata = Anomalia.get(idAnomalia)
        anomaliaSelezionata.flagOk = nuovoStato
        anomaliaSelezionata.save(flush: true, failOnError: true)
        return anomaliaSelezionata
    }

    def cambiaStatoAnomaliaMui(def idAnomalia, def stato) {
        return anomaliaMuiService.cambiaStatoAnomalia(idAnomalia, stato)
    }

    boolean isTipoAnomaliaForMui(def tipoAnomalia) {
        return (tipoAnomalia as Integer) in [22, 23]
    }

    def findAnomaliaPraticaDTOById(def idAnomaliaPratica) {
        def anomaliaPratica = AnomaliaPratica.findById(idAnomaliaPratica)

        return anomaliaPratica.toDTO(["oggettoContribuente", "anomalia.anomaliaParametro",
                                      "oggettoContribuente.oggettoPratica", "oggettoContribuente.contribuente.soggetto",
                                      "oggettoContribuente.oggettoPratica.pratica.tipoTributo"])
    }

    def getOggettoContribuente(def codFiscale, def oggettoPraticaId) {
        return OggettoContribuente.createCriteria().list {
            eq('contribuente.codFiscale', codFiscale as String)
            eq('oggettoPratica.id', oggettoPraticaId as Long)
        }[0].toDTO(["oggettoPratica", "oggettoPratica.pratica.tipoTributo", "contribuente.soggetto"])
    }

    def salvaAnomaliePratiche(def anomaliePratiche) {
        anomaliePratiche*.save(flush: true, failOnError: true)
    }

}
