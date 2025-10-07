package ufficiotributi.bonificaDati

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.dto.anomalie.AnomaliaParametroDTO
import it.finmatica.tr4.dto.anomalie.TipoAnomaliaDTO
import it.finmatica.tr4.jobs.ControlloAnomalieJob

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

class ControlloAnomalieViewModel {

    Window self
    def springSecurityService

	CompetenzeService competenzeService
    CommonService commonService
	
    Short anno
    BigDecimal scarto = new BigDecimal(Integer.valueOf(0))
    BigDecimal renditaDa = new BigDecimal(Integer.valueOf(0))
    BigDecimal renditaA = new BigDecimal(Integer.valueOf(0))
    boolean visualizzaScarto
    boolean visualizzaRenditaCategoria
    List<TipoAnomaliaDTO> listaTipiAnomaliaSelezionati = [] //item a sinistra da passare a destra
    List<TipoAnomaliaDTO> listaTipiAnomalia = [] //selezionabili - a sinistra
    List<CategoriaCatastoDTO> listaCategorieCatasto
    List<CategoriaCatastoDTO> categorieSelezionate = []
    List<String> listaTipiTributoSelezionati = []

    List tipiAnomaliaErrore = []
    List tipiAnomaliaLanciati = []

	// Competenze
	def cbTributiAbilitati = [:]
	def cbTributiInScrittura = [:]

    Map cbTributi = ['TASI': false, 'ICI': true]
	
    Map tipiOggetto = [:]
    boolean daImposta = false
    boolean checkSistemate = false

    BonificaDatiService bonificaDatiService
    ControlloAnomalieService controlloAnomalieService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anno") Integer anno) {

        this.self = w
		
		verificaCompetenze()
		
