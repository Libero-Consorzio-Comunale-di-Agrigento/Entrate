package archivio.dizionari

import it.finmatica.tr4.dto.ArrotondamentiTributoDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioArrotondamentiTributoViewModel {

	// Services
	def springSecurityService
	
	CanoneUnicoService canoneUnicoService

	// Componenti
	Window self

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
		
	// Comuni
	def listArrotondamenti = [
		[ codice : ArrotondamentiTributoDTO.ARR_MODALITA_PREDEFINITO, descrizione: "Predefinito" ],
		[ codice : ArrotondamentiTributoDTO.ARR_MODALITA_NESSUNO, descrizione: "Nessuno" ],
		[ codice : ArrotondamentiTributoDTO.ARR_MODALITA_INTERO_SUCCESSIVO, descrizione: "Intero Superiore" ],
		[ codice : ArrotondamentiTributoDTO.ARR_MODALITA_MEZZO_SUCCESSIVO, descrizione: "Mezzo Superiore" ],
	]

	boolean modificabile = false;
	boolean esistente = false
	
	// Dati
	String tipoTributo;
	CodiceTributoDTO codiceTributo;
	ArrotondamentiTributoDTO arrotondamentiTributo;
	
	def arrotondamentoCR = null
	def arrotondamentoCT = null
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("tipoTributo") String tt,
						 @ExecutionArgParam("codiceTributo") CodiceTributoDTO ct,
						 @ExecutionArgParam("arrotondamentiTributo") ArrotondamentiTributoDTO at,
						 @ExecutionArgParam("modifica") boolean md) {

		this.self = w
		
		tipoTributo = tt;
		codiceTributo = ct;
		
		modificabile = md
		
		if(at != null) {
			arrotondamentiTributo = at
			esistente = true
		}
		else {
			arrotondamentiTributo = new ArrotondamentiTributoDTO();
			esistente = false
		}
		
		impostaArrotondamentiTributo();
	}
						 
	/// Eventi interfaccia ######################################################################################################
						 
	@Command
	def onSelectArrotondamentoCR() {
							 
	}
					 
	@Command
	def onSelectArrotondamentoCT() {
		
	}
	
	@Command
	def onPredefinito() {
		
		arrotondamentoCR = listArrotondamenti.find { it.codice == ArrotondamentiTributoDTO.ARR_MODALITA_PREDEFINITO }
		arrotondamentoCT = listArrotondamenti.find { it.codice == ArrotondamentiTributoDTO.ARR_MODALITA_PREDEFINITO }
		
		arrotondamentiTributo.consistenzaMinimaReale = null
		arrotondamentiTributo.consistenzaMinima = null
		
		BindUtils.postNotifyChange(null, null, this, "arrotondamentiTributo")
		BindUtils.postNotifyChange(null, null, this, "arrotondamentoCR")
		BindUtils.postNotifyChange(null, null, this, "arrotondamentoCT")
	}
	
	@Command
	def onSalva() {
		
		if(completaArrotondamentiTributo() == false) return
		if(verificaArrotondamentiTributo() == false) return

		def report = canoneUnicoService.salvaArrotondamentiTributo(arrotondamentiTributo);
		
		visualizzaReport(report, "Salvataggio eseguito con successo !")
		
		if(report.result == 0) {
			aggiornaStato = true;
		}
		
		if(report.result == 0) {
			if(arrotondamentiTributo.getDomainObject() == null) {
				onChiudi();
			}
		}
	}
	
	@Command
	def onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################
	
	///
	/// *** Attiva arrotondamento impostata
	///
	def impostaArrotondamentiTributo() {
		
		arrotondamentoCR = listArrotondamenti.find { it.codice == arrotondamentiTributo.arrConsistenzaReale }
		arrotondamentoCT = listArrotondamenti.find { it.codice == arrotondamentiTributo.arrConsistenza }
		
		BindUtils.postNotifyChange(null, null, this, "arrotondamentiTributo")
		BindUtils.postNotifyChange(null, null, this, "arrotondamentoCR")
		BindUtils.postNotifyChange(null, null, this, "arrotondamentoCT")
	}
	
	///
	/// *** Completa arrotondamento prima di verifica e salvataggio
	///
	private def completaArrotondamentiTributo() {
		
		String message = ""
		boolean result = true;
		
		def report = [
			message : message,
			result : 0
		]
		
		arrotondamentiTributo.codiceTributo = codiceTributo; 
		if((arrotondamentiTributo.sequenza ?: 0) < 1) arrotondamentiTributo.sequenza = 1;
			
		arrotondamentiTributo.arrConsistenzaReale = arrotondamentoCR?.codice
		arrotondamentiTributo.arrConsistenza = arrotondamentoCT?.codice
		
		if(message.size() > 0) {
			
			report = [
				message : "Attenzione : \n\n" + message,
				result : 1
			]
			visualizzaReport(report, null);
			result = false;
		}
		
		return result;
	}
	
	///
	/// *** Verifica coerenza dati Scadenza
	///
	private def verificaArrotondamentiTributo() {
		
		String message = ""
		boolean result = true;
		
		def report = canoneUnicoService.verificaArrotondamentiTributo(arrotondamentiTributo, tipoTributo)
		if(report.result != 0) {
			message = report.message;
		}

		if(message.size() > 0) {
			
			report = [
				message : "Attenzione : \n\n" + message,
				result : 1
			]
			visualizzaReport(report, null);
			result = false;
		}
		
		return result;
	}
	
	///
	/// *** Visualizza report
	///
	def visualizzaReport(def report, String messageOnSuccess) {
	
		switch(report.result) {
			case 0 :
				if((messageOnSuccess ?: '').size() > 0) {
					String message = messageOnSuccess
					Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true);
				}
				break;
			case 1 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true);
				break;
			case 2 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 15000, true);
				break;
		}
		
		return;
	}
}
