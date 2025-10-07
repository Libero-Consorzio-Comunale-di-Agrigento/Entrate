package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.speseNotifica.SpeseNotificaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaSpeseNotificaViewModel extends TabListaGenericaTributoViewModel {

    CommonService commonService
    SpeseNotificaService speseNotificaService

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
        list = speseNotificaService.getListaSpeseNotifica(filter)
        BindUtils.postNotifyChange(null, null, this, "list")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpesaNotifica.zul", self,
                [spesaNotifica : selectedItem,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: lettura ? DettaglioSpesaNotificaViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioSpesaNotificaViewModel.TipoOperazione.MODIFICA],
                { onRefresh() })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpesaNotifica.zul", self,
                [spesaNotifica : null,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: DettaglioSpesaNotificaViewModel.TipoOperazione.INSERIMENTO],
                { onRefresh() })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpesaNotifica.zul", self,
                [spesaNotifica : selectedItem,
                 tipoTributo   : tipoTributoSelezionato,
                 tipoOperazione: DettaglioSpesaNotificaViewModel.TipoOperazione.CLONAZIONE],
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
                        speseNotificaService.eliminaSpesaNotifica(selectedItem.toDomain())

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        Map fields = [descrizione               : 'Descrizione',
                      descrizioneBreve          : 'Descrizione Breve',
                      importo                   : 'Importo',
                      'tipoNotifica.descrizione': 'Tipo Notifica']

        XlsxExporter.exportAndDownload("SpeseNotifica_${tipoTributoSelezionato.tipoTributoAttuale}", list, fields)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaSpeseNotificaRicerca.zul",
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
