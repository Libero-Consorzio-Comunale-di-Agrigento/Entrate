package sportello.contribuenti

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SituazioneContribuenteRuoliRicercaViewModel {

    Window self
    def filtro
    boolean resetParams = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtroRuoli") def pRuoli) {

        this.self = w
        this.filtro = pRuoli
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
        Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi", resetParams: resetParams])
    }

    @Command
    def onCancellaFiltri() {
        filtro.ruoloDa = null
        filtro.ruoloA = null
        filtro.annoDa = null
        filtro.annoA = null
        BindUtils.postNotifyChange(null, null, this, "filtro")
        resetParams = true
    }

    @Command
    def onCerca() {

        String errorMessage = ""

        if (filtro.ruoloDa != null && filtro.ruoloA != null && (filtro.ruoloA < filtro.ruoloDa)) {
            errorMessage = "Ruolo 'a' non puo' essere inferiore a Roulo 'da'\n"
        }

        if (filtro.annoDa != null && filtro.annoA != null && (filtro.annoA < filtro.annoDa)) {
            errorMessage += "Anno 'a' non puo' essere inferiore a Anno 'da'"
        }

        if (!errorMessage.empty) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            Events.postEvent(Events.ON_ERROR, self, null)
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: filtro])
        }
    }
}
