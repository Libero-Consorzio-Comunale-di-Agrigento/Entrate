package archivio.dizionari


import it.finmatica.tr4.codifiche.CodificheService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.InstallazioneParametroDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioInstallazioneParametroViewModel {


    // Componenti
    Window self

    // Services
    CodificheService codificheService

    OggettiCacheMap oggettiCacheMap


    InstallazioneParametroDTO installazioneParametro
    Boolean modifica
    boolean readOnly = true

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("installazioneParametro") InstallazioneParametroDTO ip) {

        this.self = w

        this.installazioneParametro = ip
        this.modifica = installazioneParametro.parametro != null
        this.readOnly = modifica
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        String message = codificheService.aggiornaInstallazioneParametro(installazioneParametro, modifica)

        if (!message.empty) {
            Clients.showNotification(
                    message,
                    Clients.NOTIFICATION_TYPE_WARNING, null,
                    "before_center", 5000, true)
            return
        }

        // Si aggiorna la cache
        oggettiCacheMap.refresh(OggettiCache.INSTALLAZIONE_PARAMETRI)
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
