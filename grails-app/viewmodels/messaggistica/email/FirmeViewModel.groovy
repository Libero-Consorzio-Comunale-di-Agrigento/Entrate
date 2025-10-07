package messaggistica.email


import it.finmatica.tr4.email.MessaggisticaService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class FirmeViewModel {

    // componenti
    Window self

    // Service
    MessaggisticaService messaggisticaService

    // Model
    def listaFirme

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        caricaFirme()
    }

    private void caricaFirme() {
        listaFirme = messaggisticaService.caricaFirme()
    }

    @Command
    def onSalvaFirma(@BindingParam("firma") def firma) {

        messaggisticaService.inserisciModificaFirma(firma)
        caricaFirme()

        Clients.showNotification("Firma salvata correttamente", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
