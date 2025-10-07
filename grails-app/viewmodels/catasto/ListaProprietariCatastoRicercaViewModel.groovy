package catasto

import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaProprietariCatastoRicercaViewModel {
    Window self

    CatastoCensuarioService catastoCensuarioService
    ContribuentiService contribuentiService

    def filtro = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("filtro") def f) {

        this.self = w
        this.filtro = f ?: [:]

        valorizzaDataEfficacia()
    }

    @NotifyChange(["filtro"])
    @Command
    onSvuotaFiltri() {

        def validitaDal = filtro.validitaDal
        def validitaAl = filtro.validitaAl

        filtro = [:]

        filtro.validitaDal = validitaDal
        filtro.validitaAl = validitaAl

    }

    @Command
    onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtro: filtro])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCambiaDataEfficacia() {

        filtro.validitaDal = filtro.validitaDal ?: Date.parse('dd/MM/yyyy', '01/01/1850')
        filtro.validitaAl = filtro.validitaAl ?: Date.parse('dd/MM/yyyy', '31/12/9999')

        def pu = contribuentiService.leggiParametroUtente('CATASTO_DATE_EFF')
        if (pu) {
            pu.valore = filtro.validitaDal.format('dd/MM/yyyy') + " " + filtro.validitaAl.format('dd/MM/yyyy')
            pu.save(failOnError: true, flush: true)
        } else {
            contribuentiService.creaParametroUtente('CATASTO_DATE_EFF',
                    filtro.validitaDal.format('dd/MM/yyyy') + " " + filtro.validitaAl.format('dd/MM/yyyy'),
                    "Indicazione delle date efficacia di riferimento.")
        }
    }

    def valorizzaDataEfficacia() {

        def pu = contribuentiService.leggiParametroUtente('CATASTO_DATE_EFF')
        def dateEfficacia = pu?.valore?.split(" ")
        if (dateEfficacia) {
            filtro.validitaDal = Date.parse('dd/MM/yyyy', dateEfficacia[0])
            filtro.validitaAl = Date.parse('dd/MM/yyyy', dateEfficacia[1])
        } else {
            filtro.validitaDal = Date.parse('dd/MM/yyyy', '01/01/1850')
            filtro.validitaAl = Date.parse('dd/MM/yyyy', '31/12/9999')
        }
    }
}
