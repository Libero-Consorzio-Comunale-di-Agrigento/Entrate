package archivio.dizionari

import it.finmatica.tr4.categorieCatasto.CategorieCatastoService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCategorieCatastoViewModel extends TabListaGenericaTributoViewModel {

    // Services
    CategorieCatastoService categorieCatastoService


    // Comuni
    def listaCategorieCatasto
    def categoriaCatastoSelezionato
    def labels

    // Ricerca
    def filtro
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        this.lettura = lettura || tipoTributoSelezionato.tipoTributo == "TASI"

        def filtriNow = [
                categoriaCatasto: filtro?.categoriaCatasto,
                descrizione     : filtro?.descrizione,
                flagReale       : filtro?.flagReale == 'Con' ? true : (filtro?.flagReale == 'Senza' ? false : null),
                eccezione       : filtro?.eccezione
        ]

        this.listaCategorieCatasto = categorieCatastoService.getListaCategorieCatasto(filtriNow)
        this.categoriaCatastoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaCategorieCatasto")
        BindUtils.postNotifyChange(null, null, this, "categoriaCatastoSelezionato")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCategoriaCatasto.zul", self,
                [
                        categoriaCatastoSelezionato: categoriaCatastoSelezionato.dto,
                        tipoOperazione: lettura ? DettaglioCategoriaCatastoViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioCategoriaCatastoViewModel.TipoOperazione.MODIFICA
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        }
                    }
                    onRefresh()
                })

    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCategoriaCatasto.zul", self,
                [
                        categoriaCatastoSelezionato: null,
                        tipoOperazione             : DettaglioCategoriaCatastoViewModel.TipoOperazione.INSERIMENTO
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        }
                    }
                    onRefresh()
                })
    }

    @Command
    def onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCategoriaCatasto.zul", self,
                [
                        categoriaCatastoSelezionato: categoriaCatastoSelezionato.dto,
                        tipoOperazione             : DettaglioCategoriaCatastoViewModel.TipoOperazione.CLONAZIONE
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        }
                    }
                    onRefresh()
                })
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
                        categorieCatastoService.eliminaCategoriaCatasto(categoriaCatastoSelezionato.dto)


                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })

    }

    @Command
    def onExportXls() {

        Map fields = [
                "categoriaCatasto": "Categoria Catasto",
                "descrizione"     : "Descrizione",
                "flagReale"       : "Reale",
                "eccezione"       : "Eccezione"
        ]

        def formatters = ['flagReale': { value -> value ? 'S' : 'N' }]

        def nomeFile = "CategorieCatasto_${tipoTributoSelezionato.tipoTributoAttuale}"

        XlsxExporter.exportAndDownload(nomeFile, listaCategorieCatasto, fields, formatters)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCategorieCatastoRicerca.zul", self, [filtro: filtro], { event ->
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
