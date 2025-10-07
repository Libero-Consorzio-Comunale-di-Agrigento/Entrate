package ufficiotributi.versamenti


import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.soggetti.SoggettiService
import it.finmatica.tr4.versamenti.FiltroRicercaVersamenti
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ElencoVersamentiRicercaViewModel {

	// services
	def    springSecurityService
	SoggettiService soggettiService

	// componenti
	Window self

	// dati
	String tipoTributo
	def lista
	def selected
	Date dataDefault = new Date().clearTime()
	Date aData = dataDefault
	
	// ricerca
	List<FonteDTO> listaFonti=[]
	def tipoPratica

	def listTipiVersamento = [
			[ codice : 'T',		descrizione: 'Tutti' ],
			[ codice : 'A',		descrizione: 'Acconto' ],
			[ codice : 'S',		descrizione: 'Saldo' ],
			[ codice : 'U',		descrizione: 'Unico' ],
	]

	def listTipiPratica = [
			[ codice : 'T',		descrizione: 'Tutti' ],
			[ codice : 'D',		descrizione: 'Dichiarazione' ],
			[ codice : 'L',		descrizione: 'Liquidazione/Infrazione' ],
			[ codice : 'A',		descrizione: 'Accertamento' ],
			[ codice : 'V',		descrizione: 'Ravvedimento' ],
			[ codice : 'C',		descrizione: 'Concessione' ],
			[ codice : 'O',		descrizione: 'Versamenti Ordinari' ]
	]

	def listaRate = [-1,0,1,2,3,4]

	def listaStatiPratica = []
	def listProgrDocVersamento = []
	FiltroRicercaVersamenti mapParametri

	@Init init(@ContextParam(ContextType.COMPONENT) Window w,
			   @ExecutionArgParam("tipoTributo") String tipoTributo,
			   @ExecutionArgParam("parRicerca") FiltroRicercaVersamenti parametriRicerca) {

		this.self 	= w
		this.tipoTributo = tipoTributo
		caricaListaFonti()
		caricaListaStatiPratica()
		mapParametri = parametriRicerca?:new FiltroRicercaVersamenti()
		ricaricaListProgDoc(true)
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}

	@Command onRefresh() {
		caricaListaFonti()
		caricaListaStatiPratica()
		ricaricaListProgDoc(true)
	}

	@Command onCerca() {
		Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
	}

	@Command svuotaFiltri() {
		mapParametri = new FiltroRicercaVersamenti()
		ricaricaListProgDoc(false)
		BindUtils.postNotifyChange(null, null, this, "mapParametri")
	}
	
	@Command onChiudi () {
		Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi"])
	}

	private void caricaListaStatiPratica() {
		List<TipoStato> elencoTipiStato = TipoStato.findAll();
		elencoTipiStato.sort { it.descrizione }

		listaStatiPratica = [
				[codice: null, descrizione: 'Tutti']
		]
		elencoTipiStato.each {
			def stato = [:]
			stato.codice = it.tipoStato;
			stato.descrizione = it.descrizione;
			listaStatiPratica << stato
		}
		BindUtils.postNotifyChange(null, null, this, "listaStatiPratica")
	}

	private void caricaListaFonti() {
		List<FonteDTO> elencoFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()
		listaFonti = [
				[ codice : -1,		descrizione: 'Tutte' ],
		]
		elencoFonti.each {
			def fonte = [:]
			fonte.codice = it.fonte;
			fonte.descrizione = (it.fonte as String) + " - " + it.descrizione;
			listaFonti << fonte
		}
		BindUtils.postNotifyChange(null, null, this, "listaFonti")
	}

	def ricaricaListProgDoc(boolean select) {

		def selezioneOld = mapParametri.progrDocVersamento?.codice;

		listProgrDocVersamento = [
				[	codice : -1,	descrizione : 'Tutti'	]
		]

		def elencoTributi = [tipoTributo]
		def elencoProgrDoc = soggettiService.getListaProgrDocPerTributi([tipoTributo])
		elencoProgrDoc.each {
			listProgrDocVersamento << it
		}

		if(select != false) {
			def selezione = selezioneOld ?: mapParametri.progrDocVersamento
			mapParametri.progrDocVersamento = listProgrDocVersamento.find { it.codice == selezione }
		}
		else {
			mapParametri.progrDocVersamento = null
		}

		BindUtils.postNotifyChange(null, null, this, "mapParametri")
		BindUtils.postNotifyChange(null, null, this, "listProgrDocVersamento")
	}
}
