package sportello.contribuenti

import it.finmatica.tr4.datiesterni.CatastoCensuarioService

import org.zkoss.bind.BindUtils;
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class SoggettiACatastoRicercaViewModel {
	
	Window self
	
	// services
	CatastoCensuarioService catastoCensuarioService
	
	String cfSoggetto = "ZZZ"
	
	def listaSoggetti
	def soggettoSelezionato
	
	def soggettiSelezionati = [:]
	def selezionePresente = false;
	
	// filtri
	def filtri = [  cognome:				""
				  , nome:					""
				  , codiceFiscale: 			""
				  , codiceFiscaleEscluso:	""		/// Non da maschera
	]
	
	// paginazione
	def pagingDetails = [
		activePage : 0,
		pageSize : 15,
		totalSize : 0
	];

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w
			 , @ExecutionArgParam("cfSoggetto") def cfSoggetto) {
			 
		this.self 	= w
		
		if(cfSoggetto) {
			this.cfSoggetto = cfSoggetto
		}
		
		filtri.codiceFiscaleEscluso = this.cfSoggetto;
	}
	
	@Command
	onSvuotaFiltri() {
		
		filtri.codiceFiscaleEscluso = this.cfSoggetto;
		
		filtri.cognome  = ""
		filtri.nome		= ""
		filtri.codiceFiscale	= ""
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}
	
	@Command
	def onCerca() {
		
		caricaLista(true);
		resetMultiSelezione()
	}
	
	@Command
	def onRefresh() {
		
		caricaLista(true);
		resetMultiSelezione()
	}
	
	@Command
	def onPaging() {
		
		caricaLista();
	}
	
	@Command
	def onCheckSoggetto() {
		
		selezionePresente();
	}

	@Command
	def onCheckSoggetti() {

		selezionePresente()

		soggettiSelezionati = [:]

		// nessuna selezione -> selezionare tutti
		if (!selezionePresente) {
			
			def noPaging = [
				activePage : 0,
				pageSize : Integer.MAX_VALUE,
				totalSize : 0
			]
			
			def elenco = catastoCensuarioService.getProprietariNoCF(filtri, noPaging)
			def tuttiSoggetti = elenco.data
			
			tuttiSoggetti.each {
				soggettiSelezionati << [(it.ID_SOGGETTO): true]
			}
		}
		
		selezionePresente()

		BindUtils.postNotifyChange(null, null, this, "soggettiSelezionati")
	}

	@Command
	def onScegliSoggetti() {
		
		def idSoggetti = []
		Long idSoggetto;
		
		for ( s in soggettiSelezionati ) {
			
			if(s.value != false) {
				
				idSoggetto = s.key;
				if(!(idSoggetti.contains(idSoggetto))) {
					
					idSoggetti << [id: idSoggetto]
				}
			}
		}
		
		Events.postEvent(Events.ON_CLOSE, self,	[ status: "Sogggetti", idSoggetti: idSoggetti ])
	}
	
	@Command
	onChiudi() {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
	
	private resetMultiSelezione() {

		soggettiSelezionati = [:]
		selezionePresente = false
		BindUtils.postNotifyChange(null, null, this, "soggettiSelezionati")
		BindUtils.postNotifyChange(null, null, this, "selezionePresente")
	}

	private void selezionePresente() {

		selezionePresente = (soggettiSelezionati.find { k, v -> v } != null)
		BindUtils.postNotifyChange(null, null, this, "selezionePresente")
	}

	///
	/// Ricarica elenco in modalità lista
	///
	private caricaLista(def resetPaginazione = false) {
		
		if (resetPaginazione) {
			pagingDetails.activePage = 0
		}

		def elenco = catastoCensuarioService.getProprietariNoCF(filtri, pagingDetails)
		listaSoggetti = elenco.data
		pagingDetails.totalSize = elenco.totalCount
		
		BindUtils.postNotifyChange(null, null, this, "listaSoggetti")
		BindUtils.postNotifyChange(null, null, this, "pagingDetails")
	}
}
