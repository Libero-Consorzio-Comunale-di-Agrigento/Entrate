package ufficiotributi.datiesterni

import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.ufficiotributi.datiesterni.FiltroRicercaImportDati
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ImportDatiRicercaViewModel {

    // componenti
    Window self

    def titolo

    def listaTitoliDocumento = TitoloDocumento.list().findAll { it.nomeBean && it.nomeMetodo }.toDTO().sort { it.descrizione }

    def selectedStato

    FiltroRicercaImportDati filtro

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") FiltroRicercaImportDati filtro) {
        this.self = w
        this.filtro = filtro ? filtro : new FiltroRicercaImportDati()

        this.titolo = "Ricerca avanzata Documenti"

        this.selectedStato = String.valueOf(this.filtro.stato)
    }

    @Command
    onCerca() {
        def errors = filtro.validate()
        if (!errors.isEmpty()) {
            Clients.showNotification(errors, Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [filtro: filtro])
    }

    @Command
    svuotaFiltri() {

        filtro = new FiltroRicercaImportDati()
        selectedStato = String.valueOf(filtro.stato)

        BindUtils.postNotifyChange(null, null, this, "filtro")
        BindUtils.postNotifyChange(null, null, this, "selectedStato")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCheckStato() {

        filtro.stato = Short.parseShort(selectedStato)

        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

}
