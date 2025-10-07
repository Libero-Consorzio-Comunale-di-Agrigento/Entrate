package archivio.dizionari

import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaComunicazioniParametriRicercaViewModel {

    SmartPndService smartPndService

    Window self

    String titolo = "Ricerca Comunicazioni"
    def filtro
    def smartPndAbilitato

    List<TipiCanaleDTO> listaTipiCanale

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("listaTipiCanale") List<TipiCanaleDTO> listaTipiCanale,
         @ExecutionArgParam("filtro") def filtro) {

        this.listaTipiCanale = listaTipiCanale

        this.self = w
        this.filtro = filtro ?: inizializzaFiltro()

        smartPndAbilitato = smartPndService.smartPNDAbilitato()

    }

    boolean isFiltroAttivo() {
        return filtro.descrizione?.trim() ||
                (!smartPndAbilitato && filtro.flagFirma != 'T') ||
                (!smartPndAbilitato && filtro.flagProtocollo != 'T') ||
                (!smartPndAbilitato && filtro.flagPec != 'T')
    }

    static def inizializzaFiltro() {
        return [flagFirma     : 'T',
                flagProtocollo: 'T',
                flagPec       : 'T',
                descrizione   : ''
        ]
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
        filtro = inizializzaFiltro()
        BindUtils.postNotifyChange(null, null, this, "filtro")
        BindUtils.postNotifyChange(null, null, this, "filtriFlag")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
