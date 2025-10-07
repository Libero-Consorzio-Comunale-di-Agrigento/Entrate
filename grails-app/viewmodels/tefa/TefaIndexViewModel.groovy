package tefa

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Window

class TefaIndexViewModel {
    Window self

    // stato
    String selectedSezione
    String urlSezione

    def pagine = [
            fornitureAE  : "/ufficiotributi/datiesterni/fornitureAE.zul",
            importDati   : "/ufficiotributi/datiesterni/importDati.zul",
            datiContabili: "/archivio/dizionari/listaDatiContabili.zul",
    ]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        String elemento = Sessions.getCurrent().getAttribute("elemento")
        Sessions.getCurrent().removeAttribute("elemento")
        setSelectedSezione(elemento)
    }

    List<String> getPatterns() {
        return pagine.collect { it.key }
    }

    void handleBookmarkChange(String bookmark) {
        setSelectedSezione(bookmark)
    }

    void setSelectedSezione(String value) {
        if (value == null || value.length() == 0) {
            urlSezione = null
        }

        selectedSezione = value
        urlSezione = pagine[selectedSezione]

        BindUtils.postNotifyChange(null, null, this, "urlSezione")
    }
}
