package archivio.dizionari

import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.Tariffa
import it.finmatica.tr4.TipoTributo

import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import org.hibernate.criterion.CriteriaSpecification

class CopiaTariffeDaAnnualitaViewModel {

	// Services
	def springSecurityService
	
	CanoneUnicoService canoneUnicoService

	// Componenti
	Window self

	TributiSession tributiSession
	
	List<Short> listaAnni = []
	Short annoSelected = null
	
	// Dati
	def impostazioni = [
		annoTributo : null,
		tipoTributo : null,
		codiceTributo : null,
		tariffaSingola : false,
		tipoTributoDes : "",
		codiceTributoDes : ""
	]
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
							 @ExecutionArgParam("impostazioni") def imp) {

		this.self = w
		
		if(imp) {
			impostazioni = imp;
		}
		
		listaAnni = canoneUnicoService.getAnnualitaInTariffe(impostazioni.tipoTributo)
		if(impostazioni.annoTributo) {
			def index = listaAnni.indexOf(impostazioni.annoTributo as Short)
			if(index >= 0) {
				listaAnni.remove(index)
			}
		}
		if(impostazioni.annoCopiaDa) {
			Short annoCopiaDa = impostazioni.annoCopiaDa as Short
			def index = listaAnni.indexOf(annoCopiaDa)
			if(index >= 0) {
				annoSelected = annoCopiaDa
			}
		}
		
		if((listaAnni.size() > 0) && (annoSelected == null)) {
			annoSelected = listaAnni[0]
		}
	}
							 
	@Command
	def onSelectAnno() {
		
	}

	@Command
	def onOK() {
		
		if(!annoSelected) {
			Clients.showNotification("Specificare l'anno da cui copiare", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
			return;	
		}
		
		Events.postEvent(Events.ON_CLOSE, self, [ annoOrigine : annoSelected ])
	}

	@Command
	def onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [ annoOrigine : null ])
	}
}
