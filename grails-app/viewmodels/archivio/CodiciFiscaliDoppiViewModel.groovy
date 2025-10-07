package archivio

import document.FileNameGenerator
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

class CodiciFiscaliDoppiViewModel {

    // Componenti
    Window self

    @Wire("#paging")
    protected Paging paging

    // Service
    SoggettiService soggettiService

    // Modello
    def lista = []
    def tuttoElenco = []
    def ordinamento = 'a'
    // paginazione
    int activePage  = 0
    int pageSize    = 15
    int totalSize   = 0

    boolean integrazioneGSD = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,  @ExecutionArgParam("integrazioneGSD") @Default('false') boolean integrazioneGSD) {
        this.self = w
        this.integrazioneGSD = integrazioneGSD
        caricaLista(true)
    }

    @Command
    onRefresh() {
        resetPaginazione()
        caricaLista(true)
    }

    @Command
    onStampa() {
        generaReport(tuttoElenco)
    }

    @Command onPaging() {
        caricaLista(false)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command onCerca() {
       caricaLista(true)
    }

    private caricaLista(boolean resetPaginazione) {
        if ((tuttoElenco.size() == 0) || (resetPaginazione != false)) {
            activePage = 0
            def ls = soggettiService.codiciFiscaliDoppi(pageSize, activePage, true,ordinamento)
            tuttoElenco = ls.records
            totalSize = ls.totalCount
        }

        int fromIndex = pageSize * activePage;
        int toIndex = Math.min((fromIndex + pageSize), totalSize);
        lista = tuttoElenco.subList(fromIndex, toIndex)

        if(totalSize<=pageSize) activePage = 0
        if(paging) paging.setTotalSize(totalSize)

        BindUtils.postNotifyChange(null, null, this, "lista")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    private resetPaginazione(){
        activePage = 0
        totalSize = 0
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    def generaReport(def lista){
        String nomeFile = FileNameGenerator.generateFileName(
				FileNameGenerator.GENERATORS_TYPE.JASPER,
				FileNameGenerator.GENERATORS_TITLES.CODICI_FISCALI_DOPPI,
				[:])
        String testata=""
        def report =  soggettiService.generaReportCodiciFiscaliDoppi(testata,lista)

        if (report == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {
            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }
}
