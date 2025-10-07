package archivio.dizionari


import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaParametriModelliViewModel {
    Window self

    ModelliService modelliService

    // Tipi modello
    def listaTipiModello = OggettiCache.TIPI_MODELLO.valore.sort { it.descrizione }
    def tipoModelloSelezionato = listaTipiModello[0]

    // Parametri
    def listaParametri = []
    def parametroSelezionato

    // Modelli
    def listaModelli = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        caricaParametri()
    }

    @Command
    def onSelezionaGruppo() {
        caricaParametri()
        listaModelli = []
        parametroSelezionato = []
        BindUtils.postNotifyChange(null, null, this, "listaModelli")
        BindUtils.postNotifyChange(null, null, this, "parametroSelezionato")
    }

    @Command
    def onSelezionaParametro() {
        caricaModelli()
    }

    private void caricaParametri() {
        def filtri = [
                tipoModello: tipoModelloSelezionato.tipoModello]

        listaParametri = modelliService.caricaListaParametri(
                [max: 90000],
                filtri,
                [property: 'descrizione', direction: 'asc']
        ).record

        BindUtils.postNotifyChange(null, null, this, "listaParametri")
    }

    private void caricaModelli() {
        def filtri = [
                tipoModello: tipoModelloSelezionato.tipoModello
        ]

        listaModelli = modelliService.caricaListaModelli(
                [max: 90000],
                filtri,
                [property: 'descrizione', direction: 'asc']
        ).record

        BindUtils.postNotifyChange(null, null, this, "listaModelli")
    }

}
