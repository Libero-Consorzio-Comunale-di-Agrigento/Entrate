package ufficiotributi.datiesterni

import java.util.Date;
import java.util.List;

import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.CfaAccTributi
import it.finmatica.tr4.CfaProvvisorioEntrataTributi
import it.finmatica.tr4.dto.CfaAccTributiDTO
import it.finmatica.tr4.dto.CfaProvvisorioEntrataTributiDTO
import it.finmatica.tr4.dto.datiesterni.FornituraAEDTO

import org.junit.After;
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class AssociazioneContabileViewModel {

	// Services
	def springSecurityService

	FornitureAEService fornitureAEService

	// Componenti
	Window self
	
	// Generali
	def listaAnniEserc = []
	def annoEsercSelected
	
	def listaAnniAcc = []
	def annoAccSelected
	
	List<CfaAccTributiDTO> listaNumeriAcc = []
	CfaAccTributiDTO accTributoSelected
	Boolean togliAccTributo = false
	List<CfaProvvisorioEntrataTributiDTO> listaProvvisori = []
	CfaProvvisorioEntrataTributiDTO provvisorioSelected
	Boolean togliProvvisorio = false
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w) {

		this.self = w
		
		Short annoFinale = Calendar.getInstance().get(Calendar.YEAR) as Short;
		Short annoIniziale = annoFinale - 1;
		
		listaAnniEserc = []
		for(def anno = annoFinale; anno >= annoIniziale; anno--) {
			listaAnniEserc << anno.toString()
		}
		annoEsercSelected = listaAnniEserc[0]
		
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
	def onSelezioneNumeroAcc() {
		
		togliAccTributo = false
		BindUtils.postNotifyChange(null, null, this, "togliAccTributo")
	}
	
	@Command
	def onCheckTogliAccTributo() {
		
		accTributoSelected = null
		BindUtils.postNotifyChange(null, null, this, "accTributoSelected")
	}
	
	@Command
	def onSelezioneProvvisorio() {
		
		togliProvvisorio = false
		BindUtils.postNotifyChange(null, null, this, "togliProvvisorio")
	}
	
	@Command
	def onCheckTogliProvvisorio() {
		
		provvisorioSelected = null
		BindUtils.postNotifyChange(null, null, this, "provvisorioSelected")
	}
	
	@Command
	def onApplica() {
		
		String message = ""
		
		if((accTributoSelected != null) && (togliAccTributo != false)) {
			message += "- Accertamento Contabile : selezionare Numero OPPURE spuntare Pulisci, non entrambe!"
		}
		if((provvisorioSelected != null) && (togliProvvisorio != false)) {
			message += "- Provvisorio : selezionare Numero OPPURE spuntare Pulisci, non entrambe!"
		}
		if((accTributoSelected == null) && (togliAccTributo == false) &&
			(provvisorioSelected == null) && (togliProvvisorio == false)) {
			message += "- Non e' stata impostata nessuna associazione ne operazione!"
		}

		if(!(message.isEmpty())) {
			
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true);
			return;
		}
		
		def impostazioni = [
			accertamento : accTributoSelected,
			togliAccTributo : togliAccTributo,
			provvisorio : provvisorioSelected,
			togliProvvisorio : togliProvvisorio
		]
		
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : true, impostazioni : impostazioni ])
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ aggiornaStato : false, impostazioni : null ])
	}
	
	/// Funzion interne ######################################################################################################
	
	///
	/// Ricarica elenco anni accertamenti contabili
	///
	def ricaricaElencoAnniAcc(Boolean selectAttivo) {
		
		annoAccSelected = null
		BindUtils.postNotifyChange(null, null, this, "annoAccSelected")
		
		listaAnniAcc = fornitureAEService.getListaAnniAcc(null, annoEsercSelected, false);
		BindUtils.postNotifyChange(null, null, this, "listaAnniAcc")
	}
	
	///
	/// Ricarica elenco accertamenti per anno
	///
	def ricaricaElencoNumeriAcc(Boolean selectAttivo) {
		
		accTributoSelected = null
		BindUtils.postNotifyChange(null, null, this, "accTributoSelected")
		
		Short annoAcc = (annoAccSelected ?: 0) as Short
		listaNumeriAcc = fornitureAEService.getListaNumeriAcc(null, annoEsercSelected, annoAcc, false);
		BindUtils.postNotifyChange(null, null, this, "listaNumeriAcc")
	}
	
	///
	/// Ricarica elenco provvisori
	///
	def ricaricaElencoProvvisori(Boolean selectAttivo) {
	
		provvisorioSelected = null
		BindUtils.postNotifyChange(null, null, this, "provvisorioSelected")
		
		listaProvvisori = fornitureAEService.getListaProvvisori(null)
		BindUtils.postNotifyChange(null, null, this, "listaProvvisori")
	}
	
	///
	/// *** Visualizza report
	///
	def visualizzaReport(def report, String messageOnSuccess) {
	
		switch(report.result) {
			case 0 :
				if((messageOnSuccess ?: '').size() > 0) {
					String message = messageOnSuccess
					Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true);
				}
				break;
			case 1 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true);
				break;
			case 2 :
				String message = report.message
				Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true);
				break;
		}
		
		return;
	}
}
