package ufficiotributi.supportoservizi

import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.supportoservizi.SupportoServiziService
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SupportoServiziAggiornaAssegnazioneViewModel {

    // services
    def springSecurityService

    CompetenzeService competenzeService
    SupportoServiziService supportoServiziService

    // componenti
    Window self

    /// filtri
    Map parametri = [
            utente: null,
    ]

    /// dizionari
    def listaUtenti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        def elencoUtenti = supportoServiziService.getElencoUtenti()
        listaUtenti = []
        listaUtenti << 'Tutti'
        elencoUtenti.each { listaUtenti << it }
    }

    @Command
    def onOK() {

        if (!validaParametri()) {
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [parametri: parametri])
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    ///
    /// Valida parametri -> True se ok
    ///
    private boolean validaParametri() {

        String message = ""

        if (parametri.utente == null) {
            message += "Utente non specificato\n"
        }

        if (!(message.isEmpty())) {
            message = "Attenzione : \n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return message.isEmpty()
    }
}
