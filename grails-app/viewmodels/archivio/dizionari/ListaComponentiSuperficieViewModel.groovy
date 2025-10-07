package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.componentiSuperficie.ComponentiSuperficieService
import it.finmatica.tr4.dto.ComponentiSuperficieDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaComponentiSuperficieViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    ComponentiSuperficieService componentiSuperficieService

    // Componenti
    Window self
    def labels

    // Modello
    ComponentiSuperficieDTO componenteSuperficieSelezionato
    Collection<ComponentiSuperficieDTO> listaComponentiSuperficie

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
        componenteSuperficieSelezionato = null

        listaComponentiSuperficie = componentiSuperficieService.getByCriteria(filtro)

        BindUtils.postNotifyChange(null, null, this, "componenteSuperficieSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaComponentiSuperficie")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComponentiSuperficie.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: componenteSuperficieSelezionato.clone(),
                        isModifica : true,
                        isLettura: lettura
                ], { event -> if (event.data?.componenteSuperficie) modifyElement(event.data.componenteSuperficie) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComponentiSuperficie.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: null,
                        isModifica : false,
                ], { event -> if (event.data?.componenteSuperficie) addElement(event.data.componenteSuperficie) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComponentiSuperficie.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: componenteSuperficieSelezionato.clone(),
                        isModifica : false,
                ], { event -> if (event.data?.componenteSuperficie) addElement(event.data?.componenteSuperficie) })
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
                    componentiSuperficieService.elimina(componenteSuperficieSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaComponentiSuperficie) {

            Map fields = [
                    "anno"           : "Anno",
                    "numeroFamiliari": "Numero Familiari",
                    "daConsistenza"  : "Da Consistenza",
                    "aConsistenza"   : "A Consistenza",
            ]

            XlsxExporter.exportAndDownload("ComponentiSuperficie_${tipoTributoSelezionato.tipoTributoAttuale}", listaComponentiSuperficie, fields)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaComponentiSuperficieRicerca.zul", self,
                [
                        filtro: filtro,
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

    private def modifyElement(ComponentiSuperficieDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(componenteSuperficieSelezionato, elementFromEvent)) {
            componentiSuperficieService.elimina(componenteSuperficieSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(ComponentiSuperficieDTO elementFromEvent) {
        componentiSuperficieService.salva(elementFromEvent)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    private static def isPrimaryModified(ComponentiSuperficieDTO source, ComponentiSuperficieDTO dest) {
        return !(source.anno.equals(dest.anno) && source.numeroFamiliari.equals(dest.numeroFamiliari))
    }


}
