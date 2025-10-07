package archivio.dizionari

import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.TipoUtilizzo
import it.finmatica.tr4.UtilizzoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.tipoUtilizzo.TipiUtilizzoService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioUtilizzoViewModel {

    // Services
    TipiUtilizzoService tipiUtilizzoService
    CommonService commonService

    // Componenti
    Window self

    // Comuni
    def listaTipiUtilizzo
    def tipoUtilizzoSelezionato
    def listaTipiTributo
    def tipoTributoSelezionato
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributoSelezionato") def tt) {

        this.self = w

        this.tipoTributoSelezionato = tt

        this.listaTipiUtilizzo = tipiUtilizzoService.getListaUtilizzoTributoCombo([tipoTributo:tipoTributoSelezionato.tipoTributo])
        this.tipoUtilizzoSelezionato = listaTipiUtilizzo[0]
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    onSalva() {

        UtilizzoTributo utilizzoTributo = new UtilizzoTributo()
        utilizzoTributo.tipoUtilizzo = TipoUtilizzo.get(tipoUtilizzoSelezionato.tipoUtilizzo)
        utilizzoTributo.tipoTributo = TipoTributo.findByTipoTributo(tipoTributoSelezionato.tipoTributo)

        tipiUtilizzoService.salvaUtilizzoTributo(utilizzoTributo)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
