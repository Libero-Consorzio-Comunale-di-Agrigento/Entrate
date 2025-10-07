package pratiche.denunce

import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.denunce.DenunceService

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

class SuccessioneViewModel  {
	
	// componenti
	Window self
	
	DenunceService denunceService
	
	Long idSuccessione
	Long idOggetto
	String tipoTributo
	String codFiscaleRiferimento
	
	def datiSuccessione = [
		idSuccessione : 0,
		ufficio : '',
		anno : 0,
		volume : 0,
		numero : 0,
		sottoNumero : 0,
		comune : '',
		tipoDichiarazione : '',
		dataMorte : '',
		codFiscale : '',
		cognomeNome : '',
		sesso : '',
		nascita : '',
		residenza : '',
		pratica : '',
		tipoTributo : ''
	]
	
	def listaImmobili = []
	def immobileSelezionato
	
	def listaEredi = []
	def eredeSelezionato

	// -> Preso paro paro da ElencoDenunceViewModel.groovy !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
    Map caricaPannello = ["ICI"  : ["zul": "/pratiche/denunce/denunciaImu.zul",  "lettura": true, daBonifiche: false],
                          "TARSU": ["zul": "/pratiche/denunce/denunciaTari.zul", "lettura": true, daBonifiche: false],
                          "TASI" : ["zul": "/pratiche/denunce/denunciaTasi.zul", "lettura": true, daBonifiche: false]
    ]

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("idSuccessione") Long sid,
						@ExecutionArgParam("idOggetto") Long oid,
						@ExecutionArgParam("tipoTributo") String tt,
						@ExecutionArgParam("codFiscaleRiferimento") String cfr) {

		self = w
		
		idSuccessione = sid
		idOggetto = oid
		tipoTributo = tt
		codFiscaleRiferimento = cfr
		
		def successioni = denunceService.getDatiSuccessione(idSuccessione, tipoTributo);
		if(successioni.size() > 0) {
			
			datiSuccessione = successioni[0]
		}
		
		listaImmobili = denunceService.getImmobiliSuccessione(idSuccessione, idOggetto);
		listaEredi = denunceService.getErediImmobile(idSuccessione, idOggetto, tipoTributo);
	}
						
	@Command
	onSelezioneImmobile() {
		
	}
	
	@Command
	onSelezioneErede() {
		
	}
	
	@Command
	onVisualizzaDenunciaErede() {
	
		String zul = caricaPannello[tipoTributo]["zul"]
		boolean lettura = caricaPannello[tipoTributo]["lettura"]
		creaPopup(zul, [pratica: eredeSelezionato.pratica, tipoRapporto: "D", lettura: lettura, daBonifiche: caricaPannello[tipoTributo]["daBonifiche"]])
	}

	@Command
	onChiudi()  {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
	
	///
	/// *** Crea PopUp
	///
	private void creaPopup(String zul, def parametri) {
		
		Window w = Executions.createComponents(zul, self, parametri)
		w.doModal()
	}
}
