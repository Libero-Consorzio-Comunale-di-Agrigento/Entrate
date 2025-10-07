package archivio.dizionari

import it.finmatica.tr4.coefficientiContabili.CoefficientiContabiliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CoefficientiContabiliDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCoefficienteContabileViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    // Componenti
    Window self

    // Services
    CoefficientiContabiliService coefficientiContabiliService
    CommonService commonService

    // Comuni
    def coefficienteContabileSelezionato
    def tipoOperazione
    def annoSelezionato
    def labels


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("coefficienteContabileSelezionato") def ms,
         @ExecutionArgParam("tipoOperazione") def to,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.tipoOperazione = to
        this.annoSelezionato = ann

        initCoefficienteContabile(ms)

        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {

        if (coefficienteContabileSelezionato.annoCoeff == null) {
            def messaggio = "Anno Coefficiente non valido"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }

        // Controllo valori input
        if (coefficienteContabileSelezionato.coeff == null || coefficienteContabileSelezionato.coeff < 0) {
            def messaggio = "Coefficiente non valido"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }

        if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

            // Controllo se esiste già un coefficienteContabile con lo stesso id (anno-categoriaCatasto)
            if (coefficientiContabiliService.existsCoefficienteContabile(coefficienteContabileSelezionato)) {

                String unformatted = labels.get('dizionario.notifica.esistente')
                def message = String.format(unformatted,
                        "un Coefficiente Contabile",
                        "questo Anno Coefficiente e Coefficiente")

                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
                return
            }
        }

        coefficientiContabiliService.salvaCoefficienteContabile(coefficienteContabileSelezionato)

        Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }


    private def initCoefficienteContabile(def coefficienteContabile) {

        if (tipoOperazione == TipoOperazione.INSERIMENTO) {

            def newCoefficienteContabile = new CoefficientiContabiliDTO()
            newCoefficienteContabile.anno = annoSelezionato as Short
            newCoefficienteContabile.annoCoeff = annoSelezionato as Short
            newCoefficienteContabile.coeff = null

            this.coefficienteContabileSelezionato = newCoefficienteContabile

        } else {
            this.coefficienteContabileSelezionato = coefficienteContabile
        }

    }

}