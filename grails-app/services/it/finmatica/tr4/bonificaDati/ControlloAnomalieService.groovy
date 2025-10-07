package it.finmatica.tr4.bonificaDati

import grails.transaction.Transactional
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.anomalie.AnomaliaParametro
import it.finmatica.tr4.anomalie.AnomaliaPratica
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.anomalie.AnomaliaParametroDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.apache.commons.lang.builder.HashCodeBuilder
import org.apache.log4j.Logger
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin
import org.hibernate.LazyInitializationException
import org.hibernate.criterion.*

@Transactional
class ControlloAnomalieService {

    private static final Logger log = Logger.getLogger(ControlloAnomalieService.class)

    CommonService commonService
    OggettiService oggettiService
    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP

    /* Closure utilizzate nelle query */

    /**
     * Closure per join su oggetti imposta partendo da Oggetto contribuente
     * @param anno
     * @param tipoTributo
     * @return
     */
    private oggettiImpostaOgcoClosure = { anno, tipoTributo ->
        createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
        oggettiImposta {
            eq("anno", anno)
            eq("flagCalcolo", true)
        }
        eq("prtr.tipoTributo.tipoTributo", tipoTributo)
        ne("prtr.tipoPratica", "K")
    }

    /**
     * Closure per join su oggetti pratica partendo da Oggetto contribuente.
     * Da aggiungere la condizione sull'anno.
     * @param anno
     * @param tipoTributo
     * @return
     */
    private oggettiPraticaOgcoClosure = { tipoTributo ->
        createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
        'in'("tipoRapporto", ['D', 'C'])
        eq("prtr.tipoPratica", "D")
        eq("prtr.tipoTributo.tipoTributo", tipoTributo)
    }

    /**
     * Closure per join su oggetti imposta partendo da Oggetto
     * @param anno
     * @param tipoTributo
     * @return
     */
    private oggettiImpostaClosure = { anno, tipoTributo ->
        createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
        createAlias("ogco.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)

        eq("ogim.anno", anno)
        eq("ogim.flagCalcolo", true)

        eq("prtr.tipoTributo.tipoTributo", tipoTributo)
        ne("prtr.tipoPratica", "K")
    }

    /**
     * Closure per join su oggetti pratica partendo da Oggetto
     * @param anno
     * @param tipoTributo
     */
    private oggettiPraticaClosure = { anno, tipoTributo ->
        createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
        createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)

        eq("prtr.tipoTributo.tipoTributo", tipoTributo)
        eq("ogco.anno", anno)
        eq("prtr.tipoPratica", "D")
    }

    /**
     *  Closure per nvl tipo oggetto su oggetto e oggetto pratica.
     *  Presuppone l'esistenza dell'alias ogpr per la Oggetti Pratica
     *
     * @param listaTipiOggetto
     */
    private nvlTipoOggetto = { List to ->
        or {
            and {
                isNull("ogpr.tipoOggetto")
                'in'("tipoOggetto.tipoOggetto", to)
            }
            and {
                isNotNull("ogpr.tipoOggetto")
                'in'("ogpr.tipoOggetto.tipoOggetto", to)
            }
        }
    }

    private Criterion getSubQueryOggettiPossedutiAllAnno(def anno, def tipoTributo) {
        DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoContribuente, "ogco").setProjection(Projections.property("percPossesso"))
        subQuery.with {
            createAlias("oggettoPraticaId", "ogpr1", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr1.pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
            add(Restrictions.le("prtr1.anno", anno))
            add(Restrictions.gtProperty("prtr1.anno", "this.anno"))
            add(Restrictions.eqProperty("ogpr1.oggetto.id", "ogpr.oggetto.id"))
            add(Restrictions.eqProperty("contribuente.codFiscale", "this.contribuente.codFiscale"))
            add(Restrictions.eq("prtr1.tipoTributo.tipoTributo", tipoTributo))
            add(Restrictions.eq("prtr1.tipoPratica", "D"))
            delegate
        }
        ExistsSubqueryExpression exists = new ExistsSubqueryExpression("not exists", subQuery)

        Criterion cAnd = Restrictions.conjunction()
        cAnd.add(Restrictions.lt("anno", anno))
        cAnd.add(Restrictions.eq("flagPossesso", true))
        cAnd.add(new ExistsSubqueryExpression("not exists", subQuery))

        Criterion cOr = Restrictions.disjunction()
        cOr.add(Restrictions.eq("anno", anno))
        cOr.add(cAnd)

        return cOr
    }

