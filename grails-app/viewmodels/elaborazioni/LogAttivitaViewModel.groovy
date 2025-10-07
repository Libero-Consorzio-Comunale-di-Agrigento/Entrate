package elaborazioni

import it.finmatica.tr4.elaborazioni.ElaborazioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class LogAttivitaViewModel {

    // componenti
    Window self

    ElaborazioniService elaborazioniService

    def idAttivita
    def logAttivita = ""

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idAttivita") def idAttivita) {
        this.self = w

        this.idAttivita = idAttivita

        this.logAttivita = elaborazioniService.logAttivita(idAttivita)
    }

    @Command
    def onAggiornaLogAttivita() {
        this.logAttivita = elaborazioniService.logAttivita(idAttivita)
        BindUtils.postNotifyChange(null, null, this, "logAttivita")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
