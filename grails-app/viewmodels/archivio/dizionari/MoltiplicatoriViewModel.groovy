package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.moltiplicatori.MoltiplicatoriService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class MoltiplicatoriViewModel extends TabListaGenericaTributoViewModel {

    // Services
    MoltiplicatoriService moltiplicatoriService


    // Comuni
    def listaMoltiplicatori
    def moltiplicatoreSelezionato
    def cbTributiInScrittura = [:]
    def cbTributiInLettura = [:]
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
        this.lettura = lettura || tipoTributoSelezionato.tipoTributo == "TASI"

        def filtriNow = filtro ?: [:]

        this.listaMoltiplicatori = moltiplicatoriService.getListaMoltiplicatori([
                *   : filtriNow,
                anno: selectedAnno
        ])
        this.moltiplicatoreSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaMoltiplicatori")
        BindUtils.postNotifyChange(null, null, this, "moltiplicatoreSelezionato")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return moltiplicatoriService.getCountMoltiplicatoriByAnno(selectedAnno) == 0 &&
                !moltiplicatoriService.getListaAnniDuplicaDaAnno().empty
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaMoltiplicatoriDaAnno.zul", self,
                [anno: selectedAnno],
                { event ->
                    if (event.data) {
                        if (event.data.anno) {
                            Clients.showNotification("Duplicazione da anno ${event.data.anno} avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                            onRefresh()
                        }
                    }
                })
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMoltiplicatore.zul", self,
                [
                        moltiplicatoreSelezionato: moltiplicatoreSelezionato,
                        tipoOperazione           : lettura ? DettaglioMoltiplicatoreViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioMoltiplicatoreViewModel.TipoOperazione.MODIFICA,
                        anno                     : selectedAnno
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            Clients.showNotification("Modifica avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                    onRefresh()
                })

    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioMoltiplicatore.zul", self,
                [
                        moltiplicatoreSelezionato: null,
                        tipoOperazione           : DettaglioMoltiplicatoreViewModel.TipoOperazione.INSERIMENTO,
                        anno                     : selectedAnno
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        }
                    }
                    onRefresh()
                })
    }

    @Command
    def onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioMoltiplicatore.zul", self,
                [
                        moltiplicatoreSelezionato: moltiplicatoreSelezionato,
                        tipoOperazione           : DettaglioMoltiplicatoreViewModel.TipoOperazione.CLONAZIONE,
                        anno                     : selectedAnno
                ],
                { event ->
                    if (event.data) {
                        if (event.data.salvataggio) {
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        }
                    }
                    onRefresh()
                })
    }

    @Command
    def onElimina() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        moltiplicatoriService.eliminaMoltiplicatore(moltiplicatoreSelezionato)


                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })

    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = getListaForXls(mode)

        if (lista) {
            Map fields = [
                    "anno"            : "Anno",
                    "categoriaCatasto": "Categoria Catastale",
                    "moltiplicatore"  : "Moltiplicatore"
            ]

            def formatters = [
                    "categoriaCatasto": { ccat -> "${ccat.categoriaCatasto} - ${ccat.descrizione}" }
            ]

            def nomeFile = getNomeFileXls(mode)
            XlsxExporter.exportAndDownload(nomeFile, lista, fields, formatters)
        }

    }

    private def getListaForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return listaMoltiplicatori
        }

        if (mode == ExportXlsMode.TUTTI) {
            return moltiplicatoriService.getListaMoltiplicatori()
        }
    }

    private def getNomeFileXls(String mode) {
        return FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.MOLTIPLICATORI,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                        anno       : mode == ExportXlsMode.PARAMETRI ? selectedAnno : null,
                ]
        )
    }

    @Command
    def onSelectAnno() {
        onRefresh()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/moltiplicatoriRicerca.zul", self, [filtro: filtro], { event ->
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
