package sportello.contribuenti

import it.finmatica.tr4.MotivoSgravio;
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.oggetti.OggettiService

import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire;
import org.zkoss.zul.Window

class RuoliEsgraviViewModel {

	Window self
	
	ContribuenteDTO contribuente
	def oggetto
	
	//Service
	OggettiService 		oggettiService
	ContribuentiService contribuentiService
	
	//ListBox
	def listRuoli
	def listSgravi
	def listMotiviSgravio
	
	def ruoloSelezionato
	def sgravioSelezionato
	
	@Init init(@ContextParam(ContextType.COMPONENT) Window w
				, @ExecutionArgParam("oggetto") def oggettoContribuente
				, @ExecutionArgParam("contribuente") def contribuenteOggetto) {
		this.self 	= w
		
		oggetto 	 = oggettoContribuente
		
		contribuente = contribuenteOggetto
		
		listRuoli = contribuentiService.getRuoliOggettoContribuente(oggetto.tipoTributo, contribuente.codFiscale, oggetto.oggetto, oggetto.pratica, oggetto.oggettoPratica)
	}
		
	@NotifyChange(["listSgravi"])		
	@Command onSelezionaRuolo() {
		
		listSgravi = contribuentiService.getSgraviOggettoContribuente(ruoloSelezionato.id, ruoloSelezionato.codFiscale, ruoloSelezionato.sequenza)
	}
	
	@NotifyChange(["listMotiviSgravio"])
	@Command onVisualizzaSgravio(@BindingParam("popup")Component popupSgravio) {
		listMotiviSgravio = MotivoSgravio.list().toDTO()
		popupSgravio.visible = true
	}
	
	@NotifyChange(["sgravioSelezionato"])
	@Command onChiudiPopupSgravio(@BindingParam("popup")Component popupSgravio) {
		sgravioSelezionato = null
		popupSgravio.visible = false
	}
	
	@Command onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
