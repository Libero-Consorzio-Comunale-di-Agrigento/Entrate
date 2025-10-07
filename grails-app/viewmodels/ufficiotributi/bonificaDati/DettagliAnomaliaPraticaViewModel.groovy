package ufficiotributi.bonificaDati

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.bonificaDati.nonDichiarati.BonificaNonDichiaratiService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoIntervento
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.anomalie.TipoAnomaliaDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

class DettagliAnomaliaPraticaViewModel {

    public static final String STATO_POSITION_OGGETTO = 'OGGETTO'
    public static final String STATO_POSITION_PRATICA = 'PRATICA'
    Window self

    TributiSession tributiSession
    CompetenzeService competenzeService

    Boolean lettura = true

    @Wire("#praticheAnomalieGrid")
    Grid praticheAnomalieGrid

    @Wire('#praticheAnomalieGridTimer')
    Timer praticheAnomalieGridTimer

    def listaCategorieCatasto

    def dettagliAperti = []

    // paginazione
    int activePage = 0
    int pageSize = 10
    def totalSize

    def filtriPratiche
    /*
    def filtriPratiche = [
            stato                   : "0"
            , tipoOggettoSelezionato: null
            , annoSelezionato       : null
            , idOggetto             : null
            , categoriaCatasto      : null
    ]

     */

    TipoAnomaliaDTO tipoAnomaliaSelezionata
    String statoAnomaliaIconPosition = STATO_POSITION_PRATICA

    def praticheAnomalie
    List listaTipiOggetto

    List tipiTributoSelezionati = []
    List tipiPraticheSelezionate = []

    def anomaliaSelezionata
    def dettaglioSelezionato
    def praticaSelezionata
    String tipoAnalisiSelezionato

    boolean praticaPerAnno = true
    boolean filtriAttivi = false
    boolean espandiDettagli = true

    BonificaDatiService bonificaDatiService
    BonificaNonDichiaratiService bonificaNonDichiaratiService
    ControlloAnomalieService controlloAnomalieService
    DenunceService denunceService

    def campiOrdinamento = [
            'anicOgge.id': [verso: 'A', posizione: 0]
    ]

    def campiCssOrdinamento =
            [
                    'anicOgge.id': 'z-column-sort-asc_'
            ]

    def ordinamentoCss = [
            0: '',
            1: 'z-column-sort-asc_',
            2: 'z-column-sort-dsc_'
    ]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        dettagliAperti = []
        listaTipiOggetto = OggettiCache.TIPI_OGGETTO.valore
        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore

