package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.MotivoCompensazioneDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.motiviCompensazione.MotiviCompensazioneService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaMotiviCompensazioneViewModel extends TabListaGenericaTributoViewModel {

    // Servizi

    MotiviCompensazioneService motiviCompensazioneService

    // Componenti
    Window self

    // Modello
    MotivoCompensazioneDTO motivoCompensazioneSelezionato
    Collection<MotivoCompensazioneDTO> listaMotiviCompensazione
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
        motivoCompensazioneSelezionato = null

        listaMotiviCompensazione = motiviCompensazioneService.getByCriteria(filtro)

        BindUtils.postNotifyChange(null, null, this, "motivoCompensazioneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviCompensazione")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviCompensazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: motivoCompensazioneSelezionato.clone(),
                        isModifica : true,
                        isClone  : false,
                        isLettura: lettura
                ], { event -> if (event.data?.motivoCompensazione) modifyElement(event.data.motivoCompensazione) })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviCompensazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: null,
                        isModifica : false,
                        isClone    : false
                ], { event -> if (event.data?.motivoCompensazione) addElement(event.data.motivoCompensazione) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioMotiviCompensazione.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        selezionato: motivoCompensazioneSelezionato.clone(),
                        isModifica : false,
                        isClone    : true
                ], { event -> if (event.data?.motivoCompensazione) addElement(event.data?.motivoCompensazione) })
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
                        motiviCompensazioneService.elimina(motivoCompensazioneSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaMotiviCompensazione) {

            Map fields = [
                    "id"         : "Motivo Compensazione",
                    "descrizione": "Descrizione",
            ]

            XlsxExporter.exportAndDownload("MotiviCompensazione_${tipoTributoSelezionato.tipoTributoAttuale}", listaMotiviCompensazione, fields)
        }
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaMotiviCompensazioneRicerca.zul", self,
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

    private def modifyElement(MotivoCompensazioneDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(motivoCompensazioneSelezionato, elementFromEvent)) {
            motiviCompensazioneService.elimina(motivoCompensazioneSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(MotivoCompensazioneDTO elementFromEvent) {
        motiviCompensazioneService.salva(elementFromEvent)
        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        onRefresh()
    }

    private static def isPrimaryModified(MotivoCompensazioneDTO source, MotivoCompensazioneDTO dest) {
        return !source.id.equals(dest.id)
    }


}
