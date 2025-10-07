package ufficiotributi.bonificaDati.versamenti

import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class VersamentoDettaglioPopupViewModel {

    Window self
    def versamentoSelezionato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("versamento") def versamento) {
        this.self = w
        this.versamentoSelezionato = versamento
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}