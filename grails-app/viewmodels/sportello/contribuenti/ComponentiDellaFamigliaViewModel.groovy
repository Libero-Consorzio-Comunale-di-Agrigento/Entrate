package sportello.contribuenti


import document.FileNameGenerator
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ComponentiDellaFamigliaViewModel {

    // componenti
    Window self

    // Service
    ContribuentiService contribuentiService

    // Modello
    SoggettoDTO soggetto
    def listaComponenti = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("sogg") SoggettoDTO sogg) {

        self = w
        soggetto = sogg
        listaComponenti = contribuentiService.componentiFamiglia(soggetto.fascia, soggetto.codFam)
        BindUtils.postNotifyChange(null, null, this, "componenti")

    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onOpenSituazioneContribuente(@BindingParam("ni") Long ni) {
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }


    @Command
    componentiToXls() {

        Map fields = [
                'RAPPORTO_PAR'       : 'Rapporto',
                'COGNOME_NOME'       : 'Cognome e Nome',
                'COD_FISCALE'        : 'Cod. Fiscale',
                'CODICE_CONTRIBUENTE': 'Cod.Contribuente',
                'TRIB_ICI'           : 'IMU',
                'TRIB_TASI'          : 'TASI',
                'TRIB_ICP'           : 'ICP',
                'TRIB_RSU'           : 'TARSU',
                'TRIB_TOSAP'         : 'TOSAP',
                'DATA_NAS'           : 'Data Nascita',
                'COMUNE'             : 'Comune',
                'STATO'              : 'Iscrizione/Cancellazione',
                'DATA_ULT_EVE'       : 'Data Evento',
                'COMUNE_EVENTO'      : 'Comune Evento'
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COMPONENTI_DELLA_FAMIGLIA,
                [idSoggetto: soggetto.id])

        XlsxExporter.exportAndDownload(nomeFile, listaComponenti, fields)
    }

}
