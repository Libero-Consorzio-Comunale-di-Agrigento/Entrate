import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class OggettiInvalidiViewModel {

    // Services
    CommonService commonService

    // Componenti
    Window self

    // Comuni
    def listaOggettiInvalidi


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("listOggInvalidi") def loi) {

        self = w

        this.listaOggettiInvalidi = loi
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onRicompila() {

        // Ricompilazione
        try {
            commonService.ricompilaOggetti()
        } catch (Exception e) {

            // Si ricarica la lista
            listaOggettiInvalidi = commonService.getOggettiInvalidi()
            BindUtils.postNotifyChange(null, null, this, "listaOggettiInvalidi")

            // Si lancia l'eccezione in modo che venga gestita dall'ErrorViewModel
            throw e
        }

        // Controllo presenza oggetti invalidi
        listaOggettiInvalidi = commonService.getOggettiInvalidi()

        if (listaOggettiInvalidi.size() == 0) {
            Events.postEvent(Events.ON_CLOSE, self, null)
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggettiInvalidi")

        Clients.showNotification("Ricompilazione eseguita.",
                Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
    }


}
