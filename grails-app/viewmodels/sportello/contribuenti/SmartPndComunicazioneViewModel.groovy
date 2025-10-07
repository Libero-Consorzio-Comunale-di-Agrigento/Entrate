package sportello.contribuenti

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.Comunicazione
import it.finmatica.tr4.smartpnd.SmartPndService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class SmartPndComunicazioneViewModel {

    private static Log log = LogFactory.getLog(SmartPndComunicazioneViewModel)

    Window self

    CommonService commonService
    SmartPndService smartPndService

    Comunicazione comunicazione

    def modInvioList
    boolean testoColumnVisible

    boolean nuovo
    boolean protetto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("comunicazione") def comunicazione) {
        this.self = w

        this.comunicazione = comunicazione

        modInvioList = smartPndService.getListaModInvio(comunicazione)
        testoColumnVisible = modInvioList?.any {
            it.tipo in [SmartPndService.TIPO_MOD_INVIO_APPIO, SmartPndService.TIPO_MOD_INVIO_EMAIL]
        }
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onDownloadFileAllegato(@BindingParam("allegato") def allegato) {
        def filename = allegato.filename
        byte[] content

        try {
            if (allegato.url) {
                String[] splits = allegato.url.split('/')
                filename = !filename && splits.size() > 0 ? splits.last() : allegato.url

                def url = new URL(allegato.url)
                content = url.openStream().bytes
            } else {
                content = smartPndService.getComunicazioneAllegato(comunicazione.idComunicazione, allegato.filename)
            }

            AMedia amedia = commonService.fileToAMedia(filename, content)
            Filedownload.save(amedia)
        } catch (Exception e) {
            log.error('Impossibile creare comunicazione', e)

            Clients.showNotification("Impossibile scaricare file - ${e.localizedMessage}",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
        }
    }

}
