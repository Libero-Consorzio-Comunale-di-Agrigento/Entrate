package archivio.dizionari

import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaTestiRicercaViewModel {

    SmartPndService smartPndService
    ComunicazioniTestiService comunicazioniTestiService

    Window self
    def filtro

    def listaTipiCanale

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtroPerComunicazione") def filtro) {

        this.self = w
        this.filtro = filtro ?: getFiltroIniziale()

        this.listaTipiCanale = [null, *comunicazioniTestiService.getListaTipiCanale()]
    }

    boolean isFiltroAttivo() {
        return (filtro.descrizione || filtro.oggetto || filtro.testo || filtro.note || filtro.tipoCanale)
    }

    static def getFiltroIniziale() {
        return [:]
    }

    @Command
    onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [
                filtro        : filtro,
                isFiltroAttivo: isFiltroAttivo()
        ])
    }

    @Command
    svuotaFiltri() {
        filtro = getFiltroIniziale()
        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}

