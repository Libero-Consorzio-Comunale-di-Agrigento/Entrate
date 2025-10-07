package archivio

import document.FileNameGenerator
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.tr4.Anadev
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

class VariazioniAnaResViewModel {

    // Componenti
    Window self

    @Wire("#pagingAnagrafiche")
    protected Paging pagingAnagrafiche

    @Wire("#pagingResidenze")
    protected Paging pagingResidenze

    // Service
    SoggettiService soggettiService
    CommonService commonService

    // Modello
    def variazioneTabSelezionato

    //Variazioni Residenze
    def listaVariazioniResidenze = []
    def tipoEvento
    def dataResEventoDal
    def dataResEventoAl
    def tipoResidente
    def tipoSoggettoRes
    def selectedVariazioniResidenze
    // paginazione
    int activePageResidenze = 0
    int pageSizeResidenze = 15
    int totalSizeResidenze

    //Variazioni anagrafiche
    def listaVariazioniAnagrafiche = []
    def listaAnadev
    def tipoEventoSelezionato
    def dataAnaEventoDal
    def dataAnaEventoAl
    def tipoSoggetto
    def selectedVariazioniAnagrafiche
    // paginazione
    int activePageAnagrafiche = 0
    int pageSizeAnagrafiche = 15
    int totalSizeAnagrafiche

    //Comuni
    def esisteCodFamiliare

