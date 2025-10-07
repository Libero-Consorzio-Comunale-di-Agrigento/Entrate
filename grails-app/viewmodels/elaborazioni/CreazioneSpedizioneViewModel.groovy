package elaborazioni

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.DettaglioElaborazione
import it.finmatica.tr4.elaborazioni.ElaborazioneMassiva
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.TipoSpedizione
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CreazioneSpedizioneViewModel {

    // componenti
    Window self

    // Service
    CommonService commonService

    ElaborazioniService elaborazioniService
    def tipoSpedizione
    def idElaborazione

    def tipiSpedizione
    def tipoLimiteFile = 'NO'
    def labelLimiteFile
    def limiteFile
    def dettagli

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idElaborazione") String idElaborazione) {
        this.self = w
        this.idElaborazione = idElaborazione
        this.tipiSpedizione = TipoSpedizione.findAll().sort { it.descrizione }

        def docSelezionati = DettaglioElaborazione.countByElaborazioneAndFlagSelezionato(ElaborazioneMassiva.get(idElaborazione), 'S')
        def docSelezionatiDim = commonService.humanReadableSize(elaborazioniService.getDimensioneTotaleDocumenti(idElaborazione, true) ?: 0)
        def docSelezionatiPagine = (elaborazioniService.getPagineTotaleDocumenti(idElaborazione, true) ?: 0)

        this.dettagli = "${docSelezionati} documenti selezionati per un totale di ${docSelezionatiDim} e ${docSelezionatiPagine} pagine."
    }

    @Command
    def onTipoLimite() {
        switch (tipoLimiteFile) {
            case 'DIM':
                labelLimiteFile = 'Mb'
                break
            default:
                labelLimiteFile = ''
        }

        limiteFile = null
        BindUtils.postNotifyChange(null, null, this, "labelLimiteFile")
        BindUtils.postNotifyChange(null, null, this, "limiteFile")
    }

    @Command
    onOk() {

        if (!verifica()) {
            return
        }

        Events.postEvent("onClose", self, [
                tipoSpedizione: tipoSpedizione,
                tipoLimiteFile: tipoLimiteFile,
                limiteFile    : limiteFile])
    }

    @Command
    def onChiudi() {
        Events.postEvent("onClose", self, null)
    }

    private def verifica() {
        if (tipoSpedizione == null) {
            Clients.showNotification("Indicare un tipo di spedizione.", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 2000, true)
            return false
        }

        if (tipoLimiteFile != 'NO') {
            if (limiteFile == null || limiteFile == 0) {
                if (tipoLimiteFile == 'DIM') {
                    Clients.showNotification("Indicare la massima dimensione del file in Mb.", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
                    return false
                }

                if (tipoLimiteFile == 'NUMP') {
                    Clients.showNotification("Indicare il massimo numero di pagine.", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
                    return false
                }
            } else {
                if (tipoLimiteFile == 'DIM' && (limiteFile * 1_000_000) < elaborazioniService.getDimensioneDocumentiMax(idElaborazione)) {
                    Clients.showNotification("La massima dimensione indicata e' minore della massima dimensione tra i file selezionati.", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
                    return false
                }

                if (tipoLimiteFile == 'NUMP' && limiteFile < elaborazioniService.getPagineDocumentiMax(idElaborazione)) {
                    Clients.showNotification("Il massimo numero di pagine indicato e' minore del massimo numero di pagine tra i file selezionati", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
                    return false
                }
            }
        }

        return true
    }

}
