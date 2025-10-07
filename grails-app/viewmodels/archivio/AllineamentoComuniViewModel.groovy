package archivio

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.InstallazioneParametro
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.jobs.AllineamentoComuniJob
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class AllineamentoComuniViewModel {

    // Componenti
    Window self

    // Service
    def springSecurityService

    // Modello
    def dataUltimoAllineamento
    OggettiCacheMap oggettiCacheMap

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        this.dataUltimoAllineamento = InstallazioneParametro.get('COMU_INS')?.valore
    }

    @Command
    onAllineamentoComuni() {
        try {

            Clients.showNotification("Elaborazione avviata", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

            AllineamentoComuniJob.triggerNow(
                    [
                            codiceUtenteBatch: springSecurityService.currentUser.id,
                            codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                    ]
            )

            oggettiCacheMap.refresh(OggettiCache.INSTALLAZIONE_PARAMETRI)

            onChiudi()

        } catch (Exception ex) {
            if (ex instanceof Application20999Error) {
                Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                throw ex
            }
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


}
