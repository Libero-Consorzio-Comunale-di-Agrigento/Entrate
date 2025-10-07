package archivio.dizionari

import it.finmatica.tr4.relazioniCalcolo.RelazioniCalcoloService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ListaRelazioniCalcoloRicercaViewModel {

    // Services
    RelazioniCalcoloService relazioniCalcoloService

    // Componenti
    Window self

    // Comuni
    def filtri
    def tipoTributo
    def anno

    def listaTipiOggetto
    def listaCategorieCatasto
    def listaTipiAliquota

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def pr,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("anno") def an) {

        this.self = w
        this.tipoTributo = tt
        this.anno = an

        this.filtri = pr ?: [:]

        this.listaTipiOggetto = [null] + relazioniCalcoloService.getListaTipiOggetto(tipoTributo)
        this.listaCategorieCatasto = [null] + relazioniCalcoloService.getListaCategoriaCatasto(anno)
        this.listaTipiAliquota = [null] + relazioniCalcoloService.getListaTipiAliquota(tipoTributo, anno)
    }

    @Command
    onCerca() {

        def errori = controllaFiltri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, [filtri: filtri])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCancellaFiltri() {

        this.filtri = [
                daTipoOggetto : null,
                aTipoOggetto  : null,
                daCatCatasto  : null,
                aCatCatasto   : null,
                daTipoAliquota: null,
                aTipoAliquota : null,
        ]

        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


    def controllaFiltri() {

        def errori = []

        if (filtri.daTipoOggetto != null && filtri.aTipoOggetto != null && filtri.daTipoOggetto.tipoOggetto > filtri.aTipoOggetto.tipoOggetto) {
            errori << "Tipo Oggetto Da deve essere minore di A"
        }

        if (filtri.daTipoAliquota != null && filtri.aTipoAliquota != null && filtri.daTipoAliquota.tipoAliquota > filtri.aTipoAliquota.tipoAliquota) {
            errori << "Tipo Aliquota Da deve essere minore di A"
        }

        return errori
    }


}
