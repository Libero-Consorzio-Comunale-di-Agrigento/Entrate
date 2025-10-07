package ufficiotributi.svuotamenti

import it.finmatica.tr4.CodiceRfid
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.svuotamenti.SvuotamentiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioSvuotamentoViewModel {

    Window self

    SvuotamentiService svuotamentiService

    def svuotamentoSelezionato
    def svuotamentoSelezionatoOld
    def solaLettura
    def listaRfid
    def contribuente
    def modifica
    def clonazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("solaLettura") def l,
         @ExecutionArgParam("isModifica") def im,
         @ExecutionArgParam("isClonazione") def ic,
         @ExecutionArgParam("codFiscale") def cf,
         @ExecutionArgParam("svuotamentoSelezionato") def ss) {

        this.self = w

        svuotamentoSelezionato = ss ?: [:]
        solaLettura = l
        modifica = im
        clonazione = ic

        contribuente = Contribuente.findByCodFiscale(svuotamentoSelezionato?.codFiscale ?: cf)

        svuotamentoSelezionato.contribuente = contribuente

        listaRfid = CodiceRfid.findAllByContribuente(contribuente).sort { it.oggetto.id }

        svuotamentoSelezionatoOld = svuotamentoSelezionato?.getClass()?.newInstance(svuotamentoSelezionato)

    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOk() {

        if (!valida()) {
            return
        }

        def rfidSelezionato = listaRfid.find { it.idCodiceRfid == svuotamentoSelezionato.idCodiceRfid }

        svuotamentoSelezionato.codRfid = rfidSelezionato.codRfid
        svuotamentoSelezionato.oggetto = rfidSelezionato.oggetto

        svuotamentiService.salvaSvuotamento(svuotamentoSelezionato, svuotamentoSelezionatoOld)

        Events.postEvent(Events.ON_CLOSE, self, [salvato: true])
    }

    private valida() {
        if (!(svuotamentoSelezionato.idCodiceRfid?.trim())) {
            Clients.showNotification("Selezionare un Codice RFID.", Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return false
        }

        if (!svuotamentoSelezionato.dataSvuotamento) {
            Clients.showNotification("Selezionare una data.", Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return false
        }

        return true
    }

}
