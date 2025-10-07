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

class OggettiDaWebGisViewModel {

    OggettiService oggettiService
    IntegrazioneWEBGISService integrazioneWEBGISService
	
	def self

	/////////////////////////////////////////////////////////
	/// Generale
	List<FiltroRicercaOggetto> listaFiltri = []
	
	boolean listaOggettiVisibile = false;
	boolean listaImmobiliVisibile = false;
	
	/////////////////////////////////////////////////////////
	/// Oggetti
	def listaOggetti = []

	def oggettiSelezionati
	def oggettoSelezionato
	
	def pagingOggetti = [
		activePage : 0,
		pageSize : 10,
		totalSize : 0
	];

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
	
		listaOggetti = [:]
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
			
//			println "codCom : ${codCom}"
//			println "intIdCom : ${intIdCom}"
//			println "tipoCat : ${tipoCat}"
//			println "sezCat : ${sezCat}"
//			println "fogCat : ${fogCat}"
//			println "numCat : ${numCat}"
//			println "subCat : ${subCat}"
			
			if(tipoCat > tipoCatFilter) tipoCatFilter = tipoCat		// 0 -> Default, 10 -> Oggetti TR4, 20 -> Immobili Catasto
			
			filtro = new FiltroRicercaOggetto()
			filtro.sezione = sezCat;
			filtro.foglio = fogCat;
			filtro.numero = numCat;
			filtro.subalterno = subCat;
			
			listaFiltri << filtro
        }
		
		switch(tipoCatFilter) {
			default :
	//		case 0 :
				ricaricaListaOggetti();
				ricaricaListaImmobili();
				
				if(listaOggetti.size() == 0) {
					listaOggettiVisibile = false;
					listaImmobiliVisibile = true;
				}
				else {
					listaOggettiVisibile = true;
					if(listaImmobili.size() == 0) {
						listaImmobiliVisibile = false;
					}
					else {
						listaImmobiliVisibile = true;
					}
				}
				break;
			case 10 :
				ricaricaListaOggetti();
				listaOggettiVisibile = true;
				listaImmobiliVisibile = false;
				break;
			case 20 :
				ricaricaListaImmobili();
				listaOggettiVisibile = false;
				listaImmobiliVisibile = true;
				break;
		}
	}
		 
	@Command
	def onPagingOggetti() {
		
		ricaricaListaOggetti()
	}

	@Command
	def onRefreshOggetti() {
		
		pagingOggetti.activePage = 0;
		ricaricaListaOggetti()
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
	
	private def ricaricaListaOggetti() {
		
	   def totaleOggetti = oggettiService.listaOggetti(listaFiltri, pagingOggetti.pageSize, pagingOggetti.activePage, null)
	   listaOggetti = totaleOggetti.lista;
	   pagingOggetti.totalSize = totaleOggetti.totale;
	   
	   BindUtils.postNotifyChange(null, null, this, "listaOggetti")
	   BindUtils.postNotifyChange(null, null, this, "pagingOggetti")
   };
		
	private def ricaricaListaImmobili() {
		
	   def totaleImmobili = integrazioneWEBGISService.listaCatasto(listaFiltri, pagingImmobili.pageSize, pagingImmobili.activePage)
	   listaImmobili = totaleImmobili.records;
	   pagingImmobili.totalSize = totaleImmobili.totalCount;
	   
	   BindUtils.postNotifyChange(null, null, this, "listaImmobili")
	   BindUtils.postNotifyChange(null, null, this, "pagingImmobili")
	};
}
