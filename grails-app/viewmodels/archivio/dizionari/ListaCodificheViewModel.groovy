package archivio.dizionari


import org.zkoss.bind.BindContext
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Components
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Tab
import org.zkoss.zul.Tabbox
import org.zkoss.zul.Tabpanel
import org.zkoss.zul.Window

class ListaCodificheViewModel {

    // services
    def springSecurityService

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
                [codice  : "oggetti",
                 nome    : "Oggetti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "utilizzi",
                 nome    : "Utilizzi",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "usi",
                 nome    : "Usi",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "cariche",
                 nome    : "Cariche",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "aree",
                 nome    : "Aree",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "contatti",
                 nome    : "Contatti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "richiedenti",
                 nome    : "Richiedenti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "fonti",
                 nome    : "Fonti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "tipiTributo",
                 nome    : "Tipi Tributo",
                 zul     : "/archivio/dizionari/listaTipiTributo.zul",
                 visibile: true
                ],
                [codice  : "codiciAttività",
                 nome    : "Codici Attività",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "stati",
                 nome    : "Stati",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "eventi",
                 nome    : "Eventi",
                 zul     : "/archivio/dizionari/listaEventi.zul",
                 visibile: true
                ],
                [codice  : "atti",
                 nome    : "Atti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "recapiti",
                 nome    : "Recapiti",
                 zul     : "/archivio/dizionari/listaCodificheBase.zul",
                 visibile: true
                ],
                [codice  : "contributiIFEL",
                 nome    : "Contributi IFEL",
                 zul     : "/archivio/dizionari/listaContributiIFEL.zul",
                 visibile: true
                ],
                [codice  : "tipiNotifica",
                 nome    : "Tipi Notifica",
                 zul     : "/archivio/dizionari/listaTipiNotifica.zul",
                 visibile: true
                ],
                [codice  : "tipiStatoContribuente",
                 nome    : "Tipi Stato Contribuente",
                 zul     : "/archivio/dizionari/listaTipiStatoContribuente.zul",
                 visibile: true
                ]

        ]
        selezionato = listaTab[0].codice
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
        Executions.createComponents(zul, tabPanel, [tipoTributo : tipoTributo,
                                                    tipoCodifica: tipoTributo])
    }

    @Command
    caricaPrimoTab(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        Tabbox tabbox = (Tabbox) ctx.getComponent()
        Tabpanel tabPanel = tabbox.getSelectedTab()?.linkedPanel
        if (tabPanel != null && (tabPanel.children == null || tabPanel.children.empty)) {
            def tabSelezionato = listaTab.find { it.codice == selezionato }
            Executions.createComponents(zul, tabPanel, [
                    tipoTributo : tabSelezionato.codice,
                    tipoCodifica: tabSelezionato.codice
            ])
        }
    }
}
