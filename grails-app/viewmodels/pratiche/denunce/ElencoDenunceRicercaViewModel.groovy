package pratiche.denunce

import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.denunce.FiltroRicercaDenunce
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ElencoDenunceRicercaViewModel {

    // services
    def springSecurityService
    DenunceService denunceService
    CanoneUnicoService canoneUnicoService

    // componenti
    Window self

    String tipoTributo
    def documentIdList
    boolean filtroDocVisibile

    String annoTributo

    // dati
    def lista
    def selected
    Date aData = new Date()

    // ricerca
    def listaFonti
    def disabilitaANumero = false
    def listaTipiPratica

    FiltroRicercaDenunce mapParametri
    FiltroRicercaCanoni filtriAggiunti

    def listaTariffe = []
    def tariffeSelezionate = []

    def listCodici = []
    def codiciSelezionati = []

    def filtriComuni = [
            comuneOggetto: [
                    denominazione: "",
                    provincia    : "",
                    siglaProv    : ""
            ]
    ]

    def tipiEsenzione = [
            [codice: 'S', descrizione: 'Si'],
            [codice: 'N', descrizione: 'No'],
            [codice: null, descrizione: 'Tutto'],
    ]

    def filtroNullaOsta = [
            [codice: 'S', descrizione: 'Si'],
            [codice: 'N', descrizione: 'No'],
            [codice: null, descrizione: 'Tutto'],
    ]

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") FiltroRicercaDenunce parametriRicerca,
         @ExecutionArgParam("tipoTributo") String tipoTributo) {

        this.self = w

        this.tipoTributo = tipoTributo
        this.annoTributo = "Tutti"

        caricaListaFonti()
        listaTipiPratica = [
                '*'                      : 'Tutte',
                (TipoPratica.D.tipoPratica): TipoPratica.D.descrizione,
                (TipoPratica.P.tipoPratica): TipoPratica.P.descrizione
        ]

        mapParametri = parametriRicerca ?: new FiltroRicercaDenunce()
        mapParametri.tipoPratica = mapParametri?.tipoPratica ?: '*'

        filtriAggiunti = mapParametri.filtriAggiunti ?: new FiltroRicercaCanoni()

        filtroDocVisibile = DenunceService.VISUALIZZA_DOC_ID[tipoTributo]

        if (filtroDocVisibile) {
            def filter = [:]
            filter.put("tipoTributo", tipoTributo)
            documentIdList = denunceService.getProgrDocumenti(DenunceService.DENUNCE, filter)
            documentIdList = [["descrizione": "Tutti"]] + documentIdList
        }

        codiciSelezionati = []
        tariffeSelezionate = []

        if (tipoTributo == 'CUNI') {

            leggiDettagliComuneOggetto()

            def filtriCodici = [
                    tipoTributo: tipoTributo,
                    fullList   : (annoTributo == 'Tutti')
            ]
            listCodici = canoneUnicoService.getElencoDettagliatoCodiciTributo(filtriCodici)

            def selezione = parametriRicerca?.codiciTributo ?: []
            codiciSelezionati = aggiornaSelezionati(listCodici, selezione)

            ricaricaElencoTariffe()

            selezione = parametriRicerca?.tipiTariffa ?: []
            tariffeSelezionate = aggiornaSelezionati(listaTariffe, selezione)
        }

        onCambiaNumero()

        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    private void caricaListaFonti() {
        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()
        BindUtils.postNotifyChange(null, null, this, "listaFonti")
    }

    @Command
    onRefresh() {
        caricaListaFonti()
    }

    @Command
    onCerca() {

        def errors = controllaNumero()

        if (errors != null) {
            Clients.showNotification(errors, Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 2000, true)
            return
        }

        mapParametri.filtriAggiunti = filtriAggiunti
		
        def codiciTributo = []
        codiciSelezionati.each { codiciTributo << it.codice }
        mapParametri.codiciTributo = codiciTributo

        def tipiTariffa = []
        tariffeSelezionate.each { tipiTariffa << it.codice }
        mapParametri.tipiTariffa = tipiTariffa

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    svuotaFiltri() {

        mapParametri = new FiltroRicercaDenunce()
        filtriAggiunti = new FiltroRicercaCanoni()
        mapParametri.tipoPratica = '*'

        codiciSelezionati = []
        tariffeSelezionate = []
        disabilitaANumero = false
        leggiDettagliComuneOggetto()

        BindUtils.postNotifyChange(null, null, this, "mapParametri")
        BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
        BindUtils.postNotifyChange(null, null, this, "codiciSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoCodiciSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoCodiciSelezionatiToolTip")
        BindUtils.postNotifyChange(null, null, this, "tariffeSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoTariffeSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoTariffeSelezionateToolTip")
        BindUtils.postNotifyChange(null, null, this, "disabilitaANumero")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi"])
    }

    /// Filtri aggiuntivi ################################################################################################################

    @Command
    def onSelectComuneOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def selectedComune = event?.data

        if (selectedComune != null) {
            filtriAggiunti.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
            filtriAggiunti.codCom = selectedComune.comune
        } else {
            filtriAggiunti.codPro = null
            filtriAggiunti.codCom = null
        }

        leggiDettagliComuneOggetto()
    }

    @NotifyChange(["elencoCodiciSelezionati", "elencoCodiciSelezionatiToolTip", "elencoTariffeSelezionate", "elencoTariffeSelezionateToolTip"])
    @Command
    def onSelectCodiceTributo() {

        ricaricaElencoTariffe()

        def selezione = tariffeSelezionate?.collect { it.codice }
        tariffeSelezionate = aggiornaSelezionati(listaTariffe, selezione)
        BindUtils.postNotifyChange(null, null, this, "tariffeSelezionate")
    }

    String getElencoCodiciSelezionati() {

        String elenco = codiciSelezionati?.descrizioneFull?.join(", ")

        if (elenco.size() > 90) {
            elenco = codiciSelezionati?.codice?.join(", ")
        }

        return elenco
    }

    String getElencoCodiciSelezionatiToolTip() {

        return codiciSelezionati?.descrizioneFull?.join("\n")
    }

    @NotifyChange(["elencoTariffeSelezionate", "elencoTariffeSelezionateToolTip"])
    @Command
    def onSelectTariffa() {

    }

    String getElencoTariffeSelezionate() {

        String elenco = tariffeSelezionate?.descrizioneFull?.join(", ")

        if (elenco.size() > 90) {
            elenco = tariffeSelezionate?.nome?.join(", ")
        }

        return elenco
    }

    String getElencoTariffeSelezionateToolTip() {

        return tariffeSelezionate?.descrizioneFull?.join("\n")
    }

    @Command
    def onCambiaNumero() {

        def errors = controllaNumero()

        if (errors != null) {
            Clients.showNotification(errors, Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 2000, true)
        }

    }

    /// Funzioni private ######################################################################################################

    def leggiDettagliComuneOggetto() {

        Ad4ComuneTr4 comune = null

        Long codPro = filtriAggiunti.codPro as Long
        Integer codCom = filtriAggiunti.codCom as Integer

        if (codCom != null && codPro != null) {
            comune = Ad4ComuneTr4.createCriteria().get {
                eq('provinciaStato', codPro)
                eq('comune', codCom)
            }
        }

        def comuneOggetto = filtriComuni.comuneOggetto

        if (comune) {
            Ad4Comune ad4Comune = comune.ad4Comune

            comuneOggetto.denominazione = ad4Comune?.denominazione
            comuneOggetto.provincia = ad4Comune?.provincia?.denominazione
            comuneOggetto.siglaProv = ad4Comune?.provincia?.sigla
        } else {
            comuneOggetto.denominazione = ""
            comuneOggetto.provincia = ""
            comuneOggetto.siglaProv = ""
        }

        BindUtils.postNotifyChange(null, null, this, "filtriComuni")
    }

    def ricaricaElencoTariffe() {

        Short anno

        if (annoTributo == 'Tutti') {
            anno = Calendar.getInstance().get(Calendar.YEAR) as Short
        } else {
            anno = annoTributo as Short
        }

        def elencoCodici = codiciSelezionati?.collect { it.codice as Long }
        def numCodici = (elencoCodici ?: []).size()

        def filtriTariffe = [
                tipoTributo : 'CUNI',
                annoTributo : anno,
                elencoCodici: elencoCodici
        ]
        listaTariffe = canoneUnicoService.getElencoDettagliatoTariffe(filtriTariffe, (numCodici != 1))

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
    }

    ///
    /// *** Aggiorna selezionati x codice da lista
    ///
    private def aggiornaSelezionati(def lista, def selezionati) {

        def listaSelezionati = []

        selezionati.each {

            def codice = it
            def selezione = lista.find { it.codice == codice }

            if (selezione) {
                listaSelezionati << selezione
            }
        }

        return listaSelezionati
    }

    private def controllaNumero() {

        def daNumero = mapParametri?.daNumero
        def aNumero = mapParametri?.aNumero

        def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
        def isANumeroNotEmpty = aNumero != null && aNumero != ""


        if (isDaNumeroNotEmpty && daNumero.contains('%')) {
            disabilitaANumero = true

            // Si elimina il valore al
            mapParametri?.aNumero = null
            BindUtils.postNotifyChange(null, null, mapParametri, "aNumero")
        } else {
            disabilitaANumero = false
        }

        BindUtils.postNotifyChange(null, null, this, "disabilitaANumero")

        if (isANumeroNotEmpty && aNumero.contains('%')) {
            return "Carattere '%' non consentito nel campo Numero A"
        }

        // Nel caso in cui sia dal che al contengono un valore numerico si controlla che dal < al
        if (isANumeroNotEmpty && isDaNumeroNotEmpty && daNumero.isNumber() && aNumero.isNumber()) {
            if ((aNumero as Long) < (daNumero as Long)) {
                return "Numero Dal deve essere minore di Numero Al"
            }
        }

        return null
    }
}
