package archivio.dizionari

import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.dto.MotiviPraticaDTO
import it.finmatica.tr4.motiviPratica.MotiviPraticaService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioMotiviPraticaViewModel {

    // Services
    MotiviPraticaService motiviPraticaService

    // Componenti
    Window self

    // Comuni
    def tipoTributo

    // tracciamento dello stato
    boolean isModifica = false
    boolean esistente = false
    boolean isClone = false
    boolean isLettura = false

    MotiviPraticaDTO motivoPratica

    Collection<TipoPratica> tipiPraticaAbilitati

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tipiPraticaAbilitati") Collection<TipoPratica> tipiPraticaAbilitati,
         @ExecutionArgParam("selezionato") MotiviPraticaDTO selected,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isClone") boolean isClone,
         @ExecutionArgParam("isLettura") @Default("false") boolean isLettura) {
        this.self = w
        this.tipoTributo = tipoTributo

        this.tipiPraticaAbilitati = tipiPraticaAbilitati
        this.motivoPratica = selected ?: new MotiviPraticaDTO(tipoTributo)

        this.esistente = (null != selected)
        this.isModifica = isModifica
        this.isClone = isClone
        this.isLettura = isLettura ?: false
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        def next = motiviPraticaService.getNextSequenza(tipoTributo)
        motivoPratica.sequenza = next

        Events.postEvent(Events.ON_CLOSE, self, ["motivoPratica": motivoPratica])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []
//        Controllo annullato per allineamento con TR4
//        if (null == motivoPratica.anno) {
//            errori << "Il campo Anno è obbligatorio"
//        }
        if (StringUtils.isBlank(motivoPratica.tipoPratica)) {
            errori << "Il campo Tipo Pratica è obbligatorio"
        }
        if (StringUtils.isBlank(motivoPratica.motivo)) {
            errori << "Il campo Motivo è obbligatorio"
        }

        return errori
    }

}
