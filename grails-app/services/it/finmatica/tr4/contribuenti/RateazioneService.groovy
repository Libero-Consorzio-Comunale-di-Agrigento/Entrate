package it.finmatica.tr4.contribuenti

import groovy.sql.Sql
import it.finmatica.tr4.InstallazioneParametro
import it.finmatica.tr4.Interessi
import it.finmatica.tr4.Versamento
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.rateazione.PianoRimborso
import it.finmatica.tr4.contribuenti.rateazione.PianoRimborsoRata
import it.finmatica.tr4.contribuenti.rateazione.PianoRimborsoTestata
import it.finmatica.tr4.contribuenti.rateazione.PianoRimborsoVersamento
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.RataPratica
import org.apache.log4j.Logger
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.hibernate.transform.Transformers

class RateazioneService {

    private static final Logger log = Logger.getLogger(RateazioneService.class)

    private static final String RATE_CALC = "RATE_CALC"
    private static final String RATE_INT_E = "RATE_INT_E"
    private static final String RATE_ONERI = "RATE_ONERI"

    def tipiRata = [
            M: 'Mensile',
            B: 'Bimestrale',
            T: 'Trimestrale',
            Q: 'Quadrimestrale',
            S: 'Semestrale',
            A: 'Annuale',
            N: '-'
    ]
    def tipiCalcoloRata = [
            V: 'Rate variabili',
            C: 'Rate costanti',
            R: 'Rate costanti per gruppo',
    ]

    static transactional = false
    def dataSource
    def sessionFactory
    def springSecurityService
    CommonService commonService

    def getCalcoloRatePredefinito() {
        return InstallazioneParametro.get(RATE_CALC)?.valore
    }

    def getIntRateSoloEvasaPredefinito() {
        return (InstallazioneParametro.get(RATE_INT_E)?.valore == 'S')
    }

    def getRateOneriPredefinito() {
        // Se non configurato o valorizzato a null si assume per default S (comportamento pre modifica)
        return ((InstallazioneParametro.get(RATE_ONERI)?.valore ?: 'S') == 'S')
    }

