package archivio.dizionari

import it.finmatica.tr4.ArchivioVie
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.ArchivioVieDTO
import it.finmatica.tr4.dto.ArchivioVieZonaDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioViaZonaViewModel {

	// Services
	CommonService commonService
	CanoneUnicoService canoneUnicoService

	// Componenti
	Window self

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
	
	def latoVia = null
	def zonaAssociata = null
	
	def parametriBandBox = [
		codiceVia : null,
		indirizzo : null,
	]
	
	// Comuni
	def listZone = null
	def listLato

	boolean modificabile = false
	boolean esistente = false
	
	// Dati
	ArchivioVieZonaDTO viaZona
	def labels

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("viaZona") ArchivioVieZonaDTO vz,
		 @ExecutionArgParam("modifica") boolean md,
		 @ExecutionArgParam("modifica") boolean dp,
		 @ExecutionArgParam("zona") def zona) {

		this.self = w

		modificabile = md
		
		listZone = canoneUnicoService.getElencoZone()
		listZone.sort { it.codZona }
		listZone.each {
			it.denominazione = (it.codZona as String) + " - " + it.denominazione
		}

		listLato = canoneUnicoService.getListaLati()
		
		if(vz != null) {
			viaZona = vz
			if (!dp){
				esistente = true
			}
		}
		else {
			viaZona = new ArchivioVieZonaDTO()
			esistente = false
		}

		impostaViaZona(zona)
		labels = commonService.getLabelsProperties('dizionario')
	}
						 
	/// Eventi interfaccia ######################################################################################################
						 
	@Command
	def onSelectVia(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
		
		def selectedVia = event.data
		
		parametriBandBox.codiceVia = (selectedVia.id ?: null)
		parametriBandBox.indirizzo = (selectedVia.denomUff ?: null)
		
		BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
	}
	
	@Command
	def onSelectLato() {
		
	}
 
	@Command
	def onSelectZona() {
		
	}


	@Command
	onSalva() {
		
		if(completaViaZona() == false) return
		if(verificaViaZona() == false) return
		
		def report = canoneUnicoService.salvaViaZona(viaZona)

		def savedMessage = "Salvataggio avvenuto con successo"
		visualizzaReport(report, savedMessage)
		
		if(report.result == 0) {
			aggiornaStato = true
			onChiudi()
		}
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################

	def impostaViaZona(def zona) {
		
		parametriBandBox.codiceVia = viaZona.archivioVie?.id
		parametriBandBox.indirizzo = viaZona.archivioVie?.denomUff
		
		latoVia = listLato.find { it.codice == viaZona.lato }

		if (zona) {
			zonaAssociata = listZone.find { (it.codZona == zona.codZona) && (it.sequenza == zona.sequenza) }
		} else {
			zonaAssociata = listZone.find { (it.codZona == viaZona.codZona) && (it.sequenza == viaZona.sequenzaZona) }
		}

		BindUtils.postNotifyChange(null, null, this, "viaZona")

		BindUtils.postNotifyChange(null, null, this, "zonaAssociata")
		BindUtils.postNotifyChange(null, null, this, "latoVia")
		
		BindUtils.postNotifyChange(null, null, this, "modificabile")
		BindUtils.postNotifyChange(null, null, this, "esistente")
	}
	
	///
	/// *** Completa tariffa prima di verifica e salvataggio
	///
	private def completaViaZona() {
		
		String message = ""
		boolean result = true
		
		ArchivioVieDTO selectedVia = null
		
		///
		/// *** Se esiste codice ricava da esso e confronta, se diversi azzera ed uno testo isnerito
		///
		if((parametriBandBox.codiceVia ?: -1) != -1) {
			selectedVia = ArchivioVie.findById(parametriBandBox.codiceVia)?.toDTO()
			if(selectedVia.denomUff != parametriBandBox.indirizzo) {
				selectedVia = null
			}
		}
		viaZona.archivioVie = selectedVia
		
		viaZona.lato = listLato.find { it.codice == latoVia?.codice } ?.codice
		
		def zona = listZone.find { (it.codZona == zonaAssociata?.codZona) && (it.sequenza == zonaAssociata?.sequenza) } 
		viaZona.codZona = zona?.codZona
		viaZona.sequenzaZona = zona?.sequenza
		
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
	private def verificaViaZona() {
		
		String message = ""
		boolean result = true
		
		def report = canoneUnicoService.verificaViaZona(viaZona)
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
	
	///
	/// *** Visualizza report
	///
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