    /**
     * Subquery per gestire i criteria con join su oggetti_imposta o oggetti_pratica
     * partendo dall'oggetto da integrare con eventuali altre condizioni
     *
     * @param parametri
     * @return
     */
    private DetachedCriteria getSubQueryDaImposta(Map parametri) {
        DetachedCriteria subQuery = DetachedCriteria.forClass(Oggetto, "ogge").setProjection(Projections.property("id"))
        subQuery.with {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            if (parametri.daImposta) {
                createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                createAlias("ogco.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)

                add(Restrictions.eq("ogim.flagCalcolo", true))
                add(Restrictions.eq("ogim.anno", parametri.anno))
                add(Restrictions.ne("prtr.tipoPratica", "K"))
                add(Restrictions.eq("prtr.tipoTributo.tipoTributo", parametri.tipoTributo))
            } else {
                add(Restrictions.eq("prtr.tipoTributo.tipoTributo", parametri.tipoTributo))
                add(Restrictions.eq("prtr.anno", parametri.anno))
                add(Restrictions.eq("prtr.tipoPratica", "D"))
            }
        }
        return subQuery
    }

    public calcolaRendite(Long idAnomaliaParametro, Long idAnomalia = null) {

        log.info "Ricalcolo rendite/valori per ANPA[$idAnomaliaParametro] e ANOM[$idAnomalia]"

        def anpa = AnomaliaParametro.get(idAnomaliaParametro).toDTO(["tipoAnomalia"])

        String flagImposta = anpa.flagImposta
        def anno = anpa.anno

        String ogprJoin = anpa.tipoAnomalia.tipoIntervento.id == 'PRATICA' ?
                """
                    INNER JOIN
                        anomIci.anomaliePratiche anPr
                    INNER JOIN
                        anPr.oggettoContribuente oggCnt
					INNER JOIN
					    oggCnt.oggettoPratica AS oggPrt
				"""
                :
                """
                    INNER JOIN
                        ogg.oggettiPratica AS oggPrt
                    INNER JOIN
                        oggPrt.oggettiContribuente oggCnt
                """

        String ogimJoin = """"""

        def parametri = [
                'pIdAnomaliaParametro': idAnomaliaParametro,
                'pAnno'               : anno
        ]

        String whereIdAnomalia = ""

        if (idAnomalia) {
            parametri.pIdAnomalia = idAnomalia
            whereIdAnomalia = """
						AND anomIci.id = :pIdAnomalia
					  """
        }

        String where = """
                            anpa.id = :pIdAnomaliaParametro
                            AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo
                            AND anomIci.flagOk = 'N' 
                        """

        if (anpa.flagImposta != 'S') {
            where += """
                       AND prtr.tipoPratica.tipoPratica = 'D'
                       AND oggCnt.tipoRapporto IN ('D', 'E')                            
                       AND oggCnt.anno = :pAnno
            """
        } else {

            ogimJoin += """
                 INNER JOIN
                        oggCnt.oggettiImposta ogim
            """

            where += """
                AND ogim.anno = :pAnno 
                AND ogim.flagCalcolo = 'S'
                AND prtr.tipoPratica.tipoPratica != 'K'
            """
        }

        String fRendita = """
            CASE WHEN NVL(oggPrt.tipoOggetto.tipoOggetto, ogg.tipoOggetto.tipoOggetto) IN (1, 3, 55) THEN
                f_rendita(oggPrt.valore
                    , NVL(oggPrt.tipoOggetto.tipoOggetto, ogg.tipoOggetto.tipoOggetto)
                    , oggPrt.anno
                    , NVL(oggPrt.categoriaCatasto.categoriaCatasto, ogg.categoriaCatasto.categoriaCatasto))
            ELSE 0
            END
        """

        String fValoreDaRendita = """
             f_valore_da_rendita(ROUND($fRendita, 2),
                     COALESCE(oggPrt.tipoOggetto.tipoOggetto, ogg.tipoOggetto.tipoOggetto),
                     anpa.anno,
                     COALESCE(oggPrt.categoriaCatasto.categoriaCatasto, ogg.categoriaCatasto.categoriaCatasto),
                     oggPrt.immStorico)
        """

        log.info "Calcolo rendite..."

        long startTime = 0

        String sqlRenditaMaxMediaOggetto = """
                SELECT new Map(
                    anomIci.id as idAnomaliaIci,
                    MAX($fRendita) as renditaMassima,
                    ROUND(AVG($fRendita), 2) as renditaMedia,
                    MAX(oggPrt.valore) as valoreMassimo,
                    AVG(ROUND(oggPrt.valore, 2)) as valoreMedio
                 )
                FROM
                    AnomaliaParametro as anpa
                INNER JOIN
                    anpa.anomalie AS anomIci						
                INNER JOIN 
                    anomIci.oggetto AS ogg
                    $ogprJoin
                    $ogimJoin
                INNER JOIN
                    oggPrt.pratica prtr
                WHERE
                    $where
                    $whereIdAnomalia
                GROUP BY anomIci.id
            """

        String sqlRenditaMaxMediaAnomalia = """
						SELECT new Map(
							MAX(anomIci.renditaMassima) as renditaMassima,
							ROUND(AVG(anomIci.renditaMedia), 2) as renditaMedia,
                            MAX(anomIci.valoreMassimo) as valoreMassimo,
                            ROUND(AVG(anomIci.valoreMedio), 2) as valoreMedio
                        )
						FROM
							AnomaliaParametro as anpa
						INNER JOIN
							anpa.anomalie AS anomIci						
						WHERE
							anpa.id = :pIdAnomaliaParametro AND
							anomIci.flagOk = 'N'
					"""

        String sqlRenditaOggettoPratica = """
						SELECT new Map(
							anPr.id as idAnomaliaPratica,
							MAX($fRendita) as rendita,
                            MAX(oggPrt.valore) as valore
							)
						FROM
							AnomaliaParametro as anpa
						INNER JOIN
							anpa.anomalie AS anomIci						
						INNER JOIN 
							anomIci.oggetto AS ogg
                            $ogprJoin
                            $ogimJoin
						INNER JOIN
							oggPrt.pratica prtr
						WHERE
							anpa.id = :pIdAnomaliaParametro
                            AND prtr.tipoTributo.tipoTributo = anpa.tipoTributo.tipoTributo
                            $whereIdAnomalia
                        and :pAnno = :pAnno
						GROUP BY anPr.id
					"""

        def listaSqlRenditaOggettoPratica = []
        startTime = System.currentTimeMillis()
        log.info "[Query]: Calcolo della rendita massima/media per Anomalia..."
        def listaRenditaMaxMediaOggetto = Anomalia.executeQuery(sqlRenditaMaxMediaOggetto, parametri)
        log.info "Esguita in " + (System.currentTimeMillis() - startTime) + " millisecondi"
        log.info "----------------------------------------------------------------------------------------"

        if (anpa.tipoAnomalia.tipoIntervento.id == 'PRATICA') {
            startTime = System.currentTimeMillis()
            log.info "[Query]: Calcolo della rendita massima/media per OggettoPratica..."
            listaSqlRenditaOggettoPratica = Anomalia.executeQuery(sqlRenditaOggettoPratica, parametri)
            log.info "Esguita in " + (System.currentTimeMillis() - startTime) + " millisecondi"
            log.info "----------------------------------------------------------------------------------------"
        }

        int n = 0;
        startTime = System.currentTimeMillis()
        log.info "Aggiornamento tabella Anomalia..."
        def oggettoDaModificare
        listaRenditaMaxMediaOggetto.each {
            oggettoDaModificare = Anomalia.get(it.idAnomaliaIci)
            log.info "Calcolo per oggetto ${oggettoDaModificare.oggetto.id}..."
            oggettoDaModificare.renditaMedia = it.renditaMedia
            oggettoDaModificare.renditaMassima = it.renditaMassima

            if (oggettoDaModificare.oggetto.tipoOggetto.tipoOggetto in [1L, 3L] && oggettoDaModificare.oggetto.categoriaCatasto?.categoriaCatasto) {
                oggettoDaModificare.valoreMedio = oggettiService.valoreDaRendita(it.renditaMedia?.toDouble()?.round(2),
                        oggettoDaModificare.oggetto.tipoOggetto.tipoOggetto,
                        anno,
                        oggettoDaModificare.oggetto.categoriaCatasto.categoriaCatasto,
                        null)
                oggettoDaModificare.valoreMassimo = oggettiService.valoreDaRendita(it.renditaMassima?.toDouble()?.round(2),
                        oggettoDaModificare.oggetto.tipoOggetto.tipoOggetto,
                        anno,
                        oggettoDaModificare.oggetto.categoriaCatasto.categoriaCatasto,
                        null)
            } else {
                oggettoDaModificare.valoreMedio = it.valoreMedio
                oggettoDaModificare.valoreMassimo = it.valoreMassimo
                if (oggettoDaModificare.oggetto.tipoOggetto.tipoOggetto in [2L, 4L]) {
                    oggettoDaModificare.renditaMedia = null
                    oggettoDaModificare.renditaMassima = null
                }
            }


            log.info it.renditaMedia + "/" + it.renditaMassima
            oggettoDaModificare.save(failOnError: true, flush: true)
            if (idAnomalia == null) cleanUpGorm()
            n++
        }
        log.info "Aggiornati " + n + " record in " + (System.currentTimeMillis() - startTime) + " millisecondi"
        log.info "----------------------------------------------------------------------------------------"

        n = 0
        startTime = System.currentTimeMillis()
        log.info "Aggiornamento tabella AnomaliaPratica..."
        listaSqlRenditaOggettoPratica.each {
            oggettoDaModificare = AnomaliaPratica.get(it.idAnomaliaPratica)
            oggettoDaModificare.rendita = it.rendita
            oggettoDaModificare.valore = it.valore
            log.info it.idAnomaliaPratica + "/" + it.rendita
            oggettoDaModificare.save(failOnError: true, flush: true)
            if (idAnomalia == null) cleanUpGorm()
            n++
        }
        log.info "Aggiornati " + n + " record in " + (System.currentTimeMillis() - startTime) + " millisecondi"
        log.info "----------------------------------------------------------------------------------------"


        parametri.remove("pIdAnomalia")
        startTime = System.currentTimeMillis()
        log.info "[Query]: Calcolo della rendita massima/media AnomaliaParametri..."
        def listaRenditaMaxMediaAnomalia = Anomalia.executeQuery(sqlRenditaMaxMediaAnomalia, [pIdAnomaliaParametro: idAnomaliaParametro])
        log.info "Esguita in " + (System.currentTimeMillis() - startTime) + " millisecondi"
        log.info "----------------------------------------------------------------------------------------"

        startTime = System.currentTimeMillis()
        log.info "Aggiornamento tabella AnomaliaParametro..."
        oggettoDaModificare = AnomaliaParametro.get(idAnomaliaParametro)
        oggettoDaModificare.renditaMedia = listaRenditaMaxMediaAnomalia[0].renditaMedia
        oggettoDaModificare.renditaMassima = listaRenditaMaxMediaAnomalia[0].renditaMassima
        oggettoDaModificare.valoreMedio = listaRenditaMaxMediaAnomalia[0].valoreMedio
        oggettoDaModificare.valoreMassimo = listaRenditaMaxMediaAnomalia[0].valoreMassimo
        oggettoDaModificare.save(failOnError: true, flush: true)
        log.info "Aggiornato 1 record in " + (System.currentTimeMillis() - startTime) + " millisecondi"
        log.info "----------------------------------------------------------------------------------------"
    }
    /* Metodi per gestire il lock e l'unlock su anomalie parametri per evitare controlli concorrenti */

    public
    synchronized AnomaliaParametroDTO lockControlloAnomalia(short tipoAnomalia, short anno, boolean daImposta, String tipoTributo, Map parametri) {
        AnomaliaParametro anomaliaParametro = AnomaliaParametro.createCriteria().get {
            eq("tipoAnomalia.tipoAnomalia", tipoAnomalia)
            eq("anno", anno)
            eq("flagImposta", (daImposta ? "S" : "N"))
            eq("tipoTributo.tipoTributo", tipoTributo)
            lock(true)
        } ?: new AnomaliaParametro(tipoAnomalia: TipoAnomalia.findByTipoAnomalia(tipoAnomalia)
                , anno: anno
                , flagImposta: (daImposta ? "S" : "N")
                , tipoTributo: TipoTributo.findByTipoTributo(tipoTributo))

        if (anomaliaParametro.isLocked()) {
            // TODO: gestire una classe per le eccezioni TributiRuntimeException
            throw new Exception("Controllo anomalie per tipo anomalia ${tipoAnomalia}, tipo tributo ${tipoTributo} e anno ${anno} " + (daImposta ? " su oggetti da imposta " : "") + " lanciato da un altro utente")
        } else {
            // "risorsa" libera
            anomaliaParametro.locked = true
            anomaliaParametro.scarto = parametri.scarto
            anomaliaParametro.renditaDa = parametri.renditaDa
            anomaliaParametro.renditaA = parametri.renditaA
            anomaliaParametro.categorie = parametri.tipiCategoria?.join(",")
            // elimino le vecchie anomalie generate
            anomaliaParametro.save(failOnError: true, flush: true)
        }
        anomaliaParametro.toDTO()
    }

    public synchronized void unlockControlloAnomalia(long idAnomaliaParametro) {
        log.info "eseguo unlock per " + idAnomaliaParametro
        AnomaliaParametro ap = AnomaliaParametro.get(idAnomaliaParametro)
        ap?.locked = false
        ap?.save(fainOnError: true)
        log.info "salvato"
    }

    def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }

    /* Metodi per il controllo della singola anomalia */

    /**
     * Verifica che l'anomalia sia effettivamente sistemata e imposta il campo
     * flag OK a S.
     *
     * @param idAnomalia
     * @return
     */
    def checkAnomalia(long idAnomalia) {
        Anomalia a = Anomalia.get(idAnomalia)
        calcolaRendite(a.anomaliaParametro.id, idAnomalia)
    }

    def checkAnomaliaPratica(long idAnomaliaPratica) {

        // Gestione del caso in cui lo stato OK venga settato dall'utente
        // Se tutte le anomalie pratica associate all'anamolia sono ok si setta ad ok l'anomalia madre e si esce.
        Anomalia anom = AnomaliaPratica.get(idAnomaliaPratica).anomalia
        //se tutte le anomaliePratiche di a sono ok si mette ok anche a.
        if (!AnomaliaPratica.findWhere(anomalia: anom, flagOk: "N")) {
            anom.flagOk = "S"
            anom.save(failOnError: true, flush: true)

            return
        } else {
            // se non tutte le anomaliePratiche di a sono ok, se a è ok si setta a non OK
            if (anom.flagOk == "S") {
                anom.flagOk = "N"
                anom.save(failOnError: true, flush: true)
            }
        }

        calcolaRendite(anom.anomaliaParametro.id, anom.id)
    }

