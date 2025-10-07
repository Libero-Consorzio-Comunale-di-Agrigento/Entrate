package archivio.dizionari


import it.finmatica.tr4.categorieCatasto.CategorieCatastoService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCategoriaCatastoViewModel {

	static enum TipoOperazione {
		INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
	}


	// Componenti
	Window self

	// Services
	CategorieCatastoService categorieCatastoService
	CommonService commonService

	// Comuni
	CategoriaCatastoDTO categoriaCatastoSelezionato
	def tipoOperazione
	def labels
	def listaTipiTrattamento


	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("categoriaCatastoSelezionato") CategoriaCatastoDTO ccs,
		 @ExecutionArgParam("tipoOperazione") def to) {

		this.self = w

		this.tipoOperazione = to

		initCategoriaCatasto(ccs)

		this.listaTipiTrattamento = CategorieCatastoService.TIPI_TRATTAMENTO
		labels = commonService.getLabelsProperties('dizionario')
	}

	// Eventi interfaccia
	@Command
	onSalva() {

		// Controllo valori input
		if ((categoriaCatastoSelezionato.categoriaCatasto == null || categoriaCatastoSelezionato.categoriaCatasto.isEmpty()) ||
				(categoriaCatastoSelezionato.descrizione == null || categoriaCatastoSelezionato.descrizione.isEmpty())
		) {

			def messaggio = "I campi Categoria Catasto e Descrizione sono obbligatori!\n"
			Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
			return
		}

		if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

			if (categorieCatastoService.existsCategoriaCatasto(categoriaCatastoSelezionato)) {
				String unformatted = labels.get('dizionario.notifica.esistente')
				def message = String.format(unformatted,
						'una Categoria Catasto',
						"questa Categoria Catasto")

				Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
				return
			}
		}

		categorieCatastoService.salvaCategoriaCatasto(categoriaCatastoSelezionato)

		Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
	}

	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [:])
	}


	private def initCategoriaCatasto(def categoriaCatasto) {

		if (tipoOperazione == TipoOperazione.INSERIMENTO) {
			this.categoriaCatastoSelezionato = new CategoriaCatastoDTO()
			return
		}

		this.categoriaCatastoSelezionato = categoriaCatasto
	}

}