package archivio.dizionari

import it.finmatica.tr4.carichi.CarichiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.CaricoTarsuDTO
import org.zkoss.bind.BindContext
import org.zkoss.bind.Converter
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCarichiViewModel {

    //  Services
    CarichiService carichiService
    CommonService commonService

    //  Componenti
    Window self


    //  Tracciamento dello stato
    boolean isModifica = false
    boolean isLettura = false

    CaricoTarsuDTO carico
    def listaModalita
    def listaMesiCalcolo
    def listaRatePerequative
    def rataPerequativeActive

    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("selezionato") CaricoTarsuDTO selected,
         @ExecutionArgParam("listaModalita") def listaModalita,
         @ExecutionArgParam("listaRatePerequative") def listaRatePerequative,
         @ExecutionArgParam("isModifica") boolean isModifica,
         @ExecutionArgParam("isLettura") @Default('false') boolean isLettura) {

        this.self = w

        this.listaModalita = listaModalita
        this.listaRatePerequative = listaRatePerequative

        this.carico = selected ?: new CaricoTarsuDTO()

        this.rataPerequativeActive = listaRatePerequative.find { it?.codice == this.carico.rataPerequative }

        this.isModifica = isModifica
        this.isLettura = isLettura ?: false

        this.listaMesiCalcolo = [null] + carichiService.getListaMesiCalcolo()

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {
        if (carico.modalitaFamiliari == 0) {
            carico.modalitaFamiliari = null
        }

        carico.rataPerequative = rataPerequativeActive?.codice

        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }

        if (!isModifica && alreadyExist()) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted, 'un Carico', 'questo Anno')

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)

            return
        }

        Events.postEvent(Events.ON_CLOSE, self, ["carico": carico])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def controllaParametri() {

        def errori = []

        if (null == carico.anno) {
            errori << "Il campo Anno è obbligatorio"
        }

        if (carico.maggiorazioneTares != null && carico.maggiorazioneTares < new BigDecimal("0.01")) {
            errori << "Componenti Perequative deve essere maggiore o uguale di 0,01"
        }

        if (carico.compensoMinimo != null && carico.compensoMinimo <= new BigDecimal("0")) {
            errori << "Compenso Minimo deve essere maggiore di 0"
        }

        return errori
    }

    private boolean alreadyExist() {
        return carichiService.exist(["anno": carico.anno,])
    }

    FlagConverter getFlagConverter() {
        return new FlagConverter()
    }

    private class FlagConverter implements Converter {
        Object coerceToUi(Object val, Component comp, BindContext ctx) {
            String valueFromVM = (String) val
            if (!valueFromVM) {
                return "false"
            }
            if (valueFromVM == "S") {
                return "true"
            }
            if (valueFromVM == "N") {
                return "false"
            }
            return "false"
        }

        Object coerceToBean(Object val, Component comp, BindContext ctx) {
            String valueFromZul = (String) val
            if (valueFromZul == "true") {
                return "S"
            }
            if (valueFromZul == "false") {
                return null
            }
            return null
        }
    }
}
