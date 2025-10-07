package pratiche


import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.zk.ui.Components
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Tab
import org.zkoss.zul.Tabbox
import org.zkoss.zul.Tabpanel
import org.zkoss.zul.Window

abstract class ElencoPraticheViewModel {

    @Command
    caricaTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx
              , @BindingParam("zul") String zul
              , @BindingParam("tipoTributo") String tipoTributo) {
        Tab tab = (Tab) ctx.getComponent()
        Tabpanel tabPanel = tab.linkedPanel
        if (tabPanel != null) {
            Components.removeAllChildren(tabPanel)
        }
        Window w = Executions.createComponents(zul, tabPanel, [tipoTributo: tipoTributo, tipoPratica: tipoPratica])
    }

    @Command
    caricaPrimoTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        Tabbox tabbox = (Tabbox) ctx.getComponent()

        Tabpanel tabPanel = tabbox.getSelectedTab()?.linkedPanel
        if (tabPanel != null && (tabPanel.children == null || tabPanel.children.empty)) {
            def tabSelezionato = listaTab.find { it.codice == selezionato }
            Window w = Executions.createComponents(tabSelezionato.zul, tabPanel, [tipoTributo: tabSelezionato.codice, tipoPratica: tipoPratica])
        }
    }

    protected void determinaSelezionato(def tributo) {
        // Se non è selezionato un tirbuto o quello selezionato non è visibile o presente tra le tab
        if (!tributo || listaTab.find { it.codice == tributo } == null || !listaTab.find {
            it.codice == tributo
        }.visibile) {
            // Il selezionato è il primo visibile
            selezionato = listaTab.find { it.visibile }?.codice
        } else {
            selezionato = tributo
        }
    }

}