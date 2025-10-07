package ufficiotributi.bonificaDati.docfa

import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class DocfaNotaViewModel {


    Window self
    def nota
    def titolo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("nota") def nota,
         @ExecutionArgParam("titolo") def titolo) {
        this.self = w
        this.nota = nota
        this.titolo = titolo
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}