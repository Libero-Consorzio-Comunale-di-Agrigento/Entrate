package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.GruppiSanzioneDTO
import it.finmatica.tr4.sanzioni.SanzioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioGruppoSanzioneViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    SanzioniService sanzioniService
    CommonService commonService

    Window self
    def tipoOperazione
    def labels
    GruppiSanzioneDTO gruppoSanzione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("gruppoSanzione") GruppiSanzioneDTO gruppoSanzione,
         @ExecutionArgParam("tipoOperazione") TipoOperazione tipoOperazione) {

        this.self = w
        this.tipoOperazione = tipoOperazione
        this.gruppoSanzione = gruppoSanzione
        this.labels = commonService.getLabelsProperties('dizionario')

        fetchGruppoSanzione(tipoOperazione, gruppoSanzione)

    }

    private void fetchGruppoSanzione(TipoOperazione tipoOperazione, GruppiSanzioneDTO gruppoSanzione) {
        if (tipoOperazione == TipoOperazione.INSERIMENTO) {
            this.gruppoSanzione = new GruppiSanzioneDTO()
            return
        }
        if (tipoOperazione == TipoOperazione.CLONAZIONE) {
            this.gruppoSanzione = commonService.clona(gruppoSanzione)
            return
        }
        this.gruppoSanzione = gruppoSanzione
    }

    @Command
    onSalva() {

        if (!gruppoSanzione.gruppoSanzione) {
            def message = "Codice è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!gruppoSanzione.descrizione) {
            def message = "Descrizione è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        if ((tipoOperazione == TipoOperazione.INSERIMENTO || tipoOperazione == TipoOperazione.CLONAZIONE) &&
                sanzioniService.existsGruppoSanzione(gruppoSanzione.toDomain())) {

            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    "un Gruppo Sanzione",
                    "questo Codice")

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)

            return
        }

        gruppoSanzione.descrizione = gruppoSanzione.descrizione.toUpperCase()
        sanzioniService.salvaGruppoSanzione(gruppoSanzione.toDomain())

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCheckboxCheck(@BindingParam("flagCheckbox") def flagCheckbox) {
        // Inverte il flag del checkbox relativo tra null o 'S'
        this.gruppoSanzione."${flagCheckbox}" = this.gruppoSanzione."${flagCheckbox}" == null ? "S" : null
    }

}
