package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tipoUtilizzo.TipiUtilizzoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaUtilizziViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    TipiUtilizzoService tipiUtilizzoService

    // Componenti
    Window self

    // Comuni
    def tipoUtilizzoTributoSelezionato
    def listaTipiUtilizzoTributo
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {
        super.init(w, tipoTributo, null, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        tipoUtilizzoTributoSelezionato = null
        listaTipiUtilizzoTributo = tipiUtilizzoService.getListaUtilizzoTributo([
                tipoTributo: tipoTributoSelezionato.tipoTributo,
                daId       : filtro?.daUtilizzo,
                aId        : filtro?.aUtilizzo,
                descrizione: filtro?.descrizione
        ])
        BindUtils.postNotifyChange(null, null, this, "tipoUtilizzoTributoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaTipiUtilizzoTributo")
    }

    @Command
    def onAggiungiUtilizzoTributo() {
        commonService.creaPopup("/archivio/dizionari/dettaglioUtilizzo.zul", self,
                [tipoTributoSelezionato        : tipoTributoSelezionato,
                 listaTipiUtilizzoTributo      : listaTipiUtilizzoTributo.id,
                 tipoUtilizzoTributoSelezionato: null,

                ], { event -> onRefresh() })

    }

    @Command
    def onEliminaUtilizzoTributo() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        tipiUtilizzoService.deleteUtilizzoTributo([
                                tipoTributo : tipoTributoSelezionato.tipoTributo,
                                tipoUtilizzo: tipoUtilizzoTributoSelezionato.tipoUtilizzo.id
                        ])

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXlsUtilizzo() {
        Map fields = ["tipoUtilizzo.id"         : "Utilizzo",
                      "tipoUtilizzo.descrizione": "Descrizione"]

        def formatters = ["tipoUtilizzo.id": Converters.decimalToInteger]
        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.UTILIZZI,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])
        XlsxExporter.exportAndDownload(nomeFile, listaTipiUtilizzoTributo, fields, formatters)

    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaUtilizziRicerca.zul", self, [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }
}
