package archivio.dizionari

import it.finmatica.tr4.TipoNotifica
import it.finmatica.tr4.codifiche.CodificheTipoNotificaService
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.TipoNotificaDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioTipiNotificaViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE
    }

    // Componenti
    Window self

    OggettiCacheMap oggettiCacheMap

    // Services
    CodificheTipoNotificaService codificheTipoNotificaService


    // Comuni
    def tipoNotificaSelezionata
    def tipoOperazione


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoNotificaSelezionata") def tns,
         @ExecutionArgParam("tipoOperazione") def to) {

        this.self = w

        this.tipoNotificaSelezionata = tns ?: new TipoNotificaDTO()
        this.tipoOperazione = to

    }

    // Eventi interfaccia
    @Command
    onSalva() {

        // Controllo id
        if (tipoNotificaSelezionata.tipoNotifica < 0){
            Clients.showNotification("L'identificatore deve essere positivo", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        if (tipoNotificaSelezionata.tipoNotifica > 80){
            Clients.showNotification("L'identificatore deve essere compreso tra 1 e 80", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        // Converto la descrizione in maiuscolo
        tipoNotificaSelezionata.descrizione = tipoNotificaSelezionata.descrizione.toUpperCase()

        if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO){

            // Controllo se esiste già un tipo notifica con lo stesso id
            if (codificheTipoNotificaService.existsTipoNotifica(tipoNotificaSelezionata.tipoNotifica)){
                Clients.showNotification("Esiste già un Tipo Notifica con lo stesso identificatore", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                return
            }

            // Imposto come default flagModificabile = true sull'aggiunta di un nuovo Tipo Notifica
            tipoNotificaSelezionata.flagModificabile = true
        }

        codificheTipoNotificaService.salvaTipoNotifica(tipoNotificaSelezionata)
        oggettiCacheMap.refresh()

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }


}
