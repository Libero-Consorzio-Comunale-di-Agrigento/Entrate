package ufficiotributi.versamenti


import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class StampeVersamentiViewModel {

    // Componenti
    Window self

    // Services


    // Comuni
    def titolo

    def anno
    def codFiscale
    def scarto
    def ordinamento
    def dal
    def al

    /**
     *  SQ - Squadratura Totale
     *  TV - Totale Versamenti
     *  TVG - Totale Versamenti per Giorno
     *  Niente - Versamenti Doppi
     */
    def tipoStampa


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoStampa") def ts,
         @ExecutionArgParam("titolo") def tl) {

        this.self = w
        this.tipoStampa = ts
        this.titolo = tl

        scarto = 0
        anno = Calendar.getInstance().get(Calendar.YEAR)
        al = new Date()

        if (tipoStampa == "TVG"){
            ordinamento = "tutti"
        }else{
            ordinamento = "alfa"
        }
    }

    // Eventi interfaccia

    @Command
    onOk() {

        if (anno == null){
            Clients.showNotification("L'anno è obbligatorio", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        if (tipoStampa == "TVG"){

            if (al == null){
                al = new Date()
            }
            if (dal == null){
                dal = new Date(0, 00, 01)
            }

            if (dal > al) {
                Clients.showNotification("Date non coerenti", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                return
            }
        }

        Events.postEvent(Events.ON_CLOSE, self, [codFiscale: codFiscale, anno: anno, scarto: scarto, ordinamento: ordinamento, dal:dal, al:al])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
