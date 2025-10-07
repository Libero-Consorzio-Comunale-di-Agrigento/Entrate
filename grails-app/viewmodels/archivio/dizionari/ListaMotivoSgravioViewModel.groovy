package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.MotivoSgravioDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.sgravio.MotivoSgravioService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaMotivoSgravioViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    MotivoSgravioService motivoSgravioService

    // Componenti
    Window self

    // Modello
    MotivoSgravioDTO motivoSgravioSelezionato
    def listaMotiviSgravio = []
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

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
        motivoSgravioSelezionato = null

        listaMotiviSgravio = motivoSgravioService.getByCriteria(filtro)

        BindUtils.postNotifyChange(null, null, this, "motivoSgravioSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviSgravio")
    }

    @Command
    def onModificaMotivoSgravio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotivoSgravio.zul", self,
                [
                        motivoSgravioSelezionato: motivoSgravioSelezionato,
                        isModifica              : true,
                        isClone  : false,
                        isLettura: lettura
                ], { event -> if (event.data?.motivoSgravio) modifyElement(event.data.motivoSgravio) })
    }


    @Command
    def onAggiungiMotivoSgravio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotivoSgravio.zul", self,
                [
                        motivoSgravioSelezionato: null,
                        isModifica              : false,
                        isClone                 : false
                ], { event -> if (event.data?.motivoSgravio) addElement(event.data?.motivoSgravio) })
    }

    @Command
    def onDuplicaMotivoSgravio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotivoSgravio.zul", self,
                [
                        motivoSgravioSelezionato: motivoSgravioSelezionato,
                        isModifica              : false,
                        isClone                 : true
                ], { event -> if (event.data?.motivoSgravio) addElement(event.data?.motivoSgravio) })
    }


    @Command
    def onEliminaMotivoSgravio() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        motivoSgravioService.elimina(motivoSgravioSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXlsMotivoSgravio() {

        if (listaMotiviSgravio) {

            Map fields = [
                    "id"         : "Sgravio",
                    "descrizione": "Descrizione"
            ]

            XlsxExporter.exportAndDownload("MotiviSgravio_${tipoTributoSelezionato.tipoTributoAttuale}", listaMotiviSgravio, fields)
        }
    }

    @Command
    def editSelected() {
        onModificaMotivoSgravio()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaMotivoSgravioRicerca.zul", self,
                [
                        filtro: filtro
                ], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private def modifyElement(MotivoSgravioDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(motivoSgravioSelezionato, elementFromEvent)) {
            motivoSgravioService.elimina(motivoSgravioSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(MotivoSgravioDTO elementFromEvent) {
        motivoSgravioService.salva(elementFromEvent)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    private static def isPrimaryModified(MotivoSgravioDTO source, MotivoSgravioDTO dest) {
        return !source.id.equals(dest.id)
    }

}
