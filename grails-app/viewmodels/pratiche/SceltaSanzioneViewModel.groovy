package pratiche

import it.finmatica.tr4.Sanzione
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SceltaSanzioneViewModel {

    // Services


    // Componenti
    Window self

    def listaSanzioni
    def sanzioneSelezionata


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("tipoPratica") def tp,
         @ExecutionArgParam("sanzioneSelezionata") def ss
    ) {

        self = w
        sanzioneSelezionata = ss

        listaSanzioni = Sanzione.createCriteria().list {
            eq('tipoTributo.tipoTributo', tt.tipoTributo)
            ge('codSanzione', (short) 100)
            // Se sollecito si possono inserire solo sanzioni di imposta oppure di spese di notifica
            if (tp == 'S') {
                'in'('tipoCausale', ['E', 'S'])
            }
            order('codSanzione')
            order('sequenza', 'desc')
        }.toDTO()
    }


    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onOk() {
        if (sanzioneSelezionata == null) {
            Clients.showNotification("Selezionare una Sanzione", Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 2000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, [sanzioneSelezionata: sanzioneSelezionata])
    }


}
