package sportello.contribuenti


import document.FileNameGenerator
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class EventiResidenzeStoricheViewModel {

    // componenti
    Window self

    // Service
    ContribuentiService contribuentiService

    // Modello
    SoggettoDTO soggetto
    def listaEventi = []

    @NotifyChange("componenti")
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("sogg") SoggettoDTO sogg) {

        self = w
        soggetto = sogg
        listaEventi = contribuentiService.eventiEResidenzeStoriche(soggetto.matricola)
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    eventiToXls() {

        Map fields = [
                'DATA_INIZ'  : 'Dal',
                'DATA_EVEN'  : 'Al',
                'DESC_EVENTO': 'Descrizione Evento'
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.EVENTI_RESIDENZE_STORICHE,
                [idSoggetto: soggetto.id])

        XlsxExporter.exportAndDownload(nomeFile, listaEventi, fields)
    }


}
