package pratiche.violazioni

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class OggettiAccertabiliViewModel {

	// Componenti
	def self

	// Service
	CommonService commonService
	LiquidazioniAccertamentiService liquidazioniAccertamentiService
	
	// parametri
	String tipoTributo
	Short anno
	String codFiscale
	
	Boolean consentiNuovo
	Boolean consentiDaCessati
	
	ContribuenteDTO contribuente;
	String tipoTributoDescr

	// Modello
	def listaOggetti
	def oggettoSelezionato = null
	def oggettiSelezionati = null
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("tipoTributo") String tt,
						 @ExecutionArgParam("anno") Short aa,
						 @ExecutionArgParam("codFiscale") String cf,
						 @ExecutionArgParam("consentiNuovo") Boolean cn,
						 @ExecutionArgParam("consentiDaCessati") Boolean cc) {

		this.self = w
		
		this.tipoTributo = tt
		this.anno = aa
		this.codFiscale = cf
		
		this.consentiNuovo = cn
		this.consentiDaCessati = cc
		
		if (tipoTributo in ['ICI']) {
			this.self.setWidth("90%")
		} else {
			this.self.setWidth("900px")
		}

		TipoTributoDTO tipoTributoDTO = TipoTributo.get(this.tipoTributo)?.toDTO()
		this.tipoTributoDescr = tipoTributoDTO ?.getTipoTributoAttuale(this.anno)
		
		Contribuente contribuenteRaw = Contribuente.get(this.codFiscale);
		contribuente = contribuenteRaw.toDTO(['soggetto']); 
		
		caricalLista()
	}
						 
	def caricalLista() {
		
		listaOggetti = liquidazioniAccertamentiService.getOggettiAccertabili(this.tipoTributo, this.codFiscale, this.anno)
		
		oggettoSelezionato = null
		
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
	}

	@Command
	def onSelezionaOggetto() {
		
		Events.postEvent(Events.ON_CLOSE, self, [operazione: 'daSelezione', selezione: oggettoSelezionato])
	}
	
	@Command
	def onDaCessati() {
		
		Events.postEvent(Events.ON_CLOSE, self, [operazione: 'daCessato'])
	}

	@Command
	def onNuovo() {
		
		Events.postEvent(Events.ON_CLOSE, self, [operazione: 'daNuovo'])
	}

	@Command
	def onClose() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
