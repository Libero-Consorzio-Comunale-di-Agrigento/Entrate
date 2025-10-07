package archivio.dizionari

import it.finmatica.tr4.codiciDiritto.CodiciDirittoService
import it.finmatica.tr4.dto.CodiceDirittoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCodiceDirittoViewModel {

	static enum TipoOperazione {
		INSERIMENTO, MODIFICA, CLONAZIONE, MODIFICA_TRATTAMENTO
	}

	// Componenti
	Window self

	// Services
	CodiciDirittoService codiciDirittoService

	// Comuni
	CodiceDirittoDTO codiceDirittoSelezionato
	def tipoOperazione

	def listaTipiTrattamento

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("codiceDirittoSelezionato") CodiceDirittoDTO cds,
		 @ExecutionArgParam("tipoOperazione") def to) {

		this.self = w

		this.tipoOperazione = to

		initCodiceDiritto(cds)

		this.listaTipiTrattamento = CodiciDirittoService.TIPI_TRATTAMENTO
	}

	// Eventi interfaccia
	@Command
	onSalva() {

		// Controllo valori input
		if ((codiceDirittoSelezionato.codDiritto == null || codiceDirittoSelezionato.codDiritto.isEmpty()) ||
			((codiceDirittoSelezionato.ordinamento ?: 0) < 1) ||
			(codiceDirittoSelezionato.descrizione == null || codiceDirittoSelezionato.descrizione.isEmpty())) {

			def messaggio = "I campi Codice Diritto, Ordinamento e Descrizione sono obbligatori!\n"
			Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
			return
		}

		if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

			if (codiciDirittoService.existsCodiceDiritto(codiceDirittoSelezionato)) {
				Clients.showNotification("Esiste già un Codice Diritto con questi dati!", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
				return
			}
		}

		codiciDirittoService.salvaCodiceDiritto(codiceDirittoSelezionato)

		Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
	}

	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [:])
	}

	private def initCodiceDiritto(def codiceDiritto) {

		if (tipoOperazione == TipoOperazione.INSERIMENTO) {

			def newCodiceDiritto = new CodiceDirittoDTO()

			this.codiceDirittoSelezionato = newCodiceDiritto

		} else if(tipoOperazione == TipoOperazione.CLONAZIONE){
			this.codiceDirittoSelezionato = codiceDiritto

			this.codiceDirittoSelezionato.codDiritto = ''
		}else {
			this.codiceDirittoSelezionato = codiceDiritto
		}
	}

	@Command
	onCheckboxCheck(@BindingParam("flagCheckbox") def flagCheckbox) {

		// Inverte il flag del checkbox relativo tra null o 'S'
		this.codiceDirittoSelezionato."${flagCheckbox}" = this.codiceDirittoSelezionato."${flagCheckbox}" == null ? "S" : null
	}

}