    Map filtri = [comuneEvento: [comune: "", denominazione: "", provincia: "", sigla: ""]]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        tipoEvento = 91
        tipoSoggetto = 0
        tipoSoggettoRes = 0
        tipoResidente = 0
        variazioneTabSelezionato = 0
        esisteCodFamiliare = false
        listaAnadev = Anadev.findAllByFlagStato('S').sort { it.descrizione }.toDTO()
        BindUtils.postNotifyChange(null, null, this, "tipoEvento")
        BindUtils.postNotifyChange(null, null, this, "listaAnadev")
    }

    @NotifyChange(["selectedVariazioniResidenze", "esisteCodFamiliare"])
    @Command
    onRefreshResidenze() {
        resetPaginazione()
        caricaLista()
        selectedVariazioniResidenze = null
        esisteCodFamiliare = false

    }

    @Command
    def onSelectVariazione(@BindingParam("tipo") def tipo) {

        def niSoggetto = (tipo == "residenze" ? selectedVariazioniResidenze.ni : selectedVariazioniAnagrafiche.ni)

        if (!niSoggetto) {
            esisteCodFamiliare = false
            return
        }

        SoggettoDTO soggetto = Soggetto.findById(niSoggetto).toDTO()

        if (soggetto.codFam) {
            esisteCodFamiliare = true
        } else {
            esisteCodFamiliare = false
        }

        BindUtils.postNotifyChange(null, null, this, "esisteCodFamiliare")

    }

    @NotifyChange(["selectedVariazioniAnagrafiche", "esisteCodFamiliare"])
    @Command
    onRefreshAnagrafiche() {
        resetPaginazione()
        caricaLista()
        selectedVariazioniAnagrafiche = null
        esisteCodFamiliare = false
    }

    @Command
    onExportXlsResidenze() {
        def variazioniResidenze =
                soggettiService.variazioniResidenze(tipoEvento, dataResEventoDal, dataResEventoAl, pageSizeResidenze,
                        activePageResidenze, tipoSoggettoRes, true)
        listaVariazioniResidenze = variazioniResidenze.records
        totalSizeResidenze = variazioniResidenze.totalCount
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.VARIAZIONI_RESIDENZE,
                [:])
        onExportXls(listaVariazioniResidenze, nomeFile)
    }

    @Command
    onExportXlsAnagrafiche() {
        def variazioneAnagrafiche =
                soggettiService.variazioniAnagrafiche(tipoEventoSelezionato.id, filtri.comuneEvento.comune,
                        filtri.comuneEvento.provincia, dataAnaEventoDal, dataAnaEventoAl, pageSizeAnagrafiche,
                        activePageAnagrafiche, tipoSoggetto, true)
        listaVariazioniAnagrafiche = variazioneAnagrafiche.records
        totalSizeAnagrafiche = variazioneAnagrafiche.totalCount
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.VARIAZIONI_ANAGRAFICHE,
                [:])
        onExportXls(listaVariazioniAnagrafiche, nomeFile)
    }

    @Command
    onPaging() {
        caricaLista()
    }

    private onExportXls(def lista, def titolo) {

        Map fields

        if (lista) {

            fields = [
                    "ni"             : "Numero individuale",
                    "contribuente"   : "Contribuente",
                    "cognome"        : "Cognome",
                    "nome"           : "Nome",
                    "codFiscale"     : "Cod.Fiscale",
                    "dataNascita"    : "Data Nascita",
                    "codContribuente": "Codice Contribuente",
                    "indirizzo"      : "Indirizzo",
                    "comune"         : "Comune",
                    "matricola"      : "Matricola",
                    "dataEvento"     : "Data Evento"
            ]

            if (titolo.equals("Variazioni Anagrafiche")) {
                fields.put("comuneEvento", "Comune Evento")
            }

            def formatters =
                    ["ni"       : Converters.decimalToInteger,
                     "matricola": Converters.decimalToInteger]

            XlsxExporter.exportAndDownload(titolo, lista, fields, formatters)
        }
    }

    @Command
    onVisualizzaSoggetto() {
        def soggetto = (variazioneTabSelezionato == 0) ? selectedVariazioniAnagrafiche : selectedVariazioniResidenze

        def ni = soggetto.ni

        if (!ni) {
            Clients.showNotification("Soggetto non trovato.", Clients.NOTIFICATION_TYPE_INFO, null,
                    "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=SOGGETTO&idSoggetto=${ni}','_blank');")
    }

    @Command
    caricaTab(@BindingParam("id") def tabId) {
        variazioneTabSelezionato = tabId
        esisteCodFamiliare = false
        selectedVariazioniAnagrafiche = null
        selectedVariazioniResidenze = null
        BindUtils.postNotifyChange(null, null, this, "variazioneTabSelezionato")
        BindUtils.postNotifyChange(null, null, this, "esisteCodFamiliare")
        BindUtils.postNotifyChange(null, null, this, "selectedVariazioniAnagrafiche")
        BindUtils.postNotifyChange(null, null, this, "selectedVariazioniResidenze")
    }

    @Command
    onSelezionaTipoEvento(@BindingParam("tipo") long tipo) {
        tipoEvento = tipo

        if (dataResEventoDal != null && dataResEventoAl != null) {
            resetPaginazione()
            caricaLista()
        } else {
            if (dataResEventoDal == null && dataResEventoAl != null) {
                dataResEventoDal = new Date(1000 - 1900, 00, 01)
                resetPaginazione()
                caricaLista()
            }

            if (dataResEventoAl == null && dataResEventoDal != null) {
                dataResEventoAl = new Date(9999 - 1900, 11, 31)
                resetPaginazione()
                caricaLista()
            }
        }
        BindUtils.postNotifyChange(null, null, this, "dataResEventoDal")
        BindUtils.postNotifyChange(null, null, this, "dataResEventoAl")
    }

    @Command
    onSelezionaTipoSoggetto(@BindingParam("tipo") long tipo) {
        if (variazioneTabSelezionato == 0) {
            tipoSoggetto = tipo
        } else {
            tipoSoggettoRes = tipo
        }
        resetPaginazione()
        caricaLista()
    }

    @Command
    onChangeEvento() {
        if (variazioneTabSelezionato == 0) {
            listaVariazioniAnagrafiche = []
            dataAnaEventoDal = null
            dataAnaEventoAl = null
            resetPaginazione()
            BindUtils.postNotifyChange(null, null, this, "listaVariazioniAnagrafiche")
            BindUtils.postNotifyChange(null, null, this, "dataAnaEventoDal")
            BindUtils.postNotifyChange(null, null, this, "dataAnaEventoAl")
        } else {
            listaVariazioniResidenze = []
            dataResEventoDal = null
            dataResEventoAl = null
            resetPaginazione()
            BindUtils.postNotifyChange(null, null, this, "listaVariazioniResidenze")
            BindUtils.postNotifyChange(null, null, this, "dataResEventoDal")
            BindUtils.postNotifyChange(null, null, this, "dataResEventoAl")
        }
    }

    @Command
    def onSelectComune(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event.getData()) {
            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato =
                    event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            filtri.comuneEvento = [comune       : ad4ComuneTr4DTO.ad4Comune.comune,
                                   denominazione: ad4ComuneTr4DTO.ad4Comune.denominazione,
                                   provincia    : ad4ComuneTr4DTO.ad4Comune.provincia.id,
                                   sigla        : ad4ComuneTr4DTO.ad4Comune.provincia.sigla]
        } else {
            filtri.comuneEvento = [comune: "", denominazione: "", provincia: "", sigla: ""]
        }
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    def onChangeComune(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {
        filtri.comuneEvento = [comune: "", denominazione: "", provincia: "", sigla: ""]
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onCheckData() {
        if (variazioneTabSelezionato == 0) {
            if (dataAnaEventoAl && dataAnaEventoDal && dataAnaEventoAl < dataAnaEventoDal) {
                Clients.showNotification("Attenzione. Data inizio maggiore di data fine!!!",
                        Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 3000, true)
                dataAnaEventoDal = null
                dataAnaEventoAl = null
                BindUtils.postNotifyChange(null, null, this, "dataAnaEventoDal")
                BindUtils.postNotifyChange(null, null, this, "dataAnaEventoAl")
            }
        } else {
            if (dataResEventoAl && dataResEventoDal && dataResEventoAl < dataResEventoDal) {
                Clients.showNotification("Attenzione. Data inizio maggiore di data fine!!!",
                        Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 3000, true)
                dataResEventoDal = null
                dataResEventoAl = null
                BindUtils.postNotifyChange(null, null, this, "dataResEventoDal")
                BindUtils.postNotifyChange(null, null, this, "dataResEventoAl")
            }
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onSvuotaFiltri() {
        if (variazioneTabSelezionato == 0) {
            listaVariazioniAnagrafiche = []
            filtri.comuneEvento = [comune: "", denominazione: "", provincia: "", sigla: ""]
            tipoEventoSelezionato = null
            dataAnaEventoDal = null
            dataAnaEventoAl = null
            selectedVariazioniAnagrafiche = null
            BindUtils.postNotifyChange(null, null, this, "selectedVariazioniAnagrafiche")
            BindUtils.postNotifyChange(null, null, this, "listaVariazioniAnagrafiche")
            BindUtils.postNotifyChange(null, null, this, "filtri")
            BindUtils.postNotifyChange(null, null, this, "tipoEventoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "dataAnaEventoDal")
            BindUtils.postNotifyChange(null, null, this, "dataAnaEventoAl")
        } else {
            listaVariazioniResidenze = []
            tipoEvento = 91
            dataResEventoDal = null
            dataResEventoAl = null
            selectedVariazioniResidenze = null
            BindUtils.postNotifyChange(null, null, this, "selectedVariazioniResidenze")
            BindUtils.postNotifyChange(null, null, this, "listaVariazioniResidenze")
            BindUtils.postNotifyChange(null, null, this, "tipoEvento")
            BindUtils.postNotifyChange(null, null, this, "dataResEventoDal")
            BindUtils.postNotifyChange(null, null, this, "dataResEventoAl")
        }

        esisteCodFamiliare = false
        BindUtils.postNotifyChange(null, null, this, "esisteCodFamiliare")
    }

    @Command
    onCerca() {
        caricaLista()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("ni") def ni) {

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onComponentiDellaFamiglia(@BindingParam("tipo") def tipo) {

        def niSoggetto = (tipo == "residenze" ? selectedVariazioniResidenze.ni : selectedVariazioniAnagrafiche.ni)

        if (!niSoggetto) {
            Clients.showNotification("Soggetto non trovato.", Clients.NOTIFICATION_TYPE_INFO, null,
                    "middle_center", 3000, true)
            return
        }

        SoggettoDTO soggetto = Soggetto.findById(niSoggetto).toDTO()

        commonService.creaPopup(
                "/sportello/contribuenti/componentiDellaFamiglia.zul", self, [sogg: soggetto, modificaCognomeNomeCodFiscale: true]
        )
    }

    private resetPaginazione() {
        if (variazioneTabSelezionato == 0) {
            activePageAnagrafiche = 0
            totalSizeAnagrafiche = 0
        } else {
            activePageResidenze = 0
            totalSizeResidenze = 0
        }
    }

    private caricaLista() {
        if (variazioneTabSelezionato == 0) {

            if (!tipoEventoSelezionato) {
                Clients.showNotification("Indicare l'evento", Clients.NOTIFICATION_TYPE_ERROR, self,
                        "before_center", 3000, true)
                return
            }

            if (dataAnaEventoAl && dataAnaEventoDal && dataAnaEventoAl < dataAnaEventoDal) {
                Clients.showNotification("Data inizio maggiore di data fine", Clients.NOTIFICATION_TYPE_ERROR,
                        self, "before_center", 3000, true)
            } else {

                def variazioneAnagrafiche =
                        soggettiService.variazioniAnagrafiche(tipoEventoSelezionato.id, filtri.comuneEvento.comune,
                                filtri.comuneEvento.provincia, dataAnaEventoDal, dataAnaEventoAl, pageSizeAnagrafiche,
                                activePageAnagrafiche, tipoSoggetto, false)
                listaVariazioniAnagrafiche = variazioneAnagrafiche.records
                totalSizeAnagrafiche = variazioneAnagrafiche.totalCount

                if (totalSizeAnagrafiche <= pageSizeAnagrafiche) activePageAnagrafiche = 0
                pagingAnagrafiche.setTotalSize(totalSizeAnagrafiche)

                BindUtils.postNotifyChange(null, null, this, "listaVariazioniAnagrafiche")
                BindUtils.postNotifyChange(null, null, this, "totalSizeAnagrafiche")
                BindUtils.postNotifyChange(null, null, this, "activePageAnagrafiche")
            }
        } else {
            if (dataResEventoAl && dataResEventoDal && dataResEventoAl < dataResEventoDal) {
                Clients.showNotification("Data inizio maggiore di data fine", Clients.NOTIFICATION_TYPE_ERROR,
                        self, "before_center", 3000, true)
            } else {
                def variazioniResidenze = soggettiService.variazioniResidenze(tipoEvento,
                        dataResEventoDal, dataResEventoAl, pageSizeResidenze, activePageResidenze,
                        tipoSoggettoRes, false)
                listaVariazioniResidenze = variazioniResidenze.records
                totalSizeResidenze = variazioniResidenze.totalCount
                if (totalSizeResidenze <= pageSizeResidenze) activePageResidenze = 0
                pagingResidenze.setTotalSize(totalSizeResidenze)

                BindUtils.postNotifyChange(null, null, this, "listaVariazioniResidenze")
                BindUtils.postNotifyChange(null, null, this, "totalSizeResidenze")
                BindUtils.postNotifyChange(null, null, this, "activePageResidenze")
            }
        }

        esisteCodFamiliare = false
        BindUtils.postNotifyChange(null, null, this, "esisteCodFamiliare")

    }

}
