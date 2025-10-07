package ufficiotributi.imposte


import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListeDiCaricoRuoliOrdinamentoViewModel {

    // Componenti
    Window self

    /*
     Alfabetico - A
     Codice Fiscale - CF
     Codice Contribuente - CC
     Indirizzo - I
     ---
     Deceduti e Non Deceduti - DND
     Non Deceduti - ND
     Deceduti - D
    */
    def ordinamento = "A"
    def filtro = "DND"


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
    }

    @Command
    onStampa() {
       Events.postEvent(Events.ON_CLOSE, self, [ordinamento: ordinamento, filtro: filtro])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
