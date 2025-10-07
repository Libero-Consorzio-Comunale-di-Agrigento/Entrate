package ufficiotributi.bonificaDati

import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class RiepilogoSostituzioniViewModel {

	Window self
	
	List riepilogoAnomalie
	
	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			  ,@ExecutionArgParam("anomalieSostituzione") List anomalieSostituzione) {
		this.self 	= w
		
		riepilogoAnomalie = anomalieSostituzione
	}
			  
	@Command onChiudi(){
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
