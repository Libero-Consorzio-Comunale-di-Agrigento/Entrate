import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SimpleMessageboxViewModel {

    Window self

    String icon
    def buttons
    String title
    String message

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam('title') String title,
         @ExecutionArgParam("message") String message) {

        self = w

        this.icon = Messagebox.EXCLAMATION
        this.buttons = [Messagebox.Button.OK]

        this.title = title
        this.message = message
    }

    @Command
    onOk() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
