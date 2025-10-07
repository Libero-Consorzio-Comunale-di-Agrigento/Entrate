package elaborazioni

import it.finmatica.tr4.elaborazioni.ElaborazioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class FiltriElaborazioniViewModel {

    // componenti
    Window self

    def springSecurityService

    ElaborazioniService elaborazioniService

    def filtri = [
            utente: null
    ]

    def listaUtenti = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def filtri) {
        this.self = w
        this.filtri = filtri ?: this.filtri
        this.filtri.utente = springSecurityService.currentUser?.id

        listaUtenti = [null] + elaborazioniService.utentiElaborazioni()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [filtri: filtri, filtriAttivi: filtriAttivi()])
    }

    @NotifyChange(["filtri"])
    @Command
    def onSvuotaFiltri() {
        filtri.utente = ''
    }

    private boolean filtriAttivi() {
        return filtri.utente
    }
}
