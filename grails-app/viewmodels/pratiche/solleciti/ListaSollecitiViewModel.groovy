package pratiche.solleciti


import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Components
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Tab
import org.zkoss.zul.Tabbox
import org.zkoss.zul.Tabpanel
import org.zkoss.zul.Window
import pratiche.*

class ListaSollecitiViewModel extends ElencoPraticheViewModel {

    // services
    CompetenzeService competenzeService

    // componenti
    Window self
    def listaTab = []

    String selezionato
    String tipoPratica = 'S'

    def mascheraTributi = [
            [tipoTributo: 'TARSU', visible: true, index: 0],
            [tipoTributo: 'CUNI', visible: true, index: 1]
    ]

    @NotifyChange("selezionato")
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        def listaTipiTributo = competenzeService.tipiTributoUtenza().findAll {
            it.tipoTributo == 'TARSU' || it.tipoTributo == 'CUNI'
        }

        listaTab = []

        listaTipiTributo.each {

            def tipoTributo = it
            def maschera = mascheraTributi.find { it.tipoTributo == tipoTributo.tipoTributo }

            def tab = [
                    codice  : it.tipoTributo,
                    nome    : it.tipoTributoAttuale,
                    zul     : "/pratiche/solleciti/elencoSolleciti.zul",
                    visibile: ((maschera != null) ? maschera.visible : false),
                    index   : (maschera != null) ? maschera.index : 9999
            ]

            listaTab << tab
        }

        listaTab.sort { it.index }

        String tributo = Sessions.getCurrent().getAttribute("tributo")
        // Se non è selezionato un tributo o se il tributo selezionato non è visibile
        // si prende il primo visibile.
        determinaSelezionato(tributo)
    }
}
