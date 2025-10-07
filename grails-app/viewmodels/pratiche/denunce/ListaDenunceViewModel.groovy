package pratiche.denunce

import it.finmatica.tr4.Si4Competenze
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
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

class ListaDenunceViewModel {

    // services
    def springSecurityService
    CompetenzeService competenzeService
    CommonService commonService

    // componenti
    Window self
    def listaTab = []

    String selezionato

	def mascheraTributi = [
		[ tipoTributo : 'ICI', visible : true, index : 0	],
		[ tipoTributo : 'TASI', visible : true, index : 1	],
		[ tipoTributo : 'TARSU', visible : true, index : 2	],
		[ tipoTributo : 'ICP', visible : false, index : 3	],
		[ tipoTributo : 'TOSAP', visible : false, index : 4	],
		[ tipoTributo : 'CUNI', visible : true, index : 5	]
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
				codice   : it.tipoTributo,
				nome     : it.tipoTributoAttuale,
				zul      : "/pratiche/denunce/elencoDenunce.zul",
				visibile : ((maschera != null) ? maschera.visible : false),
				index    : (maschera != null) ? maschera.index : 9999
			]
			
			listaTab << tab
		}
		
		listaTab.sort {it.index}

        String tributo = Sessions.getCurrent().getAttribute("tributo")
        //Sessions.getCurrent().removeAttribute("tributo")
        selezionato = tributo ?: null
    }

    @Command
    caricaTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx
              , @BindingParam("zul") String zul
              , @BindingParam("tipoTributo") String tipoTributo) {
        Tab tab = (Tab) ctx.getComponent()
        Tabpanel tabPanel = tab.linkedPanel
        // TODO: non so se esiste un modo migliore per fare un refresh dello zul
        if (tabPanel != null) {
            Components.removeAllChildren(tabPanel)
        }
        Window w = Executions.createComponents(zul, tabPanel, [tipoTributo: tipoTributo])
    }

    @Command
    caricaPrimoTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        Tabbox tabbox = (Tabbox) ctx.getComponent()
        Tabpanel tabPanel = tabbox.getSelectedTab()?.linkedPanel
        if (tabPanel != null && (tabPanel.children == null || tabPanel.children.empty)) {
            def tabSelezionato = listaTab.find { it.codice == selezionato }
            Window w = Executions.createComponents(tabSelezionato.zul, tabPanel, [tipoTributo: tabSelezionato.codice])
        }
    }

}
