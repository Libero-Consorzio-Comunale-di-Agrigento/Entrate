package pratiche.violazioni

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Window
import pratiche.*

class ListaRateazioniViewModel extends ElencoPraticheViewModel {

    // services
    def springSecurityService
    CommonService commonService
    CompetenzeService competenzeService

    // componenti
    Window self
    def listaTab = []

    String selezionato
    String tipoPratica = null

    def mascheraTributi = [
            [tipoTributo: 'ICI', visible: true, index: 0],
            [tipoTributo: 'TASI', visible: true, index: 1],
            [tipoTributo: 'TARSU', visible: true, index: 2],
            [tipoTributo: 'ICP', visible: true, index: 3],
            [tipoTributo: 'TOSAP', visible: true, index: 4],
            [tipoTributo: 'CUNI', visible: true, index: 5]
    ]

    @NotifyChange("selezionato")
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

		def listaTipiTributo = competenzeService.tipiTributoUtenza()

		listaTab = []

		listaTipiTributo.each {

			def tipoTributo = it
			def maschera = mascheraTributi.find { it.tipoTributo == tipoTributo.tipoTributo }

			def tab = [
					codice  : it.tipoTributo,
					nome    : it.tipoTributoAttuale,
					zul     : "/pratiche/rateazione/elencoRateazioni.zul",
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

