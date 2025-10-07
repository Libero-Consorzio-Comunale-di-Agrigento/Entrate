package ufficiotributi.bonificaDati

import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoIntervento
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.anomalie.TipoAnomaliaDTO
import it.finmatica.tr4.imposte.ImposteService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DichiarazioniViewModel {

    Window self

	CompetenzeService competenzeService
    CommonService commonService
    ImposteService imposteService
    ControlloAnomalieService controlloAnomalieService

    // paginazione
    int activePage = 0
    int pageSize = 10
    def totalSize

    int activePagePrt = 0
    int pageSizePrt = 10
    def totalSizePrt


    List<TipoAnomaliaDTO> listaTipiAnomalie

    List listaAnomalie
    List listaAnomalieSelezionate = []
    List<Short> listaAnni

    Short anno

    def anomaliaSelezionata
    List<TipoAnomaliaDTO> tipiAnomaliaSelezionati = []
    def oggettoSelezionato

    boolean openOggetti = false
    boolean slideUp = false
    //serve a far vedere o non far vedere l'immagine con la freccina, per riaprire il riepilogo delle anomalie
    boolean praticaPerAnno = true
    String tipoControllo = "D"

	// Competenze
	def cbTributiAbilitati = [:]
	def cbTributiInScrittura = [:]

    Map cbTributi = ['TASI': false, 'ICI': true]

    BonificaDatiService bonificaDatiService

    def oggettoFiltro

    def dettagliAnomalia = [
            (TipoIntervento.OGGETTO)  : "/ufficiotributi/bonificaDati/dettagliAnomaliaOggetto.zul"
            , (TipoIntervento.PRATICA): "/ufficiotributi/bonificaDati/dettagliAnomaliaPratica.zul"
    ]

    String urlIncluded

    def title = ""
    def daSituazioneContribuente = false
    def oggettoAnomalo = null

    @NotifyChange(["listaTipiAnomalie"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") String anno,
         @ExecutionArgParam("elencoAnom") String elencoAnom,
         @ExecutionArgParam("oggetto") Long oggetto) {

        this.self = w

        daSituazioneContribuente = oggetto != null
        oggettoAnomalo = oggetto

        verificaCompetenze()

        if (!daSituazioneContribuente) {
            title = " Bonifica dati - Dichiarazioni"
        } else {
            title = " Bonifica Oggetti"
        }

        listaTipiAnomalie = OggettiCache.TIPI_ANOMALIA.valore.findAll {
            it.tipoBonifica == "D" && (it.tipoAnomalia as int) in ((1..15) + [22, 23])
        }
        listaAnni = imposteService.getListaAnni()

        // Si apre la funzionalità di bonifica in modalità standalone
        this.anno = anno as Short
        if (this.anno) {

            tipiAnomaliaSelezionati = listaTipiAnomalie.findAll { (it.tipoAnomalia as String) in elencoAnom.split("-") }
            if (this.anno >= 2014) {
                cbTributi.TASI = true
            }
            tipoControllo = 'T'

            onCerca()
        }

        if (daSituazioneContribuente) {
            self.width = "100%"
            self.height = "100%"
            self.invalidate()
        }

        this.oggettoFiltro = oggetto

    }

    @NotifyChange(["listaAnomalie", "listaAnomalieSelezionate", "slideUp", "anomaliaSelezionata", "urlIncluded"])
    @Command
    onCerca() {

        if (tipiAnomaliaSelezionati.isEmpty()) {
            Clients.showNotification("Selezionare almeno un tipo anomalia"
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        } else {
            listaAnomalie = bonificaDatiService.getAnomalieIn(tipiAnomaliaSelezionati.tipoAnomalia, anno, cbTributi, tipoControllo, oggettoAnomalo)
            slideUp = false
            anomaliaSelezionata = null
            listaAnomalieSelezionate = []
            urlIncluded = null
        }
    }

    @Command
    onControllaAnomalie() {
        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/controlloAnomalie.zul", self, [anno: anno])
        w.onClose { event ->
            if (event.data) {
                tipiAnomaliaSelezionati = listaTipiAnomalie.findAll {
                    it.tipoAnomalia in event.data.tipiAnomalia.tipoAnomalia
                }
                anno = event.data.anno
                BindUtils.postNotifyChange(null, null, this, "tipiAnomaliaSelezionati")
                BindUtils.postNotifyChange(null, null, this, "anno")
                BindUtils.postNotifyChange(null, null, this, "elencoTipiAnomaliaSel")
            }
        }
        w.doModal()
    }


    @Command
    onVisualizzaOggetti() {
        slideUp = false
        listaAnomalie*.visibile = 0
        anomaliaSelezionata.visibile = 1
        urlIncluded = dettagliAnomalia[anomaliaSelezionata.tipoIntervento]
        BindUtils.postNotifyChange(null, null, this, "listaAnomalie")
        BindUtils.postNotifyChange(null, null, this, "slideUp")
        BindUtils.postNotifyChange(null, null, this, "urlIncluded")
        BindUtils.postGlobalCommand(null, null, "loadDettagliAnomalia",
                [
                        anomaliaSelezionata: anomaliaSelezionata,
                        idOggetto          : oggettoFiltro
                ])
    }

    @NotifyChange(["listaAnomalie", "slideUp", "listaAnomalieSelezionate"])
    @Command
    ricaricaAnomalie() {
        listaAnomalie*.visibile = 1
        listaAnomalieSelezionate = []
        listaAnomalieSelezionate << anomaliaSelezionata
        slideUp = true
    }


    @NotifyChange("elencoTipiAnomaliaSel")
    @Command
    onSelectTipoAnomalia() {}

    String getElencoTipiAnomaliaSel() {
        tipiAnomaliaSelezionati?.tipoAnomalia?.join(", ")
    }

    @Command
    nascondiAnomalie() {
        slideUp = true
        BindUtils.postNotifyChange(null, null, this, "slideUp")
    }

    @Command
    onChiudiRiepilogoJob(@BindingParam("popup") Component popupStatoJob) {
        popupStatoJob.close()
    }

    @NotifyChange(["listaAnomalie"])
    @GlobalCommand
    aggiornaRendite() {
        listaAnomalie = bonificaDatiService.getAnomalieIn(tipiAnomaliaSelezionati.tipoAnomalia, anno, cbTributi, tipoControllo, oggettoAnomalo)
    }

    @Command
    onRicalcolaRendita(@BindingParam("anomalia") def anomalia) {

        if (!bonificaDatiService.isTipoAnomaliaForMui(anomalia.tipoAnomalia)) {
            controlloAnomalieService.calcolaRendite(anomalia.id)
        }

        listaAnomalie = bonificaDatiService.getAnomalieIn(tipiAnomaliaSelezionati.tipoAnomalia, anno, cbTributi, tipoControllo, oggettoAnomalo)

        BindUtils.postNotifyChange(null, null, this, "listaAnomalie")
        BindUtils.postGlobalCommand(null, null, "loadDettagliAnomalia", [anomaliaSelezionata: anomaliaSelezionata])
    }
	
    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
			if(competenzeService.utenteAbilitatoScrittura(it.tipoTributo)) {
				cbTributiInScrittura << [(it.tipoTributo): true]
			}
        }
		
        cbTributi.each { k, v ->
            if (competenzeService.tipiTributoUtenza().find { it.tipoTributo == k } == null) {
                cbTributi[k] = false
            }
        }
    }
}
