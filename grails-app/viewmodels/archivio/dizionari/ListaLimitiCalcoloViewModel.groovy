package archivio.dizionari

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.LimiteCalcoloDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaLimitiCalcoloViewModel extends TabListaGenericaTributoViewModel {


    CanoneUnicoService canoneUnicoService

    def labels
    // Interfaccia
    def filtriList = [
            descrizione: ''
    ]
    boolean filtroAttivoList = false

    // Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Limiti Calcolo
    def elencoLimitiCalcolo = []
    def listaLimitiCalcolo = []
    def limiteCalcoloSelezionato = null

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    def onSelectAnno() {
        caricaListaLimitiCalcolo(true)
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    void onRefresh() {
        caricaListaLimitiCalcolo(true)
        self.invalidate()
    }

    @Command
    def onCambioPagina() {

        caricaListaLimitiCalcolo(false)
    }

    @Command
    def onLimiteCalcoloSelected() {

    }

    @Command
    def onModificaLimiteCalcolo() {

        modificaLimiteCalcolo(limiteCalcoloSelezionato.dto, true)
    }

    @Command
    def onDuplicaLimiteCalcolo() {

        modificaLimiteCalcolo(limiteCalcoloSelezionato.dto, true, true)
    }

    @Command
    def onEliminaLimiteCalcolo() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        eliminaLimiteCalcolo()
                    }
                })
    }

    @Command
    def onNuovoLimiteCalcolo() {

        modificaLimiteCalcolo(null, true)
    }

    @Command
    def onLimitiCalcoloToXls() {

        def fields = [
                'anno': 'Anno'
        ]
        if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
            fields << [
                    'dto.gruppoTributo': 'Cod. Gruppo Tributo',
                    'gruppoTributo'    : 'Gruppo Tributo',
                    'tipoOccupazione'  : 'Tipo Occupazione',
            ]
        }
        fields << [
                'dto.limiteImposta'   : 'Limite Imposta',
                'dto.limiteViolazione': 'Limite Violazione',
                'dto.limiteRata'      : 'Limite Rata',
        ]

        def tipoTributoAttuale = TipoTributo.findByTipoTributo(tipoTributoSelezionato.tipoTributo).tipoTributoAttuale

        XlsxExporter.exportAndDownload("LimitiCalcolo_${tipoTributoAttuale}_${selectedAnno}", elencoLimitiCalcolo as List, fields)
    }

    // Funzioni interne

    // Verifica impostazioni filtro
    def aggiornaFiltroAttivoList() {

        filtroAttivoList = (filtriList.descrizione != '')

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoList")
    }

    // Apre finestra visualizza/modifica del Limiti Calcolo
    private def modificaLimiteCalcolo(LimiteCalcoloDTO limiteCalcolo, boolean modifica, boolean duplica = false) {

        Boolean modificaNow = (lettura) ? false : modifica

        commonService.creaPopup("/archivio/dizionari/dettaglioLimiteCalcolo.zul",
                self,
                [
                        tipoTributo  : tipoTributoSelezionato.tipoTributo,
                        annoTributo  : selectedAnno as Short,
                        limiteCalcolo: limiteCalcolo,
                        modifica     : modificaNow,
                        duplica      : duplica
                ], { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaLimitiCalcolo(true, true)
                }
            }
        })


    }

    // Rilegge elenco Limiti Calcolo
    private def caricaListaLimitiCalcolo(boolean resetPaginazione, boolean restorePagina = false) {

        def filtriNow = completaFiltriLimitiCalcolo()

        if (elencoLimitiCalcolo.empty || resetPaginazione) {

            def activePageOld = pagingList.activePage

            pagingList.activePage = 0
            elencoLimitiCalcolo = canoneUnicoService.getElencoLimitiCalcolo(filtriNow)
            pagingList.totalSize = elencoLimitiCalcolo.size()

            if (restorePagina) {
                if (activePageOld < ((pagingList.totalSize / pagingList.pageSize) + 1)) {
                    pagingList.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        listaLimitiCalcolo = elencoLimitiCalcolo.subList(fromIndex, toIndex)

        limiteCalcoloSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "limiteCalcoloSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaLimitiCalcolo")
    }

    // Elimina il Limiti Calcolo selezionato
    private def eliminaLimiteCalcolo() {

        LimiteCalcoloDTO limiteCalcolo = limiteCalcoloSelezionato.dto

        def report = canoneUnicoService.eliminaLimiteCalcolo(limiteCalcolo)

        if (report.result != 0) {
            visualizzaReport(report, "")
        }

        def message = "Eliminazione avvenuta con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    // Completa filtri per Limiti Calcolo
    private def completaFiltriLimitiCalcolo() {

        def filtriNow = filtriList.clone()

        filtriNow.annoTributo = selectedAnno as Short
        filtriNow.tipoTributo = tipoTributoSelezionato.tipoTributo

        return filtriNow
    }


    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }

    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def lista = []
        if (modalita == 'TUTTI') {
            lista.addAll(canoneUnicoService.getElencoLimitiCalcolo([tipoTributo: tipoTributoSelezionato.tipoTributo]))
        } else {
            lista.addAll(canoneUnicoService.getElencoLimitiCalcolo(completaFiltriLimitiCalcolo()))
        }

        def fields = [
                'anno': 'Anno'
        ]
        if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
            fields << [
                    'dto.gruppoTributo': 'Cod. Gruppo Tributo',
                    'gruppoTributo'    : 'Gruppo Tributo',
                    'tipoOccupazione'  : 'Tipo Occupazione',
            ]
        }
        fields << [
                'dto.limiteImposta'   : 'Limite Imposta',
                'dto.limiteViolazione': 'Limite Violazione',
                'dto.limiteRata'      : 'Limite Rata',
        ]

        def tipoTributoAttuale = TipoTributo.findByTipoTributo(tipoTributoSelezionato.tipoTributo).tipoTributoAttuale

        def annoStr = ""
        if (modalita != 'TUTTI') {
            annoStr = "_${selectedAnno}"
        }

        XlsxExporter.exportAndDownload("LimitiCalcolo_${tipoTributoAttuale}${annoStr}", lista, fields)

    }

}
