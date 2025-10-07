package it.finmatica.zkutils

import grails.util.Holders
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients

class CodiceFiscaleLabelWithButton extends LabelWithButton {

    private idSoggetto

    CodiceFiscaleLabelWithButton() {
        super()
        this.image = '/images/afc/16x16/user.png'
    }

    def setIdSoggetto(String idSoggetto) {
        this.idSoggetto = idSoggetto
    }

    // onCreate is fired before data is send to the client,
    // but after the Component and all it children exists.
    @Override
    def onCreate() {
        super.onCreate()

        if (idSoggetto) {
            image.addEventListener(Events.ON_CLICK, new org.zkoss.zk.ui.event.EventListener() {
                void onEvent(Event event) {
                    Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${idSoggetto}','_blank');")
                }
            })
        }

        image.visible = idSoggetto ? true : showButtonIfEmpty
    }
}
