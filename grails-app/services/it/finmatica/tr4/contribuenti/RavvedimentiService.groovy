package it.finmatica.tr4.contribuenti

import java.text.DecimalFormat

import org.hibernate.transform.AliasToEntityMapResultTransformer

class RavvedimentiService {

    static transactional = false

    def dataSource

    def sessionFactory

    def springSecurityService

    // Estrae elenco ravvedimenti
    def getRavvedimenti(def parametriRicerca, def sortBy = null, int pageSize = 999999, int activePage = 0, boolean onlyIDs = false) {

	//	DecimalFormat valuta = new DecimalFormat("� #,###.00")
        DecimalFormat valuta = new DecimalFormat("#,###.00")	// Il � simbolo non appare correttamente nei tooltiptext

        def sortBySql = ""
        sortBy.each { k, v ->
            if (v.verso) {
                if (sortBySql.isEmpty()) {
                    sortBySql += "ORDER BY"
                }
                switch (k) {
                    case 'COD_FISCALE':
                        sortBySql += """\nlpad(upper("COD_FISCALE"), 15, \' \') ${v.verso},"""
                        break
                    default:
                        sortBySql += """\n"$k" ${v.verso},"""
                        break
                }
            }
        }
        if (sortBySql.isEmpty()) {
            sortBySql = "ORDER BY SOGGETTI.COGNOME ASC, SOGGETTI.NOME ASC\n"
        } else {
            sortBySql = sortBySql.substring(0, sortBySql.length() - 1)
        }

        String sql = ""
        String sqlTotali = ""
        String sqlFiltri = ""
        String sqlVersamenti = ""
        String sqlVersamentiFiltro = ""
        def filtri = [:]

        if (parametriRicerca.cf) {
            filtri << ['cf': parametriRicerca.cf]
            sqlFiltri += " AND UPPER(CONTRIBUENTI.COD_FISCALE) LIKE UPPER(:cf)"
        }
        if (parametriRicerca.cognome) {
            filtri << ['cognome': parametriRicerca.cognome]
            sqlFiltri += " AND UPPER(SOGGETTI.COGNOME) LIKE UPPER(:cognome)"
        }
        if (parametriRicerca.nome) {
            filtri << ['nome': parametriRicerca.nome]
            sqlFiltri += " AND UPPER(SOGGETTI.NOME) LIKE UPPER(:nome)"
        }
        if (parametriRicerca.numeroIndividuale) {
            filtri << ['numeroIndividuale': parametriRicerca.numeroIndividuale]
            sqlFiltri += " AND SOGGETTI.NI = :numeroIndividuale"
        }
        if (parametriRicerca.codContribuente) {
            filtri << ['codContribuente': parametriRicerca.codContribuente]
            sqlFiltri += " AND CONTRIBUENTI.COD_CONTRIBUENTE = :codContribuente"
        }

        //Stato
        if (!parametriRicerca.tuttiTipiStatoSelezionati) {
            def condizioneStato = ""
            def listaTipi = ""
            def lista = parametriRicerca.tipiStatoSelezionati.collect { t -> t.tipoStato }
            HashSet<String> hs = new HashSet<String>(lista)
            hs.each { tipo ->
                if (!tipo) {
                    condizioneStato += " prtr.stato_accertamento is null "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
            listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
            if (condizioneStato != "" && listaTipi != "") {
                condizioneStato += " or prtr.stato_accertamento in (" + listaTipi + ") "
            }

            if (condizioneStato == "" && listaTipi != "") {
                condizioneStato += " prtr.stato_accertamento in (" + listaTipi + ") "
            }
            sqlFiltri += " ${condizioneStato ? " and ( ${condizioneStato} )" : ""} "
        }

        //Atto
        if (!parametriRicerca.tuttiTipiAttoSelezionati) {
            def condizioneAtto = ""
            def listaTipi = ""
            def lista = parametriRicerca.tipiAttoSelezionati.collect { t -> t.tipoAtto }
            HashSet<String> hs = new HashSet<String>(lista)
            hs.each { tipo ->
                if (!tipo) {
                    condizioneAtto += " prtr.tipo_atto is null "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
			listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
			if (condizioneAtto != "" && listaTipi != "") {
				condizioneAtto += " or  prtr.tipo_atto in (" + listaTipi + ") "
			}

			if (condizioneAtto == "" && listaTipi != "") {
				condizioneAtto += "  prtr.tipo_atto in (" + listaTipi + ") "
			}
			sqlFiltri += " ${condizioneAtto ? " and ( ${condizioneAtto} )" : ""} "
		}

		 // lista stati/tipo atto
		 if (parametriRicerca.statoAttiSelezionati != null) {

             def statoAttiSelezionati = parametriRicerca.statoAttiSelezionati
		 String filtroStatiAtti

		 if (statoAttiSelezionati.size() > 0) {
		 filtroStatiAtti = "'" + statoAttiSelezionati.join("','") + "'"
		 } else {
		 filtroStatiAtti = "'_'"
		 }
		 sqlFiltri += """ and (nvl(prtr.stato_accertamento,'-') || '_' || nvl(prtr.tipo_atto,0)) in(${filtroStatiAtti}) """
		 }

		if (parametriRicerca.daAnno) {
			filtri << ['daAnno': parametriRicerca.daAnno]
			sqlFiltri += " AND PRTR.ANNO(+) >= :daAnno"
			sqlVersamenti += " AND VERSAMENTI.ANNO >= :daAnno"
		}
		if (parametriRicerca.aAnno) {
			filtri << ['aAnno': parametriRicerca.aAnno]
			sqlFiltri += " AND PRTR.ANNO(+) <= :aAnno"
			sqlVersamenti += " AND VERSAMENTI.ANNO <= :aAnno"
        }
        if (parametriRicerca.daData) {
            filtri << ['daData': parametriRicerca.daData.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA >= TO_DATE(:daData, 'dd/mm/yyyy')"
        }
        if (parametriRicerca.aData) {
            filtri << ['aData': parametriRicerca.aData.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA <= TO_DATE(:aData, 'dd/mm/yyyy')"
        }
        if (parametriRicerca.daImporto != null) {
            filtri << ['daImporto': parametriRicerca.daImporto]
            sqlFiltri += " AND NVL(PRTR.IMPORTO_TOTALE, 0) >= :daImporto"
        }
        if (parametriRicerca.aImporto != null) {
            filtri << ['aImporto': parametriRicerca.aImporto]
            sqlFiltri += " AND NVL(PRTR.IMPORTO_TOTALE, 0) <= :aImporto"
        }

        if (parametriRicerca.statoSoggetto) {

            if (parametriRicerca.statoSoggetto == "D") {
                sqlFiltri += " AND SOGGETTI.STATO = 50"
            }
            if (parametriRicerca.statoSoggetto == "ND") {
                sqlFiltri += " AND (SOGGETTI.STATO IS NULL OR SOGGETTI.STATO != 50)"
            }
        }

        // Residente
        if (parametriRicerca?.residente == "S") {
            sqlFiltri += " and (soggetti.tipo_residente = 0 and soggetti.fascia = 1) "
        } else if (parametriRicerca?.residente == "N") {
            sqlFiltri += " and (soggetti.tipo_residente <> 0 and soggetti.fascia <> 1) "
        }

        if (parametriRicerca.daDataPagamento) {
            filtri << ['daDataPagamento': parametriRicerca.daDataPagamento?.format('dd/MM/yyyy') ?: '01/01/1800']
            sqlVersamentiFiltro += " AND VERSAMENTI.DATA_PAGAMENTO >= TO_DATE(:daDataPagamento, 'dd/mm/yyyy')"
        }
        if (parametriRicerca.aDataPagamento) {
            filtri << ['aDataPagamento': parametriRicerca.aDataPagamento?.format('dd/MM/yyyy') ?: '31/12/9999']
            sqlVersamentiFiltro += " AND VERSAMENTI.DATA_PAGAMENTO <= TO_DATE(:aDataPagamento, 'dd/mm/yyyy')"
        }
        if (sqlVersamentiFiltro != '') {
            sqlFiltri += " AND NVL(VERS_COUNT.NUM_VERSAMENTI,0) > 0"
        }

        def daNumero = parametriRicerca?.daNumeroPratica
        def aNumero = parametriRicerca?.aNumeroPratica
        def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
        def isANumeroNotEmpty = aNumero != null && aNumero != ""

        if (isDaNumeroNotEmpty) {
            if (daNumero.contains('%')) {
                sqlFiltri += " and upper(prtr.numero) like :daNumeroPratica "
                filtri << ['daNumeroPratica': daNumero.toUpperCase()]
            } else {
                sqlFiltri += " and lpad(upper(prtr.numero), 15, ' ') >= :daNumeroPratica "
                filtri << ['daNumeroPratica': daNumero.padLeft(15).toUpperCase()]
            }
        }

        if (isANumeroNotEmpty) {
            sqlFiltri += " and lpad(upper(prtr.numero), 15, ' ') <= :aNumeroPratica "
            filtri << ['aNumeroPratica': aNumero.padLeft(15).toUpperCase()]
        }

        if (parametriRicerca.daDataRifRavv) {
            filtri << ['daDataRifRavv': parametriRicerca.daDataRifRavv.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA_RIF_RAVVEDIMENTO >= TO_DATE(:daDataRifRavv, 'dd/mm/yyyy')"
        }
        if (parametriRicerca.aDataRifRavv) {
            filtri << ['aDataRifRavv': parametriRicerca.aDataRifRavv.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA_RIF_RAVVEDIMENTO <= TO_DATE(:aDataRifRavv, 'dd/mm/yyyy')"
        }

        if (parametriRicerca.tipoAtto?.tipoAtto == 90) {

            if (parametriRicerca.tipologiaRate) {
                filtri << ['tipologiaRate': parametriRicerca.tipologiaRate]
                sqlFiltri += " AND NVL(PRTR.TIPOLOGIA_RATE,'N') LIKE :tipologiaRate"
            }
            if (parametriRicerca.daImportoRateizzato) {
                filtri << ['daImportoRateizzato': parametriRicerca.daImportoRateizzato]
                sqlFiltri += " AND (PRTR.IMPORTO_TOTALE + NVL(PRTR.MORA,0) - NVL(PRTR.VERSATO_PRE_RATE,0)) >= :daImportoRateizzato"
            }
            if (parametriRicerca.aImportoRateizzato) {
                filtri << ['aImportoRateizzato': parametriRicerca.aImportoRateizzato]
                sqlFiltri += " AND (PRTR.IMPORTO_TOTALE + NVL(PRTR.MORA,0) - NVL(PRTR.VERSATO_PRE_RATE,0)) <= :aImportoRateizzato"
            }
            if (parametriRicerca.daDataRateazione) {
                filtri << ['daDataRateazione': parametriRicerca.daDataRateazione.format('dd/MM/yyyy')]
                sqlFiltri += " AND NVL(PRTR.DATA_RATEAZIONE,TO_DATE('01011901','ddmmyyyy')) >= TO_DATE(:daDataRateazione, 'dd/mm/yyyy')"
            }
            if (parametriRicerca.aDataRateazione) {
                filtri << ['aDataRateazione': parametriRicerca.aDataRateazione.format('dd/MM/yyyy')]
                sqlFiltri += " AND NVL(PRTR.DATA_RATEAZIONE,TO_DATE('01011901','ddmmyyyy')) <= TO_DATE(:aDataRateazione, 'dd/mm/yyyy')"
            }
        }

        filtri << ['tipoTributo': parametriRicerca.tipoTributo]

        if (parametriRicerca.tipoTributo == 'ICI') {

            sql = """
				SELECT	TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ') COG_NOM,
						SOGGETTI.NI NUM_IND,
                        SOGGETTI.FASCIA FASCIA,
                        SOGGETTI.TIPO_RESIDENTE TIPO_RESIDENTE,
						CONTRIBUENTI.COD_FISCALE COD_FISCALE,
						F_ROUND(PRTR.IMPORTO_RIDOTTO,1) IMPORTO_RIDOTTO,
						PRTR.DATA_NOTIFICA DATA_NOTIFICA,
						TIST.DESCRIZIONE STATO_ACCERTAMENTO,
                        TIAT.TIPO_ATTO   TIPO_ATTO,
                        TIAT.DESCRIZIONE TIPO_ATTO_DESCRIZIONE,
						PRTR.ANNO ANNO,
						LPAD(PRTR.NUMERO, 15) CLNUMERO,
						PRTR.PRATICA,
						PRTR.DATA DATA_LIQ,
					    PRTR.FLAG_DEPAG,
						NVL(VERS.VERSATO,0) IMP_VER,
						F_ROUND(PRTR.IMPOSTA_TOTALE,1) IMP_C,
						F_ROUND(PRTR.IMPORTO_TOTALE,1) IMP_TOT,
		                0 AS IMP_LORDO,
						0 AS IMP_RID_LORDO,
						0 AS IMP_ADD_ECA,
						0 AS IMP_MAG_ECA,
						0 AS IMP_ADD_PRO,
						0 AS IMP_MAG_TARES,
						0 AS IMP_INTERESSI,
						0 AS IMP_SANZIONI,
						0 AS IMP_SANZIONI_RID,
						UPPER(REPLACE(SOGGETTI.COGNOME,' ','')) COGNOME,
						UPPER(REPLACE(SOGGETTI.NOME,' ','')) NOME,
						DECODE(SOGGETTI.COD_VIA,NULL,SOGGETTI.DENOMINAZIONE_VIA,ARCHIVIO_VIE.DENOM_UFF)
							|| DECODE(NUM_CIV,NULL,'', ', '|| NUM_CIV )
							|| DECODE(SUFFISSO,NULL,'', '/'|| SUFFISSO ) INDIRIZZO,
						AD4_COMUNI.DENOMINAZIONE
							|| DECODE(AD4_PROVINCIE.SIGLA,NULL, '', ' (' || AD4_PROVINCIE.SIGLA || ')') COMUNE,
						NVL(SOGGETTI.CAP,AD4_COMUNI.CAP) CAP,
						TO_NUMBER(NVL(DECODE(F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo),0,
							NULL, F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo)),'0')) VERSAMENTI2,
						NVL(VERS_COUNT.NUM_VERSAMENTI,0) AS NUM_VERSAMENTI,
						'' AS TIPO_RAPPORTO,
	                    PRTR.TIPOLOGIA_RATE TIPOLOGIA_RATE,
						PRTR.TIPO_RAVVEDIMENTO TIPO_RAVVEDIMENTO, 
	                    PRTR.IMPORTO_RATE IMPORTO_RATE,
	                    (SELECT NVL(COUNT(*), 0)
							FROM RATE_PRATICA RTPR
							WHERE RTPR.PRATICA = PRTR.PRATICA) NUMERO_RATE,
	                    (SELECT NVL(COUNT(DISTINCT RATA), 0)
							FROM VERSAMENTI VERS
							WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA
								AND VERS.RATA BETWEEN 1 AND PRTR.RATE) RATE_VERSATE,
						decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
                        	decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                               lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "COMUNE_RES_ERR",
                    	f_verifica_cap(soggetti.cod_pro_res,soggetti.cod_com_res,soggetti.cap) "CAP_RES_ERR",
                        PRTR.DATA_RIF_RAVVEDIMENTO DATA_RIF_RAVVEDIMENTO,
                        PRTR.MOTIVO,
                        PRTR.NOTE
				FROM (	SELECT SUM(VERSAMENTI.IMPORTO_VERSATO) VERSATO, VERSAMENTI.PRATICA
							FROM VERSAMENTI
							WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamenti}
							GROUP BY VERSAMENTI.PRATICA
						) VERS,
			            (  SELECT COUNT(VERSAMENTI.IMPORTO_VERSATO) NUM_VERSAMENTI, VERSAMENTI.PRATICA
			              FROM VERSAMENTI
			              WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamentiFiltro}
			              GROUP BY VERSAMENTI.PRATICA
			            ) VERS_COUNT,
						PRATICHE_TRIBUTO PRTR,
						RAPPORTI_TRIBUTO RATR,
						SOGGETTI,
						AD4_COMUNI,
						AD4_PROVINCIE,
						ARCHIVIO_VIE,
					    DATI_GENERALI,
						CONTRIBUENTI,
						TIPI_STATO TIST,
						TIPI_ATTO TIAT
				WHERE ( VERS.PRATICA(+) = PRTR.PRATICA) AND
						( VERS_COUNT.PRATICA(+) = PRTR.PRATICA) AND
						( SOGGETTI.NI = CONTRIBUENTI.NI ) AND
						( SOGGETTI.COD_VIA = ARCHIVIO_VIE.COD_VIA (+)) AND
						( SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO (+)) AND
						( SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE (+)) AND
						( AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA (+)) AND
						( PRTR.PRATICA = RATR.PRATICA ) AND
						( CONTRIBUENTI.COD_FISCALE = RATR.COD_FISCALE ) AND
						PRTR.STATO_ACCERTAMENTO = TIST.TIPO_STATO (+) AND
            			PRTR.TIPO_ATTO = TIAT.TIPO_ATTO (+) AND
						( PRTR.TIPO_TRIBUTO||'' = :tipoTributo ) AND
						( PRTR.TIPO_PRATICA = 'V' )
						${sqlFiltri}
				"""
        }

        if (parametriRicerca.tipoTributo == 'TASI') {

            sql = """
				 SELECT	TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ') COG_NOM,
						SOGGETTI.NI NUM_IND,
                        SOGGETTI.FASCIA FASCIA,
                        SOGGETTI.TIPO_RESIDENTE TIPO_RESIDENTE,
						CONTRIBUENTI.COD_FISCALE COD_FISCALE,
						F_ROUND(PRTR.IMPORTO_RIDOTTO,1) IMPORTO_RIDOTTO,
						PRTR.DATA_NOTIFICA DATA_NOTIFICA,
						TIST.DESCRIZIONE STATO_ACCERTAMENTO,
                        TIAT.TIPO_ATTO   TIPO_ATTO,
                        TIAT.DESCRIZIONE TIPO_ATTO_DESCRIZIONE,
						PRTR.ANNO ANNO,
						LPAD(PRTR.NUMERO, 15) CLNUMERO,
						PRTR.PRATICA,
						PRTR.DATA DATA_LIQ,
					    PRTR.FLAG_DEPAG,
						NVL(VERS.VERSATO,0) IMP_VER,
						F_ROUND(PRTR.IMPOSTA_TOTALE,1) IMP_C,
						F_ROUND(PRTR.IMPORTO_TOTALE,1) IMP_TOT,
		                0 AS IMP_LORDO,
						0 AS IMP_RID_LORDO,
						0 AS IMP_ADD_ECA,
						0 AS IMP_MAG_ECA,
						0 AS IMP_ADD_PRO,
						0 AS IMP_MAG_TARES,
						0 AS IMP_INTERESSI,
						0 AS IMP_SANZIONI,
						0 AS IMP_SANZIONI_RID,
						UPPER(REPLACE(SOGGETTI.COGNOME,' ','')) COGNOME,
						UPPER(REPLACE(SOGGETTI.NOME,' ','')) NOME,
						DECODE(SOGGETTI.COD_VIA,NULL,SOGGETTI.DENOMINAZIONE_VIA,ARCHIVIO_VIE.DENOM_UFF)
							 || DECODE( NUM_CIV,NULL,'', ', ' || NUM_CIV )
							 || DECODE( SUFFISSO,NULL,'', '/' || SUFFISSO ) INDIRIZZO,
						AD4_COMUNI.DENOMINAZIONE
							 || DECODE( AD4_PROVINCIE.SIGLA,NULL, '', ' (' || AD4_PROVINCIE.SIGLA || ')') COMUNE,
						NVL(SOGGETTI.CAP,AD4_COMUNI.CAP) CAP,
						TO_NUMBER(NVL(DECODE(F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo),0,
							 NULL, F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo)),'0')) VERSAMENTI2,
						NVL(VERS_COUNT.NUM_VERSAMENTI,0) AS NUM_VERSAMENTI,
						RATR.TIPO_RAPPORTO TIPO_RAPPORTO,
	                    PRTR.TIPOLOGIA_RATE TIPOLOGIA_RATE,
						PRTR.TIPO_RAVVEDIMENTO TIPO_RAVVEDIMENTO, 
	                    PRTR.IMPORTO_RATE IMPORTO_RATE,
	                    (SELECT NVL(COUNT(*), 0)
							FROM RATE_PRATICA RTPR
							WHERE RTPR.PRATICA = PRTR.PRATICA) NUMERO_RATE,
	                    (SELECT NVL(COUNT(DISTINCT RATA), 0)
							FROM VERSAMENTI VERS
							WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA
								AND VERS.RATA BETWEEN 1 AND PRTR.RATE) RATE_VERSATE,
						decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
							decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                               lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "COMUNE_RES_ERR",
                        f_verifica_cap(soggetti.cod_pro_res,soggetti.cod_com_res,soggetti.cap) "CAP_RES_ERR",
                        PRTR.DATA_RIF_RAVVEDIMENTO DATA_RIF_RAVVEDIMENTO,
                        PRTR.MOTIVO,
                        PRTR.NOTE
				 FROM (	SELECT SUM(VERSAMENTI.IMPORTO_VERSATO) VERSATO, VERSAMENTI.PRATICA
							FROM VERSAMENTI
							WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamenti}
							GROUP BY VERSAMENTI.PRATICA
						) VERS,
			            (  SELECT COUNT(VERSAMENTI.IMPORTO_VERSATO) NUM_VERSAMENTI, VERSAMENTI.PRATICA
			              FROM VERSAMENTI
			              WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamentiFiltro}
			              GROUP BY VERSAMENTI.PRATICA
			            ) VERS_COUNT,
						PRATICHE_TRIBUTO PRTR,
						RAPPORTI_TRIBUTO RATR,
						SOGGETTI,
						AD4_COMUNI,
						AD4_PROVINCIE,
						DATI_GENERALI,
						ARCHIVIO_VIE,
						CONTRIBUENTI,
						TIPI_STATO TIST,
						TIPI_ATTO TIAT
				 WHERE	( VERS.PRATICA(+) = PRTR.PRATICA) AND
						( VERS_COUNT.PRATICA(+) = PRTR.PRATICA) AND
						( SOGGETTI.NI = CONTRIBUENTI.NI ) AND
						( SOGGETTI.COD_VIA = ARCHIVIO_VIE.COD_VIA (+)) AND
						( SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO (+)) AND
						( SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE (+)) AND
						( AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA (+)) AND
						( PRTR.PRATICA = RATR.PRATICA ) AND
						( CONTRIBUENTI.COD_FISCALE	= RATR.COD_FISCALE ) AND
						PRTR.STATO_ACCERTAMENTO = TIST.TIPO_STATO (+) AND
            			PRTR.TIPO_ATTO = TIAT.TIPO_ATTO (+) AND
						( PRTR.TIPO_TRIBUTO||'' = :tipoTributo ) AND
						( PRTR.TIPO_PRATICA = 'V' )
						${sqlFiltri}
				 """
        }

        if (parametriRicerca.tipoTributo == 'TARSU') {

            sql = """
				SELECT	TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ') COG_NOM,
						SOGGETTI.NI NUM_IND,
                        SOGGETTI.FASCIA FASCIA,
                        SOGGETTI.TIPO_RESIDENTE TIPO_RESIDENTE,
						CONTRIBUENTI.COD_FISCALE COD_FISCALE,
						F_ROUND(PRTR.IMPORTO_RIDOTTO,1) IMPORTO_RIDOTTO,
						PRTR.DATA_NOTIFICA DATA_NOTIFICA,
						TIST.DESCRIZIONE STATO_ACCERTAMENTO,
                        TIAT.TIPO_ATTO   TIPO_ATTO,
                        TIAT.DESCRIZIONE TIPO_ATTO_DESCRIZIONE,
						PRTR.ANNO ANNO,
						LPAD(PRTR.NUMERO, 15) CLNUMERO,
						PRTR.PRATICA,
						PRTR.DATA DATA_LIQ,
					    PRTR.FLAG_DEPAG,
						NVL(VERS.VERSATO,0) IMP_VER,
						-- Ravvedimento da sportello per mancati versamenti su Ruoli
						CASE WHEN PRTR.TIPO_RAVVEDIMENTO = 'D' AND PRTR.TIPO_EVENTO = '0' THEN
							F_IMPORTI_ACC(PRTR.PRATICA,'N','TASSA_EVASA_TOTALE')
						ELSE
							F_ROUND(PRTR.IMPOSTA_TOTALE,1)
						END AS IMP_C,
						F_ROUND(PRTR.IMPORTO_TOTALE,1) IMP_TOT,
		                f_importo_acc_lordo(PRTR.PRATICA, 'N') IMP_LORDO,
						f_importo_acc_lordo(PRTR.PRATICA, 'S') IMP_RID_LORDO,
		                f_importi_acc(PRTR.PRATICA, 'N', 'ADD_ECA') IMP_ADD_ECA,
		                f_importi_acc(PRTR.PRATICA, 'N', 'MAG_ECA') IMP_MAG_ECA,
		                f_importi_acc(PRTR.PRATICA, 'N', 'ADD_PRO') IMP_ADD_PRO,
		                f_importi_acc(PRTR.PRATICA, 'N', 'MAGGIORAZIONE') IMP_MAG_TARES,
		                f_importi_acc(PRTR.PRATICA, 'N', 'INTERESSI') IMP_INTERESSI,
		                f_importi_acc(PRTR.PRATICA, 'N', 'SANZIONI') IMP_SANZIONI,
		                f_importi_acc(PRTR.PRATICA, 'S', 'SANZIONI') IMP_SANZIONI_RID,
						UPPER(REPLACE(SOGGETTI.COGNOME,' ','')) COGNOME,
						UPPER(REPLACE(SOGGETTI.NOME,' ','')) NOME,
						DECODE(SOGGETTI.COD_VIA,NULL,SOGGETTI.DENOMINAZIONE_VIA,ARCHIVIO_VIE.DENOM_UFF)
							 || DECODE( NUM_CIV,NULL,'', ', ' || NUM_CIV )
							 || DECODE( SUFFISSO,NULL,'', '/' || SUFFISSO ) INDIRIZZO,
						AD4_COMUNI.DENOMINAZIONE
							 || DECODE( AD4_PROVINCIE.SIGLA,NULL, '', ' (' || AD4_PROVINCIE.SIGLA || ')') COMUNE,
						NVL(SOGGETTI.CAP,AD4_COMUNI.CAP) CAP,
						TO_NUMBER(NVL(DECODE(F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo),0,
							 NULL, F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo)),'0')) VERSAMENTI2,
						NVL(VERS_COUNT.NUM_VERSAMENTI,0) AS NUM_VERSAMENTI,
						RATR.TIPO_RAPPORTO TIPO_RAPPORTO,
	                    PRTR.TIPOLOGIA_RATE TIPOLOGIA_RATE,
						PRTR.TIPO_RAVVEDIMENTO TIPO_RAVVEDIMENTO, 
	                    PRTR.IMPORTO_RATE IMPORTO_RATE,
	                    (SELECT NVL(COUNT(*), 0)
							FROM RATE_PRATICA RTPR
							WHERE RTPR.PRATICA = PRTR.PRATICA) NUMERO_RATE,
	                    (SELECT NVL(COUNT(DISTINCT RATA), 0)
							FROM VERSAMENTI VERS
							WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA
								AND VERS.RATA BETWEEN 1 AND PRTR.RATE) RATE_VERSATE,
						decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
                        	decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                               lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "COMUNE_RES_ERR",
                        f_verifica_cap(soggetti.cod_pro_res,soggetti.cod_com_res,soggetti.cap) "CAP_RES_ERR",
                        PRTR.DATA_RIF_RAVVEDIMENTO DATA_RIF_RAVVEDIMENTO,
                        PRTR.MOTIVO,
                        PRTR.NOTE
				FROM (	SELECT SUM(VERSAMENTI.IMPORTO_VERSATO) VERSATO, VERSAMENTI.PRATICA
							FROM VERSAMENTI
							WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamenti}
							GROUP BY VERSAMENTI.PRATICA
						) VERS,
			            (  SELECT COUNT(VERSAMENTI.IMPORTO_VERSATO) NUM_VERSAMENTI, VERSAMENTI.PRATICA
			              FROM VERSAMENTI
			              WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamentiFiltro}
			              GROUP BY VERSAMENTI.PRATICA
			            ) VERS_COUNT,
						PRATICHE_TRIBUTO PRTR,
						RAPPORTI_TRIBUTO RATR,
						SOGGETTI,
						AD4_COMUNI,
						AD4_PROVINCIE,
						ARCHIVIO_VIE,
					    DATI_GENERALI,
						CONTRIBUENTI,
						TIPI_STATO TIST,
						TIPI_ATTO TIAT
				WHERE	( VERS.PRATICA(+) = PRTR.PRATICA) AND
						( VERS_COUNT.PRATICA(+) = PRTR.PRATICA) AND
						( SOGGETTI.NI = CONTRIBUENTI.NI ) AND
						( SOGGETTI.COD_VIA = ARCHIVIO_VIE.COD_VIA (+)) AND
						( SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO (+)) AND
						( SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE (+)) AND
						( AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA (+)) AND
						( PRTR.PRATICA = RATR.PRATICA ) AND
						( CONTRIBUENTI.COD_FISCALE	= RATR.COD_FISCALE ) AND
						PRTR.STATO_ACCERTAMENTO = TIST.TIPO_STATO (+) AND
            			PRTR.TIPO_ATTO = TIAT.TIPO_ATTO (+) AND
						( PRTR.TIPO_TRIBUTO||'' = :tipoTributo ) AND
						( PRTR.TIPO_PRATICA = 'V' )
						${sqlFiltri}
				"""
        }

        if (parametriRicerca.tipoTributo == 'CUNI') {

            sql = """
				SELECT	TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ') COG_NOM,
						SOGGETTI.NI NUM_IND,
                        SOGGETTI.FASCIA FASCIA,
                        SOGGETTI.TIPO_RESIDENTE TIPO_RESIDENTE,
						CONTRIBUENTI.COD_FISCALE COD_FISCALE,
						F_ROUND(PRTR.IMPORTO_RIDOTTO,1) IMPORTO_RIDOTTO,
						PRTR.DATA_NOTIFICA DATA_NOTIFICA,
						TIST.DESCRIZIONE STATO_ACCERTAMENTO,
                        TIAT.TIPO_ATTO   TIPO_ATTO,
            			TIAT.DESCRIZIONE TIPO_ATTO_DESCRIZIONE,
						PRTR.ANNO ANNO,
						PRTR.TIPO_EVENTO,
						LPAD(PRTR.NUMERO, 15) CLNUMERO,
						PRTR.PRATICA,
						PRTR.DATA DATA_LIQ,
					    PRTR.FLAG_DEPAG,
						NVL(VERS.VERSATO,0) IMP_VER,
						F_ROUND(PRTR.IMPOSTA_TOTALE,1) IMP_C,
						F_ROUND(PRTR.IMPORTO_TOTALE,1) IMP_TOT,
		                0 AS IMP_LORDO,
						0 AS IMP_RID_LORDO,
						0 AS IMP_ADD_ECA,
						0 AS IMP_MAG_ECA,
						0 AS IMP_ADD_PRO,
						0 AS IMP_MAG_TARES,
						0 AS IMP_INTERESSI,
						0 AS IMP_SANZIONI,
						0 AS IMP_SANZIONI_RID,
						UPPER(REPLACE(SOGGETTI.COGNOME,' ','')) COGNOME,
						UPPER(REPLACE(SOGGETTI.NOME,' ','')) NOME,
						DECODE(SOGGETTI.COD_VIA,NULL,SOGGETTI.DENOMINAZIONE_VIA,ARCHIVIO_VIE.DENOM_UFF)
							 || DECODE( NUM_CIV,NULL,'', ', ' || NUM_CIV )
							 || DECODE( SUFFISSO,NULL,'', '/' || SUFFISSO ) INDIRIZZO,
						AD4_COMUNI.DENOMINAZIONE
							 || DECODE( AD4_PROVINCIE.SIGLA,NULL, '', ' (' || AD4_PROVINCIE.SIGLA || ')') COMUNE,
						NVL(SOGGETTI.CAP,AD4_COMUNI.CAP) CAP,
						TO_NUMBER(NVL(DECODE(F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo),0,
							 NULL, F_VERS_CONT(PRTR.ANNO,CONTRIBUENTI.COD_FISCALE,NULL,NULL,NULL,:tipoTributo)),'0')) VERSAMENTI2,
						NVL(VERS_COUNT.NUM_VERSAMENTI,0) AS NUM_VERSAMENTI,
						RATR.TIPO_RAPPORTO TIPO_RAPPORTO,
	                    PRTR.TIPOLOGIA_RATE TIPOLOGIA_RATE,
						PRTR.TIPO_RAVVEDIMENTO TIPO_RAVVEDIMENTO, 
	                    PRTR.IMPORTO_RATE IMPORTO_RATE,
	                    (SELECT NVL(COUNT(*), 0)
							FROM RATE_PRATICA RTPR
							WHERE RTPR.PRATICA = PRTR.PRATICA) NUMERO_RATE,
	                    (SELECT NVL(COUNT(DISTINCT RATA), 0)
							FROM VERSAMENTI VERS
							WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA
								AND VERS.RATA BETWEEN 1 AND PRTR.RATE) RATE_VERSATE,
					    decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
							decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                               lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "COMUNE_RES_ERR",
                        PRTR.DATA_RIF_RAVVEDIMENTO DATA_RIF_RAVVEDIMENTO,
                        PRTR.MOTIVO,
                        PRTR.NOTE
				FROM (	SELECT SUM(VERSAMENTI.IMPORTO_VERSATO) VERSATO, VERSAMENTI.PRATICA
							FROM VERSAMENTI
							WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamenti}
							GROUP BY VERSAMENTI.PRATICA
						) VERS,
			            (  SELECT COUNT(VERSAMENTI.IMPORTO_VERSATO) NUM_VERSAMENTI, VERSAMENTI.PRATICA
			              FROM VERSAMENTI
			              WHERE VERSAMENTI.TIPO_TRIBUTO = :tipoTributo AND VERSAMENTI.PRATICA IS NOT NULL
							${sqlVersamentiFiltro}
			              GROUP BY VERSAMENTI.PRATICA
			            ) VERS_COUNT,
						PRATICHE_TRIBUTO PRTR,
						RAPPORTI_TRIBUTO RATR,
						SOGGETTI,
						AD4_COMUNI,
						AD4_PROVINCIE,
				        DATI_GENERALI,
						ARCHIVIO_VIE,
						CONTRIBUENTI,
						TIPI_STATO TIST,
						TIPI_ATTO TIAT
				WHERE	( VERS.PRATICA(+) = PRTR.PRATICA) AND
						( VERS_COUNT.PRATICA(+) = PRTR.PRATICA) AND
						( SOGGETTI.NI = CONTRIBUENTI.NI ) AND
						( SOGGETTI.COD_VIA = ARCHIVIO_VIE.COD_VIA (+)) AND
						( SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO (+)) AND
						( SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE (+)) AND
						( AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA (+)) AND
						( PRTR.PRATICA = RATR.PRATICA ) AND
						( CONTRIBUENTI.COD_FISCALE	= RATR.COD_FISCALE ) AND
						PRTR.STATO_ACCERTAMENTO = TIST.TIPO_STATO (+) AND
            			PRTR.TIPO_ATTO = TIAT.TIPO_ATTO (+) AND
						( PRTR.TIPO_TRIBUTO||'' = :tipoTributo ) AND
						( PRTR.TIPO_PRATICA = 'V' )
						${sqlFiltri}
				"""
        }

        sqlTotali = """
				SELECT	COUNT(*) AS TOT_COUNT,
						SUM(IMP_VER) AS TOT_IMP_VER,
						SUM(IMP_C) AS TOT_IMP_C,
						SUM(IMP_TOT) AS TOT_IMP_TOT,
						SUM(IMPORTO_RIDOTTO) AS TOT_IMP_RID,
						SUM(IMP_LORDO) AS TOT_IMP_LORDO,
						SUM(IMP_RID_LORDO) AS TOT_IMP_RID_LORDO,
						SUM(IMP_ADD_ECA) AS TOT_IMP_ADD_ECA,
						SUM(IMP_MAG_ECA) AS TOT_IMP_MAG_ECA,
						SUM(IMP_ADD_PRO) AS TOT_IMP_ADD_PRO,
						SUM(IMP_MAG_TARES) AS TOT_IMP_MAG_TARES,
						SUM(IMP_INTERESSI) AS TOT_IMP_INTERESSI,
						SUM(IMP_SANZIONI) AS TOT_IMP_SANZIONI,
						SUM(IMP_SANZIONI_RID) AS TOT_IMP_SANZIONI_RID,
						SUM(VERSAMENTI2) AS VERSAMENTI2
				FROM ($sql)
				"""

        int totalCount = 0
        int pageCount = 0

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        // Solo ID, restituisce solo i dati minimali dei Ravvedimenti
        if (onlyIDs) {

            def idsList = eseguiQuery("$sql", filtri, params)
                    .collect {
                        [
                                id        : it.PRATICA as Integer,
                                impTotNum : it.IMP_TOT,
                                clNumero  : it.CLNUMERO,
                                codFiscale: it.COD_FISCALE
                        ]
                    }

            return idsList
        }

        def totali = eseguiQuery("${sqlTotali}", filtri, params, true)[0]

        def totals = [
                totalCount     : totali.TOT_COUNT,
                impCalcolata   : (totali.TOT_IMP_C != null) ? totali.TOT_IMP_C : 0,
                impRavvedimenti: (totali.TOT_IMP_TOT != null) ? totali.TOT_IMP_TOT : 0,
                impRidotto     : (totali.TOT_IMP_RID != null) ? totali.TOT_IMP_RID : 0,
                impVersato     : (totali.TOT_IMP_VER != null) ? totali.TOT_IMP_VER : 0,
				impLordo       : (totali.TOT_IMP_LORDO != null) ? totali.TOT_IMP_LORDO : 0,
				impRidLordo    : (totali.TOT_IMP_RID_LORDO != null) ? totali.TOT_IMP_RID_LORDO : 0,
				impAddECA	   : (totali.TOT_IMP_ADD_ECA != null) ? totali.TOT_IMP_ADD_ECA : 0,
				impMagECA  	   : (totali.TOT_IMP_MAG_ECA != null) ? totali.TOT_IMP_MAG_ECA : 0,
				impAddPro 	   : (totali.TOT_IMP_ADD_PRO != null) ? totali.TOT_IMP_ADD_PRO : 0,
				impMagTARES    : (totali.TOT_IMP_MAG_TARES != null) ? totali.TOT_IMP_MAG_TARES : 0,
				impInteressi   : (totali.TOT_IMP_INTERESSI != null) ? totali.TOT_IMP_INTERESSI : 0,
				impSanzioni    : (totali.TOT_IMP_SANZIONI != null) ? totali.TOT_IMP_SANZIONI : 0,
				impSanzioniRid : (totali.TOT_IMP_SANZIONI_RID != null) ? totali.TOT_IMP_SANZIONI_RID : 0,
                impVersamenti  : (totali.VERSAMENTI2 != null) ? totali.VERSAMENTI2 : 0
        ]

        def results = eseguiQuery("${sql} ${sortBySql}", filtri, params)

        def records = []

        results.each {

            def record = [:]

            record.impTotNum = it['IMP_TOT']        // Per documenti, forse vanno cambiati altri valori ?

            record.pratica = it['PRATICA'] as Integer
            record.cognomeNome = it['COG_NOM']
            record.codFiscale = it['COD_FISCALE']
            record.clNumero = it['CLNUMERO']
            record.anno = it['ANNO']
            record.dataRavv = it['DATA_LIQ']?.format("dd/MM/yyyy")
            record.dataNotifica = it['DATA_NOTIFICA']?.format("dd/MM/yyyy")
            record.numInd = it['NUM_IND']
            record.stato = it['STATO_ACCERTAMENTO']
            record.tipoAtto = it['TIPO_ATTO'] ? "${it['TIPO_ATTO']} - ${it['TIPO_ATTO_DESCRIZIONE']}" : null
            record.tipoRavvedimento = it['TIPO_RAVVEDIMENTO'] as String

            record.impCalcolata = it['IMP_C']
            record.impRavved = it['IMP_TOT']
            record.impRidotto = it['IMPORTO_RIDOTTO']
			
			record.impLordo = it['IMP_LORDO']
			record.impRidLordo = it['IMP_RID_LORDO']
			
			record.impAddECA = it['IMP_ADD_ECA']
			record.impMagECA = it['IMP_MAG_ECA']
			record.impAddPro = it['IMP_ADD_PRO']
			record.impMagTARES = it['IMP_MAG_TARES']
			record.impInteressi = it['IMP_INTERESSI']
			record.impSanzioni = it['IMP_SANZIONI']
			record.impSanzioniRid = it['IMP_SANZIONI_RID']
			
            record.cognome = it['COGNOME']
            record.nome = it['NOME']

            record.impVersato = it['IMP_VER']
            record.impVersamenti = it['VERSAMENTI2']

            record.resIndirizzo = it['INDIRIZZO']
            record.resCAP = it['CAP']
            record.resComune = it['COMUNE']

            record.tipoRapp = it['TIPO_RAPPORTO']

            record.tipoEvento = it['TIPO_EVENTO']
            record.flagDePag = it['FLAG_DEPAG']

            record.capResErr = it['CAP_RES_ERR']
            record.comuneResErr = it['COMUNE_RES_ERR']

            record.capResErr = it['CAP_RES_ERR']
            record.comuneResErr = it['COMUNE_RES_ERR']

            record.isResidente = (it['FASCIA'] == 1 && it['TIPO_RESIDENTE'] == 0)

            record.dataRiferimentoRavvedimento = it['DATA_RIF_RAVVEDIMENTO']?.format("dd/MM/yyyy")

            record.note = it['NOTE']
            record.motivo = it['MOTIVO']

            if (parametriRicerca.tipoTributo == 'TARSU') {
                record.impCalcolataNote = 'Di cui : \n' +
                        'Imposta ' + valuta.format(record.impCalcolata - record.impMagTARES) + '\n' +
                        'C.Pereq. ' + valuta.format(record.impMagTARES)
            }

            records << record
        }

        return [totalCount: totals.totalCount, totals: totals, records: records]
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




