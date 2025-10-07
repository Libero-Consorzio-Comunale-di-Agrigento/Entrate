package archivio

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Sessions
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Tabs
import org.zkoss.zul.Window

class ArchivioIndexViewModel {

    Window self
    def selectedTab

    def amministratore = false

    // Servizi
    CommonService commonService
    CompetenzeService competenzeService
    DatiGeneraliService datiGeneraliService

    def cbTributiAbilitati = [:]
    def cbTributiConCompetenze = [:]

    // stato
    String selectedSezione
    String selectedSezioneDizionari
    String urlSezione
    String zul
    String tipoTributoAttivo
    def selectedTabTributo
    def annoTributoAttivo
    def tipoTributoAttuale

    OggettiCacheMap oggettiCacheMap

    def gestioneCompetenzeAbilitata = false

    def pagineArchivio = [
            "soggetti"  : "/archivio/listaSoggetti.zul"
            , "oggetti" : "/archivio/listaOggetti.zul"
            , "catasto" : "/catasto/catasto.zul"
            , "famiglie": "/archivio/listaFamiglie.zul"]

    def tabDizionari = [
            "modelli"      : ["include": "/archivio/dizionari/gestioneModelli.zul", "url": "/archivio/dizionari/gestioneModelli.zul"],
            "datiContabili": ["include": "/archivio/dizionari/listaDatiContabili.zul", "url": "/archivio/dizionari/listaDatiContabili.zul"],
            "installParams": ["include": "/archivio/dizionari/installazioneParametri.zul", "url": "/archivio/dizionari/installazioneParametri.zul"],
            "codifiche"    : ["include": "/archivio/dizionari/tabCodifiche.zul", "url": "/archivio/dizionari/listaCodificheBase.zul"],
            "competenze"   : ["include": "/archivio/dizionari/competenze.zul", "url": "/archivio/dizionari/competenze.zul"],
            "datiGenerali" : ["include": "/archivio/dizionari/datiGenerali.zul", "url": "/archivio/dizionari/datiGenerali.zul"],
            "tributo"      : ["include": "/archivio/dizionari/tributo.zul", "url": "/archivio/dizionari/tributo.zul"],
            "stradario"    : ["include": "/archivio/dizionari/stradario.zul", "url": "/archivio/dizionari/stradario.zul"]
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        selectedTab = 0
        String elemento = Sessions.getCurrent().getAttribute("elemento")
        Sessions.getCurrent().removeAttribute("elemento")
        setSelectedSezione(elemento)

        verificaCompetenze()

        amministratore = competenzeService.isAmministratore()

        annoTributoAttivo = commonService.yearFromDate(new Date())
    }

    List<String> getPatterns() {
        return pagineArchivio.collect { it.key }
    }

    @GlobalCommand
    def setAnnoTributoAttivo(@BindingParam("annoTributo") def annoTributo) {

        this.annoTributoAttivo = annoTributo

        BindUtils.postNotifyChange(null, null, this, "annoTributoAttivo")
    }

    void handleBookmarkChange(String bookmark) {
        setSelectedSezione(bookmark)
    }

    void setSelectedSezione(String value) {
        if (value == null || value.length() == 0) {
            urlSezione = null
        }

        if (value.equals("dizionari"))
            selectedTab = 1
        else {
            selectedSezione = value
            urlSezione = pagineArchivio[selectedSezione]
            BindUtils.postNotifyChange(null, null, this, "urlSezione")
        }
    }

    void setSelectedTabTributo(def index) {
        selectedTabTributo = index

        tipoTributoAttuale = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributoAttivo }?.getTipoTributoAttuale()

        BindUtils.postGlobalCommand(null, null, "setTipoTributoAttivo",
                [tipoTributo: tipoTributoAttivo, selectedTabIndex: index])

        BindUtils.postNotifyChange(null, null, this, "tipoTributoAttuale")
    }

    void setSelectedSezioneDizionari(String value) {
        if (value == 'aggiorna') {
            oggettiCacheMap.refresh()
            Clients.showNotification("Cache dei dizionari aggiornata. ", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            return
        }

        if (value == null || value.length() == 0) {
            urlSezione = null
            zul = null
            tipoTributoAttivo = null
        } else {
            def sezioneDizionariToOpen

            selectedSezioneDizionari = value

            if (value.toUpperCase() in cbTributiAbilitati.keySet()) {
                sezioneDizionariToOpen = 'tributo'
                tipoTributoAttivo = value.toUpperCase()
            } else {

                sezioneDizionariToOpen = value
            }

            urlSezione = tabDizionari[sezioneDizionariToOpen]["include"]
            zul = tabDizionari[sezioneDizionariToOpen]["url"]
        }

        if (tipoTributoAttivo != 'TRASV') {
            setSelectedTabTributo(0)
        } else {
            setSelectedTabTributo(35) // Comunicazioni
        }

        BindUtils.postGlobalCommand(null, null, "setTipoTributoAttivo",
                [tipoTributo: tipoTributoAttivo, selectedTabIndex: selectedTabTributo])
        BindUtils.postNotifyChange(null, null, this, "tipoTributoAttivo")
        BindUtils.postNotifyChange(null, null, this, "zul")
        BindUtils.postNotifyChange(null, null, this, "urlSezione")
        BindUtils.postNotifyChange(null, null, this, "selectedTabTributo")
    }

    private verificaCompetenze() {

        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]

            def tipoAbilitazione = competenzeService.tipoAbilitazioneUtente(it.tipoTributo)
            def lettura = (tipoAbilitazione == competenzeService.TIPO_ABILITAZIONE.LETTURA)
            def scrittura = (tipoAbilitazione == competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)

            cbTributiConCompetenze << [(it.tipoTributo): (lettura || scrittura)]
        }


        gestioneCompetenzeAbilitata = datiGeneraliService.gestioneCompetenzeAbilitata()
    }
}
