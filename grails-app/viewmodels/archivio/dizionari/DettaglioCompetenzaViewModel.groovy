package archivio.dizionari

import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.Si4CompetenzeDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCompetenzaViewModel {

    // Componenti
    Window self

    CompetenzeService competenzeService

    Si4CompetenzeDTO competenza
    def tipoOggetto

    def tipiAbilitazione

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("competenza") def competenza,
         @ExecutionArgParam("tipoOggetto") def tipoOggetto

    ) {

        this.self = w
        this.competenza = competenza
        this.tipoOggetto = tipoOggetto
        this.tipiAbilitazione =
                competenzeService.abilitazioniPerTipoOggetto(tipoOggetto)
    }

    @Command
    def onSalva() {

        if (competenza.al != null && competenza.dal != null && (competenza.al < competenza.dal)) {
            String message = "Data 'Al' non puo' essere inferiore a data 'Dal'"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            Events.postEvent(Events.ON_ERROR, self, null)
            return
        }

        if (competenzeService.existsOverlappingCompetenza(competenza)) {
            def message = "Esistono Competenze intersecanti per ${tipoOggetto == CompetenzeService.TIPO_OGGETTO ? 'Tipo Tributo' : 'Funzione'} e Nominativo"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        competenzeService.aggiornaCompetenze(competenza)
        Events.postEvent(Events.ON_CLOSE, self, [salvato: true])
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
