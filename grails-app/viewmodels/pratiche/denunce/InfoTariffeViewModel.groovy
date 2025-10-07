package pratiche.denunce

import it.finmatica.tr4.Categoria
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.denunce.DenunceService
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class InfoTariffeViewModel {

    private def PARAMS = [
            'tipoTributo',
            'tributo',
            'categoria',
            'tipoTariffa'
    ]

    // Componenti
    def self

    // Modello
    List infoTariffe = []
    def params
    def descrizioneTributo
    def descrizioneCategoria

    // Servizi
    DenunceService denunceService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("params") def params) {

        this.self = w
        this.params = params

        validate()

        infoTariffe = denunceService.getInfoTariffe(
                params.tipoTributo,
                params.tributo,
                params.categoria,
                params.tipoTariffa
        )

        CodiceTributo tributo = CodiceTributo.get(params.tributo)
        descrizioneTributo = "${params.tributo} - ${tributo.descrizione}"
        Categoria categoria = Categoria.findByCategoria(params.categoria)
        descrizioneCategoria = "${params.categoria} - ${categoria.descrizione}"
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private validate() {
        if (!params || params.empty) {
            throw new RuntimeException("Parametri non definiti")
        }

        PARAMS.each {
            if (params[it] == null) {
                throw new RuntimeException("Parametro ${it} non definito")
            }
        }
    }
}