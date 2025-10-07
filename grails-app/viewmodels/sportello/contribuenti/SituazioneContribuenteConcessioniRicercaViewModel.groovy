package sportello.contribuenti

import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4

import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.sportello.FiltroRicercaCanoni

import org.junit.After
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SituazioneContribuenteConcessioniRicercaViewModel {

	// Services
	def springSecurityService
	TributiSession tributiSession
	CanoneUnicoService canoneUnicoService

	// Componenti
	Window self

	Short anno
	FiltroRicercaCanoni filtri
	
    def filtriComuni = [
		comuneOggetto  : [
			denominazione : "",
			provincia : "",
			siglaProv : ""
		]
	]
	
	def listaTariffe = []
	
    def tipiEsenzione = [
		[	codice : 'S',	descrizione : 'Si'	 	],
		[	codice : 'N',	descrizione : 'No'		],
		[	codice : null,	descrizione : 'Tutto' 	],
    ]

    def filtroNullaOsta = [
		[	codice : 'S',	descrizione : 'Si'	 	],
		[	codice : 'N',	descrizione : 'No'		],
		[	codice : null,	descrizione : 'Tutto' 	],
    ]
		
	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("anno") def aa,
						 @ExecutionArgParam("filtri") def ff) {

		this.self = w
		
		filtri = (ff) ? ff : new FiltroRicercaCanoni()

		leggiDettagliComuneOggetto()

		def annoStr = aa ?: 'Tutti'
		if(annoStr == 'Tutti') {
			anno = Calendar.getInstance().get(Calendar.YEAR) as Short
		}
		else {
			anno = aa as Short
		}
		
		def filtriTariffe = [
			tipoTributo : 'CUNI',
			annoTributo : anno,
		]
		listaTariffe = canoneUnicoService.getElencoDettagliatoTariffe(filtriTariffe, true)
	}
						 
	/// Eventi interfaccia ######################################################################################################
	
	@Command
	onSvuotaFiltri() {
		
		filtri.pulisci()
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		
		leggiDettagliComuneOggetto()
	}
	
	@Command
	onCerca() {
		
		Events.postEvent(Events.ON_CLOSE, self,	[ status: "Cerca", filtri: filtri ])
	}
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
	
	@Command
	def onSelectComuneOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
		
		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			filtri.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			filtri.codCom = selectedComune.comune
		}
		else {
			filtri.codPro = null
			filtri.codCom = null
		}
		
		leggiDettagliComuneOggetto()
	}
	
    /// Funzioni private ######################################################################################################

	def  leggiDettagliComuneOggetto() {
		
		Ad4ComuneTr4 comune = null
		
		Long codPro = filtri.codPro as Long
		Integer codCom = filtri.codCom as Integer
		
		if (codCom != null && codPro != null) {
			comune = Ad4ComuneTr4.createCriteria().get {
				eq('provinciaStato', codPro)
				eq('comune', codCom)
			}
		}
		
		def comuneOggetto = filtriComuni.comuneOggetto 
		
		if(comune) {
			Ad4Comune ad4Comune = comune.ad4Comune
			
			comuneOggetto.denominazione = ad4Comune?.denominazione
			comuneOggetto.provincia = ad4Comune?.provincia?.denominazione
			comuneOggetto.siglaProv = ad4Comune?.provincia?.sigla
		}
		else {
			comuneOggetto.denominazione = ""
			comuneOggetto.provincia = ""
			comuneOggetto.siglaProv = ""
		}
		
		BindUtils.postNotifyChange(null, null, this, "filtriComuni")
	}
}
