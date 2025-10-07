package archivio.dizionari

import it.finmatica.tr4.Sanzione
import it.finmatica.tr4.sanzioni.SanzioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ArchiviaEDuplicaViewModel {

    SanzioniService sanzioniService

    Window self

    def dataChiusura
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("tipoTributo") def tt) {
        this.self = w
        this.tipoTributo = tt
    }

    @Command
    def onOK() {
        if (this.dataChiusura == null) {
            Clients.showNotification("Indicare una data", Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return
        }

        def sanzioni = Sanzione.createCriteria().list {
            ge('codSanzione', 100 as Short)
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('dataFine', Date.parse('dd/MM/yyyy', '31/12/9999'))
        }

        if (sanzioni.any { it.dataInizio > dataChiusura }) {
            String messaggio = "Esistono sanzioni con data di inizio successiva alla \"Data chiusura\" indicata.\n" +
                    "Proseguendo si archivieranno soltanto le sanzioni con data di inizio precedente alla \"Data chiusura\" indicata."

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES == e.getName()) {
                                sanzioniService.archiviaEDuplica(tipoTributo, dataChiusura)
                                Clients.showNotification("Chiusura e duplicazione eseguita con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                                Events.postEvent(Events.ON_CLOSE, self, true)
                            }
                        }
                    }
            )
        } else {
            sanzioniService.archiviaEDuplica(tipoTributo, dataChiusura)
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