        filtriPratiche = tributiSession.filtroAnomalie
        if (!filtriPratiche) {
            filtriPratiche = [
                    stato                   : "0"
                    , tipoOggettoSelezionato: null
                    , annoSelezionato       : null
                    , idOggetto             : null
                    , categoriaCatasto      : null
            ]
        }


    }

    @GlobalCommand
    loadDettagliAnomalia(@BindingParam("anomaliaSelezionata") def anomaliaSelezionata, @BindingParam("idOggetto") def idOggetto) {

        if (anomaliaSelezionata.tipoIntervento != TipoIntervento.PRATICA) {
            return
        }

        lettura = !competenzeService.utenteAbilitatoScrittura(anomaliaSelezionata.tipoTributoOrg);
        BindUtils.postNotifyChange(null, null, this, "lettura")

        activePage = 0
        this.anomaliaSelezionata = anomaliaSelezionata

        if (idOggetto) {
            filtriPratiche.idOggetto = idOggetto
        }

        tipiTributoSelezionati.clear()
        tipiTributoSelezionati << (anomaliaSelezionata.tipoTributo == 'IMU' ? 'ICI' : anomaliaSelezionata.tipoTributo)

        def lista = bonificaDatiService.getDettagliAnomaliaPratica(this.anomaliaSelezionata.tipoAnomalia, this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta, filtriPratiche, tipiTributoSelezionati, tipiPraticheSelezionate, campiOrdinamento, pageSize, activePage)
        praticheAnomalie = lista.list

        totalSize = lista.total
        tipoAnomaliaSelezionata = TipoAnomalia.findByTipoAnomalia(this.anomaliaSelezionata.tipoAnomalia).toDTO()

        BindUtils.postNotifyChange(null, null, this, "filtriAttivi")
        BindUtils.postNotifyChange(null, null, this, "praticheAnomalie")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "pageSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
        BindUtils.postNotifyChange(null, null, this, "tipoAnomaliaSelezionata")

        refreshStatoAnomaliaIconPosition()
    }

    private void refreshStatoAnomaliaIconPosition() {
        statoAnomaliaIconPosition = bonificaDatiService.isTipoAnomaliaForMui(tipoAnomaliaSelezionata.tipoAnomalia) ? STATO_POSITION_OGGETTO : STATO_POSITION_PRATICA
        BindUtils.postNotifyChange(null, null, this, "statoAnomaliaIconPosition")
    }

    @NotifyChange(["oggettiAnomalie", "totalSize", "activePage"])
    @Command
    onRefresh() {
        onVisualizzaPratiche()

        // Ripristina i dettagli aperti
        praticheAnomalieGridTimer.start()
    }

    @Command
    onSituazioneContribuenteAnomalia() {

        def ni = Contribuente.findByCodFiscale(praticaSelezionata?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")

    }

    @Command
    onCorreggiAnomalia(@BindingParam("ogg") def ogg) {

        def oggettoContribuente = bonificaDatiService.getOggettoContribuente(praticaSelezionata.codFiscale, praticaSelezionata.idOggettoPratica)

        int indexSelezione = 0
        Window w = Executions.createComponents("/pratiche/denunce/oggettoContribuente.zul", self
                , [idOggPr         : praticaSelezionata ? praticaSelezionata.idOggettoPratica : -1
                   , contribuente  : praticaSelezionata ? praticaSelezionata.codFiscale : null
                   , tipoRapporto  : praticaSelezionata ? praticaSelezionata.tipoRapporto : ""
                   , tipoTributo   : praticaSelezionata ? praticaSelezionata.tipoTributo : ""
                   , idOggetto     : -1
                   , pratica       : praticaSelezionata ? denunceService.findPraticaTributoDTOById(praticaSelezionata.idPratica) : null
                   , oggPr         : null
                   , listaId: [oggettoContribuente]
                   , indexSelezione: indexSelezione
                   , modifica      : !lettura
                   , daBonifiche   : true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato) {
                    bonificaDatiService.cambiaStatoAnomaliaPratica(praticaSelezionata.idAnomaliaPratica)
                    controlloAnomalieService.checkAnomaliaPratica(praticaSelezionata.idAnomaliaPratica)
                }
                onRefresh()
                BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
                BindUtils.postNotifyChange(null, null, this, "totalSize")
                BindUtils.postNotifyChange(null, null, this, "activePage")
                BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
            }
        }
        w.doModal()

    }

    @Command
    onCorreggiAnomaliaSuPratica(@BindingParam("ogg") def ogg) {

        def url = 'pratiche/denunce/' + (praticaSelezionata.tipoTributo == 'ICI' ? 'denunciaImu.zul' : 'denunciaTasi.zul')

        Window w = Executions.createComponents(url, self,
                [pratica     : praticaSelezionata.idPratica,
                 tipoRapporto: praticaSelezionata.tipoRapporto,
                 lettura     : lettura,
                 daBonifiche : true])
        w.onClose { event ->
            if (event.data.aggiornaStato) {
                bonificaDatiService.cambiaStatoAnomaliaPratica(praticaSelezionata.idAnomaliaPratica)
                controlloAnomalieService.checkAnomaliaPratica(praticaSelezionata.idAnomaliaPratica)
            }
            onRefresh()
            BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
            BindUtils.postNotifyChange(null, null, this, "totalSize")
            BindUtils.postNotifyChange(null, null, this, "activePage")
            BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
        }
        w.doModal()
    }

    @Command
    onCorreggiAnomaliaOggetto() {

        def anomalia = dettaglioSelezionato

        Window w = Executions.createComponents("/archivio/oggetto.zul", self,
                [
                        oggetto    : anomalia.idOggetto,
                        daBonifiche: true,
                        lettura    : lettura
                ]
        )
        w.onClose() { event ->

            if (event.data.aggiornaStato) {

                anomalia.dettagli.each {
                    bonificaDatiService.cambiaStatoAnomaliaPratica(it.idAnomaliaPratica)
                    controlloAnomalieService.checkAnomaliaPratica(it.idAnomaliaPratica)
                }
            }

            onRefresh()
            BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
            BindUtils.postNotifyChange(null, null, this, "totalSize")
            BindUtils.postNotifyChange(null, null, this, "activePage")
            BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
        }
        w.doModal()
    }

    @Command
    onInserimentoRendite() {

        def anomalia = dettaglioSelezionato

        def idOggetto = anomalia.idOggetto
        def oggetto = Oggetto.findById(idOggetto)
        def idImmobile = oggetto.idImmobile ?: 0

        if (idImmobile == 0) {

            def elencoOggetti = []
            elencoOggetti << idOggetto

            def parametriRicerca = [
                    idOggetti: elencoOggetti
            ]

            def immobiliDaElaborare = bonificaNonDichiaratiService.preparaListaImmobiliDaOggetti(parametriRicerca)
            def listaImmobili = immobiliDaElaborare.listaImmobili

            listaImmobili.each {

                if (it.idOggetto == idOggetto) idImmobile = it.idImmobile
            }
        }

        creaPopup("/catasto/inserimentoOggettiRendite.zul",
                [
                        immobile    : idImmobile,
                        oggetto     : idOggetto,
                        tipoImmobile: 'F'
                ],
                { e ->
                    if (e?.data?.esito) {

                    }
                }
        )
        /**
         ***
         def elencoOggetti = []
         elencoOggetti << idOggetto

         def parametriRicerca = [
         idOggetti: elencoOggetti
         ]

         def immobiliDaElaborare = bonificaNonDichiaratiService.preparaListaImmobiliDaOggetti(parametriRicerca)
         def totaleImmobili = immobiliDaElaborare.totaleImmobili;
         def listaImmobili = immobiliDaElaborare.listaImmobili

         if(idImmobile  != 0) {

         listaImmobili.each {

         if(it.idOggetto == idOggetto) it.idImmobile = idImmobile
         }
         }

         creaPopup("/ufficiotributi/bonificaDati/nonDichiarati/nonDichiaratiRendita.zul",
         [
         totale      : totaleImmobili,
         immobili    : listaImmobili,
         datiSoggetti: false
         ]
         )
         ***
         **/
    }

    @Command
    onInfoPratica(@BindingParam("ogg") def ogg) {
        // praticaSelezionata = ogg ?: praticaSelezionata
        //BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")

        if (praticaSelezionata == null)
            return

        if (PraticaTributo.get(praticaSelezionata.idPratica).tipoPratica == "D") {
            String parametri = "sezione=PRATICA"
            parametri += "&idPratica=${praticaSelezionata.idPratica}"
            parametri += "&tipoTributo=${praticaSelezionata.tipoTributo}"
            parametri += "&tipoRapporto=${praticaSelezionata.tipoRapporto}"
            parametri += "&lettura=${lettura}"

            Clients.evalJavaScript("window.open('standalone.zul?$parametri','_blank');")
        } else {
            Clients.showNotification("In fase di realizzazione", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }
    }

    @Command
    def onVisualizzaCatasto() {

        def anomalia = dettaglioSelezionato

        def oggettoPerCensuario = [
                oggetto    : anomalia.idOggetto,
                indirizzo  : anomalia.indirizzo,
                sezione    : anomalia.sezione ?: '',
                foglio     : anomalia.foglio ?: '',
                numero     : anomalia.numero ?: '',
                subalterno : anomalia.subalterno ?: '',
                tipoOggetto: anomalia.tipoOggetto
        ]

        creaPopup("/sportello/contribuenti/informazioniCatastoCensuario.zul", [oggetto: oggettoPerCensuario])
    }

    @Command
    onVisualizzaMappa() {

        def anomalia = dettaglioSelezionato

        def elencoOggetti = []

        def oggetto = [:]

        oggetto.idOggetto = anomalia.idOggetto;
        oggetto.tipoOggetto = anomalia.tipoOggetto;
        oggetto.sezione = anomalia.sezione;
        oggetto.foglio = anomalia.foglio;
        oggetto.numero = anomalia.numero;
        oggetto.subalterno = anomalia.subalterno;
        oggetto.estremiCatastoSort = anomalia.estremiCatasto;
        oggetto.partita = anomalia.partita;
        oggetto.categoriaCatasto = anomalia.categoria;
        oggetto.classeCatasto = anomalia.classe;
        oggetto.zona = anomalia.zona;
        oggetto.indirizzoCompleto = anomalia.indirizzo;
        oggetto.indirizzoCompletoSort = anomalia.indirizzo;

        oggetto.protocolloCatasto = "";
        oggetto.annoCatasto = "";

        elencoOggetti << oggetto

        Window w = Executions.createComponents("/archivio/oggettiWebGis.zul", self,
                [oggetti: elencoOggetti,
                 zul    : '/archivio/oggettiWebGisArchivio.zul'])
        w.doModal()
    }

    @Command
    onVisualizzaPratiche() {

        tipiTributoSelezionati.clear()

        tipiTributoSelezionati << (anomaliaSelezionata.tipoTributo == 'IMU' ? 'ICI' : anomaliaSelezionata.tipoTributo)

        def lista = bonificaDatiService.getDettagliAnomaliaPratica(this.anomaliaSelezionata.tipoAnomalia, this.anomaliaSelezionata.anno, this.anomaliaSelezionata.flagImposta,
                filtriPratiche, tipiTributoSelezionati, tipiPraticheSelezionate, campiOrdinamento, pageSize, activePage)

        praticheAnomalie = lista.list
        totalSize = lista.total
        praticaSelezionata = null

        if (activePage > 0 && (activePage + 1) > Math.ceil(totalSize / pageSize)) {
            activePage = activePage - 1
        }

        BindUtils.postNotifyChange(null, null, this, "filtriAttivi")
        BindUtils.postNotifyChange(null, null, this, "praticheAnomalie")
        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "pageSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    @Command
    onFiltraPratiche(@BindingParam("popup") Component popupFiltriPratiche) {
        activePage = 0
        tributiSession.filtroAnomalie = filtriPratiche
        onVisualizzaPratiche()
        popupFiltriPratiche?.close()
    }

    @NotifyChange(["filtriPratiche", "filtriAttivi"])
    @Command
    onPulisciFiltriPratiche() {
        filtriPratiche.annoSelezionato = null
        filtriPratiche.tipoOggettoSelezionato = null
        filtriPratiche.idOggetto = null
        filtriPratiche.categoriaCatasto = null
        filtriPratiche.stato = "0"
        tributiSession.filtroAnomalie = filtriPratiche
    }

    @Command
    onCloseFiltriPratiche(@BindingParam("popup") Component popupFiltriPratiche) {
        popupFiltriPratiche?.close()
    }


    @Command
    onHelpAnomalia(@BindingParam("popup") Component popupHelp
                   , @BindingParam("ogg") def ogg) {
        praticaSelezionata = ogg

        Window w = null;

        if (!tipoAnomaliaSelezionata.zul.contains("datiCatastaliNulli.zul")) {
            w = Executions.createComponents(tipoAnomaliaSelezionata.zul, self,
                    [
                            anomaliaSelezionata: anomaliaSelezionata,
                            praticaSelezionata : bonificaDatiService.findAnomaliaPraticaDTOById(praticaSelezionata.idAnomaliaPratica),
                            lettura            : lettura
                    ])
        } else {
            w = Executions.createComponents(tipoAnomaliaSelezionata.zul, self,
                    [
                            oggetto : praticaSelezionata.idOggetto,
                            anomalia: praticaSelezionata.idAnomalia,
                            lettura : lettura
                    ]
            )
        }

        w.onClose { event ->
            if (praticaSelezionata) {
                controlloAnomalieService.checkAnomaliaPratica(praticaSelezionata.idAnomaliaPratica)
            }
            onRefresh()
            BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
            BindUtils.postNotifyChange(null, null, this, "totalSize")
            BindUtils.postNotifyChange(null, null, this, "activePage")
            BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
        }
        w.doModal()
    }

    @Command
    setSelectedDettaglio(@BindingParam("dettaglio") def dettaglio) {

        dettaglioSelezionato = dettaglio
        BindUtils.postNotifyChange(null, null, this, "dettaglioSelezionato")
    }

    @Command
    setSelectedAnomaliaPratica(@BindingParam("ogg") def ogg) {

        praticaSelezionata = ogg
        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
    }

    @NotifyChange("espandiDettagli")
    @Command
    gestisciDettagli() {
        espandiDettagli = !espandiDettagli
    }

    @NotifyChange("filtriAttivi")
    public boolean isFiltriAttivi() {
        (filtriPratiche.idOggetto != null
                || filtriPratiche.stato != "0"
                || filtriPratiche.tipoOggettoSelezionato != null
                || filtriPratiche.categoriaCatasto != null
                || filtriPratiche.annoSelezionato != null)
    }

    @Command
    void cambiaStatoAnomaliaOggetto(@BindingParam("ogg") def oggetto) {
        if (lettura) {
            return
        }
        if (!bonificaDatiService.isTipoAnomaliaForMui(tipoAnomaliaSelezionata.tipoAnomalia)) {
            return
        }
        bonificaDatiService.cambiaStatoAnomaliaMui(oggetto.idAnomalia, oggetto.flagOk == 'S' ? null : 'S')
        BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
        onRefresh()
    }

    @Command
    def cambiaStatoAnomaliaPratica(@BindingParam("ogg") def anomaliaPratica) {

        if (!lettura) {

            if (bonificaDatiService.isTipoAnomaliaForMui(tipoAnomaliaSelezionata.tipoAnomalia)) {
                bonificaDatiService.cambiaStatoAnomaliaMui(anomaliaPratica.idAnomaliaPratica, anomaliaPratica.flagOk == 'S' ? null : 'S')
            } else {
                bonificaDatiService.cambiaStatoAnomaliaPratica(anomaliaPratica.idAnomaliaPratica, anomaliaPratica.flagOk == 'S' ? 'N' : 'S')
                controlloAnomalieService.checkAnomaliaPratica(anomaliaPratica.idAnomaliaPratica)
            }

            BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
            onRefresh()
        }
    }

    @Command
    onDetailClick(@BindingParam("anomaliaId") Long anomaliaId) {
        if (anomaliaId in dettagliAperti) {
            dettagliAperti.remove(anomaliaId)
        } else {
            dettagliAperti << anomaliaId
        }
    }

    @Command
    ripristinaDettagliAperti() {
        Rows rows = praticheAnomalieGrid.getRows();
        for (Object row : rows.getChildren()) {
            if (row instanceof Row) {
                Detail detail = row.getDetailChild()

                if (row.getValue().idAnomalia in dettagliAperti) {
                    Events.sendEvent("onOpen", detail, null)
                    detail.setOpen(true)
                }
            }
        }
        praticheAnomalieGridTimer.stop()
    }

    @Command
    onRicalcolaRendita(@BindingParam("anomaliaSelezionata") def anomalia) {
        if (!bonificaDatiService.isTipoAnomaliaForMui(anomaliaSelezionata.tipoAnomalia)) {
            def anom = Anomalia.get(anomalia.idAnomalia)
            controlloAnomalieService.calcolaRendite(anom.anomaliaParametro.id, anomalia.idAnomalia)
        }

        bonificaDatiService.getDettagliAnomaliaPratica(this.anomaliaSelezionata.tipoAnomalia, this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta, filtriPratiche, tipiTributoSelezionati, tipiPraticheSelezionate, campiOrdinamento, pageSize, activePage)
                .list.find { it.idAnomalia == anomalia.idAnomalia }.each { k, v ->
            anomalia[k] = v
        }

        BindUtils.postNotifyChange(null, null, anomalia, "*")
    }

    @Command
    onCambiaOrdinamento(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        // Se l'oggetto non è presente si inizializza
        if (!campiOrdinamento[valore]) {
            campiOrdinamento[valore] = [:]
        }

        switch (campiOrdinamento[valore].verso) {
            case null:
                campiOrdinamento[valore].verso = 'A'
                campiOrdinamento[valore].posizione = campiOrdinamento.max { it.value.posizione }.value.posizione + 1
                campiCssOrdinamento[valore] = ordinamentoCss[1]
                break
            case 'A':
                campiOrdinamento[valore].verso = 'D'
                campiCssOrdinamento[valore] = ordinamentoCss[2]
                break
            case 'D':
                campiOrdinamento[valore].verso = null
                campiOrdinamento[valore].posizione = -1
                campiCssOrdinamento[valore] = ordinamentoCss[0]
                break
        }

        // Si ordinano i parametri in base alla posizione
        campiOrdinamento = campiOrdinamento.sort { it.value.posizione }

        tipiTributoSelezionati.clear()
        tipiTributoSelezionati << (anomaliaSelezionata.tipoTributo == 'IMU' ? 'ICI' : anomaliaSelezionata.tipoTributo)

        def lista = bonificaDatiService.getDettagliAnomaliaPratica(this.anomaliaSelezionata.tipoAnomalia, this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta, filtriPratiche, tipiTributoSelezionati, tipiPraticheSelezionate, campiOrdinamento, pageSize, activePage)
        praticheAnomalie = lista.list
        totalSize = lista.total

        BindUtils.postNotifyChange(null, null, this, "praticheAnomalie")
        BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")
    }

    ///
    /// Crea un popup
    ///
    private void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }
}
