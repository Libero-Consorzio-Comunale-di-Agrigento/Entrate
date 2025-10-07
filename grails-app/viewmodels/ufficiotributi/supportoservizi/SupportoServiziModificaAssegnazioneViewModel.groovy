package ufficiotributi.supportoservizi

import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.imposte.supportoservizi.FiltroRicercaSupportoServizi;
import it.finmatica.tr4.supportoservizi.SupportoServiziService

import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SupportoServiziModificaAssegnazioneViewModel {

	// services
	def springSecurityService

	CompetenzeService competenzeService
	SupportoServiziService supportoServiziService

	// componenti
	Window self

	/// filtri
	Map parametri = [
			utente: null,
	]

	/// dizionari
	def listaUtenti

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		@ExecutionArgParam("tipiTributo") def tipiTributo) {

		this.self = w
		
		listaUtenti = null
		
		if(tipiTributo) {
			// Uno o più tipi tributo -> Prende solo quelli in comune
			tipiTributo.each { tipoTributo ->
				
				def elencoUtenti = supportoServiziService.getElencoUtentiPerTipoTributo(tipoTributo, competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
				
				if(listaUtenti != null) {
					listaUtenti = listaUtenti.findAll { it in  elencoUtenti }
				} else {
					listaUtenti = elencoUtenti
				}
			}
		}
		else {
			// Nessun tipo tributo -> Prende tutto
			listaUtenti = supportoServiziService.getElencoUtentiPerTipoTributo(null, competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
		}
	}

	@Command
	def onOK() {

		if (!validaParametri()) {
			return
		}

		Events.postEvent(Events.ON_CLOSE, self, [parametri: parametri])
	}

	@Command
	def onChiudi() {

		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	///
	/// Valida parametri -> True se ok
	///
	private boolean validaParametri() {

		String message = ""

		if (parametri.utente == null) {
			message += "Utente non specificato\n"
		}

		if (!(message.isEmpty())) {
			message = "Attenzione : \n\n" + message
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
		}

		return message.isEmpty()
	}
}
