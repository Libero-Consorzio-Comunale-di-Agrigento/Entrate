package it.finmatica.tr4.tributiminori

import document.FileNameGenerator
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.RapportoTributo
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import it.finmatica.tr4.versamenti.VersamentiService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.FetchMode
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer

import java.math.RoundingMode
import java.text.DecimalFormat

@Transactional
class CanoneUnicoService {

    private static Log logger = LogFactory.getLog(CanoneUnicoService)

    static transactional = false

    def dataSource

    def sessionFactory

    def springSecurityService
    CommonService commonService

	ContribuentiService contribuentiService
    DenunceService denunceService
    OggettiService oggettiService
    VersamentiService versamentiService
    IntegrazioneDePagService integrazioneDePagService

    List<TipoOccupazione> listaTipiOccupazione = [TipoOccupazione.P, TipoOccupazione.T]

    public static final Integer STATO_CONONE_NORMALE = 0
    public static final Integer STATO_CONONE_ANNOCORRENTE = 1
    public static final Integer STATO_CONONE_BONIFICATO = 2
    public static final Integer STATO_CONONE_ANOMALO = 3
    public static final String TARIFFA_FORMAT_PATTERN = "###,##0.00000"
    public static final String RIDUZIONE_FORMAT_PATTERN = "##0.00"

    private final def CUNI_CONV = "CUNI_CONV"

    // Legge flag abilitazione Conversione
    def conversioneAbilitata() {

        def conversioniCUNI = OggettiCache.INSTALLAZIONE_PARAMETRI.valore
                .find { it.parametro == CUNI_CONV }
        return (conversioniCUNI != null && conversioniCUNI.valore == 'S')
    }

    // Crea elenco annualità Canone Unico
    def getElencoAnni(Integer offsetStart = 0, Integer offsetStop = 0, Integer annoMinimo = 0) {

        Short annoFinale = Calendar.getInstance().get(Calendar.YEAR) + Math.abs(offsetStart) as Short
        Short annoIniziale = annoFinale - Math.abs(offsetStop) as Short
        if (annoIniziale > 2021) {
            annoIniziale = 2021 as Short
        }
        if (annoIniziale < annoMinimo) {
            annoIniziale = annoMinimo as Short
        }

        def listaAnni = []

        for (def anno = annoFinale; anno >= annoIniziale; anno--) {
            listaAnni << anno.toString()
        }

        return listaAnni
    }

    def ricavaContribuente(String codFiscale) {
		
		return contribuentiService.ricavaContribuente(codFiscale)
    }
	
    def creaContribuente(SoggettoDTO soggetto) {

		return contribuentiService.creaContribuente(soggetto)
    }

    // Ricava Check Tributi da tipo tributo
    def getCheckTributi(String tipoTributo) {

        def cbTributi = [
                'ICP'  : (tipoTributo == 'ICP'),
                'TOSAP': (tipoTributo == 'TOSAP'),
                'CUNI' : (tipoTributo == 'CUNI')
        ]

        return cbTributi
    }

    // Elenco contribuenti ICP e/o TOSAP
    def getContribuenti(def parametriRicerca, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

        String sql = ""
        String sqlTotali = ""
        String sqlFiltri = ""

        def filtri = [:]

        if (parametriRicerca.id) {
            filtri << ['idSoggetto': parametriRicerca.id]
            sqlFiltri += "AND NVL(SOGG.NI,0) = :idSoggetto "
        }
        if (parametriRicerca.cognomeNome) {
            filtri << ['cognomeNome': parametriRicerca.cognomeNome.trim().toUpperCase()]
            sqlFiltri += "AND SOGG.COGNOME_NOME_RIC LIKE(:cognomeNome) "
        }
        if (parametriRicerca.cognome) {
            filtri << ['cognome': parametriRicerca.cognome.trim().toUpperCase()]
            sqlFiltri += "AND DECODE(SOGG.TIPO,1,SOGG.COGNOME_NOME_RIC,SOGG.COGNOME_RIC) LIKE(:cognome) "
        }
        if (parametriRicerca.nome) {
            filtri << ['nome': parametriRicerca.nome.trim().toUpperCase()]
            sqlFiltri += "AND SOGG.NOME_RIC LIKE(:nome) "
        }
        if (parametriRicerca.codFiscale) {
            filtri << ['codFiscale': parametriRicerca.codFiscale.trim().toUpperCase()]
            sqlFiltri += "AND CONTR.COD_FISCALE LIKE(:codFiscale) "
        }
        if (parametriRicerca.indirizzo) {
            filtri << ['indirizzo': parametriRicerca.indirizzo.trim()]
            sqlFiltri += "AND (DECODE(SOGG.COD_VIA,NULL,SOGG.DENOMINAZIONE_VIA,AVIE.DENOM_UFF) || " +
                    "DECODE(SOGG.NUM_CIV, NULL, '', ', ' || SOGG.NUM_CIV) || " +
                    "DECODE(SOGG.SUFFISSO, NULL, '', '/' || SOGG.SUFFISSO)) LIKE(:indirizzo) "
        }
        if (parametriRicerca.contribuenteCU == 1) {
            sqlFiltri += "AND PRTR.TIPO_TRIBUTO IN ('ICP','TOSAP','CUNI') "
        }

        sql = """
				SELECT DISTINCT
					SOGG.NI,
					SOGG.COGNOME_NOME,
					CONTR.COD_FISCALE,
					SOGG.PARTITA_IVA,
					DECODE(SOGG.COD_VIA,NULL,SOGG.DENOMINAZIONE_VIA,AVIE.DENOM_UFF) ||
									DECODE(SOGG.NUM_CIV, NULL, '', ', ' || SOGG.NUM_CIV) ||
											DECODE(SOGG.SUFFISSO, NULL, '', '/' || SOGG.SUFFISSO) INDIRIZZO,
					COMU.DENOMINAZIONE AS COMUNE_RESIDENZA,
					TRANSLATE(SOGG.COGNOME_NOME, '/',' ') COG_NOM,
					UPPER(REPLACE(SOGG.COGNOME,' ','')) COGNOME,
					UPPER(REPLACE(SOGG.NOME,' ','')) NOME
				FROM
					PRATICHE_TRIBUTO PRTR,
					SOGGETTI SOGG,
					CONTRIBUENTI CONTR,
					ARCHIVIO_VIE AVIE,
					AD4_COMUNI COMU,
					AD4_PROVINCIE PROV
				WHERE
					CONTR.NI = SOGG.NI AND
					CONTR.COD_FISCALE = PRTR.COD_FISCALE (+) AND
					COMU.PROVINCIA_STATO = PROV.PROVINCIA (+) AND
					SOGG.COD_PRO_RES = COMU.PROVINCIA_STATO (+) AND
					SOGG.COD_COM_RES = COMU.COMUNE (+) AND
					SOGG.COD_VIA = AVIE.COD_VIA (+) AND	
					NVL(PRTR.TIPO_PRATICA,'D') IN ('D','V','A','L')
					${sqlFiltri}
				ORDER BY
					UPPER(REPLACE(SOGG.COGNOME,' ','')) ASC,
					UPPER(REPLACE(SOGG.NOME,' ','')) ASC,
					CONTR.COD_FISCALE ASC
		"""

        sqlTotali = """
				SELECT
					COUNT(*) AS TOT_COUNT
				FROM ($sql)
		"""

        int totalCount = 0

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

        results.each {

            def record = [:]

            record.id = it['NI']

            record.cognomeNome = it['COGNOME_NOME']
            record.codFiscale = it['COD_FISCALE']
            record.partitaIva = it['PARTITA_IVA']
            record.indirizzo = it['INDIRIZZO']
            record.comuneResidenza = it['COMUNE_RESIDENZA']

            records << record
        }

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    // Sistema elenco imposte contribuente per Canone Unico
    def fixupImposteContribuente(def listaTotale, def conta) {

        def listaCUNI = listaTotale.findAll {
            (it.tipoTributo in ['ICP', 'TOSAP', 'CUNI']) && (it.anno >= 2021)
        }

        def listaFinale = listaTotale.findAll {
            !(it.tipoTributo in ['ICP', 'TOSAP']) || (it.anno < 2021)
        }

        def anni = []

        listaCUNI.each {
            def anno = it.anno
            if (anni.find { it == anno } == null) {
                anni << anno
            }
        }

        anni.each {

            def anno = it
            def listaAnno = listaCUNI.findAll { it.anno == anno }

            def elementoCUNI = listaAnno[0]

            elementoCUNI.tipoTributo = 'CUNI'
            elementoCUNI.descrTipoTributo = 'CUNI'

            if (conta == false) {

                elementoCUNI.imposta = listaAnno.sum { it.imposta }
                elementoCUNI.impostaAcconto = listaAnno.sum { it.impostaAcconto }
                elementoCUNI.impostaErariale = listaAnno.sum { it.impostaErariale }
                elementoCUNI.impostaMini = listaAnno.sum { it.impostaMini }
                elementoCUNI.maggiorazioneTares = listaAnno.sum { it.maggiorazioneTares }
                elementoCUNI.addPro = listaAnno.sum { it.addPro }
                elementoCUNI.addMaggEca = listaAnno.sum { it.addMaggEca }
                elementoCUNI.iva = listaAnno.sum { it.iva }
                elementoCUNI.versato = listaAnno.sum { it.versato }
            }

            listaFinale.add(elementoCUNI)
        }

        listaFinale.sort { a, b ->
            b.anno <=> a.anno ?: a.tipoTributo <=> b.tipoTributo
        }

        return listaFinale
    }

    // Estrae elenco concessioni da pratica, ignorando data decorrnza e cessazione
    def getConcessioniDaPratica(String tipoTributo, Long praticaId, def count = false) {

        def cbTributi = getCheckTributi(tipoTributo)

        def filtriRicerca = [
                tipiTributo   : cbTributi,
                pratica       : praticaId,
                ignoraValidita: true,
                skipTemaFlag  : true
        ]

        return getConcessioniContribuente(filtriRicerca, count)
    }

    // Estrae elenco concessioni da dichiarazione
    def getConcessioniDichiarazione(String tipoTributo, Long dichiarazioneId, def count = false) {

        def cbTributi = getCheckTributi(tipoTributo)

        def filtriRicerca = [
                tipiTributo : cbTributi,
                pratica     : dichiarazioneId,
                skipTemaFlag: true
        ]

        return getConcessioniContribuente(filtriRicerca, count)
    }

    // Estrae elenco concessioni chiuse da CF
    def getConcessioniCessate(String cf, Long praticaDestinazione, String tipoTributo, def count = false) {

        def cbTributi = getCheckTributi(tipoTributo)

        PraticaTributo praticaRaw = PraticaTributo.get(praticaDestinazione)
        String tipoEvento = praticaRaw?.tipoEvento?.tipoEventoDenuncia

        def filtriRicerca = [
                tipiTributo    : cbTributi,
                codFiscale     : cf,
                pratica        : null,
                praticaEsclusa : praticaDestinazione,
                anno           : null,
                tipoOccupazione: (tipoEvento == TipoEventoDenuncia.U.tipoEventoDenuncia) ? TipoOccupazione.T.id : TipoOccupazione.P.id,
                ignoraValidita : false,
                soloCessati    : true,
                skipTemaFlag   : true
        ]

        return getConcessioniContribuente(filtriRicerca, count)
    }

    // Estrae elenco concessioni variate
    def getConcessioniVariazioneCessazione(String cf, Long praticaDestinazione, String tipoTributo, TipoEventoDenuncia te = null, def count = false) {

        def cbTributi = getCheckTributi(tipoTributo)

        TipoEventoDenuncia tipoEvento = PraticaTributo.get(praticaDestinazione)?.tipoEvento ?: te

        if (tipoEvento == null) {
            throw new RuntimeException("Indicare l'id della pratica o il tipo evento")
        }

        def filtriRicerca = [
                tipiTributo    : cbTributi,
                codFiscale     : cf,
                pratica        : null,
                praticaEsclusa : praticaDestinazione,
                anno           : null,
                tipoOccupazione: (tipoEvento.tipoEventoDenuncia == TipoEventoDenuncia.U.tipoEventoDenuncia) ? TipoOccupazione.T.id : TipoOccupazione.P.id,
                ignoraValidita : false,
                soloCessati    : true,
                skipTemaFlag   : true
        ]

        return getConcessioniContribuente(filtriRicerca, count)
    }

    // Estrae elenco concessioni da CF e anno
    def getConcessioniContribuente(def filtriRicerca, def count = false) {

        def anno = filtriRicerca.anno
        def perDateValidita = filtriRicerca.perDateValidita ?: false

        def tipiTributo = filtriRicerca.tipiTributo
        def tipiPratiche = filtriRicerca.tipiPratiche
        def tipoOccupazione = filtriRicerca.tipoOccupazione

        def codiciTributo = filtriRicerca.codiciTributo ?: []
        def tipiTariffa = filtriRicerca.tipiTariffa ?: []

        def pratica = filtriRicerca.pratica
        def oggettoRif = filtriRicerca.oggettoRif
        def dataRif = filtriRicerca.dataRif

        def statoOccupazione = filtriRicerca.statoOccupazione

        // Se true evita di fare il merge Pubblicita' / Occupazione per lo stesso oggetto+data
        def skipMerge = filtriRicerca.skipMerge ?: false
        // Se true evita di assegnare la tipologia in base ad anno e tipo occupazione
        def skipTemaFlag = filtriRicerca.skipTemaFlag ?: false
        // Se true evita di cercare in depag i dati relativi allo iuv
        def skipDepagFlag = filtriRicerca.skipDepagFlag ?: false
        // Se true ignora la join con OGGETI_VALIDITA che restituisce i dati solo per tipoPratica 'D' e 'A'
        def ignoraValidita = filtriRicerca.ignoraValidita ?: false
        // Se true prende solo quelli cessati
        def soloCessati = filtriRicerca.soloCessati ?: false

        String sql = ""
        String sqlFiltri = ""

        String tipoTributoFiltro = 'CUNI'
        def filtroTipi = []

        if (tipiTributo != null) {

            if (tipiTributo.ICP) filtroTipi << 'ICP'
            if (tipiTributo.TOSAP) filtroTipi << 'TOSAP'

            if (tipiTributo.CUNI) {
                filtroTipi << 'ICP'
                filtroTipi << 'TOSAP'
                filtroTipi << tipoTributoFiltro
            }
        }

        if (filtroTipi.size() == 0) {
            return []                    // Elenco sempre vuoto se non ICP, TOSDAP o CUNI
        }

        def filtri = [:]

        if (filtriRicerca.codFiscale) {
            filtri << ['codFiscale': filtriRicerca.codFiscale.trim().toUpperCase()]
            sqlFiltri += "AND OGCR.COD_FISCALE LIKE (:codFiscale) "
        }
        if (filtriRicerca.codContribuente) {
            filtri << ['codContribuente': filtriRicerca.codContribuente]
            sqlFiltri += "AND CONT.COD_CONTRIBUENTE = :codContribuente "
        }
        if (filtriRicerca.cognome) {
            filtri << ['cognome': filtriRicerca.cognome.trim().toUpperCase()]
            sqlFiltri += "AND DECODE(SOGG.TIPO,1,SOGG.COGNOME_NOME_RIC,SOGG.COGNOME_RIC) LIKE(:cognome) "
        }
        if (filtriRicerca.nome) {
            filtri << ['nome': filtriRicerca.nome.trim().toUpperCase()]
            sqlFiltri += "AND SOGG.NOME_RIC LIKE(:nome) "
        }

        if (pratica != null) {
            filtri << ['pratica': pratica as Long]
            sqlFiltri += "AND PRTR.PRATICA = :pratica "
        }
        if ((anno != null) && (anno != "Tutti")) {
            filtri << ['anno': anno as Integer]
            if (perDateValidita) {
				/// #69834 : non vogliamo gli oggetti che Iniziano il 31/12 dell'anno richiesto, quindi si mette 3012
                sqlFiltri += "AND NVL(OGVA.DAL,TO_DATE('01011900','ddmmyyyy')) <= TO_DATE('3012' || :anno,'ddmmyyyy') "
                sqlFiltri += "AND NVL(OGVA.AL,TO_DATE('31129999','ddmmyyyy')) >= TO_DATE('0101' || :anno,'ddmmyyyy') "
            } else {
                sqlFiltri += "AND PRTR.ANNO = :anno "
            }
        }
        if (oggettoRif != null) {
            filtri << ['oggettoRif': oggettoRif]
            sqlFiltri += "AND OGPR.OGGETTO = :oggettoRif "
        }
        if (dataRif != null) {
            filtri << ['dataRif': dataRif]
            sqlFiltri += "AND OGCR.DATA_DECORRENZA = :dataRif "
        }

        if (filtroTipi.size() > 0) {
            sqlFiltri += "AND PRTR.TIPO_TRIBUTO IN ("
            filtroTipi.each {
                sqlFiltri += "'" + it + "',"
            }
            sqlFiltri = sqlFiltri.substring(0, sqlFiltri.length() - 1)
            sqlFiltri += ") "
        }

        def filtroPratiche = []

        if (tipiPratiche != null) {

            if (tipiPratiche.D) {
                filtroPratiche << TipoPratica.D.tipoPratica
            }
            if (tipiPratiche.V) {
                filtroPratiche << TipoPratica.V.tipoPratica
            }
            if (tipiPratiche.A) {
                filtroPratiche << TipoPratica.A.tipoPratica
            }
            if (tipiPratiche.L) {
                filtroPratiche << TipoPratica.L.tipoPratica
            }
            if (tipiPratiche.I) {
                filtroPratiche << TipoPratica.I.tipoPratica
            }

            if (filtroPratiche.size() > 0) {

                sqlFiltri += "AND PRTR.TIPO_PRATICA IN ("
                filtroPratiche.each {
                    sqlFiltri += "'" + it + "',"
                }
                sqlFiltri = sqlFiltri.substring(0, sqlFiltri.length() - 1)
                sqlFiltri += ") "
            }
        }

        if (codiciTributo.size() > 0) {
            String listCodici = codiciTributo.join(", ")
            sqlFiltri += "AND OGPR.TRIBUTO IN (" + listCodici + ") "
        }

        if (tipiTariffa.size() > 0) {
            String listTariffe = tipiTariffa.join(", ")
            sqlFiltri += "AND TO_NUMBER(LPAD(OGPR.TRIBUTO,4,'0')||LPAD(OGPR.TIPO_TARIFFA,2,'0')) IN (" + listTariffe + ") "
        }

        if (tipoOccupazione != null) {
            filtri << ['tipoOccupazione': tipoOccupazione]
            sqlFiltri += "AND OGPR.TIPO_OCCUPAZIONE = :tipoOccupazione "
        }

        String sqlValiditaSelect
        String sqlValiditaFrom
        String sqlValiditaWhere
        String sqlValiditaSort

        if (ignoraValidita) {
            sqlValiditaSelect = """
				OGCR.DATA_DECORRENZA DATA_DECORRENZA_STO,
				OGCR.DATA_CESSAZIONE DATA_CESSAZIONE_STO,
			"""
            sqlValiditaFrom = ""
            sqlValiditaWhere = ""
            sqlValiditaSort = "OGCR.DATA_DECORRENZA ASC"

            if (soloCessati) {
                sqlFiltri += "AND OGCR.DATA_CESSAZIONE IS NOT NULL "
            }
        } else {
            sqlValiditaSelect = """
					OGVA.DAL DATA_DECORRENZA_STO,
					OGVA.AL DATA_CESSAZIONE_STO,
			"""
            sqlValiditaFrom = "OGGETTI_VALIDITA OGVA,"
            sqlValiditaWhere = """
					OGPR.OGGETTO_PRATICA = OGVA.OGGETTO_PRATICA AND 
					OGCR.COD_FISCALE = OGVA.COD_FISCALE AND 
					PRTR.TIPO_TRIBUTO = OGVA.TIPO_TRIBUTO AND
			"""
            sqlValiditaSort = "OGVA.DAL ASC"

            if (soloCessati) {
                sqlFiltri += """AND OGVA.AL = (SELECT MAX(NVL(OGVA_SOCE.AL, TO_DATE('31122999', 'DDMMYYYY')))
												FROM OGGETTI_VALIDITA OGVA_SOCE
											   WHERE OGVA_SOCE.COD_FISCALE = :codFiscale
												 AND OGVA_SOCE.TIPO_TRIBUTO = '${tipoTributoFiltro}'
												 AND OGVA_SOCE.OGGETTO = OGVA.OGGETTO
												 AND OGVA_SOCE.TIPO_PRATICA <> 'C'
												 AND OGVA_SOCE.TIPO_EVENTO <> 'C')
				"""
            }
        }

        if (filtriRicerca.praticaEsclusa) {
            filtri << ['praticaEsclusa': filtriRicerca.praticaEsclusa]
            sqlFiltri += "AND f_esiste_oggetto_in_prat(OGGE.OGGETTO, :praticaEsclusa, '${tipoTributoFiltro}') = 'N' "
        }

        FiltroRicercaCanoni filtriAggiuntivi = filtriRicerca.filtriAggiunti

        if (filtriAggiuntivi) {

            if (filtriAggiuntivi.descrizione) {
                filtri << ['descrizioneOgg': filtriAggiuntivi.descrizione.toLowerCase()]
                sqlFiltri += "AND lower(OGGE.DESCRIZIONE) like(:descrizioneOgg) "
            }
            if (filtriAggiuntivi.indirizzo) {
                filtri << ['indirizzoOgg': filtriAggiuntivi.indirizzo.toLowerCase()]
                sqlFiltri += """AND lower(DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARCHIVIO_VIE.DENOM_UFF) ||
																DECODE(OGGE.NUM_CIV,NULL,'', ', ' || OGGE.NUM_CIV) ||
																		DECODE(OGGE.SUFFISSO,NULL,'', '/' || OGGE.SUFFISSO)) like(:indirizzoOgg) """
            }
            if (filtriAggiuntivi.localita) {
                filtri << ['indirizzoOcc': filtriAggiuntivi.localita.toLowerCase()]
                sqlFiltri += "AND lower(OGPR.INDIRIZZO_OCC) like(:indirizzoOcc) "
            }
            if (filtriAggiuntivi.codPro) {
                filtri << ['codProOcc': filtriAggiuntivi.codPro]
                sqlFiltri += "AND NVL(OGPR.COD_PRO_OCC,0) = :codProOcc "
            }
            if (filtriAggiuntivi.codCom) {
                filtri << ['codComOcc': filtriAggiuntivi.codCom]
                sqlFiltri += "AND NVL(OGPR.COD_COM_OCC,0) = :codComOcc "
            }
            if (filtriAggiuntivi.daKMDa) {
                filtri << ['daKMDaOgg': filtriAggiuntivi.daKMDa]
                sqlFiltri += "AND NVL(OGPR.DA_CHILOMETRO,-1) >= :daKMDaOgg "
            }
            if (filtriAggiuntivi.daKMA) {
                filtri << ['daKMAOgg': filtriAggiuntivi.daKMA]
                sqlFiltri += "AND NVL(OGPR.DA_CHILOMETRO,9999999) <= :daKMAOgg "
            }
            if (filtriAggiuntivi.aKMDa) {
                filtri << ['aKMDaOgg': filtriAggiuntivi.aKMDa]
                sqlFiltri += "AND NVL(OGPR.A_CHILOMETRO,-1) >= :aKMDaOgg "
            }
            if (filtriAggiuntivi.aKMA) {
                filtri << ['aKMAOgg': filtriAggiuntivi.aKMA]
                sqlFiltri += "AND NVL(OGPR.A_CHILOMETRO,9999999) <= :aKMAOgg "
            }

            if (filtriAggiuntivi.latitudineDa) {
                filtri << ['daLatitudineDa': filtriAggiuntivi.latitudineDa]
                sqlFiltri += "AND NVL(OGGE.LATITUDINE,0) >= :daLatitudineDa "
            }
            if (filtriAggiuntivi.latitudineA) {
                filtri << ['daLatitudineA': filtriAggiuntivi.latitudineA]
                sqlFiltri += "AND NVL(OGGE.LATITUDINE,0) <= :daLatitudineA "
            }
            if (filtriAggiuntivi.longitudineDa) {
                filtri << ['daLongitudineDa': filtriAggiuntivi.longitudineDa]
                sqlFiltri += "AND NVL(OGGE.LONGITUDINE,0) >= :daLongitudineDa "
            }
            if (filtriAggiuntivi.longitudineA) {
                filtri << ['daLongitudineA': filtriAggiuntivi.longitudineA]
                sqlFiltri += "AND NVL(OGGE.LONGITUDINE,0) <= :daLongitudineA "
            }

            if (filtriAggiuntivi.aLatitudineDa) {
                filtri << ['aLatitudineDa': filtriAggiuntivi.aLatitudineDa]
                sqlFiltri += "AND NVL(OGGE.A_LATITUDINE,0) >= :aLatitudineDa "
            }
            if (filtriAggiuntivi.aLatitudineA) {
                filtri << ['aLatitudineA': filtriAggiuntivi.aLatitudineA]
                sqlFiltri += "AND NVL(OGGE.A_LATITUDINE,0) <= :aLatitudineA "
            }
            if (filtriAggiuntivi.aLongitudineDa) {
                filtri << ['aLongitudineDa': filtriAggiuntivi.aLongitudineDa]
                sqlFiltri += "AND NVL(OGGE.A_LONGITUDINE,0) >= :aLongitudineDa "
            }
            if (filtriAggiuntivi.aLongitudineA) {
                filtri << ['aLongitudineA': filtriAggiuntivi.aLongitudineA]
                sqlFiltri += "AND NVL(OGGE.A_LONGITUDINE,0) <= :aLongitudineA "
            }

            if (filtriAggiuntivi.concessioneDa) {
                filtri << ['concessioneDa': filtriAggiuntivi.concessioneDa as Long]
                sqlFiltri += "AND NVL(OGPR.NUM_CONCESSIONE,-1) >= :concessioneDa "
            }
            if (filtriAggiuntivi.concessioneA) {
                filtri << ['concessioneA': filtriAggiuntivi.concessioneA as Long]
                sqlFiltri += "AND NVL(OGPR.NUM_CONCESSIONE,-1) <= :concessioneA "
            }
            if (filtriAggiuntivi.dataConcessioneDa) {
                filtri << ['dataConcessioneDal': filtriAggiuntivi.dataConcessioneDa]
                sqlFiltri += "AND OGPR.DATA_CONCESSIONE >= :dataConcessioneDal "
            }
            if (filtriAggiuntivi.dataConcessioneA) {
                filtri << ['dataConcessioneAl': filtriAggiuntivi.dataConcessioneA]
                sqlFiltri += "AND OGPR.DATA_CONCESSIONE <= :dataConcessioneAl "
            }
            if (filtriAggiuntivi.tariffa) {
                filtri << ['codiceTributoTariffa': filtriAggiuntivi.tariffa?.codiceTributo ?: 0]
                filtri << ['tipoTariffaTariffa': filtriAggiuntivi.tariffa?.tipoTariffa ?: 0]
                sqlFiltri += "AND (OGPR.TRIBUTO = :codiceTributoTariffa AND OGPR.TIPO_TARIFFA = :tipoTariffaTariffa) "
            }
            if (filtriAggiuntivi.esenzione) {
                def esenzione = filtriAggiuntivi.esenzione?.codice
                if (esenzione == 'S') {
                    sqlFiltri += "AND OGPR.FLAG_CONTENZIOSO = 'S' "
                }
                if (esenzione == 'N') {
                    sqlFiltri += "AND OGPR.FLAG_CONTENZIOSO IS NULL "
                }
            }
            if (filtriAggiuntivi.flagNullaOsta) {
                def flagNullaOsta = filtriAggiuntivi.flagNullaOsta?.codice
                if (flagNullaOsta == 'S') {
                    sqlFiltri += "AND OGPR.FLAG_NULLA_OSTA = 'S' "
                }
                if (flagNullaOsta == 'N') {
                    sqlFiltri += "AND OGPR.FLAG_NULLA_OSTA IS NULL "
                }
            }
        }

        sql = """SELECT DISTINCT
					CONT.NI,
					OGCR.COD_FISCALE,
					SOGG.COGNOME_NOME_RIC,
					OGPR.OGGETTO,
					OGPR.OGGETTO_PRATICA,
					OGPR.OGGETTO_PRATICA_RIF,
					OGPR.TRIBUTO,
					OGPR.CATEGORIA,
					OGPR.TIPO_TARIFFA,
					CATE.FLAG_GIORNI,
					OGPR.DATA_VARIAZIONE,
					OGPR.PRATICA,
					OGPR.NOTE NOTE_OGGETTO,
					OGGE.TIPO_OGGETTO,
					NVL(TARIFFE.DESCRIZIONE,' ') TARIFFA_DES,
					CATE.DESCRIZIONE CATEGORIA_DES,
					COTR.DESCRIZIONE TRIBUTO_DES,
					DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARCHIVIO_VIE.DENOM_UFF) ||
												DECODE(OGGE.NUM_CIV,NULL,'', ', ' || OGGE.NUM_CIV) ||
														DECODE(OGGE.SUFFISSO,NULL,'', '/' || OGGE.SUFFISSO) INDIRIZZO_OGG,
					OGGE.INDIRIZZO_LOCALITA NOME_VIA,
					OGGE.COD_VIA,
					OGGE.NUM_CIV,
					OGGE.SUFFISSO,
					OGGE.SCALA,
					OGGE.PIANO,
					OGGE.INTERNO,
					OGPR.DA_CHILOMETRO,
					OGPR.A_CHILOMETRO,
					OGPR.LATO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.PARTITA,
					OGGE.ZONA,
					OGGE.DESCRIZIONE OGGETTO_DES,
					OGGE.ZONA,
					OGGE.LATITUDINE,
					OGGE.LONGITUDINE,
					OGGE.A_LATITUDINE,
					OGGE.A_LONGITUDINE,
					OGCR.DATA_DECORRENZA,
					OGCR.DATA_CESSAZIONE,
					${sqlValiditaSelect}
					OGCR.INIZIO_OCCUPAZIONE,
					OGCR.FINE_OCCUPAZIONE,
					OGPR.FONTE,
					OGPR.TIPO_OCCUPAZIONE,
					OGPR.LARGHEZZA,
					OGPR.PROFONDITA,
					OGPR.CONSISTENZA_REALE,
					OGPR.CONSISTENZA,
					OGPR.QUANTITA,
					OGPR.FLAG_CONTENZIOSO,
					OGPR.INIZIO_CONCESSIONE,
					OGPR.FINE_CONCESSIONE,
					OGPR.NUM_CONCESSIONE,
					OGPR.DATA_CONCESSIONE,
					OGPR.FLAG_NULLA_OSTA,
					OGCR.PERC_POSSESSO,
					OGCR.PERC_DETRAZIONE,
					OGCR.MESI_POSSESSO_1SEM,
					OGPR.INDIRIZZO_OCC,
					OGPR.COD_PRO_OCC,
					OGPR.COD_COM_OCC,
					CMOG.DENOMINAZIONE DES_COM_OCC,
					PVOG.DENOMINAZIONE DES_PRO_OCC,
					PVOG.SIGLA SIG_PRO_OCC,
					PRTR.ANNO,
					PRTR.DENUNCIANTE,
					PRTR.INDIRIZZO_DEN,
					PRTR.COD_FISCALE_DEN,
					PRTR.TIPO_CARICA,
					PRTR.COD_PRO_DEN,
					PRTR.COD_COM_DEN,
					CMTR.DENOMINAZIONE DEN_COM_DEN,
					PVTR.DENOMINAZIONE DEN_PRO_DEN,
					PVTR.SIGLA SIG_PRO_DEN,
					PRTR.NOTE,
					PRTR.MOTIVO,
					PRTR.DATA DATA_PRATICA,
					PRTR.DATA_NOTIFICA,
					PRTR.DATA_SCADENZA,
					PRTR.NUMERO NUMERO_PRATICA,
					PRTR.TIPO_TRIBUTO AS TIPO_TRIBUTO_PRTR,
					COTR.TIPO_TRIBUTO AS TIPO_TRIBUTO_COTR,
					COTR.TIPO_TRIBUTO_PREC AS TIPO_TRIBUTO_PREC,
					PRTR.TIPO_PRATICA,
					RPTR.TIPO_RAPPORTO,
					PRTR.TIPO_EVENTO,
					PRTR.DATA_VARIAZIONE AS LAST_UPDATED_PRAT,
					OGCR.DATA_VARIAZIONE AS LAST_UPDATED_OGCR,
					OGCR.UTENTE AS UTENTE_OGCR
				FROM
					PRATICHE_TRIBUTO PRTR,
					RAPPORTI_TRIBUTO RPTR,
					CONTRIBUENTI CONT,
					SOGGETTI SOGG,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					ARCHIVIO_VIE,
					CATEGORIE CATE,
					CODICI_TRIBUTO COTR,
					TARIFFE,
					OGGETTI_CONTRIBUENTE OGCR,
					${sqlValiditaFrom}
					AD4_COMUNI CMOG,
					AD4_PROVINCIE PVOG,
					AD4_COMUNI CMTR,
					AD4_PROVINCIE PVTR
				WHERE
					PRTR.PRATICA = OGPR.PRATICA AND
					PRTR.PRATICA = RPTR.PRATICA AND
					OGCR.COD_FISCALE = CONT.COD_FISCALE AND
					CONT.NI = SOGG.NI (+) AND
					OGGE.COD_VIA = ARCHIVIO_VIE.COD_VIA (+) AND
					OGPR.TRIBUTO = CATE.TRIBUTO (+) AND
					OGPR.CATEGORIA = CATE.CATEGORIA (+) AND
					OGPR.TRIBUTO = COTR.TRIBUTO (+) AND
					OGPR.TRIBUTO = TARIFFE.TRIBUTO (+) AND
					OGPR.TIPO_TARIFFA = TARIFFE.TIPO_TARIFFA (+) AND
					OGPR.CATEGORIA = TARIFFE.CATEGORIA (+) AND
					OGPR.ANNO = TARIFFE.ANNO (+) AND
					OGPR.OGGETTO = OGGE.OGGETTO AND
					OGCR.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					${sqlValiditaWhere}
					CMOG.PROVINCIA_STATO = PVOG.PROVINCIA (+) AND
					OGPR.COD_PRO_OCC = CMOG.PROVINCIA_STATO (+) AND
					OGPR.COD_COM_OCC = CMOG.COMUNE (+) AND
					CMTR.PROVINCIA_STATO = PVTR.PROVINCIA (+) AND
					PRTR.COD_PRO_DEN = CMTR.PROVINCIA_STATO (+) AND
					PRTR.COD_COM_DEN = CMTR.COMUNE (+)
					${sqlFiltri}
				ORDER BY
					SOGG.COGNOME_NOME_RIC ASC,
                    OGCR.COD_FISCALE,
					OGPR.OGGETTO_PRATICA ASC,
					${sqlValiditaSort}
		"""

        if (count) {
            return eseguiQuery("select count(*) as num from (${sql})", filtri, null, true)[0]?.NUM
        }

        def results = eseguiQuery("${sql}", filtri, null, true)

        def concessioni = []
        def concessione

        String tipoTributo
        String tipoTributoPratica

        results.each {

            def record = [:]

            record.ni = it['NI']
            record.codFiscale = it['COD_FISCALE']
            record.cognomeNome = it['COGNOME_NOME_RIC']
            record.anno = it['ANNO']

            record.pratica = it['PRATICA']
            record.dataPratica = it['DATA_PRATICA']
            record.numeroPratica = it['NUMERO_PRATICA']

            record.dataNotifica = it['DATA_NOTIFICA']
            record.dataScadenza = it['DATA_SCADENZA']

            record.oggettoPratica = it['OGGETTO_PRATICA'] as Long
            record.oggettoPraticaRif = it['OGGETTO_PRATICA_RIF'] as Long
            record.oggetto = it['OGGETTO'] as Long

            tipoTributoPratica = it['TIPO_TRIBUTO_PRTR'] ?: ''

            tipoTributo = it['TIPO_TRIBUTO_PREC'] ?: ''
            if (tipoTributo.isEmpty()) {
                tipoTributo = it['TIPO_TRIBUTO_COTR'] ?: ''
                if (tipoTributo.isEmpty()) {
                    tipoTributo = tipoTributoPratica
                }
            }
            record.tipoTributo = tipoTributo
            record.tipoTributoPratica = tipoTributoPratica

            record.fonte = it['FONTE']

            record.codiceTributo = it['TRIBUTO'] as Long
            record.categoria = it['CATEGORIA'] as Integer
            record.tariffa = it['TIPO_TARIFFA'] as Integer

            record.esenzione = (it['FLAG_CONTENZIOSO'] == 'S')

            record.tributoDescr = it['TRIBUTO_DES']
            record.categoriaDescr = it['CATEGORIA_DES']
            record.tariffaDescr = it['TARIFFA_DES']

            record.tipoPratica = it['TIPO_PRATICA']
            record.tipoRapporto = it['TIPO_RAPPORTO']
            record.tipoEvento = it['TIPO_EVENTO']
            record.dataEvento = it['DATA_VARIAZIONE']

            record.dataDecorrenza = it['DATA_DECORRENZA_STO']
            record.dataCessazione = it['DATA_CESSAZIONE_STO']

            record.denunciante = it['DENUNCIANTE']
            record.codFisDen = it['COD_FISCALE_DEN']
            record.indirizzoDen = it['INDIRIZZO_DEN']
            record.tipoCarica = it['TIPO_CARICA']

            record.codComDen = it['COD_COM_DEN']
            record.denComDen = it['DEN_COM_DEN']
            record.codProDen = it['COD_PRO_DEN']
            record.denProDen = it['DEN_PRO_DEN']
            record.sigProDen = it['SIG_PRO_DEN']

            record.tipoOccupazione = it['TIPO_OCCUPAZIONE']
            record.inizioOccupazione = it['INIZIO_OCCUPAZIONE']
            record.fineOccupazione = it['FINE_OCCUPAZIONE']

            record.inizioConcessione = it['INIZIO_CONCESSIONE']
            record.fineConcessione = it['FINE_CONCESSIONE']
            record.numConcessione = it['NUM_CONCESSIONE']
            record.dataConcessione = it['DATA_CONCESSIONE']
            record.flagNullaOsta = (it['FLAG_NULLA_OSTA'] == 'S')

            record.quantita = it['QUANTITA']
            record.larghezza = it['LARGHEZZA']
            record.profondita = it['PROFONDITA']
            record.consistenzaReale = it['CONSISTENZA_REALE']
            record.consistenza = it['CONSISTENZA']

            record.percentualePoss = it['PERC_POSSESSO']

            record.percentualeDetr = it['PERC_DETRAZIONE']

            record.note = it['NOTE']
            record.motivo = it['MOTIVO']

            record.tipoOggetto = it['TIPO_OGGETTO']

            record.codVia = it['COD_VIA']
            record.nomeVia = it['NOME_VIA']
            record.civico = it['NUM_CIV']
            record.suffisso = it['SUFFISSO']
            record.scala = it['SCALA']
            record.piano = it['PIANO']
            record.interno = it['INTERNO']

            record.daKM = it['DA_CHILOMETRO']
            record.aKM = it['A_CHILOMETRO']
            record.lato = it['LATO']

            record.codComOgg = it['COD_COM_OCC']
            record.denComOgg = it['DES_COM_OCC']
            record.codProOgg = it['COD_PRO_OCC']
            record.denProOgg = it['DES_PRO_OCC']
            record.sigProOgg = it['SIG_PRO_OCC']

            record.localita = it['INDIRIZZO_OCC']

            record.indirizzoOgg = it['INDIRIZZO_OGG']

            record.sezione = it['SEZIONE']
            record.foglio = it['FOGLIO']
            record.numero = it['NUMERO']
            record.subalterno = it['SUBALTERNO']
            record.partita = it['PARTITA']
            record.zona = it['ZONA']
            record.descrizioneOggetto = it['OGGETTO_DES']

            record.latitudine = it['LATITUDINE']
            record.longitudine = it['LONGITUDINE']
            record.aLatitudine = it['A_LATITUDINE']
            record.aLongitudine = it['A_LONGITUDINE']

            record.noteOggetto = it['NOTE_OGGETTO']

            record.lastUpdatedPratica = it['LAST_UPDATED_PRAT']
            record.lastUpdatedOggetto = it['LAST_UPDATED_OGCR']
            record.utenteOggetto = it['UTENTE_OGCR']

            concessione = fillConcessione(record)

            concessioni << concessione
        }

        def concessioniOut = []

        if (skipMerge) {

            concessioni.each {
                concessioniOut << it
            }
        } else {
            concessioni.each {
                mergeConcessioni(it, concessioniOut)
            }
        }

        if (!skipTemaFlag) {

            Short annoRiferimento = (anno != null) && (anno != "Tutti") ? (anno as short) : null

            if (annoRiferimento) {
                tematizzaConcessioni(concessioniOut, annoRiferimento)
            }

            if (statoOccupazione != null) {
                concessioniOut = concessioniOut.findAll { it.tempTipoTema == statoOccupazione }
            }

            if (!skipDepagFlag && annoRiferimento) {
                verificaDepag(concessioniOut, annoRiferimento)
            }
        }

        return concessioniOut
    }

    // Merge delle concessioni ibride ICP + OSAP
    def mergeConcessioni(def concessione, def concessioni) {

        boolean merged = false

        def annoRef = concessione.anno
        def dataPratica = concessione.dataPratica
        def dataDecorrenza = concessione.dettagli.dataDecorrenza

        if ((annoRef >= 2021) && (dataPratica != null)) {

            def ni = concessione.ni
            def oggettoRef = concessione.oggettoRef

            def inList = concessioni.findAll {
                it.ni == ni && it.oggettoRef == oggettoRef && it.dataPratica == dataPratica &&
                        it.dettagli.dataDecorrenza == dataDecorrenza && it.anno == annoRef
            }
            inList.each {
                if (!merged) {
                    merged = mergeConcessione(concessione, it)
                }
            }
        }

        if (!merged) {

            concessioni << concessione
        }
    }

    // Merge delle concessione ibrida ICP + OSAP
    def mergeConcessione(def toMerge, def original) {

        boolean merged = false


        if ((toMerge.praticaOcc != 0) && (original.praticaOcc == 0)) {

            def dataToMerge = toMerge.occupazione
            def dettagli = toMerge.dettagli

            original.dettagli.inizioConcessione = dettagli.inizioConcessione
            original.dettagli.fineConcessione = dettagli.fineConcessione
            original.dettagli.numeroConcessione = dettagli.numeroConcessione
            original.dettagli.dataConcessione = dettagli.dataConcessione
            original.dettagli.flagNullaOsta = dettagli.flagNullaOsta

            original.occupazione.quantita = dataToMerge.quantita
            original.occupazione.larghezza = dataToMerge.larghezza
            original.occupazione.profondita = dataToMerge.profondita
            original.occupazione.consistenzaReale = dataToMerge.consistenzaReale
            original.occupazione.consistenza = dataToMerge.consistenza
            original.occupazione.percentualePoss = dataToMerge.percentualePoss

            original.occupazione.note = dataToMerge.note

            original.praticaOcc = toMerge.praticaOcc
            original.oggettoPraticaOcc = toMerge.oggettoPraticaOcc
            original.oggettoPraticaRifOcc = toMerge.oggettoPraticaRifOcc

            merged = true
        }

        if ((toMerge.praticaPub != 0) && (original.praticaPub == 0)) {

            def dataToMerge = toMerge.pubblicita
            def dettagli = toMerge.dettagli

            /// Per motivi storici il dato dell'Occupazione prevale sempre, quindi prendiamo
            /// quello della Pubblicità solo se Occupazione è tutto vuoto

            if((!original.dettagli.inizioConcessione) &&
               (!original.dettagli.fineConcessione) &&
               (!original.dettagli.numeroConcessione) &&
               (!original.dettagli.dataConcessione)) {

                original.dettagli.inizioConcessione = dettagli.inizioConcessione
                original.dettagli.fineConcessione = dettagli.fineConcessione
                original.dettagli.numeroConcessione = dettagli.numeroConcessione
                original.dettagli.dataConcessione = dettagli.dataConcessione
                original.dettagli.flagNullaOsta = dettagli.flagNullaOsta
            }

            original.pubblicita.quantita = dataToMerge.quantita
            original.pubblicita.larghezza = dataToMerge.larghezza
            original.pubblicita.profondita = dataToMerge.profondita
            original.pubblicita.consistenzaReale = dataToMerge.consistenzaReale
            original.pubblicita.consistenza = dataToMerge.consistenza

            original.pubblicita.note = dataToMerge.note

            original.praticaPub = toMerge.praticaPub
            original.oggettoPraticaPub = toMerge.oggettoPraticaPub
            original.oggettoPraticaRifPub = toMerge.oggettoPraticaRifPub

            merged = true
        }

        if (merged) {

            if ((original.categoria == 99) && (original.tariffa == 99)) {

                original.tipoTributo = toMerge.tipoTributo

                original.codiceTributoSec = original.codiceTributo
                original.categoriaSec = original.categoria
                original.tariffaSec = original.tariffa

                original.codiceTributo = toMerge.codiceTributo
                original.categoria = toMerge.categoria
                original.tariffa = toMerge.tariffa

                original.percentualeDetr = toMerge.percentualeDetr

                original.esenzione = toMerge.esenzione

                original.tributoDescr = toMerge.tributoDescr
                original.categoriaDescr = toMerge.categoriaDescr
                original.tariffaDescr = toMerge.tariffaDescr

                original.numeroPratica = toMerge.numeroPratica

                original.lastUpdatedPratica = toMerge.lastUpdatedPratica
                original.lastUpdatedOggetto = toMerge.lastUpdatedOggetto

            } else {
                original.codiceTributoSec = toMerge.codiceTributo
                original.categoriaSec = toMerge.categoria
                original.tariffaSec = toMerge.tariffa
            }

            original.oggettoPraticaRef = original.oggettoPraticaPub ?: original.oggettoPraticaOcc
        }

        return merged
    }

    // Crea Concessione da record
    def fillConcessione(def record) {

        def concessione = getConcessione()

        concessione.ni = record.ni
        concessione.contribuente = record.codFiscale
        concessione.cognomeNome = record.cognomeNome
        concessione.anno = record.anno

        concessione.tipoTributoPratica = record.tipoTributoPratica
        concessione.tipoTributo = record.tipoTributo

        concessione.tipoPratica = record.tipoPratica
        concessione.tipoRapporto = record.tipoRapporto

        concessione.tipoEvento = record.tipoEvento
        concessione.dataEvento = record.dataEvento
        concessione.fonte = record.fonte

        concessione.codiceTributo = record.codiceTributo
        concessione.categoria = record.categoria
        concessione.tariffa = record.tariffa

        concessione.percentualeDetr = record.percentualeDetr

        concessione.esenzione = record.esenzione

        concessione.dettagli.dataDecorrenza = record.dataDecorrenza
        concessione.dettagli.dataCessazione = record.dataCessazione

        concessione.dettagli.tipoOccupazione = record.tipoOccupazione
        concessione.dettagli.inizioOccupazione = record.inizioOccupazione
        concessione.dettagli.fineOccupazione = record.fineOccupazione

        concessione.dettagli.denunciante = record.denunciante
        concessione.dettagli.codFisDen = record.codFisDen
        concessione.dettagli.indirizzoDen = record.indirizzoDen
        concessione.dettagli.tipoCarica = record.tipoCarica

        concessione.dettagli.codComDen = record.codComDen
        concessione.dettagli.denComDen = record.denComDen
        concessione.dettagli.codProDen = record.codProDen
        concessione.dettagli.denProDen = record.denProDen
        concessione.dettagli.sigProDen = record.sigProDen

        concessione.dettagli.note = record.note
        concessione.dettagli.motivo = record.motivo

        concessione.oggetto.tipoOggetto = record.tipoOggetto

        concessione.oggetto.descrizione = record.descrizioneOggetto

        concessione.oggetto.localita = record.localita

        concessione.oggetto.codVia = record.codVia
        concessione.oggetto.nomeVia = record.nomeVia
        concessione.oggetto.civico = record.civico
        concessione.oggetto.suffisso = record.suffisso
        concessione.oggetto.scala = record.scala
        concessione.oggetto.piano = record.piano
        concessione.oggetto.interno = record.interno

        concessione.oggetto.daKM = record.daKM
        concessione.oggetto.aKM = record.aKM
        concessione.oggetto.lato = record.lato

        concessione.oggetto.sezione = record.sezione
        concessione.oggetto.foglio = record.foglio
        concessione.oggetto.numero = record.numero
        concessione.oggetto.subalterno = record.subalterno
        concessione.oggetto.zona = record.zona
        concessione.oggetto.partita = record.partita

        concessione.oggetto.latitudine = record.latitudine
        concessione.oggetto.longitudine = record.longitudine
        concessione.oggetto.aLatitudine = record.aLatitudine
        concessione.oggetto.aLongitudine = record.aLongitudine

        concessione.oggetto.codCom = record.codComOgg
        concessione.oggetto.denCom = record.denComOgg
        concessione.oggetto.codPro = record.codProOgg
        concessione.oggetto.denPro = record.denProOgg
        concessione.oggetto.sigPro = record.sigProOgg

        concessione.dettagli.inizioConcessione = record.inizioConcessione
        concessione.dettagli.fineConcessione = record.fineConcessione
        concessione.dettagli.numeroConcessione = record.numConcessione
        concessione.dettagli.dataConcessione = record.dataConcessione
        concessione.dettagli.flagNullaOsta = record.flagNullaOsta

        if (concessione.tipoTributo == 'ICP') {

            concessione.pubblicita.quantita = record.quantita
            concessione.pubblicita.larghezza = record.larghezza
            concessione.pubblicita.profondita = record.profondita
            concessione.pubblicita.consistenzaReale = record.consistenzaReale
            concessione.pubblicita.consistenza = record.consistenza

            concessione.pubblicita.note = record.noteOggetto

            concessione.praticaPub = record.pratica
            concessione.oggettoPraticaPub = record.oggettoPratica
            concessione.oggettoPraticaRifPub = record.oggettoPraticaRif

            if (concessione.tipoTributoPratica == 'CUNI') {
                if ((concessione.praticaBase ?: 0) == 0) {
                    concessione.praticaBase = concessione.praticaPub
                }
            }
        }
        if (concessione.tipoTributo == 'TOSAP') {

            concessione.occupazione.quantita = record.quantita
            concessione.occupazione.larghezza = record.larghezza
            concessione.occupazione.profondita = record.profondita
            concessione.occupazione.consistenzaReale = record.consistenzaReale
            concessione.occupazione.consistenza = record.consistenza
            concessione.occupazione.percentualePoss = record.percentualePoss

            concessione.occupazione.note = record.noteOggetto

            concessione.praticaOcc = record.pratica
            concessione.oggettoPraticaOcc = record.oggettoPratica
            concessione.oggettoPraticaRifOcc = record.oggettoPraticaRif

            if (concessione.tipoTributoPratica == 'CUNI') {
                if ((concessione.praticaBase ?: 0) == 0) {
                    concessione.praticaBase = concessione.praticaOcc
                }
            }
        }

        concessione.tributoDescr = record.tributoDescr
        concessione.categoriaDescr = record.categoriaDescr
        concessione.tariffaDescr = record.tariffaDescr

        concessione.indirizzoOgg = record.indirizzoOgg

        concessione.oggettoRef = record.oggetto

        concessione.dataPratica = record.dataPratica
        concessione.numeroPratica = record.numeroPratica

        concessione.dataNotifica = record.dataNotifica
        concessione.dataScadenza = record.dataScadenza

        concessione.lastUpdatedPratica = record.lastUpdatedPratica
        concessione.lastUpdatedOggetto = record.lastUpdatedOggetto

        formatCoordinates(concessione, false)
        formatCoordinates(concessione, true)

        /* #65780 :
         * Attenzione al nome fuorviante, andrebbe chiamato concessione.utenteOggetto.
         * necessario per l'update di 'vm.utente' dopo il salvataggio in concessioneCU.zul
         */
        concessione.utentePratica = record.utenteOggetto

        concessione.oggettoPraticaRef = concessione.oggettoPraticaPub ?: concessione.oggettoPraticaOcc

        return concessione
    }

    // Crea Concessione vuota
    def getConcessione() {

        def concessione = [

                ni                  : null,
                contribuente        : null,
                cognomeNome         : null,
                anno                : 2021,

                tipoTributoPratica  : 'CUNI',
                tipoTributo         : null,
                tipoPratica         : null,
                tipoRapporto        : null,
                tipoEvento          : null,
                dataEvento          : null,

                fonte               : 0,

                codiceTributo       : null,
                categoria           : null,
                tariffa             : null,

                codiceTributoSec    : null,        // Non letti direttamente da DB, ricavati in fase di Merge delle Concessioni o dalla UI
                categoriaSec        : null,
                tariffaSec          : null,

                percentualeDetr     : null,

                esenzione           : false,

                dettagli            : [

                        dataDecorrenza   : null,
                        dataCessazione   : null,

                        tipoOccupazione  : null,

                        inizioOccupazione: null,
                        fineOccupazione  : null,

                        denunciante      : null,
                        codFisDen        : null,
                        indirizzoDen     : null,
                        tipoCarica       : null,

                        codComDen        : null,
                        denComDen        : null,
                        codProDen        : null,
                        denProDen        : null,
                        sigProDen        : null,

                        note             : null,
                        motivo           : null,

                        inizioConcessione: null,
                        fineConcessione  : null,
                        numeroConcessione: null,
                        dataConcessione  : null,

                        flagNullaOsta    : false
                ],

                oggetto             : [

                        tipoOggetto: null,

                        descrizione: null,

                        codCom     : null,
                        denCom     : null,
                        codPro     : null,
                        denPro     : null,
                        sigPro     : null,

                        localita: null,

                        codVia     : null,
                        nomeVia    : null,
                        civico     : null,
                        suffisso   : null,
                        scala      : null,
                        piano      : null,
                        interno    : null,

                        daKM       : null,
                        aKM        : null,
                        lato       : null,

                        partita    : null,
                        sezione    : null,
                        foglio     : null,
                        numero     : null,
                        zona       : null,
                        subalterno : null,

                        latitudine  : null,
                        longitudine : null,
                        aLatitudine  : null,
                        aLongitudine : null,

                        latSessages : null,         /// Lat/Lon in formato sessagesimale ggg°pp'ss.ds"
                        lonSessages : null,
                        aLatSessages : null,
                        aLonSessages : null,

                        geoLocation : null,         /// Stringa di geolocalizzazione
                        aGeoLocation : null,
                        geoLocationURL : null,      /// URL geolocalizzazione
                        aGeoLocationURL : null,
                ],

                pubblicita          : [

                        larghezza       : null,
                        profondita      : null,
                        consistenza     : null,
                        consistenzaReale: null,

                        quantita        : null,
                        note            : null,
                ],

                occupazione         : [

                        larghezza        : null,
                        profondita       : null,
                        consistenza      : null,
                        consistenzaReale : null,

                        percentualePoss  : null,

                        quantita         : null,
                        note             : null,
                ],

                // Derivati, solo per elenco
                tributoDescr        : null,
                categoriaDescr      : null,
                tariffaDescr        : null,

                indirizzoOgg        : null,

                // Riferimenti ad elementi esistenti
                praticaPub          : 0,                // Pratica di tipo 'ICP'
                oggettoPraticaPub   : 0,
                oggettoPraticaRifPub: 0,

                praticaOcc          : 0,                // Pratica di tipo 'TOSAP'
                oggettoPraticaOcc   : 0,
                oggettoPraticaRifOcc: 0,

                praticaRef          : 0,                // Utilizzata solo per le nuove pratiche di tipo_tributo 'CUNI' (2021/10/12)
                oggettoRef          : 0,
                oggettoPraticaRef   : 0,

                dataPratica         : null,
                numeroPratica       : null,

                lastUpdatedPratica  : null,
                lastUpdatedOggetto  : null,


                dataNotifica        : null,
                dataScadenza        : null,

                praticaBase         : null,            // Solo per la lista dei canoni

                // Dati collegati
                versamenti          : null,

                // Gestione modifiche
                tipoVariazione      : null,        // Tipo di variazione della Concessione
                dataVariazione      : null,        // Data di validit� della variazione

                // Solo temporanei
                tempTipoTema        : STATO_CONONE_NORMALE,                // Usato per tematizzare la voce in legenda, ricalcolato ad ogni lettura
        ]

        return concessione
    }

    // Crea Concessione vuota
    def fillConcessioneDaPratica(def concessione, Long praticaId) {

        PraticaTributo praticaTributoRaw
        PraticaTributoDTO praticaTributoDTO

        praticaTributoRaw = PraticaTributo.get(praticaId)
        praticaTributoDTO = praticaTributoRaw?.toDTO(["comuneDenunciante", "comuneDenunciante.ad4Comune", "comuneDenunciante.ad4Comune.provincia"])

        if (praticaTributoDTO != null) {

            Ad4ComuneTr4DTO comDenunciante = praticaTributoDTO.comuneDenunciante
            Ad4ComuneDTO comuneDenunciante = comDenunciante?.ad4Comune

            concessione.praticaRef = praticaTributoDTO.id
            concessione.dataPratica = praticaTributoDTO.data
            concessione.numeroPratica = praticaTributoDTO.numero
            concessione.tipoEvento = praticaTributoDTO.tipoEvento.tipoEventoDenuncia

            concessione.dataNotifica = praticaTributoDTO.dataNotifica
            concessione.dataScadenza = praticaTributoDTO.dataScadenza

            concessione.lastUpdatedPratica = praticaTributoDTO.lastUpdated
            concessione.lastUpdatedOggetto = null
            concessione.utentePratica = praticaTributoDTO.utente

            concessione.contribuente = praticaTributoDTO.contribuente?.codFiscale

            concessione.anno = praticaTributoDTO.anno
            concessione.tipoTributo = praticaTributoDTO.tipoTributo.tipoTributo

            def tipoTema = STATO_CONONE_ANNOCORRENTE

            if (concessione.tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]) {

                tipoTema = STATO_CONONE_NORMALE

                Short annoRiferimento = Calendar.getInstance().get(Calendar.YEAR)
                def chiusuraAnnoPrec = getChiusuraAnno(annoRiferimento - 1).getTime()

                def oggettiPratica = praticaTributoRaw.oggettiPratica
                if ((oggettiPratica != null) && (oggettiPratica.size() > 0)) {

                    def oggettoPratica = oggettiPratica[0]

                    def oggettiContribuente = oggettoPratica.oggettiContribuente
                    if ((oggettiContribuente != null) && (oggettiContribuente.size() > 0)) {

                        def oggettoContribuente = oggettiContribuente[0]
                        def dataDecorrenza = oggettoContribuente.dataDecorrenza

                        if (dataDecorrenza > chiusuraAnnoPrec) {
                            tipoTema = STATO_CONONE_ANNOCORRENTE
                        }
                    }
                }
            }
            concessione.tempTipoTema = tipoTema

            def dettagli = concessione.dettagli

            dettagli.tipoOccupazione = tipoOccupazioneDaPratica(praticaTributoDTO)

            dettagli.denunciante = praticaTributoDTO.denunciante
            dettagli.codFisDen = praticaTributoDTO.codFiscaleDen
            dettagli.indirizzoDen = praticaTributoDTO.indirizzoDen
            dettagli.tipoCarica = praticaTributoDTO.tipoCarica?.id

            dettagli.codComDen = comDenunciante?.comune
            dettagli.denComDen = comuneDenunciante?.denominazione
            dettagli.codProDen = comDenunciante?.provinciaStato
            dettagli.denProDen = comuneDenunciante?.provincia?.denominazione
            dettagli.sigProDen = comuneDenunciante?.provincia?.sigla

            dettagli.note = praticaTributoDTO.note
            dettagli.motivo = praticaTributoDTO.motivo
        }

        return concessione
    }