        this.anno = anno ?: 1992
        listaTipiAnomalia = OggettiCache.TIPI_ANOMALIA.valore.findAll {
            it.tipoBonifica == "D" && it.tipoAnomalia <= 15
        }
        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale }
        visualizzaScarto = false
        visualizzaRenditaCategoria = false
        for (String tt in cbTributi.keySet()) {
            tipiOggetto[tt] = OggettiCache.OGGETTI_TRIBUTO.valore.findAll {
                it.tipoTributo.tipoTributo == tt
            }?.tipoOggetto?.tipoOggetto
        }
    }

    @Command
    onSelect() {
        visualizzaScarto = (listaTipiAnomaliaSelezionati.findAll {
            it.tipoAnomalia in [Short.valueOf("3"), Short.valueOf("8"), Short.valueOf("14"), Short.valueOf("15")]
        })
        BindUtils.postNotifyChange(null, null, this, "visualizzaScarto")

        visualizzaRenditaCategoria = (listaTipiAnomaliaSelezionati.findAll { it.tipoAnomalia in [Short.valueOf("6")] })
        BindUtils.postNotifyChange(null, null, this, "visualizzaRenditaCategoria")
    }

    @Command
    onControlla(@BindingParam("popup") Popup popupControlloFallito) {
        tipiAnomaliaLanciati = []
        tipiAnomaliaErrore = []
        if (listaTipiAnomaliaSelezionati.isEmpty()) {
            Clients.showNotification("Selezionare almeno un Tipo anomalia"
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }
		if((!cbTributi['IMU']) && (!cbTributi['TASI'])) {
			Clients.showNotification("Selezionare almeno un Tipo tributo"
				, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
			return
		}
        if (anno == null) {
            Clients.showNotification("Parametro mancante: anno."
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }
        if (visualizzaRenditaCategoria) {
            if (categorieSelezionate.size() == 0) {
                Clients.showNotification("Parametro mancante: categoria."
                        , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }
            if (renditaDa == null && renditaA == null) {
                Clients.showNotification("Parametro mancante: specificare almeno un parametro tra Rendita Da e Rendita A."
                        , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }
        }
        if (visualizzaScarto && scarto == null) {
            Clients.showNotification("Parametro mancante: scarto."
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }
        Map parametri = [
                'anno'           : anno
                , 'scarto'       : scarto
                , 'tipiCategoria': categorieSelezionate.categoriaCatasto
                , 'renditaDa'    : renditaDa
                , 'renditaA'     : renditaA
                , 'daImposta'    : daImposta]


        for (TipoAnomaliaDTO tipoAnomalia in listaTipiAnomaliaSelezionati) {

            for (String tipoTributo in cbTributi.findAll { it.value }.keySet()) {
                String messaggioJob = "Controllo anomalia per tipo ${tipoAnomalia.tipoAnomalia}, anno ${anno} e tipo tributo ${tipoTributo} "
                messaggioJob += (daImposta ? "su oggetti imposta" : "")
                try {

                    // Il passaggio al job dell'oggetto parametri avviene per riferimento, quindi è unico.
                    // Se non si effettua la copia, nel caso di generazione multipla, la mappa verrà modificata e punterà all'ultimo id anomalie parametro.
                    def parametriAnomalia = parametri.getClass().newInstance(parametri)

                    // Gestione dei parametri per tipo di anomalia.
                    // In caso di esecuzione di controllo di diverse anomalie non tutti i parametri sono necessari.
                    // Per anomalie diverse dalla 3, 8, 14 e 15 il campo scarto non è da considerare
                    if (tipoAnomalia.tipoAnomalia != 3 && tipoAnomalia.tipoAnomalia != 8 && 
							tipoAnomalia.tipoAnomalia != 14 && tipoAnomalia.tipoAnomalia != 15) {
                        parametriAnomalia.scarto = 0
                    }

                    // Per anomalie diverse dalla 6 il campo rendita e categorie non sono da considerare
                    if (tipoAnomalia.tipoAnomalia != 6) {
                        parametriAnomalia.renditaDa = 0
                        parametriAnomalia.renditaA = 0
                        parametriAnomalia.tipiCategoria = null
                    }

                    AnomaliaParametroDTO anomaliaParametroDTO = controlloAnomalieService.lockControlloAnomalia(tipoAnomalia.tipoAnomalia, anno, daImposta, tipoTributo, parametriAnomalia)

                    parametriAnomalia.tipoTributo = tipoTributo
                    parametriAnomalia.tipiOggetto = tipiOggetto[tipoTributo]
                    parametriAnomalia.anomaliaParametro = anomaliaParametroDTO
                    parametriAnomalia.checkSistemate = checkSistemate

                    ControlloAnomalieJob.triggerNow([
                            'codiceUtenteBatch'     : springSecurityService.currentUser.id
                            , 'codiciEntiBatch'     : springSecurityService.principal.amministrazione.codice
                            , 'customDescrizioneJob': messaggioJob
                            , 'tipoAnomalia'        : tipoAnomalia
                            , 'idAnomaliaParametro' : anomaliaParametroDTO.id
                            , 'parametri'           : parametriAnomalia])
                    tipiAnomaliaLanciati << tipoAnomalia.tipoAnomalia
                } catch (Exception e) {
                    String descrizione = "Errore " + messaggioJob + " [" + e.getMessage() + "]"
                    String errore = e.getMessage()
                    tipiAnomaliaErrore << [tipoAnomalia: tipoAnomalia.tipoAnomalia, descrizione: descrizione, eccezione: errore]
                }
            }
        }
        if (tipiAnomaliaErrore.isEmpty()) {
            Clients.showNotification("Elaborazione batch per i" + (tipiAnomaliaLanciati.size() == 1 ? "l" : "") + " tip" + (tipiAnomaliaLanciati.size() == 1 ? "o" : "i") + " anomalia: " + tipiAnomaliaLanciati?.join(", "), Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            Events.postEvent(Events.ON_CLOSE, self, [tipiAnomalia: listaTipiAnomaliaSelezionati, anno: anno])
        } else {
            popupControlloFallito?.open(self, "middle_center")
            BindUtils.postNotifyChange(null, null, this, "tipiAnomaliaErrore")
        }

    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @NotifyChange("elencoCategorieSelezionate")
    @Command
    onSelectCategorie() {}

    @NotifyChange("cbTributi")
    @Command
    onChangeAnno() {
        if (anno < 2014) cbTributi['TASI'] = false
    }

    String getElencoCategorieSelezionate() {
        categorieSelezionate?.categoriaCatasto?.join(", ")
    }

    @Command
    onChiudiControlloFallito(@BindingParam("popup") Popup popupControlloFallito) {
        popupControlloFallito.close()
    }
	
    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
			if(competenzeService.utenteAbilitatoScrittura(it.tipoTributo)) {
				cbTributiInScrittura << [(it.tipoTributo): true]
			}
        }
		
        cbTributi.each { k, v ->
            if(!cbTributiInScrittura[k]) {
                cbTributi[k] = false
            }
        }
    }
}
