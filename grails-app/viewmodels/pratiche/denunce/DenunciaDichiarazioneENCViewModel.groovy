package pratiche.denunce

import java.util.List;

import org.apache.commons.lang.StringUtils

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO

import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.EventQueue
import org.zkoss.zk.ui.event.EventQueues
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DenunciaDichiarazioneENCViewModel  {
	
	// componenti
	Window self
	
	DenunceService denunceService
	
	def datiDichiarazione = [
		idDocumento : 0,
		dichiarazioneProgr : 0,
		dichiarazioneAnno : 0,
		annoImposta : 0,
		numImmobiliA : 0,
		numImmobiliB : 0,
		dovutoIMU : 0.0,
		eccedenzaDicPrecIMU : 0.0,
		eccedenzaDicPrecF24IMU : 0.0,
		rateIMUVersate : 0.0,
		debitoIMU : 0.0,
		creditoIMU : 0.0,
		dovutoTASI : 0.0,
		eccedenzaDicPrecFTASI : 0.0,
		eccedenzaDicPrecF24TASI : 0.0,
		rateVersateTASI : 0.0,
		debitoTASI : 0.0,
		creditoTASI : 0.0,
		creditoIMUDicPresente : 0.0,
		creditoIMURimborso : 0.0,
		creditoIMUCompensazione : 0.0,
		creditoTASIDicPresente : 0.0,
		creditoTASIRimborso : 0.0,
		creditoTASICompensazione : 0.0
	]
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("idPratica") Long idPratica,
						@ExecutionArgParam("tipoTributo") String tipoTributo) {

		self = w
		
		def dichiarazioniENC = denunceService.getDichiarazioniENC(idPratica, tipoTributo)
		if(dichiarazioniENC.size() > 0) {
			
			datiDichiarazione = dichiarazioniENC[0]
		}
	}

	@Command
	onChiudi()  {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
