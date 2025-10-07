package ufficiotributi.datiesterni

import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.dto.CfaAccTributiDTO
import it.finmatica.tr4.dto.CfaProvvisorioEntrataTributiDTO
import it.finmatica.tr4.dto.datiesterni.FornituraAEDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioFornituraAEViewModel {

	// Services
	def springSecurityService

	FornitureAEService fornitureAEService

	// Componenti
	Window self
	
	// Generali
	boolean aggiornaStato = false
	
	FornituraAEDTO fornitura;
	def importoNetto
	def importoIfel
	def importoLordo
	
	Boolean modificabile = false
	Boolean esistente = false;
	Boolean duplica = false
	Boolean modificaIFEL = false;
	
	def listaAnniEserc = []
	def annoEsercSelected
	
	def listaAnniAcc = []
	def annoAccSelected
	
	List<CfaAccTributiDTO> listaNumeriAcc = []
	CfaAccTributiDTO accTributoSelected
	List<CfaProvvisorioEntrataTributiDTO> listaProvvisori = []
	CfaProvvisorioEntrataTributiDTO provvisorioSelected
	
	Boolean flagProvincia = false
	Long progrDoc = null

	def enteComunale  = [
		codPro : null,
		codCom : null,
		///
		denominazione : "",
		provincia : "",
		siglaProv : "",
		siglaCFis : ""
	]

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("fornitura") def ft,
						 @ExecutionArgParam("ifel") Boolean ifel,
						 @ExecutionArgParam("modificabile") Boolean md,
						 @ExecutionArgParam("duplica") Boolean dup) {

		this.self = w
		
		modificaIFEL = ifel;
		
		modificabile = md;
		duplica = (modificabile != false) ? dup : false;
		esistente = (md != false) && (dup == false);
		
		if(dup != false) {
			fornitura = fornitureAEService.duplicaFornitura(ft);
		}
		else {
			fornitura = ft
		}

		this.flagProvincia = fornitura.tipoRecord == 'D'
		this.progrDoc = fornitura.documentoCaricato.id
		
		importoNetto = fornitura.importoNetto
		importoIfel = fornitura.importoIfel
		importoLordo = fornitura.importoLordo
		
		Short annoFinale = Calendar.getInstance().get(Calendar.YEAR) as Short;
		Short annoIniziale = annoFinale - 1;
		
		listaAnniEserc = [ null ]
		for(def anno = annoFinale; anno >= annoIniziale; anno--) {
			listaAnniEserc << anno.toString()
		}
		annoEsercSelected = null

		inizializzaDettagliEnte(fornitura.codEnteComunale)
		
		ricaricaElencoAnniAcc(true);
		ricaricaElencoNumeriAcc(true);
		
		ricaricaElencoProvvisori(true);
	}
						 
	/// Eventi interfaccia ######################################################################################################
	
	@Command
	def onSelezioneAnnoEserc() {
		
		ricaricaElencoAnniAcc(true);
		ricaricaElencoNumeriAcc(true);
	}
	
	@Command
	def onSelezioneAnnoAcc() {
		
		ricaricaElencoNumeriAcc(true);
	}
	
    @Command
    onSelectCfaAccTributi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
	
        def selectedRecord = event.getData()
		if(selectedRecord?.numeroAcc != -1) {
			accTributoSelected = selectedRecord
		}
		else {
			accTributoSelected = null
		}
        BindUtils.postNotifyChange(null, null, this, "accTributoSelected")
    }

    @Command
    onSelectEnte(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			enteComunale.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			enteComunale.codCom = selectedComune.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}

		aggiornaDettagliEnte()
    }
	
	@Command
	def onElimina() {
	
		String messaggio = "Sicuri di voler eliminare la fornitura?"
		
		Messagebox.show(messaggio, "Attenzione",
			Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
			new org.zkoss.zk.ui.event.EventListener() {
				public void onEvent(Event e) {
					if (Messagebox.ON_YES.equals(e.getName())) {
						eliminaFornitura();
					}
				}
			}
		)
	}

	@Command
	def onDuplica() {
		
		if(completaFornitura() == false) return
		if(verificaFornitura() == false) return
		
		def report = fornitureAEService.salvaFornitura(fornitura);
		
		if(report.result == 0) {
			report.result = -1
		}

		String message = "Duplicazione eseguita."
		if(!flagProvincia) message += "\n\nSara\' necessario rieseguire la quadratura!";
		visualizzaReport(report, message)
		
		if(report.result <= 0) {
			aggiornaStato = true;
			onChiudi();
		}
	}
	
	@Command
	def onSalva() {
		
		if(completaFornitura() == false) return
		if(verificaFornitura() == false) return
		
		def report = fornitureAEService.salvaFornitura(fornitura);
		
		if(report.result == 0) {
			report.result = -1
		}

		String message = "Salvataggio eseguito con successo."
		if(!flagProvincia) message += "\n\nSara\' necessario rieseguire la quadratura!";
		visualizzaReport(report, message)
		
		if(report.result <= 0) {
			aggiornaStato = true;
		}
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : aggiornaStato ])
	}
	
	/// Funzion interne ######################################################################################################
	
	///
	/// Imposta valori in fornitura e salva
	///
	private def completaFornitura() {
		
		String message = ""
		boolean result = true;
		
		fornitura.importoNetto = importoNetto;
		fornitura.importoIfel = importoIfel;
		fornitura.importoLordo = importoLordo;
		
		fornitura.annoAcc = ((annoAccSelected != null) && (annoAccSelected != '')) ? annoAccSelected as Short : null
		fornitura.numeroAcc = ((accTributoSelected?.numeroAcc ?: 0) != 0) ? accTributoSelected.numeroAcc : null;
		
		fornitura.numeroProvvisorio = provvisorioSelected?.numeroProvvisorio;
		fornitura.dataProvvisorio = provvisorioSelected?.dataProvvisorio;
		
		if(message.size() > 0) {
			
			def report = [
				message : "Attenzione : \n\n" + message,
				result : 1
			]
			visualizzaReport(report, null)
			result = false;
		}
		
		return result;
	}
	
	///
	/// Esegue verifica dati fonritura
	///
	private def verificaFornitura() {
		
		boolean result = true;
		
		def report = fornitureAEService.verificaFornitura(fornitura)
		
		if(report.result != 0) {
			visualizzaReport(report, null)
			result = false;
		}
		
		return result;
	}
	
	///
	/// Elimina dato dal db
	///
	private def eliminaFornitura() {
			
		def report = fornitureAEService.eliminaFornitura(fornitura)
		
		if(report.result == 0) {
			report.result = -1
		}

		String message = "Dato eliminato."
		if(!flagProvincia) message += "\n\nSara\' necessario rieseguire la quadratura!";
		visualizzaReport(report, message)
		
		if(report.result <= 0) {
			aggiornaStato = true;
			onChiudi();
		}
	}
	
	///
	/// Ricarica elenco anni accertamenti contabili
	///
	def ricaricaElencoAnniAcc(Boolean selectAttivo) {
		
		listaAnniAcc = fornitureAEService.getListaAnniAcc(fornitura, annoEsercSelected, true)
		annoAccSelected = fornitura.annoAcc
		
		BindUtils.postNotifyChange(null, null, this, "annoAccSelected")
		BindUtils.postNotifyChange(null, null, this, "listaAnniAcc")
	}
	
	///
	/// Ricarica elenco accertamenti per anno
	///
	def ricaricaElencoNumeriAcc(Boolean selectAttivo) {
		
		Short annoAcc = (annoAccSelected ?: 0) as Short
		listaNumeriAcc = fornitureAEService.getListaNumeriAcc(fornitura, annoEsercSelected, annoAcc, true);

		if(selectAttivo && annoAcc) {
			accTributoSelected = listaNumeriAcc.find { it.numeroAcc == fornitura.numeroAcc }
		}
		else {
			accTributoSelected = null
		};
	
		BindUtils.postNotifyChange(null, null, this, "accTributoSelected")
		BindUtils.postNotifyChange(null, null, this, "listaNumeriAcc")
	}
	
	///
	/// Ricarica elenco provvisori
	///
	def ricaricaElencoProvvisori(Boolean selectAttivo) {
	
		listaProvvisori = fornitureAEService.getListaProvvisori(fornitura)
		
		if(selectAttivo) {
			provvisorioSelected = listaProvvisori.find { ((it.numeroProvvisorio == fornitura.numeroProvvisorio) && 
																	(it.dataProvvisorio == fornitura.dataProvvisorio)) }
		}
		else {
			provvisorioSelected = null
		};
	
		BindUtils.postNotifyChange(null, null, this, "provvisorioSelected")
		BindUtils.postNotifyChange(null, null, this, "listaProvvisori")
	}
	
	def inizializzaDettagliEnte(String siglaCFis) {

		if((siglaCFis != null) && (!siglaCFis.isEmpty())) {
			def comune = fornitureAEService.getComuneDaSiglaCFis(siglaCFis)

			enteComunale.codPro = (comune.provincia != null) ? comune.provincia.id : comune.stato.id
			enteComunale.codCom = comune.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}
		aggiornaDettagliEnte()
	}

	def aggiornaDettagliEnte() {

		Ad4ComuneTr4 comune = null
		
		Long codPro = enteComunale.codPro as Long
		Integer codCom = enteComunale.codCom as Integer
		
		if (codCom != null && codPro != null) {
			comune = Ad4ComuneTr4.createCriteria().get {
				eq('provinciaStato', codPro)
				eq('comune', codCom)
			}
		}
		
		if(comune) {
			Ad4Comune ad4Comune = comune.ad4Comune
			
			enteComunale.denominazione = ad4Comune?.denominazione
			enteComunale.provincia = ad4Comune?.provincia?.denominazione
			enteComunale.siglaProv = ad4Comune?.provincia?.sigla
			enteComunale.siglaCFis = ad4Comune?.siglaCodiceFiscale
		}
		else {
			enteComunale.denominazione = ""
			enteComunale.provincia = ""
			enteComunale.siglaProv = ""
			enteComunale.siglaCFis = ""
		}
		
        BindUtils.postNotifyChange(null, null, this, "enteComunale")
	}

	///
	/// *** Visualizza report
	///
	def visualizzaReport(def report, String messageOnSuccess) {
	
		switch(report.result) {
			case -1 :
				String message = messageOnSuccess
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 10000, true);
				break;
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
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 10000, true);
				break;
		}
		
		return;
	}
}
