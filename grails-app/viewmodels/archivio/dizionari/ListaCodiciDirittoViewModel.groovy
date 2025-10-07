package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.codiciDiritto.CodiciDirittoService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCodiciDirittoViewModel extends TabListaGenericaTributoViewModel {

    // Services
    CodiciDirittoService codiciDirittoService

    // Comuni
    def listaCodiciDiritto
    def codiceDirittoSelezionato

    // Ricerca
    def filtro
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)
    }

    @Command
    void onRefresh() {

        def filtriNow = [
                codDiritto          : filtro?.codDiritto,
                daOrdinamento       : filtro?.daOrdinamento,
                aOrdinamento        : filtro?.aOrdinamento,
                descrizione         : filtro?.descrizione,
                eccezione           : filtro?.eccezione
        ]

        this.listaCodiciDiritto = codiciDirittoService.getListaCodiciDiritto(filtriNow)
        this.codiceDirittoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaCodiciDiritto")
        BindUtils.postNotifyChange(null, null, this, "codiceDirittoSelezionato")
    }

    @Command
    def onModifica() {
        if (lettura || tipoTributoSelezionato.tipoTributo == 'TASI') {
            return
        }
        commonService.creaPopup("/archivio/dizionari/dettaglioCodiceDiritto.zul", self,
                [
                        codiceDirittoSelezionato: codiceDirittoSelezionato.dto,
                        tipoOperazione          : DettaglioCodiceDirittoViewModel.TipoOperazione.MODIFICA_TRATTAMENTO
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            Clients.showNotification("Modifica avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                    onRefresh()
                })

    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCodiceDiritto.zul", self,
                [
                        codiceDirittoSelezionato: null,
                        tipoOperazione          : DettaglioCodiceDirittoViewModel.TipoOperazione.INSERIMENTO
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            Clients.showNotification("Aggiunta avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                    onRefresh()
                })
    }

    @Command
    def onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCodiceDiritto.zul", self,
                [
                        codiceDirittoSelezionato: codiceDirittoSelezionato.dto,
                        tipoOperazione          : DettaglioCodiceDirittoViewModel.TipoOperazione.CLONAZIONE
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            Clients.showNotification("Duplicazione avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                    onRefresh()
                })
    }

    @Command
    def onElimina() {
        String msg = "Si è scelto di eliminare il codice diritto.\n" +
                "Il codice diritto verrà eliminato e non sarà recuperabile.\n" +
                "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Codice Diritto ", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
            void onEvent(Event evt) throws Exception {
                if (evt.getName().equals("onOK")) {

                    codiciDirittoService.eliminaCodiceDiritto(codiceDirittoSelezionato.dto)

                    Clients.showNotification("Eliminazione avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                onRefresh()
            }
        })

    }

    @Command
    def onExportXls() {

        Map fields = [
                "codDiritto"          : "Codice Diritto",
                "ordinamento"         : "Ordinamento",
                "descrizione"         : "Descrizione",
                "note"                : "Note",
                "eccezione"           : "Trattamento"
        ]

        def formatters = [:]

        def nomeFile = "CodiciDiritto_${tipoTributoSelezionato.tipoTributoAttuale}"

        XlsxExporter.exportAndDownload(nomeFile, listaCodiciDiritto, fields, formatters)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCodiciDirittoRicerca.zul", self, [filtro: filtro], { event ->
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
