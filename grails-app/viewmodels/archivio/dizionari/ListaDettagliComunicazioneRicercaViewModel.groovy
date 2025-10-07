package archivio.dizionari

import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window


class ListaDettagliComunicazioneRicercaViewModel {

    SmartPndService smartPndService
    ComunicazioniTestiService comunicazioniTestiService

    Window self

    String titolo = "Ricerca Dettagli Comunicazione"
    def filtro
    def smartPndAbilitato

    def listaTipiCanale

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {

        this.listaTipiCanale = [null, *comunicazioniTestiService.listaTipiCanale]

        this.self = w
        this.filtro = filtro ?: inizializzaFiltro()

        smartPndAbilitato = smartPndService.smartPNDAbilitato()

    }

    boolean isFiltroAttivo() {
        return filtro.flagFirma != 'T' ||
                filtro.flagProtocollo != 'T' ||
                filtro.descrizione ||
                filtro.tipoCanale ||
                (smartPndAbilitato && filtro.tipoComunicazionePnd) ||
                (smartPndAbilitato && filtro.tagAppIo) ||
                (smartPndAbilitato && filtro.tagPec) ||
                (smartPndAbilitato && filtro.tagPND) ||
                (!smartPndAbilitato && filtro.tag)
    }

    static def inizializzaFiltro() {
        return [
                flagFirma           : 'T',
                flagProtocollo      : 'T',
                descrizione         : null,
                tipoCanale          : null,
                tipoComunicazionePnd: null,
                tagAppIo            : null,
                tagPec              : null,
                tagPND              : null,
                tag                 : null
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
