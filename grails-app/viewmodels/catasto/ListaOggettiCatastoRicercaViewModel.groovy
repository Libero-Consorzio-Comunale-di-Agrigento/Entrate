package catasto

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaOggettiCatastoRicercaViewModel {
    Window self

    CatastoCensuarioService catastoCensuarioService
    ContribuentiService contribuentiService

    String tipoOggetto
    boolean ricercaContribuente
    boolean singoloTipoOggetto

    List<FiltroRicercaOggetto> listaFiltri = []
    FiltroRicercaOggetto filtroRicercaOggetto

    List<CategoriaCatastoDTO> listaCategorieCatasto

    @NotifyChange(["filtroRicercaOggetto"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("filtri") def f
         , @ExecutionArgParam("ricercaContribuente") boolean rc
         , @ExecutionArgParam("singoloTipoOggetto") @Default("true") boolean singoloTipoOggetto) {

        this.self = w
        ricercaContribuente = rc
        this.singoloTipoOggetto = singoloTipoOggetto


        listaFiltri = f ?: []

        // TODO: per ora si gestisce un unico filtro. Da implementare come ricerca oggetti su archivio.
        filtroRicercaOggetto = listaFiltri.empty ? new FiltroRicercaOggetto(id: 0) : listaFiltri[0]

        listaFiltri[0] = filtroRicercaOggetto

        // Si imposta il tipo oggetto: 1 terreno, 3 fabbricato
        if (filtroRicercaOggetto.tipoOggetto) {
            tipoOggetto = catastoCensuarioService.trasformaTipoOggetto(filtroRicercaOggetto.tipoOggetto)
        } else {
            tipoOggetto = "F"
        }

        valorizzaDataEfficacia()

        listaCategorieCatasto = CategoriaCatasto.findAllFlagReale(sort: "categoriaCatasto").toDTO()
    }

    @Command
    onCerca() {
        filtroRicercaOggetto.tipoOggetto = catastoCensuarioService.trasformaTipoOggetto(tipoOggetto)

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: listaFiltri])

    }

    @NotifyChange(["filtroRicercaOggetto"])
    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtroRicercaOggetto.indirizzo = (event.data.denomUff ?: "")
    }

    @NotifyChange(["filtroRicercaOggetto"])
    @Command
    onSvuotaFiltri() {

        def validitaDal = listaFiltri[0]?.validitaDal
        def validitaAl = listaFiltri[0]?.validitaAl

        listaFiltri = []
        filtroRicercaOggetto = new FiltroRicercaOggetto(id: 0)
        listaFiltri[0] = filtroRicercaOggetto

        listaFiltri[0]?.validitaDal = validitaDal
        listaFiltri[0]?.validitaAl = validitaAl

    }

    @NotifyChange(["filtroRicercaOggetto"])
    @Command
    cambioTipoOggetto() {
        filtroRicercaOggetto.categoriaCatasto = null
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCambiaDataEfficacia() {

        filtroRicercaOggetto.validitaDal = filtroRicercaOggetto.validitaDal ?: Date.parse('dd/MM/yyyy', '01/01/1850')
        filtroRicercaOggetto.validitaAl = filtroRicercaOggetto.validitaAl ?: Date.parse('dd/MM/yyyy', '31/12/9999')

        def pu = contribuentiService.leggiParametroUtente('CATASTO_DATE_EFF')

        if (pu) {
            pu.valore = filtroRicercaOggetto.validitaDal.format('dd/MM/yyyy') + " " + filtroRicercaOggetto.validitaAl.format('dd/MM/yyyy')
            pu.save(failOnError: true, flush: true)
        } else {
            contribuentiService.creaParametroUtente('CATASTO_DATE_EFF',
                    filtroRicercaOggetto.validitaDal.format('dd/MM/yyyy') + " " + filtroRicercaOggetto.validitaAl.format('dd/MM/yyyy'),
                    "Indicazione delle date efficacia di riferimento.")
        }
    }

    def valorizzaDataEfficacia() {

        def pu = contribuentiService.leggiParametroUtente('CATASTO_DATE_EFF')
        def dateEfficacia = pu?.valore?.split(" ")
        if (dateEfficacia) {
            filtroRicercaOggetto.validitaDal = Date.parse('dd/MM/yyyy', dateEfficacia[0])
            filtroRicercaOggetto.validitaAl = Date.parse('dd/MM/yyyy', dateEfficacia[1])
        } else {
            filtroRicercaOggetto.validitaDal = Date.parse('dd/MM/yyyy', '01/01/1850')
            filtroRicercaOggetto.validitaAl = Date.parse('dd/MM/yyyy', '31/12/9999')
        }
    }
}
