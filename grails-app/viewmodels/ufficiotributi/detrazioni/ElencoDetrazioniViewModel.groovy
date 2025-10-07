package ufficiotributi.detrazioni


import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Components
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Tab
import org.zkoss.zul.Tabbox
import org.zkoss.zul.Tabpanel
import org.zkoss.zul.Window

class ElencoDetrazioniViewModel {

    // componenti
    Window self
    def listaTab = []

    String selezionato
    String zul

    @NotifyChange("selezionato")
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("pagina") String z) {

        this.self = w
        this.zul = z

        listaTab = [
                [codice  : "aliquote",
                 nome    : "Aliquote Particolari",
                 zul     : "/ufficiotributi/detrazioni/listaDetrazioniAliquote.zul",
                 visibile: true
                ],
                [codice  : "detrazioni",
                 nome    : "Detrazioni Particolari",
                 zul     : "/ufficiotributi/detrazioni/listaDetrazioni.zul",
                 visibile: true
                ]

        ]
        selezionato = listaTab[0].codice
    }

    @Command
    caricaTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx
              , @BindingParam("zul") String zul
              , @BindingParam("codice") String codice) {
        Tab tab = (Tab) ctx.getComponent()
        Tabpanel tabPanel = tab.linkedPanel
        // TODO: non so se esiste un modo migliore per fare un refresh dello zul
        if (tabPanel != null) {
            Components.removeAllChildren(tabPanel)
        }
        Window w = Executions.createComponents(zul, tabPanel, [codice: codice])
    }

    @Command
    caricaPrimoTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        Tabbox tabbox = (Tabbox) ctx.getComponent()
        Tabpanel tabPanel = tabbox.getSelectedTab()?.linkedPanel
        if (tabPanel != null && (tabPanel.children == null || tabPanel.children.empty)) {
            def tabSelezionato = listaTab.find { it.codice == selezionato }
            Window w = Executions.createComponents(tabSelezionato.zul, tabPanel, [codice: tabSelezionato.codice])
        }
    }
}
