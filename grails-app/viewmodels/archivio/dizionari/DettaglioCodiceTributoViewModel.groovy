package archivio.dizionari

import it.finmatica.tr4.ArrotondamentiTributo
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.ArrotondamentiTributoDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCodiceTributoViewModel {

	// Services
	def springSecurityService
	
	CanoneUnicoService canoneUnicoService
	CommonService commonService

	// Componenti
	Window self

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
	
	String tipoTributo
	
	def tipologiaTributo = null
	
	Boolean flagRuolo
	Boolean flagStampaCc
	Boolean flagCalcoloInteressi

	String codEntrata
	
	// Comuni
	def listTributi = [
		[ codice : 'ICP', descrizione: "PUBBL" ],
		[ codice : 'TOSAP', descrizione: "OSAP" ],
		[ codice : 'CUNI', descrizione: "CUNI" ],
	]
	def listGruppi = []
	def gruppoTributoSelected
	
	boolean modificabile = false
	boolean esistente = false
	def labels
	
	// Dati
	CodiceTributoDTO codiceTributo
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("tipoTributo") String tt,
						 @ExecutionArgParam("codiceTributo") CodiceTributoDTO ct,
						 @ExecutionArgParam("modifica") boolean md) {

		this.self = w
		
		tipoTributo = tt
		
		modificabile = md
		
		if(ct != null) {
			codiceTributo = ct
			esistente = true
		}
		else {
			codiceTributo = new CodiceTributoDTO()
			esistente = false
		}
		
		def elencoGruppi = canoneUnicoService.getListaGruppiTributo()
		
		listGruppi = [
			[	codice : null,	descrizione : '' 		]
		]
		
		elencoGruppi.each {
			
			def gruppo = [:]
			
			gruppo.codice = it.gruppoTributo
			gruppo.descrizione =  it.descrizione
			 
			gruppo.descrizioneGruppo = gruppo.codice + ' - ' + gruppo.descrizione
			
			listGruppi << gruppo
		}
		
		impostaCodiceTributo()
		labels = commonService.getLabelsProperties('dizionario')
	}
						 
	/// Eventi interfaccia ######################################################################################################
						 
	@Command
	def onSelectTipoTributo() {
		
	}
 
	@Command
	def onElimina() {
		
	}

	@Command
	def onAvanzate() {

		ArrotondamentiTributo arrotonamenti
		ArrotondamentiTributoDTO arrotonamentiDTO

		arrotonamenti = ArrotondamentiTributo.createCriteria().get {
			eq('codiceTributo', codiceTributo.getDomainObject())
			eq('sequenza', 1)
		}
		arrotonamentiDTO = (arrotonamenti != null) ? arrotonamenti.toDTO() : null

		Window w = Executions.createComponents(
				"/archivio/dizionari/dettaglioArrotondamentiTributo.zul",
				self,
				[
						tipoTributo : tipoTributo,
						codiceTributo : codiceTributo,
						arrotondamentiTributo : arrotonamentiDTO,
						modifica : modificabile
				]
		)
		w.doModal()
	}
	
	@Command
	def onSalva() {
		
		if(!completaCodiceTributo()) return
		if(!verificaCodiceTributo()) return

		//Trasformo la descrizione e il nome in maiuscolo prima di salvarli
		codiceTributo.descrizione = codiceTributo.descrizione.toUpperCase()
		codiceTributo.descrizioneRuolo = codiceTributo.descrizioneRuolo.toUpperCase()

		def report = canoneUnicoService.salvaCodiceTributo(codiceTributo)
		def savedMessage = "Salvataggio avvenuto con successo"
		if(report.result == 0) {
			
			List<CodiceTributoDTO> listaCodici = canoneUnicoService.getCodiciTributo(tipoTributo, null)
			
			def reportGlobal = canoneUnicoService.verificaCodiciTributo(tipoTributo, listaCodici, true)
			visualizzaReport(reportGlobal, savedMessage)
		}
		else {
			visualizzaReport(report, savedMessage)
		} 
		
		if(report.result == 0) {
			aggiornaStato = true
		}
		
		onChiudi()
	}
	
	@Command
	def onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################
	
	///
	/// *** Attiva codice tributo impostato
	///
	def impostaCodiceTributo() {
		
		tipologiaTributo = listTributi.find { it.codice == codiceTributo.tipoTributoPrec?.tipoTributo }
		
		def gruppoTributo = ''
		
		if((codiceTributo.gruppoTributo ?: '').size() > 0) {
			gruppoTributo = codiceTributo.gruppoTributo
		}
		else {
			gruppoTributo = codiceTributo.contoCorrente as String
		}
		gruppoTributoSelected = listGruppi.find { it.codice == gruppoTributo }
		
		flagRuolo = (codiceTributo.flagRuolo ?: '-') == 'S'
		flagStampaCc = (codiceTributo.flagStampaCc ?: '-') == 'S'
		flagCalcoloInteressi = (codiceTributo.flagCalcoloInteressi ?: '-') == 'S'
		
		BindUtils.postNotifyChange(null, null, this, "codiceTributo")

		BindUtils.postNotifyChange(null, null, this, "tipologiaTributo")
		BindUtils.postNotifyChange(null, null, this, "gruppoTributoSelected")
		
		BindUtils.postNotifyChange(null, null, this, "modificabile")
		BindUtils.postNotifyChange(null, null, this, "esistente")
	}
	
	///
	/// *** Completa codice tributo prima di verifica e salvataggio
	///
	private def completaCodiceTributo() {
		
		String message = ""
		boolean result = true
		
		TipoTributo tipoTributoDB
		String tipoTributoNow
		String tipoTributoPrec
		
		if(tipoTributo == 'CUNI') {
			tipoTributoNow = tipoTributo
			tipoTributoPrec = tipologiaTributo?.codice ?: '-'
			
			if(gruppoTributoSelected != null) {
				codiceTributo.contoCorrente = gruppoTributoSelected.codice as Integer
				codiceTributo.descrizioneCc = gruppoTributoSelected.descrizione
				codiceTributo.gruppoTributo = gruppoTributoSelected.codice
			}
			else {
				codiceTributo.contoCorrente = null
				codiceTributo.descrizioneCc = null
				codiceTributo.gruppoTributo = null
			}
		}
		else {
			tipoTributoNow = tipoTributo
			tipoTributoPrec = '-'
			
			codiceTributo.gruppoTributo = null
		}
		
		tipoTributoDB = TipoTributo.findByTipoTributo(tipoTributoNow)
		codiceTributo.tipoTributo = (tipoTributoDB != null)  ? tipoTributoDB.toDTO() : null
		tipoTributoDB = TipoTributo.findByTipoTributo(tipoTributoPrec)
		codiceTributo.tipoTributoPrec = (tipoTributoDB != null)  ? tipoTributoDB.toDTO() : null
		
		codiceTributo.flagRuolo = (flagRuolo != false) ? 'S' : null
		codiceTributo.flagStampaCc = (flagStampaCc != false) ? 'S' : null
		codiceTributo.flagCalcoloInteressi = (flagCalcoloInteressi != false) ? 'S' : null
		
		if(message.size() > 0) {
			
			message = "Attenzione : \n\n" + message
			Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
			result = false
		}
		
		return result
	}
	
	///
	/// *** Verifica coerenza dati Scadenza
	///
	private def verificaCodiceTributo() {
		
		String message = ""
		boolean result = true
		
		def report = canoneUnicoService.verificaCodiceTributo(codiceTributo, esistente)
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
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 15000, true)
				break
		}
		
		return
	}
}
