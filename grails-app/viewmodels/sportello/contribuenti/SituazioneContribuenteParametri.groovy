package sportello.contribuenti

import groovy.json.JsonOutput
import it.finmatica.zkutils.ordinamentomulticolonna.OrdinamentoMultiColonnaComponent
import org.zkoss.util.resource.Labels

class SituazioneContribuenteParametri {

    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true
    ]

    def cbTipiPratica = [
            D  : true    // dichiarazione D
            , A: true    // accertamento A
            , L: true    // liquidazione L
            , I: true    // infrazioni I
            , V: true    // ravvedimenti V
    ]

    def idTab = 'oggetti'

    def annoOggetti = 'Tutti'

    def tipoVisualizzazioneOggetti = 'P'
    def tipoVisualizzazioneDatiMetrici = 'DC'
    def tipoVisualizzazioneTipoOggetto = "CTT"

    def ordinePratiche

    def toJson() {
        return JsonOutput.toJson(this)
    }

}
