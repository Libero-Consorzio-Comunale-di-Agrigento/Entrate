package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.TariffaDomesticaDTO
import it.finmatica.tr4.tariffeDomestiche.TariffeDomesticheService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioTariffaDomesticaViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    // Componenti
    Window self

    // Services
    TariffeDomesticheService tariffeDomesticheService
    CommonService commonService

    // Comuni
    def tariffaDomesticaSelezionata
    def tipoOperazione
    def annoSelezionato
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tariffaDomesticaSelezionata") def ms,
         @ExecutionArgParam("tipoOperazione") def to,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.tipoOperazione = to
        this.annoSelezionato = ann

        initTariffaDomestica(ms)
        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Command
    onSalva() {

        // Controllo valori input
        if (tariffaDomesticaSelezionata.numeroFamiliari == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Numero Familiari"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }
        if (tariffaDomesticaSelezionata.tariffaQuotaFissa == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Tariffa Quota Fissa - Ab. Principale"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }
        if (tariffaDomesticaSelezionata.tariffaQuotaVariabile == null) {

            def messaggio = "Impossibile salvare.\nSpecificare Tariffa Quota Variabile - Ab. Principale"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }

        if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

            // Controllo se esiste già una tariffaDomestica con lo stesso id
            if (tariffeDomesticheService.existsTariffaDomestica(tariffaDomesticaSelezionata)) {
                String unformatted = labels.get('dizionario.notifica.esistente')
                def message = String.format(unformatted, 'una Tariffa Domestica', 'questo Numero Familiari')
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
                return
            }
        }

        tariffeDomesticheService.salvaTariffaDomestica(tariffaDomesticaSelezionata)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def initTariffaDomestica(def tariffaDomestica) {

        if (tipoOperazione == TipoOperazione.INSERIMENTO) {

            def newTariffaDomestica = new TariffaDomesticaDTO()
            newTariffaDomestica.anno = annoSelezionato as Short
            newTariffaDomestica.numeroFamiliari = null
            newTariffaDomestica.tariffaQuotaFissa = null
            newTariffaDomestica.tariffaQuotaVariabile = null
            newTariffaDomestica.tariffaQuotaFissaNoAp = null
            newTariffaDomestica.tariffaQuotaVariabileNoAp = null
            newTariffaDomestica.svuotamentiMinimi = null

            this.tariffaDomesticaSelezionata = newTariffaDomestica

            return
        }

        this.tariffaDomesticaSelezionata = tariffaDomestica
    }
}
