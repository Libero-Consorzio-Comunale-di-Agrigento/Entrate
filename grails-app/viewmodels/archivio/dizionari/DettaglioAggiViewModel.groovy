package archivio.dizionari

import it.finmatica.tr4.Aggio
import it.finmatica.tr4.aggi.AggiService
import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioAggiViewModel {

    // Servizi
    AggiService aggiService
    CommonService commonService

    // Componenti
    Window self
	
	Boolean lettura
	def isModifica
	def isClonazione

    // Comuni
    def tipoTributo
    def aggioSelezionato
    Aggio aggio
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("aggioSelezionato") def aggs,
         @ExecutionArgParam("lettura") boolean lt,
         @ExecutionArgParam("isModifica") boolean im,
         @ExecutionArgParam("isClonazione") @Default("false") boolean ic) {

        this.self = w
		
		this.lettura = lt
		
        this.tipoTributo = tt
        this.isModifica = im
        this.isClonazione = ic
        this.aggioSelezionato = aggs

        initDatiAggio()

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    onSalva() {

        if (areRequiredFieldsEmptyAndNotify()) {
            return
        }

        if (areRangesBadAndNotify()) {
            return
        }

        if (isOverlappingAndNotify()) {
            return
        }

        if (!isModifica || isClonazione) {
            def nextSequeza = aggiService.getNextSequenza(tipoTributo)
            aggio.sequenza = nextSequeza
        }

        aggiService.salvaAggio(aggio)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onChiudi()
    }

    private areRequiredFieldsEmptyAndNotify() {
        def errors = []
        if (!aggio.dataInizio) {
            errors << 'Data Inizio obbligatoria'
        }
        if (!aggio.dataFine) {
            errors << 'Data Fine obbligatoria'
        }
        if (aggio.giornoInizio == null) {
            errors << 'Giorno Inizio obbligatorio'
        }
        if (aggio.giornoFine == null) {
            errors << 'Giorno Fine obbligatorio'
        }
        if (aggio.aliquota == null) {
            errors << 'Aliquota obbligatorio'
        }
        if (!errors.empty) {
            Clients.showNotification(errors.join("\n"),
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return true
        }

        return false
    }

    private areRangesBadAndNotify() {
        def errors = []
        if (aggio.dataInizio > aggio.dataFine) {
            errors << 'Data Inizio maggiore di Data Fine'
        }
        if (aggio.giornoInizio > aggio.giornoFine) {
            errors << 'Giorno Inizio maggiore di Giorno Fine'
        }
        if (!errors.empty) {
            Clients.showNotification(errors.join("\n"),
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return true
        }

        return false
    }

    def isOverlappingAndNotify() {
        if (aggiService.existsOverlappingAggio(aggio)) {
            Clients.showNotification("Esistono periodi intersecanti",
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return true
        }
        return false
    }


    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def initDatiAggio() {

        aggio = new Aggio()

        if (isModifica) { //Caso modifica/clonazione
            aggio.dataInizio = aggioSelezionato.dataInizio
            aggio.dataFine = aggioSelezionato.dataFine
            aggio.giornoInizio = aggioSelezionato.giornoInizio
            aggio.giornoFine = aggioSelezionato.giornoFine
            aggio.aliquota = aggioSelezionato.aliquota
            aggio.sequenza = aggioSelezionato.sequenza
            aggio.importoMassimo = aggioSelezionato.importoMassimo
        }

        if (isClonazione) {
            aggio.sequenza = null
        }

        aggio.tipoTributo = tipoTributo
    }

}
