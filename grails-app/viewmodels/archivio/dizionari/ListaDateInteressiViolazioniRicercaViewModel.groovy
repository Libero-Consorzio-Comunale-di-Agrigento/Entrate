package archivio.dizionari

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.TipoRuolo
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Bandbox
import org.zkoss.zul.Window

class ListaDateInteressiViolazioniRicercaViewModel {

    private static final Logger log = Logger.getLogger(ListaDateInteressiViolazioniRicercaViewModel.class)

    Window self

    // Modello
    def filtri = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def filtri) {

        this.self = w

        this.filtri = filtri ?: [:]
    }

    @Command
    def onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [filtri: filtri])
    }

    @Command
    def onSvuotaFiltri() {
        filtri.entrySet().each { it.value = null }

        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
