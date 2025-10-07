package archivio.dizionari


import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.Si4CompetenzeDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCompetenzaUtenteViewModel {

    // Services
    CompetenzeService competenzeService

    // Componenti
    Window self

    // Comuni
    Si4CompetenzeDTO competenza
    def tipoOggetto
    def tipoOggettoString
    def utente
    def listaTipiTributo
    def listaTipiAbilitazione
    def listaFunzioni
    def titolo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoOggetto") def tp,
         @ExecutionArgParam("utente") def ut,
         @ExecutionArgParam("competenza") def cmp) {

        this.self = w

        this.competenza = cmp ?: new Si4CompetenzeDTO()
        this.utente = ut

        this.tipoOggetto = tp
        this.tipoOggettoString = tipoOggetto == CompetenzeService.TIPO_OGGETTO ? 'tributo' : 'funzione'

        this.titolo = "Competenza"

        listaTipiTributo = OggettiCache.TIPI_TRIBUTO.valore

        this.listaFunzioni = competenzeService.listaFunzioni().findAll { it.flagVisibile }

        this.listaTipiAbilitazione = competenzeService.abilitazioniPerTipoOggetto(tipoOggetto)

    }

    @Command
    def onSalva() {

        def errori = controllaParametri()

        if (errori.length() > 0) {
            Clients.showNotification(errori, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        competenza.utente = utente
        competenza.accesso = "S"

        if (competenzeService.existsOverlappingCompetenza(competenza)) {
            def message = "Esistono Competenze intersecanti per questo Utente e ${tipoOggetto == CompetenzeService.TIPO_OGGETTO ? 'Tributo' : 'Funzione'}"
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

    private def controllaParametri() {

        def message = ""

        if (competenza.oggetto == null) {
            message += "'${tipoOggetto == CompetenzeService.TIPO_OGGETTO ? "Tributo" : 'Funzione'}' campo obbligatorio\n"
        }
        if (competenza.si4Abilitazioni == null) {
            message += "'Tipologia' campo obbligatorio\n"
        }
        if (competenza.al != null && competenza.dal != null && (competenza.al < competenza.dal)) {
            message += "Data 'Al' non puo' essere inferiore di data 'Dal'"
        }

        return message
    }
}
