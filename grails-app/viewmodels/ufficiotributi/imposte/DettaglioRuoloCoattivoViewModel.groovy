package ufficiotributi.imposte

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.SpecieRuolo
import it.finmatica.tr4.commons.TipoRuolo
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettaglioRuoloCoattivoViewModel {

    // Services
    def springSecurityService

    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Componenti
    Window self

    // Generali
    boolean aggiornaStato = false

    TributiSession tributiSession

    TipoTributoDTO tipoTributo
    String tipoTributoDescr

    boolean modificabile = false
    boolean esistente = false

    // Dati
    RuoloDTO ruolo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") Long rr,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("modifica") boolean md) {

        this.self = w

        modificabile = md

        tipoTributo = TipoTributo.get(tt).toDTO()
        tipoTributoDescr = tipoTributo.getTipoTributoAttuale()

        if (rr != null) {
            ruolo = Ruolo.get(rr).toDTO()
            esistente = true
        } else {
            Short annoAttuale = Calendar.getInstance().get(Calendar.YEAR)
            ruolo = new RuoloDTO()
            ruolo.annoRuolo = annoAttuale
            ruolo.annoEmissione = annoAttuale
            ruolo.tipoTributo = tipoTributo
            ruolo.tipoRuolo = TipoRuolo.PRINCIPALE.tipoRuolo
            ruolo.specieRuolo = SpecieRuolo.COATTIVO.specieRuolo
            ruolo.dataEmissione = new Date()
            esistente = false
        }

        impostaRuolo()
    }

    // Eventi interfaccia

    @Command
    def onInserimentoAutomatico() {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/inserimentoAutomaticoRuolo.zul",
                self,
                [ruolo: ruolo.id]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {

                    ruolo = Ruolo.get(ruolo.id).toDTO()
                    impostaRuolo()
                    aggiornaStato = true
                }
            }
        }
        w.doModal()
    }

    @Command
    def onSalva() {

        if (!completaRuolo()) {
            return
        }
        if (!verificaRuolo()) {
            return
        }

        def report = listeDiCaricoRuoliService.salvaRuoloCoattivo(ruolo)
        if (report.result < 2) {
            ruolo = report.ruolo
            impostaRuolo()
        }

        visualizzaReport(report, "Salvataggio eseguito con successo")

        if (report.result == 0) {
            aggiornaStato = true
        }

        if (report.result == 0) {
            if (ruolo.getDomainObject() == null) {
                onChiudi()
            }
        }

        if (report.result == 0 && !esistente) {

            String messaggio = "Procedere con Inserimento Automatico ?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onInserimentoAutomatico()
                            }
                        }
                    }
            )
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, ruolo: ruolo])
    }

    // Funzioni interne

    // Attiva ruolo impostata
    def impostaRuolo() {

        BindUtils.postNotifyChange(null, null, this, "ruolo")

        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "esistente")
    }

    // Completa prima di verifica e salvataggio
    private def completaRuolo() {

        String message = ""
        boolean result = true

        if (ruolo.invioConsorzio == null) {
            ruolo.progrInvio = null
        }

        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    // Verifica coerenza dati
    private def verificaRuolo() {

        String message = ""
        boolean result = true

        def report = listeDiCaricoRuoliService.verificaRuoloCoattivo(ruolo)
        if (report.result != 0) {
            message = report.message
        }

        if (!message.empty) {

            message = "Attenzione :\n\n$message"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    // Visualizza report
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if (!(messageOnSuccess ?: '').empty) {
                    Clients.showNotification(messageOnSuccess, Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }
    }
}
