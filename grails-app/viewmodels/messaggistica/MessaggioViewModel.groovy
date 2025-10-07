package messaggistica

import groovy.json.JsonSlurper
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.email.MessaggisticaService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class MessaggioViewModel {

    private static Log log = LogFactory.getLog(MessaggioViewModel)

    // componenti
    Window self

    // service
    MessaggisticaService messaggisticaService
    CommonService commonService

    // Model
    Messaggio messaggio
    def note
    def allegatoSelezionato
    def dimensioneTotaleAllegati

    def contribuente

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codFiscale") def codFiscale,
         @ExecutionArgParam("sequenza") def sequenza) {
        this.self = w

        def documento = DocumentoContribuente.findByContribuenteAndSequenza(Contribuente.findByCodFiscale(codFiscale), sequenza)
        messaggio = new JsonSlurper().parseText(messaggisticaService.unzip(documento.documento))
        note = documento.note
        contribuente = documento.contribuente

        calcolaDimensioneTotaleAllegati()

        // TODO: il ws va in errore. Verificare
        // messaggisticaService.getStatoMessaggio(documento.idMessaggio)
    }

    @Command
    def onVisualizzaAllegato() {
        AMedia amedia = commonService.fileToAMedia(allegatoSelezionato.nome, allegatoSelezionato.contenuto as byte[])
        Filedownload.save(amedia)
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private void calcolaDimensioneTotaleAllegati() {
        def dimensione = 0
        messaggio.allegati.each {
            dimensione += it.contenuto.size()
        }

        dimensioneTotaleAllegati = commonService.humanReadableSize(dimensione)
        BindUtils.postNotifyChange(null, null, this, "dimensioneTotaleAllegati")
    }

}
