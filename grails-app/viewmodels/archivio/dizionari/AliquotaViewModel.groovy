package archivio.dizionari

import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.AliquotaDTO
import it.finmatica.tr4.dto.TipoAliquotaDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class AliquotaViewModel {

	Window self
	CommonService commonService
	AliquoteService aliquoteService
	CompetenzeService competenzeService

	boolean lettura
	boolean inModifica

	TipoTributoDTO tipoTributo
	AliquotaDTO aliquota
	List<TipoAliquotaDTO> listaTipiAliquota

	Boolean flagAbPrincipale
	Boolean flagPertinenze
	Boolean flagFabbricatiMerce
	Boolean flagRiduzione

	Properties labels

	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			 , @ExecutionArgParam("tipoTributo") String tt
			 , @ExecutionArgParam("aliquota") AliquotaDTO al
			 , @ExecutionArgParam("modifica") boolean m
			 , @ExecutionArgParam("lettura") boolean lt) {

		this.self 	= w

		lettura = lt
		inModifica = m

		tipoTributo =  competenzeService.tipiTributoUtenza().find{it.tipoTributo == tt}
		listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll {it.tipoTributo.tipoTributo == tipoTributo.tipoTributo}

		if (!inModifica)
			if ( al == null){
				aliquota = new AliquotaDTO()
			} else {
				aliquota = al
			}
		else
			aliquota = al

		flagAbPrincipale = (aliquota.flagAbPrincipale ?: '-') == 'S'
		flagPertinenze = (aliquota.flagPertinenze ?: '-') == 'S'
		flagFabbricatiMerce = (aliquota.flagFabbricatiMerce ?: '-') == 'S'
		flagRiduzione = (aliquota.flagRiduzione ?: '-' == 'S')

		labels = commonService.getLabelsProperties('dizionario')
	}

    //@NotifyChange("aliquota")
	@Command onSalva() {

		aliquota.flagAbPrincipale = (flagAbPrincipale) ? 'S' : null
		aliquota.flagPertinenze = (flagPertinenze) ? 'S' : null
		aliquota.flagFabbricatiMerce = (flagFabbricatiMerce) ? 'S' : null
		aliquota.flagRiduzione = (flagRiduzione) ? 'S' : null

		if (!aliquota.anno) {
			def message = "Anno non valido"
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
			return
		}

		if (!aliquota.tipoAliquota) {
			def message = "Tipo Aliquota non valido"
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
			return
		}

		if (aliquota.aliquota == null) {
			def message = "Aliquota non valido"
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
			return
		}

		if (!inModifica && aliquoteService.existsAliquota(aliquota)) {
			String unformatted = labels.get('dizionario.notifica.esistente')
			def message = String.format(unformatted,
					labels.get('dizionario.aliquota.notifica.esistente.item'),
					"questo ${labels.get('dizionario.aliquota.label.estesa.anno')} e ${labels.get('dizionario.aliquota.label.estesa.tipoAliquota')}")

			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
			return
		}

		aliquoteService.salvaAliquota(aliquota, inModifica)

		def message = "Salvataggio avvenuto con successo"
		Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
		Events.postEvent(Events.ON_CLOSE, self, [chiudi: false])
	}

	@Command onChiudi () {
		Events.postEvent(Events.ON_CLOSE, self, [chiudi: true])
	}
}
