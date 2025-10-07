package it.finmatica.zkutils

import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox

class NoteLabelWithButton extends LabelWithButton {

    NoteLabelWithButton() {
        super()

        this.image = '/images/afc/16x16/info.png'
        this.dialogTitle = 'Note'
    }

    def onCreate() {
        super.onCreate()
        image.addEventListener(Events.ON_CLICK, new org.zkoss.zk.ui.event.EventListener() {
            void onEvent(Event event) {
                Messagebox.show(super.value, super.dialogTitle, Messagebox.OK, Messagebox.INFORMATION)
            }
        })
    }
}
