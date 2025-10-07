package archivio.dizionari

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

abstract class RicercaViewModel {
    Window self

    String titolo
    def filtro

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {

        this.self = w

        this.filtro = filtro ?: getFiltroIniziale()

        this.titolo = "Ricerca avanzata"
    }

    @Command
    onCerca() {
        def errors = this.getErroriFiltro()

        if (!errors.isEmpty()) {
            Clients.showNotification(errors, Clients.NOTIFICATION_TYPE_WARNING, null, "top_center", 5000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [filtro        : filtro,
                                                 isFiltroAttivo: isFiltroAttivo()])
    }

    @Command
    svuotaFiltri() {

        this.filtro = getFiltroIniziale()

        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    fromRadioToBool(@BindingParam("radioObject") def radioObject, @BindingParam("flagObject") def flagObject) {

        if (this.filtro."${radioObject}" == "Con") {
            this.filtro."${flagObject}" = true
        } else if (this.filtro."${radioObject}" == "Senza") {
            this.filtro."${flagObject}" = false
        } else {
            this.filtro."${flagObject}" = null
        }
    }

    abstract String getErroriFiltro()

    abstract boolean isFiltroAttivo()

    def getFiltroIniziale() {}

    static String validaEstremi(def da, def a, def label) {
        if (da != null && a != null && da > a) {
            return "Valori di $label non coerenti.\n"
        }

        return ""
    }
}
