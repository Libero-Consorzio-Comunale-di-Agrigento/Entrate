package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.Contenitore
import it.finmatica.tr4.dto.ContenitoreDTO
import it.finmatica.tr4.contenitori.ContenitoriService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioContenitoreViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }

    CommonService commonService
    ContenitoriService contenitoriService

    Window self
	
    def tipoOperazione
    def tipoTributo
    def labels
	
    ContenitoreDTO contenitore

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("contenitore") ContenitoreDTO contenitore,
         @ExecutionArgParam("tipoTributo") TipoTributoDTO tipoTributo,
         @ExecutionArgParam("tipoOperazione") TipoOperazione tipoOperazione) {

        this.self = w

        this.labels = commonService.getLabelsProperties('dizionario')
		
        this.tipoOperazione = tipoOperazione
        this.contenitore = contenitore
        this.tipoTributo = tipoTributo

        fetchContenitore(tipoOperazione, contenitore)
    }

    private void fetchContenitore(TipoOperazione tipoOperazione, ContenitoreDTO contenitore) {
	
        if (tipoOperazione == TipoOperazione.INSERIMENTO) {
            this.contenitore = contenitoriService.creaContenitore()
            return
        }
        if (tipoOperazione == TipoOperazione.CLONAZIONE) {
            this.contenitore = contenitoriService.clonaContenitore(contenitore)
            return
        }
        this.contenitore = contenitore
    }

    @Command
    onSalva() {

        if (!contenitore.id) {
            def message = "Codice è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!contenitore.descrizione) {
            def message = "Descrizione è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!contenitore.unitaDiMisura) {
            def message = "Unità di Misura è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }
        if (!contenitore.capienza) {
            def message = "Capienza è obbligatorio"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        if ((tipoOperazione == TipoOperazione.INSERIMENTO) || (tipoOperazione == TipoOperazione.CLONAZIONE)) {
            Contenitore esistente = Contenitore.get(contenitore.id)
            if(esistente) {
                def message = "Esiste già un contenitore con questo Codice"
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
                return
            }
        }

        contenitore.descrizione = contenitore.descrizione.toUpperCase()
        contenitore.unitaDiMisura = contenitore.unitaDiMisura
        contenitoriService.salvaContenitore(contenitore.toDomain())

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
