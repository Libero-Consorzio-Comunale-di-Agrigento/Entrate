package ufficiotributi.bonificaDati.versamenti

import it.finmatica.tr4.bonificaDati.versamenti.BonificaVersamentiService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class BonificaVersamentiCaricaArchiviViewModel {

    Window self

    TributiSession tributiSession

    BonificaVersamentiService bonificaVersamentiService
    CommonService commonService
    CompetenzeService competenzeService

    def tipoTributo
    def tipoIncasso
    def anci
    def readOnly

    def tipiTributo = [:]
    def tipoTributoSelezionato

    String codFiscale
    String nomeCognome

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("tipoTributo") def tipoTributo
         , @ExecutionArgParam("tipoIncasso") def tipoIncasso
         , @ExecutionArgParam("readOnly") def readOnly
         , @ExecutionArgParam("codFiscale") String cf) {

        this.self = w

        this.tipoTributo = tipoTributo
        this.tipoIncasso = tipoIncasso
        this.codFiscale = cf ?: '%'
        this.readOnly = readOnly

        if (!codFiscale.contains('%')) {
            Contribuente contribuenteRaw = Contribuente.get(this.codFiscale)
            this.nomeCognome = contribuenteRaw?.soggetto?.cognomeNome ?: "TUTTI"
            this.codFiscale = contribuenteRaw?.soggetto ? this.codFiscale : "%"
        } else {
            this.nomeCognome = "TUTTI"
        }

        anci = tipoIncasso == 'ANCI'
        tipoTributoSelezionato = tipoTributo

        costrusiciTributi()
    }

    @Command
    def onCarica() {
        def esito = bonificaVersamentiService.caricaArchivi(tipoIncasso, tipoTributoSelezionato?.key, codFiscale)
        if (esito.isEmpty()) {
            Events.postEvent(Events.ON_CLOSE, self, null)

            Clients.showNotification("Archivi caricati correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                    null, "middle_center", 3000, true)
        } else {
            Clients.showNotification(esito, Clients.NOTIFICATION_TYPE_ERROR,
                    null, "middle_center", 3000, true)
        }
        onClose()
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private void costrusiciTributi() {
        // Tipi tributo
        competenzeService.tipiTributoUtenzaScrittura().each {
            tipiTributo << [(it.tipoTributo): it.tipoTributoAttuale + ' - ' + it.descrizione]
        }
    }
}
