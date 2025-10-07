package pratiche.denunce

import java.util.List;

import org.apache.commons.lang.StringUtils

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.AttributoOgco
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.AttributoOgcoDTO

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

class OggettoDatiNotaiViewModel  {
	
	// componenti
	Window self
	
	def oggettoContribuente
	
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						@ExecutionArgParam("oggettoContribuente") def ogco) {

		self = w
		
		oggettoContribuente = ogco
	}

	@Command
	onChiudi()  {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
