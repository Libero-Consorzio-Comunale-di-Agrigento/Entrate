package archivio.dizionari


import it.finmatica.tr4.dto.CodiceF24DTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaCodiciF24RicercaViewModel {

    Window self

    def filtro = [stampaRateazione: 'E']

    def tipiCodice = CodiceF24DTO.tipiCodice

    def tipiRateazione = CodiceF24DTO.tipiRateazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {

        this.self = w
        this.filtro = filtro ?: getFiltroIniziale()
    }


    boolean isFiltroAttivo() {
        filtro.tributo?.trim() || filtro.descrizione?.trim() || filtro.rateazione || filtro.tipoCodice || filtro.stampaRateazione != 'E'
    }

    def getFiltroIniziale() {
        [tributo: null, descrizione: null, rateazione: null, tipoCodice: null, stampaRateazione: 'E']
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [filtro: filtro, isFiltroAttivo: isFiltroAttivo()])
    }

    @Command
    def svuotaFiltri() {
        filtro = getFiltroIniziale()
        BindUtils.postNotifyChange(null, null, this, "filtro")
    }


}
