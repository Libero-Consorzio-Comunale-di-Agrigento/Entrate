package sportello.contribuenti

import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.contribuenti.ContribuentiService
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.UploadEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CaricaDocumentoViewModel {

    public static final String UPL_DOCCON = 'UPL_DOCCON'
    Window self

    String filePath

    String nomeFile
    def file

    DocumentoContribuente documento
    ContribuentiService contribuentiService
    CommonService commonService

    def daDocumentale
    def uploadInfo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("documento") DocumentoContribuente documentoContribuente,
         @ExecutionArgParam("daDocumentale") @Default('false') boolean daDocumentale) {
        this.self = w
        this.documento = documentoContribuente

        this.daDocumentale = daDocumentale

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

        file = media.getStreamData()
        nomeFile = media.getName()
        filePath = nomeFile
    }

    @Command
    onInserisciFile() {
        if (!daDocumentale & nomeFile == null && documento.documento == null) {
            Messagebox.show("Attenzione! Selezionare il documento da caricare.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            if (file) {
                documento.documento = file.getBytes()
                documento.nomeFile = nomeFile
            }
            contribuentiService.caricaDocumento(documento)
            Events.postEvent(Events.ON_CLOSE, self, null)
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
