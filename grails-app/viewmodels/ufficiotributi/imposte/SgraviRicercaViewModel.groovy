package ufficiotributi.imposte


import it.finmatica.tr4.imposte.SgraviService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SgraviRicercaViewModel {


    // Componenti
    Window self

    // Services
    def springSecurityService
    SgraviService sgraviService

    // Comuni
    def isFiltroAttivo
    def listaMotivi

    def tipi = [
            D: "Discarico",
            R: "Rimborso",
            S: "Sgravio",
            X: ""
    ]

    // Parametri ricerca
    def parametri = [:]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parametriFiltroAttuali") def pfa) {

        this.self = w
        this.listaMotivi = [null] + sgraviService.getMotiviSgravio()

        if (pfa) {
            this.parametri = pfa
        } else {
            inizializzaParametriFiltro()
        }
    }


    // Eventi interfaccia
    @Command
    onSvuotaFiltri() {

        inizializzaParametriFiltro()

        this.isFiltroAttivo = filtroAttivo()
        BindUtils.postNotifyChange(null, null, this, "parametri")
    }

    @Command
    onCerca() {

        //Controllo estremi Numero
        if (parametri.numeroDa != null && parametri.numeroA != null
                && (parametri.numeroDa > parametri.numeroA)) {
            Clients.showNotification("'Numero da' non può essere maggiore di 'Numero a'",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        //Controllo estremi Importo
        if (parametri.importoDa != null && parametri.importoA != null
                && (parametri.importoDa > parametri.importoA)) {
            Clients.showNotification("'Importo da' non può essere maggiore di 'Importo a'",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        //Controllo estremi Date Elenco
        if (parametri.dataElencoDa != null && parametri.dataElencoA != null
                && (parametri.dataElencoA.before(parametri.dataElencoDa))) {
            Clients.showNotification("'Data Elenco da' non può essere maggiore di 'Data Elenco a'",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        this.isFiltroAttivo = filtroAttivo()
        Events.postEvent(Events.ON_CLOSE, self, [isFiltroAttivo: isFiltroAttivo, parametri: parametri])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private Boolean filtroAttivo() {
        return parametri.numeroDa != null || parametri.numeroA != null ||
                parametri.motivo != null ||
                parametri.dataElencoDa != null || parametri.dataElencoA != null ||
                parametri.tipo != null ||
                parametri.importoDa != null || parametri.importoA != null

    }

    private inizializzaParametriFiltro() {
        parametri.numeroDa = null
        parametri.numeroA = null
        parametri.motivo = listaMotivi[0]
        parametri.dataElencoDa = null
        parametri.dataElencoA = new Date()
        parametri.tipo = tipi[0]
        parametri.importoDa = null
        parametri.importoA = null

        this.isFiltroAttivo = filtroAttivo()
    }
}
