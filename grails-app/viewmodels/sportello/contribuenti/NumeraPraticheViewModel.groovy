package sportello.contribuenti

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class NumeraPraticheViewModel {
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
    onNumeraPratiche() {
        liquidazioniAccertamentiService.numeraPratiche(
                parametri.tipoTributo,
                parametri.tipoPratica,
                parametri.ni,
                parametri.codFiscale,
                parametri.daAnno,
                parametri.aAnno,
                parametri.daData,
                parametri.aData,
                parametri.cognomeNome
        )

        onChiudi()
    }

    @Command
    onSelectContribuente(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        this.parametri.ni = event.data.id
    }
}
