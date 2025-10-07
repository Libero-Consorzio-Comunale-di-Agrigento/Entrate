package archivio.dizionari

import it.finmatica.tr4.Tariffa
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.TariffaDTO
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioTariffaCUViewModel {

	// Services
	def springSecurityService
	
	CommonService commonService
	CanoneUnicoService canoneUnicoService
	CompetenzeService competenzeService

	// Componenti
	Window self
	def tariffaFormat = CanoneUnicoService.TARIFFA_FORMAT_PATTERN
	def riduzioneFormat = CanoneUnicoService.RIDUZIONE_FORMAT_PATTERN

	// Generali
	boolean aggiornaStato = false		/// Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh
	
	Short annoCorrente
	String tipoTributo
	
	// Dati
	def categoriaOnNew = null
	TariffaDTO tariffa
	boolean flagTariffaBase
	def labels
	def annoTributo
	
	def codiceTributo = null
	def categoriaTariffa = null
	def tipologiaTariffa = null
	def tipologiaSecondaria = null
	def tipologiaCalcolo = null
	
	// Comuni
	def listaAnni = null
	def listCodiciTributo = []
	def listTipologie = []
	def listCalcolo = []
	def listSecondaria = []
	List<CategoriaDTO> listCategorie = []
	
	boolean modificabile = false
	boolean esistente = false
	boolean duplicata = false

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("tipoTributo") String tt,
		 @ExecutionArgParam("annoTributo") def aa,
		 @ExecutionArgParam("categoria") def ct,
		 @ExecutionArgParam("tariffa") TariffaDTO tr,
		 @ExecutionArgParam("modifica") boolean md,
		 @ExecutionArgParam("duplica") boolean dp,
		 @ExecutionArgParam("duplicaDaAnno") Short dpa,
		 @ExecutionArgParam("copiaParticolare") boolean copiaParticolare) {

		this.self = w

		labels = commonService.getLabelsProperties('dizionario')

		annoCorrente = (aa != null) ? (aa as Short) : Calendar.getInstance().get(Calendar.YEAR)
		
		def tipoTributoSelected = competenzeService.tipiTributoUtenza().find{it.tipoTributo == tt}
		tipoTributo = tipoTributoSelected?.tipoTributo ?: ''
		modificabile = md
		
		listTipologie = []
		
		if(tipoTributo == 'CUNI') {
			listTipologie << [ codice : TariffaDTO.TAR_TIPOLOGIA_PERMANENTE, descrizione: "Permanente" ]
			listTipologie << [ codice : TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA, descrizione: "Temporaneo" ]
			listTipologie << [ codice : TariffaDTO.TAR_TIPOLOGIA_ESENZIONE, descrizione: "Esenzione" ]
		}
		else {
			listTipologie << [ codice : TariffaDTO.TAR_TIPOLOGIA_STANDARD, descrizione: "Standard" ]
		}
		
		listaAnni = canoneUnicoService.getElencoAnni()
		
		if(tr != null) {
			Tariffa tariffaRaw = tr.getDomainObject()
			///
			/// Serve un nuovo DTO per evitare che eventuali modifiche vengano mantenute dalla lista
			///
			if(tariffaRaw) {
				tariffa = tariffaRaw.toDTO(['categoria','categoria.codiceTributo'])
				tariffa.estraiFlag()
			}
			else {
				tariffa = tr
			}
			annoTributo = tariffa.anno
			esistente = true
		}
		else {
			tariffa = new TariffaDTO()
			annoTributo = annoCorrente
			esistente = false

			categoriaOnNew = ct
			
			if(tipoTributo != 'CUNI') {
				tariffa.tipologiaTariffa = TariffaDTO.TAR_TIPOLOGIA_STANDARD
				tariffa.tipologiaSecondaria = TariffaDTO.TAR_CALCOLO_LIMITE_CONSISTENZA
				tariffa.tipologiaCalcolo = TariffaDTO.TAR_SECONDARIA_NESSUNA
			}
		}

		if (dp && dpa) {
			copiaTariffaDaAnno(dpa as Short)
			return
		}
		if (dp) {
			initClonazione()
			return
		}
		if (copiaParticolare) {
			initCopiaParticolare()
			return
		}

		impostaTariffa(false)

	}

	void initClonazione() {
		tariffa = canoneUnicoService.duplicaTariffa(tariffa, true)
		esistente = false

		impostaTariffa()
	}

	void initCopiaParticolare() {
		tariffa = canoneUnicoService.duplicaTariffa(tariffa, false)
		esistente = false
		duplicata = true

		impostaTariffa()
	}

	/// Eventi interfaccia ######################################################################################################
						 
	@Command
	def onSelectAnno() {
	
		ricaricaCodiciTributo()
	}
	
	@Command
	def onSelectCodiciTributo() {
		
		ricaricaSecondaria(true)
		ricaricaZone(true)
	}
	
	@Command
	def onSelectTipologia() {
		
		ricaricaZone(true)
		
		ricaricaTipoCalcolo(true)
	}
	
	@Command
	def onSelectCalcolo() {
		
	}
 
	@Command
	def onSelectSecondaria() {
		
	}
 
	@Command
	def onSelectZona() {
		
	}
	
	@Command
	onSalva() {
		
		if(!completaTariffa()) return
		if(!verificaTariffa()) return
		
		def report = canoneUnicoService.salvaTariffa(tariffa)

		def savedMessage = "Salvataggio avvenuto con successo"
		visualizzaReport(report, savedMessage)
		
		if(report.result == 0) {
			aggiornaStato = true
        }
		
		if(report.result == 0) {
			
			if(duplicata) {
				duplicata = false
				BindUtils.postNotifyChange(null, null, this, "duplicata")
			}

			onChiudi()
		}
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzioni interne ######################################################################################################
		
	///
	/// *** Attiva tariffa impostata
	///
	def impostaTariffa(Boolean notifyChange = true) {
		
		codiceTributo = null
		
		ricaricaCodiciTributo()

        tipologiaTariffa = listTipologie.find { it.codice == tariffa.tipologiaTariffa }
		
		ricaricaZone(false)

		def codiceCategoria = (tariffa.categoria != null) ? tariffa.categoria.categoria : 0
		if((tipoTributo != 'CUNI') && (categoriaOnNew) && (codiceCategoria == 0)) {
			codiceCategoria = categoriaOnNew.categoria ?: 0
		}
        categoriaTariffa = listCategorie.find { it.categoria == codiceCategoria }
		
		ricaricaTipoCalcolo(false)
        tipologiaCalcolo = listCalcolo.find { it.codice == tariffa.tipologiaCalcolo }
		
		ricaricaSecondaria(false)
        tipologiaSecondaria = listSecondaria.find { it.codice == tariffa.tipologiaSecondaria }
		
		flagTariffaBase = (tariffa.flagTariffaBase ?: '-') == 'S'
		
		if(notifyChange) {
			
			BindUtils.postNotifyChange(null, null, this, "tariffa")
			
			BindUtils.postNotifyChange(null, null, this, "codiceTributo")
			BindUtils.postNotifyChange(null, null, this, "tipologiaTariffa")
			BindUtils.postNotifyChange(null, null, this, "categoriaTariffa")
			BindUtils.postNotifyChange(null, null, this, "tipologiaCalcolo")
			BindUtils.postNotifyChange(null, null, this, "tipologiaSecondaria")
			
			BindUtils.postNotifyChange(null, null, this, "modificabile")
			BindUtils.postNotifyChange(null, null, this, "esistente")
			BindUtils.postNotifyChange(null, null, this, "duplicata")
		}
	}
	
	///
	/// Altera tariffa copiando i dati da altra annualità
	///
	def copiaTariffaDaAnno(Short copiaDaAnno) {
		
		def report = canoneUnicoService.copiaTariffaDaAnnualita(tariffa, copiaDaAnno)
        //	esistente = esistente		// Mantiene lo status della tariffa originale
		
		impostaTariffa()

        visualizzaReport(report, "Copia eseguita !")
	}

	///
	/// *** Rilegge codici tributo
	///
	def ricaricaCodiciTributo() {
	
		Integer anno = null	/// annoTributo as Integer
		
		listCodiciTributo = canoneUnicoService.getCodiciTributoCombo(tipoTributo, anno)
		
		if(codiceTributo == null) {
			
			def codice = this.tariffa.categoria?.codiceTributo?.id ?: categoriaOnNew?.codiceTributo ?: 0
			if(codice != 0) {
				codiceTributo = listCodiciTributo.find { it.codice == codice }
			}
			else {
				codiceTributo = listCodiciTributo[0]
			}
		}
		
		BindUtils.postNotifyChange(null, null, this, "listCodiciTributo")
	}
	
	///
	/// *** Carica lista tipo calcolo in base a tipologia tariffa
	///
	def ricaricaTipoCalcolo(boolean select) {
		
		listCalcolo = []
		
		listCalcolo << [ codice : TariffaDTO.TAR_CALCOLO_LIMITE_CONSISTENZA, descrizione: "Consistenza" ]
		
		def tipologia = tipologiaTariffa?.codice ?: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE
		if(tipologia == TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA) {
			listCalcolo << [ codice : TariffaDTO.TAR_CALCOLO_LIMITE_GIORNI, descrizione: "Giornate" ]
		}
		
		BindUtils.postNotifyChange(null, null, this, "listCalcolo")
		
		if((select != false) && (tipologiaCalcolo != null)) {
			tipologiaCalcolo = listCalcolo.find { it.codice == tipologiaCalcolo.codice }
			BindUtils.postNotifyChange(null, null, this, "tipologiaCalcolo")
		}
	}
	
	///
	/// *** Carica lista tariffa secondaria
	///
	def ricaricaSecondaria(boolean select) {
		
		String tributoPrinc = codiceTributo?.tipoTributo ?: ''
		
		listSecondaria = []

        listSecondaria << [ codice : TariffaDTO.TAR_SECONDARIA_NESSUNA, descrizione: "Nessuno" ]
		
		if(tributoPrinc == 'ICP') {
			listSecondaria << [ codice : TariffaDTO.TAR_SECONDARIA_USOSUOLO, descrizione: "OCCUPAZIONE" ]
		}
		
		BindUtils.postNotifyChange(null, null, this, "listSecondaria")
		
		if((select != false) && (tipologiaSecondaria != null)) {
			tipologiaSecondaria = listSecondaria.find { it.codice == tipologiaSecondaria.codice }
			BindUtils.postNotifyChange(null, null, this, "tipologiaSecondaria")
		}
	}
	
	///
	/// *** Ricarica combo Zone
	///
	def ricaricaZone(boolean select) {
		
		def elencoCodici = []
		
		elencoCodici << [id : codiceTributo.codice ]
		
		List<CategoriaDTO> elencoCategorie = canoneUnicoService.getCategorie(elencoCodici)

        listCategorie = []
		
		switch(tipologiaTariffa?.codice) {
			default :
				break
            case TariffaDTO.TAR_TIPOLOGIA_STANDARD :
				listCategorie = elencoCategorie.findAll { it.categoria != 0 }
				break
            case TariffaDTO.TAR_TIPOLOGIA_PERMANENTE :
				listCategorie = elencoCategorie.findAll { it.flagGiorni == null && it.categoria != 99 }
				break
            case TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA :
				listCategorie = elencoCategorie.findAll { it.flagGiorni == 'S' && it.categoria != 99 }
				break
            case TariffaDTO.TAR_TIPOLOGIA_ESENZIONE :
				listCategorie = elencoCategorie.findAll { it.categoria == 99 }
				break
        }
		
		BindUtils.postNotifyChange(null, null, this, "listCategorie")

		if((select != false) && (categoriaTariffa != null)) {
			categoriaTariffa = listCategorie.find { it.categoria == categoriaTariffa.categoria }
			BindUtils.postNotifyChange(null, null, this, "categoriaTariffa")
		}
	}
	
	///
	/// *** Completa tariffa prima di verifica e salvataggio
	///
	private def completaTariffa() {
		
		String message = ""
		boolean result = true

        tariffa.anno = annoTributo as Short
        tariffa.categoria = categoriaTariffa
		
		if(tipoTributo == 'CUNI') {
			tariffa.tipologiaTariffa = tipologiaTariffa?.codice
			tariffa.tipologiaSecondaria = tipologiaSecondaria?.codice
			tariffa.tipologiaCalcolo = tipologiaCalcolo?.codice
		}
		else {
			tariffa.tipologiaTariffa = TariffaDTO.TAR_TIPOLOGIA_STANDARD
            tariffa.tipologiaSecondaria = TariffaDTO.TAR_CALCOLO_LIMITE_CONSISTENZA
            tariffa.tipologiaCalcolo = TariffaDTO.TAR_SECONDARIA_NESSUNA
        }

        tariffa.flagTariffaBase = (flagTariffaBase != false) ? 'S' : null
		
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
	private def verificaTariffa() {
		
		String message = ""
		boolean result = true

        def report = canoneUnicoService.verificaTariffa(tariffa, tipoTributo)
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
