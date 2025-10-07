package ufficiotributi.bonificaDati

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

abstract class HelpAnomaliePraticheViewModel {

    // services
    def springSecurityService
    OggettiService oggettiService
    CatastoCensuarioService catastoCensuarioService
    CommonService commonService
    GestioneAnomalieService gestioneAnomalieService
    ControlloAnomalieService controlloAnomalieService
    BonificaDatiService bonificaDatiService
	
    // componenti
    Window self
	boolean lettura = false
	

    // dati
    OggettoContribuenteDTO oggettoContribuente
    List listaTipiOggetto
    List listaCategorieCatasto
    List listaFonti
    String tipoRapporto
    PraticaTributoDTO pratica
    boolean isPertinenza = false
    def anomaliaSelezionata
    AnomaliaPraticaDTO praticaSelezionata
    List<OggettoContribuenteDTO> ogcoHelp
    OggettoContribuenteDTO ogcoHelpSelezionato
    String tipoTributo

    def oggettiDaCatasto = []
    def immobileCatastoSelezionato
    protected List<FiltroRicercaOggetto> listaFiltriCatasto

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anomaliaSelezionata") def anomaliaSelezionata
         , @ExecutionArgParam("praticaSelezionata") AnomaliaPraticaDTO praticaSelezionata) {
		 
        this.self = w

        this.anomaliaSelezionata = anomaliaSelezionata
        this.praticaSelezionata = praticaSelezionata

        oggettoContribuente = praticaSelezionata.oggettoContribuente.getDomainObject().toDTO([
                "oggettoPratica",
                "oggettoPratica.tipoOggetto",
                "oggettoPratica.fonte",
                "oggettoPratica.categoriaCatasto",
                "oggettoPratica.oggettoPraticaRendita",
                "oggettoPratica.pratica",
                "oggettoPratica.pratica.tipoTributo",
                "contribuente",
                "contribuente.soggetto",
                "oggettoPratica.oggetto",
                "oggettoPratica.oggetto.archivioVie"
        ])
        tipoRapporto = praticaSelezionata.oggettoContribuente.tipoRapporto
        listaTipiOggetto = TipoOggetto.list().toDTO()
        listaFonti = Fonte.list().toDTO()
        listaCategorieCatasto = CategoriaCatasto.list().toDTO()
        tipoTributo = oggettoContribuente.oggettoPratica.pratica.tipoTributo.getTipoTributoAttuale(oggettoContribuente.oggettoPratica.pratica.anno)

    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onSalvaOggetto(@BindingParam("aggiornaStato") boolean aggiornaStato) {

        oggettoContribuente = oggettiService.salvaOggettoContribuente(oggettoContribuente, tipoRapporto)

        controlloAnomalieService.calcolaRendite(praticaSelezionata.anomalia.anomaliaParametro.id, praticaSelezionata.anomalia.id)

        if (aggiornaStato) {
            bonificaDatiService.cambiaStatoAnomaliaPratica(praticaSelezionata.id)
            controlloAnomalieService.checkAnomaliaPratica(praticaSelezionata.id)
        }

        BindUtils.postGlobalCommand(null, null, "aggiornaRendite", null)

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onRiporta() {
        // Nulla da fare
    }

    @Command
    onCercaCatasto() {
        Window w = Executions.createComponents("/catasto/listaOggettiCatastoRicerca.zul", self,
                [
                        filtri: listaFiltriCatasto,
                        ricercaContribuente: true
                ])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    listaFiltriCatasto = event.data.filtri
                    caricaListaCatasto()
                }
            }
        }

        w.doModal()
    }

    @Command
    onSelezionaTab(@BindingParam("tab") String tab) {
        ogcoHelpSelezionato = null
        immobileCatastoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "ogcoHelpSelezionato")
        BindUtils.postNotifyChange(null, null, this, "immobileCatastoSelezionato")

    }

    protected caricaListaCatasto() {

        if (listaFiltriCatasto[0].tipoOggettoCatasto == "F") {
            oggettiDaCatasto = catastoCensuarioService.getImmobiliCatastoUrbano(listaFiltriCatasto)
        } else {
            oggettiDaCatasto = catastoCensuarioService.getTerreniCatastoUrbano(listaFiltriCatasto)
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiDaCatasto")
    }
}
