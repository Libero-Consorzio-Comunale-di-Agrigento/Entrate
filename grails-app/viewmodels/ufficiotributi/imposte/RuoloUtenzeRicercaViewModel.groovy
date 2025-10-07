package ufficiotributi.imposte

import it.finmatica.tr4.imposte.FiltroRicercaListeDiCaricoRuoliUtenze

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class RuoloUtenzeRicercaViewModel {

	// componenti
	Window self
		
	def filtroPEC = [null] +
		[ codice: -1, descrizione : 'Tutti'] +
		[ codice: 1, descrizione : 'No'] +
		[ codice: 2, descrizione : 'Si\'']
		
	// parametri
	FiltroRicercaListeDiCaricoRuoliUtenze mapParametri
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("parRicerca") def parametriRicerca) {
		
		this.self 	= w
		
		mapParametri = parametriRicerca ?: new FiltroRicercaListeDiCaricoRuoliUtenze()
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}

	@Command
	onCerca() {
		
		Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
	}

	@Command
	onSvuotaFiltri() {
		
		mapParametri = new FiltroRicercaListeDiCaricoRuoliUtenze()
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}
	
	@Command
	onChiudi () {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
