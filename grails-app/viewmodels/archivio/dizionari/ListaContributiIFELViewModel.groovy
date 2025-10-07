package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheService
import it.finmatica.tr4.dto.ContributiIfelDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Window

class ListaContributiIFELViewModel {

    // Componenti
    Window self

    //Servizi
    CodificheService codificheService

    //Modello
    List<ContributiIfelDTO> lista
    def elenco = []
    ContributiIfelDTO elementoSelezionato

    /// Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        caricaLista(true)
    }

    @NotifyChange("lista")
    @Command
    onRefresh() {
        caricaLista(true)
    }

    @Command
    def onCambioPagina() {
        caricaLista(false)
    }

    @Command
    onAggiungi() {
        Window w = Executions.createComponents("/archivio/dizionari/contributiIFEL.zul", self, [contributo: null, modifica: false, duplica: false])
        w.doModal()
        w.onClose() { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    onModifica() {
        Window w = Executions.createComponents("/archivio/dizionari/contributiIFEL.zul", self, [contributo: elementoSelezionato, modifica: true, duplica: false])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    onDuplica() {
        Window w = Executions.createComponents("/archivio/dizionari/contributiIFEL.zul", self, [contributo: elementoSelezionato, modifica: false, duplica: true])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    onExportXls() {

        Map fields

        if (elenco != null && !elenco.empty) {

            fields = [
                    "anno"    : "Anno",
                    "aliquota": "Aliquota"
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CONTRIBUTI_IFEL,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, elenco, fields)
        }

    }

    private caricaLista(boolean resetPaginazione) {

        if ((elenco.size() == 0) || resetPaginazione) {
            pagingList.activePage = 0
            elenco = codificheService.getContributi()
            elenco.sort { it.anno ? -it.anno : 0 }
            pagingList.totalSize = elenco.size()
            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        lista = elenco.subList(fromIndex, toIndex)
        elementoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "lista")
        BindUtils.postNotifyChange(null, null, this, "elementoSelezionato")
    }
}