    // Clona la concessione ed ogni singolo componente
    def clonaConcessione(def concessione) {

        def clonata = concessione.clone()

        clonata.dettagli = concessione.dettagli.clone()
        clonata.occupazione = concessione.occupazione.clone()
        clonata.pubblicita = concessione.pubblicita.clone()

        return clonata
    }

    // Tematizza le concessioni in base alle loro caqratteristiche
    def tematizzaConcessioni(def concessioni, def annoRiferimento) {

        def chiusuraAnnoPrec = getChiusuraAnno(annoRiferimento - 1).getTime()

        def dataDecorrenza
        def dataCessazione
        def tipoOccupazione
        def codiceTributo
        Short tempTipoTema

        concessioni.each {

            tempTipoTema = STATO_CONONE_NORMALE

            dataDecorrenza = it.dettagli.dataDecorrenza
            dataCessazione = it.dettagli.dataCessazione
            tipoOccupazione = it.dettagli.tipoOccupazione
            codiceTributo = it.codiceTributo ?: 0

            if (dataCessazione != null) {
                if (dataDecorrenza <= chiusuraAnnoPrec) {
                    tempTipoTema = STATO_CONONE_BONIFICATO
                }
            } else {
                if ((codiceTributo < 8600) || (codiceTributo > 8699)) {
                    tempTipoTema = STATO_CONONE_ANOMALO
                }
            }
            if (dataDecorrenza != null) {
                if (dataDecorrenza > chiusuraAnnoPrec) {
                    tempTipoTema = STATO_CONONE_ANNOCORRENTE
                }
            }

            it.tempTipoTema = tempTipoTema
        }
    }

    // Verifica stato eventuale avviso Agid associato
    def verificaDepag(def concessioni, Short annoRiferimento) {

        def dePagAbilitato = integrazioneDePagService.dePagAbilitato()
        def dePag

        if (dePagAbilitato) {
            concessioni.each {

                dePag = identificativiDepag(it, annoRiferimento)

                if (dePag.praticaBase != null && dePag.praticaBase != 0) {
                    it.statoDepag = integrazioneDePagService.recuperaStatoDePagPratica(dePag.praticaBase)
                } else {
                    it.statoDepag = integrazioneDePagService.recuperaStatoDePagImposta(it.contribuente, annoRiferimento, 'CUNI')
                }
            }
        }
    }

    // Annula voci depag delle concessioni
    def annullaDepagConcessioni(def concessioni, Short annoRiferimento) {

        def dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        String message = ""
        Integer result = 0

        if (!dePagAbilitato) {
            message = "Depag non abilitato"
            result = 1
        } else {
            concessioni.each {

                def report = annullaDepagConcessione(it, annoRiferimento)
                if (report.result != 0) {
                    if (result < report.result) {
                        result = report.result
                    }
                    message += report.message

                } else {
                    def prtr = PraticaTributo.get(it.praticaRef)
                    prtr.flagDePag = null
                    prtr.save(failOnError: true, flush: true)
                }
            }
        }

        return [result: result, message: message]
    }

    // Annula voci depag delle concessioni
    def annullaDepagConcessione(def concessione, Short annoRiferimento) {

        def dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        String message = ""
        Integer result = 0

        if (!dePagAbilitato) {
            message = "Depag non abilitato"
            result = 1
        } else {

            def dePag = identificativiDepag(concessione, annoRiferimento)

            def results
            if ((concessione.praticaRef != null && concessione.praticaRef != 0) || (dePag.praticaBase != null && dePag.praticaBase != 0)) {
                results = integrazioneDePagService.determinaDovutiPratica(dePag.praticaBase ?: concessione.praticaRef)
            } else {
                results = integrazioneDePagService.determinaDovutiImposta(concessione.contribuente, annoRiferimento, 'CUNI', null)
            }

            results.each {
                message += integrazioneDePagService.eliminaDovuto(it.IDBACK, it.SERVIZIO)
            }

            if (!(message.isEmpty())) {
                result++
            }
        }

        return [result: result, message: message]
    }

    // Ricava dati identificazione depag dalla concessione
    def identificativiDepag(def concessione, Short annoRiferimento) {

        String tipoTributoBase

        def dePag = [:]

        tipoTributoBase = concessione.tipoTributo

        if (concessione.tempTipoTema == STATO_CONONE_NORMALE) {
            dePag.praticaBase = 0
        } else {
            if ((concessione.praticaRef ?: 0) > 0) {
                dePag.praticaBase = concessione.praticaRef
            } else {
                dePag.praticaBase = (tipoTributoBase in ['ICP', 'CUNI']) ? concessione.praticaPub : concessione.praticaOcc
            }
        }

        if (annoRiferimento >= 2021) {
            dePag.tipoTributo = 'CUNI'
        } else {
            dePag.tipoTributo = tipoTributoBase
        }

        return dePag
    }

