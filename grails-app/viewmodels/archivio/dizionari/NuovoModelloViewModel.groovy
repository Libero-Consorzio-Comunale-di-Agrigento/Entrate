package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.ModelliDTO
import it.finmatica.tr4.modelli.ModelliService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class NuovoModelloViewModel {
    Window self
    ModelliService modelliService
    ModelliDTO nuovoModello = new ModelliDTO()
    CommonService commonService
    CompetenzeService competenzeService

    // Tipi tributo
    def listaTipiTributo
    def tipoTributoSelezionato

    // Tipi modello
    def listaTipiModello = OggettiCache.TIPI_MODELLO.valore.sort { it.descrizione }
    def tipoModelloSelezionato

    def sottomodello

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("modello") def modello,
         @ExecutionArgParam("tipoTributo") def tt) {
        this.self = w

        listaTipiTributo = competenzeService.tipiTributoUtenza()
        tipoTributoSelezionato = listaTipiTributo.find {
            it.tipoTributo == tt
        }

        InvokerHelper.setProperties(nuovoModello, modello.properties)
        nuovoModello.modello = null
        nuovoModello.codiceSottomodello = ""
        nuovoModello.path = ''
        nuovoModello.flagStandard = null
        nuovoModello.flagWeb = 'S'
        // Recupero l'ultima versione se esiste
        def ultimaVersione = modello.versioni.findAll().max { it.versione }
        if (ultimaVersione) {
            nuovoModello.versioni = [ultimaVersione]
            nuovoModello.versioni[0].id = null
            nuovoModello.versioni[0].versione = 0
            nuovoModello.versioni[0].note = "Versione iniziale."
            nuovoModello.versioni[0].utente = null
            nuovoModello.versioni[0].dataVariazione = null
        }

        tipoModelloSelezionato = nuovoModello.tipoModello

        sottomodello = (modello.flagSottomodello == 'S')

    }

    @Command
    onSalvaDocumento() {

        if (nuovoModello.descrizione.isEmpty()) {
            Clients.showNotification("Specificare la Descrizione.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }
        if (sottomodello && nuovoModello.codiceSottomodello.isEmpty()) {
            Clients.showNotification("Specificare il  Codice Sottomodello.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }
        nuovoModello.flagEditabile = 'S'
        nuovoModello.path = nuovoModello.descrizione
        nuovoModello.tipoTributo = tipoTributoSelezionato.tipoTributo
        nuovoModello.tipoModello = tipoModelloSelezionato.toDomain()
        nuovoModello.codiceSottomodello = nuovoModello.codiceSottomodello.toUpperCase()

        chiudiFiniestra(modelliService.duplicaModello(nuovoModello))
    }

    @Command
    onChiudi() {
        chiudiFiniestra()
    }

    private chiudiFiniestra(def modello = null) {
        Events.postEvent(Events.ON_CLOSE, self, modello)
    }

}
