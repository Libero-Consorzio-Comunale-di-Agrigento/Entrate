package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.OggettoTributoDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.oggettiTributo.OggettiTributoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaOggettoTributoViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    OggettiTributoService oggettiTributoService

    // Componenti
    Window self
    def labels

    // Modello
    OggettoTributoDTO oggettoTributoSelezionato
    Collection<OggettoTributoDTO> listaOggettoTributo = []

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')

    }

    // Eventi interfaccia
    @Command
    void onRefresh() {
        oggettoTributoSelezionato = null

        listaOggettoTributo = oggettiTributoService.getByCriteria([
                tipoTributo: tipoTributoSelezionato.tipoTributo,
                da         : filtro?.da,
                a          : filtro?.a,
                descrizione: filtro?.descrizione,
        ])

        BindUtils.postNotifyChange(null, null, this, "oggettoTributoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaOggettoTributo")
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioOggettoTributo.zul", self,
                [
                        tipoTributo                 : tipoTributoSelezionato,
                        oggettiTributoPerTipoTributo: listaOggettoTributo,
                ], { event -> onRefresh() })
    }

    @Command
    def onElimina() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        oggettiTributoService.elimina(oggettoTributoSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {
        if (listaOggettoTributo) {
            Map fields = [
                    "tipoOggetto.tipoOggetto": "Tipo Oggetto",
                    "tipoOggetto.descrizione": "Descrizione",
            ]

            XlsxExporter.exportAndDownload("Oggetti_${tipoTributoSelezionato.tipoTributoAttuale}", listaOggettoTributo, fields)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaOggettoTributoRicerca.zul", self,
                [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }


    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
