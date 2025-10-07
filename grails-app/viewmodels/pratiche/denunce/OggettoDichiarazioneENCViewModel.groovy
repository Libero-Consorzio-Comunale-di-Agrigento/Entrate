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

class OggettoDichiarazioneENCViewModel  {
	
	// componenti
	Window self
	
	DenunceService denunceService
	
	def datoOggettoENC = [
		idDocumento : 0,
		dichiarazioneProgr : 0,
		tipoAttivita : 0,
		descrAttivita : "",
		corrispettivoMedio : 0.0,
		costoMedio : 0.0,
		rapportoSuperficie : 0.0,
		rapportoSupGG : 0.0,
		rapportoSoggetti : 0.0,
		rapportoSoggGG : 0.0,
		rapportoGiorni : 0.0,
		percImponibilita : 0.0,
		valoreAssoggettato : 0.0,
		valoreAssArt4 : 0.0,
		casellaRigoG : 0.0,
		casellaRigoH : 0.0,
		rapportoCmsCM : 0.0,
		valoreAssParziale : 0.0,
		valoreAssCompl : 0.0
	]
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("idOggPratica") Long idOggPratica,
						@ExecutionArgParam("tipoTributo") String tipoTributo) {

		self = w
		
		def dichiarazioniOggettoENC = denunceService.getDichiarazioniOggettoENC(idOggPratica, tipoTributo)
		if(dichiarazioniOggettoENC.size() > 0) {
			
			datoOggettoENC = dichiarazioniOggettoENC[0]
		}
	}

	@Command
	onChiudi()  {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
