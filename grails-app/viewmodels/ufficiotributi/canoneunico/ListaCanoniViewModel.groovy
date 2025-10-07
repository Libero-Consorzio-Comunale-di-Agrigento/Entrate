package ufficiotributi.canoneunico

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class ListaCanoniViewModel {

    Window self
    ServletContext servletContext

    CompetenzeService competenzeService

    CanoneUnicoService canoneUnicoService
    IntegrazioneDePagService integrazioneDePagService
    CommonService commonService

    /// Generali
    String tipoTributo
    def annoTributo

    Boolean lettura = true

    def dePagVisibile = false

    /// Interfaccia
    def filtriList = [
            cognome         : "",
            nome            : "",
            codFiscale      : "",
            tipoOccupazione : null,
            statoOcuupazione: null,
            codiciTributo   : [],
            tipiTariffa     : []
    ]
    FiltroRicercaCanoni filtriAggiunti
    boolean filtroAttivoList = false

    def listaAnni = null

    /// Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    /// Canoni 
    def elencoCanoni = []
    def listaCanoni = []
    def canoneSelezionato = null

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt) {

        this.self = w

        this.tipoTributo = "CUNI"

        lettura = !competenzeService.utenteAbilitatoScrittura(this.tipoTributo)

        def listaAnniOrg = canoneUnicoService.getElencoAnni()

        listaAnni = []
        listaAnniOrg.each {
            listaAnni << it as String
        }
        listaAnni << 'Tutti'

        annoTributo = listaAnni[0]

        dePagVisibile = integrazioneDePagService.dePagAbilitato()

        onOpenFiltriLista()
    }

    /// Elenco Canoni ####################################################################################

    @Command
    def onSelectAnno() {

        caricaListaCanoni(true)
    }

    @Command
    def onRicaricaLista() {

        caricaListaCanoni(true)
    }

    @Command
    def onCambioPagina() {

        caricaListaCanoni(false)
    }

    @Command
    def onOpenFiltriLista() {

        def filtri = filtriList.clone()
        filtri.filtriAggiunti = filtriAggiunti

        Window w = Executions.createComponents("/ufficiotributi/canoneunico/listaCanoniRicerca.zul", self,
                [tipoTributo: tipoTributo, annoTributo: annoTributo, filtri: filtriList])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "cerca") {

                    filtriList = event.data.filtri
                    filtriAggiunti = filtriList.filtriAggiunti
                    aggiornaFiltroAttivoList()

                    caricaListaCanoni(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onCanoneSelected() {

    }

    @Command
    def onApriContribuente() {

        def ni = canoneSelezionato.ni
		Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onModificaCanone() {

        modificaCanone(canoneSelezionato, true)
    }

    @Command
    def onNuovoCanone() {

        modificaCanone(null, true)
    }

    @Command
    def onCanoniToXls() {

        canoneUnicoService.canoniToXls(annoTributo, elencoCanoni, [anno: annoTributo], true)
    }

    @Command
    def onGeolocalizzaOggetto() {

        String url = canoneUnicoService.getGoogleMapshUrl(canoneSelezionato)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    /// Funzioni interne ####################################################################################

    ///
    /// *** Verifica impostazioni filtro
    ///
    def aggiornaFiltroAttivoList() {

        filtroAttivoList = (filtriList.cognome ?: '' != '') ||
                (filtriList.nome ?: '' != '') ||
                (filtriList.codFiscale ?: '' != '') ||
                (filtriList.codContribuente != null) ||
                (filtriList.tipoOccupazione != null) ||
                (!(filtriList.codiciTributo ?: []).empty) ||
                (filtriAggiunti?.isDirty() ?: false)

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoList")
    }

    ///
    /// *** Apre finestra visualizza/modifica del Canone
    ///
    private def modificaCanone(def canone, boolean modifica) {

        ContribuenteDTO contribuente = Contribuente.findByCodFiscale(canone.contribuente).toDTO()
        contribuente.soggetto = Soggetto.findById(contribuente.soggetto.id).toDTO()

        Window w = Executions.createComponents("/ufficiotributi/canoneunico/concessioneCU.zul", self,
                [
                        contribuente   : contribuente,
                        oggetto        : canone.oggettoRef,
                        dataRiferimento: canone.dettagli.dataDecorrenza,
                        anno           : canone.anno,
                        lettura        : lettura
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaCanoni(true, true)
                }
            }
        }
        w.doModal()
    }

    ///
    /// *** Rilegge elenco Canoni
    ///
    private def caricaListaCanoni(boolean resetPaginazione, boolean restorePagina = false) {

        def filtriNow = completaFiltriCanoni()

        if ((elencoCanoni.size() == 0) || (resetPaginazione != false)) {

            def activePageOld = pagingList.activePage

            pagingList.activePage = 0
            elencoCanoni = canoneUnicoService.getConcessioniContribuente(filtriNow)
            pagingList.totalSize = elencoCanoni.size()

            if (restorePagina) {
                if (activePageOld < ((pagingList.totalSize / pagingList.pageSize) + 1)) {
                    pagingList.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        listaCanoni = elencoCanoni.subList(fromIndex, toIndex)

        BindUtils.postNotifyChange(null, null, this, "listaCanoni")
    }

    ///
    /// *** Completa filtri per Canoni
    ///
    private def completaFiltriCanoni() {

        def filtriNow = filtriList.clone()

        def tipiTributo = [
                TARSU: false,
                TASI : false,
                ICI  : false,
                ICP  : false,
                TOSAP: false,
                CUNI : true
        ]
        def tipiPratiche = [
                D: true,
                V: false,
                A: false,
                L: false,
                I: false
        ]

        filtriNow.anno = annoTributo
		filtriNow.perDateValidita = true
		
        filtriNow.tipiTributo = tipiTributo
        filtriNow.tipiPratiche = tipiPratiche

        filtriNow.oggettoRif = null
        filtriNow.dataRif = null

        filtriNow.skipMerge = false
        filtriNow.skipTemaFlag = false
        filtriNow.skipDepagFlag = !dePagVisibile

        filtriNow.filtriAggiunti = filtriAggiunti

        return filtriNow
    }
}
