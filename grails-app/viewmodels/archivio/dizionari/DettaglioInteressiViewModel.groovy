package archivio.dizionari

import it.finmatica.tr4.Interessi
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.interessi.InteressiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioInteressiViewModel {

    // Servizi
    InteressiService interessiService
    CommonService commonService

    // Componenti
    Window self

	Boolean lettura
    def isModifica
    def isClonazione
	
    // Comuni
    def tipoTributo
    def interesseSelezionato
    Interessi interesse
    def labels
	
    def listaTipiInteresse = [
            "G",
            "L",
            "S",
            "R",
            "D"
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("interesseSelezionato") def is,
         @ExecutionArgParam("lettura") boolean lt,
         @ExecutionArgParam("isModifica") boolean im,
         @ExecutionArgParam("isClonazione") @Default("false") boolean ic) {

        this.self = w
		
		this.lettura = lt
		
        this.tipoTributo = tt
        this.interesseSelezionato = is
        this.isModifica = im
        this.isClonazione = ic

        initDatiInteresse()
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    onSalva() {
        if(areRequiredFieldsEmptyAndNotify()){
            return
        }

        if (interesse.dataInizio > interesse.dataFine) {
            def message = 'Data Inizio maggiore di Data Fine'
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return
        }

        if (isOverlappingAndNotify()) {
            return
        }

        interessiService.salvaInteresse(interesse)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    private def areRequiredFieldsEmptyAndNotify() {
        def errors = []
        if (!interesse.dataInizio) {
            errors << 'Data Inizio obbligatoria'
        }
        if (!interesse.dataFine) {
            errors << 'Data Fine obbligatoria'
        }
        if (interesse.aliquota == null) {
            errors << 'Aliquota obbligatoria'
        }
        if (!interesse.tipoInteresse) {
            errors << 'Tipo Interesse obbligatorio'
        }
        if (errors.empty) {
            return false
        }
        Clients.showNotification(errors.join("\n"),
                Clients.NOTIFICATION_TYPE_ERROR,
                self, "top_center", 3000, true)
        return true
    }

    def isOverlappingAndNotify() {
        if (interessiService.presenzaSovrapposizioni(interesse)) {
            Clients.showNotification("Esistono periodi intersecanti per questo Tipo Interesse",
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

    private def initDatiInteresse() {

        interesse = new Interessi()
        interesse.tipoTributo = tipoTributo

        if (!isModifica && !isClonazione) {
            //Caso aggiunta
            return
        }

        interesse.dataInizio = interesseSelezionato.dataInizio
        interesse.dataFine = interesseSelezionato.dataFine
        interesse.aliquota = interesseSelezionato.aliquota
        interesse.tipoInteresse = interesseSelezionato.tipoInteresse

        if (isClonazione) {
            interesse.sequenza = null
            return
        }

        interesse.sequenza = interesseSelezionato.sequenza
    }
}
