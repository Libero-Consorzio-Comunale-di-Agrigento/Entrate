package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.dto.MotiviPraticaDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.motiviPratica.MotiviPraticaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaMotiviPraticaViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    MotiviPraticaService motiviPraticaService

    // Componenti
    Window self

    // Modello
    MotiviPraticaDTO motivoPraticaSelezionato
    def listaMotiviPratica = []
    Collection<TipoPratica> tipiPraticaAbilitati = [TipoPratica.D,
                                                    TipoPratica.L,
                                                    TipoPratica.I,
                                                    TipoPratica.A,]

    def descrizioneTipiPratica = [
            (TipoPratica.D.tipoPratica): TipoPratica.D.descrizione,
            (TipoPratica.L.tipoPratica): TipoPratica.L.descrizione,
            (TipoPratica.I.tipoPratica): TipoPratica.I.descrizione,
            (TipoPratica.A.tipoPratica): TipoPratica.A.descrizione,
    ]

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false
    def labels

    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        labels = commonService.getLabelsProperties('dizionario')
    }

    // Eventi interfaccia
    @Override
    @Command
    void onRefresh() {
        motivoPraticaSelezionato = null

        listaMotiviPratica = motiviPraticaService.getByCriteria([tipoTributo: tipoTributoSelezionato.tipoTributo,
                                                                 daAnno     : filtro?.da,
                                                                 aAnno      : filtro?.a,
                                                                 tipoPratica: filtro?.tipoPratica,
                                                                 motivo     : filtro?.motivo,])

        BindUtils.postNotifyChange(null, null, this, "motivoPraticaSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviPratica")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviPratica.zul", self,
                [tipoTributo         : tipoTributoSelezionato.tipoTributo,
                 tipiPraticaAbilitati: tipiPraticaAbilitati,
                 selezionato         : motivoPraticaSelezionato.clone(),
                 isModifica          : true,
                 isClone             : false,
                 isLettura           : lettura
                ], { event -> if (event.data?.motivoPratica) modifyElement(event.data.motivoPratica) })
    }


    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviPratica.zul", self,
                [tipoTributo         : tipoTributoSelezionato.tipoTributo,
                 tipiPraticaAbilitati: tipiPraticaAbilitati,
                 selezionato         : null,
                 isModifica          : false,
                 isClone             : false
                ], { event -> if (event.data?.motivoPratica) addElement(event.data.motivoPratica) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviPratica.zul", self,
                [tipoTributo         : tipoTributoSelezionato.tipoTributo,
                 tipiPraticaAbilitati: tipiPraticaAbilitati,
                 selezionato         : motivoPraticaSelezionato.clone(),
                 isModifica          : false,
                 isClone             : true
                ], { event -> if (event.data?.motivoPratica) addElement(event.data.motivoPratica) })
    }


    @Command
    def onElimina() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        motiviPraticaService.elimina(motivoPraticaSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaMotiviPratica) {

            Map fields = ["anno"       : "Anno",
                          "tipoPratica": "Tipo Pratica",

                          "motivo"     : "Motivo",]

            def converters = [
                    tipoPratica: { tipoPratica -> descrizioneTipiPratica[tipoPratica] }
            ]

            XlsxExporter.exportAndDownload("Motivi_${tipoTributoSelezionato.tipoTributoAttuale}", listaMotiviPratica, fields, converters)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaMotiviPraticaRicerca.zul", self,
                [filtro              : filtro,
                 tipiPraticaAbilitati: tipiPraticaAbilitati], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    private def modifyElement(MotiviPraticaDTO elementFromEvent) {
        motiviPraticaService.elimina(motivoPraticaSelezionato)
        addElement(elementFromEvent)
    }

    private def addElement(MotiviPraticaDTO elementFromEvent) {
        motiviPraticaService.salva(elementFromEvent)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
