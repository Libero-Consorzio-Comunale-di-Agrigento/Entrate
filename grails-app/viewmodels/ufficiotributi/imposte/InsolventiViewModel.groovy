package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.InsolventiService
import it.finmatica.tr4.insolventi.FiltroRicercaInsolventi
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Listbox
import org.zkoss.zul.Window

class InsolventiViewModel {

    //Services
    InsolventiService insolventiService
    CommonService commonService

    // Componenti
    Window self

    @Wire("#listBoxInsolventi")
    Listbox listBoxInsolventi

    //Comuni
    TipoTributoDTO tipoTributo
    def imposta
    def listaInsolventi = []
    def insolventeSelezionato

    def ordinamentoSelezionato = "Alfabetico"
    def checkVersamenti = "Tutti"
    def pagingInsolventi = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]
	
    def totali
    def mascheraLista
    def gruppoTributoAttivo
	
	FiltroRicercaInsolventi filtri
	def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("impostaSelezionata") def is,
         @ExecutionArgParam("gruppoTributo") def gt) {

        this.self = w
        this.tipoTributo = tt
        this.imposta = is
        this.gruppoTributoAttivo = gt

        filtri = new FiltroRicercaInsolventi()
		
        initTotali()
        onRicercaInsolventi()
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onRefreshInsolventi() {
        resetPaginazione()
        caricaListaInsolventi()
    }

    @Command
    def onInsolventiXls() {

        def fields
        def listaInsolventiTot

        if (filtri.aRuolo) {

            listaInsolventiTot = insolventiService.getListaInsolventi(filtri,
                    [
                            tipoTributo: imposta.tipoTributo,
                            anno       : imposta.anno,
                            tributo    : -1,
                            ordinamento: ordinamentoSelezionato,
                            versato    : checkVersamenti
                    ],
                    [
                            activePage: 0,
                            pageSize  : Integer.MAX_VALUE,
                            totalSize : 0
                    ]).records
        } else {

            listaInsolventiTot = insolventiService.getListaInsolventiNonARuolo(filtri,
                    [
                            tipoTributo: imposta.tipoTributo,
                            anno       : imposta.anno,
                            tributo    : -1,
                            ordinamento: ordinamentoSelezionato,
                            versato    : checkVersamenti
                    ],
                    [
                            activePage: 0,
                            pageSize  : Integer.MAX_VALUE,
                            totalSize : 0
                    ]).records
        }

        if (listaInsolventiTot) {

            if (filtri.aRuolo) {

                fields = [
                        "csoggnome"                : "Contribuente",
                        "codFiscale"               : "Codice Fiscale",
                        "impostaRuolo"             : "Totali: a Ruolo",
                        "sgravioTot"               : "Totali: Sgravi tot.",
                        "versato"                  : "Totali: Versato",
                        "differenza"               : "Totali: Dovuto/Rimborso",
                        "imposta"                  : "Dettagli Imposta: Imposta Netta",
                        "addMaggEca"               : "Dettagli Imposta: ECA",
                        "addizionalePro"           : "Dettagli Imposta: Add.Pro.",
                        "importoSgravio"           : "Dettagli Sgravi: Imposta",
                        "addMaggEcaSgravio"        : "Dettagli Sgravi: ECA",
                        "addizionaleProSgravio"    : "Dettagli Sgravi: Add.Pro.",
                        "dovuto"                   : "Totali Senza Maggiorazione: Dovuto",
                        "versatoNetto"             : "Totali Senza Maggiorazione: Versato",
                        "differenzaNoMaggioraz"    : "Totali Senza Maggiorazione: Differenza",
                        "maggiorazioneTares"       : "Componenti Perequative: Imposta",
                        "maggiorazioneTaresSgravio": "Componenti Perequative: Sgravi",
                        "versatoMaggiorazione"     : "Componenti Perequative: Versato",
                        "differenzaMaggioraz"      : "Componenti Perequative: Differenza",
                        "indirizzoDich"            : "Indirizzo",
                        "residenzaDich"            : "Comune"
                ]

            } else {

                fields = [
                        "csoggnome"    : "Contribuente",
                        "codFiscale"   : "Codice Fiscale",
                        "dovuto"       : "Importo Dovuto",
                        "versato"      : "Importo Versato",
                        "tardivo"      : "Tard.",
                        "netto"        : "Insolvenza",
                        "indirizzoDich": "Indirizzo",
                        "residenzaDich": "Comune"
                ]
            }

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CONTRIBUENTI_A_RUOLO,
                    [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                     anno       : imposta.anno,
                     servizio   : gruppoTributoAttivo ? imposta.servizio : 'TUTTI'])

            XlsxExporter.exportAndDownload(nomeFile, listaInsolventiTot, fields)
        }

    }

    @Command
    def onStampaInsolventi() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.INSOLVENTI2,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 anno       : imposta.anno])

        def reportElenco = insolventiService.generaStampa(tipoTributo.getTipoTributoAttuale(), filtri,
                [
                        tipoTributo: imposta.tipoTributo,
                        anno       : imposta.anno,
                        tributo    : -1,
                        ordinamento: ordinamentoSelezionato,
                        versato    : checkVersamenti
                ],
                [
                        activePage: 0,
                        pageSize  : Integer.MAX_VALUE,
                        totalSize : 0
                ])

        if (reportElenco == null) {
            Clients.showNotification("Errore nella generazione della stampa"
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportElenco.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onRicercaInsolventi() {

        commonService.creaPopup("/ufficiotributi/imposte/insolventiRicerca.zul", self,
                [
                        tipoTributo        : tipoTributo,
                        filtri             : filtri,
                        anno               : imposta.anno,
                        gruppoTributoAttivo: gruppoTributoAttivo,
                        codiceTributo      : imposta.servizio
                ], { e ->
            if (e.data?.filtriAggiornati) {
                filtri = e.data.filtriAggiornati
                resetPaginazione()
                caricaListaInsolventi()
            }
        })
    }

    @Command
    def onCheckOrdinamento() {
        resetPaginazione()
        caricaListaInsolventi()
    }

    @Command
    def onCheckVersamenti() {
        BindUtils.postNotifyChange(null, null, this, "checkVersamenti")
        resetPaginazione()
        caricaListaInsolventi()
    }

    @Command
    def onPagingInsolventi() {
        caricaListaInsolventi()
    }

    @Command
    def onResizeColumn() {
        listBoxInsolventi?.invalidate()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("ni") def ni) {
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    private def caricaListaInsolventi() {

        def result

        insolventeSelezionato = null

        if (filtri.aRuolo) {
            mascheraLista = "/ufficiotributi/imposte/insolventiListaARuolo.zul"

            result = insolventiService.getListaInsolventi(
                    filtri,
                    [
                            tipoTributo: imposta.tipoTributo,
                            anno       : imposta.anno,
                            ordinamento: ordinamentoSelezionato,
                            versato    : checkVersamenti
                    ],
                    pagingInsolventi)
        } else {
            mascheraLista = "/ufficiotributi/imposte/insolventiListaNonARuolo.zul"

            result = insolventiService.getListaInsolventiNonARuolo(
                    filtri,
                    [
                            tipoTributo: imposta.tipoTributo,
                            anno       : imposta.anno,
                            ordinamento: ordinamentoSelezionato,
                            versato    : checkVersamenti
                    ],
                    pagingInsolventi)
        }


        listaInsolventi = result.records
        totali = result.totali
        pagingInsolventi.totalSize = totali.totalCount

        BindUtils.postNotifyChange(null, null, this, "mascheraLista")
        BindUtils.postNotifyChange(null, null, this, "listaInsolventi")
        BindUtils.postNotifyChange(null, null, this, "pagingInsolventi")
        BindUtils.postNotifyChange(null, null, this, "insolventeSelezionato")
        BindUtils.postNotifyChange(null, null, this, "totali")

        controllaFiltroAttivo()
    }

    private def controllaFiltroAttivo() {
		
		filtroAttivo = filtri.filtroAttivo()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    private def resetPaginazione() {
		
        pagingInsolventi.activePage = 0
        pagingInsolventi.totalSize = 0
        BindUtils.postNotifyChange(null, null, this, "pagingInsolventi")
    }

    private def initTotali() {

        totali = [
                totSgravioTot       : 0,
                totImposta          : 0,
                totDifferenza       : 0,
                totDovuto           : 0,
                totImportoSgravio   : 0,
                totVersatoMagg      : 0,
                totImpostaRuolo     : 0,
                totMaggTares        : 0,
                totAddProSgravio    : 0,
                totAddPro           : 0,
                totAddMaggEca       : 0,
                totAddMaggEcaSgravio: 0,
                totVersato          : 0,
                totDiffNoMagg       : 0,
                totDiffMagg         : 0,
                totVersatoNetto     : 0,
                totMaggTaresSgravio : 0
        ]
    }
}
