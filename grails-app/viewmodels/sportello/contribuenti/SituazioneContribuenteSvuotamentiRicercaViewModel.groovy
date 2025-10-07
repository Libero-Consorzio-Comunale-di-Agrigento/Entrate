package sportello.contribuenti

import it.finmatica.tr4.CodiceRfid
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SituazioneContribuenteSvuotamentiRicercaViewModel {

    Window self
    def filtro
    boolean resetParams = false
    def listaRfid
    def contribuente

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("contribuente") def c,
         @ExecutionArgParam("filtroSvuotamenti") def pSvuotamenti
    ) {

        this.self = w
        this.filtro = pSvuotamenti
        this.contribuente = c

        listaRfid = CodiceRfid.findAllByContribuente(contribuente.toDomain()).sort { it.oggetto.id }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
        Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi", resetParams: resetParams])
    }

    @Command
    def onCancellaFiltri() {
        filtro.rfid = null
        filtro.dataSvuotamentoDa = null
        filtro.dataSvuotamentoA = null

        resetParams = true

        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Command
    def onCerca() {

        String errorMessage = ""

        if (filtro.dataSvuotamentoDa != null && filtro.dataSvuotamentoA != null && (filtro.dataSvuotamentoA < filtro.dataSvuotamentoDa)) {
            errorMessage = "Data a non puo' essere inferiore a Data da\n"
        }

        if (!errorMessage.empty) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            Events.postEvent(Events.ON_ERROR, self, null)
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: filtro])
        }
    }
}
