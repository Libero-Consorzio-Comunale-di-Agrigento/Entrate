package sportello.contribuenti

import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.StatoContribuenteService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SituazioneContribuenteStatiViewModel {

    Window self

    def pagination = [
            max       : 15,
            offset    : 0,
            activePage: 0
    ]

    def deleteEnable = false
    def editEnable = false
    def cloneEnable = false
    def exportXlsxEnable = false
    def addEnable = false

    CommonService commonService
    StatoContribuenteService statoContribuenteService
    CompetenzeService competenzeService

    def contribuente
    def tipiTributo
    def selectedItem
    def itemsList = []

    @Init
    void init(@ContextParam(ContextType.COMPONENT) Window window,
              @ExecutionArgParam("contribuente") def contribuente,
              @ExecutionArgParam("tipiTributo") def tipiTributo) {

        self = window

        this.contribuente = contribuente
        this.tipiTributo = tipiTributo
    }

    @Command
    void onRefresh() {

        resetPaginazione()
        resetSelectedItem()

        fetchItems()
        exportXlsxEnable = !itemsList.empty

        BindUtils.postGlobalCommand(null, null, "refreshLastStatiDescriptions", null)
        BindUtils.postNotifyChange(null, null, this, 'exportXlsxEnable')
    }

    @Command
    void onPaging() {
        resetSelectedItem()

        fetchItems()
    }

    private void fetchItems() {
        def result =
                statoContribuenteService.findStatiContribuente(
                        [codFiscale: contribuente.codFiscale, tipiTributo: tipiTributo],
                        pagination)

        itemsList = result.list
        pagination.totalSize = result.totalSize

        BindUtils.postNotifyChange(null, null, this, 'pagination')
        BindUtils.postNotifyChange(null, null, this, 'itemsList')
    }

    private void resetSelectedItem() {
        selectedItem = null
        aggiornaCompetenze()

        BindUtils.postNotifyChange(null, null, this, 'selectedItem')
    }

    void setTipiTributo(List<String> tipiTributo) {
        this.tipiTributo = tipiTributo
    }

    @Command
    void onAdd() {
        def creationParam = [
                action     : StatoContribuenteViewModel.OpenMode.CREATE,
                codFiscale : contribuente.codFiscale,
                tipiTributo: tipiTributo
        ]
        commonService.creaPopup(
                "/sportello/contribuenti/statoContribuente.zul",
                self,
                creationParam,
                { event ->
                    if (event.data) {
                        onRefresh()
                    }
                }
        )
    }

    @Command
    void onClone() {
        def newStatoContribuente = commonService.clona(selectedItem)
        newStatoContribuente.id = null

        def creationParam = [
                action           : StatoContribuenteViewModel.OpenMode.UPDATE,
                statoContribuente: newStatoContribuente,
                tipiTributo      : tipiTributo]
        commonService.creaPopup(
                "/sportello/contribuenti/statoContribuente.zul",
                self,
                creationParam,
                { event ->
                    if (event.data) {
                        onRefresh()
                    }
                }
        )
    }

    @Command
    void onOpen() {

        def mode = competenzeService.tipoAbilitazioneUtente(selectedItem.tipoTributo.tipoTributo) == 'A' ?
                StatoContribuenteViewModel.OpenMode.UPDATE : StatoContribuenteViewModel.OpenMode.READ

        def updatingParam = [
                action           : mode,
                statoContribuente: selectedItem,
                tipiTributo      : tipiTributo.findAll {
                    competenzeService
                            .tipoAbilitazioneUtente(it) == 'A'
                }
        ]

        commonService.creaPopup(
                "/sportello/contribuenti/statoContribuente.zul",
                self,
                updatingParam,
                { event ->
                    if (event.data) {
                        onRefresh()
                    }
                }
        )
    }

    @Command
    void onDelete() {
        String message = "Eliminare Stato Contribuente?"
        Messagebox.show(message,
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {

                            statoContribuenteService.deleteStatoContribuente(selectedItem)

                            if (Soggetto.get(contribuente.soggetto.id).refresh().contribuente == null) {
                                Messagebox.show("Il contribuente è stato eliminato.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION, new EventListener() {
                                    void onEvent(Event evnt) throws Exception {
                                        BindUtils.postGlobalCommand(null, null, "closeCurrentAndRefreshListaContribuente", null)
                                    }
                                })
                            } else {

                                onRefresh()
                            }
                        }
                    }
                }
        )
    }

    @Command
    void onExportToXls() {
        def totalList = statoContribuenteService.findStatiContribuente(
                [codFiscale : contribuente.codFiscale,
                 tipiTributo: tipiTributo]
        ).list
        def fields = [
                "tipoTributo.tipoTributoAttuale": "Tributo",
                "stato.descrizione"             : "Stato",
                "dataStato"                     : "Data",
                "anno"                          : "Anno",
                "note"                          : "Note",
                "utente"                        : "Utente Modifica",
                "lastUpdated"                   : "Data Modifica"
        ]

        XlsxExporter.exportAndDownload("Stati_$contribuente.codFiscale", totalList, fields, [:])
    }

    @Command
    void onSelect() {
        aggiornaCompetenze()
    }

    void aggiornaCompetenze() {
        def lettura = selectedItem ? competenzeService.tipoAbilitazioneUtente(selectedItem?.tipoTributo?.tipoTributo) != 'A' : false

        deleteEnable = selectedItem != null && !lettura

        editEnable = selectedItem != null && statoContribuenteService.existsAnyTipoStatoContribuente() && !lettura
        cloneEnable = selectedItem != null && !lettura

        exportXlsxEnable = !itemsList.empty

        addEnable = !tipiTributo.findAll {
            competenzeService
                    .tipoAbilitazioneUtente(it) == 'A'
        }.empty && statoContribuenteService.existsAnyTipoStatoContribuente()

        BindUtils.postNotifyChange(null, null, this, 'editEnable')
        BindUtils.postNotifyChange(null, null, this, 'cloneEnable')
        BindUtils.postNotifyChange(null, null, this, 'deleteEnable')
        BindUtils.postNotifyChange(null, null, this, 'exportXlsxEnable')
        BindUtils.postNotifyChange(null, null, this, 'addEnable')

    }

    private void resetPaginazione() {
        // reset della paginazione
        pagination.offset = 0
        pagination.activePage = 0
    }
}
