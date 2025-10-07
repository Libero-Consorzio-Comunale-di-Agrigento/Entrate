package ufficiotributi.canoneunico

import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ListaCanoniRicercaViewModel {

    // Services
    def springSecurityService
	CommonService commonService
    CanoneUnicoService canoneUnicoService
	CompetenzeService competenzeService
	OggettiService oggettiService
	
    // Componenti
    Window self

    TipoTributoDTO tipoTributo
    String annoTributo

    // Comuni
    def listOccupazione = [
            [codice: null, descrizone: null],
            [codice: TipoOccupazione.P.id, descrizione: TipoOccupazione.P.descrizione],
            [codice: TipoOccupazione.T.id, descrizione: TipoOccupazione.T.descrizione],
    ]
    def listStato = [
            [codice: null, descrizone: null],
            [codice: CanoneUnicoService.STATO_CONONE_NORMALE, descrizione: 'Normale'],
            [codice: CanoneUnicoService.STATO_CONONE_ANNOCORRENTE, descrizione: 'Anno corrente'],
            [codice: CanoneUnicoService.STATO_CONONE_BONIFICATO, descrizione: 'Chiuso o Bonificato'],
            [codice: CanoneUnicoService.STATO_CONONE_ANOMALO, descrizione: 'Anomalo'],
    ]
	
	def listaTariffe = []
    def tariffeSelezionate = []
	
    def listCodici = []
    def codiciSelezionati = []
	
    def filtriComuni = [
		comuneOggetto  : [
			denominazione : "",
			provincia : "",
			siglaProv : ""
		]
	]
	
	def filtri = [
            cognome          : "",
            nome             : "",
            codFiscale       : "",
			codContribuente  : null,
            tipoOccupazione  : null,
            statoOccupazione : null,
			//
			latitudineDa	 : null,
			latitudineA		 : null,
			longitudineDa	 : null,
			longitudineA	 : null,
    ]
	FiltroRicercaCanoni filtriAggiunti

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
         @ExecutionArgParam("annoTributo") String aa,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("filtri") def ff) {

        this.self = w

        annoTributo = aa
        tipoTributo = competenzeService.tipiTributoUtenza().find { it.tipoTributo == tt }

        filtri.nome = ff?.nome
        filtri.cognome = ff?.cognome
        filtri.codFiscale = ff?.codFiscale
		filtri.codContribuente = ff?.codContribuente
		
		filtriAggiunti = ff?.filtriAggiunti ?: new FiltroRicercaCanoni()
		
		leggiDettagliComuneOggetto()

        def filtriCodici = [
                tipoTributo: tt,
                fullList   : (annoTributo == 'Tutti') ? true : false
        ]
		listCodici = canoneUnicoService.getElencoDettagliatoCodiciTributo(filtriCodici)

        def tipoOccupazione = ff?.tipoOccupazione
        filtri.tipoOccupazione = listOccupazione.find { it.codice == tipoOccupazione }
        def statoOccupazione = ff?.statoOccupazione
        filtri.statoOccupazione = listStato.find { it.codice == statoOccupazione }

		aggiornaFiltriGeolocalizzazione()

        codiciSelezionati = []
		tariffeSelezionate = []
		
        def selezione = ff?.codiciTributo ?: []
        codiciSelezionati = aggiornaSelezionati(listCodici, selezione)
		
		ricaricaElencoTariffe()
		
		selezione = ff?.tipiTariffa ?: []
		tariffeSelezionate = aggiornaSelezionati(listaTariffe, selezione)
    }

    /// Eventi interfaccia ######################################################################################################

    @Command
    def onSelectOccupazione() {

    }

    @Command
    def onSelectStato() {

    }
	
	@Command
	def onSelectComuneOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
		
		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			filtriAggiunti.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			filtriAggiunti.codCom = selectedComune.comune
		}
		else {
			filtriAggiunti.codPro = null
			filtriAggiunti.codCom = null
		}
		
		leggiDettagliComuneOggetto()
	}
	
    @NotifyChange(["elencoCodiciSelezionati", "elencoCodiciSelezionatiToolTip", "elencoTariffeSelezionate", "elencoTariffeSelezionateToolTip"])
    @Command
    def onSelectCodiceTributo() {
		
		ricaricaElencoTariffe()
		
		def selezione = tariffeSelezionate?.collect { it.codice}
		tariffeSelezionate = aggiornaSelezionati(listaTariffe, selezione)
		BindUtils.postNotifyChange(null, null, this, "tariffeSelezionate")
    }

    String getElencoCodiciSelezionati() {

		String elenco = codiciSelezionati?.descrizioneFull?.join(", ")
		
		if(elenco.size() > 60) {
			elenco = codiciSelezionati?.codice?.join(", ")
		}

		return elenco
    }

    String getElencoCodiciSelezionatiToolTip() {

        return codiciSelezionati?.descrizioneFull?.join("\n")
    }

    @NotifyChange(["elencoTariffeSelezionate", "elencoTariffeSelezionateToolTip"])
    @Command
    def onSelectTariffa() {
		
    }

    String getElencoTariffeSelezionate() {

        String elenco = tariffeSelezionate?.descrizioneFull?.join(", ")
		
		if(elenco.size() > 60) {
			elenco = tariffeSelezionate?.nome?.join(", ")
		}

        return elenco
    }

    String getElencoTariffeSelezionateToolTip() {

		return tariffeSelezionate?.descrizioneFull?.join("\n")
    }

    @Command
	def onChangeDaLatitudineDa() {

		filtriAggiunti.latitudineDa = oggettiService.tryParseCoordinate(filtri.latitudineDa)
		filtri.latitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.latitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeDaLatitudineA() {

		filtriAggiunti.latitudineA = oggettiService.tryParseCoordinate(filtri.latitudineA)
		filtri.latitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.latitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeDaLongitudineDa() {

		filtriAggiunti.longitudineDa = oggettiService.tryParseCoordinate(filtri.longitudineDa)
		filtri.longitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.longitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeDaLongitudineA() {

		filtriAggiunti.longitudineA = oggettiService.tryParseCoordinate(filtri.longitudineA)
		filtri.longitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.longitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeALatitudineDa() {

		filtriAggiunti.aLatitudineDa = oggettiService.tryParseCoordinate(filtri.aLatitudineDa)
		filtri.aLatitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.aLatitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeALatitudineA() {

		filtriAggiunti.aLatitudineA = oggettiService.tryParseCoordinate(filtri.aLatitudineA)
		filtri.aLatitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.aLatitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeALongitudineDa() {

		filtriAggiunti.aLongitudineDa = oggettiService.tryParseCoordinate(filtri.aLongitudineDa)
		filtri.aLongitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.aLongitudineDa)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
	def onChangeALongitudineA() {

		filtriAggiunti.aLongitudineA = oggettiService.tryParseCoordinate(filtri.aLongitudineA)
		filtri.aLongitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.aLongitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
	}

    @Command
    def onSvuotaFiltri() {

		filtri = [
				cognome         : "",
				nome            : "",
				codFiscale      : "",
				codContribuente : null,
				tipoOccupazione : null,
				statoOccupazione: null
		]
		filtriAggiunti.pulisci()

		aggiornaFiltriGeolocalizzazione()
		
        BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtriAggiunti")
		
        codiciSelezionati = []
        BindUtils.postNotifyChange(null, null, this, "codiciSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoCodiciSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoCodiciSelezionatiToolTip")
		
		tariffeSelezionate = []
        BindUtils.postNotifyChange(null, null, this, "tariffeSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoTariffeSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoTariffeSelezionateToolTip")
		
		leggiDettagliComuneOggetto()
    }

    @Command
    onCerca() {
		
		if(validaRicerca() == false)
			return
			
        def filtriNow = filtri.clone()
		
		filtriNow.filtriAggiunti = filtriAggiunti

        filtriNow.tipoOccupazione = filtri.tipoOccupazione?.codice
        filtriNow.statoOccupazione = filtri.statoOccupazione?.codice

        def codiciTributo = []
        codiciSelezionati.each { codiciTributo << it.codice }
        filtriNow.codiciTributo = codiciTributo
		
		def tipiTariffa = []
        tariffeSelezionate.each { tipiTariffa << it.codice }
		filtriNow.tipiTariffa = tipiTariffa
		
        Events.postEvent(Events.ON_CLOSE, self, [status: "cerca", filtri: filtriNow])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    /// Funzioni private ######################################################################################################

	def aggiornaFiltriGeolocalizzazione() {

		filtri.latitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.latitudineDa)
		filtri.latitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.latitudineA)
		filtri.longitudineDa = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.longitudineDa)
		filtri.longitudineA = oggettiService.formatCoordinateSexagesimalNS(filtriAggiunti.longitudineA)
		
		BindUtils.postNotifyChange(null, null, this, "filtri")
	}

	def  leggiDettagliComuneOggetto() {
		
		Ad4ComuneTr4 comune = null
		
		Long codPro = filtriAggiunti.codPro as Long
		Integer codCom = filtriAggiunti.codCom as Integer
		
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
	
	def ricaricaElencoTariffe() {
	
		Short anno
		
		if(annoTributo == 'Tutti') {
			anno = Calendar.getInstance().get(Calendar.YEAR) as Short
		}
		else {
			anno = annoTributo as Short
		}
		
		def elencoCodici = codiciSelezionati?.collect { it.codice as Long}
		def numCodici = (elencoCodici ?: []).size()

		def filtriTariffe = [
			tipoTributo : 'CUNI',
			annoTributo : anno,
			elencoCodici : elencoCodici
		]
		listaTariffe = canoneUnicoService.getElencoDettagliatoTariffe(filtriTariffe, (numCodici != 1)) 

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
	}
	
	///
	/// Valida parametri ricerca -> restituisce true se ok
	///
	def validaRicerca() {
		
		String message = ""

		def da
		def a
		
		da = filtriAggiunti.daKMDa ?: 0
		a = filtriAggiunti.daKMA ?: 9999999
		if(da > a) {
			message += "Da KM 'da' non puo' essere superiore a Da KM 'a'\n"
		}
		da = filtriAggiunti.aKMDa ?: 0
		a = filtriAggiunti.aKMA ?: 9999999
		if(da > a) {
			message += "A KM 'da' non puo' essere superiore ad A KM 'a'\n"
		}

		da = filtriAggiunti.latitudineDa ?: -90
		a = filtriAggiunti.latitudineA ?: 90
		if(da > a) {
			message += "Latitudine Da 'da' non puo' essere superiore a Latitudine 'a'\n"
		}
		da = filtriAggiunti.longitudineDa ?: -180
		a = filtriAggiunti.longitudineA ?: 180
		if(da > a) {
			message += "Longitudine Da 'da' non puo' essere superiore a Longitudine 'a'\n"
		}

		da = filtriAggiunti.concessioneDa ?: 0
		a = filtriAggiunti.concessioneA ?: 9999999
		if(da > a) {
			message += "Num.Concessione 'dal' non puo' essere superiore a Num.Concessione 'al'\n"
		}
	
		if (message) {
			Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
			return false
		}
		
		return true
	}

    ///
    /// *** Aggiorna selezionati x codice da lista
    ///
    private def aggiornaSelezionati(def lista, def selezionati) {

        def listaSelezionati = []

        selezionati.each {

            def codice = it
            def selezione = lista.find { it.codice == codice }

            if (selezione) {
                listaSelezionati << selezione
            }
        }

        return listaSelezionati
    }
}
