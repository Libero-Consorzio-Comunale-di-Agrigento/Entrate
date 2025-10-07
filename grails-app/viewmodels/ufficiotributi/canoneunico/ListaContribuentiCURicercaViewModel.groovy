package ufficiotributi.canoneunico

import it.finmatica.tr4.soggetti.SoggettiService

import org.zkoss.bind.BindUtils;
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.UploadEvent;
import org.zkoss.zul.Window

class ListaContribuentiCURicercaViewModel {
	
	Window self
	
	// services
	SoggettiService soggettiService
	
	// modalità lista
	boolean listaVisibile = false
	def listaContribuenti
	def soggettoSelezionato
	
    def tipoContribuente = [null] + 
		[ codice: 1, descrizione : 'Canone Unico e correlati'] +
		[ codice: -1, descrizione : 'Tutti']
		
	def tipoContribuenteSelected
		
	// filtri
	def filtri = [
		cognomeNome:	"",
		cognome:		"",
		nome:			"",
		codFiscale:		"",
		contribuenteCU:	1,
		id:				null
	]
	
	// paginazione
	def pagingDetails = [
		activePage : 0,
		pageSize : 10,
		totalSize : 0
	];

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w
		     			, @ExecutionArgParam("filtri") def f) {
			 
		this.self 	= w
		
		if (f) {
			filtri = f
		}
		
		tipoContribuenteSelected = tipoContribuente.find { it != null && it.codice == filtri.contribuenteCU }
	}
	
	@Command
	onSvuotaFiltri() {
		
		filtri.cognomeNome	= ""
		filtri.cognome		= ""
		filtri.nome			= ""
		filtri.codFiscale	= ""
		filtri.indirizzo	= ""
		filtri.contribuenteCU = 1
		filtri.id			= null
		
		tipoContribuenteSelected = tipoContribuente.find { it != null && it.codice == filtri.contribuenteCU }
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "tipoContribuenteSelected")
	}
	
	@Command
	onCerca() {
		
		filtri.contribuenteCU = (tipoContribuenteSelected != null) ? tipoContribuenteSelected.codice : 1;
		
		Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: filtri])
	}
	
	@Command
	onChiudi() {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
