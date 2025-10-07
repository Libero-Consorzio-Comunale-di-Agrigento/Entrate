package pratiche.denunce


import it.finmatica.tr4.denunce.DenunceService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCostiStoriciViewModel {

    // Services
    DenunceService denunceService

    // Componenti
    Window self

    // Comuni
    def costoStorico
    def modifica


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("costoStorico") def cs,
         @ExecutionArgParam("modifica") def md) {

        self = w

        this.modifica = md
        this.costoStorico = cs

    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [salvato: false])
    }

    @Command
    onSalva() {

        def errori = controllaParametri()

        if (errori.length() > 0) {
            Clients.showNotification(errori, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [salvato: true, costoStorico: costoStorico])
    }


    private def controllaParametri() {

        def errori = ""

        if (!modifica) {

            if (denunceService.existCostoStorico(costoStorico.anno, costoStorico.oggettoPratica.id)) {
                errori += "Esiste già un Costo Storico con lo stesso Anno\n"
            }

        }

        if (costoStorico.anno == null) {
            errori += "L'Anno è obbligatorio\n"
        }

        if (costoStorico.costo == null) {
            errori += "Il Costo è obbligatorio\n"
        }

        return errori
    }

}
