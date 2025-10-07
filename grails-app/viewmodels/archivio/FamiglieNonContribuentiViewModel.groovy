package archivio

import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

class FamiglieNonContribuentiViewModel {

    // Componenti
    Window self

    @Wire("#paging")
    protected Paging paging

    // Service
    SoggettiService soggettiService

    // Modello
    def lista = []
    def tuttoElenco = []
    // paginazione
    int activePage = 0
    int pageSize = 15
    int totalSize

    def ordinamento = 'a'
    def listaFetch = []
    def listaTipiTributo
    def filtri = [
            cognome    : "",
            nome       : "",
            codFiscale : "",
            id         : null,
            indirizzo  : "",
            codiceVia  : null,
            codFamiglia: null,
            tipoTributo: ""
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR);
        listaTipiTributo = soggettiService.getListaTributi(annoCorrente)

        filtri.tipoTributo = listaTipiTributo[0]
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtri.indirizzo = (event.data.denomUff ?: "")
        filtri.codiceVia = (event.data.id ?: null)
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeTipoTributo() {
        lista = []
        tuttoElenco = []
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
        if (filtri.tipoTributo) {
            generaReport(tuttoElenco)
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
    onSvuotaFiltri() {
        filtri.cognome = ""
        filtri.nome = ""
        filtri.codFiscale = ""
        filtri.id = null
        filtri.indirizzo = ""
        filtri.codiceVia = null
        filtri.codFamiglia = null
        filtri.tipoTributo = null
        ordinamento = 'a'
        lista = []
        tuttoElenco = []
        resetPaginazione()
        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "ordinamento")
        BindUtils.postNotifyChange(null, null, this, "lista")
    }

    @Command
    onCerca() {
        caricaLista(true)
    }

    private caricaLista(boolean resetPaginazione) {
        if (filtri.tipoTributo) {

            if (filtri.indirizzo == "") {
                filtri.codiceVia = null
            }

            if (filtri.codFiscale) {
                filtri.codFiscale = filtri.codFiscale.toUpperCase()
            }

            if ((tuttoElenco.size() == 0) || resetPaginazione) {
                activePage = 0
                def ls = soggettiService.famiglieNonContribuenti(filtri, pageSize, activePage, true, ordinamento)

                tuttoElenco = ls.records
                totalSize = ls.totalCount
            }

            int fromIndex = pageSize * activePage;
            int toIndex = Math.min((fromIndex + pageSize), totalSize);
            lista = tuttoElenco.subList(fromIndex, toIndex)

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

    def generaReport(def lista) {
        String nomeFile = "Famiglie Non Contribuenti"
        String testata = "Tipo Tributo: " + filtri.tipoTributo.nome + " - " + filtri.tipoTributo.descrizione
        def report = soggettiService.generaReportFamiglieNonContribuenti(testata, lista)

        if (report == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {
            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }
}
