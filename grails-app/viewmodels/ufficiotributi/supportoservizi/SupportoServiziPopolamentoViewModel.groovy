package ufficiotributi.supportoservizi

import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.supportoservizi.SupportoServiziService
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SupportoServiziPopolamentoViewModel {

    // services
    def springSecurityService

    CompetenzeService competenzeService
    SupportoServiziService supportoServiziService

    // componenti
    Window self

    // parametri
    Map parametri = [
            tipoTributo   : null,
            annoDa        : null,
            annoA         : null,
            eliminazioneEP: null,
    ]

    List listaTipiTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        def tipiTributoScrittura = competenzeService.tipiTributoUtenzaScrittura().collect { it.tipoTributo }

        def elencoTributi = supportoServiziService.getElencoTributi()
        def elencoTributiScrittura = elencoTributi.findAll { it.codice in tipiTributoScrittura }

        def tirbutoICI = elencoTributiScrittura.find { it.codice == 'ICI' }
        def tirbutoTASI = elencoTributiScrittura.find { it.codice == 'TASI' }

        listaTipiTributo = []
        if ((tirbutoICI != null) && (tirbutoTASI != null)) {
            listaTipiTributo << [codice: '%', descrizione: 'Tutti']
        }
        listaTipiTributo.addAll(elencoTributiScrittura)
    }

    @Command
    def onSelectTipoTributo() {

    }

    @Command
    def onOK() {

        if (!validaParametri()) {
            return
        }

        if (parametri.eliminazioneEP != 'N') {

            def count = supportoServiziService.conteggioUtentiAssegnati(parametri)
            if (count > 0) {
                String message = "Esistono dati da bonificare gia' assegnati a utenti !\n\nProseguire con l'eliminazione ?"
                Messagebox.show(message, "Attenzione",
                        Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    proseguiConPopolamento()
                                }
                            }
                        }
                )
            } else {
                proseguiConPopolamento()
            }
        } else {
            proseguiConPopolamento()
        }
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    // Chiude con conferma dell'operazione
    def proseguiConPopolamento() {

        Events.postEvent(Events.ON_CLOSE, self, [parametri: parametri])
    }

    // Valida parametri -> True se ok
    private boolean validaParametri() {

        String message = ""

        Short annoDa = parametri.annoDa ?: 0
        Short annoA = parametri.annoA ?: 9999

        if (!(parametri.tipoTributo)) {
            message += "Specificare Tipo Tributo\n"
        }
        if (annoDa < 1900) {
            message += "Anno da non valido\n"
        }
        if (annoDa > annoA) {
            message += "Anno da maggiore di Anno a\n"
        }
        if (!(parametri.eliminazioneEP)) {
            message += "Specificare tipo gestione Elaborazioni precedenti\n"
        }

        if (!(message.isEmpty())) {
            message = "Attenzione : \n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return message.isEmpty()
    }
}
