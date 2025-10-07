package archivio.dizionari

import it.finmatica.tr4.stradario.StradarioService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioStradarioDenominazioneViewModel {

    // Componenti
    Window self

    // Services
    StradarioService stradarioService

    // Comuni
    def parametri = [:]
    def codVia
    def modifica
    def denominazione


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codVia") def cv,
         @ExecutionArgParam("modifica") def md,
         @ExecutionArgParam("denominazione") def den) {

        this.self = w
        this.codVia = cv
        this.modifica = md

        if (den != null) {
            parametri.progrVia = den.progrVia
            parametri.descNominativo = den.descrizione
        }

    }


    @Command
    def onSalva() {

        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join(), Clients.NOTIFICATION_TYPE_WARNING,
                    null, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [esegui: true, parametri: parametri])
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [esegui: false])
    }


    private def controllaParametri() {

        def errori = []

        if (parametri?.progrVia == null) {
            errori << "Il Progressivo Via è obbligatorio\n"
        } else if (parametri.progrVia < 1 || parametri.progrVia > 99) {
            errori << "Il Progressivo Via deve essere un numero positivo compreso tra 1 e 99\n"
        }

        if (!modifica && parametri?.progrVia != null && stradarioService.existDenominazione(codVia, parametri.progrVia)) {
            errori << "Esiste già una Denominazione con lo stesso Progressivo Via\n"
        }

        return errori
    }


}
