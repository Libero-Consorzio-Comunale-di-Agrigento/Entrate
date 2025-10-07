package archivio

import document.FileNameGenerator
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

class CodiciFiscaliIncoerentiViewModel {

    // Componenti
    Window self

    @Wire("#paging")
    protected Paging paging

    // Service
    SoggettiService soggettiService

    // Modello
    def lista = []
    def elencoCF = []
    int tipoIncongruenzaSelected = -1
    // paginazione
    int activePage = 0
    int pageSize = 15
    int totalSize

    def listaTipiIncogruenze = [[codice: -1, descrizione: 'Selezionare un\'incongruenza'],
                                [codice: 1, descrizione: 'Codice di Anagrafe diverso dal Calcolato'],
                                [codice: 2, descrizione: 'Codice del Contribuente diverso dal Calcolato'],
                                [codice: 3, descrizione: 'Codice di Anagrafe diverso dal Contribuente'],
                                [codice: 4, descrizione: 'Tutte le Incongruenze']
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        tipoIncongruenzaSelected = listaTipiIncogruenze.get(0).codice
        BindUtils.postNotifyChange(null, null, this, "tipoIncongruenzaSelected")
    }

    @Command
    onChangeTipoIncogruenza() {
        lista = []
        elencoCF = []
        resetPaginazione()
        BindUtils.postNotifyChange(null, null, this, "lista")
    }

    @Command
    onRefresh() {
        resetPaginazione()
        caricaLista(true)
    }

    @Command
    onStampa() {
        if (tipoIncongruenzaSelected != -1) {
            def descrizione = listaTipiIncogruenze.find { it.codice == tipoIncongruenzaSelected }?.descrizione
            generaReport(descrizione, elencoCF)
        }
    }

    @Command
    onPaging() {
        caricaLista(false)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCerca() {
        caricaLista(true)
    }

    private caricaLista(boolean resetPaginazione) {

        if (tipoIncongruenzaSelected != -1) {
            if ((elencoCF.size() == 0) || (resetPaginazione != false)) {
                activePage = 0
                def ls = soggettiService.codiciFiscaliIncoerenti(tipoIncongruenzaSelected, pageSize, activePage, true)
                elencoCF = ls.records
                totalSize = ls.totalCount
            }

            int fromIndex = pageSize * activePage;
            int toIndex = Math.min((fromIndex + pageSize), totalSize);
            lista = elencoCF.subList(fromIndex, toIndex)

            if (totalSize <= pageSize) activePage = 0
            paging.setTotalSize(totalSize)

            BindUtils.postNotifyChange(null, null, this, "lista")
            BindUtils.postNotifyChange(null, null, this, "totalSize")
            BindUtils.postNotifyChange(null, null, this, "activePage")
        }
    }

    private resetPaginazione() {
        activePage = 0
        totalSize = 0
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    def generaReport(String tipo, def lista) {
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.CODICI_FISCALI_INCOERENTI,
                [:])
        def report = soggettiService.generaReportCodiciFiscaliIncoerenti(tipo, lista)

        if (report == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {
            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }
}
