package ufficiotributi.imposte

import it.finmatica.tr4.imposte.FiltroRicercaListeDiCaricoRuoliDetails
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class RuoloDettagliRicercaViewModel {

	// componenti
	Window self
		
    def filtroVersamenti = [null] + 
		[ codice: -1, descrizione : 'Tutti'] +
		[ codice: 10, descrizione : 'Con Versamenti (Qualsiasi)'] +
		[ codice: 11, descrizione : 'Con Versamenti spontanei'] +
		[ codice: 12, descrizione : 'Con Versamenti da compensazione'] +
		[ codice: 20, descrizione : 'Senza Versamenti']

    def filtroPEC = [null] + 
		[ codice: -1, descrizione : 'Tutti'] +
		[ codice: 1, descrizione : 'No'] +
		[ codice: 2, descrizione : 'Si\'']
		
	// parametri
	FiltroRicercaListeDiCaricoRuoliDetails mapParametri
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("parRicerca") def parametriRicerca) {
		
		this.self 	= w
		
		mapParametri = parametriRicerca ?: new FiltroRicercaListeDiCaricoRuoliDetails()
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}

	@Command
	onCerca() {
		
		Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
	}

	@Command
	onSvuotaFiltri() {
		
		mapParametri = new FiltroRicercaListeDiCaricoRuoliDetails()
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}
	
	@Command
	onChiudi () {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
