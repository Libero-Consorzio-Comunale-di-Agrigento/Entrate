package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.MotiviDetrazioneDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.motiviDetrazione.MotiviDetrazioneService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaMotiviDetrazioneViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    MotiviDetrazioneService motiviDetrazioneService

    // Componenti
    Window self
    def labels

    // Modello
    MotiviDetrazioneDTO motivoDetrazioneSelezionato
    Collection<MotiviDetrazioneDTO> listaMotiviDetrazione

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
        motivoDetrazioneSelezionato = null

        listaMotiviDetrazione = motiviDetrazioneService.getByCriteria(tipoTributoSelezionato.tipoTributo, filtro)

        BindUtils.postNotifyChange(null, null, this, "motivoDetrazioneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviDetrazione")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviDetrazione.zul", self,
                [tipoTributo         : tipoTributoSelezionato.tipoTributo,
                 selezionato         : motivoDetrazioneSelezionato.clone(),
                 motiviDetrazioneList: listaMotiviDetrazione,
                 isModifica          : true,
                 isClone             : false,
                 isLettura           : true],
                { event -> if (event.data?.motivoDetrazione) modifyElement(event.data?.motivoDetrazione) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviDetrazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: null,
                        isModifica : false,
                        isClone    : false
                ], { event -> if (event.data?.motivoDetrazione) addElement(event.data?.motivoDetrazione) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviDetrazione.zul", self,
                [
                        tipoTributo         : tipoTributoSelezionato.tipoTributo,
                        selezionato         : motivoDetrazioneSelezionato.clone(),
                        motiviDetrazioneList: listaMotiviDetrazione,
                        isModifica          : false,
                        isClone             : true
                ], { event -> if (event.data?.motivoDetrazione) addElement(event.data?.motivoDetrazione) })
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
                        motiviDetrazioneService.elimina(motivoDetrazioneSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaMotiviDetrazione) {

            Map fields = [
                    "motivoDetrazione": "Motivo Detrazione",
                    "descrizione"     : "Descrizione",
            ]

            XlsxExporter.exportAndDownload("MotiviDetrazione_${tipoTributoSelezionato.tipoTributoAttuale}", listaMotiviDetrazione, fields)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaMotiviDetrazioneRicerca.zul", self,
                [
                        filtro              : filtro,
                        motiviDetrazioneList: listaMotiviDetrazione,
                ], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                onRefresh()

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
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

    private def modifyElement(MotiviDetrazioneDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(motivoDetrazioneSelezionato, elementFromEvent)) {
            motiviDetrazioneService.elimina(motivoDetrazioneSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(MotiviDetrazioneDTO elementFromEvent) {
        motiviDetrazioneService.salva(elementFromEvent)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onRefresh()
    }

    private static def isPrimaryModified(MotiviDetrazioneDTO source, MotiviDetrazioneDTO dest) {
        return !(
                source.tipoTributo.equals(dest.tipoTributo) &&
                        source.motivoDetrazione.equals(dest.motivoDetrazione))
    }


}
