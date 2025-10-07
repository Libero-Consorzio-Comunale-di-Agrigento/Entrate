package archivio.dizionari

import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.TipoAliquotaDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class TipoAliquotaViewModel {

	Window self
	
	AliquoteService aliquoteService
	CommonService commonService

		TipoTributoDTO tipoTributo
	TipoAliquotaDTO tipoAliquota// = new TipoAliquotaDTO()
	Integer annoInt
	
	boolean lettura
	boolean inModifica
	def labels
	
	@Init init(@ContextParam(ContextType.COMPONENT) Window w
							, @ExecutionArgParam("tipoTributo") TipoTributoDTO tt
							, @ExecutionArgParam("tipoAliquota") TipoAliquotaDTO ta
							, @ExecutionArgParam("modifica") boolean m
							, @ExecutionArgParam("lettura") boolean lt) {
							
		this.self 	= w
		
		lettura = lt
		inModifica = m
		tipoTributo =  tt
		
		if (!inModifica) {
			if (ta == null) {
				tipoAliquota = new TipoAliquotaDTO()
			} else {
				tipoAliquota = ta
			}
		} else {
			tipoAliquota = ta
		}

		tipoTributo.tipoTributo = tipoTributo.tipoTributo.trim()
		labels = commonService.getLabelsProperties('dizionario')
	}
	
	//@NotifyChange("tipoAliquota")
	@Command onSalva()	{
		//tipoAliquota = aliquoteService.salvaTipoAliquota(tipoTributo, tipoAliquota, inModifica)
		if (!tipoAliquota.tipoAliquota) {
			def message = "Aliquota non valida"
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
			return
		}
		if (!tipoAliquota.descrizione || tipoAliquota.descrizione.trim().isEmpty()) {
			def message = "Descrizione non valida"
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
			return
		}
		if (!inModifica && aliquoteService.existsTipoAliquota([tipoTributo: tipoTributo.tipoTributo,
												tipoAliquota: tipoAliquota.tipoAliquota])) {
			String unformatted = labels.get('dizionario.notifica.esistente')
			def message = String.format(unformatted, 'un Tipo Aliquota', 'questo Tipo Aliquota')
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
			return
		}

		aliquoteService.salvaTipoAliquota(tipoTributo, tipoAliquota, inModifica)
		def message = "Salvataggio avvenuto con successo"
		Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
		Events.postEvent(Events.ON_CLOSE, self, [chiudi: false])
	}
	
	@Command onChiudi () {
		Events.postEvent(Events.ON_CLOSE, self, [chiudi: true])
	}
}
