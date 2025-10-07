package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheTipoNotificaService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaTipiNotificaViewModel {

    // Componenti
    Window self

    // Services
    CommonService commonService
    CodificheTipoNotificaService codificheTipoNotificaService

    // Modello
    def listaTipiNotifica
    def tipoNotificaSelezionata

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        onRefresh()

    }


    // Eventi interfaccia

    @Command
    def onModifica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioTipiNotifica.zul", self,
                [
                        tipoNotificaSelezionata: tipoNotificaSelezionata,
                        tipoOperazione         : DettaglioTipiNotificaViewModel.TipoOperazione.MODIFICA
                ],
                { event ->
                    Clients.showNotification("Modifica avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                    onRefresh()
                })
    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioTipiNotifica.zul", self,
                [
                        tipoNotificaSelezionata: null,
                        tipoOperazione         : DettaglioTipiNotificaViewModel.TipoOperazione.INSERIMENTO
                ],
                { event ->
                    Clients.showNotification("Aggiunta avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                    onRefresh()
                })
    }


    @Command
    def onElimina() {

        String msg = "Si è scelto di eliminare la seguente codifica:\n" +
                "Tipo Notifica: " + this.tipoNotificaSelezionata.tipoNotifica + "\n" +
                "Descrizione: " + this.tipoNotificaSelezionata.descrizione + ".\n" +
                "La codifica verrà eliminata e non sarà recuperabile.\n" +
                "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Tipo Notifica", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
            void onEvent(Event evt) throws Exception {
                if (evt.getName().equals("onOK")) {
                    def messaggio = codificheTipoNotificaService.eliminaTipoNotifica(tipoNotificaSelezionata)
                    visualizzaRisultatoEliminazione(messaggio)
                    onRefresh()
                }
            }
        })
    }

    @Command
    onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioTipiNotifica.zul", self,
                [
                        tipoNotificaSelezionata: tipoNotificaSelezionata,
                        tipoOperazione         : DettaglioTipiNotificaViewModel.TipoOperazione.CLONAZIONE
                ],
                { event ->
                    Clients.showNotification("Duplicazione avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                    onRefresh()
                })
    }

    @Command
    def onExportXls() {

        Map fields

        if (listaTipiNotifica) {

            fields = [
                    "tipoNotifica": "Tipo Notifica",
                    "descrizione" : "Descrizione"
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CODIFICHE_TIPI_NOTIFICA,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, listaTipiNotifica, fields)
        }
    }

    @Command
    onRefresh() {
        this.listaTipiNotifica = codificheTipoNotificaService.getListaTipiNotifica()
        this.tipoNotificaSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "listaTipiNotifica")
        BindUtils.postNotifyChange(null, null, this, "tipoNotificaSelezionata")
    }


    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo!"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }


}