    def rateazione(def pratica) {

        try {
            Sql sql = new Sql(dataSource)

            PraticaTributo praticaTributo = PraticaTributo.get(pratica)

            if (praticaTributo.calcoloRate != null) {
                sql.call('{call CALCOLO_RATEAZIONE_AGGI(?, ?)}',
                        [pratica, springSecurityService.currentUser.id])
            } else {
                sql.call('{call CALCOLO_RATEAZIONE(?, ?)}',
                        [pratica, springSecurityService.currentUser.id])
            }

            return PraticaTributo.get(pratica)
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

    }

    def listaTributiF24(def tipoTributo, def desTipoTributo, def tipoCodice, def nullable = false) {
        def sql = """
                    select tributo_f24 "tributoF24", lpad(tributo_f24, 4) || ' - ' || descrizione "descrizione"
                      from codici_f24
                     where tipo_tributo = :tipoTributo
                       and descrizione_titr = :desTipoTributo
                       and tipo_codice = :tipoCodice
                       ${nullable ? "union select to_number(null), '' from dual" : ''}
                     order by 1 asc
                    """

        def records = []
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {

            setString('tipoTributo', tipoTributo)
            setString('desTipoTributo', desTipoTributo)
            setString('tipoCodice', tipoCodice)

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        results.each {
            def record = [:]
            record.key = it.tributoF24
            record.value = it.descrizione

            records << record
        }

        return records

    }

    def calcolaVersamentiPreRateazione(def pratica, def dataRateazione) {
        return Versamento.createCriteria().get {
            projections {
                sum "importoVersato"
            }
            eq("pratica.id", pratica)
            lt("dataPagamento", dataRateazione)
        } as BigDecimal ?: 0
    }

    def elencoRate(def pratica) {
        return RataPratica.createCriteria().list {
            eq("pratica.id", pratica.id)
        }.sort { it.rata }
    }

    def elencoVersamentiRate(def pratica) {
        def lista = Versamento.createCriteria().list {
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
            createAlias("fonte", "fonte", CriteriaSpecification.LEFT_JOIN)

            eq("prt.id", pratica.id)
            ge('dataPagamento', pratica.dataRateazione)

            order("dataPagamento", "asc")
        }.toDTO()
	/// .each { it.rata = (it.rata == 0 ? null : it.rata) }
    }

    def praticaRateizzata(def pratica) {
        return numeroRate(pratica) > 0
    }

    def numeroRate(def pratica) {
        def sql = """
           select COUNT(*)
              from pratiche_tributo prtr
             where prtr.pratica = :pPratica
               and (prtr.data_rateazione is not null or prtr.mora is not null or
                   prtr.rate is not null or prtr.tipologia_rate is not null or
                     prtr.aliquota_rate is not null)
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def numeroRate = 0
        sqlQuery.with {
            setLong("pPratica", pratica)
            list()
        }.each {
            numeroRate = it
        }

        return numeroRate
    }

    /// Usa la function del db per calcolare, con il metodo storico, l0importo della rata
    def determinaRata(def importo, def rata, def rate, def arrotondamento) {

		BigDecimal	result = null

        try {
		    Sql sql = new Sql(dataSource)

		    sql.call('{? = call f_determina_rata(?, ?, ?, ?)}',
				    [
					    Sql.DECIMAL,
                ///     p_importo           number
                        importo,
                ///     p_rata              number
                        rata,
                ///     p_rate              number
                        rate,
                ///     p_arrotondamento    number
                        arrotondamento
			    ]
		    )
            {
                result = it
            }
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
		
		return result
    }

    def tassoAnnuo(def tipoTributo, def data) {
        return Interessi.findAllByTipoTributoAndTipoInteresse(tipoTributo.tipoTributo, 'R').find {
            it.dataInizio <= data && it.dataFine >= data
        }
    }

    def pianoRimborso(def pratica) {

        def istanza = commonService.getIstanza()

        def sqlTestata = """
         select aden.descrizione "ente",
            contribuenti.cod_contribuente "codContribuente",
            translate(soggetti.cognome_nome, '/', ' ') "cognomeNome",
            decode(soggetti.cod_via,
                   null,
                   soggetti.denominazione_via,
                   archivio_vie.denom_uff) ||
            decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
            decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) ||
            decode(soggetti.interno, null, '', ' int. ' || soggetti.interno) "indirizzoSogg",
            decode(nvl(soggetti.cap, ad4_comuni.cap),
                   null,
                   '',
                   nvl(soggetti.cap, ad4_comuni.cap) || ' ' ||
                   ad4_comuni.denominazione) || ' ' ||
            decode(ad4_provincie.sigla,
                   null,
                   '',
                   '(' || ad4_provincie.sigla || ')') "residenzaSogg",
            contribuenti.cod_fiscale "codFiscale",
            f_descrizione_titr(pratiche_tributo.tipo_tributo,
                               pratiche_tributo.anno) "tipoTributoAttuale",
            pratiche_tributo.anno "praticaAnno",
            pratiche_tributo.tipo_tributo "tipoTributo",
            pratiche_tributo.pratica "pratica",
            pratiche_tributo.data_notifica "dataNotifica",
            pratiche_tributo.numero "numeroPratica",
            pratiche_tributo.data "dataLiq",
            tipi_stato.descrizione "statoAccertamento",
            pratiche_tributo.tipo_evento "tipoEvento",
            decode(pratiche_tributo.tipo_pratica,
                   'L',
                   'Liquidazione',
                   decode(pratiche_tributo.tipo_pratica,
                   'A',
                   'Accertamento',
                   'Sollecito')) "tipoPratica",
            pratiche_tributo.note "note",
            decode(pratiche_tributo.tipo_tributo,
                   'TARSU',
                   f_importi_acc(pratiche_tributo.pratica, 'N', 'TASSA_EVASA'),
                   f_round(pratiche_tributo.imposta_totale, 1)) "impC",
            decode(pratiche_tributo.tipo_tributo,
                   'TARSU',
                   decode(nvl(carichi_tarsu.flag_lordo, 'N'),
                          'S',
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'LORDO'),
                          f_importi_acc(pratiche_tributo.pratica, 'N', 'NETTO')),
                   f_round(pratiche_tributo.importo_totale, 1)) "impSanz",
            pratiche_tributo.versato_pre_rate "sVers",
            'Rateazione ' ||
            f_descrizione_titr(pratiche_tributo.tipo_tributo,
                               pratiche_tributo.anno) titolo,
            decode(pratiche_tributo.tipo_atto, null, '', tipi_atto.descrizione) "tipoAtto",
            pratiche_tributo.data_rateazione "dataRateazione",
            nvl(pratiche_tributo.mora, 0) "mora",
            pratiche_tributo.rate "rate",
            decode(pratiche_tributo.tipologia_rate,
                   'M',
                   'Mensile',
                   'B',
                   'Bimestrale',
                   'T',
                   'Trimestrale',
                   'Q',
                   'Quadrimestrale',
                   'S',
                   'Semestrale',
                   'A',
                   'Annuale') "tipologiaRate",
            pratiche_tributo.importo_rate "importoRate",
            pratiche_tributo.aliquota_rate "aliquotaRate"
       from soggetti,
            archivio_vie,
            ad4_comuni,
            ad4_provincie,
            contribuenti,
            pratiche_tributo,
            tipi_stato,
            tipi_atto,
            carichi_tarsu,
            ad4_istanze      adis,
            ad4_enti         aden
      where soggetti.cod_via = archivio_vie.cod_via(+)
        and soggetti.cod_pro_res = ad4_comuni.provincia_stato(+)
        and soggetti.cod_com_res = ad4_comuni.comune(+)
        and ad4_provincie.provincia(+) = ad4_comuni.provincia_stato
        and contribuenti.ni = soggetti.ni
        and pratiche_tributo.cod_fiscale = contribuenti.cod_fiscale
        and pratiche_tributo.stato_accertamento = tipi_stato.tipo_stato(+)
        and pratiche_tributo.tipo_atto = tipi_atto.tipo_atto(+)
        and pratiche_tributo.anno = carichi_tarsu.anno(+)
        and adis.ente = aden.ente
        and UPPER(adis.istanza) = :pUtente
        and pratiche_tributo.pratica = :pPratica
      order by 2, 3, 4
        """

        def testata = sessionFactory.currentSession.createSQLQuery(sqlTestata).with {

            setBigDecimal('pPratica', pratica)
            setString('pUtente', istanza.toUpperCase())

            resultTransformer = Transformers.aliasToBean(PianoRimborsoTestata.class)

            list()
        }

        def sqlRate = """
                select rtpr.rata_pratica "rataPratica",
                   rtpr.pratica "pratica",
                   rtpr.rata "rata",
                   prtr.importo_rate "importoRate",
                   rtpr.data_scadenza "dataScadenza",
                   rtpr.anno "anno",
                   rtpr.tributo_capitale_f24 "tributoCapitaleF24",
                   rtpr.importo_capitale "importoCapitale",
                   rtpr.tributo_interessi_f24 "tributoInteressiF24",
                   rtpr.importo_interessi "importoInteressi",
                   rtpr.residuo_capitale "residuoCapitale",
                   rtpr.residuo_interessi "residuoInteressi",
                   rtpr.utente "utente",
                   rtpr.data_variazione "dataVariazione",
                   rtpr.giorni_aggio "giorniAggio",
                   rtpr.aliquota_aggio "aliquotaAggio",
                   rtpr.aggio "aggio",
                   rtpr.importo "importo",
                   rtpr.importo_arr "importoArr",
                   rtpr.aggio_rimodulato "aggioRimodulato",
                   rtpr.giorni_dilazione "giorniDilazione",
                   rtpr.aliquota_dilazione "aliquotaDilazione",
                   rtpr.dilazione "dilazione",
                   rtpr.dilazione_rimodulata "dilazioneRimodulata",
                   rtpr.oneri "oneri",
                   rtpr.flag_sosp_ferie "flagSospFerie",
                   nvl((select max(1)
                      from versamenti vers
                     where vers.tipo_tributo = prtr.tipo_tributo
                       and vers.pratica = prtr.pratica
                       and vers.rata = rtpr.rata), 0) "rataPag",
                   decode(prtr.tipo_pratica,
                          'L',
                          'LIQP',
                          'A',
                          'ACC' || decode(prtr.tipo_tributo,
                                          'ICI',
                                          decode(prtr.tipo_evento, 'T', 'T', 'P'),
                                          nvl(prtr.tipo_evento, 'U')),
                          '') || rpad(to_char(prtr.anno), 4, '0') ||
                   lpad(to_char(rtpr.rata), 2, '0') ||
                   lpad(to_char(prtr.pratica), 8, '0') "identificativoOperazione"
              from rate_pratica rtpr, pratiche_tributo prtr
             where rtpr.pratica = :pPratica
               and rtpr.pratica = prtr.pratica
             order by rtpr.rata asc
        """

        def rate = sessionFactory.currentSession.createSQLQuery(sqlRate).with {

            setBigDecimal('pPratica', pratica)

            resultTransformer = Transformers.aliasToBean(PianoRimborsoRata.class)

            list()
        }

        rate.each {
            it.flagSospFerie = it.flagSospFerie == 'S'
        }

        def sqlVersamenti = """
          select versamenti.anno "anno",
                   versamenti.tipo_versamento "tipoVersamento",
                   versamenti.importo_versato "importoVersato",
                   versamenti.data_pagamento "dataPagamento",
                   versamenti.fonte "fonte",
                   versamenti.documento_id "documentoId",
                   pratiche_tributo.pratica "pratica",
                   pratiche_tributo.tipo_pratica "tipoPratica",
                   versamenti.rata "rata",
                   versamenti.data_reg "dataReg"
              from versamenti, pratiche_tributo
             where versamenti.pratica = :pPratica
               and versamenti.pratica = pratiche_tributo.pratica
               and versamenti.data_pagamento >= pratiche_tributo.data_rateazione
             order by versamenti.anno asc, versamenti.data_pagamento asc
        """

        def versamenti = sessionFactory.currentSession.createSQLQuery(sqlVersamenti).with {

            setBigDecimal('pPratica', pratica)

            resultTransformer = Transformers.aliasToBean(PianoRimborsoVersamento.class)

            list()
        }

        PianoRimborso pb = new PianoRimborso()
        pb.testata = testata[0]
        pb.rate = rate
        pb.versamenti = versamenti

        def pianoRimborso = new ArrayList<PianoRimborso>()
        pianoRimborso.add(pb)

        return pianoRimborso
    }
}
