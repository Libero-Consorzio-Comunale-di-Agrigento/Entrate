package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.MotivoSgravioDTO
import it.finmatica.tr4.sgravio.MotivoSgravioService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioMotivoSgravioViewModel {

    // Services
    MotivoSgravioService motivoSgravioService
    CommonService commonService

    // Componenti
    Window self

    // tracciamento dello stato
    boolean isModifica = false
    boolean esistente = false
    boolean isClone = false
    boolean isLettura = false
    def labels

    MotivoSgravioDTO motivoSgravio

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("motivoSgravioSelezionato") MotivoSgravioDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isClone") boolean isClone,
         @ExecutionArgParam("isLettura") @Default("false") boolean isLettura
    ) {
        this.self = w
        this.motivoSgravio = selected ?: new MotivoSgravioDTO()

        this.esistente = (null != selected)
        this.isModifica = isModifica
        this.isClone = isClone
        this.isLettura = isLettura
        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }

        if (!isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    'un Motivo Sgravio',
                    "questo Sgravio")

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, ["motivoSgravio": motivoSgravio])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []

        if (null == motivoSgravio.id) {
            errori << "Il campo Sgravio è obbligatorio"
        }
        if (StringUtils.isBlank(motivoSgravio.descrizione)) {
            errori << "Il campo Descrizione è obbligatorio"
        }
        return errori
    }

    private boolean alreadyExist() {
        return motivoSgravioService.exist(motivoSgravio)
    }
}
