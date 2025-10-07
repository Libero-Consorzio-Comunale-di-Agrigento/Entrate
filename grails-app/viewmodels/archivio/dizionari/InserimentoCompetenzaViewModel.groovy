package archivio.dizionari

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dto.Ad4Tr4UtenteDTO
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.Si4CompetenzeDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class InserimentoCompetenzaViewModel {

    // Componenti
    Window self

    CompetenzeService competenzeService

    String competenzaOggetto
    def tipiAbilitazione
    Si4CompetenzeDTO competenza = new Si4CompetenzeDTO()
    List<Ad4Tr4UtenteDTO> listaUtentiSenzaCompetenze

    Long tipoOggetto

    Ad4Tr4UtenteDTO utenteSelezionato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("oggettoCompetenza") String oggettoCompetenza,
         @ExecutionArgParam("tipoOggetto") Long tipoOggetto
    ) {

        this.self = w
        this.competenzaOggetto = oggettoCompetenza
        this.tipiAbilitazione = competenzeService.abilitazioniPerTipoOggetto(tipoOggetto)
        this.tipoOggetto = tipoOggetto

        listaUtentiSenzaCompetenze = competenzeService.listaUtenti()
    }

    private String validazione() {

        String message = ""

        if (utenteSelezionato == null) {
            message += "'Nominativo' campo obbligatorio\n"
        }

        if (competenza.si4Abilitazioni == null) {
            message += "'Tipologia' campo obbligatorio\n"
        }
        if (competenza.al != null && competenza.dal != null && (competenza.al < competenza.dal)) {
            message += "Data 'Al' non puo' essere inferiore a data 'Dal'"
        }

        return message
    }

    @Command
    void onSalva() {

        String errorMessage = validazione()
        if (!errorMessage.empty) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        competenza.utente = Ad4Utente.get(utenteSelezionato.id)?.toDTO()
        competenza.oggetto = competenzaOggetto
        competenza.accesso = "S"

        if (competenzeService.existsOverlappingCompetenza(competenza)) {
            def message = "Esistono Competenze intersecanti per ${tipoOggetto == CompetenzeService.TIPO_OGGETTO ? 'Tipo Tributo' : 'Funzione' } e Nominativo"
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

