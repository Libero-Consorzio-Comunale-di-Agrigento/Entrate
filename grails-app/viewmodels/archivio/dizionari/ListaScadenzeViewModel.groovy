package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.ScadenzaDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaScadenzeViewModel extends TabListaGenericaTributoViewModel {

    CanoneUnicoService canoneUnicoService

    // Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Scadenze
    def listaScadenze = []
    def scadenzaSelezionata = null
    def labels

    // Ricerca
    def filtro
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        caricaListaScadenze()
        self.invalidate()
    }

    // Tab panel

    @Command
    def onCaricaPrimoTab() {

    }

    @Command
    def onSelectTabs() {

    }

    // Elenco Scadenze

    @Command
    def onSelectAnno() {
        caricaListaScadenze()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        def filtriNow = [
                tipoTributo: tipoTributoSelezionato.tipoTributo,
                annoTributo: selectedAnno
        ]
        return canoneUnicoService.contaScadenzePerAnnualita(filtriNow) == 0 &&
                !canoneUnicoService.getAnnualitaInScadenze(tipoTributoSelezionato.tipoTributo).empty
    }

    @Command
    def onScadenzaSelected() {

    }

    @Command
    def onModificaScadenza() {

        modificaScadenza(scadenzaSelezionata.dto, true)
    }

    @Command
    def onDuplicaScadenza() {

        modificaScadenza(scadenzaSelezionata.dto, true, true)
    }

    @Command
    def onEliminaScadenza() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def report = canoneUnicoService.eliminaScadenza(scadenzaSelezionata.dto)

                        if (report.result != 0) {
                            visualizzaReport(report, "")
                            return
                        }

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        onRefresh()
                    }
                })
    }

    @Command
    def onNuovaScadenza() {

        modificaScadenza(null, true)
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

    void openCopiaAnno() {
        def impostazioni = [
                tipoTributo    : tipoTributoSelezionato.tipoTributo,
                annoTributo    : selectedAnno,
                scadenzaSingola: false
        ]

        commonService.creaPopup("/archivio/dizionari/copiaScadenzeDaAnnualita.zul", self, [impostazioni: impostazioni], { event ->
            if (event.data) {
                if (event.data.annoOrigine) {
                    copiaScadenzeDaAnnualita(event.data.annoOrigine as Short)
                }
            }
        })
    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = getListaForXls(mode)

        if (lista) {
            def fields = [
                    'anno'        : 'Anno',
                    'tipoScadenza': 'Tipo Scadenza',
            ]
            if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
                fields = fields + [
                        'dto.gruppoTributo': 'Codice Gruppo Tributo',
                        'gruppoTributo'    : 'Nome Gruppo Tributo',
                        'tipoOccupazione'  : 'Tipo Occupazione'
                ]
            }
            fields = fields + [
                    'rata'          : 'Rata',
                    'tipoVersamento': 'Versamento',
                    'dataScadenza'  : 'Scadenza',
            ]

            def nomeFile = getNomeFileXls(mode)

            XlsxExporter.exportAndDownload(nomeFile, lista, fields)
        }
    }

    private def getListaForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return listaScadenze
        }
        if (mode == ExportXlsMode.TUTTI) {
            def filtroExcel = [tipoTributo: tipoTributoSelezionato.tipoTributo]
            return canoneUnicoService.getElencoScadenze(filtroExcel)
        }
    }

    private def getNomeFileXls(String mode) {
        return FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.SCADENZE,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                 anno       : mode == ExportXlsMode.PARAMETRI ? selectedAnno : null])
    }


    //
    // *** Apre finestra visualizza/modifica della scadenza
    //
    private def modificaScadenza(ScadenzaDTO scadenza, boolean modifica, boolean duplica = false) {

        Boolean modificaNow = (lettura) ? false : modifica

        Window w = Executions.createComponents(
                "/archivio/dizionari/dettaglioScadenza.zul",
                self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        annoTributo: selectedAnno as Short,
                        scadenza   : scadenza,
                        modifica   : modificaNow,
                        duplica    : duplica
                ]
        )
        w.onClose { event ->
            if (event.data) {
                caricaListaScadenze()
            }
        }
        w.doModal()
    }

    // Rilegge elenco scadenze
    private def caricaListaScadenze() {

        def filtriNow = [
                tipoTributo   : tipoTributoSelezionato.tipoTributo,
                da            : filtro?.da,
                a             : filtro?.a,
                tipoVersamento: filtro?.tipoVersamento?.codice,
                tipoScadenza  : filtro?.tipoScadenza?.codice,
                rata          : filtro?.rata?.codice,
                anno          : selectedAnno
        ]

        listaScadenze = canoneUnicoService.getElencoScadenze(filtriNow)
        BindUtils.postNotifyChange(null, null, this, "listaScadenze")

        scadenzaSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "scadenzaSelezionata")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    // Copia scadenze da altra annualita'
    private def copiaScadenzeDaAnnualita(Short annoOrigine) {

        def filtri = [
                tipoTributo: tipoTributoSelezionato.tipoTributo,
                annoTributo: selectedAnno
        ]

        Short annoDestinazione = filtri.annoTributo
        filtri.annoTributo = annoOrigine

        def report = canoneUnicoService.copiaScadenzeDaAnnualita(filtri, annoDestinazione)

        visualizzaReport(report, "Copia scadenze eseguita")

        onRefresh()
    }

    // Visualizza report
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
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaScadenzeRicerca.zul", self, [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @GlobalCommand
    def setAnnoTributoAttivo(@BindingParam("annoTributo") def annoTributo) {

        this.selectedAnno = annoTributo

        BindUtils.postNotifyChange(null, null, this, "selectedAnno")
    }
}
