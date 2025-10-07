package pratiche.denunce

import it.finmatica.tr4.denunce.ComponentiConsistenzaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ComponentiConsistenzaRicercaViewModel {

    //Services
    ComponentiConsistenzaService componentiConsistenzaService

    // Componenti
    Window self

    //Comuni
    def filtri

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def f) {

        this.self = w
        this.filtri = f
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [filtriAggiornati: filtri])
    }

    @Command
    def onSvuotaFiltri() {
        filtri = [
                situazioneAl : new Date(),
                componentiDa : null,
                componentiA  : null,
                consistenzaDa: null,
                consistenzaA : null,
                flagAp       : true
        ]
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


}
