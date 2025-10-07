package archivio.dizionari

import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class PathModelliViewModel {
    Window self

    ModelliService modelliService

    def path = ""

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        path = modelliService.pathCampiUnione()
    }

    @Command
    def onSelezionaPath() {
        Events.postEvent(Events.ON_CLOSE, self, [path: path])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
