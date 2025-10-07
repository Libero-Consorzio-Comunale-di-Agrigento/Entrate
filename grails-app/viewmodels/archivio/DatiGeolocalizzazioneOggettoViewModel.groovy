package archivio

import it.finmatica.tr4.oggetti.OggettiService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DatiGeolocalizzazioneOggettoViewModel {

    // Componenti
    Window self

    // Services
    OggettiService oggettiService

    // Comuni
    String geolocalizzazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {

        this.self = w

        this.geolocalizzazione = ''
    }

    // Eventi interfaccia
    @Command
    def onAcquisisci() {

        def report = oggettiService.parseCoordinates(geolocalizzazione)

        visualizzaReport(report, 'Geolocalizzazione acquisita con successo!')

        if(report.result == 0) {
            Events.postEvent(Events.ON_CLOSE, self, [ "geolocalizzazione" : report ])
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }
    }
}
