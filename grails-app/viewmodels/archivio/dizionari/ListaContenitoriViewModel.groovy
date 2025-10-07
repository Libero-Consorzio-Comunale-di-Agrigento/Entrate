package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.contenitori.ContenitoriService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaContenitoriViewModel extends TabListaGenericaTributoViewModel {

    CommonService commonService
    ContenitoriService contenitoriService

    def selectedItem
    def list
    def filtro = [:]
    def filtroAttivo = false
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        this.labels = commonService.getLabelsProperties('dizionario')

        onRefresh()
    }

    @Command
    void onRefresh() {
        selectedItem = null
        BindUtils.postNotifyChange(null, null, this, "selectedItem")
        fetchList()
    }

    private void fetchList() {
        def filter = [*: filtro, tipoTributo: tipoTributoSelezionato]
        list = contenitoriService.getListaContenitori(filter)
        BindUtils.postNotifyChange(null, null, this, "list")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioContenitore.zul", self,
                [contenitore   : selectedItem,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: lettura ? DettaglioContenitoreViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioContenitoreViewModel.TipoOperazione.MODIFICA],
                { onRefresh() })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioContenitore.zul", self,
                [contenitore   : null,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: DettaglioContenitoreViewModel.TipoOperazione.INSERIMENTO],
                { onRefresh() })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioContenitore.zul", self,
                [contenitore   : selectedItem,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: DettaglioContenitoreViewModel.TipoOperazione.CLONAZIONE],
                { onRefresh() })
    }

    @Command
    def onElimina() {
        Messagebox.show("Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.OK | Messagebox.CANCEL,
                Messagebox.EXCLAMATION,
                { event ->
                    if (event.getName() == "onOK") {
                        contenitoriService.eliminaContenitore(selectedItem.toDomain())

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        Map fields = [id                : 'Codice',
                      descrizione       : 'Descrizione',
                      unitaDiMisura     : 'Unità di Misura',
                      capienza          : 'Capienza'
        ]

        XlsxExporter.exportAndDownload("Contenitori_${tipoTributoSelezionato.tipoTributoAttuale}", list, fields)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaContenitoriRicerca.zul",
                self,
                [filtro: filtro],
                { event ->
                    if (event.data) {
                        this.filtro = event.data.filtro
                        BindUtils.postNotifyChange(null, null, this, "filtro")

                        this.filtroAttivo = event.data.isFiltroAttivo
                        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                        onRefresh()
                    }
                })
    }
}
