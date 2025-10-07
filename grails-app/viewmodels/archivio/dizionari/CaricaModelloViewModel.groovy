package archivio.dizionari

import com.aspose.words.FileFormatUtil
import com.aspose.words.LoadFormat
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.UploadEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CaricaModelloViewModel {
    public static final String UPL_DOCCON = 'UPL_MODELL'

    Window self

    ModelliService modelliService
    CommonService commonService

    String filePath
    def file
    def note
    def modello
    def uploadInfo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("modello") def modello) {
        this.self = w
        this.modello = modello

        def uploadInfoString = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == UPL_DOCCON }?.valore
        uploadInfo = commonService.getUploadInfoByString(uploadInfoString)
    }

    @NotifyChange(['filePath'])
    @Command
    onLoadFile(@ContextParam(ContextType.TRIGGER_EVENT) UploadEvent event) {
        Media media = event.getMedia()

        if (!commonService.validaEstensione(uploadInfo.formats, media)) {
            Clients.showNotification("Il tipo di file non è consentito.",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return
        }

        if (!commonService.validaDimensione(uploadInfo, media)) {
            Clients.showNotification("Il file supera il limite di dimensione consentito.",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return
        }

        file = media.getStreamData();
        filePath = media.getName()
    }

    @Command
    onCaricaDocumento() {
        def bytesFile = file.getBytes()
        if (!note || note.isEmpty()) {
            Messagebox.show("Attenzione! Inserire una nota.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            if (FileFormatUtil.detectFileFormat(new ByteArrayInputStream(bytesFile)).loadFormat == LoadFormat.UNKNOWN) {
                Clients.showNotification("Tipo di documento non supportato.", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
                return
            }

            def versione = modelliService.caricaModello(modello, bytesFile, note)
            Events.postEvent(Events.ON_CLOSE, self, [nuovaVersione: versione])
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
