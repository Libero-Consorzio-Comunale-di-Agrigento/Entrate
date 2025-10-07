package archivio.dizionari

import it.finmatica.tr4.coefficientiContabili.CoefficientiContabiliService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCoefficientiContabiliViewModel extends TabListaGenericaTributoViewModel {

    // Services
    CoefficientiContabiliService coefficientiContabiliService

    // Comuni
    def listaCoefficientiContabili
    def coefficienteContabileSelezionato
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

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {

        def filtriNow = [
                anno       : selectedAnno,
                daAnnoCoeff: filtro?.daAnnoCoeff,
                aAnnoCoeff : filtro?.aAnnoCoeff,
                daCoeff    : filtro?.daCoeff,
                aCoeff     : filtro?.aCoeff
        ]

        this.listaCoefficientiContabili = coefficientiContabiliService.getListaCoefficientiContabili(filtriNow)
        this.coefficienteContabileSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaCoefficientiContabili")
        BindUtils.postNotifyChange(null, null, this, "coefficienteContabileSelezionato")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaCoefficientiContabiliDaAnno.zul", self,
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

    @Override
    def checkCondizioneAnnoEnabled() {
        return coefficientiContabiliService.getCountCoefficientiContabiliByAnno(selectedAnno) == 0 &&
                !coefficientiContabiliService.getListaAnniDuplicaDaAnno().empty
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteContabile.zul", self,
                [
                        coefficienteContabileSelezionato: coefficienteContabileSelezionato.dto,
                        tipoOperazione                  : lettura ? DettaglioCoefficienteContabileViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioCoefficienteContabileViewModel.TipoOperazione.MODIFICA,
                        anno                            : selectedAnno
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
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteContabile.zul", self,
                [
                        coefficienteContabileSelezionato: null,
                        tipoOperazione                  : DettaglioCoefficienteContabileViewModel.TipoOperazione.INSERIMENTO,
                        anno                            : selectedAnno
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

        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteContabile.zul", self,
                [
                        coefficienteContabileSelezionato: coefficienteContabileSelezionato.dto,
                        tipoOperazione                  : DettaglioCoefficienteContabileViewModel.TipoOperazione.CLONAZIONE,
                        anno                            : selectedAnno
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
                        coefficientiContabiliService.eliminaCoefficienteContabile(coefficienteContabileSelezionato.dto)

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
                    "anno"     : "Anno",
                    "annoCoeff": "Anno Coefficiente",
                    "coeff"    : "Coefficiente"
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
            return listaCoefficientiContabili
        }

        if (mode == ExportXlsMode.TUTTI) {
            return coefficientiContabiliService.getListaCoefficientiContabili()
        }
    }

    private def getNomeFileXls(String mode) {
        return "CoefficientiContabili_${tipoTributoSelezionato.tipoTributoAttuale}${mode == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
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
        commonService.creaPopup("/archivio/dizionari/coefficientiContabiliRicerca.zul", self, [filtro: filtro], { event ->
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
