package ufficiotributi.bonificaDati

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.anomalie.Anomalia
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.bonificaDati.nonDichiarati.BonificaNonDichiaratiService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoIntervento
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.anomalie.AnomaliaDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettagliAnomaliaOggettoViewModel {

    Window self

    CompetenzeService competenzeService
    BonificaNonDichiaratiService bonificaNonDichiaratiService

    Boolean lettura = true

    // paginazione
    int activePage = 0
    int pageSize = 10
    def totalSize

    int activePagePrt = 0
    int pageSizePrt = 10
    def totalSizePrt

    def listaCategorieCatasto

    def filtriOggetto
    /*
    def filtriOggetto = [stato                   : null
                         , tipoOggettoSelezionato: null
                         , idOggetto             : null
                         , categoriaCatasto      : null
    ]

     */

    def filtriPratiche = [
            cbTributi        : [
                    TASI   : true
                    , ICI  : true
                    , TARSU: true
                    , ICP  : true
                    , TOSAP: true]

            , cbTipiPratica  : [
            D  : true    // dichiarazione D
            , A: true    // accertamento A
            , L: true    // liquidazione L
            , I: true    // infrazioni I
            , V: true]    // ravvedimenti V
            , annoSelezionato: null
    ]

    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true]

    def cbTipiPratica = [
            D  : true    // dichiarazione D
            , A: true    // accertamento A
            , L: true    // liquidazione L
            , I: true    // infrazioni I
            , R: true    // ravvedimenti R
            , V: true]    // versamenti V

    List oggettiAnomalie
    Long selectedAnyOggetto = 0
    def selectedOggetti = [:]

    List praticheContribuenti
    def listaContribuenti

    def contribuenteSelezionato

    List listaTipiOggetto
    List listaAnni

    List tipiTributoSelezionati = []
    List tipiPraticheSelezionate = []
    Integer anno = null

    def oggettoSelezionato
    def anomaliaSelezionata

    boolean openOggetti = false
    boolean openPratiche = false
    boolean filtriOggettiAttivi = false
    boolean filtriPraticheAttive = false
    boolean refreshPrt = false
    boolean visualizzaHelp = true

    def campiOrdinamento = [
            'idOggetto': [verso: 'A', posizione: 0]
    ]

    def campiCssOrdinamento =
            [
                    'idOggetto': 'z-listheader-sort-asc_'
            ]

    def ordinamentoCss = [
            0: '',
            1: 'z-listheader-sort-asc_',
            2: 'z-listheader-sort-dsc_'
    ]

    AnomaliaDTO anomalia

    Map praticaSelezionata

    BonificaDatiService bonificaDatiService
    ControlloAnomalieService controlloAnomalieService
    ContribuentiService contribuentiService
    TributiSession tributiSession

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore
        listaTipiOggetto = OggettiCache.TIPI_OGGETTO.valore

        filtriOggetto = tributiSession.filtroAnomalie
        if (!filtriOggetto) {
            filtriOggetto = [stato                   : null
                             , tipoOggettoSelezionato: null
                             , idOggetto             : null
                             , categoriaCatasto      : null
            ]
        }

        if (filtriOggetto.stato != null || filtriOggetto.tipoOggettoSelezionato != null || filtriOggetto.idOggetto != null) {
            filtriOggettiAttivi = true
        }
    }

    @GlobalCommand
    loadDettagliAnomalia(@BindingParam("anomaliaSelezionata") def anomaliaSelezionata, @BindingParam("idOggetto") def idOggetto) {

        if (anomaliaSelezionata.tipoIntervento != TipoIntervento.OGGETTO) {
            return
        }

        lettura = !competenzeService.utenteAbilitatoScrittura(anomaliaSelezionata.tipoTributoOrg);
        BindUtils.postNotifyChange(null, null, this, "lettura")

        activePage = 0
        this.anomaliaSelezionata = anomaliaSelezionata
        if (idOggetto) {
            filtriOggetto.idOggetto = idOggetto
        }

        def lista = bonificaDatiService.getDettagli(
                this.anomaliaSelezionata.tipoAnomalia,
                this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta,
                this.anomaliaSelezionata.tipoTributo,
                filtriOggetto,
                campiOrdinamento,
                pageSize,
                activePage)

        oggettiAnomalie = lista.list
        totalSize = lista.total
        //activePage = lista.activePage

        BindUtils.postNotifyChange(null, null, this, "filtriOggettiAttivi")
        BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "pageSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")

        selectedOggettiReset()

        openOggetti = true
        openPratiche = false
        refreshPrt = false
        visualizzaHelp = !(this.anomaliaSelezionata.pannello == null)
        BindUtils.postNotifyChange(null, null, this, "openOggetti")
        BindUtils.postNotifyChange(null, null, this, "openPratiche")
        BindUtils.postNotifyChange(null, null, this, "refreshPrt")
        BindUtils.postNotifyChange(null, null, this, "visualizzaHelp")

    }

    @NotifyChange(["oggettiAnomalie", "totalSize", "activePage"])
    @Command
    onRefresh() {
        onVisualizzaOggetti()
    }

    @NotifyChange(["oggettiAnomalie", "openOggetti", "openPratiche", "dettagliAnomalia", "filtriOggettiAttivi"])
    @Command
    onVisualizzaOggetti() {

        for (k in filtriOggetto) {
            if (k.value) {
                filtriOggettiAttivi = true
                break
            }
        }

        def lista = bonificaDatiService.getDettagli(
                this.anomaliaSelezionata.tipoAnomalia,
                this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta,
                this.anomaliaSelezionata.tipoTributo,
                filtriOggetto,
                campiOrdinamento,
                pageSize,
                activePage)

        oggettiAnomalie = lista.list
        totalSize = lista.total
        openOggetti = true
        openPratiche = false
        refreshPrt = false
        activePage = lista.activePage

        BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
        BindUtils.postNotifyChange(null, null, this, "pageSize")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")
    }

    @NotifyChange("filtriOggetto")
    @Command
    onCloseFiltri(@BindingParam("popup") Component popupFiltriOggetti) {
        filtriOggetto.stato = null
        filtriOggetto.tipoOggettoSelezionato = null
        filtriOggetto.idOggetto = null
        popupFiltriOggetti?.close()
    }

    @NotifyChange(["filtriOggetto", "filtriOggettiAttivi"])
    @Command
    onPulisciFiltri() {
        for (f in filtriOggetto) {
            f.value = null
        }
        tributiSession.filtroAnomalie = filtriOggetto
    }

    @Command
    onCorreggiAnomalia() {

        Window w = Executions.createComponents("/archivio/oggetto.zul", self,
                [
                        oggetto    : oggettoSelezionato.idOggetto,
                        daBonifiche: true,
                        lettura    : lettura
                ]
        )
        w.onClose() { event ->

            if (event.data && event.data.aggiornaStato) {
                bonificaDatiService.cambiaStatoAnomaliaOggetto(oggettoSelezionato.idAnomalia)
                controlloAnomalieService.checkAnomalia(oggettoSelezionato.idAnomalia)
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
    onVisualizzaCatasto(@BindingParam("anomalia") def anomalia) {

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
    onVisualizzaMappa(@BindingParam("anomalia") def anomalia) {

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
    onHelpAnomalia() {

        String pannello = this.anomaliaSelezionata.pannello;

        if ((pannello != null) && (pannello.length() > 0)) {

            if (pannello.substring(0, 1) != "/") {
                pannello = "/ufficiotributi/bonificaDati/" + pannello;
            }

            Window w = Executions.createComponents(pannello, self,
                    [
                            oggetto : oggettoSelezionato.idOggetto,
                            anomalia: oggettoSelezionato.idAnomalia,
                            lettura: lettura
                    ]
            )
            w.onClose() {
                onRefresh()
                BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
                BindUtils.postNotifyChange(null, null, this, "totalSize")
                BindUtils.postNotifyChange(null, null, this, "activePage")
            }
            w.doModal()
        } else {
            String title = "Trattamento dell'anomalia";
            String message = "Aiuto non disponibile";
            Messagebox.show(message, title, Messagebox.OK, Messagebox.INFORMATION);
        }
    }

    @NotifyChange(["oggettiAnomalie"])
    @Command
    onFiltraOggetti(@BindingParam("popup") Component popupFiltriOggetti) {
        activePage = 0
        tributiSession.filtroAnomalie = filtriOggetto
        onVisualizzaOggetti()
        popupFiltriOggetti?.close()
    }

    @Command
    onFiltraContribuenti(@BindingParam("popup") Component popupFiltriContribuenti) {
        onSelezionaPratica()
        popupFiltriContribuenti?.close()

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
    }

    @NotifyChange(["praticheContribuenti", "openPratiche", "listaAnni", "filtriPraticheAttive", "praticaSelezionata", "listaContribuenti"])
    @Command
    onVisualizzaPraticheOggetto() {

        activePagePrt = 0

        praticaSelezionata = null
        listaContribuenti = []

        onVisualizzaPratiche()

        ricaricaContribuenti();
    }

    @Command
    onSelezionaPratica() {

        ricaricaContribuenti();
    }

    private
    def ricaricaContribuenti() {

        listaContribuenti = contribuentiService.getContribuentiOggetto(oggettoSelezionato.idOggetto, null, cbTributi, cbTipiPratica).lista
        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
    }

    @NotifyChange(["praticheContribuenti", "openPratiche", "listaAnni", "filtriPraticheAttive"])
    @Command
    onVisualizzaPratiche() {
        if (!refreshPrt) {
            listaAnni = bonificaDatiService.pratichePerAnni(oggettoSelezionato.idOggetto)
        }

        for (tipoTri in filtriPratiche.cbTributi) {
            if (!tipoTri.getValue() && !tipiTributoSelezionati.contains(tipoTri.getKey()))
                tipiTributoSelezionati << tipoTri.getKey()
            if (tipoTri.getValue())
                tipiTributoSelezionati.remove(tipoTri.getKey())
        }

        for (tipoPrt in filtriPratiche.cbTipiPratica) {
            if (!tipoPrt.getValue() && !tipiPraticheSelezionate.contains(tipoPrt.getKey()))
                tipiPraticheSelezionate << tipoPrt.getKey()
            if (tipoPrt.getValue())
                tipiPraticheSelezionate.remove(tipoPrt.getKey())
        }

        def listaPrt = bonificaDatiService.getPratiche(oggettoSelezionato.idOggetto, pageSizePrt, activePagePrt, tipiTributoSelezionati, tipiPraticheSelezionate, filtriPratiche.annoSelezionato)
        praticheContribuenti = listaPrt.list

        totalSizePrt = listaPrt.total
        openPratiche = true

        if (tipiTributoSelezionati.join(',') != "" || tipiPraticheSelezionate.join(',') != "" || filtriPratiche.annoSelezionato != null)
            filtriPraticheAttive = true
        refreshPrt = false

        BindUtils.postNotifyChange(null, null, this, "totalSizePrt")
        BindUtils.postNotifyChange(null, null, this, "activePagePrt")
    }

    @NotifyChange(["praticheContribuenti"])
    @Command
    onRefreshPratiche() {
        refreshPrt = true
        onVisualizzaPratiche()
    }

    @Command
    onChangeTipoTributo() {
        BindUtils.postNotifyChange(null, null, this, "filtriPratiche")
        BindUtils.postNotifyChange(null, null, this, "praticheContribuenti")
    }

    @Command
    onChangeTipoPratica() {
        if (filtriPratiche.cbTipiPratica.L) {
            filtriPratiche.cbTipiPratica.I = true
        } else {
            filtriPratiche.cbTipiPratica.I = false
            filtriPratiche.cbTipiPratica.L = false
        }
        BindUtils.postNotifyChange(null, null, this, "filtriPratiche")
        BindUtils.postNotifyChange(null, null, this, "praticheContribuenti")
    }

    @NotifyChange(["praticheContribuenti", "openPratiche", "listaAnni"])
    @Command
    onFiltraPratiche(@BindingParam("popup") Component popupFiltriPratiche) {
        refreshPrt = true
        activePagePrt = 0
        onVisualizzaPratiche()
        popupFiltriPratiche?.close()
    }

    @NotifyChange(["filtriPratiche", "filtriPraticheAttive"])
    @Command
    onPulisciFiltriPratiche() {
        filtriPratiche.cbTributi.TASI = true
        filtriPratiche.cbTributi.ICI = true
        filtriPratiche.cbTributi.TARSU = true
        filtriPratiche.cbTributi.ICP = true
        filtriPratiche.cbTributi.TOSAP = true

        filtriPratiche.cbTipiPratica.D = true
        filtriPratiche.cbTipiPratica.A = true
        filtriPratiche.cbTipiPratica.L = true
        filtriPratiche.cbTipiPratica.I = true
        filtriPratiche.cbTipiPratica.V = true

        filtriPratiche.annoSelezionato = null
        filtriPraticheAttive = false
    }

    @NotifyChange(["filtriContribuenti"])
    @Command
    onPulisciFiltriContribuenti() {
        cbTributi.TASI = true
        cbTributi.ICI = true
        cbTributi.TARSU = true
        cbTributi.ICP = true
        cbTributi.TOSAP = true

        cbTipiPratica.D = true
        cbTipiPratica.A = true
        cbTipiPratica.L = true
        cbTipiPratica.I = true
        cbTipiPratica.V = true
    }

    @Command
    onCloseFiltriContribuenti(@BindingParam("popup") Component popupFiltriContribuenti) {
        popupFiltriContribuenti?.close()
    }

    @Command
    onCloseFiltriPratiche(@BindingParam("popup") Component popupFiltriPratiche) {
        popupFiltriPratiche?.close()
    }

    @Command
    onInfoPratica() {
        // TODO: dato che abbiamo l'apertura anche delle liquidazioni e degli accertamenti
        //       sarebbe da implementare anche l'apertura per questo tipo di pratiche
        //       come nella situazione del contribuente
        if (praticaSelezionata.tipoPratica == "D") {
            String parametri = "sezione=PRATICA"
            parametri += "&idPratica=${praticaSelezionata.idPratica}"
            parametri += "&tipoTributo=${praticaSelezionata.tipoTributo}"
            parametri += "&tipoRapporto=${praticaSelezionata.tipoRapporto}"

            Clients.evalJavaScript("window.open('standalone.zul?$parametri','_blank');")
        } else {
            Clients.showNotification("In fase di realizzazione", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(contribuenteSelezionato?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    cambiaStatoAnomalia(@BindingParam("anomaliaSelezionata") def anomalia) {

        if (!lettura) {
            bonificaDatiService.cambiaStatoAnomaliaOggetto(anomalia.idAnomalia, anomalia.stato == 'S' ? 'N' : 'S')
            controlloAnomalieService.checkAnomalia(oggettoSelezionato.idAnomalia)
            BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)
            onRefresh()
        }
    }

    @Command
    onRicalcolaRendita(@BindingParam("anomaliaSelezionata") def anomalia) {

        def anom = Anomalia.get(anomalia.idAnomalia)

        controlloAnomalieService.calcolaRendite(anom.anomaliaParametro.id, anomalia.idAnomalia)

        def lista = bonificaDatiService.getDettagli(
                this.anomaliaSelezionata.tipoAnomalia,
                this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta,
                this.anomaliaSelezionata.tipoTributo,
                filtriOggetto,
                campiOrdinamento,
                pageSize,
                activePage)

        lista.list.find { it.idAnomalia == anomalia.idAnomalia }.each { k, v ->
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
        campiOrdinamento = campiOrdinamento.sort { -it.value.posizione }
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")

        def lista = bonificaDatiService.getDettagli(
                this.anomaliaSelezionata.tipoAnomalia,
                this.anomaliaSelezionata.anno,
                this.anomaliaSelezionata.flagImposta,
                this.anomaliaSelezionata.tipoTributo,
                filtriOggetto,
                campiOrdinamento,
                pageSize,
                activePage)

        oggettiAnomalie = lista.list
        totalSize = lista.total

        BindUtils.postNotifyChange(null, null, this, "oggettiAnomalie")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
    }

    @Command
    onCheckAllOggetti() {

        selectedAnyOggettoRefresh()

        selectedOggetti = [:]

        if (!selectedAnyOggetto) {

            def lista = bonificaDatiService.getDettagli(
                    this.anomaliaSelezionata.tipoAnomalia,
                    this.anomaliaSelezionata.anno,
                    this.anomaliaSelezionata.flagImposta,
                    this.anomaliaSelezionata.tipoTributo,
                    filtriOggetto,
                    campiOrdinamento,
                    Integer.MAX_VALUE, 0)

            def listOggetti = lista.list

            listOggetti.each() { d -> (selectedOggetti << [(d.idOggetto): true]) }
        }

        BindUtils.postNotifyChange(null, null, this, "selectedOggetti")
        selectedAnyOggettoRefresh()
    }

    @Command
    onSelectOggettoAnomalia() {

    }

    @Command
    onOggettoVisualizzazioneCatasto() {

        def oggetto = oggettoSelezionato;

        def oggettoPerCensuario = [
                oggetto   : oggetto.idOggetto,
                indirizzo : oggetto.indirizzo,
                sezione   : oggetto.sezione ?: '',
                foglio    : oggetto.foglio ?: '',
                numero    : oggetto.numero ?: '',
                subalterno: oggetto.subalterno ?: '',
                tipoOggetto: oggetto.tipoOggetto
        ]

        creaPopup("/sportello/contribuenti/informazioniCatastoCensuario.zul", [oggetto: oggettoPerCensuario])
    }

    @Command
    onOggettiInserimentoRendite() {

        def elencoOggetti = []

        def activeOggetti = selectedOggetti.findAll { k, v -> v }
        if (activeOggetti.size() > 0) {

            activeOggetti.each {
                elencoOggetti << it.key
            }
        } else {
            elencoOggetti << oggettoSelezionato.idOggetto
        };

        def parametriRicerca = [
                idOggetti: elencoOggetti
        ]

        def immobiliDaElaborare = bonificaNonDichiaratiService.preparaListaImmobiliDaOggetti(parametriRicerca)
        def totaleImmobili = immobiliDaElaborare.totaleImmobili;
        def listaImmobili = immobiliDaElaborare.listaImmobili

        creaPopup("/ufficiotributi/bonificaDati/nonDichiarati/nonDichiaratiRendita.zul",
                [
                        totale      : totaleImmobili,
                        immobili    : listaImmobili,
                        datiSoggetti: false
                ]
        )
    }

    @Command
    onCheckOggetto(@BindingParam("detail") def detail) {

        selectedAnyOggettoRefresh();
    }

    def selectedOggettiReset() {

        oggettoSelezionato = null
        selectedOggetti = [:]
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "selectedOggetti")

        selectedAnyOggettoRefresh();
    }

    def selectedAnyOggettoRefresh() {

        def activeOggetti = selectedOggetti.findAll { k, v -> v }
        selectedAnyOggetto = activeOggetti.size()
        BindUtils.postNotifyChange(null, null, this, "selectedAnyOggetto")
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
