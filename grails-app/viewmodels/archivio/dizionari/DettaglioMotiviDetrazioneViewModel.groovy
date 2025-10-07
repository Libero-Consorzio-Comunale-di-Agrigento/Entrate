package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.MotiviDetrazioneDTO
import it.finmatica.tr4.motiviDetrazione.MotiviDetrazioneService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioMotiviDetrazioneViewModel {

    //  Services
    MotiviDetrazioneService motiviDetrazioneService
    CommonService commonService

    //  Componenti
    Window self

    //  Comuni
    def tipoTributo

    //  Tracciamento delle modifiche
    boolean shouldRefresh = false
    //---------------------------

    //  Tracciamento dello stato
    boolean isModifica = false
    boolean esistente = false
    boolean isClone = false
    boolean isLettura = false

    MotiviDetrazioneDTO motivoDetrazione

    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("selezionato") MotiviDetrazioneDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isClone") boolean isClone,
         @ExecutionArgParam("isLettura") @Default('false') boolean isLettura) {
        this.self = w
        this.tipoTributo = tipoTributo

        this.motivoDetrazione = selected ?: new MotiviDetrazioneDTO(tipoTributo)

        this.esistente = (null != selected)
        this.isModifica = isModifica
        this.isClone = isClone
        this.isLettura = isLettura ?: false

        this.labels = commonService.getLabelsProperties('dizionario')
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
            def message = String.format(unformatted, 'un Motivo Detrazione', 'questo Motivo Detrazione')
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, ["motivoDetrazione": motivoDetrazione])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []

        if (null == motivoDetrazione.motivoDetrazione) {
            errori << "Il campo Motivo Detrazione è obbligatorio"
        }
        if (StringUtils.isBlank(motivoDetrazione.descrizione)) {
            errori << "Il campo Descrizione è obbligatorio"
        }

        return errori
    }

    private boolean alreadyExist() {
        return motiviDetrazioneService.exist(motivoDetrazione.tipoTributo, ["motivoDetrazione": motivoDetrazione.motivoDetrazione])
    }
}
