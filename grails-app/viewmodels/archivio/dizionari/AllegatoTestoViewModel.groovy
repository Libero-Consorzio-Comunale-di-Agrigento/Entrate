package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.dto.comunicazioni.testi.AllegatoTestoDTO
import it.finmatica.tr4.dto.comunicazioni.testi.ComunicazioneTestiDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.UploadEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class AllegatoTestoViewModel {
    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, VISUALIZZAZIONE
    }
    private static final String UPL_EMAIL = 'UPL_EMAIL'

    CommonService commonService
    ComunicazioniTestiService comunicazioniTestiService

    Window self

    TipoOperazione tipoOperazione
    ComunicazioneTestiDTO testo
    AllegatoTestoDTO allegato
    def uploadInfo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam('tipoOperazione') TipoOperazione tipoOperazione,
         @ExecutionArgParam('comunicazioneTesto') ComunicazioneTestiDTO testo,
         @ExecutionArgParam('allegatoTesto') AllegatoTestoDTO allegato) {
        this.self = w
        this.tipoOperazione = tipoOperazione

        if (this.tipoOperazione == TipoOperazione.INSERIMENTO) {
            this.testo = testo
            this.allegato = comunicazioniTestiService.creallegatoTesto(testo.toDomain()).toDTO()
        }
        if (this.tipoOperazione == TipoOperazione.MODIFICA) {
            this.testo = testo
            this.allegato = allegato
        }
        if (this.tipoOperazione == TipoOperazione.VISUALIZZAZIONE) {
            this.testo = testo
            this.allegato = allegato
        }

        fetchUploadInfo()
    }

    private fetchUploadInfo() {
        def uploadInfoString = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == UPL_EMAIL }?.valore
        uploadInfo = commonService.getUploadInfoByString(uploadInfoString)
    }

    @Command
    onUpload(@ContextParam(ContextType.TRIGGER_EVENT) UploadEvent event) {
        Media media = event.getMedia()

        if (isUploadNotValidAndNotify(media)) {
            resetAllegatoFile()
            return
        }

        addAllegatoFile(media)
    }

    private resetAllegatoFile() {
        allegato.nomeFile = null
        allegato.documento = null
        BindUtils.postNotifyChange(null, null, this, 'allegato')
    }

    private addAllegatoFile(Media media) {
        allegato.nomeFile = media.getName()
        allegato.documento = media.getStreamData().bytes
        BindUtils.postNotifyChange(null, null, this, 'allegato')
    }

    private isUploadNotValidAndNotify(Media media) {
        if (!commonService.validaEstensione(uploadInfo.formats, media)) {
            Clients.showNotification("Il tipo di file non è consentito.",
                    Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return true
        }

        if (!commonService.validaDimensione(uploadInfo, media)) {
            Clients.showNotification("Il file supera il limite di dimensione consentito.",
                    Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return true
        }

        if (!commonService.validaNomeFile(media, /\s/)) {
            Clients.showNotification("Il nome del file non può contenere spazi.",
                    Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return true
        }

        def nomeFile = media.getName()
        if (testo.allegatiTesto.any { it.nomeFile == nomeFile }) {
            Clients.showNotification("File ${nomeFile} gia' aggiunto agli allegati", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return true
        }

        return false
    }

    @Command
    onSalva() {
        if (areMandatoryEmptyAndNotify()) {
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [allegatoTesto: allegato])
    }

    private areMandatoryEmptyAndNotify() {
        def errors = []
        if (!allegato.nomeFile || allegato.documento == null) {
            errors << 'File obbligatorio'
        }
        if (!allegato.descrizione) {
            errors << 'Descrizione obbligatorio'
        }

        if (errors.empty) {
            return false
        }

        Clients.showNotification(errors.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
        return true
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }
}