    // Imposta l'oggetto della concessione da <= esistente
    def impostaOggetto(def concessione, def idOggetto) {

        String message = ""
        Integer result = 0

        if (idOggetto != null) {

            Oggetto oggettoRef = Oggetto.findById(idOggetto)
            if (oggettoRef != null) {

                def oggetto = concessione.oggetto

                oggetto.tipoOggetto = oggettoRef.tipoOggetto.tipoOggetto

                oggetto.descrizione = oggettoRef.descrizione

                oggetto.codVia = oggettoRef.archivioVie?.id
                oggetto.nomeVia = (oggettoRef.archivioVie != null) ? oggettoRef.archivioVie.denomUff : oggettoRef.indirizzoLocalita
                oggetto.civico = oggettoRef.numCiv
                oggetto.suffisso = oggettoRef.suffisso
                oggetto.scala = oggettoRef.scala
                oggetto.piano = oggettoRef.piano
                oggetto.interno = oggettoRef.interno

                oggetto.sezione = oggettoRef.sezione
                oggetto.foglio = oggettoRef.foglio
                oggetto.numero = oggettoRef.numero
                oggetto.subalterno = oggettoRef.subalterno
                oggetto.zona = oggettoRef.zona
                oggetto.partita = oggettoRef.partita

                oggetto.latitudine = oggettoRef.latitudine
                oggetto.longitudine = oggettoRef.longitudine
                oggetto.aLatitudine = oggettoRef.aLatitudine
                oggetto.aLongitudine = oggettoRef.aLongitudine

                concessione.oggettoRef = oggettoRef.id

                formatCoordinates(concessione, false)
                formatCoordinates(concessione, true)

                result = 0

            } else {

                message = "Oggetto non trovato in archivio"
                result = 2
            }
        } else {

            message = "Oggetto non valido "
            result = 2
        }

        return [result: result, message: message]
    }

