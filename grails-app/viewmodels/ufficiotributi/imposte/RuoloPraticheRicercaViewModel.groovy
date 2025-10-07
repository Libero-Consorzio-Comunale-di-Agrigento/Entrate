package ufficiotributi.imposte


import it.finmatica.tr4.imposte.FiltroRicercaListeDiCaricoRuoliPratiche
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class RuoloPraticheRicercaViewModel {

    // componenti
    Window self

    def filtroVersamenti = [null] +
            [codice: -1, descrizione: 'Tutti'] +
            [codice: 10, descrizione: 'Con Versamenti (Qualsiasi)'] +
            [codice: 11, descrizione: 'Con Versamenti spontanei'] +
            [codice: 12, descrizione: 'Con Versamenti da compensazione'] +
            [codice: 20, descrizione: 'Senza Versamenti']

    def filtroPEC = [null] +
            [codice: -1, descrizione: 'Tutti'] +
            [codice: 1, descrizione: 'No'] +
            [codice: 2, descrizione: 'Si\'']

    // parametri
    FiltroRicercaListeDiCaricoRuoliPratiche mapParametri
    def disabilitaANumero = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("parRicerca") def parametriRicerca) {

        this.self = w

        mapParametri = parametriRicerca ?: new FiltroRicercaListeDiCaricoRuoliPratiche()
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
        onCambiaNumero()
    }

    @Command
    onCerca() {

        if (mapParametri.numeroDa != null && mapParametri.numeroA != null) {
            if (mapParametri.numeroDa.padLeft(15, " ") > mapParametri.numeroA.padLeft(15, " ")) {
                Clients.showNotification("Numero Da deve essere minore di A", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                return
            }
        }

        if (mapParametri.dataNotificaDa != null && mapParametri.dataNotificaA != null) {
            if (mapParametri.dataNotificaDa > mapParametri.dataNotificaA) {
                Clients.showNotification("Data Notifica Da deve essere minore di A", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                return
            }
        }

        if (mapParametri.dataEmissioneDa != null && mapParametri.dataEmissioneA != null) {
            if (mapParametri.dataEmissioneDa > mapParametri.dataEmissioneA) {
                Clients.showNotification("Data Emissione Da deve essere minore di A", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                return
            }
        }


        Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", parRicerca: mapParametri])
    }

    @Command
    onSvuotaFiltri() {

        mapParametri = new FiltroRicercaListeDiCaricoRuoliPratiche()
        BindUtils.postNotifyChange(null, null, this, "mapParametri")
    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCambiaNumero(){

        if (mapParametri?.numeroA != null && mapParametri.numeroA.contains('%')){
            Clients.showNotification("Carattere '%' non consentito nel campo Numero A", Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 2000, true)
            mapParametri.numeroA = ""
            return
        }

        if (mapParametri.numeroDa != null && mapParametri.numeroDa.contains('%')){
            disabilitaANumero = true
        }else{
            disabilitaANumero = false
        }

        BindUtils.postNotifyChange(null, null, this, "disabilitaANumero")

    }

}
