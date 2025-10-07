package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.GruppoTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioGruppoTributoViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    CanoneUnicoService canoneUnicoService
    CommonService commonService

    Window self
    def tipoOperazione
    def labels
    GruppoTributoDTO gruppoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("gruppoTributo") GruppoTributoDTO gruppoTributo,
         @ExecutionArgParam("tipoOperazione") TipoOperazione tipoOperazione) {

        this.self = w
        this.tipoOperazione = tipoOperazione
        this.gruppoTributo = gruppoTributo
        this.labels = commonService.getLabelsProperties('dizionario')

        fetchGruppoTributo(tipoOperazione, gruppoTributo)

    }

    private void fetchGruppoTributo(TipoOperazione tipoOperazione, GruppoTributoDTO gruppoTributo) {
        if (tipoOperazione == TipoOperazione.CLONAZIONE) {
            this.gruppoTributo = commonService.clona(gruppoTributo)
            return
        }
        this.gruppoTributo = gruppoTributo
    }

    @Command
    onSalva() {

        if (!gruppoTributo.gruppoTributo) {
            def message = "Codice è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        if ((tipoOperazione == TipoOperazione.INSERIMENTO || tipoOperazione == TipoOperazione.CLONAZIONE) &&
                canoneUnicoService.existsGruppoTributo(gruppoTributo.toDomain())) {

            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    "un Gruppo Tributo",
                    "questo Codice")

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)

            return
        }

        gruppoTributo.descrizione = gruppoTributo.descrizione?.toUpperCase()
        canoneUnicoService.salvaGruppoTributo(gruppoTributo.toDomain())

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
        this.gruppoTributo."${flagCheckbox}" = this.gruppoTributo."${flagCheckbox}" == null ? "S" : null
    }

}
