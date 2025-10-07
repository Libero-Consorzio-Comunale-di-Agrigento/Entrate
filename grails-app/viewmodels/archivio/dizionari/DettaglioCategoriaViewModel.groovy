package archivio.dizionari

import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCategoriaViewModel {

	// Services
	def springSecurityService
	
	CanoneUnicoService canoneUnicoService
	CommonService commonService
	CompetenzeService competenzeService

	// Componenti
	Window self

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
	
	String tipoTributo
	def labels
	
	// Comuni
	def listCodiciTributo = []
	def codiceTributoSelected = null
	
	boolean modificabile = false
	boolean esistente = false
	boolean duplicata = false
	
	// Dati
	CategoriaDTO categoria
	Boolean flagDomestica
	Boolean flagGiorni

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("tipoTributo") String tt,
		 @ExecutionArgParam("categoria") CategoriaDTO cat,
		 @ExecutionArgParam("codiceTributo") Long ct,
		 @ExecutionArgParam("modifica") boolean md,
		 @ExecutionArgParam("duplica") boolean dp,
		 @ExecutionArgParam("copiaParticolare") boolean copiaParticolare) {

		this.self = w

		def tipoTributoSelected = competenzeService.tipiTributoUtenza().find{it.tipoTributo == tt}
		tipoTributo = tipoTributoSelected?.tipoTributo ?: ''
		modificabile = md
		
		if(cat != null) {
			categoria = cat
			esistente = true
		}
		else {
			categoria = new CategoriaDTO()
			if(ct) {
				categoria.codiceTributo = CodiceTributo.get(ct) ?.toDTO()
			}
			esistente = false
		}

		labels = commonService.getLabelsProperties('dizionario')

		if (dp) {
			initClonazione()
			return
		}

		if (copiaParticolare) {
			initCopiaParticolare()
			return
		}

		impostaCategoria()
	}

	def initClonazione() {
		categoria = canoneUnicoService.duplicaCategoria(categoria, true)
		esistente = false

		impostaCategoria()
	}

	def initCopiaParticolare() {
		categoria = canoneUnicoService.duplicaCategoria(categoria, false)
		esistente = false
		duplicata = true

		impostaCategoria()
	}
						 
	/// Eventi interfaccia ######################################################################################################
						 
	@Command
	def onSelectCodiceTributo() {
		
	}
	
	@Command
	onSalva() {
		
		if(completaCategoria() == false) return
		if(verificaCategoria() == false) return
		
		def report = canoneUnicoService.salvaCategoria(categoria)

		def savedMessage = "Salvataggio avvenuto con successo"
		visualizzaReport(report, savedMessage)
		
		if(report.result == 0) {
			aggiornaStato = true
        }
		
		if(report.result == 0) {
			
			duplicata = false
			BindUtils.postNotifyChange(null, null, this, "duplicata")

			onChiudi()
		}
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################
	
	///
	/// *** Attiva categoria impostata
	///
	def impostaCategoria() {
		
		codiceTributoSelected = null
		
		ricaricaCodiciTributo()

        flagDomestica = (categoria.flagDomestica ?: '-') == 'S'
		flagGiorni = (categoria.flagGiorni ?: '-') == 'S'
		
		BindUtils.postNotifyChange(null, null, this, "categoria")
		BindUtils.postNotifyChange(null, null, this, "flagDomestica")
		BindUtils.postNotifyChange(null, null, this, "flagGiorni")

		BindUtils.postNotifyChange(null, null, this, "codiceTributoSelected")
		
		BindUtils.postNotifyChange(null, null, this, "modificabile")
		BindUtils.postNotifyChange(null, null, this, "esistente")
		BindUtils.postNotifyChange(null, null, this, "duplicata")
	}

	///
	/// *** Rilegge codici tributo
	///
	def ricaricaCodiciTributo() {
	
		listCodiciTributo = canoneUnicoService.getCodiciTributoCombo(tipoTributo, null)
		
		if(codiceTributoSelected == null) {
			
			def codice = this.categoria.codiceTributo?.id ?: 0
			if(codice != 0) {
				codiceTributoSelected = listCodiciTributo.find { it.codice == codice }
			}
			else {
				codiceTributoSelected = listCodiciTributo[0]
			}
		}
		
		BindUtils.postNotifyChange(null, null, this, "listCodiciTributo")
	}
	
	///
	/// *** Completa tariffa prima di verifica e salvataggio
	///
	private def completaCategoria() {
		
		String message = ""
		boolean result = true

        CodiceTributoDTO codiceTributo = CodiceTributo.get(codiceTributoSelected?.codice ?: 0) ?.toDTO()
		
		categoria.codiceTributo = codiceTributo
		
		categoria.flagDomestica = (flagDomestica != false) ? 'S' : null
		categoria.flagGiorni = (flagGiorni != false) ? 'S' : null
		
		if(message.size() > 0) {
			
			message = "Attenzione : \n\n" + message
			Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }
		
		return result
    }
	
	///
	/// *** Verifica coerenza dati tariffa
	///
	private def verificaCategoria() {
		
		String message = ""
		boolean result = true

        def report = canoneUnicoService.verificaCategoria(categoria)
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
