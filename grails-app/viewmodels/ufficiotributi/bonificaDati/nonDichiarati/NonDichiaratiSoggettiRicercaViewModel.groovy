package ufficiotributi.bonificaDati.nonDichiarati

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class NonDichiaratiSoggettiRicercaViewModel {

    Window self

    def tipoSoggetto = [null] +
            [codice: -1, descrizione: 'Tutti'] +
            [codice: 0, descrizione: 'Solo non contribuenti'] +
            [codice: 1, descrizione: 'Solo contribuenti']

    // filtri
    def filtri = [
            cognome     : "",
            nome        : "",
            codFiscale  : "",
            idSoggetto  : null,
            tipoSoggetto: null,
            tipoImmobile: "E"   // "F", "T" oppure 'E'
    ]
    def tipoSoggettoSelected = null

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("filtri") def f) {

        this.self = w

        filtri = f ?: filtri

        tipoSoggettoSelected = tipoSoggetto.find {
            (it != null) && (it.codice == filtri.tipoSoggetto)
        }
    }

    @Command
    onSvuotaFiltri() {

        filtri.cognome = ""
        filtri.nome = ""
        filtri.codFiscale = ""
        filtri.idSoggetto = null
        filtri.tipoSoggetto = null
        filtri.tipoImmobile = "E"

        tipoSoggettoSelected = null

        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "tipoSoggettoSelected")
    }

    @Command
    onCerca() {

        filtri.tipoSoggetto = (tipoSoggettoSelected != null) ? tipoSoggettoSelected.codice : -1

        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: filtri])
    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
