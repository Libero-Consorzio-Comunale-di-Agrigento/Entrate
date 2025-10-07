package it.finmatica.zkutils

import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO

import org.zkoss.bind.annotation.AfterCompose
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.event.OpenEvent
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Checkbox
import org.zkoss.zul.Popup

class InfoPopup extends Popup {
	@Wire("flagPossesso")
	Checkbox flagPossesso
	
	@AfterCompose
	public void afterCompose(@ContextParam(ContextType.VIEW) Component view){
		Selectors.wireComponents(view, this, false);
	}
	public void onOpen(OpenEvent event) {
		Selectors.wireComponents(this, this, false);
		if (event.getReference() == null) {
			return; // popup close - noaction
		}
		AnomaliaPraticaDTO anomaliaPraticaDTO = (AnomaliaPraticaDTO)event.getReference().getValue()
//		println anomaliaPraticaDTO.oggettoContribuente.flagPossesso
//		flagPossesso.checked = anomaliaPraticaDTO.oggettoContribuente.flagPossesso
		// println event.getReference()
		// println event.getTarget()
	}
}
