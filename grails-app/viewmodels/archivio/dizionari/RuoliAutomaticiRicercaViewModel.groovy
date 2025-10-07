package archivio.dizionari

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.TipoRuolo
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Bandbox
import org.zkoss.zul.Window

class RuoliAutomaticiRicercaViewModel {

    private static final Logger log = Logger.getLogger(RuoliAutomaticiRicercaViewModel.class)

    Window self
    def bdRuoli

    // Modello
    def listaRuoli = []
    def filtri = [:]

    def tipoEmissione = [
            A: "Acconto",
            S: "Saldo",
            T: "Totale",
            X: ''
    ]

    def tipiRuolo = [
            [codice: null, descrizione: ''],
            [codice: TipoRuolo.PRINCIPALE.tipoRuolo, descrizione: 'P - Principale'],
            [codice: TipoRuolo.SUPPLETTIVO.tipoRuolo, descrizione: 'S - Suppletivo']
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def filtri) {

        this.self = w
        this.filtri = filtri ?: [:]

        caricaRuoli()
    }

    @Command
    def onSelezionaRuolo() {
        bdRuoli?.close()
    }

    @Command
    def onApriRuolo(@BindingParam("bd") Bandbox bd) {
        bdRuoli = bd
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

    private caricaRuoli() {
        listaRuoli = Ruolo.findAll {
            invioConsorzio == null &&
                    tipoTributo.tipoTributo == tipoTributo
        }.sort { -it.id }.toDTO()

    }

}
