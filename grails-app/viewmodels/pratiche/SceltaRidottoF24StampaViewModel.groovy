package pratiche


import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class SceltaRidottoF24StampaViewModel {

    // Services


    // Componenti
    Window self

    // Dati
    def ridotto = "SI"


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onStampa() {
        Events.postEvent(Events.ON_CLOSE, self, [ridotto: ridotto])
    }


}
