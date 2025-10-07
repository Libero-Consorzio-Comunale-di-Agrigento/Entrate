package pratiche.violazioni

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.TipoAttoDTO
import it.finmatica.tr4.dto.TipoStatoDTO
import it.finmatica.tr4.jobs.AssegnaStatoTipoAttoJob
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class AssegnaStatoTipoAttoViewModel {
    Window self

    SpringSecurityService springSecurityService

    def elencoPratiche
    def listaStati
    def listaTipiAtto
    def statoSelected
    def tipoAttoSelected


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("elencoPratiche") def pratiche) {
        this.self = w

        this.elencoPratiche = pratiche

        listaStati = OggettiCache.TIPI_STATO.valore.sort { it.descrizione }
        listaStati = [new TipoStatoDTO([tipoStato: '', descrizione: ''])] + listaStati
        listaTipiAtto = OggettiCache.TIPI_ATTO.valore.sort { it.tipoAtto }
        listaTipiAtto = [new TipoAttoDTO([tipoAtto: -1, descrizione: ''])] + listaTipiAtto

    }

    @Command
    onChiudi() {
        chiudi()
    }

    @Command
    onAssegnaStatoTipoAtto() {

        if (!valid()) {
            return
        }

        AssegnaStatoTipoAttoJob.triggerNow(
                [
                        codiceUtenteBatch: springSecurityService.currentUser.id,
                        codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                        stato            : statoSelected,
                        tipoAtto         : tipoAttoSelected,
                        pratiche         : elencoPratiche
                ]
        )

        Clients.showNotification("Elaborazione avviata.", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        chiudi(true)
    }

    private def valid() {
        if (statoSelected == null && tipoAttoSelected == null) {
            Clients.showNotification("Seleziona un tipo di stato o un tipo di atto", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }
        return true
    }

    private chiudi(def value = null) {
        Events.postEvent(Events.ON_CLOSE, self, value)
    }
}
