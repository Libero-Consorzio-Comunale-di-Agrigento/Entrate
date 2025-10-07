package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.componentiSuperficie.ComponentiSuperficieService
import it.finmatica.tr4.dto.ComponentiSuperficieDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioComponentiSuperficieViewModel {

    //  Services
    ComponentiSuperficieService componentiSuperficieService
    CommonService commonService

    //  Componenti
    Window self

    //  Comuni
    def tipoTributo
    def labels

    //  Tracciamento dello stato
    boolean isModifica = false
    boolean esistente = false
    boolean isLettura = false

    ComponentiSuperficieDTO componenteSuperficie

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("selezionato") ComponentiSuperficieDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isLettura") @Default("false") boolean isLettura) {
        this.self = w
        this.tipoTributo = tipoTributo

        this.componenteSuperficie = selected ?: new ComponentiSuperficieDTO()

        this.esistente = (null != selected)
        this.isModifica = isModifica
        this.isLettura = isLettura ?: false
        this.labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        def errori = controllaParametri()

        if (!errori.empty) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, ["componenteSuperficie": componenteSuperficie])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []

        if (null == componenteSuperficie.anno) {
            errori << "Il campo Anno è obbligatorio"
        }
        if (null == componenteSuperficie.numeroFamiliari) {
            errori << "Il campo Numero Familiari è obbligatorio"
        }

        if (componenteSuperficie.daConsistenza > componenteSuperficie.aConsistenza) {
            errori << 'Da Consistenza maggiore di A Consistenza'
        }

        if (!errori.empty) {
            return errori
        }

        if (!isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted, 'un Componente Superficie', 'questo Anno e Numero Familiari')
            return [message]
        }

        return []
    }

    private boolean alreadyExist() {
        return componentiSuperficieService.exist(["anno": componenteSuperficie.anno, "numeroFamiliari": componenteSuperficie.numeroFamiliari])
    }
}
