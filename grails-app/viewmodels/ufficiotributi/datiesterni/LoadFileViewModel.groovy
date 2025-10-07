package ufficiotributi.datiesterni

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.datiesterni.ImportDatiEsterniService
import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.dto.datiesterni.TitoloDocumentoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.UploadEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class LoadFileViewModel {
    public static final String UPL_IMPORT = 'UPL_IMPORT'

    Window self

    boolean allegatiVisible

    List<TitoloDocumentoDTO> listaDocumenti
    TitoloDocumentoDTO titoloDocumentoSelezionato

    String filePath
    def uploadInfo
    String nomeFile
    def file
    Map<String, ByteArrayInputStream> listaAllegati = [:]

    String stringaListaAllegati = ""

    //service
    ImportDatiEsterniService importDatiEsterniService
    CommonService commonService


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaDocumenti = TitoloDocumento.list().findAll {it.nomeBean && it.nomeMetodo}.toDTO().sort { it.descrizione }

        allegatiVisible = false

        def uploadInfoString = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == UPL_IMPORT }?.valore
        uploadInfo = commonService.getUploadInfoByString(uploadInfoString)
    }

    @NotifyChange(['allegatiVisible'])
    @Command
    onAbilitaAllegati() {
        allegatiVisible = titoloDocumentoSelezionato.tipoCaricamento == 'MULTI'
    }

    @NotifyChange(['filePath'])
    @Command
    onLoadFile(@ContextParam(ContextType.TRIGGER_EVENT) UploadEvent event) {
        Media media = event.getMedia()

        if (!commonService.validaEstensione(uploadInfo.formats, media)) {
            Messagebox.show("Il tipo di file non è consentito.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
            return
        }

        if (!commonService.validaDimensione(uploadInfo, media)) {
            Clients.showNotification("Il file supera il limite di dimensione consentito.",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            return
        }

        file = media.getStreamData();
        nomeFile = media.getName()

        filePath = nomeFile
    }

    @NotifyChange(['listaAllegati', 'stringaListaAllegati'])
    @Command
    onLoadAllegati(@ContextParam(ContextType.TRIGGER_EVENT) UploadEvent event) {
        Media[] listMedia = event.getMedias()
        String message = getAllegatiValidationMessage(listMedia)
        if (message) {
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
            listaAllegati = [:]
            stringaListaAllegati = ""
            return
        }

        listMedia.each {
            listaAllegati.put(it.getName(), it.getStreamData())
        }

        def listaAllegatiNames = listaAllegati.collect { it.key }
        stringaListaAllegati = listaAllegatiNames.join(", ")
    }

    private String getAllegatiValidationMessage(Media[] listMedia) {
        String message
        listMedia.each { media ->
            if (!commonService.validaEstensione(uploadInfo.formats, media)) {
                if (!message) {
                    message = "Il tipo del file ${media.getName()} non è consentito."
                } else {
                    message += "\nIl tipo del file ${media.getName()} non è consentito."
                }
            }

            if (!commonService.validaDimensione(uploadInfo, media)) {
                if (!message) {
                    message = "Il file ${media.getName()} supera il limite di dimensione consentito."
                } else {
                    message += "\nIl file ${media.getName()} supera il limite di dimensione consentito."
                }
            }
        }
        return message
    }

    @Command
    onInserisciFile() {
        if (titoloDocumentoSelezionato == null || nomeFile == null)
            Messagebox.show("Attenzione! Selezionare il tipo di documento o il file da caricare.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        else if (importDatiEsterniService.findByNomeDocumento(nomeFile) != null) {
            Messagebox.show("Attenzione! File gia' importato.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            importDatiEsterniService.loadFile(titoloDocumentoSelezionato, nomeFile, file, listaAllegati)
            Events.postEvent(Events.ON_CLOSE, self, null)
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
