package sportello.contribuenti

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DataNotificaViewModel {
    Window self

    LiquidazioniAccertamentiService liquidazioniAccertamentiService

    def parametri = [:]

    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("tipoPratica") String tp) {
        this.self = w

        this.parametri.tipoTributo = tt
        this.parametri.tipoPratica = tp
        this.parametri.cognomeNome = ""

        this.tipoTributo = TipoTributo.findByTipoTributo(tt)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onDataNotifica() {
        if (!parametri.dataNotifica) {
            Clients.showNotification("Il campo Data Notifica non può essere NULLO.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }
        def modifiche = liquidazioniAccertamentiService.dataNotifica(
                parametri.tipoTributo,
                parametri.tipoPratica,
                parametri.ni,
                parametri.codFiscale,
                parametri.daAnno,
                parametri.aAnno,
                parametri.daData,
                parametri.aData,
                parametri.daNumero,
                parametri.aNumero,
                parametri.dataNotifica,
                parametri.cognomeNome
        )

        Clients.showNotification("Aggiornato il campo Data Notifica per ${modifiche} pratiche.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)

        onChiudi()
    }

    @Command
    onSelectContribuente(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        this.parametri.ni = event.data.id
    }
}
