package archivio.dizionari

import dizionari.jobs.AfcElaborazioneListaViewModel
import it.finmatica.afc.jobs.AfcElaborazione
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.jobs.Tr4AfcElaborazioneService
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class AfcElaborazioneListaExtendedViewModel extends AfcElaborazioneListaViewModel {

    CommonService commonService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("deleteVisible") Boolean deleteVisible) {
        this.self = w
        this.deleteVisible = deleteVisible ?: false
        super.caricaLista()
    }

    @Command
    def onScaricaLogErrori(@BindingParam("elaborazione") AfcElaborazione elaborazione) {
        File logFile = tr4AfcElaborazioneService.getLogFile(elaborazione)
        String fileName = tr4AfcElaborazioneService.getPrettyFileName(elaborazione, logFile)
        byte[] fileContent = logFile.readBytes()

        AMedia amedia = commonService.fileToAMedia(fileName, fileContent)
        Filedownload.save(amedia)
    }

    def controllaEsistenzaLog(AfcElaborazione elaborazione) {
        return tr4AfcElaborazioneService.existsLogFile(elaborazione)
    }
}
