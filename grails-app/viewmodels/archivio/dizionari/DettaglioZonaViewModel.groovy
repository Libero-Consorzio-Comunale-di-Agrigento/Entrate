package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.ArchivioVieZoneDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioZonaViewModel {

	// Services
	CommonService commonService
	CanoneUnicoService canoneUnicoService

	// Componenti
	Window self

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
	
	// Comuni
	def labels
	boolean modificabile = false
	boolean esistente = false
	
	// Dati
	ArchivioVieZoneDTO zona
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("zona") ArchivioVieZoneDTO zz,
						 @ExecutionArgParam("modifica") boolean md,
		 				@ExecutionArgParam("duplica") boolean dp) {

		this.self = w

		modificabile = md
		
		if(zz != null) {
			zona = zz
			if (!dp){
				esistente = true
			}
		}
		else {
			zona = new ArchivioVieZoneDTO()
			esistente = false
		}
		
		impostaZona()

		labels = commonService.getLabelsProperties('dizionario')
	}
						 
	/// Eventi interfaccia ######################################################################################################
						 

	@Command
	onSalva() {
		
		if(completaZona() == false) return
		if(verificaZona() == false) return

		def report = canoneUnicoService.salvaZona(zona)

		def savedMessage = "Salvataggio avvenuto con successo"
		visualizzaReport(report, savedMessage)
		
		if(report.result == 0) {
			aggiornaStato = true
		}
		
		if(report.result == 0) {
			if(zona.getDomainObject() == null) {
				onChiudi()
			}
		}

		onChiudi()
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################
	
	///
	/// *** Attiva tariffa impostata
	///
	def impostaZona() {
		
		BindUtils.postNotifyChange(null, null, this, "zona")

		BindUtils.postNotifyChange(null, null, this, "modificabile")
		BindUtils.postNotifyChange(null, null, this, "esistente")
	}
	


	///
	/// *** Completa tariffa prima di verifica e salvataggio
	///
	private def completaZona() {
		
		String message = ""
		boolean result = true
				
		if(message.size() > 0) {
			
			message = "Attenzione : \n\n" + message
			Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
			result = false
		}
		
		return result
	}
	
	///
	/// *** Verifica coerenza dati ViaZona
	///
	private def verificaZona() {
		
		String message = ""
		boolean result = true
		
		def report = canoneUnicoService.verificaZona(zona)
		if(report.result != 0) {
			message = report.message
		}

		if(message.size() > 0) {
			
			message = "Attenzione : \n\n" + message
			Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
			result = false
		}
		
		return result
	}
	
	def visualizzaReport(def report, String messageOnSuccess) {
	
		switch(report.result) {
			case 0 :
				if((messageOnSuccess ?: '').size() > 0) {
					String message = messageOnSuccess
					Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
				}
				break
			case 1 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
				break
			case 2 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
				break
		}
		
		return
	}
}
