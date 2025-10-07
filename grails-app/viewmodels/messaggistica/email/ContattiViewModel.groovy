package messaggistica.email

import it.finmatica.tr4.email.MessaggisticaService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ContattiViewModel {

    // componenti
    Window self

    // Service
    MessaggisticaService messaggisticaService

    // Model
    def listaContatti
    def indirizzoSelezionato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaContatti = messaggisticaService.caricaIndirizziMittente()
    }

    @Command
    def onSalvaIndirizzo(@BindingParam("ind") def indirizzoModificato) {

        if (messaggisticaService.LABEL_NON_DEFINITO != indirizzoModificato.indirizzo && !messaggisticaService.validaIndirizzo(indirizzoModificato.indirizzo)) {
            Clients.showNotification("Indirizzo email non valido", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return
        }

        messaggisticaService.inserisciModificaIndirizzo(indirizzoModificato)
        Clients.showNotification("Indirizzo salvato correttamente", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}