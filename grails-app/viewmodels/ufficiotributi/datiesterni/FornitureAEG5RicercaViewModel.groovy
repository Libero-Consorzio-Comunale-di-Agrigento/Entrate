package ufficiotributi.datiesterni

import it.finmatica.tr4.imposte.datiesterni.*
import org.junit.After;
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class FornitureAEG5RicercaViewModel {

	// Services
	def springSecurityService

	// Componenti
	Window self

	FiltroRicercaFornitureAEG5 filtri
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("filtri") def ff) {

		this.self = w
		
		filtri = ff ?: new FiltroRicercaFornitureAEG5();
	}
						 
	/// Eventi interfaccia ######################################################################################################
	
	@Command
	onSvuotaFiltri() {
		
		filtri = new FiltroRicercaFornitureAEG5();
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtroAccertatoSelected")
		BindUtils.postNotifyChange(null, null, this, "filtroProvvisorioSelected")
	}
	
	@Command
	onCerca() {
		
		Events.postEvent(Events.ON_CLOSE, self,	[ status: "cerca", filtri: filtri ])
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
