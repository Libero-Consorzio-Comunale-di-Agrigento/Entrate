package commons

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.zk.ui.event.SortEvent

@Deprecated()
// Si utilizzerà il nuovo componente it/finmatica/zkutils/OrdinamentoMultiColonnaComponent.groovy
abstract class OrdinamentoMutiColonnaViewModel {

    protected final def CSS_ASC = "z-column-sort-asc_ z-listheader-sort-asc_"
    protected final def CSS_DSC = "z-column-sort-dsc_ z-listheader-sort-dsc_"
    protected final def VERSO_ASC = "ASC"
    protected final def VERSO_DSC = "DESC"

    def campiOrdinamento = [:]
    def campiCssOrdinamento = [:]
    def ordinamentoCss = [
            0: '',
            1: CSS_ASC,
            2: CSS_DSC
    ]

    @Command
    onCambiaOrdinamento(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        // Se l'oggetto non è presente si inizializza
        if (!campiOrdinamento[valore]) {
            campiOrdinamento[valore] = [:]
        }

        switch (campiOrdinamento[valore].verso) {
            case null:
                campiOrdinamento[valore].verso = VERSO_ASC
                campiOrdinamento[valore].posizione = campiOrdinamento.max { it.value.posizione }.value.posizione + 1
                campiCssOrdinamento[valore] = ordinamentoCss[1]
                break
            case VERSO_ASC:
                campiOrdinamento[valore].verso = VERSO_DSC
                campiCssOrdinamento[valore] = ordinamentoCss[2]
                break
            case VERSO_DSC:
                campiOrdinamento[valore].verso = null
                campiOrdinamento[valore].posizione = -1
                campiCssOrdinamento[valore] = ordinamentoCss[0]
                break
        }

        // Si ordinano i parametri in base alla posizione
        campiOrdinamento = campiOrdinamento.sort { it.value.posizione }

        caricaLista()

        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")
    }

    abstract void caricaLista()
}
