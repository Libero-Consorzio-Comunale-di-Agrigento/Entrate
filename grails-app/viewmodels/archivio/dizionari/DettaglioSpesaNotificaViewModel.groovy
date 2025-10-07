package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.SpesaNotificaDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.speseNotifica.SpeseNotificaService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioSpesaNotificaViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    SpeseNotificaService speseNotificaService
    CommonService commonService

    Window self
    def tipoOperazione
    def tipoTributo
    def labels
    SpesaNotificaDTO spesaNotifica
    def listaTipiNotifica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("spesaNotifica") SpesaNotificaDTO spesaNotifica,
         @ExecutionArgParam("tipoTributo") TipoTributoDTO tipoTributo,
         @ExecutionArgParam("tipoOperazione") TipoOperazione tipoOperazione) {

        this.self = w
        this.tipoOperazione = tipoOperazione
        this.spesaNotifica = spesaNotifica
        this.tipoTributo = tipoTributo
        this.labels = commonService.getLabelsProperties('dizionario')
        this.listaTipiNotifica = [null] + speseNotificaService.getListaTipiNotifica()

        fetchSpesaNotifica(tipoOperazione, spesaNotifica)

    }

    private void fetchSpesaNotifica(TipoOperazione tipoOperazione, SpesaNotificaDTO spesaNotifica) {
        if (tipoOperazione == TipoOperazione.INSERIMENTO) {
            this.spesaNotifica = speseNotificaService.creaSpesaNotifica(this.tipoTributo)
            return
        }
        if (tipoOperazione == TipoOperazione.CLONAZIONE) {
            this.spesaNotifica = speseNotificaService.clonaSpesaNotifica(spesaNotifica)
            return
        }
        this.spesaNotifica = spesaNotifica
    }

    @Command
    onSalva() {

        if (!spesaNotifica.descrizione) {
            def message = "Descrizione è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!spesaNotifica.descrizioneBreve) {
            def message = "Descrizione Breve è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!spesaNotifica.importo) {
            def message = "Importo è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        spesaNotifica.descrizione = spesaNotifica.descrizione.toUpperCase()
        spesaNotifica.descrizioneBreve = spesaNotifica.descrizioneBreve.toUpperCase()
        speseNotificaService.salvaSpesaNotifica(spesaNotifica.toDomain())

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