    /* Metodi per il controllo dei tipi anomalia */

    /**
     * Anomalia dichiarazioni tipo 1: Immobili con dati catastali nulli
     * @return
     */

    def checkDatiCatastaliNulli(Map parametri) {

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            isNull("sezione")
            isNull("foglio")
            isNull("numero")
            isNull("subalterno")
            isNull("zona")
            isNull("partita")
            isNull("progrPartita")
            isNull("protocolloCatasto")
            isNull("annoCatasto")

            if (parametri.oggetto) {
                eq("id", parametri.oggetto)
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)

        }
        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            inserisciAnomaliaOggetti(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + oggettiAnomali.size()
        }
    }

    /**
     * Anomalia dichiarazioni tipo 2: Immobili con uguale protocollo e anno catasto.
     * @return
     */
    def checkAnnoProtocolloCatastoUguali(Map parametri) {

        Map parametriQuery = ['tipoTributo'  : parametri.tipoTributo
                              , 'anno'       : parametri.anno
                              , 'tipiOggetto': parametri.tipiOggetto]

        // se è attivo il flag da imposta
        // devo sostituire le condizioni su pratica_tributo con
        // quelle su oggetti_imposta

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }

            if (parametri.oggetto) {
                eq("id", parametri.oggetto)
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)

            /*
             *  FIXME: Quando e se passeremo a Grails 2.4 potremmo scrivere le exist con i criteria di grails
             *  http://grails.github.io/grails-doc/2.4.0/guide/introduction.html#whatsNew24
             */

            DetachedCriteria subQuery = getSubQueryDaImposta(parametri)
            subQuery.with {
                add(Restrictions.neProperty("ogge.id", "this.id"))
                add(Restrictions.eqProperty("ogge.annoCatasto", "this.annoCatasto"))
                add(Restrictions.eqProperty("ogge.protocolloCatasto", "this.protocolloCatasto"))
                delegate
            }

            ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
            add(exists)
        }


        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            inserisciAnomaliaOggetti(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + oggettiAnomali.size()
        }
    }

    /**
     * Anomalia dichiarazioni tipo 3: Immobili non posseduti al 100%
     * @return
     */
    def checkNonPosseduti100(Map parametri) {

        int totOggettiAnomali = 0

        AnomaliaParametro anomaliaParametro = parametri.anomaliaParametro.getDomainObject()

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            if (parametri.oggetto != null) {
                eq("id", parametri.oggetto)
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
                //createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                isNull("ogco.flagEsclusione")
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)
        }

        if (!parametri.oggetto) {
            deleteByAnomaliaParametro(anomaliaParametro.id)
        }
        int i = 0
        for (long oggetto : oggettiAnomali) {
            Anomalia anomalia
            // devo controllare le percentuali di possesso

            List percPossesso = OggettoContribuente.createCriteria().list {
                projections {
                    property("contribuente.codFiscale")
                    property("ogpr.id")
                    property("percPossesso")
                }

                if (parametri.daImposta) {
                    oggettiImpostaOgcoClosure.delegate = delegate
                    oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
                } else {
                    oggettiPraticaOgcoClosure.delegate = delegate
                    oggettiPraticaOgcoClosure(parametri.tipoTributo)
                    Criterion c = getSubQueryOggettiPossedutiAllAnno(parametri.anno, parametri.tipoTributo)
                    add(c)
                }

                eq("ogpr.oggetto.id", oggetto)
            }.collect { row ->
                [codFiscale        : row[0]
                 , idOggettoPratica: row[1]
                 , percPossesso    : row[2]
                ]
            }

            //List percPossesso = OggettoContribuente.executeQuery(queryPercPossesso, ['tipoTributo': parametri.tipoTributo, 'anno': parametri.anno, 'oggetto': oggetto])
            def tabellaPossessi = []
            for (short j in (1..12)) {
                tabellaPossessi << [perc: null, oggettiContribuente: []]
            }
            for (Map ogco in percPossesso) {
                /*
                 F_DATO_RIOG col parametro PT restituisce una stringa composta da:
                 -- Numero di Mesi di Possesso (caratteri 1 e 2)
                 -- Data di Inizio Possesso (caratteri 3 e 4 = giorno, caratteri 5 e 6 = mese, caratteri 7,8,9 e 10 = anno)
                 -- Data di Fine Possesso (caratteri 11 e 12 = giorno, caratteri 13 e 14 = mese, caratteri 15,16,17 e 18 = anno)
                 -- Se il numero dei mesi e` 0 le date contengono il valore 00000000
                 */
                String datoRiog = commonService.getDatoRiog(ogco.codFiscale, ogco.idOggettoPratica, parametri.anno, "PT")
                def matcher = datoRiog =~ /(\d{2})\d{2}(\d{2})\d{4}\d{2}(\d{2})\d{4}/
                short mesiPossesso = Short.valueOf(matcher[0][1])
                short meseInizio = Short.valueOf(matcher[0][2]) - 1
                short meseFine = Short.valueOf(matcher[0][3]) - 1
                if (mesiPossesso > 0) {
                    for (short mese in (meseInizio..meseFine)) {
                        tabellaPossessi[mese].perc = (tabellaPossessi[mese].perc == null) ? 0 : tabellaPossessi[mese].perc
                        tabellaPossessi[mese].perc += ogco.percPossesso ?: 0
                        tabellaPossessi[mese].oggettiContribuente << ogco
                    }
                }
            }

            /* per ogni mese ho il totale della perc possesso
             * e la lista degli ogco
             * quando ripercorro la tabella dei mesi devo aggiungere l'ogco solo una volta...
             * ... mi salvo quelli che aggiungo
             */

            ObjectRange rangePossesso = 100.0 - (parametri.scarto ?: 0)..100.0 + (parametri.scarto ?: 0)
            def ogcoAggiunti = []

            if (parametri.oggetto) {
                return tabellaPossessi.find { !(rangePossesso.containsWithinBounds(it.perc)) } ? 1 : 0
            }

            // controllo solo i mesi per cui è indicata una percentuale di possesso
            // c'è l'anomalia se un oggetto in un qualsiasi mese è stato
            // posseduto per più del 100%
            for (Map possesso in tabellaPossessi) {
                if (possesso.perc != null && !rangePossesso.containsWithinBounds(possesso.perc)) {
                    if (!anomalia) {
                        anomalia = new Anomalia()
                        anomalia.oggetto = Oggetto.get(oggetto)
                        anomalia.flagOk = "N"
                        anomalia.anomaliaParametro = anomaliaParametro
                        anomalia.utente = anomaliaParametro.utente
                        anomalia.save(failOnError: true)
                        totOggettiAnomali++
                    }
                    for (Map ogco in possesso.oggettiContribuente) {
                        def builder = new HashCodeBuilder()
                        builder.append ogco.codFiscale
                        builder.append ogco.idOggettoPratica
                        def ogcoHashCode = builder.toHashCode()
                        if (ogcoAggiunti.find { it.ogco.hashCode() == ogcoHashCode } == null) {
                            // se l'ogco è diverso, verifico che non ne esista uno dichiarato allo stesso modo (stesso quadro)
                            OggettoContribuente oggettoContribuente = OggettoContribuente.createCriteria().get {
                                eq('contribuente.codFiscale', ogco.codFiscale)
                                eq('oggettoPratica.id', ogco.idOggettoPratica)
                            }
                            // faccio guidare gli oggetti con quadri uguali sempre a quello in cui il contribuente è dichiarante
                            def ogcoStessoQuadro = ogcoAggiunti.find {
                                it.ogco.isQuadroDuplicato(oggettoContribuente) && it.ogco.tipoRapporto == 'D'
                            }
                            AnomaliaPratica anomaliaPratica = new AnomaliaPratica()
                            anomaliaPratica.oggettoContribuente = oggettoContribuente
                            anomaliaPratica.flagOk = "N"
                            anomaliaPratica.anomaliaPraticaRif = ogcoStessoQuadro?.anomaliaPratica
                            anomaliaPratica.utente = anomaliaParametro.utente
                            anomalia.addToAnomaliePratiche(anomaliaPratica)
                            anomaliaPratica.save(failOnError: true)
                            ogcoAggiunti << ['ogco': oggettoContribuente, 'anomaliaPratica': anomaliaPratica]
                        }
                    }
                }
            }
            cleanUpGorm()
        }

        anomaliaParametro = parametri.anomaliaParametro.getDomainObject()
        scartaAnomalieSanate(anomaliaParametro.id, parametri.checkSistemate)

        scartaAnomalieParzialmenteSanate(anomaliaParametro.id)

        calcolaRendite(parametri.anomaliaParametro.id)

        cleanUpGorm()

        return "Numero oggetti anomali individuati:" + totOggettiAnomali
    }

    /**
     * Anomalia dichiarazioni tipo 4: Individui piu volte proprietari dello stesso immobile.
     * @return
     */
    def checkPiuVolteProprietari(Map parametri) {

        int totOggettiAnomali = 0

        AnomaliaParametro anomaliaParametro = parametri.anomaliaParametro.getDomainObject()
        List<OggettoContribuente> oggettiContribuenteAnomali = OggettoContribuente.createCriteria().list {
            projections {
                groupProperty("contribuente.codFiscale")
                groupProperty("ogpr.id")
                groupProperty("ogpr.oggetto.id")
            }

            eq("flagPossesso", true)

            if (parametri.daImposta) {
                oggettiImpostaOgcoClosure.delegate = delegate
                oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)

                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoContribuente, "ogco").setProjection(Projections.property("percPossesso"))
                subQuery.with {
                    createAlias("oggettoPraticaId", "ogpr1", CriteriaSpecification.INNER_JOIN)
                    createAlias("ogpr1.pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggettiImposta", "ogim1", CriteriaSpecification.INNER_JOIN)
                    add(Restrictions.eq("ogim1.anno", parametri.anno))
                    add(Restrictions.eq("ogim1.flagCalcolo", true))
                    add(Restrictions.eq("prtr1.tipoTributo.tipoTributo", parametri.tipoTributo))
                    add(Restrictions.ne("prtr1.tipoPratica", "K"))
                    add(Restrictions.neProperty("ogpr1.id", "ogpr.id"))
                    add(Restrictions.eqProperty("ogpr1.oggetto.id", "ogpr.oggetto.id"))

                    add(Restrictions.eqProperty("contribuente.codFiscale", "this.contribuente.codFiscale"))
                    add(Restrictions.eq("flagPossesso", true))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)

            } else {
                oggettiPraticaOgcoClosure.delegate = delegate
                oggettiPraticaOgcoClosure(parametri.tipoTributo)

                eq("prtr.anno", parametri.anno)

                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoContribuente, "ogco").setProjection(Projections.property("percPossesso"))
                subQuery.with {
                    createAlias("oggettoPraticaId", "ogpr1", CriteriaSpecification.INNER_JOIN)
                    createAlias("ogpr1.pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
                    add(Restrictions.eq("prtr1.anno", parametri.anno))
                    add(Restrictions.eq("prtr1.tipoTributo.tipoTributo", parametri.tipoTributo))
                    add(Restrictions.eq("prtr1.tipoPratica", "D"))
                    add(Restrictions.neProperty("ogpr1.id", "ogpr.id"))
                    add(Restrictions.eqProperty("ogpr1.oggetto.id", "ogpr.oggetto.id"))

                    add(Restrictions.eqProperty("contribuente.codFiscale", "this.contribuente.codFiscale"))
                    add(Restrictions.eq("flagPossesso", true))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            or {
                and {
                    isNull("ogpr.tipoOggetto")
                    'in'("ogge.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
                and {
                    isNotNull("ogpr.tipoOggetto")
                    'in'("ogpr.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
            }

            if (parametri.oggetto) {
                eq("ogpr.oggetto.id", parametri.oggetto)
                eq("contribuente.codFiscale", parametri.codFiscale)
            }
        }.collect { row ->
            [codFiscale        : row[0]
             , idOggettoPratica: row[1]
             , idOggetto       : row[2]
            ]
        }

        /*
         * L'oggetto non deve essere dichiarato più volte con il flag_possesso abilitato
         * e la somma dei mesi non deve superare i 12.
         */
        if (!parametri.oggetto) {
            deleteByAnomaliaParametro(anomaliaParametro.id)
        } else {
            return oggettiContribuenteAnomali.size()
        }

        def ogcoGrouppedByOggetto = oggettiContribuenteAnomali.groupBy { it.idOggetto }
        int i = 0

        log.info "Inizio inserimento anomalie"
        for (def oggettoOgco in ogcoGrouppedByOggetto) {

            long startTimeAnom = System.currentTimeMillis()

            def ogcoAggiunti = []

            Anomalia anomalia = new Anomalia()
            Oggetto oggetto = new Oggetto();
            oggetto.id = oggettoOgco.key
            anomalia.oggetto = oggetto
            anomalia.flagOk = "N"
            anomalia.anomaliaParametro = anomaliaParametro
            anomalia.utente = anomaliaParametro.utente
            anomalia.save(failOnError: true)
            totOggettiAnomali++

            long startTimeAnomPratica = System.currentTimeMillis()
            for (Map ogcoKey in oggettoOgco.value) {
                OggettoContribuente ogco = OggettoContribuente.createCriteria().get {
                    eq('contribuente.codFiscale', ogcoKey.codFiscale)
                    eq('oggettoPratica.id', ogcoKey.idOggettoPratica)
                }
                def ogcoStessoQuadro = ogcoAggiunti.find { it.ogco.isQuadroDuplicato(ogco) }
                AnomaliaPratica anomaliaPratica = new AnomaliaPratica()
                anomaliaPratica.oggettoContribuente = ogco
                anomaliaPratica.flagOk = "N"
                anomaliaPratica.anomaliaPraticaRif = ogcoStessoQuadro?.anomaliaPratica
                anomaliaPratica.utente = anomaliaParametro.utente
                anomalia.addToAnomaliePratiche(anomaliaPratica)
                anomaliaPratica.save(failOnError: true)
                ogcoAggiunti << ['ogco': ogco, 'anomaliaPratica': anomaliaPratica]
            }
            //log.info "Inserite " + ogcoAggiunti.size + "anomalie_pratica in " + (System.currentTimeMillis() - startTimeAnomPratica) + " millisecondi"
            //log.info "Inserita anomalia " + i++ + " in " + (System.currentTimeMillis() - startTimeAnom) + " millisecondi"
            //log.info "--------------------------------------------------------------------------------------------------"
            cleanUpGorm()
        }

        anomaliaParametro = parametri.anomaliaParametro.getDomainObject()
        scartaAnomalieSanate(anomaliaParametro.id, parametri.checkSistemate)

        scartaAnomalieParzialmenteSanate(anomaliaParametro.id)

        //log.info "Calcolo rendite..."
        //long startTimRendite = System.currentTimeMillis()
        calcolaRendite(parametri.anomaliaParametro.id)
        //log.info "Fine calcolo rendite. Tempo di esecuzione: " + (System.currentTimeMillis() - startTimRendite) + " millisecondi"

        cleanUpGorm()

        return "Numero oggetti anomali individuati:" + totOggettiAnomali
    }

    /**
     * Anomalia dichiarazioni tipo 5: immobili con indirizzo non codificato.
     * @return
     */
    def checkIndirizzoNonCodificato(Map parametri) {

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            isNull("archivioVie")

            if (parametri.oggetto) {
                eq("id", parametri.oggetto)
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            inserisciAnomaliaOggetti(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + oggettiAnomali.size()
        }

    }

    /**
     * Anomalia dichiarazioni tipo 6: immobili con rendita molto elevata
     * @return
     */
    def checkRenditaMoltoElevata(Map parametri) {

        def param = [
                'tipoTributo'    : parametri.tipoTributo
                , 'tipiOggetto'  : parametri.tipiOggetto
                , 'anno'         : parametri.anno
                , 'tipiCategoria': parametri.tipiCategoria
                , 'renditaDa'    : (parametri.renditaDa ?: 0)
                , 'renditaA'     : (parametri.renditaA == 0 ? 999999 : parametri.renditaA)
        ]

        String whereOggetto = ""
        if (parametri.oggetto) {
            whereOggetto = """
					OGGE.OGGETTO = :oggetto
				AND	OGCO.COD_FISCALE = :codFiscale
				AND	OGPR.OGGETTO_PRATICA = :oggettoPratica
				AND
		"""
            param.oggetto = parametri.oggetto
            param.codFiscale = parametri.codFiscale
            param.oggettoPratica = parametri.oggettoPratica
        }

        String queryOgpr = """
							SELECT OGCO.*
							  FROM OGGETTI_TRIBUTO      OGTR,
							       OGGETTI              OGGE,
							       OGGETTI_PRATICA      OGPR,
							       PRATICHE_TRIBUTO     PRTR,
							       OGGETTI_CONTRIBUENTE OGCO,
							       DATI_GENERALI        DAGE
							 WHERE $whereOggetto
							       OGTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGTR.TIPO_OGGETTO = NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO)
                               AND F_RENDITA(OGPR.VALORE, 
                                    NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO),
                                    PRTR.ANNO,
                                    NVL(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)) BETWEEN
							            NVL(:renditaDa, 0) AND NVL(:renditaA, 0)
							   AND COALESCE(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)
									IN (:tipiCategoria)
							   AND NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO) = 1
							   AND OGGE.OGGETTO = OGPR.OGGETTO
							   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
							   AND PRTR.PRATICA = OGPR.PRATICA
							   AND PRTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGCO.ANNO = :anno
							   AND PRTR.TIPO_PRATICA = 'D'
							UNION
							SELECT OGCO.*
							  FROM OGGETTI_TRIBUTO      OGTR,
							       OGGETTI              OGGE,
							       OGGETTI_PRATICA      OGPR,
							       PRATICHE_TRIBUTO     PRTR,
							       OGGETTI_CONTRIBUENTE OGCO,
							       DATI_GENERALI        DAGE
							 WHERE $whereOggetto
							       OGTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGTR.TIPO_OGGETTO = NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO)
							   AND F_RENDITA(OGPR.VALORE, 
                                 NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO),
                                 PRTR.ANNO,
                                 NVL(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)) BETWEEN
                                    NVL(:renditaDa, 0) AND NVL(:renditaA, 0)
							   AND COALESCE(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)
									IN (:tipiCategoria)
							   AND NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO) != 1
							   AND OGGE.OGGETTO = OGPR.OGGETTO
							   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
							   AND PRTR.PRATICA = OGPR.PRATICA
							   AND PRTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGCO.ANNO = :anno
							   AND PRTR.TIPO_PRATICA = 'D'
							   AND OGGE.TIPO_OGGETTO != 2
							"""

        // con quale valore deve essere calcolata la rendita per il confronto???
        String queryOgim = """
							SELECT OGCO.*
							  FROM OGGETTI_TRIBUTO      OGTR,
							       OGGETTI              OGGE,
							       OGGETTI_PRATICA      OGPR,
							       PRATICHE_TRIBUTO     PRTR,
							       OGGETTI_CONTRIBUENTE OGCO,
								   OGGETTI_IMPOSTA		OGIM,
							       DATI_GENERALI        DAGE
							 WHERE $whereOggetto
							       OGTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGTR.TIPO_OGGETTO = NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO)
							   AND F_RENDITA(OGPR.VALORE, 
                                 NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO),
                                 PRTR.ANNO,
                                 NVL(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)) BETWEEN
                                    NVL(:renditaDa, 0) AND NVL(:renditaA, 0)
							   AND COALESCE(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)
									IN (:tipiCategoria)
							   AND NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO) = 1
							   AND OGGE.OGGETTO = OGPR.OGGETTO
							   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
							   AND PRTR.PRATICA = OGPR.PRATICA
							   AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
							   AND PRTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGIM.ANNO = :anno
							   AND OGIM.FLAG_CALCOLO = 'S'
							   AND PRTR.TIPO_PRATICA <> 'K'
							UNION
							SELECT OGCO.*
							  FROM OGGETTI_TRIBUTO      OGTR,
							       OGGETTI              OGGE,
							       OGGETTI_PRATICA      OGPR,
							       PRATICHE_TRIBUTO     PRTR,
							       OGGETTI_CONTRIBUENTE OGCO,
								   OGGETTI_IMPOSTA		OGIM,
							       DATI_GENERALI        DAGE
							 WHERE $whereOggetto
							       OGTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGTR.TIPO_OGGETTO = NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO)
							   AND F_RENDITA(OGPR.VALORE, 
                                 NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO),
                                 PRTR.ANNO,
                                 NVL(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)) BETWEEN
                                    NVL(:renditaDa, 0) AND NVL(:renditaA, 0)
							   AND COALESCE(OGPR.CATEGORIA_CATASTO, OGGE.CATEGORIA_CATASTO)
									IN (:tipiCategoria)
							   AND NVL(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO) != 1
							   AND OGGE.OGGETTO = OGPR.OGGETTO
							   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
							   AND PRTR.PRATICA = OGPR.PRATICA
							   AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
							   AND PRTR.TIPO_TRIBUTO = :tipoTributo
							   AND OGIM.ANNO = :anno
							   AND OGIM.FLAG_CALCOLO = 'S'
							   AND PRTR.TIPO_PRATICA <> 'K'
							   AND OGGE.TIPO_OGGETTO != 2
		"""
        def sqlQuery = (parametri.daImposta) ? sessionFactory.currentSession.createSQLQuery(queryOgim) : sessionFactory.currentSession.createSQLQuery(queryOgpr)
        List<OggettoContribuente> oggettiAnomali = sqlQuery.with {
            addEntity(OggettoContribuente)
            setParameter('anno', param.anno)
            setParameter('renditaDa', param.renditaDa)
            setParameter('renditaA', param.renditaA)
            setParameter('tipoTributo', param.tipoTributo)
            setParameterList('tipiCategoria', parametri.tipiCategoria)
            if (parametri.oggetto) {
                setParameter('oggetto', param.oggetto)
                setParameter('codFiscale', param.codFiscale)
                setParameter('oggettoPratica', param.oggettoPratica)
            }
            list()
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 7: immobili dichiarati con tipologie diverse
     * @return
     */
    def checkTipologieDiverse(Map parametri) {

        List<OggettoContribuente> oggettiAnomali = OggettoContribuente.createCriteria().list {

            if (parametri.daImposta) {
                oggettiImpostaOgcoClosure.delegate = delegate
                oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaOgcoClosure.delegate = delegate
                oggettiPraticaOgcoClosure(parametri.tipoTributo)
                Criterion c = getSubQueryOggettiPossedutiAllAnno(parametri.anno, parametri.tipoTributo)
                add(c)
            }
            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)

            'in'("ogge.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
            neProperty("ogge.tipoOggetto.tipoOggetto", "ogpr.tipoOggetto.tipoOggetto")

            if (parametri.oggetto) {
                eq("ogge.id", parametri.oggetto)
                eq("contribuente.codFiscale", parametri.codFiscale)
            }
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 8: immobili dichiarati con rendite diverse
     * @return
     */
    def checkRenditeDiverse(Map parametri) {

        def param = ['tipoTributo'  : parametri.tipoTributo
                     , 'tipiOggetto': parametri.tipiOggetto
                     , 'anno'       : parametri.anno
                     , 'scarto'     : parametri.scarto]

        String whereOggetto = ""
        if (parametri.oggetto) {
            whereOggetto = """
					ogge.id = :oggetto
				AND
		"""
            param.oggetto = parametri.oggetto
        }

        String query = """
			SELECT DISTINCT ogco
				FROM 
						OggettoContribuente ogco
							INNER JOIN ogco.oggettoPratica AS ogpr
							INNER JOIN ogpr.pratica	AS prtr
							INNER JOIN ogpr.oggetto AS ogge
				WHERE	$whereOggetto
						prtr.anno = :anno
					AND prtr.tipoPratica = 'D'
					AND ogco.tipoRapporto = 'D'
					AND prtr.tipoTributo.tipoTributo || '' = :tipoTributo
					AND COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto) 
									IN (:tipiOggetto)
					AND EXISTS (
						SELECT 1
							FROM 
		                  		OggettoContribuente ogco1
									INNER JOIN ogco1.oggettoPratica AS ogpr1
									INNER JOIN ogpr1.pratica	AS prtr1
		              		WHERE
		                  		prtr1.tipoTributo.tipoTributo || '' = :tipoTributo
		              		AND prtr1.anno = :anno
		              		AND prtr1.tipoPratica = 'D'
							AND ogpr1.oggetto.id = ogpr.oggetto.id
							AND ogpr1.id != ogpr.id
							and ogpr1.valore NOT BETWEEN ogpr.valore-:scarto AND ogpr.valore+:scarto)
		"""
        String queryOgim = """
			SELECT DISTINCT ogco
				FROM OggettoContribuente ogco
					INNER JOIN ogco.contribuente AS cont
					INNER JOIN ogco.oggettoPratica AS ogpr
					INNER JOIN ogco.oggettiImposta AS ogim
					INNER JOIN ogpr.pratica	AS prtr
					INNER JOIN ogpr.oggetto AS ogge
				WHERE	$whereOggetto
						ogim.anno = :anno
					AND ogim.flagCalcolo = 'S'
					AND prtr.tipoPratica <> 'K'
					AND prtr.tipoTributo.tipoTributo || '' = :tipoTributo
					AND COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto) 
									IN (:tipiOggetto)
					AND EXISTS (
						SELECT 1
							FROM OggettoContribuente ogco1
								INNER JOIN ogco1.oggettoPratica AS ogpr1
								INNER JOIN ogco1.oggettiImposta AS ogim1
								INNER JOIN ogpr1.pratica	AS prtr1
		              		WHERE   ogim1.anno = :anno
								AND ogim1.flagCalcolo = 'S'
								AND prtr1.tipoPratica <> 'K'
								AND prtr1.tipoTributo.tipoTributo || '' = :tipoTributo
		              			AND ogpr1.oggetto.id = ogpr.oggetto.id
								AND ogpr1.id != ogpr.id
								AND f_valore( ogpr1.valore
											, COALESCE(ogpr1.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto)
											, prtr1.anno
											, ogim1.anno
											, COALESCE(ogpr1.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)
											, prtr1.tipoPratica
											, ogpr1.flagValoreRivalutato) 
									NOT BETWEEN 
										f_valore( ogpr.valore
												, COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto)
												, prtr.anno
												, ogim.anno
												, COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)
												, prtr.tipoPratica
												, ogpr.flagValoreRivalutato) - :scarto 
									AND f_valore( ogpr.valore
												, COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto)
												, prtr.anno
												, ogim.anno
												, COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)
												, prtr.tipoPratica
												, ogpr.flagValoreRivalutato) + :scarto) 
		"""

        List<OggettoContribuente> oggettiAnomali = (parametri.daImposta) ? OggettoContribuente.executeQuery(queryOgim, param) : OggettoContribuente.executeQuery(query, param)
        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 9: immobili con dati catastali uguali e categorie diverse
     * @return
     */

    def checkDatiCatastaliUgualiCatDiverse(Map parametri) {

        List<OggettoContribuente> oggettiAnomali = OggettoContribuente.createCriteria().list {
            if (parametri.daImposta) {
                oggettiImpostaOgcoClosure.delegate = delegate
                oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaOgcoClosure.delegate = delegate
                oggettiPraticaOgcoClosure(parametri.tipoTributo)
                eq("anno", parametri.anno)
            }

            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            or {
                and {
                    isNull("ogpr.tipoOggetto")
                    'in'("ogge.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
                and {
                    isNotNull("ogpr.tipoOggetto")
                    'in'("ogpr.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
            }

            or {
                isNotNull("ogge.sezione")
                isNotNull("ogge.foglio")
                isNotNull("ogge.numero")
                isNotNull("ogge.subalterno")
                isNotNull("ogge.zona")
                isNotNull("ogge.protocolloCatasto")
                isNotNull("ogge.annoCatasto")
            }

            if (parametri.daImposta) {
                sqlRestriction(""" NVL(OGGE4_.CATEGORIA_CATASTO, ' ') !=
								NVL(OGPR1_.CATEGORIA_CATASTO, NVL(OGGE4_.CATEGORIA_CATASTO, ' '))""")
                sqlRestriction("""NVL(OGGE4_.SEZIONE, ' ') = NVL(OGGE4_.SEZIONE, ' ')""")
                sqlRestriction("""NVL(OGGE4_.FOGLIO, ' ') = NVL(OGGE4_.FOGLIO, ' ')""")
                sqlRestriction("""NVL(OGGE4_.NUMERO, ' ') = NVL(OGGE4_.NUMERO, ' ')""")
                sqlRestriction("""NVL(OGGE4_.SUBALTERNO, ' ') = NVL(OGGE4_.SUBALTERNO, ' ')""")
                sqlRestriction(""" NVL(OGGE4_.PROTOCOLLO_CATASTO, ' ') =
								NVL(OGGE4_.PROTOCOLLO_CATASTO, ' ')""")
                sqlRestriction("""NVL(OGGE4_.ANNO_CATASTO, 0) = NVL(OGGE4_.ANNO_CATASTO, 0)""")
            } else {
                sqlRestriction(""" NVL(OGGE3_.CATEGORIA_CATASTO, ' ') !=
								NVL(OGPR1_.CATEGORIA_CATASTO, NVL(OGGE3_.CATEGORIA_CATASTO, ' '))""")
                sqlRestriction("""NVL(OGGE3_.SEZIONE, ' ') = NVL(OGGE3_.SEZIONE, ' ')""")
                sqlRestriction("""NVL(OGGE3_.FOGLIO, ' ') = NVL(OGGE3_.FOGLIO, ' ')""")
                sqlRestriction("""NVL(OGGE3_.NUMERO, ' ') = NVL(OGGE3_.NUMERO, ' ')""")
                sqlRestriction("""NVL(OGGE3_.SUBALTERNO, ' ') = NVL(OGGE3_.SUBALTERNO, ' ')""")
                sqlRestriction(""" NVL(OGGE3_.PROTOCOLLO_CATASTO, ' ') =
								NVL(OGGE3_.PROTOCOLLO_CATASTO, ' ')""")
                sqlRestriction("""NVL(OGGE3_.ANNO_CATASTO, 0) = NVL(OGGE3_.ANNO_CATASTO, 0)""")
            }

            if (parametri.oggetto) {
                eq("ogge.id", parametri.oggetto)
                eq("contribuente.codFiscale", parametri.codFiscale)
                eq("ogpr.id", parametri.oggettoPratica)
            }
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 10: mesi possesso, esclusione, riduzione, al. ridotta incoerenti
     *
     * NO IMPOSTA
     * @return
     */

    def checkMesiIncoerenti(Map parametri) {

        List<OggettoContribuente> oggettiAnomali = OggettoContribuente.createCriteria().listDistinct {
            if (parametri.daImposta) {
                oggettiImpostaOgcoClosure.delegate = delegate
                oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaOgcoClosure.delegate = delegate
                oggettiPraticaOgcoClosure(parametri.tipoTributo)
                eq("anno", parametri.anno)
            }

            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            or {
                and {
                    isNull("ogpr.tipoOggetto")
                    'in'("ogge.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
                and {
                    isNotNull("ogpr.tipoOggetto")
                    'in'("ogpr.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
            }
            sqlRestriction("""(COALESCE({alias}.mesi_possesso,12) < (COALESCE({alias}.mesi_riduzione,0) + COALESCE({alias}.mesi_esclusione,0))
             		          OR
             			      COALESCE({alias}.mesi_possesso,12) < COALESCE({alias}.mesi_aliquota_ridotta,0))""")
            if (parametri.oggetto) {
                eq("ogge.id", parametri.oggetto)
                eq("contribuente.codFiscale", parametri.codFiscale)
            }
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 11: Tipo oggetto e indicazione di abitazione principale incoerenti
     *
     * NO IMPOSTA
     * @return
     */

    def checkTipoOggettoAbPrincipale(Map parametri) {

        List<OggettoContribuente> oggettiAnomali = OggettoContribuente.createCriteria().listDistinct {
            if (parametri.daImposta) {
                oggettiImpostaOgcoClosure.delegate = delegate
                oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaOgcoClosure.delegate = delegate
                oggettiPraticaOgcoClosure(parametri.tipoTributo)
                eq("prtr.anno", parametri.anno)
            }

            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            or {
                and {
                    isNull("ogpr.tipoOggetto")
                    'in'("ogge.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
                and {
                    isNotNull("ogpr.tipoOggetto")
                    'in'("ogpr.tipoOggetto.tipoOggetto", parametri.tipiOggetto)
                }
            }
            isNotNull("flagAbPrincipale")
            or {
                and {
                    isNull("ogpr.tipoOggetto")
                    not {
                        'in'("ogge.tipoOggetto.tipoOggetto", [
                                (long) 3,
                                (long) 4,
                                (long) 55
                        ])
                    }
                }
                and {
                    isNotNull("ogpr.tipoOggetto")
                    not {
                        'in'("ogpr.tipoOggetto.tipoOggetto", [
                                (long) 3,
                                (long) 4,
                                (long) 55
                        ])
                    }
                }
            }
            if (parametri.oggetto) {
                eq("ogge.id", parametri.oggetto)
                eq("contribuente.codFiscale", parametri.codFiscale)
            }
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    /**
     * Anomalia dichiarazioni tipo 12: oggetti con stessi estremi catastali
     * @return
     */

    def checkStessiEstremiCatastali(Map parametri) {

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            sqlRestriction("TRIM({alias}.estremi_catasto) IS NOT NULL")

            if (parametri.oggetto) {
                eq("id", parametri.oggetto)
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)

            DetachedCriteria subQuery = getSubQueryDaImposta(parametri)
            subQuery.with {
                add(Restrictions.neProperty("ogge.id", "this.id"))
                add(Restrictions.eqProperty("ogge.estremiCatasto", "this.estremiCatasto"))
                delegate
            }

            ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
            add(exists)

        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            inserisciAnomaliaOggetti(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + oggettiAnomali.size()
        }
    }

    /**
     * Anomalia dichiarazioni tipo 13: oggetti con estremi catastali parziali
     * @return
     */
    def checkEstremiCatastaliParziali(Map parametri) {

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            if (parametri.oggetto) {
                eq("id", parametri.oggetto)
            }

            or {
                and {
                    sqlRestriction("TRIM({alias}.estremi_catasto) IS NOT NULL")
                    or {
                        isNull("foglio")
                        isNull("numero")
                        isNull("subalterno")
                    }
                }
                and {
                    sqlRestriction("TRIM({alias}.estremi_catasto) IS NULL")
                    or {
                        isNotNull("partita")
                        isNotNull("progrPartita")
                        isNotNull("protocolloCatasto")
                        isNotNull("annoCatasto")
                    }
                }
            }

            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)
        }

        if (parametri.oggetto) {
            return oggettiAnomali.size()
        } else {
            inserisciAnomaliaOggetti(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + oggettiAnomali.size()
        }
    }

    /**
     * Anomalia dichiarazioni tipo 14: immobili non posseduti per 12 mesi
     * @return
     */

    def checkImmobiliNon12Mesi(Map parametri) {

        int totOggettiAnomali = 0

        AnomaliaParametro anomaliaParametro = parametri.anomaliaParametro.getDomainObject()

        List oggettiAnomali = Oggetto.createCriteria().list {
            projections { groupProperty("id") }
            if (parametri.oggetto != null) {
                eq("id", parametri.oggetto)
            }
            if (parametri.daImposta) {
                oggettiImpostaClosure.delegate = delegate
                oggettiImpostaClosure(parametri.anno, parametri.tipoTributo)
            } else {
                oggettiPraticaClosure.delegate = delegate
                oggettiPraticaClosure(parametri.anno, parametri.tipoTributo)
                isNull("ogco.flagEsclusione")
            }

            nvlTipoOggetto.delegate = delegate
            nvlTipoOggetto(parametri.tipiOggetto)
        }

        if (!parametri.oggetto) {
            deleteByAnomaliaParametro(anomaliaParametro.id)
        }
        int i = 0
        for (long oggetto : oggettiAnomali) {

            Anomalia anomalia
            // devo controllare le percentuali di possesso
            List percPossessoOgco = OggettoContribuente.createCriteria().list {
                projections {
                    property("contribuente.codFiscale")
                    property("ogpr.id")
                    property("percPossesso")
                }

                if (parametri.daImposta) {
                    oggettiImpostaOgcoClosure.delegate = delegate
                    oggettiImpostaOgcoClosure(parametri.anno, parametri.tipoTributo)
                } else {
                    oggettiPraticaOgcoClosure.delegate = delegate
                    oggettiPraticaOgcoClosure(parametri.tipoTributo)
                    Criterion c = getSubQueryOggettiPossedutiAllAnno(parametri.anno, parametri.tipoTributo)
                    add(c)
                }

                eq("ogpr.oggetto.id", oggetto)
            }.collect { row ->
                [codFiscale        : row[0]
                 , idOggettoPratica: row[1]
                 , percPossesso    : row[2]
                ]
            }

            def tabellaPossessi = [
                    [perc: 0, oggettiContribuente: []]
            ]
            for (short j in (1..12)) {
                tabellaPossessi[j] = [perc: null, oggettiContribuente: []]
            }
            for (Map ogco in percPossessoOgco) {
                /*
                 F_DATO_RIOG col parametro PT restituisce una stringa composta da:
                 -- Numero di Mesi di Possesso (caratteri 1 e 2)
                 -- Data di Inizio Possesso (caratteri 3 e 4 = giorno, caratteri 5 e 6 = mese, caratteri 7,8,9 e 10 = anno)
                 -- Data di Fine Possesso (caratteri 11 e 12 = giorno, caratteri 13 e 14 = mese, caratteri 15,16,17 e 18 = anno)
                 -- Se il numero dei mesi e` 0 le date contengono il valore 00000000
                 */
                String datoRiog = commonService.getDatoRiog(ogco.codFiscale, ogco.idOggettoPratica, parametri.anno, "PT")
                def matcher = datoRiog =~ /(\d{2})\d{2}(\d{2})\d{4}\d{2}(\d{2})\d{4}/
                short mesiPossesso = Short.valueOf(matcher[0][1])
                short meseInizio = Short.valueOf(matcher[0][2])
                short meseFine = Short.valueOf(matcher[0][3])

                // se l'immobile è stato posseduto per qualche mese calcolo la
                // percentuale di possesso
                // altrimenti memorizzo solo l'ogco nell'array con indice 0 (pratiche con mesi possesso ma flag esclusione)
                if (mesiPossesso > 0) {
                    for (short mese in (meseInizio..meseFine)) {
                        if (ogco.percPossesso != null) {
                            tabellaPossessi[mese].perc = (tabellaPossessi[mese].perc == null) ? 0 : tabellaPossessi[mese].perc
                            tabellaPossessi[mese].perc += ogco.percPossesso
                        }
                        tabellaPossessi[mese].oggettiContribuente << ogco
                    }
                }
            }

            /* per ogni mese ho il totale della perc possesso
             * e la lista degli ogco
             * quando ripercorro la tabella dei mesi devo aggiungere l'ogco solo una volta...
             * ... mi salvo quelli che aggiungo
             */

            ObjectRange rangePossesso = 100.0 - (parametri.scarto ?: 0)..100.0 + (parametri.scarto ?: 0)

            def ogcoAggiunti = []

            // l'anomalia è sistemata quando
            // - l'oggetto è posseduto per la percentuale del range per 12 mesi
            // - l'oggetto non è posseduto da nessuno
            if (parametri.oggetto) {
                boolean ogcoDichiarati0Mesi = tabellaPossessi[0].oggettiContribuente.isEmpty()
                int totaleMesiPossessoRange = tabellaPossessi.count {
                    it.perc > 0 && rangePossesso.containsWithinBounds(it.perc)
                }
                int totaleMesiPossesso0oNull = tabellaPossessi.count { it.perc == 0 || it.perc == null }

                return (ogcoDichiarati0Mesi && totaleMesiPossessoRange == 12 && totaleMesiPossesso0oNull <= 1) ? 0 : 1
            }

            boolean anomaliaPresente = false

            for (short mese in (1..12)) {
                def percPossesso = tabellaPossessi[mese].perc == null ? 0 : tabellaPossessi[mese].perc
                anomaliaPresente = !(percPossesso >= 100.0 - (parametri.scarto ?: 0) && percPossesso <= 100.0 + (parametri.scarto ?: 0))
                if (anomaliaPresente) {
                    break
                }
            }

            if (anomaliaPresente) {
                for (Map possesso in tabellaPossessi) {
                    if (!anomalia) {
                        try {
                            anomaliaParametro.tipoTributo
                        } catch (LazyInitializationException e) {
                            log.error("eseguita la clear della session... riattacco anomaliaParametro", e)
                            anomaliaParametro = parametri.anomaliaParametro.getDomainObject()
                        }
                        anomalia = new Anomalia()
                        anomalia.oggetto = Oggetto.get(oggetto)
                        anomalia.flagOk = "N"
                        anomalia.anomaliaParametro = anomaliaParametro
                        anomalia.utente = anomaliaParametro.utente
                        //anomalia.tipoAnomalia = ta
                        //anomalia.anno = parametri.anno
                        anomalia.save(failOnError: true)
                        totOggettiAnomali++
                    }
                    for (Map ogco in possesso.oggettiContribuente) {
                        def builder = new HashCodeBuilder()
                        builder.append ogco.codFiscale
                        builder.append ogco.idOggettoPratica
                        def ogcoHashCode = builder.toHashCode()
                        if (ogcoAggiunti.find { it.ogco.hashCode() == ogcoHashCode } == null) {
                            // se l'ogco è diverso, verifico che non ne esista uno dichiarato allo stesso modo (stesso quadro)
                            OggettoContribuente oggettoContribuente = OggettoContribuente.createCriteria().get {
                                eq('contribuente.codFiscale', ogco.codFiscale)
                                eq('oggettoPratica.id', ogco.idOggettoPratica)
                            }
                            // faccio guidare gli oggetti con quadri uguali sempre a quello in cui il contribuente è dichiarante dichiarante
                            def ogcoStessoQuadro = ogcoAggiunti.find {
                                it.ogco.isQuadroDuplicato(oggettoContribuente) && it.ogco.tipoRapporto == 'D'
                            }
                            AnomaliaPratica anomaliaPratica = new AnomaliaPratica()
                            anomaliaPratica.oggettoContribuente = oggettoContribuente
                            anomaliaPratica.flagOk = "N"
                            anomaliaPratica.anomaliaPraticaRif = ogcoStessoQuadro?.anomaliaPratica
                            anomaliaPratica.utente = anomaliaParametro.utente
                            anomalia.addToAnomaliePratiche(anomaliaPratica)
                            anomaliaPratica.save(failOnError: true)
                            ogcoAggiunti << ['ogco': oggettoContribuente, 'anomaliaPratica': anomaliaPratica]
                        }
                    }

                }
                cleanUpGorm()
            }
        }

        anomaliaParametro = parametri.anomaliaParametro.getDomainObject()
        scartaAnomalieSanate(anomaliaParametro.id, parametri.checkSistemate)

        scartaAnomalieParzialmenteSanate(anomaliaParametro.id)

        calcolaRendite(parametri.anomaliaParametro.id)

        cleanUpGorm()

        return "Numero oggetti anomali individuati:" + totOggettiAnomali
    }

    /**
     * Anomalia dichiarazioni tipo 15: immobili dichiarati con rendite diverse da catasto
     * @return
     */
    def checkRenditeDiverseInCatasto(Map parametri) {

        def param = [
			'tipoTributo' : parametri.tipoTributo,
			'tipiOggetto' : parametri.tipiOggetto,
			'anno'        : parametri.anno,
			'scarto'      : parametri.scarto
		]
		
        String whereOggetto = ""
        if (parametri.oggetto) {
            whereOggetto = """
				OGGE.ID = :oggetto AND
			"""
            param.oggetto = parametri.oggetto
        }

        String queryOgpr = """
				SELECT
					DISTINCT OGCO.*
				FROM
					PRATICHE_TRIBUTO     PRTR,
					OGGETTI_PRATICA      OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI              OGGE
				WHERE
					${whereOggetto}
					PRTR.PRATICA = OGPR.PRATICA
					AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
					AND OGCO.COD_FISCALE = PRTR.COD_FISCALE
					AND OGPR.OGGETTO = OGGE.OGGETTO
					AND TRIM(OGGE.ESTREMI_CATASTO) IS NOT NULL
					AND PRTR.ANNO = :anno
					AND PRTR.TIPO_PRATICA = 'D'
					AND OGCO.TIPO_RAPPORTO = 'D'
					AND PRTR.TIPO_TRIBUTO = :tipoTributo
					AND COALESCE(OGPR.TIPO_OGGETTO, OGGE.TIPO_OGGETTO) IN (:tipiOggetto)
					AND (
						(OGGE.TIPO_OGGETTO = 3 AND EXISTS
							(SELECT 1
							FROM
								IMMOBILI_CATASTO_URBANO FABB
							WHERE
								FABB.ESTREMI_CATASTO = OGGE.ESTREMI_CATASTO
								AND :anno BETWEEN EXTRACT(YEAR FROM FABB.DATA_EFFICACIA) AND EXTRACT(YEAR FROM FABB.DATA_FINE_EFFICACIA)
								AND FABB.RENDITA NOT BETWEEN
									f_rendita(OGPR.VALORE,OGGE.TIPO_OGGETTO,:anno,OGGE.CATEGORIA_CATASTO) - :scarto AND
										f_rendita(OGPR.VALORE,OGGE.TIPO_OGGETTO,:anno,OGGE.CATEGORIA_CATASTO) + :scarto))
						OR
						(OGGE.TIPO_OGGETTO = 1 AND EXISTS
							(SELECT 1
							FROM
								IMMOBILI_CATASTO_TERRENI TERR
							WHERE
								TERR.ESTREMI_CATASTO = OGGE.ESTREMI_CATASTO
								AND :anno BETWEEN EXTRACT(YEAR FROM TERR.DATA_EFFICACIA) AND EXTRACT(YEAR FROM TERR.DATA_FINE_EFFICACIA)
								AND TERR.REDDITO_DOMINICALE_EURO NOT BETWEEN
									f_rendita(OGPR.VALORE,OGGE.TIPO_OGGETTO,:anno,OGGE.CATEGORIA_CATASTO) - :scarto AND
										f_rendita(OGPR.VALORE,OGGE.TIPO_OGGETTO,:anno,OGGE.CATEGORIA_CATASTO) + :scarto))
				       )
		"""
        String queryOgim = """
				SELECT
					DISTINCT OGCO.*
				FROM
					PRATICHE_TRIBUTO PRTR,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_IMPOSTA OGIM,
					OGGETTI OGGE
				WHERE
					${whereOggetto}
					PRTR.PRATICA = OGPR.PRATICA
					AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
					AND OGCO.COD_FISCALE = PRTR.COD_FISCALE
					AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
					AND OGIM.COD_FISCALE = PRTR.COD_FISCALE
					AND OGPR.OGGETTO = OGGE.OGGETTO
					AND OGIM.ANNO = :anno
					AND OGIM.FLAG_CALCOLO = 'S'
					AND PRTR.TIPO_PRATICA != 'K'
					AND PRTR.TIPO_TRIBUTO = :tipoTributo
					AND COALESCE(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO) IN (:tipiOggetto)
					AND (
						(OGGE.TIPO_OGGETTO = 3 AND EXISTS
							(SELECT 1
							FROM
								IMMOBILI_CATASTO_URBANO FABB
							WHERE
								FABB.ESTREMI_CATASTO = OGGE.ESTREMI_CATASTO
								AND :anno BETWEEN EXTRACT(YEAR FROM FABB.DATA_EFFICACIA) AND EXTRACT(YEAR FROM FABB.DATA_FINE_EFFICACIA)
								AND FABB.RENDITA NOT BETWEEN
									f_rendita_riog_ogpr(OGPR.OGGETTO_PRATICA,:anno) - :scarto AND
										f_rendita_riog_ogpr(OGPR.OGGETTO_PRATICA,:anno) + :scarto)
						)
						OR
						(OGGE.TIPO_OGGETTO = 1 AND EXISTS
							(SELECT 1
							FROM
								IMMOBILI_CATASTO_TERRENI TERR
							WHERE
								TERR.ESTREMI_CATASTO = OGGE.ESTREMI_CATASTO
								AND :anno BETWEEN EXTRACT(YEAR FROM TERR.DATA_EFFICACIA) AND EXTRACT(YEAR FROM TERR.DATA_FINE_EFFICACIA)
								AND TERR.REDDITO_DOMINICALE_EURO NOT BETWEEN
									f_rendita_riog_ogpr(OGPR.OGGETTO_PRATICA,:anno) - :scarto AND
										f_rendita_riog_ogpr(OGPR.OGGETTO_PRATICA,:anno) + :scarto)
						)
					)
		"""

		def sqlQuery = (parametri.daImposta) ? sessionFactory.currentSession.createSQLQuery(queryOgim) : sessionFactory.currentSession.createSQLQuery(queryOgpr)
		List<OggettoContribuente> oggettiAnomali = sqlQuery.with {
			addEntity(OggettoContribuente)
			setParameter('anno', param.anno)
			setParameter('tipoTributo', param.tipoTributo)
			setParameterList('tipiOggetto', parametri.tipiOggetto)
			setParameter('scarto', param.scarto)
			if (parametri.oggetto) {
				setParameter('oggetto', param.oggetto)
			}
			list()
		}
		
        if (parametri.oggetto) {
            return oggettiAnomali.size()
        }
		else {
            int numAnomalie = inserisciAnomaliaPratiche(oggettiAnomali, parametri.anomaliaParametro, parametri.checkSistemate)
            calcolaRendite(parametri.anomaliaParametro.id)
            return "Numero oggetti anomali individuati:" + numAnomalie
        }
    }

    private void inserisciAnomaliaOggetti(List oggettiAnomali, AnomaliaParametroDTO ap, boolean checkSistemate) {

        AnomaliaParametro anomaliaParametro = ap.getDomainObject()

        deleteByAnomaliaParametro(anomaliaParametro.id)
        int i = 0
        for (long oggetto : oggettiAnomali) {
            try {
                anomaliaParametro.tipoTributo
            } catch (LazyInitializationException e) {
                log.error("eseguita la clear della session... riattacco anomaliaParametro", e)
                anomaliaParametro = ap.getDomainObject()
            }
            Anomalia anomalia = new Anomalia()
            anomalia.oggetto = Oggetto.get(oggetto)
            anomalia.flagOk = "N"
            anomalia.anomaliaParametro = anomaliaParametro
            anomalia.utente = anomaliaParametro.utente
            anomalia.save(failOnError: true)
            cleanUpGorm()
        }

        anomaliaParametro = ap.getDomainObject()
        scartaAnomalieSanate(anomaliaParametro.id, checkSistemate)

        scartaAnomalieParzialmenteSanate(anomaliaParametro.id)

        cleanUpGorm()
    }

    private int inserisciAnomaliaPratiche(List<OggettoContribuente> oggettiAnomali, AnomaliaParametroDTO ap, boolean checkSistemate) {

        int numOggettiAnomali = 0

        AnomaliaParametro anomaliaParametro = ap.getDomainObject()

        deleteByAnomaliaParametro(anomaliaParametro.id)
        def groupped = oggettiAnomali.groupBy { it.oggettoPratica.oggetto.id }
        int i = 0
        for (def map in groupped) {
            try {
                anomaliaParametro.tipoTributo
            } catch (LazyInitializationException e) {
                log.error("eseguita la clear della session... riattacco anomaliaParametro", e)
                anomaliaParametro = ap.getDomainObject()
            }
            Anomalia anomalia = new Anomalia()
            anomalia.oggetto = Oggetto.get(map.key)
            anomalia.flagOk = "N"
            anomalia.anomaliaParametro = anomaliaParametro
            anomalia.utente = anomaliaParametro.utente
            anomalia.save(failOnError: true)
            numOggettiAnomali++

            for (OggettoContribuente ogco in map.value) {
                AnomaliaPratica anomaliaPratica = new AnomaliaPratica()
                anomaliaPratica.oggettoContribuente = ogco
                anomaliaPratica.flagOk = "N"
                anomaliaPratica.utente = anomaliaParametro.utente
                anomalia.addToAnomaliePratiche(anomaliaPratica)
                anomaliaPratica.save(failOnError: true)
            }

            cleanUpGorm()
        }

        anomaliaParametro = ap.getDomainObject()

        try {
            anomaliaParametro.tipoTributo
        } catch (LazyInitializationException e) {
            log.error("eseguita la clear della session... riattacco anomaliaParametro", e)
            anomaliaParametro = ap.getDomainObject()
        }

        scartaAnomalieSanate(anomaliaParametro.id, checkSistemate)

        scartaAnomalieParzialmenteSanate(anomaliaParametro.id)

        cleanUpGorm()

        return numOggettiAnomali
    }

    private void scartaAnomalieParzialmenteSanate(long idAnomaliaParametro) {

        def parametri = [:]
        parametri.pIdAnomaliaParametro = idAnomaliaParametro

        String sqlDeleteAnom = """
			DELETE Anomalia anom WHERE
				anom.anomaliaParametro.id = :pIdAnomaliaParametro AND
				anom.flagOk = 'N' AND
				(
					(
						EXISTS(SELECT anpr.id FROM AnomaliaPratica anpr WHERE anpr.anomalia.id = anom.id and anpr.flagOk = 'S')
					)
				)
		"""
        Anomalia.executeUpdate(sqlDeleteAnom, parametri)
    }

    private void scartaAnomalieSanate(long idAnomaliaParametro, def checkSistemate) {

        def parametri = [:]
        parametri.pIdAnomaliaParametro = idAnomaliaParametro

        String sqlDeleteAnom = """
			DELETE Anomalia anom WHERE
				anom.anomaliaParametro.id = :pIdAnomaliaParametro AND
				anom.flagOk = '${checkSistemate ? 'S' : 'N'}' AND
				(
				    EXISTS (SELECT anom1.id	FROM Anomalia anom1	WHERE anom1.anomaliaParametro.id = :pIdAnomaliaParametro AND anom.oggetto = anom1.oggetto AND anom1.flagOk = '${checkSistemate ? 'N' : 'S'}')	
				)
		"""

        Anomalia.executeUpdate(sqlDeleteAnom, parametri)
    }

    private void deleteByAnomaliaParametro(long idAnomaliaParametro) {
        String sqlDeleteAnPr = """
			DELETE AnomaliaPratica anprDel where anprDel.anomalia.id IN (
				SELECT anom.id FROM
					Anomalia anom
				WHERE 
					anom.anomaliaParametro.id = :pIdAnomaliaParametro
					AND anom.flagOk = 'N'
					AND NOT EXISTS (SELECT anpr.id FROM AnomaliaPratica anpr WHERE anpr.anomalia.id = anom.id AND anpr.flagOk = 'S'
					)
				)
		"""

        String sqlDeleteAnom = """
			DELETE Anomalia anom WHERE
				anom.anomaliaParametro.id = :pIdAnomaliaParametro AND
				(
					( 
						EXISTS(SELECT anpa.id FROM AnomaliaParametro anpa WHERE anpa.id = :pIdAnomaliaParametro and anpa.tipoAnomalia.tipoIntervento = 'PRATICA') AND
					  	NOT EXISTS(SELECT anpr.id FROM AnomaliaPratica anpr	WHERE anpr.anomalia.id = anom.id)
					) 
						OR
					(
						EXISTS(SELECT anpa.id FROM AnomaliaParametro anpa WHERE anpa.id = :pIdAnomaliaParametro and anpa.tipoAnomalia.tipoIntervento = 'OGGETTO') AND
						anom.flagOk = 'N'
					)
				)
		"""

        Anomalia.executeUpdate(sqlDeleteAnPr, [pIdAnomaliaParametro: idAnomaliaParametro])
        Anomalia.executeUpdate(sqlDeleteAnom, [pIdAnomaliaParametro: idAnomaliaParametro])
    }
}
