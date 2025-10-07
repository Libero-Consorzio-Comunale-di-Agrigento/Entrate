package archivio

import document.FileNameGenerator
import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.TipoUtilizzo
import it.finmatica.tr4.archivio.FiltroRicercaOggettoPerVia
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.oggetti.oggettipervia.OggettiPerViaService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window


class OggettiPerViaViewModel {
	Window self

	// paginazione bandbox
	int activePage  = 0
	int pageSize 	= 10
	int totalSize

	// services
	OggettiService oggettiService
	OggettiPerViaService oggettiPerViaService

	// dati
	def listaTipiOggetto = [:]
	def tipoOggetto
	def listaTipiUtilizzo = [:]
	def tipoUtilizzo
	FiltroRicercaOggettoPerVia filtroRicercaOggettoPerVia
	List<FiltroRicercaOggettoPerVia> listaFiltri = []
	List<CategoriaCatastoDTO> listaCategorieCatasto

	def cbTributi = [
			TASI   : true
			, ICI  : true
			, TARSU: true
			, ICP  : true
			, TOSAP: true]

	@Init init(@ContextParam(ContextType.COMPONENT) Window w) {
		this.self 	= w
		listaFiltri = []
		filtroRicercaOggettoPerVia = listaFiltri.empty? new FiltroRicercaOggettoPerVia(id: 0) : listaFiltri[0]

		listaTipiOggetto << [Tutti: '']
		OggettiCache.OGGETTI_TRIBUTO.valore.sort { it.tipoOggetto.tipoOggetto }.each {
			listaTipiOggetto << [(it.tipoOggetto.tipoOggetto): it.tipoOggetto.descrizione]
		}

		listaTipiUtilizzo << [Tutti: '']
		TipoUtilizzo.listOrderById().each {
			listaTipiUtilizzo << [(it.id): it.descrizione]
		}

		listaCategorieCatasto = CategoriaCatasto.findAllFlagReale(sort: "categoriaCatasto").toDTO()

		BindUtils.postNotifyChange(null, null, this, "listaTipiOggetto")
		BindUtils.postNotifyChange(null, null, this, "listaCategorieCatasto")
		BindUtils.postNotifyChange(null, null, this, "listaTipiUtilizzo")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggettoPerVia")
	}


	@Command onSvuotaFiltri() {
		filtroRicercaOggettoPerVia = new FiltroRicercaOggettoPerVia(id: 0)
		listaFiltri = []
		BindUtils.postNotifyChange(null, null, this, "listaFiltri")
		BindUtils.postNotifyChange(null, null, this, "listaCategorieCatasto")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggettoPerVia")
		BindUtils.postNotifyChange(null, null, this, "listaOggetti")
		BindUtils.postNotifyChange(null, null, this, "activePage")
		BindUtils.postNotifyChange(null, null, this, "totalSize")
	}

	@Command onCerca() {
		if (validaMaschera()) {
			String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.JASPER,
				FileNameGenerator.GENERATORS_TITLES.OGGETTO_PER_VIA,
				[:])
			def reportOggettoPerVia = oggettiPerViaService.genera(filtroRicercaOggettoPerVia.getListaCampiRicerca(this.cbTributi))

			if (reportOggettoPerVia == null) {
				Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
						Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
			} else {
				AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportOggettoPerVia.toByteArray())
				Filedownload.save(amedia)
			}
		}
	}

	@Command onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT)Event event){
		filtroRicercaOggettoPerVia.indirizzo  = (event.data.denomUff?:"")
		filtroRicercaOggettoPerVia.codiceVie  = (event.data.id?:"")
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggettoPerVia")
	}

	@Command onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	@Command onChangeEvento() {
		BindUtils.postNotifyChange(null, null, this, "listaOggetti")
	}

	@Command onChangeCategoria(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {
		if (event?.getValue() && !filtroRicercaOggettoPerVia.categoriaCatasto) {
			CategoriaCatastoDTO categoriaPers = new CategoriaCatastoDTO(categoriaCatasto: event.getValue())
			listaCategorieCatasto << categoriaPers
			filtroRicercaOggettoPerVia.categoriaCatasto = categoriaPers
		}
		BindUtils.postNotifyChange(null, null, this, "filtroRicercaOggettoPerVia")
		BindUtils.postNotifyChange(null, null, this, "listaCategorieCatasto")
	}

	private boolean validaMaschera() {
		def messaggi = [];
		LinkedHashMap<Object, Object> listaCampiRicerca = filtroRicercaOggettoPerVia.getListaCampiRicerca()

		if(listaCampiRicerca.get("rendita_da") && listaCampiRicerca.get("rendita_a") && (listaCampiRicerca.get("rendita_da")>listaCampiRicerca.get("rendita_a"))) {
			messaggi << ("Valori Rendita incoerenti")
		}

		if(listaCampiRicerca.get("cons_da") && listaCampiRicerca.get("cons_a") && (listaCampiRicerca.get("cons_da")>listaCampiRicerca.get("cons_a"))) {
			messaggi << ("Valori Consistenza incoerenti")
		}

		if (messaggi.size() > 0) {
			messaggi.add(0, "Impossibile ricercare:");
			Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true);
			return false;
		}

		return true;
	}
}
