package archivio.dizionari

import it.finmatica.tr4.codifiche.CodificheTipoTributoService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class DettaglioTipiTributoViewModel {


    // Componenti
    Window self

    // Services
    def springSecurityService
    CodificheTipoTributoService codificheTipoTributoService

    // Dati
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt) {

        this.self = w
        this.tipoTributo = tt;


    }

    // Eventi interfaccia

    @Command
    onSalva() {
        def dto = codificheTipoTributoService.getTipoTributoDTO(this.tipoTributo)

        //Converto in maiuscolo la descrizione prima di salvarla
        dto.descrizione = dto.descrizione.toUpperCase()

        codificheTipoTributoService.salvaTipoTributo(dto)
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    @Command
    onCheckboxCheck(@BindingParam("flagCheckbox") def flagCheckbox) {

        // Inverte il flag del checkbox relativo tra null o 'S'
        this.tipoTributo."${flagCheckbox}" = this.tipoTributo."${flagCheckbox}" == null ? "S" : null
    }

}
