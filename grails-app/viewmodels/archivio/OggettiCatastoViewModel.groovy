package archivio

import java.util.List;

import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window
import org.zkoss.zhtml.Messagebox;

class OggettiCatastoViewModel {

    OggettiService oggettiService
    IntegrazioneWEBGISService integrazioneWEBGISService
	
	def self

	/////////////////////////////////////////////////////////
	/// Generale
	List<FiltroRicercaOggetto> listaFiltri = []
	
	/////////////////////////////////////////////////////////
	/// Catasto
	def listaImmobili = []

	def immobiliSelezionati
	def immobileSelezionato
	
	def pagingImmobili = [
		activePage : 0,
		pageSize : 10,
		totalSize : 0
	];

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
		 @ExecutionArgParam("idOggetti") def idOggetti) {

		this.self = w
		
		FiltroRicercaOggetto filtro
	
		listaImmobili = [:]
		if(idOggetti == null) idOggetti = "";
		
		def elencoOggetti = integrazioneWEBGISService.parseElencoOggetti(idOggetti)
		
		listaFiltri = []
		
		Integer tipoCatFilter = 0
		
		elencoOggetti.each {
			
			String codCom = it.codCom;
			String intIdCom = it.intIdCom;
			Integer tipoCat = it.tipoCat;
			String sezCat = it.sezCat;
			String fogCat = it.fogCat;
			String numCat = it.numCat;
			String subCat = it.subCat;
			
			filtro = new FiltroRicercaOggetto()
			filtro.sezione = sezCat;
			filtro.foglio = fogCat;
			filtro.numero = numCat;
			filtro.subalterno = subCat;
			
			listaFiltri << filtro
        }
		
		ricaricaListaImmobili();
	}
		 
	@Command
	def onPagingImmobili() {
		
		ricaricaListaImmobili()
	}

	@Command
	def onRefreshImmobili() {
		
		pagingImmobili.activePage = 0;
		ricaricaListaImmobili()
	}

	@Command
	def onChiudi() {
		
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
	
	private def ricaricaListaImmobili() {
		
	   def totaleImmobili = integrazioneWEBGISService.listaCatasto(listaFiltri, pagingImmobili.pageSize, pagingImmobili.activePage)
	   listaImmobili = totaleImmobili.records;
	   pagingImmobili.totalSize = totaleImmobili.totalCount;
	   
	   BindUtils.postNotifyChange(null, null, this, "listaImmobili")
	   BindUtils.postNotifyChange(null, null, this, "pagingImmobili")
	};
}
