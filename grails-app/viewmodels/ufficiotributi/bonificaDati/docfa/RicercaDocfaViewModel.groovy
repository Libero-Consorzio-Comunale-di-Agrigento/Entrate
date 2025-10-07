package ufficiotributi.bonificaDati.docfa

import it.finmatica.tr4.denunce.DenunceService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class RicercaDocfaViewModel {

    // componenti
    Window self

    DenunceService denunceService

    def filtro = [:]

    List<HashMap<BigDecimal,String>> documentIdList

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") def filtro) {

        this.self = w
        this.filtro = filtro
        documentIdList = denunceService.getProgrDocumenti(DenunceService.DOCFCA,null)
        documentIdList = [["descrizione": "Tutti"]] + documentIdList
    }

    @Command
    onCerca() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", docDaCercare: filtro])
    }

    @Command
    onSvuotaFiltri() {
        filtro.documento = null
        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Chiudi", docDaCercare: filtro])
    }
}
