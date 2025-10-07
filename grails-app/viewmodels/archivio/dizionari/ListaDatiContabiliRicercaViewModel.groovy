package archivio.dizionari

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.CfaAccTributi
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.TipoTributo
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.archivio.dizionari.FiltroRicercaDatiContabili
import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.soggetti.SoggettiService

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaDatiContabiliRicercaViewModel {

    // componenti
    Window self

    // services
    CommonService commonService
    CompetenzeService competenzeService
    DatiGeneraliService datiGeneraliService
    SoggettiService soggettiService
	FornitureAEService fornitureAEService

    // dati
    def lista
    def selected
    List<TipoTributoDTO> listaTipoTributo = []
    List<CodiceTributoDTO> listaCodiceTributo = []
    List<CodiceF24DTO> listaCodiceF24 = []
    List<TipoStatoDTO> listaTipoStato = []
    def listaAnniAcc
    def annoAcc
    List<CfaAccTributiDTO> listaNumeriAcc = []
    FiltroRicercaDatiContabili mapParametri
    CfaAccTributiDTO cfaAccTributo
    def codTributoF24

    def listaTipoImposta = [[codice: null, descrizione: '']
                            , [codice: 'O', descrizione: 'Ordinario']
                            , [codice: 'V', descrizione: 'Violazioni']
    ]

	def tipoOccupazioneSelected
	def listaTipiOccupazione = [
		[ codice: null, descrizione: '' ],
		[ codice: TipoOccupazione.P.id, descrizione: TipoOccupazione.P.descrizione ],
		[ codice: TipoOccupazione.T.id, descrizione: TipoOccupazione.T.descrizione ],
	]

    def listaTipoPratica

	Boolean flagProvincia = false

    /// Filtri per bandboxComuniFAE
	Long provStato
	Long progrDoc

	def enteComunale  = [
		codPro : null,
		codCom : null,
		///
		denominazione : "",
		provincia : "",
		siglaProv : "",
		siglaCFis : ""
	]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") FiltroRicercaDatiContabili parametriRicerca,
         @ExecutionArgParam("flagProvincia") Boolean fp) {

        this.self = w

        this.flagProvincia = fp

        if(this.flagProvincia) {
            this.provStato = datiGeneraliService.extractDatiGenerali().codProvincia
            this.progrDoc = 0
        }
        else {
            this.provStato = 0
            this.progrDoc = -1
        }

        Short anno = Calendar.getInstance().get(Calendar.YEAR)

        listaTipoPratica = [[codice: null, descrizione: '']] +
                TipoPratica.enumConstants
                        .findAll { it.order > -1 }
                        .sort { it.order }
                        .collect { [codice: it.tipoPratica, descrizione: it.descrizione] }

        def elencoTributiCompetenza = competenzeService.tipiTributoUtenza().collect { it.tipoTributo }
        def tipiTributo = soggettiService.getListaTributi(anno)
        tipiTributo = tipiTributo.findAll { it.codice in elencoTributiCompetenza }
        listaTipoTributo = [[codice: null, descrizione: '', nome: '']] + tipiTributo

        listaTipoStato = [new TipoStatoDTO([tipoStato: '', descrizione: ''])] + TipoStato.list().sort { it.descrizione }.toDTO()

        mapParametri = parametriRicerca ?: new FiltroRicercaDatiContabili()

        if (mapParametri.anno) {
            listaAnniAcc = [new CfaAccTributiDTO().annoAcc] + CfaAccTributi.createCriteria().listDistinct() {
                eq("esercizio", Integer.valueOf(mapParametri.anno))
                projections {
                    groupProperty("annoAcc")
                }
                order("annoAcc", "asc")
            }
            if (mapParametri.annoAcc && mapParametri.annoAcc != 0) {
                listaNumeriAcc = [new CfaAccTributiDTO()] + CfaAccTributi.createCriteria().listDistinct() {
                    eq("annoAcc", Short.valueOf(mapParametri.annoAcc))
                    order("numeroAcc", "asc")
                }?.toDTO()
            }
        }

        applicaParametri()

        listaCodiceTributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                .valore
                .findAll { it.tipoTributo?.tipoTributo == mapParametri.codiceTipoTributo }
                .sort { it.id }

        listaCodiceF24 = [new CodiceF24DTO()] + OggettiCache.CODICI_F24
                .valore
                .findAll { it.tipoTributo?.tipoTributo == mapParametri.codiceTipoTributo }
                .sort { it.tributo }
    }

    @Command
    def onSelect() {
    }

    @Command
    def onSelectTipiTributo() {
        if (mapParametri.codiceTipoTributo) {
            listaCodiceTributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == mapParametri.codiceTipoTributo }
                    .sort { it.id }

            listaCodiceF24 = [new CodiceF24DTO()] + OggettiCache.CODICI_F24
                    .valore
                    .findAll { it.tipoTributo?.tipoTributo == mapParametri.codiceTipoTributo }
                    .sort { it.tributo }

            mapParametri.tipoTributo = TipoTributo.findByTipoTributo(mapParametri.codiceTipoTributo)?.toDTO()
            mapParametri.tributo = listaCodiceTributo.get(0)
            mapParametri.codTributoF24 = listaCodiceF24.get(0).tributo
            codTributoF24 = listaCodiceF24.get(0).tributo
        } else {
            listaCodiceTributo = [new CodiceTributoDTO()]
            listaCodiceF24 = [new CodiceF24DTO()]
            listaTipoTributo = [[codice: null, descrizione: '', nome: '']]

            mapParametri.tipoTributo = listaTipoTributo.get(0).codice
            mapParametri.tributo = listaCodiceTributo.get(0)
            mapParametri.codTributoF24 = listaCodiceF24.get(0).tributo

        }

        BindUtils.postNotifyChange(null, null, this, "listaCodiceTributo")
        BindUtils.postNotifyChange(null, null, this, "listaCodiceF24")
        BindUtils.postNotifyChange(null, null, this, "dato")

        self.invalidate()
    }

    @Command
    def onSelezioneAnnoAcc() {
        if (mapParametri.annoAcc && mapParametri.annoAcc != 0) {
            listaNumeriAcc = [new CfaAccTributiDTO()] + CfaAccTributi.createCriteria().listDistinct() {
                eq("annoAcc", Short.valueOf(mapParametri.annoAcc))
                order("numeroAcc", "asc")
            }?.toDTO()
        } else {
            listaNumeriAcc = [new CfaAccTributiDTO()]
        }
        mapParametri.numeroAcc = listaNumeriAcc[0].numeroAcc
        BindUtils.postNotifyChange(null, null, this, "listaAnniAcc")
        BindUtils.postNotifyChange(null, null, this, "listaNumeriAcc")
        BindUtils.postNotifyChange(null, null, mapParametri, "*")

        applicaParametriAcc()
    }

    @Command
    def onChangeAnno() {

        // Forza la pulizia della combo che altrimenti verrebbe svuotata
        // ma rimarrebbe l'eticheta di un'eventuale selezione precedente.
        mapParametri.numeroAcc = listaNumeriAcc[0]?.numeroAcc
        BindUtils.postNotifyChange(null, null, this, "mapParametri")

        if (mapParametri.anno) {
            listaAnniAcc = [new CfaAccTributiDTO().annoAcc] + CfaAccTributi.createCriteria().listDistinct() {
                eq("esercizio", Integer.valueOf(mapParametri.anno))
                projections {
                    groupProperty("annoAcc")
                }
                order("annoAcc", "asc")
            }
        }

        listaNumeriAcc = []
        mapParametri.numeroAcc = null
        mapParametri.annoAcc = null

        BindUtils.postNotifyChange(null, null, this, "listaAnniAcc")
        BindUtils.postNotifyChange(null, null, this, "listaNumeriAcc")
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    onSelectCfaAccTributi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
	
        def selectedRecord = event.getData()
        cfaAccTributo = selectedRecord
        BindUtils.postNotifyChange(null, null, this, "cfaAccTributo")

        mapParametri.numeroAcc = cfaAccTributo?.numeroAcc
        if(mapParametri.numeroAcc == -1) mapParametri.numeroAcc = null
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    onCerca() {

        if(this.flagProvincia) {
		    mapParametri.codEnteComunale = enteComunale.siglaCFis
        }
        else {
		    mapParametri.codEnteComunale = ''
        }
        if(mapParametri.tipoTributo?.tipoTributo == 'CUNI') {
		    mapParametri.tipoOccupazione = tipoOccupazioneSelected?.codice
        }
        else {
		    mapParametri.tipoOccupazione = null
        }
        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    svuotaFiltri() {
        mapParametri = new FiltroRicercaDatiContabili()
        applicaParametri()
        BindUtils.postNotifyChange(null, null, this, "mapParametri")

        self.invalidate()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi"])
    }

    @Command
    onSelectEnte(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			enteComunale.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			enteComunale.codCom = selectedComune.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}

		aggiornaDettagliEnte()
    }
	
    def applicaParametri() {

        inizializzaDettagliEnte(mapParametri.codEnteComunale)

        applicaParametriAcc()

		tipoOccupazioneSelected = listaTipiOccupazione.find { it.codice == mapParametri.tipoOccupazione?.id }
        BindUtils.postNotifyChange(null, null, this, "tipoOccupazioneSelected")
    }

    def applicaParametriAcc() {

        Integer numeroAcc = mapParametri.numeroAcc as Integer

        if((mapParametri.annoAcc) && (numeroAcc)) {
            cfaAccTributo = listaNumeriAcc.find { it.numeroAcc == numeroAcc}
        }
        else {
            cfaAccTributo = null
        }

        BindUtils.postNotifyChange(null, null, this, "cfaAccTributo")
    }

	def inizializzaDettagliEnte(String siglaCFis) {

		if((siglaCFis != null) && (!siglaCFis.isEmpty())) {
			def comune = fornitureAEService.getComuneDaSiglaCFis(siglaCFis)

			enteComunale.codPro = comune?.provincia?.id ?: comune?.stato?.id
			enteComunale.codCom = comune?.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}
		aggiornaDettagliEnte()
	}

	def aggiornaDettagliEnte() {

		Ad4ComuneTr4 comune = null
		
		Long codPro = enteComunale.codPro as Long
		Integer codCom = enteComunale.codCom as Integer
		
		if (codCom != null && codPro != null) {
			comune = Ad4ComuneTr4.createCriteria().get {
				eq('provinciaStato', codPro)
				eq('comune', codCom)
			}
		}
		
		if(comune) {
			Ad4Comune ad4Comune = comune.ad4Comune
			
			enteComunale.denominazione = ad4Comune?.denominazione
			enteComunale.provincia = ad4Comune?.provincia?.denominazione
			enteComunale.siglaProv = ad4Comune?.provincia?.sigla
			enteComunale.siglaCFis = ad4Comune?.siglaCodiceFiscale
		}
		else {
			enteComunale.denominazione = ""
			enteComunale.provincia = ""
			enteComunale.siglaProv = ""
			enteComunale.siglaCFis = ""
		}
		
        BindUtils.postNotifyChange(null, null, this, "enteComunale")
	}
}
