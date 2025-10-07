package messaggistica.email

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.email.MessaggisticaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.util.media.AMedia
import org.zkoss.util.media.Media
import org.zkoss.zk.ui.event.UploadEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

abstract class AbstractEmailViewModel {
    public static final String UPL_EMAIL = 'UPL_EMAIL'

    // componenti
    Window self

    // Service
    CommonService commonService
    MessaggisticaService messaggisticaService

    def listaAllegati
    def dimensioneTotaleAllegati
    def allegatoSelezionato
    def uploadInfo

    def listaFirme
    def firmaSelezionata
    def testoFirma

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        def uploadInfoString = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == UPL_EMAIL }?.valore
        uploadInfo = commonService.getUploadInfoByString(uploadInfoString)

        caricaFirme()
    }

    @Command
    def onAggiungiAllegato(@ContextParam(ContextType.TRIGGER_EVENT) UploadEvent event) {

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

        if (!commonService.validaNomeFile(media, /\s/)) {
            Clients.showNotification("Il nome del file non può contenere spazi.",
                    Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        def file = media.getStreamData()
        def nomeFile = media.getName()
        def bytes = file.bytes

        if (listaAllegati.find { it.nome == nomeFile } != null) {
            Clients.showNotification("File ${nomeFile} gia' aggiunto agli allegati", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        listaAllegati << [nome: nomeFile, contenuto: bytes, dimensione: commonService.humanReadableSize(bytes.size())]

        calcolaDimensioneTotaleAllegati()

        BindUtils.postNotifyChange(null, null, this, "listaAllegati")
    }

    @Command
    def onRimuoviAllegato() {
        listaAllegati = listaAllegati - allegatoSelezionato
        allegatoSelezionato = null
        calcolaDimensioneTotaleAllegati()

        BindUtils.postNotifyChange(null, null, this, "listaAllegati")
        BindUtils.postNotifyChange(null, null, this, "allegatoSelezionato")
    }

    @Command
    def onVisualizzaAllegato() {
        AMedia amedia = commonService.fileToAMedia(allegatoSelezionato.nome, allegatoSelezionato.contenuto)
        Filedownload.save(amedia)
    }

    @Command
    def onGestioneFirme() {
        commonService.creaPopup("/messaggistica/email/firme.zul", self, [:], {
            caricaFirme()
        })
    }

    @Command
    def onChangeFirmaSelezionata() {
        changeFirmaSelezionata()
    }

    protected abstract changeFirmaSelezionata()

    protected void caricaFirme() {
        listaFirme = [null, *messaggisticaService.caricaFirme(true)]
        BindUtils.postNotifyChange(null, null, this, "listaFirme")
    }

    protected void calcolaDimensioneTotaleAllegati() {
        def dimensione = 0
        listaAllegati.each {
            dimensione += it.contenuto.size()
        }

        dimensioneTotaleAllegati = commonService.humanReadableSize(dimensione)

        BindUtils.postNotifyChange(null, null, this, "dimensioneTotaleAllegati")
    }
}
