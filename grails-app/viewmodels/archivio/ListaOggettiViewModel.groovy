package archivio

import document.FileNameGenerator
import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.oggetti.oggettiPertinenza.OggettiPertinenzaService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class ListaOggettiViewModel {

	// Componenti
	Window self

	//Servizi
	OggettiService oggettiService
	OggettiPertinenzaService oggettiPertinenzaService
	ContribuentiService contribuentiService
	IntegrazioneWEBGISService integrazioneWEBGISService

	// Modello
	// paginazione
	int activePage  = 0
	int pageSize 	= 30
	int totalSize

	// ricerca
	String testoCerca  = ""
	def parRicerca

	//combo tipo e categoria
	def listaCategorieCatasto
	def listaTipiOggetto

	//filtri
	boolean	filtroAttivo 	  = false
	boolean tipoTributoAttivo = false
	boolean tipoPraticaAttivo = false

	def filtri = [ 	  tipoOggetto: null
					, classeCatasto: null
					, inPratica:  "no"
					, cbTributi: [ TASI: 		null
						, IMU:		null
						, TARI: 		null
						, COSAP:		null
						, PUBBLICITA:	null
						, tipoTributoAttivo: false ]
					, cbTipiPratica: [
						  D:	null				// dichiarazione D
						, A:	null				// accertamento A
						, L:	null 				// liquidazione L
						, tipoPraticaAttivo: false ]
	]

	List<FiltroRicercaOggetto> listaFiltri

	def listaOggetti
	def oggettoSelezionato
	def listaAnni

	//Funzioni di visualizzazione contestuale
	def cbTributi = [
			TASI   : true
			, ICI  : true
			, TARSU: true
			, ICP  : true
			, TOSAP: true
	]

	//Mappe
	def abilitaMappe = false
	def zul

	//Dati metrici
	def datiMetriciTipologia = 'TARES'
	def datiMetriciTitolo
	def datiMetriciUiuSelezionata
	def datiMetriciTabSelezionata = 0
	def listaDatiMetrici
	def listaDatiMetriciIntestatari
	boolean showDatiMetriciOggetto = false

	//Locazioni
	SoggettoDTO soggetto
	boolean showLocazioniOggetto = false
	def listaContrattiLocazioni
	def locazioniOrderBy = [[property: 'anno', direction: 'desc'],
							[property: 'dataStipula', direction: 'desc'],
							[property: 'dataFine', direction: 'desc']]

	@Init init(@ContextParam(ContextType.COMPONENT) Window w) {
		this.self 	= w
		abilitaMappe = integrazioneWEBGISService.integrazioneAbilitata()
		zul = "/archivio/oggettiWebGisCruscotto.zul"
		listaTipiOggetto = TipoOggetto.list().toDTO()
		listaCategorieCatasto = CategoriaCatasto.findAllFlagReale().toDTO()
	}

	/*
	 	Usato per gestire la compatibilità dello zul situazioneContribuenteContrattiLocazioniGrid.zul
	 	condiviso con SituazioneContribuenteViemodel

	 */
	def codFiscale = null

	@Command onCerca() {
		caricaLista()
	}

	@Command onSvuota() {
		filtri.tipoOggetto	= null
		filtri.categoriaCatasto = null
		filtri.inPratica = "no"
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

	@Command openCloseFiltri() {
		Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self, [filtri: listaFiltri, listaVisibile: false, inPratica: true, ricercaContribuente: false])
		w.onClose {event ->
			if (event.data) {
				if(event.data.status == "Cerca") {
					listaFiltri = event.data.filtri
					activePage=0
					caricaLista()
				}
			}
			BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
		}
		w.doModal()
	}

	@Command onModifica(){
		Window w = Executions.createComponents("/archivio/oggetto.zul", self, [oggetto: oggettoSelezionato.id])
		w.onClose {
			caricaLista()
		}
		w.doModal()
	}

	@Command onAggiungi(){
		Window w = Executions.createComponents("/archivio/oggetto.zul", self, [oggetto: -1])
		w.onClose {
			caricaLista()
		}
		w.doModal()
	}

	@Command onRefresh() {
		caricaLista()
	}

	@Command
	onVisualizzaOggettiPerVia() {
		Window w = Executions.createComponents("/archivio/oggettiPerVia.zul", self,null)
		w.doModal()
	}

	@Command
	onVisualizzaOggettiPertinenza() {
		String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.JASPER,
				FileNameGenerator.GENERATORS_TITLES.OGGETTI_PERTINENZA,
				[:])
		def reportOggettiPertinenza = oggettiPertinenzaService.genera()

		if (reportOggettiPertinenza == null) {
			Clients.showNotification("La ricerca non ha prodotto alcun risultato.",Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
		} else {
			AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportOggettiPertinenza.toByteArray())
			Filedownload.save(amedia)
		}
	}

	@Command onVisualizzaInformazioniCatasto() {
		if (oggettoSelezionato) {
			Window w = Executions.createComponents("/sportello/contribuenti/informazioniCatastoCensuario.zul", null,  [oggetto: oggettoSelezionato])
			w.onClose {
				caricaLista()
			}
			w.doModal()
		}
	}

	@Command
	onVisualizzaResidentiInOggetto() {
		Window w = Executions.createComponents("/sportello/contribuenti/residentiOggetto.zul", self,[oggetto  : oggettoSelezionato.id])
		w.onClose {
			caricaLista()
		}
		w.doModal()
	}

	@Command
	onVisualizzaContribuentiOggetto() {
		if(oggettoSelezionato){

			Window w = Executions.createComponents("/sportello/contribuenti/contribuentiOggetto.zul", self,
					[
							oggetto  : oggettoSelezionato.id,
							pratica  : null,
							anno     : "Tutti"
					]
			)
			w.onClose {
				caricaLista()
			}
			w.doModal()
		}
	}

	@Command
	onVisualizzaPraticheOggetto() {
		Window w = Executions.createComponents("/pratiche/praticheOggetto.zul", self,[oggetto  : oggettoSelezionato.id])
		w.onClose {
			caricaLista()
		}
		w.doModal()
	}

	@Command
	onVisualizzaLocazioniOggetto() {
		def filtri = [
				sezione   : oggettoSelezionato.sezione,
				foglio    : oggettoSelezionato.foglio,
				numero    : oggettoSelezionato.numero,
				subalterno: oggettoSelezionato.subalterno
		]

		// Ricarca locazioni sull'oggetto
		listaContrattiLocazioni = contribuentiService.caricaLocazioni(filtri, [offset: 999999, activePage: 0], locazioniOrderBy).record
		showLocazioniOggetto = true
		BindUtils.postNotifyChange(null, null, this, "showLocazioniOggetto")
		BindUtils.postNotifyChange(null, null, this, "listaContrattiLocazioni")
	}

	@Command
	def caricaIntestatariUiu() {
		listaDatiMetriciIntestatari = datiMetriciUiuSelezionata.intestatari
		BindUtils.postNotifyChange(null, null, this, "listaDatiMetriciIntestatari")
	}

	@Command
	onVisualizzaDatiMetriciOggetto() {
		if(oggettoSelezionato) {

			datiMetriciTipologia = 'TARES'
			datiMetriciUiuSelezionata = null
			datiMetriciTabSelezionata = 0

			datiMetriciTitolo = "Oggetto: $oggettoSelezionato.id - Sez.: ${oggettoSelezionato.sezione ?: ''} - Fgl.: ${oggettoSelezionato.foglio ?: ''} - Num.: ${oggettoSelezionato.numero ?: ''} - Sub.: ${oggettoSelezionato.subalterno ?: ''}"

			def filtri = [
					sezione   : oggettoSelezionato.sezione,
					foglio    : oggettoSelezionato.foglio,
					numero    : oggettoSelezionato.numero,
					subalterno: oggettoSelezionato.subalterno,
					tipologia : datiMetriciTipologia
			]

			listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,[max:999999,offset:0,activePage:0],[[property: 'uiu.idUiu', direction: 'asc']]).record

			showDatiMetriciOggetto = true
			BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
			BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
			BindUtils.postNotifyChange(null, null, this, "datiMetriciTitolo")
			BindUtils.postNotifyChange(null, null, this, "datiMetriciUiuSelezionata")
			BindUtils.postNotifyChange(null, null, this, "datiMetriciTabSelezionata")
			BindUtils.postNotifyChange(null, null, this, "datiMetriciTipologia")
		}
	}

	@Command
	def onSelezionaDatiMetriciTipologia() {
		datiMetriciUiuSelezionata = null
		datiMetriciTabSelezionata = 0

		datiMetriciTitolo = "Oggetto: $oggettoSelezionato.id - Sez.: ${oggettoSelezionato.sezione ?: ''} - Fgl.: ${oggettoSelezionato.foglio ?: ''} Num.: ${oggettoSelezionato.numero ?: ''} Sub.: ${oggettoSelezionato.subalterno ?: ''}"

		def filtri = [
				sezione   : oggettoSelezionato.sezione,
				foglio    : oggettoSelezionato.foglio,
				numero    : oggettoSelezionato.numero,
				subalterno: oggettoSelezionato.subalterno,
				tipologia : datiMetriciTipologia
		]

		listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,[max:999999,offset:0,activePage:0],[[property: 'uiu.idUiu', direction: 'asc']]).record

		showDatiMetriciOggetto = true
		BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
		BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
		BindUtils.postNotifyChange(null, null, this, "datiMetriciTitolo")
		BindUtils.postNotifyChange(null, null, this, "datiMetriciUiuSelezionata")
		BindUtils.postNotifyChange(null, null, this, "datiMetriciTabSelezionata")
	}

	@Command
	def onCambiaOrdinamentoDatiMetrici(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
		listaDatiMetrici = listaDatiMetrici.sort {
			it."$valore"
		}
		if (!event.ascending) {
			listaDatiMetrici = listaDatiMetrici.reverse()
		}
		BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
	}

	@Command
	def onCambiaOrdinamentoDatiMetriciIntestatari(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
		listaDatiMetriciIntestatari = listaDatiMetriciIntestatari.sort {
			it."$valore"
		}
		if (!event.ascending) {
			listaDatiMetriciIntestatari = listaDatiMetriciIntestatari.reverse()
		}
		BindUtils.postNotifyChange(null, null, this, "listaDatiMetriciIntestatari")
	}

	@Command
	def onVisualizzaMappa() {
		if (oggettoSelezionato) {
			def oggettiDaVisualizzare = []
			if (zul.indexOf("Cruscotto") * zul.indexOf("Archivio") < 0) {
				oggettiDaVisualizzare << [tipoOggetto : oggettoSelezionato.tipoOggetto.tipoOggetto, sezione: oggettoSelezionato.sezione, foglio: oggettoSelezionato.foglio, numero: oggettoSelezionato.numero]
			} else {
				oggettiDaVisualizzare << [tipoOggetto : oggettoSelezionato.tipoOggetto.tipoOggetto, sezione: oggettoSelezionato.SEZIONE, foglio: oggettoSelezionato.FOGLIO, numero: oggettoSelezionato.NUMERO]
			}
			integrazioneWEBGISService.openWebGis(oggettiDaVisualizzare)
		}
		else {
			Messagebox.show("Attenzione :\n\nNessun oggetto selezionato","Problema di selezione", Messagebox.OK, Messagebox.EXCLAMATION)
			return
		}
	}

	@Command
	def onGeolocalizzaOggetto() {
		
		def oggetto = oggettoSelezionato

        String url = oggettiService.getGoogleMapshUrl(null, oggetto.latitudine, oggetto.longitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
	}

	boolean isFiltroAttivo() {
		listaFiltri? !listaFiltri.isEmpty():false
	}
	
	private caricaLista() {
		def lista = oggettiService.listaOggetti(listaFiltri, pageSize, activePage, ["archivioVie"])
		oggettoSelezionato = null
		listaOggetti = lista.lista
		totalSize = lista.totale
		BindUtils.postNotifyChange(null, null, this, "listaOggetti")
		BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
		BindUtils.postNotifyChange(null, null, this, "totalSize")
		BindUtils.postNotifyChange(null, null, this, "activePage")
	}
}
