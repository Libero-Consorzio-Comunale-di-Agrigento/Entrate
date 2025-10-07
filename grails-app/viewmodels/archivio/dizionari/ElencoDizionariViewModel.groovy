package archivio.dizionari

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.Components
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Tab
import org.zkoss.zul.Tabbox
import org.zkoss.zul.Tabpanel
import org.zkoss.zul.Window

class ElencoDizionariViewModel {

	// services
	def springSecurityService
	CompetenzeService competenzeService
	//StrutturaOrganizzativaService strutturaOrganizzativaService

	// componenti
	Window self
	def listaTab = []

	String selezionato
	String zul

	@NotifyChange("selezionato")
	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			, @ExecutionArgParam("pagina") String z) {
		this.self = w
		zul = z
		listaTab = OggettiCache.TIPI_TRIBUTO.valore.collect {
			[  codice: it.tipoTributo
			 , nome: it.tipoTributoAttuale
			 , zul: zul
			 , visibile: ((it.tipoTributo == "TASI" || it.tipoTributo == "ICI")
					&& competenzeService.tipoAbilitazioneUtente(it.tipoTributo) != null)
			]
		}
		String tributo = Sessions.getCurrent().getAttribute("tributo")
		Sessions.getCurrent().removeAttribute("tributo")
		selezionato = tributo?:listaTab[0].codice
	}

	@Command caricaTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx
			, @BindingParam("zul") String zul
			, @BindingParam("tipoTributo") String tipoTributo) {

		Tab tab				= (Tab) ctx.getComponent()
		Tabpanel tabPanel	= tab.linkedPanel
		// TODO: non so se esiste un modo migliore per fare un refresh dello zul
		if (tabPanel != null) {
			Components.removeAllChildren(tabPanel)
		}
		Window w	= Executions.createComponents(zul, tabPanel, [tipoTributo: tipoTributo])
	}

	@Command caricaPrimoTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
		Tabbox tabbox 		= (Tabbox) ctx.getComponent()
		Tabpanel tabPanel 	= tabbox.getSelectedTab()?.linkedPanel
		if (tabPanel != null && (tabPanel.children == null || tabPanel.children.empty)) {
			def tabSelezionato = listaTab.find { it.codice == selezionato }
			Window w	= Executions.createComponents(zul, tabPanel, [tipoTributo: tabSelezionato.codice])
		}
	}
}
