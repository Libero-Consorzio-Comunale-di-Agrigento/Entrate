package archivio.dizionari

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class RicercaStradarioViewModel {

    // Componenti
    Window self

    // Services


    // Comuni
    def tipo
    def filtriRicerca = [:]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipo") def tp,
         @ExecutionArgParam("filtri") def fltr) {

        this.self = w
        this.tipo = tp

        initFiltri(fltr)
    }


    @Command
    def onCerca() {

        def errori = controllaFiltri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING,
                    null, "middle_center", 3000, true)
            return
        }

        def filtroAttivo = controllaFiltroAttivo()

        Events.postEvent(Events.ON_CLOSE, self, [ricarica: true, filtri: filtriRicerca, filtroAttivo: filtroAttivo])
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [ricarica: false])
    }

    @Command
    def onCancellaFiltri() {

        if (tipo == "vie") {

            filtriRicerca = [
                    codiceDa: null,
                    codiceA : null,
                    denomUff: null,
                    denomOrd: null
            ]

        } else if (tipo == "denominazioni") {
            filtriRicerca = [
                    daProgrVia: null,
                    aProgrVia : null,
                    descNominativo: null
            ]
        }

        BindUtils.postNotifyChange(null, null, this, "filtriRicerca")
    }

    private def controllaFiltri() {

        def errori = []

        if (tipo == "vie") {

            if (filtriRicerca.codiceDa != null && filtriRicerca.codiceA != null && filtriRicerca.codiceDa > filtriRicerca.codiceA) {
                errori << "Il Codice Da deve essere minore di Codice A\n"
            }

            if (filtriRicerca.codiceDa != null && filtriRicerca.codiceDa < 0) {
                errori << "Il Codice Da deve essere positivo\n"
            }

            if (filtriRicerca.codiceA != null && filtriRicerca.codiceA < 0) {
                errori << "Il Codice A deve essere positivo\n"
            }

        } else if (tipo == "denominazioni") {
            if (filtriRicerca.daProgrVia != null && filtriRicerca.daProgrVia < 0) {
                errori << "Il Progressivo Via Da deve essere positivo\n"
            }
            if (filtriRicerca.aProgrVia != null && filtriRicerca.aProgrVia < 0) {
                errori << "Il Progressivo Via A deve essere positivo\n"
            }
        }

        return errori
    }

    private def controllaFiltroAttivo() {

        if (tipo == "vie") {

            return (filtriRicerca.codiceDa != null) || (filtriRicerca.codiceA != null) ||
                    (filtriRicerca.denomUff != null) || (filtriRicerca.denomOrd6 != null)

        } else if (tipo == "denominazioni") {
            return (filtriRicerca.daProgrVia != null) ||
                    filtriRicerca.aProgrVia != null ||
                    (filtriRicerca.descNominativo != null)
        }

    }

    private def initFiltri(def filtri) {

        if (filtri == null) {

            filtriRicerca = [
                    codiceDa: null,
                    codiceA : null,
                    denomUff: null,
                    denomOrd: null
            ]

        } else {
            filtriRicerca = filtri
        }
    }

}
