package archivio.dizionari


import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class GestioneParametriViewModel {
    Window self

    ModelliService modelliService
    def parametro
    def oldParametro
    def nuovaPersonalizzazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parametro") def parametro,
         @ExecutionArgParam("modello") def modello) {
        this.self = w
        this.parametro = parametro
        this.oldParametro = parametro.dettaglio.testo
        this.nuovaPersonalizzazione = parametro.dettaglio.parametroId == null

        if (nuovaPersonalizzazione) {
            this.parametro.dettaglio.parametroId = parametro.id
            this.parametro.dettaglio.modello = modello.id
            this.parametro.dettaglio.testo = ''
        }
    }

    @Command
    onChiudi() {

        if (oldParametro != parametro.dettaglio.testo) {
            String messaggio = "Le modifiche apportate verranno perse. Continuare?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        public void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                if (nuovaPersonalizzazione) {
                                    this.parametro.dettaglio.parametroId = null
                                    this.parametro.dettaglio.modello = null
                                    this.parametro.dettaglio.testo = null
                                }
                                Events.postEvent(Events.ON_CLOSE, self, null)
                            }
                        }
                    }
            )
        } else {
            Events.postEvent(Events.ON_CLOSE, self, null)
        }
    }

    @Command
    def onSalvaParametro() {
        parametro.dettaglio.toDomain().save(flush: true, failOnError: true)

        Events.postEvent(Events.ON_CLOSE, self, [parametro: parametro.dettaglio])
    }

}
