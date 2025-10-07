package portale

import it.finmatica.tr4.portale.IntegrazionePortaleService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Checkbox
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ElencoPratichePortaleViewModel {

    @Wire('#chkSelectAll')
    Checkbox chkSelectAll

    Window self
    IntegrazionePortaleService integrazionePortaleService

    def listaPratiche
    def dettagliPratica
    def praticaSelezionata
    def filtri = [:]
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt) {

        self = w

        tipoTributo = tt
        filtri = [tipoTributo: tt, step: IntegrazionePortaleService.STEP_RICEVUTO]
        caricaPratiche()
    }

    @Command
    def onRefresh() {
        praticaSelezionata = null
        caricaPratiche()

        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCaricaDettagliPratica() {
        caricaDettagliPratica()
    }

    @Command
    def onToggleSelection() {
        listaPratiche*.selezionata = !listaPratiche.any { it.selezionata }
        BindUtils.postNotifyChange(null, null, this, "listaPratiche")
    }

    @Command
    def onCheckPratica() {
        chkSelectAll.checked = !listaPratiche.any { !it.selezionata }
        BindUtils.postNotifyChange(null, null, null, "listaPratiche")
    }

    @Command
    def onAcquisisciPratiche() {

        if (!validate()) {
            return
        }

        Messagebox.show("Le pratiche acquisite dovranno essere validate e trasformate in denunce manualmente.\nProseguire?", "Attenzione",
                Messagebox.OK | Messagebox.CANCEL, Messagebox.QUESTION, { event ->
            if (event.name == Messagebox.ON_OK) {
                def msg = integrazionePortaleService.acquisisciPratiche(listaPratiche.findAll { it.selezionata }, tipoTributo)
                onChiudi()

                Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 5000, true)
            }
        })
    }

    private void caricaPratiche() {
        listaPratiche = integrazionePortaleService.elencoPratiche(filtri)
        dettagliPratica = null
        praticaSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "dettagliPratica")
        BindUtils.postNotifyChange(null, null, this, "listaPratiche")
        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
    }

    private void caricaDettagliPratica() {
        dettagliPratica = integrazionePortaleService.elencoDettagliPratica(praticaSelezionata.idPratica, tipoTributo)

        BindUtils.postNotifyChange(null, null, this, "dettagliPratica")
    }

    private def validate() {

        if (!listaPratiche.any { it.selezionata }) {
            Clients.showNotification("Selezionare almeno una pratica", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return false
        }

        return true
    }
}
