package archivio.dizionari


import it.finmatica.tr4.coefficientiDomestici.CoefficientiDomesticiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CoefficientiDomesticiDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCoefficienteDomesticoViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    // Componenti
    Window self

    // Services
    CoefficientiDomesticiService coefficientiDomesticiService
    CommonService commonService

    // Comuni
    def coefficienteDomesticoSelezionato
    def tipoOperazione
    def annoSelezionato

    def labels


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("coefficienteDomesticoSelezionato") def ms,
         @ExecutionArgParam("tipoOperazione") def to,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.tipoOperazione = to
        this.annoSelezionato = ann

        initCoefficienteDomestico(ms)

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {

        // Controllo valori input
        if (coefficienteDomesticoSelezionato.numeroFamiliari == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Numero Familiari"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }
        if (coefficienteDomesticoSelezionato.coeffAdattamento == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Coeff. Adattamento - Ab. Principale"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }
        if (coefficienteDomesticoSelezionato.coeffProduttivita == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Coeff. Produttività - Ab. Principale"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }

        if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

            // Controllo se esiste già un coefficienteContabile con lo stesso id (anno-categoriaCatasto)
            if (coefficientiDomesticiService.existsCoefficienteDomestico(coefficienteDomesticoSelezionato)) {

                String unformatted = labels.get('dizionario.notifica.esistente')
                def message = String.format(unformatted, 'un Coefficiente Domestico', 'questo Numero Familiari')

                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)

                return
            }
        }

        coefficientiDomesticiService.salvaCoefficienteDomestico(coefficienteDomesticoSelezionato)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }


    private def initCoefficienteDomestico(def coefficienteDomestico) {

        if (tipoOperazione == TipoOperazione.INSERIMENTO) {

            def newCoefficienteDomestico = new CoefficientiDomesticiDTO()
            newCoefficienteDomestico.anno = annoSelezionato as Short
            newCoefficienteDomestico.numeroFamiliari = null
            newCoefficienteDomestico.coeffAdattamento = null
            newCoefficienteDomestico.coeffProduttivita = null
            newCoefficienteDomestico.coeffAdattamentoNoAp = null
            newCoefficienteDomestico.coeffProduttivitaNoAp = null
            this.coefficienteDomesticoSelezionato = newCoefficienteDomestico

            return
        }

        this.coefficienteDomesticoSelezionato = coefficienteDomestico

    }

}
