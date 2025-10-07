package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.TipoStatoContribuenteService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioTipoStatoContribuenteViewModel {

    enum OpeningMode {
        CREATE('CREATE'),
        EDIT('EDIT'),
        CLONE('CLONE'),
        VIEW('VIEW')

        String code

        OpeningMode(String code) {
            this.code = code
        }
    }

    CommonService commonService
    TipoStatoContribuenteService tipoStatoContribuenteService

    Window self
    OpeningMode openingMode
    def tipoStatoContribuente

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("openingMode") OpeningMode openingMode,
         @ExecutionArgParam("tipoStatoContribuente") def tipoStatoContribuente) {

        this.self = w

        if (openingMode in [OpeningMode.EDIT, OpeningMode.CLONE, OpeningMode.VIEW] && !tipoStatoContribuente) {
            throw new IllegalArgumentException("Tipo stato contribuente non specificato")
        }

        if (openingMode == OpeningMode.CLONE) {
            tipoStatoContribuente.id = null
        }

        this.openingMode = openingMode

        initTipoStatoContribuente(tipoStatoContribuente)
    }

    private void initTipoStatoContribuente(tipoStatoContribuente) {
        if (openingMode == OpeningMode.CREATE) {
            this.tipoStatoContribuente = tipoStatoContribuenteService.newTipoStatoContribuente()
            return
        }
        if (openingMode == OpeningMode.CLONE) {
            this.tipoStatoContribuente = commonService.clona(tipoStatoContribuente)
            return
        }
        this.tipoStatoContribuente = tipoStatoContribuente
    }

    @Command
    onSalva() {
        if (openingMode == OpeningMode.VIEW) {
            throw new IllegalStateException("Non si possono effettuare modifiche in modalità di visualizzazione")
        }
        if (!isValidTipoStatoContribuente()) {
            return
        }

        tipoStatoContribuente.descrizione = tipoStatoContribuente.descrizione.toUpperCase()
        tipoStatoContribuente.descrizioneBreve = tipoStatoContribuente.descrizioneBreve.toUpperCase()
        tipoStatoContribuenteService.saveTipoStatoContribuente(tipoStatoContribuente)

        onChiudi()
    }

    private def isValidTipoStatoContribuente() {
        if (!tipoStatoContribuente.descrizione || !tipoStatoContribuente.descrizione.trim()) {
            Clients.showNotification("Descrizione obbligatoria", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 3000, true)
            return false
        }

        if (!tipoStatoContribuente.descrizioneBreve || !tipoStatoContribuente.descrizioneBreve.trim()) {
            Clients.showNotification("Descrizione Breve obbligatoria", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 3000, true)
            return false
        }

        if (tipoStatoContribuente.id == null) {
            Clients.showNotification("Codice obbligatorio", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 3000, true)
            return false
        }

        if (openingMode in [OpeningMode.CREATE, OpeningMode.CLONE] && tipoStatoContribuenteService.existsTipoStatoContribuente(tipoStatoContribuente.id)) {
            def message = "Tipo stato contribuente con codice ${tipoStatoContribuente.id} esistente"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return false
        }

        return true
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