    // Esegue verifica su dati della Concessione e crea messaggio di avvertimento
    def verificaDichiarazione(def concessione, def dovutiRateizzati) {

        String message = ""
        Integer result = 0

        Date minDate = new Date(0, 0, 1)                // 01/01/1900
        Date maxDate = new Date(199, 11, 31)            // 31/12/2099

        def dettagli = concessione.dettagli

        // Frontespizio
        if (concessione.dataPratica != null) {
            if ((concessione.dataPratica < minDate) || (concessione.dataPratica > maxDate)) {
                message += "Data non valida\n"
            }
        }

        if (dettagli.tipoOccupazione == null) {
            message += "Tipologia non impostata\n"
        }

        if (concessione.dataScadenza != null) {
            if ((concessione.dataScadenza <= (concessione.dataPratica ?: minDate)) || (concessione.dataScadenza > maxDate)) {
                message += "Data Scadenza non valida\n"
            }
        }

        // Versamenti
        def versamenti = concessione.versamenti

        if (versamenti != null) {
            versamenti.each {
                VersamentoDTO vers = it

                def reportVers = versamentiService.verificaVersamento(vers, concessione.anno, dovutiRateizzati)
                if (reportVers.result > 1) {    // Ignores the warnings
                    message += reportVers.message
                }
            }
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Esegue verifica su dati della Concessione e crea messaggio di avvertimento
    def verificaConcessione(def concessione) {

        String message = ""
        Integer result = 0

        Date minDate = new Date(0, 0, 1)                // 01/01/1900
        Date maxDate = new Date(199, 11, 31)            // 31/12/2099

        def dettagli = concessione.dettagli

        // Coerenza eventi con tipo occupazione
        def tipoEvento = concessione.tipoEvento ?: '-'
        def tipoPratica = concessione.tipoPratica ?: '-'

        if (tipoPratica == TipoPratica.D.tipoPratica) {
            if (tipoEvento == TipoEventoDenuncia.U.tipoEventoDenuncia) {
                if (dettagli.tipoOccupazione != TipoOccupazione.T.tipoOccupazione) {
                    message += "Il Canone e' stato originariamente creato con Tipologia Temporanea. Impossibile modificare !\n"
                }
            } else {
                if (dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {
                    message += "Il Canone e' stato originariamente creato con Tipologia Permanente. Impossibile modificare !\n"
                }
            }
        }

        // Frontespizio
        if (dettagli.dataDecorrenza == null) {
            message += "Data Decorrenza non impostata\n"
        } else {
            if ((dettagli.dataDecorrenza < minDate) || (dettagli.dataDecorrenza > maxDate)) {
                message += "Data Decorrenza non valida\n"
            }

            if (dettagli.dataCessazione != null) {
                if ((dettagli.dataCessazione < minDate) || (dettagli.dataCessazione > maxDate)) {
                    message += "Data Cessazione non valida\n"
                }
                if (dettagli.tipoOccupazione != TipoOccupazione.T.tipoOccupazione) {
                    message += "Data Cessazione deve essere vuoto per Tipologia Permanente\n"
                }
                if (dettagli.dataCessazione < dettagli.dataDecorrenza) {
                    message += "Data Cessazione non coerente\n"
                }
            } else {
                if (dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {
                    message += "Data Cessazione non impostata\n"
                }
            }
        }

        // Denunciante

        // Estremi
        def oggetto = concessione.oggetto

        if (oggetto.tipoOggetto == null) {
            message += "Tipo oggetto non impostato\n"
        }

        def foglio = oggetto.foglio ?: ""
        def numero = oggetto.numero ?: ""

        if (((oggetto.codVia == null) && (oggetto.nomeVia == null)) && ((foglio.size() == 0) || (numero.size() == 0))) {
            message += "Specificare l'indirizzo oppure gli estremi catastali dell'oggetto\n"
        }

        if (oggetto.civico != null) {
            if ((oggetto.civico < 0) || (oggetto.civico > 999999)) {
                message += "Civico non valido : indicare un numero tra 0 e 999999, oppure lasciare vuoto\n"
            }
        }
        if (oggetto.daKM != null) {
            if ((oggetto.daKM < -9999.99) || (oggetto.daKM > 9999.99)) {
                message += "Valore di KM non valido : indicare un numero tra -9999.99 e 9999.99, oppure lasciare vuoto\n"
            }
        }
        if (oggetto.aKM != null) {
            if ((oggetto.aKM < -9999.99) || (oggetto.aKM > 9999.99)) {
                message += "Valore di Al KM non valido : indicare un numero tra -9999.99 e 9999.99, oppure lasciare vuoto\n"
            }
        }
        if (oggetto.lato != null) {
            switch (oggetto.lato.toUpperCase()) {
                default:
                    message += "Valore di L non valido : indicare 'S' per Sinistra, 'D' per Destra oppure lasciare vuoto\n"
                    break
                case 'S':
                case 'D':
                    break
            }
        }
        if (oggetto.interno != null) {
            if ((oggetto.interno < 0) || (oggetto.interno > 99)) {
                message += "Interno non valido : indicare un numero tra 0 e 99, oppure lasciare vuoto\n"
            }
        }

        // Tariffa
        if (concessione.tipoTributo != "CUNI") {
            if (concessione.codiceTributo == null) {
                message += "Tipo tariffa non impostato\n"
            }
            if (dettagli.tipoOccupazione == null) {
                message += "Tipologia tariffa non impostata\n"
            }
            if (concessione.categoria == null) {
                message += "Categoria tariffa non impostata\n"
            }
            if (dettagli.tariffa == null) {
                message += "Tariffa non impostata\n"
            }
        } else {
            if ((concessione.codiceTributo == null) || (concessione.categoria == null) ||
                    (concessione.tariffa == null) || (dettagli.tipoOccupazione == null)) {
                message += "Tariffa non impostata correttamente\n"
            }
        }
        if (dettagli.inizioOccupazione == null) {
            message += "Data Inizio Occupazione non impostata\n"
        } else {
            if ((dettagli.inizioOccupazione < minDate) || (dettagli.inizioOccupazione > maxDate)) {
                message += "Data Inizio Occupazione non valida\n"
            }

            if (dettagli.fineOccupazione != null) {
                if ((dettagli.fineOccupazione < minDate) || (dettagli.fineOccupazione > maxDate)) {
                    message += "Data Fine Occupazione non valida\n"
                }

                if (dettagli.fineOccupazione < dettagli.inizioOccupazione) {
                    message += "Data Fine Occupazione non coerente\n"
                }
            } else {
                if (dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {
                    message += "Data Fine Occupazione non impostata\n"
                }
            }
        }

        if (concessione.percentualeDetr != null) {
            if ((concessione.percentualeDetr < -1000.0) || (concessione.percentualeDetr > 99.99)) {
                message += "Valore di % Detr. non valido : indicare un numero tra -1000.00 e 99.99, oppure lasciare vuoto\n"
            }
        }

        // Dati Protocollo Concessione
        if (dettagli.fineConcessione != null) {
            if (dettagli.inizioConcessione != null) {
                if (dettagli.fineConcessione < dettagli.inizioConcessione) {
                    message += "Data Fine Concessione non coerente\n"
                }
            } else {
                message += "Data Inizio Concessione non impostata\n"
            }
        }

        if (dettagli.numeroConcessione != null) {
            if ((dettagli.numeroConcessione < 1) || (dettagli.numeroConcessione > 9999999)) {
                message += "Numero Concessione non valido : indicare un numero tra 1 e 9999999, oppure lasciare vuoto\n"
            }
            if (dettagli.dataConcessione == null) {
                message += "Data Concessione non impostata\n"
            }
        }

        // Pubblicità
        def pubblicita = concessione.pubblicita

        if (pubblicita.quantita != null) {
            if ((pubblicita.quantita < 1) || (pubblicita.quantita > 999999)) {
                message += "Valore di Pubblicita' > Quantita' non valido : indicare un numero tra 1 e 999999, oppure lasciare vuoto\n"
            }
        }
        if (pubblicita.larghezza != null) {
            if ((pubblicita.larghezza < 0.01) || (pubblicita.larghezza > 99999)) {
                message += "Valore di Pubblicita' > L (m) non valido : indicare un numero tra 0.01 e 99999.99, oppure lasciare vuoto\n"
            }
        }
        if (pubblicita.profondita != null) {
            if ((pubblicita.profondita < 0.01) || (pubblicita.profondita > 99999)) {
                message += "Valore di Pubblicita' > H (m) non valido : indicare un numero tra 0.01 e 99999.99, oppure lasciare vuoto\n"
            }
        }

        // Occupazione suolo
        def occupazione = concessione.occupazione

        if (occupazione.quantita != null) {
            if ((occupazione.quantita < 1) || (occupazione.quantita > 999999)) {
                message += "Valore di Occupazione > Quantita' non valido : indicare un numero tra 1 e 999999, oppure lasciare vuoto\n"
            }
        }
        if (occupazione.larghezza != null) {
            if ((occupazione.larghezza < 0.01) || (occupazione.larghezza > 99999)) {
                message += "Valore di Occupazione > Larghezza non valido : indicare un numero tra 0.01 e 99999.99, oppure lasciare vuoto\n"
            }
        }
        if (occupazione.profondita != null) {
            if ((occupazione.profondita < 0.01) || (occupazione.profondita > 99999)) {
                message += "Valore di Occupazione > Profondita' non valido : indicare un numero tra 0.01 e 99999.99, oppure lasciare vuoto\n"
            }
        }

        if (occupazione.percentualePoss != null) {
            if ((occupazione.percentualePoss < 0.00) || (occupazione.percentualePoss > 100.00)) {
                message += "Valore di Occupazione > % Poss. non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
            }
        }

        // Coerenza tariffa con campi superficie tassabile
        try {

            Short anno = concessione.anno as Short
            def datiTariffaBase = getDatiTariffa(anno, concessione.codiceTributo, concessione.categoria, concessione.tariffa)

            def codiceTributo = datiTariffaBase.codiceTributo
            String codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo

            if (codiceTributoTxt == 'ICP') {
                if ((pubblicita.consistenza ?: 0) < 0.001) {
                    message += "Pubblicita' > Sup. Tassabile deve essere compilato e valido\n"
                }
            }
            if (codiceTributoTxt == 'TOSAP') {
                if ((occupazione.consistenza ?: 0) < 0.001) {
                    message += "Occupazione > Sup. Tassabile deve essere compilato e valido\n"
                }
            }
        }
        catch (Exception e) {
            message += e.message
            if (result < 2) result = 2
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Gestisce e corregge il campo quantita
    def verificaQuantita(def dati) {

        Boolean changed = false

        if (dati.quantita != null) {
            if (dati.quantita < 1) {
                dati.quantita = 1
                changed = true
            }
            if (dati.quantita > 999999) {
                dati.quantita = 999999
                changed = true
            }
        }

        return changed
    }

    // Gestisce e corregge i campi dimensionali
    def verificaDimensioni(def dati) {

        Boolean changed = false

        if (dati.larghezza != null) {
            if (dati.larghezza < 0.01) {
                dati.larghezza = 0.01
                changed = true
            }
            if (dati.larghezza > 99999.99) {
                dati.larghezza = 99999.99
                changed = true
            }
        }
        if (dati.profondita != null) {
            if (dati.profondita < 0.01) {
                dati.profondita = 0.01
                changed = true
            }
            if (dati.profondita > 99999.99) {
                dati.profondita = 99999.99
                changed = true
            }
        }

        return changed
    }

    // Ricava configurazione arrotondamento da Tributo, Codice per l'Ente attivo
    def getArrotondamento(String tipoTributo, def codiceTributo) {

        CodiceTributo codiceTributoObj
        ArrotondamentiTributo arrotondamenti = null
        String rounding
        Double limiteMin

        def roundingMode = [
                consistenzaReale: [
                        rounding: 'none',
                        minimum : 0.0,
                        maximum : 999999.00
                ],
                consistenza     : [
                        rounding: (tipoTributo == 'CUNI') ? 'next_integer' : 'next_half',
                        minimum : 0.0,
                        maximum : 999999.00
                ]
        ]

        codiceTributoObj = CodiceTributo.findById(codiceTributo)
        if (codiceTributoObj != null) {

            arrotondamenti = ArrotondamentiTributo.findByCodiceTributo(codiceTributoObj)

            if (arrotondamenti != null) {

                rounding = getArrotondamentoRounding(arrotondamenti.arrConsistenza)
                if (rounding != null) {
                    roundingMode.consistenza.rounding = rounding
                }
                limiteMin = arrotondamenti.consistenzaMinima
                if (limiteMin != null) {
                    roundingMode.consistenza.minimum = limiteMin
                }

                rounding = getArrotondamentoRounding(arrotondamenti.arrConsistenzaReale)
                if (rounding != null) {
                    roundingMode.consistenzaReale.rounding = rounding
                }
                limiteMin = arrotondamenti.consistenzaMinimaReale
                if (limiteMin != null) {
                    roundingMode.consistenzaReale.minimum = limiteMin
                }
            }
        }

        DatoGenerale datoGenerale = DatoGenerale.get(1)
        Ad4ComuneTr4 comune = datoGenerale.comuneCliente

        return roundingMode
    }

    // Ricava tipo arrotondamento da modalita
    String getArrotondamentoRounding(Integer modalita) {

        String ronding = 'none'

        switch (modalita) {
            default:
                ronding = null
                break
            case ArrotondamentiTributoDTO.ARR_MODALITA_PREDEFINITO:
                ronding = null
                break
            case ArrotondamentiTributoDTO.ARR_MODALITA_NESSUNO:
                ronding = 'none'
                break
            case ArrotondamentiTributoDTO.ARR_MODALITA_INTERO_SUCCESSIVO:
                ronding = 'next_integer'
                break
            case ArrotondamentiTributoDTO.ARR_MODALITA_MEZZO_SUCCESSIVO:
                ronding = 'next_half'
                break
        }

        return ronding
    }

    // Ricalcola consistenza
    def ricalcolaConsistenza(String tipoTributo, def codiceTributo, def dati) {

        Double consistenzaReale
        Double consistenza

        Boolean changed = false

        def roundingMode = getArrotondamento(tipoTributo, codiceTributo)

        //	println "Tipo Tributo : ${tipoTributo}"
        //	println "Codice Tributo : ${codiceTributo}"
        //	println "Rounding : ${roundingMode}"

        if ((dati.larghezza != null) || (dati.profondita != null)) {

            Double quantita = (dati.quantita ?: 1.0) as Double
            Double larghezza = (dati.larghezza ?: 1.0) as Double
            Double profondita = (dati.profondita ?: 1.0) as Double

            consistenzaReale = larghezza * profondita
            consistenzaReale = fixupConsistenza(roundingMode.consistenzaReale, consistenzaReale)

            consistenza = consistenzaReale * quantita
            consistenza = fixupConsistenza(roundingMode.consistenza, consistenza)

            changed = true
        } else {
            consistenzaReale = null

            if (dati.quantita != null) {
                consistenza = fixupConsistenza(roundingMode.consistenza, dati.quantita as Double)
            } else {
                consistenza = dati.consistenza
            }

            changed = true
        }

        dati.consistenzaReale = consistenzaReale
        dati.consistenza = consistenza

        return changed
    }

    // Fixup consistenza
    private Double fixupConsistenza(def roundingMode, double consistenza) {

        switch (roundingMode.rounding) {
            case 'none':
                break
            case 'next_integer':
                consistenza = Math.ceil(consistenza)
                break
            case 'next_half':
                consistenza *= 2.0
                consistenza = Math.ceil(consistenza)
                consistenza /= 2.0
                break
        }
        if ((consistenza > 0) && (consistenza < roundingMode.minimum)) consistenza = roundingMode.minimum
        if (consistenza > roundingMode.maximum) consistenza = roundingMode.maximum

        return consistenza
    }

    // Verifica se chiudibile
    def dichiarazioneChiudibile(def concessione) {

        String message = ""
        Integer result = 0

        def cbTributiNow = getCheckTributi(concessione.tipoTributo)

        def filtriRicerca = [
                tipiTributo : cbTributiNow,
                pratica     : concessione.praticaRef,
                skipTemaFlag: true
        ]

        def elencoCanoni = getConcessioniContribuente(filtriRicerca)
        def canoniAperti = elencoCanoni.findAll { it.dettagli.dataCessazione == null }

        if (canoniAperti.size() != 0) {
            def decorrenza = null
            canoniAperti.each {
                def data = it.dettagli.dataDecorrenza
                if (data != null) {
                    if (decorrenza != null) {
                        if (data > decorrenza) {
                            decorrenza = data
                        }
                    } else {
                        decorrenza = data
                    }
                }
            }
            concessione.dettagli.dataDecorrenza = decorrenza
        }

        if (canoniAperti.size() == 0) {

            message = "Tutti i canoni della dichiarazione risultano gia\' chiusi "
            result = 1
        }

        return [result: result, message: message]
    }

    // Verifica se chiudibile
    def concessioneChiudibile(def concessione) {

        String message = ""
        Integer result = 0

        if (concessione.dettagli.dataCessazione != null) {

            message = "Canone gia' chiuso "
            result = 1
        }

        return [result: result, message: message]
    }

    // Chiude dichiarazione
    def chiudiDichiarazione(def concessioneOriginale, Date dataChiusuraUD, Date fineOccupazioneUD = null, def canoniDaChiudere = []) {

        String message = ""
        Integer result = 0

        def praticaRef = 0

        def elencoCanoni = getConcessioniDichiarazione(concessioneOriginale.tipoTributo, concessioneOriginale.praticaRef)
        def canoniAperti = elencoCanoni.findAll { it.dettagli.dataCessazione == null }

        canoniAperti.each { daChiudere ->

            Long oggettoPraticaRef = daChiudere.oggettoPraticaRef

            if ((canoniDaChiudere.size() == 0) || (canoniDaChiudere.indexOf(oggettoPraticaRef) != -1)) {

                daChiudere.praticaRef = praticaRef

                def reportThis = chiudiConcessione(daChiudere, dataChiusuraUD, fineOccupazioneUD)

                if (reportThis.result != 0) {
                    if (result < reportThis.result) {
                        result = reportThis.result
                    }
                    if (!(message.isEmpty())) {
                        message += "\n"
                    }
                    message += reportThis.message
                }

                praticaRef = daChiudere.praticaRef
            }
        }

        return [result: result, message: message, concessione: concessioneOriginale]
    }

    // Chiude conessioni
    def chiudiConcessioni(def concessioneDaChiudere, Date dataChiusuraUD, Date fineOccupazioneUD = null) {

        String message = ""
        Integer result = 0

        def praticaRef = 0

        def canoniAperti = concessioneDaChiudere.findAll { it.dettagli.dataCessazione == null }

        canoniAperti.each { daChiudere ->

            daChiudere.praticaRef = praticaRef

            def reportThis = chiudiConcessione(daChiudere, dataChiusuraUD, fineOccupazioneUD)

            if (reportThis.result != 0) {
                if (result < reportThis.result) {
                    result = reportThis.result
                }
                if (!(message.isEmpty())) {
                    message += "\n"
                }
                message += reportThis.message
            }

            praticaRef = daChiudere.praticaRef
        }

        return [result: result, message: message]
    }

    // Chiude conessione
    def chiudiConcessione(def concessioneOriginale, Date dataChiusuraUD, Date fineOccupazioneUD = null, Short annoChiusura = null) {

        String message = ""
        Integer result = 0

        def concessione = clonaConcessione(concessioneOriginale)

        Short anno = annoChiusura ?: -1
        Date dataChiusura = dataChiusuraUD ?: getChiusuraAnno(annoChiusura).getTime()
        Calendar chiusura = Calendar.getInstance()
        chiusura.setTime(dataChiusura)

        concessione.tipoVariazione = TipoEventoDenuncia.C
        concessione.dataVariazione = dataChiusura
        concessione.anno = chiusura.get(Calendar.YEAR)
        concessione.dataPratica = null

        if (fineOccupazioneUD) {
            concessione.dettagli.fineOccupazione = fineOccupazioneUD
        }

        concessione.praticaPub = 0
        if ((concessione.oggettoPraticaRifPub ?: 0) == 0) {
            concessione.oggettoPraticaRifPub = concessione.oggettoPraticaPub
        }
        concessione.oggettoPraticaPub = 0

        concessione.praticaOcc = 0
        if ((concessione.oggettoPraticaRifOcc ?: 0) == 0) {
            concessione.oggettoPraticaRifOcc = concessione.oggettoPraticaOcc
        }
        concessione.oggettoPraticaOcc = 0

        if (result == 0) {

            def report = salvaConcessione(concessione)
            result = report.result
            message = report.message
        }

        if (result == 0) {

            concessioneOriginale.dataPratica = getDataOdierna()

            concessioneOriginale.dettagli.dataCessazione = concessione.dataVariazione

            concessioneOriginale.dettagli.fineOccupazione = concessione.dettagli.fineOccupazione

            concessioneOriginale.praticaPub = concessione.praticaPub
            concessioneOriginale.oggettoPraticaPub = concessione.oggettoPraticaPub
            concessioneOriginale.oggettoPraticaRifPub = concessione.oggettoPraticaRifPub

            concessioneOriginale.praticaOcc = concessione.praticaOcc
            concessioneOriginale.oggettoPraticaOcc = concessione.oggettoPraticaOcc
            concessioneOriginale.oggettoPraticaRifOcc = concessione.oggettoPraticaRifOcc

            concessioneOriginale.oggettoRef = concessione.oggettoRef

            concessioneOriginale.praticaRef = concessione.praticaRef
        }

        return [result: result, message: message, concessione: concessioneOriginale]
    }

    // Subentro conessioni da dichiarazione
    def subentroDichiarazione(def dichiarazioneOriginale, def dettagliSubentro) {

        String message = ""
        Integer result = 0

        def canoniInSubentro = dettagliSubentro.canoniInSubentro ?: []

        def conessioniOriginali = getConcessioniDichiarazione(dichiarazioneOriginale.tipoTributo, dichiarazioneOriginale.praticaRef)

        conessioniOriginali.each { inSubentro ->

            Long oggettoPraticaRef = inSubentro.oggettoPraticaRef

            if ((canoniInSubentro.size() == 0) || (canoniInSubentro.indexOf(oggettoPraticaRef) != -1)) {

                def reportNow = subentroConcessione(inSubentro, dettagliSubentro)
                if (reportNow.result > 0) {
                    if (result < reportNow.result) {
                        result = reportNow.result
                    }
                    message += reportNow.message
                }
            }
        }

        return [result: result, message: message]
    }

    // Subentro conessioni da dichiarazione
    def subentroConcessioni(def canoniInSubentro, def dettagliSubentro) {

        String message = ""
        Integer result = 0

        canoniInSubentro.each { inSubentro ->

            def reportNow = subentroConcessione(inSubentro, dettagliSubentro)
            if (reportNow.result > 0) {
                if (result < reportNow.result) {
                    result = reportNow.result
                }
                message += reportNow.message
            }
        }

        return [result: result, message: message]
    }

    // Verifica se possibile subentro
    def verificaSubentro(Short annoIn, def concessioniIn, Date dataSubentro = null, SoggettoDTO soggDestinazione = null) {

        String message = ""
        Integer result = 0

        List concessioni = []
        Boolean listMode = false

        if (concessioniIn) {

            if (concessioniIn.getClass() != [].getClass()) {
                concessioni << concessioniIn
            } else {
                concessioni = concessioniIn
                listMode = true
            }
        }

        Boolean isCUNI = (annoIn >= 2021)

        concessioni.each {

            String messageNow = ""

            try {
                getDatiTariffa(annoIn, it.codiceTributo, it.categoria, it.tariffa, isCUNI)

                if (dataSubentro) {
                    if (it.dettagli.dataDecorrenza) {
                        if (it.dettagli.dataDecorrenza > dataSubentro) {
                            messageNow += "Data Decorrenza successiva a Data cessazione"
                            result = 2
                        }
                    }
                }
            }
            catch (Exception e) {

                logger.error(e, e);

                messageNow = e.message
                result = 2
            }

            if (!messageNow.isEmpty()) {
                if (listMode) {
                    message += "Oggetto ${it.oggettoRef} : ${messageNow}\n"
                } else {
                    message += messageNow + "\n"
                }
                if (result < 1) result = 1
            }
        }

        if (result != 1) {
            if (soggDestinazione != null) {
                message = "Trasferimento non disponibile : \n\n" + message
            } else {
                message = "Impossibile procedere : \n\n" + message
            }
        }

        return [result: result, message: message]
    }

    // Riassegna conessione
    def subentroConcessione(def concessioneOriginale, def dettagliSubentro) {

        String message = ""
        Integer result = 0

        def concessione = clonaConcessione(concessioneOriginale)

        Date dataDecorrenza = dettagliSubentro.dataDecorrenza
        Date dataCessazione = dettagliSubentro.dataCessazione
        Date inizioOccupazione = dettagliSubentro.dataInizioOccupazione
        Date fineOccupazione = dettagliSubentro.dataFineOccupazione

        // Prima di tutto sistemiamo le date
        def dettagli = concessione.dettagli

        Calendar decorrenza = Calendar.getInstance()
        decorrenza.setTime(dataDecorrenza)

        concessione.tipoVariazione = null
        concessione.dataVariazione = dataDecorrenza
        concessione.anno = decorrenza.get(Calendar.YEAR)
        concessione.dataPratica = getDataOdierna()

        dettagli.dataDecorrenza = dataDecorrenza
        dettagli.dataCessazione = dataCessazione

        dettagli.inizioOccupazione = inizioOccupazione ?: dataDecorrenza
        dettagli.fineOccupazione = fineOccupazione ?: dataCessazione

        // Puliamo dati residui
        dettagli.denunciante = null
        dettagli.codFisDen = null
        dettagli.indirizzoDen = null
        dettagli.tipoCarica = null

        dettagli.codComDen = null
        dettagli.denComDen = null
        dettagli.codProDen = null
        dettagli.denProDen = null
        dettagli.sigProDen = null

        concessione.versamenti = null

        // Tutto nuovo, sia pubblicita' che occupazione
        concessione.praticaPub = 0
        concessione.oggettoPraticaPub = 0
        concessione.oggettoPraticaRifPub = 0

        concessione.praticaOcc = 0
        concessione.oggettoPraticaOcc = 0
        concessione.oggettoPraticaRifOcc = 0

        concessione.praticaRef = dettagliSubentro.praticaRef

        Contribuente contribuente

        try {
            contribuente = creaContribuente(dettagliSubentro.soggSubentro)
        }
        catch (Exception e) {
            message += e.message
            if (result < 2) result = 2
        }

        if (result == 0) {

            concessione.contribuente = contribuente.codFiscale

            def report = salvaConcessione(concessione)

            dettagliSubentro.praticaRef = concessione.praticaRef

            result = report.result
            message = report.message
        }

        return [result: result, message: message, dettagliSubentro: dettagliSubentro]
    }

    // Verifica se duplicabile
    def concessioneDuplicabile(def concessione, def annoNuovo) {

        String message = ""
        Integer result = 0

        while (1 == 1) {

            if (concessione.dataPratica == null) {

                message = "Canone senza data, impossibile procedere "
                result = 2
                break
            }

            //		def resultVerifica = verificaUnivocita(concessione);
            //		if(resultVerifica.result != 0) {

            //			message = resultVerifica.message;
            //			result = resultVerifica.result;
            //			break;
            //		}

            if (concessione.dettagli.dataCessazione == null) {

                message = "Prima di duplicare il Canone e' necessario chiuderlo "
                result = 2
                break
            }

            //
            break
        }

        return [result: result, message: message]
    }

    // Duplica conessione
    def duplicaConcessione(def concessione, def annoNuovo) {

        String message = ""
        Integer result = 0

        // Cambia dati di base
        concessione.tipoTributo = 'CUNI'

        reimpostaDecorrenza(concessione, annoNuovo)

        // Denunciante

        // Estremi

        // Riassegna tariffa

        // Dati Protocollo Concessione
        if (concessione.dettagli.fineConcessione != null) {

            if (concessione.dettagli.fineConcessione < concessione.dettagli.dataDecorrenza) {

                concessione.dettagli.inizioConcessione = null
                concessione.dettagli.fineConcessione = null
                concessione.dettagli.numeroConcessione = null
                concessione.dettagli.dataConcessione = null
                concessione.dettagli.flagNullaOsta = false
            }
        }

        // Pubblicità

        // Occupazione

        // Tutto nuovo, sia pubblicit� che occupazione
        concessione.praticaPub = 0
        concessione.oggettoPraticaPub = 0
        concessione.oggettoPraticaRifPub = 0

        concessione.praticaOcc = 0
        concessione.oggettoPraticaOcc = 0
        concessione.oggettoPraticaRifOcc = 0

        return [result: result, message: message, concessione: concessione]
    }

    // Verifica se convertibile a Canone Unico
    def concessioneConvertibile(def concessione, def annoNuovo) {

        String message = ""
        Integer result = 0

        while (1 == 1) {

            if (concessione.dettagli.dataCessazione == null) {

                message = "Prima di convertire il canone e' necessario chiuderlo "
                result = 2
                break
            }

            if (annoNuovo < 2021) {
                message = "Annualita' non valida per Canone Unico (${concessione.anno})"
                result = 2
                break
            }

            if (concessione.anno == annoNuovo) {
                message = "Impossibile applicare conversione verso medesima annualita' (${concessione.anno})"
                result = 2
                break
            }

            //
            break
        }

        return [result: result, message: message]
    }

    // Converte elenco concessioni contribuente - Modalit� UI less
    def convertiConcessioniContribuente(def elencoConcessioni, def statsOrg = null) {

        def refData = [:]

        def stats = [
                processed   : 0,
                converted   : 0,
                closed      : 0,
                noZona      : 0,
                noConversion: 0,
                errors      : 0
        ]

        def report = [
                message: '',
                result : 0
        ]

        String tipoTributo = "CUNI"
        Short annoTributo = Calendar.getInstance().get(Calendar.YEAR)

        refData.tipoTributo = tipoTributo
        refData.annoTributo = annoTributo
        refData.dataChiusura = getChiusuraAnno(-1).getTime()
        refData.fineOccupazione = null

        refData.listaCodici = getCodiciTributo(tipoTributo, annoTributo)
        refData.elencoCategorie = getCategorie(refData.listaCodici)
        refData.elencoTariffe = getTariffe(refData.listaCodici, annoTributo)

        refData.associazioniVie = getAssociazioniVieZona([anno: annoTributo])
        refData.listaZone = getElencoZone([anno: annoTributo])

        elencoConcessioni.each {

            def concessione = clonaConcessione(it)

            def reportThis = convertiConcessioneUIL(concessione, refData, stats)

            if (reportThis.result != 0) {

                if (report.result < reportThis.result) report.result = reportThis.result
                report.message += reportThis.message
            }
        }

        if (report.result == 0) {
            report.message = "Risultato conversione Canoni : \n\n"
            report.message += "Processati : " + stats.processed.toString() + "\n"
            report.message += "Convertiti : " + stats.converted.toString() + "\n"
            report.message += "Gia' chiusi : " + stats.closed.toString() + "\n"
            report.message += "Non localizzabili : " + stats.noZona.toString() + "\n"
            report.message += "Senza conversione : " + stats.noConversion.toString() + "\n"
            report.message += "Errori di conversione : " + stats.errors.toString() + "\n"
        }

        if (statsOrg != null) {
            statsOrg.processed = (statsOrg.processed ?: 0) + stats.processed
            statsOrg.converted = (statsOrg.converted ?: 0) + stats.converted
            statsOrg.closed = (statsOrg.closed ?: 0) + stats.closed
            statsOrg.noZona = (statsOrg.noZona ?: 0) + stats.noZona
            statsOrg.noConversion = (statsOrg.noConversion ?: 0) + stats.noConversion
            statsOrg.errors = (statsOrg.errors ?: 0) + stats.errors
        }

        return report
    }

    // Converte conessione - Modalità UI less
    def convertiConcessioneUIL(def concessione, def refData, def statistics) {

        def reportNow = [:]
        def report = [
                message: '',
                result : 0
        ]

        def conversione
        def zonaDaVia
        def codiceZona
        boolean preCheckOk = true

        while (1 == 1) {

            // Analisi preliminare

            if (concessione.dettagli.dataCessazione != null) {
                statistics.closed++
                break
            }

            zonaDaVia = determinaZonaOggetto(refData.associazioniVie, concessione.oggetto)
            codiceZona = zonaDaVia.codiceZona
            if (codiceZona == null) {
                statistics.noZona++
                preCheckOk = false
            }

            conversione = getConversioneTariffaConcessione(concessione, concessione.anno as Integer, refData.tipoTributo, refData.annoTributo)
            if (conversione != null) {
                if (!verificaConversioneTariffaUIL(concessione, conversione, codiceZona, refData)) conversione = null
            }

            if (conversione == null) {
                statistics.noConversion++
                preCheckOk = false
            }

            if (!preCheckOk) {
                break
            }

            // Chiude e converte

            reportNow = concessioneChiudibile(concessione)
            if (reportNow.result != 0) {
                statistics.errors++
                break
            }

            reportNow = chiudiConcessione(concessione, refData.dataChiusura, refData.fineOccupazione)
            if (reportNow.result != 0) {
                statistics.errors++
                break
            }

            concessione = reportNow.concessione

            reportNow = convertiConcessione(concessione, refData.annoTributo)
            if (reportNow.result != 0) {
                statistics.errors++
                break
            }

            concessione = reportNow.concessione

            if (!verificaConversioneTariffaUIL(concessione, conversione, codiceZona, refData, true)) {
                statistics.errors++
                break
            }

            // Salva e chiude

            reportNow = salvaConcessione(concessione)
            if (reportNow.result != 0) {
                statistics.errors++
                break
            }

            statistics.converted++
            //
            break
        }

        statistics.processed++

        return report
    }

    // Verifica coerenza tariffaria dopo conversione
    def verificaConversioneTariffaUIL(def concessione, def conversione, def codZona, def refData, boolean apply = false) {

        boolean result = false

        String denominazioneZona = "--SENZA_NOME--"

        def zona = refData.listaZone.find { it.codZona == codZona }
        if (zona != null) {
            denominazioneZona = zona.denominazione
        }

        Integer tipologiaTariffa

        if (concessione.dettagli.tipoOccupazione != TipoOccupazione.T.tipoOccupazione) {
            tipologiaTariffa = TariffaDTO.TAR_TIPOLOGIA_PERMANENTE
        } else {
            tipologiaTariffa = TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA
        }

        def convertiTributo = conversione.convertiTributo
        def convertiCategoria = conversione.convertiCategoria
        def convertiTipoTariffa = conversione.convertiTipoTariffa

        List<CategoriaDTO> listaCategorie = []
        List<TariffaDTO> listaTariffe = []

        if (convertiTributo != null) {
            listaCategorie = refData.elencoCategorie.findAll { it.codiceTributo.id == convertiTributo }
            listaTariffe = refData.elencoTariffe.findAll { it.categoria.codiceTributo.id == convertiTributo }
        } else {
            listaCategorie = refData.elencoCategorie
            listaTariffe = refData.elencoTariffe
        }

        listaCategorie = listaCategorie.findAll { it.descrizione == denominazioneZona }

        def categorie = []
        listaCategorie.each {
            def codCategoria = it.categoria
            if (categorie.find { it == codCategoria } == null) {
                categorie << it.categoria
            }
        }

        listaTariffe = listaTariffe.findAll {
            it.tipoTariffa == convertiTipoTariffa && it.tipologiaTariffa == tipologiaTariffa && it.categoria.categoria in categorie
        }

        TariffaDTO tariffaNuova

        if (listaTariffe.size() == 1) {
            tariffaNuova = listaTariffe[0]
            result = true
        } else {
            tariffaNuova = null
        }

        if (result && apply) {

            concessione.codiceTributo = tariffaNuova.categoria.codiceTributo.id
            concessione.categoria = tariffaNuova.categoria.categoria
            concessione.tariffa = tariffaNuova.tipoTariffa
        }

        return result
    }

    // Converte conessione
    def convertiConcessione(def concessione, def annoNuovo) {

        String message = ""
        Integer result = 0

        def dati = null

        // Cambia dati di base
        Integer annoOrigine = concessione.anno

        concessione.tipoTributoPratica = 'CUNI'

        reimpostaDecorrenza(concessione, annoNuovo)

        // Denunciante

        // Estremi
        List<TipoOggettoDTO> listaTipiOggetto = getTipiOggetto(concessione.tipoTributo)

        def tipoOggetto = listaTipiOggetto.find { it.tipoOggetto == concessione.oggetto.tipoOggetto }
        if (tipoOggetto == null) {

            tipoOggetto = listaTipiOggetto.find { it.tipoOggetto == 10 }
            if (tipoOggetto == null) {

                if (listaTipiOggetto.size() > 0) {
                    tipoOggetto = listaTipiOggetto[0]
                }
            }
        }
        if (concessione.oggetto.tipoOggetto != tipoOggetto.tipoOggetto) {

            concessione.oggetto.tipoOggetto = tipoOggetto.tipoOggetto
            concessione.oggettoRef = 0
        }

        concessione.fonte = 0

        // Riassegna tariffa
        convertiTariffaConcessione(concessione, annoOrigine)

        // Dati Protocollo Concessione
        if (concessione.dettagli.fineConcessione != null) {

            if (concessione.dettagli.fineConcessione < concessione.dettagli.dataDecorrenza) {

                concessione.dettagli.inizioConcessione = null
                concessione.dettagli.fineConcessione = null
                concessione.dettagli.numeroConcessione = null
                concessione.dettagli.dataConcessione = null
                concessione.dettagli.flagNullaOsta = false
            }
        }

        // Pubblicità
        dati = concessione.pubblicita

        def tariffaCodice = concessione.codiceTributo ?: 0
        ricalcolaConsistenza(concessione.tipoTributo, tariffaCodice, dati)

        // Occupazione
        dati = concessione.occupazione

        ricalcolaConsistenza(concessione.tipoTributo, 0, dati)

        // Tutto nuovo, sia pubblicit� che occupazione
        concessione.praticaPub = 0
        concessione.oggettoPraticaPub = 0
        concessione.oggettoPraticaRifPub = 0

        concessione.praticaOcc = 0
        concessione.oggettoPraticaOcc = 0
        concessione.oggettoPraticaRifOcc = 0

        return [result: result, message: message, concessione: concessione]
    }

    // Converte la tariffa di una concessione
    def convertiTariffaConcessione(def concessione, Integer annoOrigine) {

        def conversione = getConversioneTariffaConcessione(concessione, annoOrigine, concessione.tipoTributo as String, concessione.anno as Integer)

        if (conversione != null) {

            concessione.codiceTributo = conversione.convertiTributo
            concessione.categoria = conversione.convertiCategoria
            concessione.tariffa = conversione.convertiTipoTariffa

            if (conversione.convertiPercDetrazione != null) {
                if (conversione.convertiPercDetrazione > 100.0) {
                    concessione.esenzione = true
                } else {
                    concessione.percentualeDetr = conversione.convertiPercDetrazione
                }
            }

            concessione.dettagli.note = modificaStringaDaConversione(concessione.dettagli.note, conversione.convertiNote)
            concessione.dettagli.motivo = modificaStringaDaConversione(concessione.dettagli.motivo, conversione.convertiMotivo)

            concessione.pubblicita.note = modificaStringaDaConversione(concessione.pubblicita.note, conversione.convertiNoteTariffa)
            concessione.occupazione.note = modificaStringaDaConversione(concessione.occupazione.note, conversione.convertiNoteTariffa)
        } else {

            concessione.codiceTributo = null
            concessione.categoria = null
            concessione.tariffa = null
        }

        concessione.codiceTributoSec = null
        concessione.categoriaSec = null
        concessione.tariffaSec = null
    }

    // Cerca conversione per tariffa concessione
    def getConversioneTariffaConcessione(def concessione, Integer annoOrigine, String tributoDestinazione, Integer annoDestinazione) {

        def elencoConversioni = getConversioniTariffa(annoOrigine, tributoDestinazione, annoDestinazione)

        def conversione = elencoConversioni.find {
            it.tributo == concessione.codiceTributo &&
                    it.categoria == concessione.categoria && it.tipoTariffa == concessione.tariffa
        }

        /**
         println "Tributo : ${concessione.codiceTributo}"
         println "Categoria : ${concessione.categoria}"
         println "Tariffa : ${concessione.tariffa}"

         if(conversione != null) {println "Conv : ${conversione}"}
        **/

        return conversione
    };

    // Modifca campo note in base a conversione
    private String modificaStringaDaConversione(String originale, String modifica) {

        String risultato

        if ((modifica ?: '').isEmpty()) {

            risultato = originale
        } else {

            def modificatore = modifica.substring(0, 1)

            switch (modificatore) {
                default:
                    if ((originale ?: '').isEmpty()) {
                        risultato = modifica
                    } else {
                        risultato = originale
                        risultato += " - "
                        risultato += modifica
                    }
                    break
                case "+":
                    if ((originale ?: '').isEmpty()) {
                        risultato = modifica.substring(1, modifica.length() - 1)
                    } else {
                        risultato = originale
                        risultato += " - "
                        risultato += modifica.substring(1, modifica.length() - 1)
                    }
                    break
                case "=":
                    risultato = modifica.substring(1, modifica.length() - 1)
                    break
            }
        }

        return risultato
    }

    // Verifica univocità della concessione
    def verificaUnivocita(def concessione) {

        String message = ""
        Integer result = 0

        if (concessione.tipoVariazione != TipoEventoDenuncia.C) {

            def oggettoRef = concessione.oggettoRef

            if (oggettoRef != 0) {

                def tipiTributo = [
                        TARSU: false,
                        TASI : false,
                        ICI  : false,
                        ICP  : (concessione.tipoTributo == 'ICP'),
                        TOSAP: (concessione.tipoTributo == 'TOSAP'),
                        CUNI : (concessione.tipoTributo == 'CUNI')
                ]
                def tipiPratica = [
                        D: true,
                        V: false,
                        A: false,
                        L: false,
                        I: false
                ]

                def filtri = [
                        codFiscale   : concessione.contribuente,
                        anno         : concessione.anno as Short,
                        oggettoRif   : concessione.oggettoRef,
                        dataRif      : concessione.dettagli.dataDecorrenza,
                        tipiPratica  : tipiPratica,
                        tipiTributo  : tipiTributo,
                        skipMerge    : true,
                        skipTemaFlag : true,
                        skipDepagFlag: true
                ]

                def listaConcessioni = getConcessioniContribuente(filtri)

                def matchs = 0
                listaConcessioni.each {
                    if (((it.praticaPub != 0) && (it.praticaPub != concessione.praticaPub)) ||
                            ((it.praticaOcc != 0) && (it.praticaOcc != concessione.praticaOcc))) matchs++
                }

                if (matchs > 0) {

                    message = "Esite gia' un Canone per questo Oggetto e per questa Decorrenza !\n\nImpossibile procedere."
                    result = 1
                }
            }
        }

        return [result: result, message: message]
    }

    // Salva dichiarazione
    def salvaDichiarazione(def concessione) {

        String message = ""
        Integer result = 0

        try {
            def datiTariffaBase = [:]

            datiTariffaBase.codiceTributo = null
            datiTariffaBase.categoria = null
            datiTariffaBase.tariffa = null

            datiTariffaBase.dataVariazione = concessione.dataPratica ?: getDataOdierna()
            datiTariffaBase.versamenti = concessione.versamenti

            Contribuente contribuente = Contribuente.findByCodFiscale(concessione.contribuente)
            if (contribuente == null) {
                throw new Exception("Contribuente non trovato")
            }
            datiTariffaBase.contribuente = contribuente

            datiTariffaBase.oggetto = null

            PraticaTributo praticaRef = salvaConcessionePratica(concessione, datiTariffaBase, concessione.praticaRef as Long, 0)
            concessione.praticaRef = praticaRef.id
        } catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message, concessione: concessione]
    }

    // Salva conessione
    def salvaConcessione(def concessione) {

        String message = ""
        Integer result = 0

        try {

            def resultVerifica = verificaUnivocita(concessione)
            if (resultVerifica.result != 0) {
                throw new Exception(resultVerifica.message)
            }

            Short anno = concessione.anno
            String tipoTributo = concessione.tipoTributo

            CodiceTributo codiceTributo
            PraticaTributo pratica
            String codiceTributoTxt

            def datiTariffaBase = getDatiTariffa(anno, concessione.codiceTributo, concessione.categoria, concessione.tariffa)

            datiTariffaBase.dataVariazione = concessione.dataPratica ?: getDataOdierna()

            Contribuente contribuente = Contribuente.findByCodFiscale(concessione.contribuente)
            if (contribuente == null) {
                throw new Exception("Contribuente non trovato")
            }
            datiTariffaBase.contribuente = contribuente

            Oggetto oggetto = salvaConcessioneOggetto(concessione)
            datiTariffaBase.oggetto = oggetto

            codiceTributo = datiTariffaBase.codiceTributo
            codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo

            if (codiceTributoTxt == 'ICP') {

                PraticaTributo praticaPub = salvaConcessionePratica(concessione, datiTariffaBase, concessione.praticaPub as Long, concessione.praticaRef as Long)
                concessione.praticaPub = praticaPub.id
                datiTariffaBase.pratica = praticaPub

                OggettoPratica oggettoPraticaPub = salvaConcessioneOggPrTr(concessione, datiTariffaBase, concessione.oggettoPraticaPub, concessione.oggettoPraticaRifPub)
                concessione.oggettoPraticaPub = oggettoPraticaPub.id
                concessione.oggettoPraticaRifPub = oggettoPraticaPub.oggettoPraticaRif?.id ?: 0
                datiTariffaBase.oggettoPratica = oggettoPraticaPub

                salvaConcessioneOggCont(concessione, datiTariffaBase)

                if ((concessione.tariffaSec ?: 0) != 0) {

                    def datiTariffaSec = getDatiTariffa(anno, concessione.codiceTributoSec, concessione.categoriaSec, concessione.tariffaSec)

                    datiTariffaBase.codiceTributo = datiTariffaSec.codiceTributo
                    datiTariffaBase.categoria = datiTariffaSec.categoria
                    datiTariffaBase.tariffa = datiTariffaSec.tariffa
                }
            } else {

                if (concessione.praticaPub != 0) {

                    def eliminaResult = eliminaOggettoPratica(concessione.praticaPub, concessione.oggettoPraticaPub)
                    if (eliminaResult > 0) {
                        concessione.oggettoPraticaPub = 0
                        if (eliminaResult > 1) {
                            concessione.praticaPub = 0
                        }
                    }
                }
            }

            codiceTributo = datiTariffaBase.codiceTributo
            codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo

            if (codiceTributoTxt == 'TOSAP') {

                Long praticaRef = (concessione.praticaRef) ? (concessione.praticaRef as Long) : (concessione.praticaPub as Long)

                PraticaTributo praticaOcc = salvaConcessionePratica(concessione, datiTariffaBase, concessione.praticaOcc as Long, praticaRef)
                concessione.praticaOcc = praticaOcc.id
                datiTariffaBase.pratica = praticaOcc

                OggettoPratica oggettoPraticaOcc = salvaConcessioneOggPrTr(concessione, datiTariffaBase, concessione.oggettoPraticaOcc, concessione.oggettoPraticaRifOcc)
                concessione.oggettoPraticaOcc = oggettoPraticaOcc.id
                concessione.oggettoPraticaRifOcc = oggettoPraticaOcc.oggettoPraticaRif?.id ?: 0
                datiTariffaBase.oggettoPratica = oggettoPraticaOcc

                salvaConcessioneOggCont(concessione, datiTariffaBase)
            } else {

                if (concessione.praticaOcc != 0) {

                    def eliminaResult = eliminaOggettoPratica(concessione.praticaOcc, concessione.oggettoPraticaOcc)
                    if (eliminaResult > 0) {
                        concessione.oggettoPraticaOcc = 0
                        if (eliminaResult > 1) {
                            concessione.praticaOcc = 0
                        }
                    }
                }
            }

            if ((concessione.tipoTributoPratica == 'CUNI') && (concessione.praticaRef == 0)) {

                if (concessione.praticaPub != 0) {
                    concessione.praticaRef = concessione.praticaPub
                } else {
                    concessione.praticaRef = concessione.praticaOcc
                }
            }
        }
        catch (Exception ex) {

            String msg = ex?.getMessage() ?: ''

            if (msg.startsWith("ORA-20999")) {
                message += msg.substring('ORA-20999: '.length(), msg.indexOf('\n'))
                if (result < 1) result = 1
            }
            else {
                msg = ex?.getCause() ?: ''
                if (msg.startsWith("ORA-20999")) {
                    message += msg.substring('ORA-20999: '.length(), msg.indexOf('\n'))
                    if (result < 1) result = 1
                }
                else {
                    if(msg.isEmpty()) {
                        msg = ex?.toString() ?: 'UnknowException'
                    }
                    message += msg
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Elimina Oggetto_Pratica e se libera, pure la pratica.
    //		Riporta :	0, fatto nulla (non trovato)
    //					1, eliminato solo ooggetto_pratica (pratica ancora occupata)
    //					2, eliminato ooggetto_pratica e pratica relativa, se di tipoTributo non 'CUNI'
    //		Nota :		la pratica viene eliminata SOLO se non ci sono altri Oggetti_Pratica
    //					Se "eliminaPraticaQualsiasiTributo" = true, il vincolo sul tipoTributo viene ignorato
    def eliminaOggettoPratica(def praticaId, def oggettoPraticaId, Boolean eliminaPraticaQualsiasiTributo = false) {

        def result = 0

        PraticaTributo pratica = PraticaTributo.findById(praticaId)
        String tipoTributoPratica = pratica.tipoTributo?.tipoTributo ?: ''

        def oggettiPratica = pratica.oggettiPratica
        OggettoPratica oggettoPratica = oggettiPratica.find { it.id == oggettoPraticaId }

        if (oggettoPratica != null) {

            int elements = oggettiPratica.size()

            oggettiPratica.remove(oggettoPratica)
            oggettoPratica.pratica = null
            oggettoPratica.delete(failOnError: true, flush: true)
            pratica.save(failOnError: true)

            result = 1

            if (elements <= 1) {
                if ((tipoTributoPratica != 'CUNI') || eliminaPraticaQualsiasiTributo) {
                    String esitoSoppressione = denunceService.eliminaPratica(pratica)
                    if (!(esitoSoppressione.isEmpty()))
                        throw new Exception(esitoSoppressione)

                    result = 2
                }
            }
        }

        return result
    }

    // Salva oggetto della concessione
    def salvaConcessioneOggetto(concessione) {

        Oggetto oggetto = null
        Fonte fonte = null

        def conOggetto = concessione.oggetto

        if (concessione.oggettoRef > 0) {
            oggetto = Oggetto.findById(concessione.oggettoRef)
        }
        if (oggetto == null) oggetto = new Oggetto()

        // Dati principali
        oggetto.tipoOggetto = TipoOggetto.findByTipoOggetto(conOggetto.tipoOggetto)

        oggetto.descrizione = conOggetto.descrizione

        oggetto.archivioVie = ArchivioVie.findById(conOggetto.codVia)
        oggetto.indirizzoLocalita = conOggetto.nomeVia
        oggetto.numCiv = conOggetto.civico
        oggetto.suffisso = conOggetto.suffisso
        oggetto.scala = conOggetto.scala
        oggetto.piano = conOggetto.piano
        oggetto.interno = conOggetto.interno

        oggetto.sezione = conOggetto.sezione
        oggetto.foglio = conOggetto.foglio
        oggetto.numero = conOggetto.numero
        oggetto.subalterno = conOggetto.subalterno
        oggetto.zona = conOggetto.zona
        oggetto.partita = conOggetto.partita

        println"CO: ${conOggetto}"

        oggetto.latitudine = conOggetto.latitudine
        oggetto.longitudine = conOggetto.longitudine
        oggetto.aLatitudine = conOggetto.aLatitudine
        oggetto.aLongitudine = conOggetto.aLongitudine

        // Finalizza e salva
        if ((concessione.fonte ?: 0) != 0) {
            fonte = Fonte.findById(concessione.fonte)
        }
        if (fonte == null) {
            fonte = getFonteInserimentoCanoni()
        }
        oggetto.fonte = fonte

        oggetto.save(failOnError: true, flush: true)
        concessione.oggettoRef = oggetto.id

        return oggetto
    }

    // Salva la Pratica
    def salvaConcessionePratica(def concessione, def datiTariffa, Long praticaRef, Long praticaRefMaster) {

        PraticaTributo pratica = null

        String tipoRapporto
        String tipoPratica

        def conDettagli = concessione.dettagli

        Date dataVariazione = datiTariffa.dataVariazione

        Contribuente contribuente = datiTariffa.contribuente

        TipoTributo tipoTributo = null

        if (concessione.tipoTributoPratica) {
            tipoTributo = TipoTributo.findByTipoTributo(concessione.tipoTributoPratica)
        }
        if (tipoTributo == null) {
            CodiceTributo codiceTributo = datiTariffa.codiceTributo
            tipoTributo = codiceTributo?.tipoTributo
        }
        if (tipoTributo == null) {
            tipoTributo = TipoTributo.findByTipoTributo(concessione.tipoTributo)
        }
        if (tipoTributo == null) {
            throw new Exception("Errore assegnando TipoTributo")
        }

        // Se c'e' gia' una pratica ed e' di tipo CUNI la ricicla pure per riferimenti secondati
        if ((praticaRefMaster > 0) && (praticaRef == 0)) {
            pratica = PraticaTributo.findById(praticaRefMaster)
            if (pratica != null) {
                String tipoTributoRefMaster = pratica.tipoTributo?.tipoTributo
                if (tipoTributoRefMaster == 'CUNI') {
                    praticaRef = praticaRefMaster
                }
            }
        }

        if (praticaRef > 0) {
            pratica = PraticaTributo.findById(praticaRef)
        }
        if (pratica == null) {

            praticaRef = 0

            pratica = new PraticaTributo()

            tipoPratica = TipoPratica.D.tipoPratica
            tipoRapporto = 'D'

            pratica.data = dataVariazione

            if (concessione.tipoVariazione != null) {
                pratica.tipoEvento = concessione.tipoVariazione
            } else {
                switch (tipoPratica) {
                    case TipoPratica.D.tipoPratica:
                        if (concessione.dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {
                            pratica.tipoEvento = TipoEventoDenuncia.U
                        } else {
                            pratica.tipoEvento = TipoEventoDenuncia.I
                        }
                        break
                    case TipoPratica.A.tipoPratica:
                        pratica.tipoEvento = TipoEventoDenuncia.U
                        break
                    case TipoPratica.V.tipoPratica:
                        pratica.tipoEvento = TipoEventoDenuncia.U
                        break
                    default:
                        if (concessione.dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {
                            pratica.tipoEvento = TipoEventoDenuncia.U
                        } else {
                            pratica.tipoEvento = TipoEventoDenuncia.I
                        }
                        break
                }
            }

            pratica.tipoPratica = tipoPratica

            pratica.contribuente = contribuente

            RapportoTributo ratr = new RapportoTributo()
            ratr.tipoRapporto = tipoRapporto
            ratr.contribuente = contribuente
            pratica.addToRapportiTributo(ratr)

            concessione.tipoPratica = tipoPratica
            concessione.tipoRapporto = tipoRapporto
        }

        // Dati principali
        if (praticaRef == 0) {

            pratica.tipoTributo = tipoTributo
            pratica.anno = concessione.anno
        }

        pratica.numero = concessione.numeroPratica

        pratica.dataScadenza = concessione.dataScadenza

        // Dati denunciante
        pratica.denunciante = (conDettagli.denunciante != null) ? conDettagli.denunciante.toUpperCase() : null
        pratica.codFiscaleDen = (conDettagli.codFisDen != null) ? conDettagli.codFisDen.toUpperCase() : null
        pratica.partitaIvaDen = null
        pratica.indirizzoDen = (conDettagli.indirizzoDen != null) ? conDettagli.indirizzoDen.toUpperCase() : null

        if (conDettagli.codComDen != null && conDettagli.codProDen != null) {
            pratica.comuneDenunciante = Ad4ComuneTr4.createCriteria().get {
                eq('comune', conDettagli.codComDen.toInteger())
                eq('provinciaStato', conDettagli.codProDen.toLong())
            }
        }

        pratica.tipoCarica = TipoCarica.findById(conDettagli.tipoCarica)

        // Verifica versamenti
        gestisciVersamentiPratica(pratica, datiTariffa.versamenti)

        // Finalizza e salva
        pratica.motivo = conDettagli.motivo
        pratica.note = conDettagli.note
        pratica.utente = springSecurityService?.currentUser?.id

        if (concessione.dataPratica) {
            pratica.data = concessione.dataPratica
        }

        pratica.save(failOnError: true, flush: true)

        concessione.lastUpdatedPratica = pratica.lastUpdated
        concessione.utentePratica = pratica.utente

        return pratica
    }

    // Gestisce aggiornamento dei versamenti della pratica
    def gestisciVersamentiPratica(PraticaTributo pratica, List<VersamentoDTO> versamentiNew) {

        def maxSeq =
                Versamento.createCriteria().get {
                    projections {
                        max "sequenza"
                    }
                    eq("contribuente", pratica.contribuente)
                    eq("anno", pratica.anno)
                    eq("tipoTributo", pratica.tipoTributo)
                } as Short ?: 0

        List<VersamentoDTO> versamentiOld = Versamento.createCriteria().list {
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
            eq("prt.id", pratica.id)
        }.toDTO()

        pratica.versamenti?.clear()

        // Si annullano le sequenze negative, si tratta di nuovi versamenti non ancora salvati
        versamentiNew.each {
            if (it.sequenza < 0) {
                it.sequenza = null
            }
        }

        // Eliminazione dei versamenti
        versamentiOld?.each { versOld ->
            if (!versamentiNew.find { versNew -> versNew.sequenza != null && versOld.sequenza == versNew.sequenza }) {
                versOld.toDomain().delete(flush: true)
            }
        }

        // Aggiunte/modificate
        versamentiNew?.each {
            def versDaSalvare = it.toDomain()
            versDaSalvare.sequenza = versDaSalvare.sequenza ?: ++maxSeq
            versDaSalvare.save(failOnError: true, flush: true)
        }
    }

    // Salva l'oggetto tributo
    def salvaConcessioneOggPrTr(def concessione, def datiTariffa, def oggettoPraticaRef, def oggettoPraticaRifRef) {

        OggettoPratica oggettoPratica = null
        OggettoPratica oggettoPraticaRif = null
        Fonte fonte = null

        def conOggetto = concessione.oggetto

        CodiceTributo codiceTributo = datiTariffa.codiceTributo
        Categoria categoria = datiTariffa.categoria
        Tariffa tariffa = datiTariffa.tariffa

        String codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo

        PraticaTributo pratica = datiTariffa.pratica
        Oggetto oggetto = datiTariffa.oggetto

        if (oggettoPraticaRef > 0) {
            oggettoPratica = OggettoPratica.findById(oggettoPraticaRef)
        }
        if (oggettoPratica == null) {

            oggettoPratica = new OggettoPratica()

            oggettoPratica.oggetto = oggetto
            oggettoPratica.pratica = pratica
        }
        if (oggettoPraticaRifRef > 0) {
            oggettoPraticaRif = OggettoPratica.findById(oggettoPraticaRifRef)
        }

        // Dati principali
        oggettoPratica.anno = concessione.anno
        oggettoPratica.tipoOggetto = TipoOggetto.findByTipoOggetto(conOggetto.tipoOggetto)

        oggettoPratica.codiceTributo = codiceTributo

        oggettoPratica.categoria = categoria
        oggettoPratica.tipoCategoria = categoria.categoria

        oggettoPratica.tariffa = tariffa
        oggettoPratica.tipoTariffa = tariffa.tipoTariffa

        oggettoPratica.tipoOccupazione = listaTipiOccupazione.find {
            it.tipoOccupazione == concessione.dettagli.tipoOccupazione
        }

        oggettoPratica.flagContenzioso = concessione.esenzione ?: false

        oggettoPratica.oggettoPraticaRendita = null
        oggettoPratica.categoriaCatasto = null

        oggettoPratica.numOrdine = null
        oggettoPratica.immStorico = false
        oggettoPratica.classeCatasto = null
        oggettoPratica.valore = null

        oggettoPratica.flagProvvisorio = false
        oggettoPratica.flagValoreRivalutato = false
        oggettoPratica.flagFirma = false
        oggettoPratica.flagUipPrincipale = false
        oggettoPratica.flagDomicilioFiscale = false

        oggettoPratica.indirizzoOcc = (conOggetto.localita != null) ? conOggetto.localita.toUpperCase() : null

        oggettoPratica.daChilometro = conOggetto.daKM
        oggettoPratica.aChilometro = conOggetto.aKM
        oggettoPratica.lato = (conOggetto.lato != null) ? conOggetto.lato.toUpperCase() : null

        if (conOggetto.codCom != null && conOggetto.codPro != null) {
            Ad4ComuneTr4 comune = Ad4ComuneTr4.createCriteria().get {
                eq('comune', conOggetto.codCom.toInteger())
                eq('provinciaStato', conOggetto.codPro.toLong())
            }

            oggettoPratica.codProOcc = comune.provinciaStato as Short
            oggettoPratica.codComOcc = comune.comune
        }

        oggettoPratica.oggettoPraticaRif = oggettoPraticaRif

        // Da verificare

        //	oggettoPratica.oggettoPraticaRifV = null
        //	oggettoPratica.oggettoPraticaRifAp = null

        //	String titolo
        //	String estremiTitolo
        //	Short modello
        //	BigDecimal locale
        //	BigDecimal coperta
        //	BigDecimal scoperta

        //	BigDecimal reddito

        //	BigDecimal impostaBase
        //	BigDecimal impostaDovuta

        //	Short codProOcc
        //	Short codComOcc
        //	String indirizzoOcc

        //	Short tipoQualita
        //	String qualita

        //	TitoloOccupazione titoloOccupazione
        //	NaturaOccupazione naturaOccupazione
        //	DestinazioneUso destinazioneUso
        //	AssenzaEstremiCatasto assenzaEstremiCatasto

        //	Date dataAnagrafeTributaria
        //	Short numeroFamiliari

        def dettagli = concessione.dettagli

        oggettoPratica.inizioConcessione = dettagli.inizioConcessione
        oggettoPratica.fineConcessione = dettagli.fineConcessione
        oggettoPratica.numConcessione = dettagli.numeroConcessione
        oggettoPratica.dataConcessione = dettagli.dataConcessione
        oggettoPratica.flagNullaOsta = dettagli.flagNullaOsta

        // Dati tributi
        if (codiceTributoTxt == 'ICP') {

            def dati = concessione.pubblicita

            oggettoPratica.quantita = dati.quantita
            oggettoPratica.larghezza = dati.larghezza
            oggettoPratica.profondita = dati.profondita
            oggettoPratica.consistenzaReale = dati.consistenzaReale
            oggettoPratica.consistenza = dati.consistenza

            oggettoPratica.note = dati.note
        }

        if (codiceTributoTxt == 'TOSAP') {

            def dati = concessione.occupazione

            oggettoPratica.quantita = dati.quantita
            oggettoPratica.larghezza = dati.larghezza
            oggettoPratica.profondita = dati.profondita
            oggettoPratica.consistenzaReale = dati.consistenzaReale
            oggettoPratica.consistenza = dati.consistenza

            oggettoPratica.note = dati.note
        }

        // Finalizza e salva
        if ((concessione.fonte ?: 0) != 0) {
            fonte = Fonte.findById(concessione.fonte)
        }
        if (fonte == null) {
            fonte = getFonteInserimentoCanoni()
        }
        oggettoPratica.fonte = fonte

        oggettoPratica.save(failOnError: true, flush: true)

        return oggettoPratica
    }

    // Salva l'oggetto tributo
    def salvaConcessioneOggCont(def concessione, def datiTariffa) {

        OggettoContribuente oggettoContribuente = null
        String tipoRapportoPreDef = "D"

        String tipoRapporto = concessione.tipoRapporto ?: ''
        if (tipoRapporto.isEmpty()) tipoRapporto = tipoRapportoPreDef

        PraticaTributo praticaTributo = datiTariffa.pratica
        CodiceTributo codiceTributo = datiTariffa.codiceTributo
        OggettoPratica oggettoPratica = datiTariffa.oggettoPratica
        Contribuente contribuente = datiTariffa.contribuente

        String codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo

        oggettoContribuente = oggettoPratica.oggettiContribuente.find { it.contribuente.codFiscale == contribuente.codFiscale && it.tipoRapporto == tipoRapportoPreDef }
        if (oggettoContribuente == null) {
            oggettoContribuente = new OggettoContribuente()

            oggettoContribuente.contribuente = contribuente
            oggettoContribuente.tipoRapporto = tipoRapporto
            oggettoContribuente.oggettoPratica = oggettoPratica
        }

        // Dati principali
        oggettoContribuente.anno = concessione.anno

        oggettoContribuente.note = null

        def dettagli = concessione.dettagli

        if (praticaTributo.tipoEvento == TipoEventoDenuncia.C) {

            oggettoContribuente.dataDecorrenza = null
            oggettoContribuente.dataCessazione = concessione.dataVariazione

            oggettoContribuente.fineOccupazione = dettagli.fineOccupazione ?: concessione.dataVariazione
        } else {

            oggettoContribuente.dataDecorrenza = dettagli.dataDecorrenza
            oggettoContribuente.dataCessazione = dettagli.dataCessazione

            oggettoContribuente.inizioOccupazione = dettagli.inizioOccupazione
            oggettoContribuente.fineOccupazione = dettagli.fineOccupazione
        }

        // Dati tariffa
        oggettoContribuente.percDetrazione = concessione.percentualeDetr

        // Dati tributi
        if (codiceTributoTxt == 'ICP') {

            def dati = concessione.pubblicita
        }

        if (codiceTributoTxt == 'TOSAP') {

            def dati = concessione.occupazione

            oggettoContribuente.percPossesso = dati.percentualePoss
        }

        // Da verificare

        //	BigDecimal percDetrazione
        //	Short mesiOccupato
        //	Short mesiOccupato1sem
        //	Short mesiPossesso
        //	Short mesiPossesso1sem
        //	Short mesiEsclusione
        //	Short mesiRiduzione
        //	Short mesiAliquotaRidotta
        //	BigDecimal detrazione
        //	boolean flagPossesso
        //	boolean flagRiduzione
        //	boolean flagAbPrincipale
        //	boolean flagAlRidotta
        //	Long successione
        //	Integer progressivoSudv
        //	String tipoRapportoK
        //	OggettoPratica oggettoPraticaId
        //	Short daMesePossesso

        // Finalizza e salva
        oggettoContribuente.save(failOnError: true, flush: true)

        concessione.lastUpdatedOggetto = oggettoContribuente.lastUpdated

        return oggettoContribuente
    }

    // Ricava dati della tariffa
    def getDatiTariffa(def anno, def codTributo, def codCategoria, def tipoTariffa, Boolean verificaCUNI = false) {

        CodiceTributo codiceTributo = null
        Categoria categoria = null
        Tariffa tariffa = null

        def datiTariffa = [:]

        codiceTributo = CodiceTributo.findById(codTributo)
        if (codiceTributo == null) {
            throw new Exception("Codice Tributo non trovato")
        }
        if (verificaCUNI) {
            if (codiceTributo.tipoTributo.tipoTributo != 'CUNI') {
                throw new Exception("Tariffa non valida per Canone Unico, anno ${anno}")
            }
        }
        datiTariffa.codiceTributo = codiceTributo

        def categorie = Categoria.createCriteria().list {
            eq("codiceTributo.id", codTributo)
            eq("categoria", codCategoria as Short)
        }
        if (categorie.size() == 1) categoria = categorie[0]
        if (categoria == null) {
            throw new Exception("Categoria non trovata")
        }
        datiTariffa.categoria = categoria

        def tariffe = Tariffa.createCriteria().list {
            eq("categoria.id", categoria.id)
            eq("tipoTariffa", tipoTariffa as short)
            eq("anno", anno)
        }
        if (tariffe.size() == 1) tariffa = tariffe[0]
        if (tariffa == null) {
            throw new Exception("Tariffa non trovata per l'anno ${anno}")
        }
        datiTariffa.tariffa = tariffa

        //	println "CodTributo : ${codTributo}"
        //	println "CodCategoria : ${codCategoria}"
        //	println "TipoTariffa : ${tipoTariffa}"
        //	println "Tariffa : ${tariffa.descrizione}"

        return datiTariffa
    }

    // Verifica se eliminabile
    def concessioneEliminabile(def concessione) {

        PraticaTributo pratica
        String esito

        String message = ""
        Integer result = 0

        if (concessione.praticaPub != 0) {

            pratica = PraticaTributo.findById(concessione.praticaPub)
            esito = denunceService.eliminabile(pratica)
            if (!esito.isEmpty()) {
                if (!message.isEmpty()) message += "\n\n"
                message += esito
                if (result < 2) result = 2
            }
        }
        if (concessione.praticaOcc != 0) {

            pratica = PraticaTributo.findById(concessione.praticaOcc)
            esito = denunceService.eliminabile(pratica)
            if (!esito.isEmpty()) {
                if (!message.isEmpty()) message += "\n\n"
                message += esito
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina dichiarazione
    def eliminaDichiarazione(def concessione) {

        PraticaTributo pratica
        String esito

        String message = ""
        Integer result = 0

        try {
            pratica = PraticaTributo.findById(concessione.praticaRef)

            if (pratica == null) {
                throw new Exception("Pratica Tributo non trovata")
            }

            esito = denunceService.eliminaPratica(pratica)
            if (!(esito.isEmpty()))
                throw new Exception(esito)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina concessione
    def eliminaConcessione(def concessione) {

        String esito
        Boolean eliminaPratica

        String message = ""
        Integer result = 0

        try {
            PraticaTributo pratica

            if (concessione.praticaPub != 0) {

                eliminaPratica = (concessione.praticaPub != concessione.praticaOcc)

                def eliminaResult = eliminaOggettoPratica(concessione.praticaPub, concessione.oggettoPraticaPub, eliminaPratica)
                if (eliminaResult > 0) {
                    concessione.praticaPub = 0
                    concessione.oggettoPraticaPub = 0
                }
            }
            if (concessione.praticaOcc != 0) {

                eliminaPratica = true

                def eliminaResult = eliminaOggettoPratica(concessione.praticaOcc, concessione.oggettoPraticaOcc, eliminaPratica)
                if (eliminaResult > 0) {
                    concessione.praticaOcc = 0
                    concessione.oggettoPraticaOcc = 0
                }
            }

            if (concessione.oggettoRef != 0) {

                //			oggettiService.eliminaOggetto(concessione.oggettoRef as Long)
                //			concessione.oggettoRef = 0;
            }
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Reimposta decorrenza su concessione
    def reimpostaDecorrenza(def concessione, def annoNuovo) {

        if (concessione.dettagli.tipoOccupazione == TipoOccupazione.T.tipoOccupazione) {

            concessione.dettagli.dataDecorrenza = getDataOdierna()

            concessione.dettagli.inizioOccupazione = concessione.dettagli.dataDecorrenza
            concessione.dettagli.fineOccupazione = null
        } else {

            Calendar today = getDataOdierna(true)

            if (concessione.anno != annoNuovo) {
                today.set(Calendar.YEAR, annoNuovo)
                today.set(Calendar.DAY_OF_YEAR, 1)
                today.add(Calendar.DAY_OF_MONTH, -1)
            }

            concessione.dettagli.dataDecorrenza = today.getTime()

            if (concessione.dettagli.inizioOccupazione == null) {

                today.add(Calendar.DAY_OF_MONTH, 1)
                concessione.dettagli.inizioOccupazione = today.getTime()
                concessione.dettagli.fineOccupazione = null
            }
        }

        concessione.dettagli.dataCessazione = null

        concessione.anno = annoNuovo
    }

    // Riporta data odierna - mezzanotte
    def getDataOdierna(boolean asCalendar = false) {

        Calendar today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)

        if (!asCalendar) {
            return today.getTime()
        }

        return today
    }

    // Riporta data fine anno - mezzanotte
    def getChiusuraAnno(int anno) {

        Short annoNow

        Calendar today = Calendar.getInstance()

        if ((anno > -100) && (anno < 100)) {

            annoNow = today.get(Calendar.YEAR) + anno
        } else {
            annoNow = anno
        }

        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)

        today.set(Calendar.MONTH, Calendar.DECEMBER)
        today.set(Calendar.DAY_OF_MONTH, 31)
        today.set(Calendar.YEAR, annoNow)

        return today
    };

    // Ricava giornate di validità della concessione
    def getGiornateConcessione(def concessione) {

        def giornate = null

        def dataDecorrenza = concessione.dettagli.dataDecorrenza
        def dataCessazione = concessione.dettagli.dataCessazione

        if ((dataDecorrenza != null) && (dataCessazione != null)) {

            float daysBetween = dataCessazione - dataDecorrenza
            giornate = (long) Math.floor(daysBetween + 1.0f)
        }

        return giornate
    }

    // Esporta i dati dei canoni in xlsx
    def canoniToXls(def annoTributo, def listaConcessioni, def paramsFileNameGenerator, boolean datiContribuente) {

        String etichettaCategoria

        if ((annoTributo < '2021') || (annoTributo == 'Tutti')) {
            etichettaCategoria = 'Categoria/Zona'
        } else {
            etichettaCategoria = 'Zona'
        }

        def fields = [
                'statoDepag': 'Depag',
        ]

        if (datiContribuente) {
            fields << [
                    'cognomeNome' : 'Cognome e Nome',
                    'contribuente': 'Codice Fiscale',
            ]
        }

        fields << [
                'oggettoRef'                   : 'Oggetto',
                'oggetto.descrizione'          : 'Descrizione',
                'indirizzoOgg'                 : 'Indirizzo',

                'oggetto.daKM'                 : 'Da KM',
                'oggetto.aKM'                  : 'A KM',
                'oggetto.lato'                 : 'Lato',

                'oggetto.latSessages'          : 'Latitudine',
                'oggetto.lonSessages'          : 'Longitudine',
                'oggetto.geoLocationURL'       : 'Geolocalizzazione',

                'tempDenComFull'               : 'Comune',
                'oggetto.localita': 'Localita\'',
                'oggetto.sezione'              : 'Sez.',
                'oggetto.foglio'               : 'Fgl.',
                'oggetto.numero'               : 'Num.',
                'oggetto.subalterno'           : 'Sub.',

                'dettagli.numeroConcessione'   : 'Num. Concessione',
                'dettagli.dataConcessione'     : 'Data Concessione',
                'dettagli.flagNullaOsta'       : 'Nulla Osta',

                'dettagli.dataDecorrenza'      : 'Decorrenza',
                'dettagli.dataCessazione'      : 'Cessazione',

                'codiceTributo'                : 'Codice Tributo',
                'categoriaDescr'               : etichettaCategoria,
                'tariffaDescr'                 : 'Tipologia',
                'dettagli.tipoOccupazione'     : 'Occ.',
                'esenzione'                    : 'Es.',

                'occupazione.quantita'         : 'Quantita\'',
                'occupazione.larghezza'        : 'Larghezza',
                'occupazione.profondita'       : 'Profondita\'',
                'occupazione.consistenzaReale' : 'Sup. Reale',
                'occupazione.consistenza'      : 'Superficie',

                'pubblicita.quantita'          : 'Quantita\'',
                'pubblicita.larghezza'         : 'L (m)',
                'pubblicita.profondita'        : 'H (m)',
                'pubblicita.consistenzaReale'  : 'Sup. Reale',
                'pubblicita.consistenza'       : 'Superficie',

                'anno'                         : 'Anno',
                'dataPratica'                  : 'Data',
                'dataScadenza'                 : 'Scadenza'
        ]

        def formatters = [
                "anno"                         : Converters.decimalToInteger,
                "oggettoRef"                   : Converters.decimalToInteger,

                "esenzione"                    : { s -> s ? 'E' : '' },

                "oggetto.daKM"                 : Converters.decimalToDouble,
                "oggetto.aKM"                  : Converters.decimalToDouble,

                "tempDenComFull"               : { e -> (e.oggetto.denCom ?: '') + (e.oggetto.sigPro ? " (${e.oggetto.sigPro})" : '') },

                "dettagli.numeroConcessione"   : Converters.decimalToInteger,
                "occupazione.quantita"         : Converters.decimalToInteger,

                "occupazione.larghezza"        : Converters.decimalToDouble,
                "occupazione.profondita"       : Converters.decimalToDouble,
                "occupazione.consistenzaReale" : Converters.decimalToDouble,
                "occupazione.consistenza"      : Converters.decimalToDouble,
                "dettagli.flagNullaOsta"       : Converters.flagBooleanToString,

                "pubblicita.larghezza"         : Converters.decimalToDouble,
                "pubblicita.profondita"        : Converters.decimalToDouble,
                "pubblicita.consistenzaReale"  : Converters.decimalToDouble,
                "pubblicita.consistenza"       : Converters.decimalToDouble,

                "statoDepag"                   : { s -> s?.value?.descrizione }
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CANONI,
                paramsFileNameGenerator)

        XlsxExporter.exportAndDownload(nomeFile, listaConcessioni as List, fields, formatters)
    }

    // Ricava tipo occupazione da tipo evento pratica
    def tipoOccupazioneDaPratica(PraticaTributoDTO pratica) {

        def tipoOccupazione = null

        switch (pratica.tipoPratica) {
            case TipoPratica.D.tipoPratica:
                if (pratica?.tipoEvento) {
                    if (pratica.tipoEvento == TipoEventoDenuncia.U) {
                        tipoOccupazione = TipoOccupazione.T.tipoOccupazione
                    } else {
                        tipoOccupazione = TipoOccupazione.P.tipoOccupazione
                    }
                }
                break
            default:
                break
        }

        return tipoOccupazione
    }

    // Determina zona da via e civico
    def determinaZonaOggetto(def associazioniVie, def oggetto) {

        def codiceZona = null
        def sequenzaZona = null

        def codVia = oggetto.codVia
        def associazioniVia = associazioniVie.findAll { it.codVia == codVia }

        if (associazioniVia.size() > 0) {

            def civico = oggetto.civico
            def civicoMatch = (civico ?: 0) as Integer

            def associazione = null

            if (civicoMatch != 0) {        // Il civico ha precedenza sempre e comunque

                if ((civicoMatch % 2) == 0) {
                    associazione = associazioniVia.find { it.daNumCiv <= civicoMatch && it.aNumCiv >= civicoMatch && it.flagPari != false }
                } else {
                    associazione = associazioniVia.find { it.daNumCiv <= civicoMatch && it.aNumCiv >= civicoMatch && it.flagDispari != false }
                }
            }
            else {

                if (oggetto.daKM != null) {

                    Double daKM = (oggetto.daKM ?: 0.0) as Double
                    String lato = (oggetto.lato ?: 'E') as String

                    associazione = associazioniVia.find { it.daKM <= daKM && it.aKM >= daKM && it.latoNotNull in ['E', lato] }
                }
                else {
                    associazione = associazioniVia.find { it.sequenza == 1 }
                }
            }

            if (associazione != null) {
                codiceZona = associazione.codZona
                sequenzaZona = associazione.sequenzaZona
            }
        }

        return [codiceZona: codiceZona, sequenzaZona: sequenzaZona]
    }

    // Legge associazionivia zona
    def getAssociazioniVieZona(def filtri) {

        def filtroZone = [:]

        if (filtri?.codiceZona) {
            filtroZone << [daCodice: filtri.codiceZona]
            filtroZone << [aCodice: filtri.codiceZona]
        }

        def elencoZone = getElencoZone(filtroZone)

        def query = """
        SELECT avz
        FROM ArchivioVieZona as avz
            INNER JOIN FETCH avz.archivioVie as av
        WHERE
            1=1
        """

        def parameters = [:]

        if (filtri?.daCodice) {
            query += ' AND  av.id >= :p_daCodice '
            parameters << ['p_daCodice': filtri.daCodice as Long]
        }
        if (filtri?.aCodice) {
            query += ' AND  av.id <= :p_aCodice '
            parameters << ['p_aCodice': filtri.aCodice as Long]
        }
        if (filtri?.daSequenza) {
            query += ' AND  sequenza >= :p_daSequenza '
            parameters << ['p_daSequenza': filtri.daSequenza as Short]
        }
        if (filtri?.aSequenza) {
            query += ' AND  sequenza <= :p_aSequenza '
            parameters << ['p_aSequenza': filtri.aSequenza as Short]
        }
        if (filtri?.denomUff) {
            query += " AND lower(av.denomUff) like lower(:p_denomUff)"
            parameters << ['p_denomUff': filtri.denomUff]
        }
        if (filtri?.daDaNumCiv) {
            query += ' AND avz.daNumCiv >= :p_daDaNumCiv '
            parameters << ['p_daDaNumCiv': filtri.daDaNumCiv as Integer]
        }
        if (filtri?.aDaNumCiv) {
            query += ' AND avz.daNumCiv <= :p_aDaNumCiv '
            parameters << ['p_aDaNumCiv': filtri.aDaNumCiv as Integer]
        }
        if (filtri?.daANumCiv) {
            query += ' AND avz.aNumCiv >= :p_daANumCiv '
            parameters << ['p_daANumCiv': filtri.daANumCiv]
        }
        if (filtri?.aANumCiv) {
            query += ' AND avz.aNumCiv <= :p_aANumCiv '
            parameters << ['p_aANumCiv': filtri.aANumCiv]
        }
        if (filtri.flagPari != null) {
            query += ' AND avz.flagPari is ' + (filtri.flagPari ? 'true' : 'null')
        }
        if (filtri.flagDispari != null) {
            query += ' AND avz.flagDispari is ' + (filtri.flagDispari ? 'true' : 'null')
        }
        if (filtri?.daDaChilometro) {
            query += ' AND avz.daChilometro >= :p_daDaChilometro '
            parameters << ['p_daDaChilometro': filtri.daDaChilometro as Double]
        }
        if (filtri?.aDaChilometro) {
            query += ' AND avz.daChilometro <= :p_aDaChilometro '
            parameters << ['p_aDaChilometro': filtri.aDaChilometro as Double]
        }
        if (filtri?.daAChilometro) {
            query += ' AND avz.aChilometro >= :p_daAChilometro '
            parameters << ['p_daAChilometro': filtri.daAChilometro as Double]
        }
        if (filtri?.aAChilometro) {
            query += ' AND avz.aChilometro <= :p_aAChilometro '
            parameters << ['p_aAChilometro': filtri.aAChilometro as Double]
        }
        if (filtri?.lato) {
            if (filtri.lato == 'E') {
                query += " AND (avz.lato IS NULL OR avz.lato = 'E') "
            } else {
                query += ' AND avz.lato = :p_lato '
                parameters << ['p_lato': filtri.lato]
            }
        }
        if (filtri?.anno) {
            query += ' AND (avz.daAnno IS NULL OR avz.daAnno = :p_anno) AND (avz.aAnno IS NULL OR avz.aAnno = :p_anno) '
            parameters << ['p_anno': filtri.anno as Short]
        } else {
            if (filtri?.daDaAnno) {
                query += ' AND avz.daAnno >= :p_daDaAnno '
                parameters << ['p_daDaAnno': filtri.daDaAnno as Short]
            }
            if (filtri?.aDaAnno) {
                query += ' AND avz.daAnno <= :p_aDaAnno '
                parameters << ['p_aDaAnno': filtri.aDaAnno as Short]
            }
            if (filtri?.daAAnno) {
                query += ' AND avz.aAnno >= :p_daAAnno '
                parameters << ['p_daAAnno': filtri.daAAnno as Short]
            }
            if (filtri?.aAAnno) {
                query += ' AND avz.aAnno <= :p_aAAnno '
                parameters << ['p_aAAnno': filtri.aAAnno as Short]
            }
        }
        if (filtri?.codiceZona) {
            query += ' AND avz.codZona = :p_codiceZona '
            parameters << ['p_codiceZona': filtri.codiceZona as Short]
        }
        if (filtri?.sequenzaZona) {
            query += ' AND avz.sequenzaZona = :p_sequenzaZona '
            parameters << ['p_sequenzaZona': filtri.sequenzaZona as Short]
        }

        def vieZona = []

        List<ArchivioVieZonaDTO> vieZonaDTO = ArchivioVieZona.executeQuery(query, parameters).toDTO(['archivioVie'])

        vieZonaDTO.sort { a, b ->
            b.archivioVie.id <=> a.archivioVie.id ?: b.sequenza <=> a.sequenza
        }

        def lati = getListaLati().collectEntries { [(it.codice): it.descrizione] }
        vieZonaDTO.each {
            def viaZona = [:]

            def zona = elencoZone.find { zona -> (zona.codZona == it.codZona) && (zona.sequenza == it.sequenzaZona) }
            if (!zona) {
                return
            }

            viaZona.dto = it
            viaZona.codVia = it.archivioVie.id
            viaZona.sequenza = it.sequenza
            viaZona.denomUff = it.archivioVie.denomUff
            viaZona.daNumCiv = (it.daNumCiv ?: Integer.MIN_VALUE) as Integer
            viaZona.aNumCiv = (it.aNumCiv ?: Integer.MAX_VALUE) as Integer
            viaZona.flagPari = it.flagPari
            viaZona.flagDispari = it.flagDispari
            viaZona.daKM = (it.daChilometro ?: -Double.MAX_VALUE) as Double
            viaZona.aKM = (it.aChilometro ?: Double.MAX_VALUE) as Double
            viaZona.lato = it.lato
            viaZona.latoNotNull = it.lato ?: 'E'
            viaZona.latoDescr = lati[it.lato]
            viaZona.daAnno = it.daAnno
            viaZona.aAnno = it.aAnno
            viaZona.codZona = zona.codZona
            viaZona.sequenzaZona = zona.sequenza
            viaZona.denomZona = zona.denominazione

            vieZona << viaZona
        }

        return vieZona
    }

    // Esegue verifica su dati della ViaZona e crea messaggio di avvertimento
    def verificaViaZona(ArchivioVieZonaDTO viaZona) {

        String message = ""
        Integer result = 0

        // Dati base
        if (viaZona.archivioVie == null) {
            message += "Via non specificata\n"
        }

        if (viaZona.codZona == null) {
            message += "Zona non specificata\n"
        }

        if (viaZona.daNumCiv != null &&
                viaZona.aNumCiv != null &&
                viaZona.daNumCiv > viaZona.aNumCiv) {
            message += "A Civico non valido, indicare un valore maggiore o uguale a Da Civico oppure lasciare vuoto\n"
        }

        def daCivico = viaZona.daNumCiv ?: 0
        def aCivico = viaZona.aNumCiv ?: 0

        if ((daCivico < 0) || (daCivico > 999999)) {
            message += "Da Civico non valido, indicare un valore tra 0 e 999999 oppure lasciare vuoto!\n"
        }
        if ((aCivico < 0) || (aCivico > 999999)) {
            message += "A Civico non valido, indicare un valore tra 0 e 999999 oppure lasciare vuoto!\n"
        }

        if (viaZona.daChilometro != null &&
                viaZona.aChilometro != null &&
                viaZona.daChilometro > viaZona.aChilometro) {
            message += "A KM non valido, indicare un valore maggiore o uguale a Da KM oppure lasciare vuoto\n"
        }

        def daKM = viaZona.daChilometro ?: 0.0
        def aKM = viaZona.aChilometro ?: 0.0

        if ((daKM < 0.0) || (daKM > 9999.9999)) {
            message += "Da KM non valido, indicare un valore tra 0.0 e 9999.9999 oppure lasciare vuoto!\n"
        }
        if ((aKM < 0.0) || (daKM > 9999.9999)) {
            message += "A KM non valido, indicare un valore tra 0.0 e 9999.9999 oppure lasciare vuoto!\n"
        }

        def daAnno = viaZona.daAnno ?: 1900
        def aAnno = viaZona.aAnno ?: 2099

        if ((daAnno < 1900) || (daAnno >= 2099)) {
            message += "Da Anno non valido, indicare un valore tra 1900 e 2099 oppure lasciare vuoto!\n"
        } else {
            if (aAnno < daAnno) {
                message += "Ad Anno non valido, indicare un valore maggiore o uguale a Da Anno ed inferiore a 2099 oppure lasciare vuoto\n"
            }
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Salva la ViaZona
    def salvaViaZona(ArchivioVieZonaDTO viaZonaDTO) {

        String message = ''
        Integer result = 0

        try {
            ArchivioVieZona viaZonaSalva = viaZonaDTO.getDomainObject()
            if (viaZonaSalva == null) {

                Short sequenza = viaZonaDTO.sequenza

                if ((sequenza ?: (short) 0) == (short) 0) {
                    sequenza = getNuovaSequenzaViaZona(viaZonaDTO) as Short
                }

                viaZonaSalva = new ArchivioVieZona()

                viaZonaSalva.archivioVie = viaZonaDTO.archivioVie.getDomainObject()
                viaZonaSalva.sequenza = sequenza
            }

            viaZonaSalva.daNumCiv = viaZonaDTO.daNumCiv
            viaZonaSalva.aNumCiv = viaZonaDTO.aNumCiv
            viaZonaSalva.flagPari = viaZonaDTO.flagPari
            viaZonaSalva.flagDispari = viaZonaDTO.flagDispari
            viaZonaSalva.daChilometro = viaZonaDTO.daChilometro
            viaZonaSalva.aChilometro = viaZonaDTO.aChilometro
            viaZonaSalva.lato = viaZonaDTO.lato
            viaZonaSalva.daAnno = viaZonaDTO.daAnno
            viaZonaSalva.aAnno = viaZonaDTO.aAnno

            viaZonaSalva.codZona = viaZonaDTO.codZona
            viaZonaSalva.sequenzaZona = viaZonaDTO.sequenzaZona

            viaZonaSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina la Scadenza
    def eliminaViaZona(ArchivioVieZonaDTO viaZonaDTO) {

        String message = ''
        Integer result = 0

        ArchivioVieZona viaZonaSalva = viaZonaDTO.getDomainObject()
        if (viaZonaSalva == null) {

            message = "Associazione Via/Zona non registrata in banca dati "
            result = 2
        } else {

            try {
                viaZonaSalva.delete(flush: true)
            }
            catch (Exception e) {

                if (e?.message?.startsWith("ORA-20999")) {
                    message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                    message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else {
                    message += e.message
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Ricava nuovo numero sequenza per la ViaZona
    def getNuovaSequenzaViaZona(ArchivioVieZonaDTO viaZona) {

        Short sequenza = 0

        def filtri = [:]

        filtri << ['codVia': viaZona.archivioVie.id]

        String sql = """
				SELECT
					MAX(ARVZ.SEQUENZA) AS ULTIMA_SEQ
				FROM
					ARCHIVIO_VIE_ZONA ARVZ
				WHERE
					ARVZ.COD_VIA = :codVia
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        sequenza = (totali.ULTIMA_SEQ ?: 0) as Short

        return sequenza + 1
    }

    // Esegue verifica su dati della Zona e crea messaggio di avvertimento
    def verificaZona(ArchivioVieZoneDTO zona) {

        String message = ""
        Integer result = 0

        // Dati base
        Short codZona = zona.codZona ?: 0
        if ((codZona <= 0) || (codZona > 99)) {
            message += "Codice non valido, specificare un valore compreso tra 1 e 99\n"
        }

        String denominazione = zona.denominazione ?: ''
        def denomSize = denominazione.size()

        if ((denomSize < 3) || (denomSize > 60)) {
            message += "Denominazione non valida, specificare un valore con lunghezza compresa tra 3 e 60 caratteri\n"
        }

        def daAnno = zona.daAnno ?: 1900
        def aAnno = zona.aAnno ?: 2099

        if ((daAnno < 1900) || (daAnno >= 2099)) {
            message += "Da Anno non valido, indicare un valore tra 1900 e 2099 oppure lasciare vuoto!\n"
        } else {
            if (aAnno < daAnno) {
                message += "Ad Anno non valido, indicare un valore maggiore o uguale a Da Anno ed inferiore a 2099 oppure lasciare vuoto\n"
            }
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Salva la Zona
    def salvaZona(ArchivioVieZoneDTO zonaDTO) {

        String message = ''
        Integer result = 0

        try {
            ArchivioVieZone zonaSalva = zonaDTO.getDomainObject()
            if (zonaSalva == null) {

                Short sequenza = zonaDTO.sequenza

                if ((sequenza ?: (short) 0) == (short) 0) {
                    sequenza = getNuovaSequenzaZona(zonaDTO) as Short
                }

                zonaSalva = new ArchivioVieZone()

                zonaSalva.codZona = zonaDTO.codZona
                zonaSalva.sequenza = sequenza
            }

            zonaSalva.denominazione = zonaDTO.denominazione
            zonaSalva.daAnno = zonaDTO.daAnno
            zonaSalva.aAnno = zonaDTO.aAnno

            zonaSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina la Scadenza
    def eliminaZona(ArchivioVieZoneDTO zonaDTO) {

        String message = ''
        Integer result = 0

        ArchivioVieZone zonaSalva = zonaDTO.getDomainObject()
        if (zonaSalva == null) {

            message = "Zona non registrata in banca dati "
            result = 2

            return [result: result, message: message]
        }

        def associazioneVieZona = getAssociazioniVieZona([
                codiceZona  : zonaSalva.codZona,
                sequenzaZona: zonaSalva.sequenza
        ])
        if (associazioneVieZona.size() > 0) {
            message = "Esistono vie associate a questa zona"
            result = 2

            return [result: result, message: message]
        }

        try {
            zonaSalva.delete(flush: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Verifica se Zona eliminabile
    def checkZonaEliminabile(ArchivioVieZoneDTO zona) {

        return ''
    }

    // Ricava nuovo numero sequenza per la Zona
    def getNuovaSequenzaZona(ArchivioVieZoneDTO zona) {

        Short sequenza = 0

        def filtri = [:]

        filtri << ['codZona': zona.codZona]

        String sql = """
				SELECT
					MAX(ARVZ.SEQUENZA) AS ULTIMA_SEQ
				FROM
					ARCHIVIO_VIE_ZONE ARVZ
				WHERE
					ARVZ.COD_ZONA = :codZona
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        sequenza = (totali.ULTIMA_SEQ ?: 0) as Short

        return sequenza + 1
    }

    def getListaLati() {
        return [[codice: null, descrizione: ""],
                [codice: 'E', descrizione: "E - Entrambe"],
                [codice: 'S', descrizione: "S - Sinistra"],
                [codice: 'D', descrizione: "D - Destra"]]
    }

    // Legge elenco delle zone
    def getElencoZone(def filtri) {

        List<ArchivioVieZoneDTO> listaZoneDTO

        listaZoneDTO = ArchivioVieZone.createCriteria().list {
            if (filtri?.daCodice) {
                ge('codZona', filtri.daCodice as Short)
            }
            if (filtri?.aCodice) {
                le('codZona', filtri.aCodice as Short)
            }
            if (filtri?.denominazione) {
                ilike('denominazione', filtri.denominazione)
            }
            if (filtri?.anno) {
                or {
                    isNull('daAnno')
                    le('daAnno', filtri.anno as Short)
                }
                or {
                    isNull('aAnno')
                    ge('aAnno', filtri.anno as Short)
                }
            } else {
                if (filtri?.daDaAnno) {
                    ge('daAnno', filtri.daDaAnno as Short)
                }
                if (filtri?.aDaAnno) {
                    le('daAnno', filtri.aDaAnno as Short)
                }
                if (filtri?.daAAnno) {
                    ge('aAnno', filtri.daAAnno as Short)
                }
                if (filtri?.aAAnno) {
                    le('aAnno', filtri.aAAnno as Short)
                }
            }
        }.toDTO().sort { a, b ->
            b.codZona <=> a.codZona ?: a.sequenza <=> b.sequenza
        }

        def zone = []

        listaZoneDTO.each {

            def zona = [:]

            zona.dto = it

            zona.codZona = it.codZona
            zona.sequenza = it.sequenza
            zona.denominazione = it.denominazione
            zona.daAnno = it.daAnno
            zona.aAnno = it.aAnno

            zone << zona
        }

        return zone
    }

    // Legge elenco delle conversion di tariffa
    def getConversioniTariffa(Integer annoOrigine, String tipoTributo, Integer annoDestinazione) {

        String sql = ""

        def filtri = [:]

        filtri << ['annoOrigine': annoOrigine]
        filtri << ['tipoTributo': tipoTributo]
        filtri << ['anno': annoDestinazione]

        sql = """
				SELECT 
					TRXL.TRIBUTO,
					TRXL.CATEGORIA,
					TRXL.TIPO_TARIFFA,
					TRXL.TIPO_TRIBUTO,
					TRXL.ANNO,
					TRXL.CONVERTI_TRIBUTO,
					TRXL.CONVERTI_CATEGORIA,
					TRXL.CONVERTI_TIPO_TARIFFA,
					TRXL.CONVERTI_PERC_DETRAZIONE,
					TRXL.CONVERTI_NOTE,
					TRXL.CONVERTI_MOTIVO,
					TRXL.CONVERTI_NOTE_TARIFFA
				FROM
					TARIFFE_CONVERSIONE TRXL
				WHERE
					NVL(TRXL.DA_ANNO,1900) <= :annoOrigine AND
					NVL(TRXL.A_ANNO,9999) >= :annoOrigine AND
					TRXL.ANNO = :anno AND
					TRXL.TIPO_TRIBUTO = :tipoTributo
				ORDER BY
					TRXL.SEQUENZA DESC
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def conversioni = []

        results.each {

            def conv = [:]

            conv.tributo = it['TRIBUTO']
            conv.categoria = it['CATEGORIA']
            conv.tipoTariffa = it['TIPO_TARIFFA']

            conv.tipoTributo = it['TIPO_TRIBUTO']
            conv.anno = it['ANNO']

            conv.convertiTributo = it['CONVERTI_TRIBUTO']
            conv.convertiCategoria = it['CONVERTI_CATEGORIA']
            conv.convertiTipoTariffa = it['CONVERTI_TIPO_TARIFFA']
            conv.convertiPercDetrazione = it['CONVERTI_PERC_DETRAZIONE']

            conv.convertiNote = it['CONVERTI_NOTE']
            conv.convertiMotivo = it['CONVERTI_MOTIVO']
            conv.convertiNoteTariffa = it['CONVERTI_NOTE_TARIFFA']

            conversioni << conv
        }

        return conversioni
    }

    // Ricava codici tributo compatibili per anno e tributo
    def getCodiciTributo(String tipoTributo, Integer anno, Boolean conCodiceTotale = false) {

        String sql = ""
        String sqlFiltri = ""

        def filtri = [:]

        if (anno != null) {
            filtri << ['anno': anno]
            sqlFiltri += " AND TARR.ANNO = :anno "
        }

        def filtroTipi = []

        if (tipoTributo != null) {
            if (tipoTributo == 'CUNI') {
                filtroTipi << 'CUNI'
                filtroTipi << 'ICP'
                filtroTipi << 'TOSAP'

                sqlFiltri += " AND (COTR.TRIBUTO BETWEEN 8600 AND 8699) "
            } else {
                filtroTipi << tipoTributo
            }
        } else {
            filtroTipi << 'ICP'
            filtroTipi << 'TOSAP'
        }
        if (filtroTipi.size() > 0) {

            sqlFiltri += "AND COTR.TIPO_TRIBUTO IN ("
            filtroTipi.each {
                sqlFiltri += "'" + it + "',"
            }
            sqlFiltri = sqlFiltri.substring(0, sqlFiltri.length() - 1)
            sqlFiltri += ") "
        }

        sql = """SELECT DISTINCT
					COTR.TRIBUTO,
					COTR.DESCRIZIONE,
					COTR.DESCRIZIONE_RUOLO,
					COTR.TIPO_TRIBUTO,
					COTR.TIPO_TRIBUTO_PREC,
					COTR.CONTO_CORRENTE,
					COTR.DESCRIZIONE_CC,
					COTR.FLAG_STAMPA_CC,
					COTR.FLAG_RUOLO,
					COTR.FLAG_CALCOLO_INTERESSI,
					COTR.COD_ENTRATA
				 FROM
					CODICI_TRIBUTO COTR,
					TARIFFE TARR
				 WHERE
					COTR.TRIBUTO = TARR.TRIBUTO (+)
					${sqlFiltri}
				 ORDER BY
					COTR.TRIBUTO
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def codiciTributo = []

        if (conCodiceTotale) {
            CodiceTributoDTO tutti = new CodiceTributoDTO()
            tutti.id = -1
            tutti.descrizione = "Tutti"
            codiciTributo << tutti
        }

        results.each {

            def codiceTributo = new CodiceTributoDTO()

            def tipoTributoCodice = it['TIPO_TRIBUTO']
            def tipoTributoCodicePrec = it['TIPO_TRIBUTO_PREC']

            codiceTributo.id = it['TRIBUTO'] as Integer
            codiceTributo.descrizione = it['DESCRIZIONE'] as String
            codiceTributo.descrizioneRuolo = it['DESCRIZIONE_RUOLO'] as String
            codiceTributo.tipoTributo = TipoTributo.findByTipoTributo(tipoTributoCodice).toDTO()
            codiceTributo.tipoTributoPrec = TipoTributo.findByTipoTributo(tipoTributoCodicePrec)?.toDTO()

            codiceTributo.contoCorrente = it['CONTO_CORRENTE'] as Number
            codiceTributo.descrizioneCc = it['DESCRIZIONE_CC'] as String
            codiceTributo.flagStampaCc = it['FLAG_STAMPA_CC'] as String
            codiceTributo.flagRuolo = it['FLAG_RUOLO']
            codiceTributo.flagCalcoloInteressi = it['FLAG_CALCOLO_INTERESSI']
            codiceTributo.codEntrata = it['COD_ENTRATA']

            codiciTributo << codiceTributo
        }

        return codiciTributo
    }

    // Ricava codici tributo compatibili per anno e tributo e crea lista per combo
    def getCodiciTributoCombo(String tipoTributo, Integer anno) {

        List<CodiceTributoDTO> codiciTributo = getCodiciTributo(tipoTributo, anno)

        def listCodiciTributo = []

        codiciTributo.each {

            def codiceTributo = [:]

            codiceTributo.codice = it.id

            if (tipoTributo == 'CUNI') {
                codiceTributo.descrizione = it.descrizioneRuolo
            } else {
                codiceTributo.descrizione = (it.id as String) + ' - ' + it.descrizione
            }

            codiceTributo.tipoTributo = (it.tipoTributoPrec != null) ? it.tipoTributoPrec.tipoTributo : it.tipoTributo.tipoTributo

            listCodiciTributo << codiceTributo
        }

        return listCodiciTributo
    }

    // Ricava elenco codici tributo
    def getElencoCodiciTributo(def filtri) {

        List<CodiceTributoDTO> codiciTributoDTO = []

        def tipoTributo = filtri.tipoTributo
        def fullList = filtri.fullList ?: false

        def filtroTipi = []
        filtroTipi << tipoTributo

        /// #75586 : Soluzione temporanea, da rivalutare tutti i filtri per range 8600_8699 sparpagliati nel codice
        if (filtri.noCUNILegacy) {
            fullList = true
        }

        if (tipoTributo == 'CUNI') {
            if (!filtri.noCUNILegacy) {
                /// #75586 : Per compatibilità, aggiunge tutti i Tributi Legacy CUNI
                filtroTipi << 'ICP'
                filtroTipi << 'TOSAP'
            }
        }

        codiciTributoDTO = CodiceTributo.createCriteria().list {
            createAlias('tipoTributo', 'tt', CriteriaSpecification.INNER_JOIN)
            createAlias('tipoTributoPrec', 'ttp', CriteriaSpecification.LEFT_JOIN)

            inList('tt.tipoTributo', filtroTipi)

            if (filtri.daCodice) {
                ge('id', filtri.daCodice as Long)
            }
            if (filtri.aCodice) {
                le('id', filtri.aCodice as Long)
            }
            if (filtri.nome) {
                ilike('descrizioneRuolo', filtri.nome)
            }
            if (filtri.descrizione) {
                ilike('descrizione', filtri.descrizione)
            }
            if (filtri.tributoPrecedente) {
                String matchExpr

                switch (filtri.tributoPrecedente) {
                    case 'PUBBL':
                        matchExpr = 'ICP'
                        break
                    case 'OSAP':
                        matchExpr = 'TOSAP'
                        break
                    default:
                        matchExpr = filtri.tributoPrecedente ?: ''
                        break
                }
                isNotNull('tipoTributoPrec')
                like('ttp.tipoTributo', matchExpr)
            }
            if (filtri.contoCorrente) {
                eq('contoCorrente', filtri.contoCorrente)
            }
            if (filtri.descrizioneCc) {
                ilike('descrizioneCc', filtri.descrizioneCc)
            }
            if (filtri.flagStampaCc != null) {
                if (filtri.flagStampaCc) {
                    eq('flagStampaCc', 'S')
                } else {
                    isNull('flagStampaCc')
                }
            }
            if (filtri.flagRuolo != null) {
                if (filtri.flagRuolo) {
                    eq('flagRuolo', 'S')
                } else {
                    isNull('flagRuolo')
                }
            }
            if (filtri.flagCalcoloInteressi != null) {
                if (filtri.flagCalcoloInteressi) {
                    eq('flagCalcoloInteressi', 'S')
                } else {
                    isNull('flagCalcoloInteressi')
                }
            }
            if (filtri.codEntrata != null) {
                ilike('codEntrata', '%' + filtri.codEntrata + '%')
            }

            if (!fullList) {
                if (filtri.tipoTributo == 'CUNI') {
                    ge('id', 8600 as Long)
                    le('id', 8699 as Long)
                } else {
                    or {
                        lt('id', 8600 as Long)
                        gt('id', 8699 as Long)
                    }
                }
            }

        }.toDTO().sort { it.id }

        def codiciTributo = []

        codiciTributoDTO.each {

            def codiceTributo = [:]

            codiceTributo.dto = it

            codiceTributo.id = it.id

            codiceTributo.nome = it.descrizioneRuolo
            codiceTributo.descrizione = it.descrizione

            String tributoDescr = (it.tipoTributoPrec != null) ? it.tipoTributoPrec.tipoTributo : it.tipoTributo.tipoTributo
            switch (tributoDescr) {
                default:
                    break
                case 'ICP':
                    tributoDescr = "PUBBL"
                    break
                case 'TOSAP':
                    tributoDescr = "OSAP"
                    break
                case 'CUNI':
                    tributoDescr = "CUNI"
                    break
            }
            codiceTributo.tipoTributo = tributoDescr

            codiceTributo.contoCorrente = it.contoCorrente
            codiceTributo.descrizioneCc = it.descrizioneCc

            codiceTributo.flagRuolo = (it.flagRuolo ?: '') == 'S'

            codiceTributo.flagStampaCc = (it.flagStampaCc ?: '') == 'S'
            codiceTributo.flagCalcoloInteressi = (it.flagCalcoloInteressi ?: '') == 'S'
            codiceTributo.codEntrata = it.codEntrata

            codiciTributo << codiceTributo
        }

        return codiciTributo
    }

    // Ricava elenco dettagliato codici tributo
    def getElencoDettagliatoCodiciTributo(def filtri) {

        def elencoCodici = getElencoCodiciTributo(filtri)

        def listCodici = []

        elencoCodici.each {

            def codice = [:]

            codice.codice = it.id
            codice.descrizione = ((it.nome) ? it.nome : it.descrizione)
            codice.descrizioneFull = (it.id as String) + " : " + codice.descrizione

            listCodici << codice
        }

        return listCodici
    }

    // Verifica codice tributo
    def verificaCodiceTributo(CodiceTributoDTO codiceTributo, Boolean esistente) {

        String message = ""
        Integer result = 0

        String tipoTributo = (codiceTributo.tipoTributo != null) ? codiceTributo.tipoTributo.tipoTributo : '-'

        // Frontespizio
        Integer codice = codiceTributo.id
        if (tipoTributo == 'CUNI') {
            if ((codice < 8600) || (codice > 8699)) {
                message += "Codice non valido, specificare un valore compreso tra 8600 e 8699\n"
            }
        } else {
            if ((codice < 1) || (codice > 9999)) {
                message += "Codice non valido, specificare un valore compreso tra 1 e 9999\n"
            }
        }
        if (!esistente) {
            if (codiceTributo.getDomainObject() != null) {
                message += "Codice gia' in uso, impossibile procedere\n"
            }
        }

        String descrizioneRuolo = codiceTributo.descrizioneRuolo ?: ''
        def length = descrizioneRuolo.size()
        if ((length < 3) || (length > 100)) {
            message += "${codiceTributo.tipoTributo.tipoTributo == 'CUNI' ? 'Nome' : 'Descrizione Ruolo'} non valida, specificare un valore con lunghezza compresa tra 3 e 60 caratteri\n"
        }

        String descrizione = codiceTributo.descrizione ?: ''
        length = descrizione.size()
        if ((length < 3) || (length > 60)) {
            message += "Descrizione non valida, specificare un valore con lunghezza compresa tra 3 e 100 caratteri\n"
        }

        if (codiceTributo.tipoTributo == null) {
            message += "Tributo non specificato\n"
        }
        if (tipoTributo == 'CUNI') {
            if (codiceTributo.tipoTributoPrec == null) {
                message += "Tributo di provenienza non specificato\n"
            }
        }

        String descrizioneCc = codiceTributo.descrizioneCc ?: '----'
        length = descrizioneCc.size()
        if ((length < 3) || (length > 100)) {
            message += "Servizio non valido, specificare un valore con lunghezza compresa tra 3 e 60 caratteri oppure lasciare vuoto\n"
        }

        String codEntrata = codiceTributo.codEntrata ?: ''
        length = codEntrata.size()
        if (length > 4) {
            message += "Codice Entrata non valido, specificare un valore con lunghezza massima di 4 caratteri\n"
        }

        Integer contoCorrente = codiceTributo.contoCorrente ?: 1
        if ((contoCorrente < 1) || (contoCorrente > 99999999)) {
            message += "Codice Gruppo T. non valido, specificare un valore tra 1 e 99999999 oppure lasciare vuoto\n"
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Verifica codici tributo
    def verificaCodiciTributo(String tipoTributo, List<CodiceTributoDTO> listaCodici, Boolean configTime = false) {

        String message = ""
        Integer result = 0

        Integer configErrorlevel = configTime ? 1 : 2
        // Warning se Configurazione, Error se utilizzo

        String tributoDepag
        boolean invalid

        if (tipoTributo == 'CUNI') {

            List<CodiceTributoDTO> noCC = listaCodici.findAll { it.contoCorrente == null }
            List<CodiceTributoDTO> conCC = listaCodici.findAll { it.contoCorrente != null }

            def numCodici = listaCodici.size()
            def numCodiciCC = conCC.size()

            if ((numCodiciCC > 0) && (numCodiciCC != numCodici)) {
                message += "Se richiesto, il Gruppo Tributo va specificato per tutti i codici del tributo ${tipoTributo}\n"
                if (result < configErrorlevel) result = configErrorlevel
            }

            noCC.each {

                if (it.descrizioneCc != null) {
                    message += "Se non specificato Codice Gruppo Tributo, il Nome Gruppo Tributo deve essere vuoto : ${it.id} -> ${it.descrizioneCc}\n"
                    if (result < configErrorlevel) result = configErrorlevel
                }
            }

            conCC.each {

                tributoDepag = it.descrizioneCc ?: ''
                if (tributoDepag == null) tributoDepag = tipoTributo

                invalid = tributoDepag.size() < 2

                if (!invalid) {

                    InstallazioneParametroDTO desDepag = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "DES_" + tributoDepag }
                    InstallazioneParametroDTO desrDepag = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "DESR_" + tributoDepag }
                    InstallazioneParametroDTO depaDepag = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "DEPA_" + tributoDepag }

                    if ((desDepag?.valore ?: '').size() < 5) invalid = true
                    if ((desrDepag?.valore ?: '').size() < 5) invalid = true
                    if ((depaDepag?.valore ?: '').size() < 5) invalid = true
                }

                if (invalid) {
                    message += "Gruppo Tributo non configurato correttamente nei parametri di installazione : ${it.id} -> ${tributoDepag}\n"
                    if (result < 1) result = 1
                }

                if (!invalid) {

                    def contoCorrente = it.contoCorrente

                    List<CodiceTributoDTO> matchCC = listaCodici.findAll { it.descrizioneCc != tributoDepag && it.contoCorrente == contoCorrente }
                    List<CodiceTributoDTO> matchCC2 = listaCodici.findAll { it.descrizioneCc == tributoDepag && it.contoCorrente != contoCorrente }

                    matchCC += matchCC2

                    if (matchCC.size() > 0) {
                        message += "A parita' di Codice Gruppo Tributo, il Nome Gruppo Tributo deve essere il medesimo : ${it.id} -> ${it.contoCorrente} / ${tributoDepag}\n"
                        if (result < configErrorlevel) result = configErrorlevel
                    }
                }
            }
        }

        switch (result) {
            default:
                break
            case 1:
                message = "Attenzione : problema di configurazione Codici Tributo !\n\n" + message
                break
            case 2:
                message = "ATTENZIONE : errore di configurazione Codici Tributo !\n\n" + message
                break
        }

        return [result: result, message: message]
    }

    // Verifica codici tributo
    def salvaCodiceTributo(CodiceTributoDTO codiceTributoDTO) {

        String message = ''
        Integer result = 0

        try {
            CodiceTributo codiceTributoSalva = codiceTributoDTO.getDomainObject()

            if (codiceTributoSalva == null) {

                codiceTributoSalva = new CodiceTributo()

                codiceTributoSalva.id = codiceTributoDTO.id
            }

            codiceTributoSalva.descrizione = codiceTributoDTO.descrizione
            codiceTributoSalva.descrizioneRuolo = codiceTributoDTO.descrizioneRuolo
            codiceTributoSalva.tipoTributo = codiceTributoDTO.tipoTributo.getDomainObject()
            codiceTributoSalva.tipoTributoPrec = (codiceTributoDTO.tipoTributoPrec) ? codiceTributoDTO.tipoTributoPrec.getDomainObject() : null

            codiceTributoSalva.contoCorrente = codiceTributoDTO.contoCorrente
            codiceTributoSalva.descrizioneCc = codiceTributoDTO.descrizioneCc
            codiceTributoSalva.flagRuolo = codiceTributoDTO.flagRuolo

            codiceTributoSalva.flagStampaCc = codiceTributoDTO.flagStampaCc
            codiceTributoSalva.flagCalcoloInteressi = codiceTributoDTO.flagCalcoloInteressi

            codiceTributoSalva.codEntrata = codiceTributoDTO.codEntrata

            codiceTributoSalva.gruppoTributo = codiceTributoDTO.gruppoTributo

            codiceTributoSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina codice tributo
    def eliminaCodiceTributo(def codiceTributo) {
        codiceTributo.delete(failOnError: true, flush: true)
    }

    // Verifica arrotondamenti tributo
    def verificaArrotondamentiTributo(ArrotondamentiTributoDTO arrotondamenti, String tipoTributo) {

        String message = ""
        Integer result = 0

        String nomeImpostazione
        Double minimum

        // Consistenza Reale
        nomeImpostazione = (tipoTributo == 'CUNI') ? "Superficie" : "Consistenza Reale"
        minimum = arrotondamenti.consistenzaMinimaReale ?: 0

        if (arrotondamenti.arrConsistenzaReale == null) {
            message += nomeImpostazione + "->Arrotondamento non specificata\n"
        }
        if ((minimum < 0.0) || (minimum > 999999.99)) {
            message += "Valore di " + nomeImpostazione + "->Valore Minimo non valido : indicare un numero tra 0.00 e 999999.99, oppure lasciare vuoto\n"
        }

        // Consistenza Tassabile
        nomeImpostazione = (tipoTributo == 'CUNI') ? "Superficie Tassabile" : "Consistenza"
        minimum = arrotondamenti.consistenzaMinima ?: 0

        if (arrotondamenti.arrConsistenza == null) {
            message += nomeImpostazione + "->Arrotondamento non specificata\n"
        }
        if ((minimum < 0.0) || (minimum > 999999.99)) {
            message += "Valore di " + nomeImpostazione + "->Valore Minimo non valido : indicare un numero tra 0.00 e 999999.99, oppure lasciare vuoto\n"
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Salva arrotondamenti Tributo
    def salvaArrotondamentiTributo(ArrotondamentiTributoDTO arrotondamentiDTO) {

        String message = ''
        Integer result = 0

        try {
            ArrotondamentiTributo arrotondamentiSalva = arrotondamentiDTO.getDomainObject()
            if (arrotondamentiSalva == null) {

                arrotondamentiSalva = new ArrotondamentiTributo()
            }

            arrotondamentiSalva.codiceTributo = arrotondamentiDTO.codiceTributo.getDomainObject()
            arrotondamentiSalva.sequenza = arrotondamentiDTO.sequenza

            arrotondamentiSalva.arrConsistenzaReale = arrotondamentiDTO.arrConsistenzaReale
            arrotondamentiSalva.consistenzaMinimaReale = arrotondamentiDTO.consistenzaMinimaReale
            arrotondamentiSalva.arrConsistenza = arrotondamentiDTO.arrConsistenza
            arrotondamentiSalva.consistenzaMinima = arrotondamentiDTO.consistenzaMinima

            arrotondamentiSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]

    }

    // Riporta categorie
    def getCategorie(def elencoCodici) {

        def listaCodici = null

        if ((elencoCodici != null) && (elencoCodici.size() > 0)) {

            listaCodici = []

            elencoCodici.each {
                listaCodici << it.id
            }
        }

        def lista = Categoria.createCriteria().list {

            if ((listaCodici != null) && (listaCodici.size() > 0)) {
                'in'("codiceTributo.id", listaCodici)
            }
        }
        def elencoCategorie = lista.toDTO()

        return elencoCategorie
    }

    // Riporta elenco categorie per lista
    def getElencoCategorie(def parametri) {

        def results = Categoria.createCriteria().list {
            createAlias('codiceTributo', 'ct', CriteriaSpecification.INNER_JOIN)

            if (parametri.tipoTributo) {
                eq('ct.tipoTributo.tipoTributo', parametri.tipoTributo)
            }
            if (parametri.codiceTributo && parametri.codiceTributo > 0) {
                eq('ct.id', parametri.codiceTributo)
            }
            if (parametri.daCodiceTributo && parametri.daCodiceTributo > 0) {
                ge('ct.id', parametri.daCodiceTributo as Long)
            }
            if (parametri.aCodiceTributo && parametri.aCodiceTributo > 0) {
                le('ct.id', parametri.aCodiceTributo as Long)
            }
            if (parametri.descrizione) {
                ilike('descrizione', parametri.descrizione)
            }
            if (parametri.descrizionePrec) {
                ilike('descrizionePrec', parametri.descrizionePrec)
            }
            if (parametri.daCategoria) {
                ge('categoria', parametri.daCategoria as Short)
            }
            if (parametri.aCategoria) {
                le('categoria', parametri.aCategoria as Short)
            }
            if (parametri.flagDomestica != null) {
                if (parametri.flagDomestica) {
                    eq('flagDomestica', 'S')
                } else {
                    isNull('flagDomestica')
                }
            }
            if (parametri.flagGiorni != null) {
                if (parametri.flagGiorni) {
                    eq('flagGiorni', 'S')
                } else {
                    isNull('flagGiorni')
                }
            }
            if (parametri.flagNoDepag != null) {
				if(parametri.flagNoDepag) {
                    eq('flagNoDepag', true)
				}
				else {
                    isNull('flagNoDepag')
                }
            }

            order('ct.id', 'asc')
            order('categoria', 'asc')
        }.toDTO()

        def records = []

        results.each {

            def record = [:]

            record.codiceTributo = it.codiceTributo.id
            record.categoria = it.categoria
            record.descrizione = it.descrizione
            record.descrizionePrec = it.descrizionePrec
            record.flagDomestica = (it.flagDomestica ?: '') == 'S'
            record.flagGiorni = (it.flagGiorni ?: '') == 'S'
            record.flagNoDepag = it.flagNoDepag

            if (parametri.tipoTributo == 'CUNI') {
                record.codiceTributoDes = it.codiceTributo.descrizioneRuolo
            } else {
                record.codiceTributoDes = it.codiceTributo.id + ' - ' + it.codiceTributo.descrizione
            }

            records << record
        }

        return records
    }

    // Esegue verifica su dati della Tariffa e crea messaggio di avvertimento
    def verificaCategoria(CategoriaDTO categoria) {

        String message = ""
        Integer result = 0

        // Frontespizio
        if (!(categoria.codiceTributo)) {
            message += "Tributo non impostato correttamente\n"
        }
        Short codCategoria = (categoria.categoria != null) ? categoria.categoria : -1
        if ((codCategoria < 0) || (codCategoria > 9999)) {
            message += "Categoria non valido, deve essere un valore numerico compreso tra 1 e 9999\n"
        }

        String descrizione = categoria.descrizione ?: ''
        def length = descrizione.size()

        if (length < 3) {
            message += "Descrizione troppo breve, inserire almento 3 caratteri\n"
        } else {
            if (length > 100) {
                message += "Descrizione troppo lunga, massimo 100 caratteri ammessi\n"
            }
        }

        descrizione = categoria.descrizionePrec ?: ''
        length = descrizione.size()
        if (length > 100) {
            message += "Descrizione Precedente troppo lunga, massimo 100 caratteri ammessi\n"
        }

        // Dati categoria

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Duplica la categoria
    def duplicaCategoria(CategoriaDTO categoriaOrg, boolean copia) {

        CategoriaDTO categoria

        categoria = new CategoriaDTO()

        categoria.codiceTributo = categoriaOrg.codiceTributo

        categoria.categoria = categoriaOrg.categoria
        categoria.categoriaRif = categoriaOrg.categoriaRif

        categoria.descrizione = copia ? "${categoriaOrg.descrizione} (Copia)" : categoriaOrg.descrizione
        categoria.descrizionePrec = categoriaOrg.descrizionePrec
        categoria.flagDomestica = categoriaOrg.flagDomestica
        categoria.flagGiorni = categoriaOrg.flagGiorni
        categoria.flagNoDepag = categoriaOrg.flagNoDepag

        categoria.ente = categoriaOrg.ente

        return categoria
    }

    // Verifica se esiste un altra categoria con queste caratteristiche -> true se esiste
    boolean checkCategoriaEsistente(CategoriaDTO categoria) {

        CodiceTributo codiceTributo = CodiceTributo.get(categoria.codiceTributo.id)
        Short categoriaId = categoria.categoria

        Categoria esistente = Categoria.findByCodiceTributoAndCategoria(codiceTributo, categoriaId)

        return (esistente != null)
    }

    // Verifica se categoria eliminabile
    def checkCategoriaEliminabile(def categoria) {

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call CATEGORIE_PD(?,?)}',
                    [
                            categoria.codiceTributo,
                            categoria.categoria,
                    ]
            )

            return ''
        }
        catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    // Salva la Categoria
    def salvaCategoria(CategoriaDTO categoriaDTO) {

        String message = ''
        Integer result = 0

        try {
            Categoria categoriaSalva = categoriaDTO.getDomainObject()
            if (categoriaSalva == null) {

                Short numCategoria = categoriaDTO.categoria

                if (numCategoria == 0) {

                    numCategoria = getNuovoNumeroCategoria(categoriaDTO)
                } else {
                    if (checkCategoriaEsistente(categoriaDTO)) {
                        throw new Exception("Esiste gia' una categoria con queste caratteristiche ")
                    }
                }

                CategoriaRaw categoriaRaw = new CategoriaRaw()

                categoriaRaw.tributo = categoriaDTO.codiceTributo.id
                categoriaRaw.categoria = numCategoria

                String idTributo = categoriaDTO.codiceTributo.id as String
                String idCategoria = categoriaDTO.categoria as String
                categoriaRaw.idCategoria = String.format("%4s%4s", idTributo, idCategoria).replace(' ', '0')

                categoriaRaw.descrizione = categoriaDTO.descrizione
                categoriaRaw.descrizionePrec = categoriaDTO.descrizionePrec
                categoriaRaw.categoriaRif = categoriaDTO.categoriaRif
                categoriaRaw.flagDomestica = categoriaDTO.flagDomestica
                categoriaRaw.flagGiorni = categoriaDTO.flagGiorni
                categoriaRaw.flagNoDepag = categoriaDTO.flagNoDepag

                categoriaRaw.save(flush: true, failOnError: true)
            } else {
                categoriaSalva.descrizione = categoriaDTO.descrizione
                categoriaSalva.descrizionePrec = categoriaDTO.descrizionePrec
                categoriaSalva.categoriaRif = categoriaDTO.categoriaRif
                categoriaSalva.flagDomestica = categoriaDTO.flagDomestica
                categoriaSalva.flagGiorni = categoriaDTO.flagGiorni
                categoriaSalva.flagNoDepag = categoriaDTO.flagNoDepag

                categoriaSalva.save(flush: true, failOnError: true)
            }
        } catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Ricava nuovo numero per la categoria
    def getNuovoNumeroCategoria(CategoriaDTO categoria) {

        Short codCategoria = 0

        def filtri = [:]

        filtri << ['codiceTributo': categoria.codiceTributo?.id ?: 0]

        String sql = """
				SELECT
					MAX(CATE.CATEGORIA) AS ULTIMA_CATEGORIA
				FROM
					CATEGORIE CATE
				WHERE
					CATE.TRIBUTO = :codiceTributo
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        codCategoria = (totali.ULTIMA_CATEGORIA ?: 0) as Short

        if ((codCategoria < 1) || (codCategoria > 9999)) {
            throw new Exception("Nessun Codice Categoria automatico disponibile, specificare manualemnte ")
        }

        return codCategoria + 1
    }

    // Elimina la categoria
    def eliminaCategoria(def identificativi) {

        String message = ''
        Integer result = 0

        Categoria categoriaSalva = getCategoriaDaIdentificativiLista(identificativi)

        if (categoriaSalva == null) {

            message = "Categoria non registrata in banca dati "
            result = 2
        } else {

            try {
                categoriaSalva.delete(flush: true)
            }
            catch (Exception e) {

                if (e?.message?.startsWith("ORA-20999")) {
                    message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                    message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else {
                    message += e.message
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Riporta oggetto Categoria da identificativi della lista
    Categoria getCategoriaDaIdentificativiLista(def identificativi) {

        CodiceTributo codiceTributo = CodiceTributo.get(identificativi.codiceTributo)
        Short categoriaId = identificativi.categoria

        Categoria categoria = Categoria.findByCodiceTributoAndCategoria(codiceTributo, categoriaId)

        return categoria
    }

    // Ricava elenco anni da tariffe per tributo
    def getAnnualitaInTariffe(String tipoTributo) {

        List<Short> listaAnni = Tariffa.createCriteria().list() {
            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)
            createAlias("cotr.tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)

            projections {
                groupProperty('anno')
                order('anno', 'desc')
            }
            if (tipoTributo) {
                eq('titr.tipoTributo', tipoTributo)
            }
        }

        return listaAnni
    }

    // Riporta elenco tariffe per lista
    def getElencoTariffe(def filtri) {

        def listaTariffe = []

        List<TariffaDTO> elencoTariffe = Tariffa.createCriteria().list {

            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)

            if (filtri.tipoTributo) {
                eq('cotr.tipoTributo.tipoTributo', filtri.tipoTributo)
            }
			if(filtri.categoria) {
                eq('cate.categoria', filtri.categoria.categoria as Short)
                eq('cotr.id', filtri.categoria.codiceTributo as Long)
            }
			if(filtri.annoTributo) {
                eq('anno', filtri.annoTributo as Short)
            }
            if (filtri.daTipoTariffa) {
                ge('tipoTariffa', filtri.daTipoTariffa as Short)
            }
            if (filtri.aTipoTariffa) {
                le('tipoTariffa', filtri.aTipoTariffa as Short)
            }
            if (filtri.descrizione) {
                ilike("descrizione", filtri.descrizione)
            }
            if (filtri.daTariffaQuotaFissa) {
                ge('tariffaQuotaFissa', filtri.daTariffaQuotaFissa as BigDecimal)
            }
            if (filtri.aTariffaQuotaFissa) {
                le('tariffaQuotaFissa', filtri.aTariffaQuotaFissa as BigDecimal)
            }
            if (filtri.daPercRiduzione) {
                ge('percRiduzione', filtri.daPercRiduzione as BigDecimal)
            }
            if (filtri.aPercRiduzione) {
                le('percRiduzione', filtri.aPercRiduzione as BigDecimal)
            }
            if (filtri.daTariffa) {
                ge('tariffa', filtri.daTariffa as BigDecimal)
            }
            if (filtri.aTariffa) {
                le('tariffa', filtri.aTariffa as BigDecimal)
            }
            if (filtri.daLimite) {
                ge('limite', filtri.daLimite as BigDecimal)
            }
            if (filtri.aLimite) {
                le('limite', filtri.aLimite as BigDecimal)
            }
            if (filtri.daTariffaSuperiore) {
                ge('tariffaSuperiore', filtri.daTariffaSuperiore as BigDecimal)
            }
            if (filtri.aTariffaSuperiore) {
                le('tariffaSuperiore', filtri.aTariffaSuperiore as BigDecimal)
            }
            if (filtri.daRiduzioneQuotaFissa) {
                ge('riduzioneQuotaFissa', filtri.daRiduzioneQuotaFissa as BigDecimal)
            }
            if (filtri.aRiduzioneQuotaFissa) {
                le('riduzioneQuotaFissa', filtri.aRiduzioneQuotaFissa as BigDecimal)
            }
            if (filtri.daRiduzioneQuotaFissaVariabile) {
                ge('riduzioneQuotaFissaVariabile', filtri.daRiduzioneQuotaFissaVariabile as BigDecimal)
            }
            if (filtri.aRiduzioneQuotaFissaVariabile) {
                le('riduzioneQuotaFissaVariabile', filtri.aRiduzioneQuotaFissaVariabile as BigDecimal)
            }
            if (filtri.daTariffaPrec) {
                ge('tariffaPrec', filtri.daTariffaPrec as BigDecimal)
            }
            if (filtri.aTariffaPrec) {
                le('tariffaPrec', filtri.aTariffaPrec as BigDecimal)
            }
            if (filtri.daLimitePrec) {
                ge('limitePrec', filtri.daLimitePrec as BigDecimal)
            }
            if (filtri.aLimitePrec) {
                le('limitePrec', filtri.aLimitePrec as BigDecimal)
            }
            if (filtri.daTariffaSuperiorePrec) {
                ge('tariffaSuperiorePrec', filtri.daTariffaSuperiorePrec as BigDecimal)
            }
            if (filtri.aTariffaSuperiorePrec) {
                le('tariffaSuperiorePrec', filtri.aTariffaSuperiorePrec as BigDecimal)
            }
            if (filtri.flagRuolo != null) {
                if (filtri.flagRuolo) {
                    eq('cotr.flagRuolo', 'S')
                } else {
                    isNull('cotr.flagRuolo')
                }
            }
            if (filtri.flagTariffaBase != null) {
                if (filtri.flagTariffaBase) {
                    eq('flagTariffaBase', 'S')
                } else {
                    isNull('flagTariffaBase')
                }
            }
            if (filtri.flagNoDepag != null) {
				if(filtri.flagNoDepag) {
                    eq('flagNoDepag', true)
				}
				else {
                    isNull('flagNoDepag')
                }
            }
        }.toDTO()

        if (elencoTariffe.size() > 1) {
            Collections.sort(elencoTariffe, new Comparator<TariffaDTO>() {
                @Override
                int compare(TariffaDTO t1, TariffaDTO t2) {
                    int cmp

                    cmp = t2.anno <=> t1.anno
                    if (cmp != 0) {
                        return cmp
                    }

                    cmp = t1.categoria.codiceTributo.id <=> t2.categoria.codiceTributo.id
                    if (cmp != 0) {
                        return cmp
                    }

                    cmp = t1.categoria.categoria <=> t2.categoria.categoria
                    if (cmp != 0) {
                        return cmp
                    }

                    cmp = t1.tipoTariffa <=> t2.tipoTariffa
                    if (cmp != 0) {
                        return cmp
                    }

                    cmp = t1.descrizione <=> t2.descrizione
                    if (cmp != 0) {
                        return cmp
                    }

                    int tipologia1 = (t1.tipologiaTariffa ?: 0)
                    int tipologia2 = (t2.tipologiaTariffa ?: 0)
                    cmp = tipologia1 - tipologia2
                    if (cmp != 0) {
                        return cmp
                    }

                    cmp = t1.categoria.descrizione <=> t2.categoria.descrizione
                    return cmp
                }
            })
        }

        elencoTariffe.each {

            it.estraiFlag()

            if (filtri.tipologiaTariffa && it.tipologiaTariffa != filtri.tipologiaTariffa.codice) {
                return
            }
            if (filtri.tipologiaCalcolo && it.tipologiaCalcolo != filtri.tipologiaCalcolo.codice) {
                return
            }

            def tariffa = [:]

            CategoriaDTO categoriaObj = it.categoria
            CodiceTributoDTO codiceTributoObj = categoriaObj.codiceTributo
            String descrizione

            tariffa.dto = it

            tariffa.anno = it.anno

            tariffa.tipoTariffa = it.tipoTariffa
            tariffa.flagRuolo = ((codiceTributoObj.flagRuolo ?: '') == 'S')

            if (filtri.codiceTributo == 'CUNI') {
                descrizione = codiceTributoObj.descrizioneRuolo
            } else {
                descrizione = (codiceTributoObj.id as String) + ' - ' + codiceTributoObj.descrizione
            }
            tariffa.codiceTributo = codiceTributoObj.id
            tariffa.codiceTributoDescr = descrizione

            tariffa.categoria = categoriaObj.categoria
            tariffa.categoriaDescr = categoriaObj.descrizione

            tariffa.descrizione = it.descrizione

            tariffa.tariffaQuotaFissa = it.tariffaQuotaFissa
            tariffa.percRiduzione = it.percRiduzione

            tariffa.tariffa = it.tariffa
            tariffa.limite = it.limite
            tariffa.tariffaSuperiore = it.tariffaSuperiore

            tariffa.tariffaPrec = it.tariffaPrec
            tariffa.limitePrec = it.limitePrec
            tariffa.tariffaSuperiorePrec = it.tariffaSuperiorePrec

            tariffa.flagTariffaBase = ((it.flagTariffaBase ?: '') == 'S')
            tariffa.riduzioneQuotaFissa = it.riduzioneQuotaFissa
            tariffa.riduzioneQuotaVariabile = it.riduzioneQuotaVariabile

            tariffa.flagNoDepag = it.flagNoDepag

            switch (it.tipologiaTariffa) {
                default:
                    descrizione = "???"
                    break
                case TariffaDTO.TAR_TIPOLOGIA_STANDARD:
                    descrizione = "-"
                    break
                case TariffaDTO.TAR_TIPOLOGIA_PERMANENTE:
                    descrizione = "P"
                    break
                case TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA:
                    descrizione = "T"
                    break
                case TariffaDTO.TAR_TIPOLOGIA_ESENZIONE:
                    descrizione = "E"
                    break
            }
            tariffa.tipologiaTariffa = descrizione

            switch (it.tipologiaCalcolo) {
                default:
                    descrizione = "--Sconosciuto--"
                    break
                case TariffaDTO.TAR_CALCOLO_LIMITE_CONSISTENZA:
                    descrizione = (tariffa.limite > 0) ? "Consistenza" : "-"
                    break
                case TariffaDTO.TAR_CALCOLO_LIMITE_GIORNI:
                    descrizione = "Giornate"
                    break
            }
            tariffa.tipologiaCalcolo = descrizione

            switch (it.tipologiaSecondaria) {
                default:
                    descrizione = "--Sconosciuta--"
                    break
                case TariffaDTO.TAR_SECONDARIA_NESSUNA:
                    descrizione = "-"
                    break
                case TariffaDTO.TAR_SECONDARIA_USOSUOLO:
                    descrizione = "OCCUPAZIONE"
                    break
            }
            tariffa.tipologiaSecondaria = descrizione

            tariffa.importoTariffa = descriviTariffa(it, true)

            listaTariffe << tariffa
        }

        return listaTariffe
    }

    // Ricava elenco dettagliato tariffe in base ai filtri
    def getElencoDettagliatoTariffe(def filtri, Boolean prefissoCodiceTributo) {

        String ctStr
        String ttStr
        String descrizione

        def elencoTariffe = getElencoTariffe(filtri)

        def listaTariffe = []
        elencoTariffe.each {

            def tariffa = [:]

            ctStr = it.codiceTributo as String
            ttStr = it.tipoTariffa as String
            descrizione = ttStr + " - " + it.descrizione

            tariffa.codice = (String.format("%4s", ctStr) + String.format("%2s", ttStr)).replace(' ', '0')
            tariffa.codiceTributo = it.codiceTributo
            tariffa.tipoTariffa = it.tipoTariffa
            tariffa.nome = (prefissoCodiceTributo != false) ? ctStr + " : " + ttStr : ttStr
            tariffa.descrizione = it.descrizione
            tariffa.descrizioneFull = (prefissoCodiceTributo != false) ? ctStr + " : " + descrizione : descrizione
            tariffa.sortString = ctStr + "_" + it.descrizione

            if (listaTariffe.find { it.codiceTributo == tariffa.codiceTributo && it.tipoTariffa == tariffa.tipoTariffa } == null) {
                listaTariffe << tariffa
            }
        }

        listaTariffe.sort { it.sortString }

        return listaTariffe
    }

    // Riporta elenco tariffe
    def getTariffe(def elencoCodici, def annoTributo, String nameFilter = null, def tipologiaTariffe = null) {

        def listaCodici = null

        if ((elencoCodici != null) && (elencoCodici.size() > 0)) {

            listaCodici = []

            elencoCodici.each {
                listaCodici << it.id
            }
        }

        def lista = Tariffa.createCriteria().list {

            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)

            eq("anno", annoTributo as Short)

            if (nameFilter) {
                ilike("descrizione", (nameFilter ?: '%'))
            }

            if ((listaCodici != null) && (listaCodici.size() > 0)) {
                'in'("cotr.id", listaCodici)
            }
        }
        List<TariffaDTO> elencoTariffe = lista.toDTO()

        // Postprocessing temporaneo specifico x CU
        elencoTariffe.each {
            if ((it.descrizione ?: '').trim().size() < 1) {
                it.descrizione = "SENZA DESCRIZIONE (" + it.id.toString() + ")"
            }
        }

        elencoTariffe.each {
            it.estraiFlag()
        }

        if(tipologiaTariffe != null) {
            if(tipologiaTariffe.getClass() != [].getClass()) {
                elencoTariffe = elencoTariffe.findAll { it.tipologiaTariffa == tipologiaTariffe}
            }
            else {
                elencoTariffe = elencoTariffe.findAll { it.tipologiaTariffa in tipologiaTariffe}
            }
        }

        return elencoTariffe
    }

    // Conta le tariffe presenti per annualita
    def contaTariffePerAnnualita(def filtri) {

        Short anno = filtri.annoTributo
        String tipoTributo = filtri.tipoTributo ?: '-'
        Long codiceTributo = filtri.codiceTributo ?: 0

        def conteggio = Tariffa.createCriteria().count() {
            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)
            createAlias("cotr.tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)

            eq('titr.tipoTributo', tipoTributo)
            eq('anno', anno)
            if ((codiceTributo ?: 0) > 0) {
                eq("cotr.id", codiceTributo)
            }
        }

        return conteggio
    }

    // Copia tariffe corrispondenti con filtro su nuova annualita, salta eventuali esistenti
    def copiaTariffeDaAnnualita(def filtri, Short annoDestinazione) {

        def report = [
                message: '',
                result : 0
        ]

        Short annoOrigine = filtri.annoTributo
        String tipoTributo = filtri.tipoTributo ?: '-'
        Long codiceTributo = filtri.codiceTributo ?: 0

        List<Tariffa> tariffeEsistenti = Tariffa.createCriteria().list() {
            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)
            createAlias("cotr.tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)

            eq('titr.tipoTributo', tipoTributo)
            eq('anno', annoDestinazione)
            if ((codiceTributo ?: 0) > 0) {
                eq("cotr.id", codiceTributo)
            }
        }

        List<Tariffa> tariffeOrigine = Tariffa.createCriteria().list() {
            createAlias("categoria", "cate", CriteriaSpecification.INNER_JOIN)
            createAlias("cate.codiceTributo", "cotr", CriteriaSpecification.INNER_JOIN)
            createAlias("cotr.tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)

            eq('titr.tipoTributo', tipoTributo)
            eq('anno', annoOrigine)
            if ((codiceTributo ?: 0) > 0) {
                eq("cotr.id", codiceTributo)
            }
        }

        if (tariffeOrigine.size() > 0) {

            tariffeOrigine.each { tariffa ->

                Tariffa tariffaEsistente = tariffeEsistenti.find {
                    it.anno == annoDestinazione &&
                            it.categoria.categoria == tariffa.categoria.categoria &&
                            it.categoria.codiceTributo.id == tariffa.categoria.codiceTributo.id &&
                            it.tariffa == tariffa.tariffa
                }

                if (tariffaEsistente == null) {
                    def reportNow = copiaTariffaDaAnnualita(tariffa, annoDestinazione)

                    if (reportNow.result != 0) {
                        if (!(report.message.isEmpty())) report.message += "\n"
                        report.message += reportNow.message
                        if (report.result < reportNow.result) {
                            report.result = reportNow.result
                        }
                    }
                }
            }
        } else {
            report.message = "Non e' stata trovata alcuna tariffa da copiare "
            report.result = 1
        }

        return report
    }

    // Crea copia di tariffa per altra annualita
    def copiaTariffaDaAnnualita(Tariffa tariffaOriginale, Short annoDestinazione) {

        String message = ""
        Integer result = 0

        try {
            TariffaRaw tariffa = new TariffaRaw()

            tariffa.tributo = tariffaOriginale.categoria.codiceTributo.id
            tariffa.categoria = tariffaOriginale.categoria.categoria
            tariffa.anno = annoDestinazione
            tariffa.tipoTariffa = tariffaOriginale.tipoTariffa

            tariffa.descrizione = tariffaOriginale.descrizione
            tariffa.tariffa = tariffaOriginale.tariffa
            tariffa.percRiduzione = tariffaOriginale.percRiduzione
            tariffa.limite = tariffaOriginale.limite
            tariffa.tariffaSuperiore = tariffaOriginale.tariffaSuperiore
            tariffa.limitePrec = tariffaOriginale.limitePrec
            tariffa.tariffaPrec = tariffaOriginale.tariffaPrec
            tariffa.tariffaSuperiorePrec = tariffaOriginale.tariffaSuperiorePrec
            tariffa.tariffaQuotaFissa = tariffaOriginale.tariffaQuotaFissa

            tariffa.flagTariffaBase = tariffaOriginale.flagTariffaBase
            tariffa.riduzioneQuotaFissa = tariffaOriginale.riduzioneQuotaFissa
            tariffa.riduzioneQuotaVariabile = tariffaOriginale.riduzioneQuotaVariabile

            tariffa.flagNoDepag = tariffaOriginale.flagNoDepag

            tariffa.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Descrive tariffa
    String descriviTariffa(TariffaDTO tariffa, boolean valueOnly = false) {

        DecimalFormat fmtValuta = new DecimalFormat("€ #,##0.00")
        DecimalFormat fmtNumero = new DecimalFormat("#,##0.00")
        DecimalFormat fmtCoeff = new DecimalFormat("#,##0.000")
        DecimalFormat fmtPerc = new DecimalFormat("#,##0.00")
        DecimalFormat fmtInt = new DecimalFormat("#,##0")

        String strCoeff
        String strValore = ""
        String strLimiteUM

        String descrizione = ""

        double base = tariffa.tariffaQuotaFissa ?: 0
        double coeff = tariffa.tariffa ?: 1.0
        double riduz = tariffa.percRiduzione ?: 0
        double limite = tariffa.limite ?: 0

        double valore = base * coeff
        valore -= (valore * riduz) / 100.0
        valore = round(valore, 2)

        if (limite > 0) {

            strLimiteUM = (tariffa.tipologiaCalcolo == TariffaDTO.TAR_CALCOLO_LIMITE_GIORNI) ? "gg" : ""

            double coeffSup = tariffa.tariffaSuperiore ?: 1.0
            double valoreSup = base * coeffSup
            valoreSup -= (valoreSup * riduz) / 100.0
            valoreSup = round(valoreSup, 2)

            strCoeff = fmtCoeff.format(coeff) + " fino a " + fmtInt.format(limite) + strLimiteUM + " poi " + fmtCoeff.format(coeffSup)
            strValore = fmtValuta.format(valore) + " poi " + fmtValuta.format(valoreSup)
        } else {
            strCoeff = fmtCoeff.format(coeff)
            strValore = fmtValuta.format(valore)
        }

        if (valueOnly) {
            descrizione = strValore
        } else {

            if (!(strValore.isEmpty())) {
                strValore = " => " + strValore
            }

            descrizione = "B: " + fmtValuta.format(base) + " - C: " + strCoeff
            if (riduz < 0.0) {
                descrizione += " - M: " + fmtPerc.format(-riduz) + "%" + strValore
            } else {
                descrizione += " - R: " + fmtPerc.format(riduz) + "%" + strValore
            }

            if (!strValore.isEmpty()) {
                switch (tariffa.tipologiaTariffa) {
                    default:
                        break
                    case TariffaDTO.TAR_TIPOLOGIA_PERMANENTE:
                        descrizione += " / Anno"
                        break
                    case TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA:
                        descrizione += " / Giorno"
                        break
                }
            }
        }

        return descrizione
    }

    // Esegue verifica su dati della Tariffa e crea messaggio di avvertimento
    def verificaTariffa(TariffaDTO tariffa, String tipoTributo) {

        String message = ""
        Integer result = 0

        tariffa.accorpaFlag()

        if (tariffa.tipoTariffa == null || tariffa.tipoTariffa < 0 || tariffa.tipoTariffa > 99) {
            message += "Tipo non valido, deve essere compreso tra 0 e 99\n"
        }

        // Frontespizio
        Integer anno = tariffa.anno
        if (tipoTributo == 'CUNI') {
            if ((anno < 2021) || (anno > 2999)) {
                message += "Valore di Anno non valido, deve essere compreso tra 2021 e 2999\n"
            }
        } else {
            if ((anno < 1900) || (anno > 2999)) {
                message += "Valore di Anno non valido, deve essere compreso tra 1900 e 2999\n"
            }
        }

        String descrizione = tariffa.descrizione ?: ''
        def length = descrizione.size()

        if (length < 5) {
            message += "Descrizione troppo breve, inserire almento 5 caratteri\n"
        } else {
            if (length > 60) {
                message += "Descrizione troppo lunga, massimo 60 caratteri ammessi\n"
            }
        }

        if (tipoTributo == 'CUNI') {
            if (tariffa.tipologiaTariffa == null) {
                message += "Tipo Canone non impostato correttamente !\n"
            }
            if (tariffa.categoria == null) {
                message += "Zona non impostata correttamente !\n"
            }
            if (tariffa.tipologiaSecondaria == null) {
                message += "Tributo Secondario non impostato correttamente !\n"
            }
            if (tariffa.tipologiaCalcolo == null) {
                message += "Modalita' Limite non impostata correttamente !\n"
            }
        } else {
            if (tariffa.categoria == null) {
                message += "Categoria non impostata correttamente !\n"
            }
        }

        // Dati tariffa
        def base = tariffa.tariffaQuotaFissa ?: 0
        def percRiduzione = tariffa.percRiduzione ?: 0

        def riduzioneQuotaF = tariffa.riduzioneQuotaFissa ?: 0
        def riduzioneQuotaV = tariffa.riduzioneQuotaVariabile ?: 0

        if (tipoTributo == 'CUNI') {
            if ((base < 0.01) || (base > 999999.99999)) {
                message += "Valore di Base non valido : indicare un numero tra 0.01 e 99999999.99999\n"
            }
        } else {
            if ((base < 0.0) || (base > 999999.99999)) {
                message += "Valore di Tar.Quota Fissa non valido : indicare un numero tra 0.01 e 99999999.99999, oppure lasciare vuoto\n"
            }
        }

        if (tipoTributo == 'CUNI') {
            if ((percRiduzione < -1000.0) || (percRiduzione > 100.00)) {
                message += "Valore di % Riduz. o Magg. non valido : indicare un numero tra -1000.00 e 100.00, oppure lasciare vuoto\n"
            }
            /// Per motivi storici CUNI usa questo campo in modo diverso - Tipo tariffa secondaria TAR_SECONDARIA_xxxx - Vedi tariffa.accorpaFlag()
        /// if ((riduzioneQuotaF < 0.0) || (riduzioneQuotaF > 100.00)) {
        ///     message += "Valore di Riduzione Q.F. non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
        /// }
            /// Per motivi storici CUNI usa questo campo in modo diverso - Tipologia tariffa TAR_TIPOLOGIA_xxxx - Vedi tariffa.accorpaFlag()
        /// if ((riduzioneQuotaV < 0.0) || (riduzioneQuotaV > 100.00)) {
        ///     message += "Valore di Riduzione Q.V. non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
        /// }
        }
        else {
            if ((percRiduzione < 0.0) || (percRiduzione > 100.00)) {
                message += "Valore di %Rid.M.T. non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
            }
            if ((riduzioneQuotaF < 0.0) || (riduzioneQuotaF > 100.00)) {
                message += "Valore di %Rid.QF non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
            }
            if ((riduzioneQuotaV < 0.0) || (riduzioneQuotaV > 100.00)) {
                message += "Valore di %Rid.QV non valido : indicare un numero tra 0.00 e 100.00, oppure lasciare vuoto\n"
            }
        }

        def coefficiente = tariffa.tariffa ?: -1
        def limite = tariffa.limite ?: 0
        def coefficienteSup = tariffa.tariffaSuperiore ?: 0

        if (tipoTributo == 'CUNI') {
            if ((coefficiente < 0.001) || (coefficiente > 100.0)) {
                message += "Valore di Coefficiente non valido : indicare un numero tra 0.001 e 100.000\n"
            }
            if (limite != 0.0) {
                if ((coefficienteSup < 0.001) || (coefficienteSup > 100.0)) {
                    message += "Valore di Coeff.Sup. non valido : indicare un numero tra 0.001 e 100.000\n"
                }
            } else {
                if (coefficienteSup != 0) {
                    message += "Coeff.Sup. deve essere vuoto se Limite non specificato\n"
                }
            }
        } else {
            if ((coefficiente < 0.0) || (coefficiente > 999999.99999)) {
                message += "Valore di Tariffa non valido : indicare un numero tra 0.00001 e 999999.99999, oppure lasciare vuoto\n"
            }
            if (limite != 0.0) {
                if ((coefficienteSup < 0.00001) || (coefficienteSup > 999999.99999)) {
                    message += "Valore di Tar.Sup. non valido : indicare un numero tra 0.00001 e 999999.99999\n"
                }
            } else {
                if (coefficienteSup != 0) {
                    message += "Tar.Sup. deve essere vuoto se Limite non specificato\n"
                }
            }
        }

        if ((limite < 0.0) || (limite > 999999.99999)) {
            message += "Valore di Limite non valido : indicare un numero tra 0.00001 e 999999.99999, oppure lasciare vuoto\n"
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Duplica la tariffa
    def duplicaTariffa(TariffaDTO tariffaOrg, boolean copia) {

        TariffaDTO tariffa

        tariffa = new TariffaDTO()

        tariffa.anno = tariffaOrg.anno
        tariffa.categoria = tariffaOrg.categoria
        tariffa.tipoTariffa = tariffaOrg.tipoTariffa

        tariffa.descrizione = copia ? "${tariffaOrg.descrizione} (Copia)" : tariffaOrg.descrizione
        tariffa.tariffa = tariffaOrg.tariffa
        tariffa.percRiduzione = tariffaOrg.percRiduzione
        tariffa.limite = tariffaOrg.limite
        tariffa.tariffaSuperiore = tariffaOrg.tariffaSuperiore
        tariffa.limitePrec = tariffaOrg.limitePrec
        tariffa.tariffaPrec = tariffaOrg.tariffaPrec
        tariffa.tariffaSuperiorePrec = tariffaOrg.tariffaSuperiorePrec
        tariffa.tariffaQuotaFissa = tariffaOrg.tariffaQuotaFissa

        tariffa.ente = tariffaOrg.ente

        tariffa.flagTariffaBase = tariffaOrg.flagTariffaBase
        tariffa.riduzioneQuotaFissa = tariffaOrg.riduzioneQuotaFissa
        tariffa.riduzioneQuotaVariabile = tariffaOrg.riduzioneQuotaVariabile

        tariffa.tipologiaTariffa = tariffaOrg.tipologiaTariffa
        tariffa.tipologiaCalcolo = tariffaOrg.tipologiaCalcolo
        tariffa.tipologiaSecondaria = tariffaOrg.tipologiaSecondaria
        tariffa.flagNoDepag = tariffaOrg.flagNoDepag

        return tariffa
    }

    // Copia dati tariffa da altra annualita'
    def copiaTariffaDaAnnualita(TariffaDTO tariffa, Short copiaDaAnno) {

        def report = [
                message: '',
                result : 0
        ]

        TariffaDTO tariffaOrg = getTariffaDaAnnualita(tariffa, copiaDaAnno)

        if (tariffaOrg == null) {
            report.message = "Tariffa non trovata per l'anno ${copiaDaAnno}"
            report.result = 2
        } else {

            tariffa.descrizione = tariffaOrg.descrizione
            tariffa.tariffa = tariffaOrg.tariffa
            tariffa.percRiduzione = tariffaOrg.percRiduzione
            tariffa.limite = tariffaOrg.limite
            tariffa.tariffaSuperiore = tariffaOrg.tariffaSuperiore
            tariffa.limitePrec = tariffaOrg.limitePrec
            tariffa.tariffaPrec = tariffaOrg.tariffaPrec
            tariffa.tariffaSuperiorePrec = tariffaOrg.tariffaSuperiorePrec
            tariffa.tariffaQuotaFissa = tariffaOrg.tariffaQuotaFissa

            tariffa.ente = tariffaOrg.ente

            tariffa.flagTariffaBase = tariffaOrg.flagTariffaBase
            tariffa.riduzioneQuotaFissa = tariffaOrg.riduzioneQuotaFissa
            tariffa.riduzioneQuotaVariabile = tariffaOrg.riduzioneQuotaVariabile

            tariffa.tipologiaTariffa = tariffaOrg.tipologiaTariffa
            tariffa.tipologiaCalcolo = tariffaOrg.tipologiaCalcolo
            tariffa.tipologiaSecondaria = tariffaOrg.tipologiaSecondaria
            tariffa.flagNoDepag = tariffaOrg.flagNoDepag
        }

        return report
    }

    // Cerca una tariffa per un anno specifico
    def getTariffaDaAnnualita(TariffaDTO tariffa, Short annualita) {

        TariffaDTO tariffaPerAnno

        def tariffe = Tariffa.createCriteria().list {
            eq("categoria.id", tariffa.categoria.id)
            eq("tipoTariffa", tariffa.tipoTariffa)
            eq("anno", annualita)
        }
        if (tariffe.size() > 0) {
            tariffaPerAnno = tariffe[0].toDTO(['categoria', 'categoria.codiceTributo'])
            tariffaPerAnno.estraiFlag()
        }

        return tariffaPerAnno
    }

    // Salva la Tariffa
    def salvaTariffa(TariffaDTO tariffaDTO) {

        String message = ''
        Integer result = 0

        try {
            Tariffa tariffaSalva = tariffaDTO.getDomainObject()
            if (tariffaSalva == null) {

                def tipoTariffa = tariffaDTO.tipoTariffa

                if (tipoTariffa == 0) {

                    tipoTariffa = getNuovoTipoTariffa(tariffaDTO)
                } else {
                    if (checkTariffaEsistente(tariffaDTO)) {
                        throw new Exception("Esiste gia' una tariffa con queste caratteristiche ")
                    }
                }

                TariffaRaw tariffaRaw = new TariffaRaw()

                tariffaRaw.anno = tariffaDTO.anno
                tariffaRaw.tributo = tariffaDTO.categoria.codiceTributo.id
                tariffaRaw.categoria = tariffaDTO.categoria.categoria
                tariffaRaw.tipoTariffa = tipoTariffa

                tariffaRaw.descrizione = tariffaDTO.descrizione
                tariffaRaw.tariffa = tariffaDTO.tariffa
                tariffaRaw.percRiduzione = tariffaDTO.percRiduzione
                tariffaRaw.limite = tariffaDTO.limite
                tariffaRaw.tariffaSuperiore = tariffaDTO.tariffaSuperiore
                tariffaRaw.limitePrec = tariffaDTO.limitePrec
                tariffaRaw.tariffaPrec = tariffaDTO.tariffaPrec
                tariffaRaw.tariffaSuperiorePrec = tariffaDTO.tariffaSuperiorePrec
                tariffaRaw.tariffaQuotaFissa = tariffaDTO.tariffaQuotaFissa
                tariffaRaw.flagTariffaBase = tariffaDTO.flagTariffaBase
                tariffaRaw.riduzioneQuotaFissa = tariffaDTO.riduzioneQuotaFissa
                tariffaRaw.riduzioneQuotaVariabile = tariffaDTO.riduzioneQuotaVariabile
                tariffaRaw.flagNoDepag = tariffaDTO.flagNoDepag

                tariffaRaw.save(flush: true, failOnError: true)
            } else {

                tariffaSalva.descrizione = tariffaDTO.descrizione
                tariffaSalva.tariffa = tariffaDTO.tariffa
                tariffaSalva.percRiduzione = tariffaDTO.percRiduzione
                tariffaSalva.limite = tariffaDTO.limite
                tariffaSalva.tariffaSuperiore = tariffaDTO.tariffaSuperiore
                tariffaSalva.limitePrec = tariffaDTO.limitePrec
                tariffaSalva.tariffaPrec = tariffaDTO.tariffaPrec
                tariffaSalva.tariffaSuperiorePrec = tariffaDTO.tariffaSuperiorePrec
                tariffaSalva.tariffaQuotaFissa = tariffaDTO.tariffaQuotaFissa
                tariffaSalva.flagTariffaBase = tariffaDTO.flagTariffaBase
                tariffaSalva.riduzioneQuotaFissa = tariffaDTO.riduzioneQuotaFissa
                tariffaSalva.riduzioneQuotaVariabile = tariffaDTO.riduzioneQuotaVariabile
                tariffaSalva.flagNoDepag = tariffaDTO.flagNoDepag

                tariffaSalva.save(flush: true, failOnError: true)
            }
        }
        catch (Exception e) {
            e.printStackTrace()
            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina la tariffa
    def eliminaTariffa(TariffaDTO tariffaDTO) {

        String message = ''
        Integer result = 0

        Tariffa tariffaSalva = tariffaDTO.getDomainObject()
        if (tariffaSalva == null) {

            message = "Tariffa non registrata in banca dati "
            result = 2
        } else {

            try {
                tariffaSalva.delete(flush: true)
            }
            catch (Exception e) {

                if (e?.message?.startsWith("ORA-20999")) {
                    message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                    message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else {
                    message += e.message
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Verifica se esiste un altra tariffa con queste caratteristiche -> true se esiste
    def checkTariffaEsistente(TariffaDTO tariffa) {

        def filtri = [:]

        filtri << ['anno': tariffa.anno]
        filtri << ['tributo': tariffa.categoria.codiceTributo.id]
        filtri << ['categoria': tariffa.categoria.categoria]
        filtri << ['tipoTariffa': tariffa.tipoTariffa ?: 0]

        String sql = """
		        SELECT
		          COUNT(TARI.TIPO_TARIFFA) AS CONTATORE
		        FROM
		          TARIFFE TARI
		        WHERE
		          TARI.ANNO = :anno AND
		          TARI.TRIBUTO = :tributo AND
		          TARI.CATEGORIA = :categoria AND
		          TARI.TIPO_TARIFFA = :tipoTariffa
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        def occorrenze = (totali.CONTATORE ?: 0) as Integer

        return (occorrenze > 0)
    }

    // Verifica se tariffa eliminabile
    def checkTariffaEliminabile(TariffaDTO tariffa) {

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call TARIFFE_PD(?,?,?,?)}',
                    [
                            tariffa.categoria.codiceTributo.id,
                            tariffa.categoria.categoria,
                            tariffa.anno,
                            tariffa.tipoTariffa
                    ]
            )

            return ''
        }
        catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    // Verifica se la tariffa risulti utilizzzata o meno -> true se utilizzata
    def checkTariffaUtilizzata(TariffaDTO tariffa) {

        def filtri = [:]

        filtri << ['tributo': tariffa.categoria.codiceTributo.id]
        filtri << ['categoria': tariffa.categoria.categoria]
        filtri << ['tipoTariffa': tariffa.tipoTariffa]

        String sql = """
				SELECT
	              COUNT(OGPR.OGGETTO_PRATICA) AS CONTATORE
	            FROM
	              OGGETTI_PRATICA OGPR
	            WHERE
	              OGPR.TRIBUTO = :tributo AND
	              OGPR.CATEGORIA = :categoria AND
	              OGPR.TIPO_TARIFFA = :tipoTariffa
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        def occorrenze = (totali.CONTATORE ?: 0) as Integer

        return (occorrenze > 0)
    }

    // Ritorna prossimo tipo tariffa, escluso esenzione
    def getNuovoTipoTariffa(TariffaDTO tariffa) {

        Integer tipoTariffa = 0

        def filtri = [:]

        filtri << ['anno': tariffa.anno]
        filtri << ['tributo': tariffa.categoria.codiceTributo.id]

        String sql = """
				SELECT
					MAX(TARI.TIPO_TARIFFA) AS ULTIMO_TIPO
				FROM
					TARIFFE TARI
				WHERE
					TARI.ANNO = :anno AND
					TARI.TRIBUTO = :tributo AND
					TARI.TIPO_TARIFFA <> 99
		"""

        def totali = eseguiQuery("${sql}", filtri, null, true)[0]
        tipoTariffa = (totali.ULTIMO_TIPO ?: 0) as Integer

        if (tipoTariffa > 98) {
            throw new Exception("Nessun Tipo Tariffa automatico disponibile, specificare manualemnte ")
        }

        return tipoTariffa + 1
    }

    // Ricava elenco anni da scadenze per tributo
    def getAnnualitaInScadenze(String tipoTributo) {

        List<Short> listaAnni = Scadenza.createCriteria().list() {
            projections {
                groupProperty('anno')
                order('anno', 'desc')
            }
            if (tipoTributo) {
                eq('tipoTributo.tipoTributo', tipoTributo)
            }
        }

        return listaAnni
    }

    def getDescrizioneRataScadenza(def codice) {
        switch (codice) {
            default:
                return ""
            case null:
                return "-"
            case 0:
                return "Unica"
            case 1:
                return "Prima"
            case 2:
                return "Seconda"
            case 3:
                return "Terza"
            case 4:
                return "Quarta"
            case 5:
                return "Quinta"
            case 6:
                return "Sesta"
        }
    }

    def getDescrizioneTipoScadenza(def codice) {
        switch (codice) {
            default:
                return ""
            case null:
                return "-"
            case 'D':
                return "Dichiarazione"
            case 'V':
                return "Versamento"
            case 'T':
                return "Terremoto"
            case 'R':
                return "Ravvedimento"
        }
    }

    def getDescrizioneVersamentoScadenza(def codice) {
        switch (codice) {
            default:
                return ""
            case null:
                return "-"
            case 'A':
                return "Acconto"
            case 'S':
                return "Saldo"
            case 'U':
                return "Unico"
        }
    }

    // Ricava elenco scadenze per anno e per tributo
    def getElencoScadenze(def filtri) {

        List scadenze = []

        TipoTributo tipoTributoObj = TipoTributo.findByTipoTributo(filtri.tipoTributo)
        List<GruppoTributo> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoObj)

        Scadenza.createCriteria().list {

            fetchMode('tipoTributo', FetchMode.JOIN)

            if (filtri?.tipoTributo) {
                eq('tipoTributo.tipoTributo', filtri.tipoTributo)
            }
            if (filtri?.anno) {
                eq('anno', filtri.anno as Short)
            }
            if (filtri?.rata != null) {
                eq('rata', filtri.rata as Short)
            }
            if (filtri?.tipoScadenza) {
                eq('tipoScadenza', filtri.tipoScadenza)
            }
            if (filtri?.tipoVersamento) {
                eq('tipoVersamento', filtri.tipoVersamento)
            }
            if (filtri?.da) {
                ge('dataScadenza', filtri.da)
            }
            if (filtri?.a) {
                le('dataScadenza', filtri.a)
            }
        }.toDTO().sort { a, b ->
            (((((a.gruppoTributo <=> b.gruppoTributo) ?: (b.anno <=> a.anno) ?: a.tipoOccupazione?.tipoOccupazione <=> b.tipoOccupazione?.tipoOccupazione) ?:
                    a.tipoScadenza <=> b.tipoScadenza) ?: a.rata <=> b.rata) ?: a.dataScadenza <=> b.dataScadenza)
        }.each {
            def scadenza = [:]

            scadenza.dto = it

            scadenza.id = it.id
            scadenza.anno = it.anno
            scadenza.dataScadenza = it.dataScadenza
            scadenza.sequenza = it.sequenza

			scadenza.gruppoTributo = gruppiTributo.find { g -> g.gruppoTributo == it.gruppoTributo} ?.descrizione
            scadenza.tipoOccupazione = it.tipoOccupazione?.tipoOccupazione

            scadenza.rata = getDescrizioneRataScadenza(it.rata)
            scadenza.tipoScadenza = getDescrizioneTipoScadenza(it.tipoScadenza)
            scadenza.tipoVersamento = getDescrizioneVersamentoScadenza(it.tipoVersamento)

            scadenze << scadenza
        }

        return scadenze
    }

    // Conta le scadenze presenti per annualita
    def contaScadenzePerAnnualita(def filtri) {

        Short anno = filtri.annoTributo
        String tipoTributo = filtri.tipoTributo ?: '-'

        def conteggio = Scadenza.createCriteria().count() {
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('anno', anno)
        }

        return conteggio
    }

    // Copia scadenze corrispondenti con filtro su nuova annualita, salta eventuali esistenti
    def copiaScadenzeDaAnnualita(def filtri, Short annoDestinazione) {

        def report = [
                message: '',
                result : 0
        ]

        Short annoOrigine = filtri.annoTributo
        String tipoTributo = filtri.tipoTributo ?: '-'

        List<Scadenza> esistenti = Scadenza.createCriteria().list() {
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('anno', annoDestinazione)
        }

        List<Scadenza> origine = Scadenza.createCriteria().list() {
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('anno', annoOrigine)
        }

        origine.each { scadenza ->

            Scadenza esistente = esistenti.find {
                it.anno == annoDestinazione && it.tipoScadenza == scadenza.tipoScadenza &&
                        it.rata == scadenza.rata && it.tipoVersamento == scadenza.tipoVersamento
            }

            if (esistente == null) {
                def reportNow = copiaScadenzaDaAnnualita(scadenza, annoDestinazione)

                if (reportNow.result != 0) {
                    if (!(report.message.isEmpty())) report.message += "\n"
                    report.message += reportNow.message
                    if (report.result < reportNow.result) {
                        report.result = reportNow.result
                    }
                }
            }
        }

        return report
    }

    // Crea copia di scadenza per altra annualita
    def copiaScadenzaDaAnnualita(Scadenza originale, Short annoDestinazione) {

        String message = ""
        Integer result = 0

        Calendar oldDate
        Calendar newDate

        try {
            Scadenza scadenza = new Scadenza()

            scadenza.tipoTributo = originale.tipoTributo
            scadenza.anno = annoDestinazione

            scadenza.gruppoTributo = originale.gruppoTributo
            scadenza.tipoOccupazione = originale.tipoOccupazione

            scadenza.tipoScadenza = originale.tipoScadenza
            scadenza.rata = originale.rata
            scadenza.tipoVersamento = originale.tipoVersamento

            oldDate = new GregorianCalendar()
            oldDate.setTime(originale.dataScadenza)

            newDate = new GregorianCalendar(annoDestinazione, oldDate.get(Calendar.MONTH), oldDate.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
            scadenza.dataScadenza = newDate.getTime()

            scadenza.sequenza = getNuovaSequenzaScadenza(scadenza.toDTO())

            scadenza.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Esegue verifica su dati della Scadenza e crea messaggio di avvertimento
    def verificaScadenza(ScadenzaDTO scadenza) {

        String message = ""
        Integer result = 0

        // Frontespizio
        Integer anno = scadenza.anno
        if ((anno < 2000) || (anno > 2099)) {
            message += "Valore di Anno non valido\n"
        }

        // Dati scadenza
        if (scadenza.tipoScadenza == null) {
            message += "Tipo Scadenza non impostato correttamente\n"
        }

        def rata = scadenza.rata ?: 0
        if ((rata < 0) || (rata > 6)) {
            message += "Rata non impostato correttamente\n"
        }

        if (scadenza.dataScadenza == null) {
            message += "Scadenza non impostata correttamente\n"
        }

        def scadenzeFromDB = []

        if (scadenza.tipoScadenza == 'D' || scadenza.tipoScadenza == 'R') {

            // Controllo se nel caso del ravvedimento non sono stati impostati rata e tipo versamento (non controllato dalla procedure)
            if (scadenza.tipoScadenza == 'R' && (scadenza.rata != null || scadenza.tipoVersamento != null)) {
                message += "Tipo scadenza e rata-tipo versamento non coerenti\n"
            } else {

                scadenzeFromDB = getScadenzeByAnnoAndTipoTributo(scadenza.anno, scadenza.tipoTributo)

                if (!scadenzeFromDB.empty) {

                    def errore = false
                    scadenzeFromDB.each {

                        // Basta trovare un'inconsistenza, il resto potrebbe riportare a false la variabile errore
                        if (!errore) {
                            errore = (it.sequenza != (scadenza.sequenza ?: 0)) && (it.tipoScadenza == scadenza.tipoScadenza)
                        }
                    }
                    if (errore) {
                        message += "Esiste gia' una scadenza con lo stesso Anno e Tipo Tributo\n"
                    }
                }
            }

        } else if (scadenza.tipoScadenza == 'V' || scadenza.tipoScadenza == 'T') {

            // La mancanza o presenza di entrambi i parametri (rata e tipoVersamento) viene controllata da procedure db

            scadenzeFromDB = getScadenzeByAnnoAndTipoTributoAndTipoVersamentoOrRata(scadenza.anno, scadenza.tipoTributo, scadenza.tipoVersamento, scadenza.rata,
                    scadenza.gruppoTributo, scadenza.tipoOccupazione)

            if (!scadenzeFromDB.empty) {

                def errore = false
                scadenzeFromDB.each {

                    // Basta trovare un'inconsistenza, il resto delle entry potrebbe riportare a false la variabile errore
                    if (!errore) {

                        if (scadenza.rata != null) {
                            errore = (it.sequenza != (scadenza.sequenza ?: 0) &&
                                    (it.tipoScadenza == scadenza.tipoScadenza) &&
                                    it.rata != null && it.rata == scadenza.rata)
                        } else if (scadenza.tipoVersamento != null) {
                            errore = (it.sequenza != (scadenza.sequenza ?: 0) &&
                                    (it.tipoScadenza == scadenza.tipoScadenza) &&
                                    it.tipoVersamento != null && it.tipoVersamento == scadenza.tipoVersamento)
                        }
                    }
                }
                if (errore) {

                    if (scadenza.rata != null) {
                        message += "Esiste gia' una scadenza con lo stesse caratteristiche\n"
                    } else if (scadenza.tipoVersamento != null) {
                        message += "Esiste gia' una scadenza con lo stesso Anno, Tipo Tributo e Tipo Versamento\n"
                    }
                }
            }
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    // Duplica la scadenza
    def duplicaScadenza(ScadenzaDTO originale, boolean copia) {

        ScadenzaDTO scadenza

        scadenza = new ScadenzaDTO()

        scadenza.anno = originale.anno
        scadenza.tipoTributo = originale.tipoTributo

        scadenza.gruppoTributo = originale.gruppoTributo
        scadenza.tipoOccupazione = originale.tipoOccupazione

        scadenza.tipoScadenza = originale.tipoScadenza
        scadenza.rata = originale.rata
        scadenza.tipoVersamento = originale.tipoVersamento
        scadenza.dataScadenza = originale.dataScadenza

        return scadenza
    }

    // Salva la Scadenza
    def salvaScadenza(ScadenzaDTO scadenzaDTO) {

        String message = ''
        Integer result = 0

        try {
            Scadenza scadenzaSalva = scadenzaDTO.getDomainObject()
            if (scadenzaSalva == null) {

                Short sequenza = scadenzaDTO.sequenza

                if ((sequenza ?: (short) 0) == (short) 0) {
                    sequenza = getNuovaSequenzaScadenza(scadenzaDTO) as Short
                }

                scadenzaSalva = new Scadenza()

                scadenzaSalva.anno = scadenzaDTO.anno
                scadenzaSalva.tipoTributo = scadenzaDTO.tipoTributo.getDomainObject()
                scadenzaSalva.sequenza = sequenza
            }

            scadenzaSalva.rata = scadenzaDTO.rata
            scadenzaSalva.gruppoTributo = scadenzaDTO.gruppoTributo
            scadenzaSalva.tipoOccupazione = scadenzaDTO.tipoOccupazione
            scadenzaSalva.tipoScadenza = scadenzaDTO.tipoScadenza
            scadenzaSalva.tipoVersamento = scadenzaDTO.tipoVersamento
            scadenzaSalva.dataScadenza = scadenzaDTO.dataScadenza

            scadenzaSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina la Scadenza
    def eliminaScadenza(ScadenzaDTO scadenzaDTO) {

        String message = ''
        Integer result = 0

        Scadenza scadenzaSalva = scadenzaDTO.getDomainObject()
        if (scadenzaSalva == null) {

            message = "Scadenza non registrata in banca dati "
            result = 2
        } else {

            try {
                scadenzaSalva.delete(flush: true)
            }
            catch (Exception e) {

                if (e?.message?.startsWith("ORA-20999")) {
                    message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                    message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else {
                    message += e.message
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Ricava nuova sequenza per la Scadenza
    def getNuovaSequenzaScadenza(ScadenzaDTO scadenza) {

        Short sequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call SCADENZE_NR(?, ?, ?)}',
                [
                        scadenza.tipoTributo.tipoTributo,
                        scadenza.anno,
                        Sql.NUMERIC
                ],
                { sequenza = it }
        )

        return sequenza
    }

    // Ricava elenco Limiti Calcolo per anno e per tributo
    def getElencoLimitiCalcolo(def filtri) {

        List<LimiteCalcoloDTO> limitiCalcoloDTO = []

        def tipoTributo = filtri.tipoTributo
        def annoTributo = filtri.annoTributo


        TipoTributo tipoTributoObj = TipoTributo.findByTipoTributo(tipoTributo)
        if (annoTributo != null) {
            limitiCalcoloDTO = LimiteCalcolo.findAllByTipoTributoAndAnno(tipoTributoObj, annoTributo).toDTO()
        } else {
            limitiCalcoloDTO = LimiteCalcolo.findAllByTipoTributo(tipoTributoObj).toDTO()
        }

        List<GruppoTributo> gruppiTributo = GruppoTributo.findAllByTipoTributo(tipoTributoObj)

        limitiCalcoloDTO.sort { a, b ->
            int cmp = b.anno <=> a.anno
            if (cmp != 0) {
                return cmp
            }
            return (a.gruppoTributo <=> b.gruppoTributo)
        }

        def limitiCalcolo = []

        limitiCalcoloDTO.each {

            def limiteCalcolo = [:]

            limiteCalcolo.dto = it

            limiteCalcolo.id = it.id
            limiteCalcolo.anno = it.anno

            limiteCalcolo.tipoOccupazione = it.tipoOccupazione?.descrizione

			limiteCalcolo.gruppoTributo = gruppiTributo.find { g -> g.gruppoTributo == it.gruppoTributo} ?.descrizione

            limitiCalcolo << limiteCalcolo
        }

        return limitiCalcolo
    }

    // Esegue verifica su dati del Limite Calcolo e crea messaggio di avvertimento
    def verificaLimiteCalcolo(LimiteCalcoloDTO limiteCalcolo) {

        String message = ""
        Integer result = 0

        TipoTributo tipoTributo = limiteCalcolo.tipoTributo.toDomain()
        String gruppoTributo = limiteCalcolo.gruppoTributo
        TipoOccupazione tipoOccupazione = limiteCalcolo?.tipoOccupazione

        // Frontespizio
        Integer anno = limiteCalcolo.anno
        if ((anno < 2000) || (anno > 2099)) {
            message += "Valore di Anno non valido\n"
        }

        if (limiteCalcolo.limiteImposta == null && limiteCalcolo.limiteViolazione == null && limiteCalcolo.limiteRata == null) {
            message += "Obbligatorio impostare almeno un Limite\n"
        }

        def fromDB = LimiteCalcolo.findAllByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazione(anno, tipoTributo, gruppoTributo, tipoOccupazione)

        if (!fromDB.empty) {

            def errore = false
            fromDB.each {

                if (!errore) {
                    errore = (it.sequenza != (limiteCalcolo.sequenza ?: 0))
                }
            }
            if (errore) {
                message += "Esiste gia' un Limite Calcolo con lo stesso Anno, Tipo Tributo, Gruppo Tributo e Tipo Occupazione\n"
            }
        }

        // Fine
        if (message.size() > 0) result = 1

        return [result: result, message: message]
    }

    def duplicaLimiteCalcolo(LimiteCalcoloDTO limiteCalcolo) {
        return commonService.clona(limiteCalcolo)
    }

    // Salva il Limite Calcolo
    def salvaLimiteCalcolo(LimiteCalcoloDTO limiteCalcoloDTO) {

        String message = ''
        Integer result = 0

        try {
            LimiteCalcolo limiteCalcoloSalva = limiteCalcoloDTO.getDomainObject()
            if (limiteCalcoloSalva == null) {

                Short sequenza = limiteCalcoloDTO.sequenza

                if ((sequenza ?: (short) 0) == (short) 0) {
                    sequenza = getNuovaSequenzaLimiteCalcolo(limiteCalcoloDTO) as Short
                }

                limiteCalcoloSalva = new LimiteCalcolo()

                limiteCalcoloSalva.tipoTributo = limiteCalcoloDTO.tipoTributo.getDomainObject()
                limiteCalcoloSalva.anno = limiteCalcoloDTO.anno
                limiteCalcoloSalva.sequenza = sequenza
            }

            limiteCalcoloSalva.gruppoTributo = limiteCalcoloDTO.gruppoTributo
            limiteCalcoloSalva.tipoOccupazione = limiteCalcoloDTO.tipoOccupazione

            limiteCalcoloSalva.limiteImposta = limiteCalcoloDTO.limiteImposta
            limiteCalcoloSalva.limiteViolazione = limiteCalcoloDTO.limiteViolazione
            limiteCalcoloSalva.limiteRata = limiteCalcoloDTO.limiteRata

            limiteCalcoloSalva.save(flush: true, failOnError: true)
        }
        catch (Exception e) {

            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                if (result < 1) result = 1
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                if (result < 1) result = 1
            } else {
                message += e.message
                if (result < 2) result = 2
            }
        }

        return [result: result, message: message]
    }

    // Elimina il Limite Calcolo
    def eliminaLimiteCalcolo(LimiteCalcoloDTO limiteCalcoloDTO) {

        String message = ''
        Integer result = 0

        LimiteCalcolo limiteCalcoloSalva = limiteCalcoloDTO.getDomainObject()
        if (limiteCalcoloSalva == null) {

            message = "Limite Calcolo non registrato in banca dati "
            result = 2
        } else {

            try {
                limiteCalcoloSalva.delete(flush: true)
            }
            catch (Exception e) {

                if (e?.message?.startsWith("ORA-20999")) {
                    message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                    message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                    if (result < 1) result = 1
                } else {
                    message += e.message
                    if (result < 2) result = 2
                }
            }
        }

        return [result: result, message: message]
    }

    // Ricava nuova sequenza per la Scadenza
    def getNuovaSequenzaLimiteCalcolo(LimiteCalcoloDTO limiteCalcolo) {

        Short sequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call LIMITI_CALCOLO_NR(?, ?, ?)}',
                [
                        limiteCalcolo.tipoTributo.tipoTributo,
                        limiteCalcolo.anno,
                        Sql.NUMERIC
                ],
                { sequenza = it }
        )

        return sequenza
    }

    // Riporta tipi oggetto validi per tipo tributo
    def getTipiOggetto(String tipoTributo) {

        List<TipoOggettoDTO> listaTipiOggetto = []

        def lista = OggettoTributo.createCriteria().listDistinct {
            eq("tipoTributo.tipoTributo", tipoTributo)
            order("tipoOggetto", "asc")
        }.toDTO().tipoOggetto.tipoOggetto

        lista.each {
            def tipoOggetto = it
            if (listaTipiOggetto.find { it.tipoOggetto == tipoOggetto } == null) {
                listaTipiOggetto.add(TipoOggetto.findByTipoOggetto(tipoOggetto).toDTO())
            }
        }

        return listaTipiOggetto
    }

    // Ottiene Fonte Inserimento Concessione - Basato su metodo diContribuentiService
    private getFonteInserimentoConcessioni() {

        def descrizione = "INSERIMENTO CONCESSIONI"
        def fonte = Fonte.findByDescrizione(descrizione)
        if (fonte == null) {

            def id = 8
            fonte = new Fonte([fonte: id, descrizione: descrizione])
            fonte.save(failOnError: true, flush: true)
        }

        return fonte
    }

    // Ottiene Fonte Inserimento Concessione - Basato su metodo diContribuentiService
    private getFonteInserimentoCanoni() {

        def descrizione = "INSERIMENTO CANONI"
        def fonte = Fonte.findByDescrizione(descrizione)
        if (fonte == null) {

            def id = 8
            fonte = new Fonte([fonte: id, descrizione: descrizione])
            fonte.save(failOnError: true, flush: true)
        }

        return fonte
    }

    // Ottiene Fonte automatica per dichiarazioni - Basato su metodo medesimo in ContribuentiService
    private getFonteInserimentoAutomatico() {

        def descrizione = "INSERIMENTO AUTOMATICO DICHIARAZIONI"
        def fonte = Fonte.findByDescrizione(descrizione)
        if (fonte == null) {

            def id = 86
            fonte = new Fonte([fonte: id, descrizione: descrizione])
            fonte.save(failOnError: true, flush: true)
        }

        return fonte
    }

    // Arrotonda double
    static double round(double value, int places) {

        if (places < 0) throw new IllegalArgumentException()

        BigDecimal bd = value as BigDecimal
        bd = bd.setScale(places, RoundingMode.HALF_UP)
        return bd.doubleValue()
    }

    @Transactional
    private def annullaDovutoDepag(def idBack) {

        String funzione

        funzione = "PAGONLINE_TR4.annullamento_dovuto"

        try {
            def pUtente = "TR4"

            String r

            Sql sql = new Sql(dataSource)

            sql.call('{? = call ' + funzione + '(?, ?, ?)}', [Sql.VARCHAR, null, idBack, pUtente]) {

                r = it
            }

            return r
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
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

    def getScadenzePerGruppoTributo(Short anno, String tipoOccupazione) {

        def filtri = [:]

        filtri << ['tipoTributo' : 'CUNI']

        filtri << ['anno' : anno]
        filtri << ['tipoOccupazione' : tipoOccupazione]

        String sql = """
                select
                    scad.gruppo_tributo,
                    count(*) as num_rate
                from
                    scadenze scad
                where 
                    scad.tipo_tributo = :tipoTributo
                    and scad.tipo_scadenza = 'V'
                    and scad.anno = :anno
                    and nvl(scad.tipo_occupazione,:tipoOccupazione) = :tipoOccupazione
                group by
                    scad.gruppo_tributo
        """

        def results = eseguiQuery("${sql}", filtri, null, true)

        def rateGruppi = []

        results.each {

            def rateGruppo = [:]

            rateGruppo.nomeGruppo = it['GRUPPO_TRIBUTO']
            rateGruppo.numRate = it['NUM_RATE']

            rateGruppi << rateGruppo
        }

        Boolean scadenzePerGruppo
        def gruppiConScadenze = []

        def rateGruppiConNome = rateGruppi.findAll { it.nomeGruppo != null }

        if((rateGruppi.size() <= 1) && (rateGruppiConNome.size() == 0)) {
            scadenzePerGruppo = false
        }
        else {
            scadenzePerGruppo = true
            gruppiConScadenze = rateGruppiConNome.collect { it.nomeGruppo }
        }

        return [ scadenzePerGruppo : scadenzePerGruppo, gruppiConScadenze : gruppiConScadenze ]
    }

    def getScadenzeByAnnoAndTipoTributo(Short anno, TipoTributoDTO tipoTributo) {

        return Scadenza.findAllByAnnoAndTipoTributo(anno, tipoTributo.toDomain())
    }

    /**
     * Ottiene le scadenze con lo stesso tipoVersamento o con la stessa rata.
     * Solo uno dei due parametri può essere valorrizato
     */
    def getScadenzeByAnnoAndTipoTributoAndTipoVersamentoOrRata(Short anno, TipoTributoDTO tipoTributo, String tipoVersamento, Short rata, String gruppoTributo = null,
                                                               def tipoOccupazione = null) {

        if (tipoVersamento != null) {
            return Scadenza.findAllByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazioneAndTipoVersamento(anno, tipoTributo.toDomain(), gruppoTributo,
                    tipoOccupazione, tipoVersamento)
        } else if (rata != null) {
            return Scadenza.findAllByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazioneAndRata(anno, tipoTributo.toDomain(), gruppoTributo, tipoOccupazione, rata)
        }
		else {
            return Scadenza.findAllByAnnoAndTipoTributoAndGruppoTributoAndTipoOccupazioneAndTipoVersamentoAndRata(anno, tipoTributo.toDomain(), gruppoTributo,
                    tipoOccupazione, null, null)
        }
    }

    def getListaGruppiTributo(def filter = [:]) {
        GruppoTributo.createCriteria().list {
            eq('tipoTributo.tipoTributo', 'CUNI')
            if (filter.gruppoTributo) {
                ilike('gruppoTributo', filter.gruppoTributo)
            }
            if (filter.descrizione) {
                ilike('descrizione', filter.descrizione)
            }
            order("gruppoTributo", "asc")
        }.toDTO()
    }

    def createGruppoTributo(TipoTributoDTO tipoTributo) {
        return new GruppoTributo(tipoTributo: tipoTributo.toDomain())
    }

    def existsGruppoTributo(GruppoTributo gruppoTributo) {
        GruppoTributo.createCriteria().count {
            eq('gruppoTributo', gruppoTributo.gruppoTributo)
        } > 0
    }

    def salvaGruppoTributo(GruppoTributo gruppoTributo) {
        gruppoTributo.save(failOnError: true, flush: true)
    }

    def eliminaGruppoTributo(GruppoTributo gruppoTributo) {
        gruppoTributo.delete(failOnError: true, flush: true)
    }

    /// Salva i soli dati di geolocalizzazione dell'oggetto, quindi aggiorna la concessione
    def aggiornaGeolocalizzazioneOggetto(def concessione, Boolean aLonLat = false) {

        Long oggettoId = concessione.oggettoRef

        Oggetto oggetto = Oggetto.get(oggettoId)

        println"OG: ${oggetto}"

        if(aLonLat) {
            oggetto.aLatitudine = concessione.oggetto.aLatitudine
            oggetto.aLongitudine = concessione.oggetto.aLongitudine
        }
        else {
            oggetto.latitudine = concessione.oggetto.latitudine
            oggetto.longitudine = concessione.oggetto.longitudine
        }
        oggetto.save(failOnError: true, flush: true)
        
        impostaOggetto(concessione, oggettoId)

        return;
    }

    /// Formatta le coordinate in formato sessagesimale
    def formatCoordinates(def concessione, Boolean aLonLat = false) {

        def oggetto = concessione.oggetto

        def latitudine
        def longitudine

        String latSessages
        String lonSessages
        String geoLocation
        String url

        Integer valid = 0

        if(aLonLat) {
            latitudine = oggetto.aLatitudine
            longitudine = oggetto.aLongitudine
        }
        else {
            latitudine = oggetto.latitudine
            longitudine = oggetto.longitudine
        }

        if(latitudine != null) {
            latSessages = oggettiService.formatCoordinateSexagesimal(latitudine as Double)
            valid++
        }
        else {
            latSessages = ''
        }

        if(longitudine != null) {
            lonSessages = oggettiService.formatCoordinateSexagesimal(longitudine as Double)
            valid++
        }
        else {
            lonSessages = ''
        }

        if(valid) {
            geoLocation = oggettiService.formatCoordinateGoogleMaps(latitudine as Double, 'LAT')
            geoLocation += ', '
            geoLocation +=  oggettiService.formatCoordinateGoogleMaps(longitudine as Double, 'LON')
        }
        else {
            geoLocation = ''
        }

        if(valid == 2) {
            url = getGoogleMapshUrl(concessione, aLonLat)
        }
        else {
            url = ''
        }

        if(aLonLat) {
            oggetto.aLatSessages = latSessages
            oggetto.aLonSessages = lonSessages
            oggetto.aGeoLocation = geoLocation
            oggetto.aGeoLocationURL = url
        }
        else {
            oggetto.latSessages = latSessages
            oggetto.lonSessages = lonSessages
            oggetto.geoLocation = geoLocation
            oggetto.geoLocationURL = url
        }

        return
    }

    /// Determina url di google maps per l'oggetto della concessione
    def getGoogleMapshUrl(def concessione, Boolean aLonLat = false) {

        def oggetto = concessione.oggetto

        def latitudine
        def longitudine

        if(aLonLat) {
            latitudine = oggetto.aLatitudine
            longitudine = oggetto.aLongitudine
        }
        else {
            latitudine = oggetto.latitudine
            longitudine = oggetto.longitudine
        }

        return oggettiService.getGoogleMapshUrl(null, latitudine as Double, longitudine as Double)
    }
}
