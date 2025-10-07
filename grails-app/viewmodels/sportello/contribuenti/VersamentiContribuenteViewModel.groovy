package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class VersamentiContribuenteViewModel  {

	// componenti
	Window self

	// services
	ContribuentiService contribuentiService

	// Modello
	SoggettoDTO soggetto
	String codFiscale
	def listaVersamenti
	// paginazione
	int activePage  = 0
	int pageSize    = 15
	int totalSize

	def versamenti

	def cbTributi = [
			TASI   : true
			, ICI  : true
			, TARSU: true
			, ICP  : true
			, TOSAP: true]

	def ultimoStato = ""

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("idSoggetto") long idSoggetto) {
		this.self = w
		if (idSoggetto > 0) {
			soggetto = Soggetto.get(idSoggetto).toDTO([
					"contribuenti",
					"comuneResidenza",
					"comuneResidenza.ad4Comune",
					"archivioVie",
					"stato"
			])

			if (soggetto.stato) {
				ultimoStato = soggetto.stato.descrizione
				if (soggetto.dataUltEve) {
					ultimoStato += " il " + soggetto.dataUltEve.format('dd/MM/yyyy')
				}
			}

			codFiscale = soggetto?.contribuente?.codFiscale
			caricaLista()

			this.cbTributi.TASI = versamenti.tipiTributi.TASI
			this.cbTributi.ICI = versamenti.tipiTributi.ICI
			this.cbTributi.TARSU = versamenti.tipiTributi.TARSU
			this.cbTributi.ICP = versamenti.tipiTributi.ICP
			this.cbTributi.TOSAP = versamenti.tipiTributi.TOSAP
		}
	}

	@Command onPaging() {
		caricaLista()
	}

	@Command
	onRefresh() {
		resetPaginazione()
		caricaLista()
	}

	@Command
	onOpenSituazioneContribuente() {
		def ni = Contribuente.findBySoggetto(soggetto.getDomainObject())?.soggetto?.id

		if (!ni) {
			Clients.showNotification("Contribuente non trovato."
					, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
			return
		}
		Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
	}

	@Command
	onChiudiPopup() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	@Command
	onChangeTipoTributo() {
		caricaLista()
	}

	@Command
	onExportXlsVersamenti() {
		List<String> listaTipi = []
		cbTributi.each {it-> if(it.value) listaTipi.add(it.key)}

		def versamenti = contribuentiService.versamentiContribuente(codFiscale,soggetto.cognomeNome,listaTipi,pageSize, activePage,true)
		listaVersamenti = versamenti.records
		totalSize = versamenti.totalCount

		BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
		BindUtils.postNotifyChange(null, null, this, "totalSize")
		BindUtils.postNotifyChange(null, null, this, "activePage")
		onExportXls(listaVersamenti)
	}

	private onExportXls(def lista) {


		Map fields = [
				  "codFiscale"            			 : "Codice Fiscale"
				, "cognomeNome"						 : "Cognome Nome"
				, "descrizioneTributo"               : "Tipo Tributo"
				, "anno"                             : "Anno"
				, "tipoPratica"              		 : "Tipo Pratica"
				, "tipoVersamento"                   : "Tipo Versamento"
				, "rata"                             : "Rata"
				, "importoVersato"                   : "Importo Versato"
				, "dataPagamento"                    : "Data Pagamento"
				, "ruolo"                            : "Ruolo"
				, "fabbricati"                       : "Fabbricati"
				, "terreniAgricoli"                  : "Terreni Agricoli"
				, "areeFabbricabili"                 : "Aree Fabbricabili"
				, "abPrincipale"                     : "Abitazione Principale"
				, "altriFabbricati"                  : "Altri Fabbricati"
				, "detrazione"                       : "Detrazione"
				, "rurali"                           : "Fabbricati Rurali"
				, "fabbricatiD"                      : "Fabbricati Uso Produttivo"
				, "fabbricatiMerce" 				 : "Fabbr.Merce"
				, "addizionalePro" 				 	 : "Add.TEFA"
				, "maggiorazioneTares"               : "Componenti Perequative"
				, "fonte"                            : "Fonte"
				, "chekCompensazione"                : "Compensazione"
		]

		String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.XLSX,
				FileNameGenerator.GENERATORS_TITLES.ELENCO_VERSAMENTI,
				[codFiscale: soggetto.contribuente.codFiscale])

		def formatters = [
				"anno"  : Converters.decimalToInteger,
				"rata": Converters.decimalToInteger,
				"ruolo"  : Converters.decimalToInteger,
				"fabbricati" : Converters.decimalToInteger,
				"fonte" : Converters.decimalToInteger
		]


		XlsxExporter.exportAndDownload(nomeFile, lista, fields,formatters)

	}

	private resetPaginazione() {
		activePage = 0
		totalSize = 0
	}

	private caricaLista() {
		List<String> listaTipi = []
		cbTributi.each {it-> if(it.value) listaTipi.add(it.key)}

		versamenti = contribuentiService.versamentiContribuente(codFiscale,soggetto.cognomeNome,listaTipi,pageSize, activePage,true)
		listaVersamenti = versamenti.records
		totalSize = versamenti.totalCount

		if(totalSize<=pageSize) activePage = 0

		BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
		BindUtils.postNotifyChange(null, null, this, "totalSize")
		BindUtils.postNotifyChange(null, null, this, "activePage")

	}

}
