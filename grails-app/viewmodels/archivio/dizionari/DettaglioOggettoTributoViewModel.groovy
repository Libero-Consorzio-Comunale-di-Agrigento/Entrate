package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.OggettoTributoDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.oggettiTributo.OggettiTributoService
import it.finmatica.tr4.tipoOggetto.TipoOggettoService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioOggettoTributoViewModel {

    // Services
    OggettiTributoService oggettiTributoService
    TipoOggettoService tipoOggettoService
    CommonService commonService

    // Componenti
    Window self

    // Comuni
    def tipoTributo
    def labels

    // Modello
    TipoOggettoDTO tipoOggetto
    Collection<TipoOggettoDTO> tipiOggettoSenzaOggettiTributoByTipoTributo = []


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("oggettiTributoPerTipoTributo") Collection<OggettoTributoDTO> oggettiTributoPerTipoTributo
    ) {
        this.self = w
        this.tipoTributo = tipoTributo

        Collection<Long> idListTipoOggetto = oggettiTributoPerTipoTributo.collect {
            ogtr -> ogtr.tipoOggetto.tipoOggetto
        }

        this.tipiOggettoSenzaOggettiTributoByTipoTributo = tipoOggettoService.getAll().sort { it.tipoOggetto }.findAll
                {
                    !idListTipoOggetto.contains(it.tipoOggetto)
                }

        this.tipoOggetto = tipiOggettoSenzaOggettiTributoByTipoTributo?.getAt(0)
        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia

    @Command
    onSalva() {
        oggettiTributoService.salva(new OggettoTributoDTO(tipoOggetto, tipoTributo))
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
