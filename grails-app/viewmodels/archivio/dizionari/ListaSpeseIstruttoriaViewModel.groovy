package archivio.dizionari

import it.finmatica.tr4.SpeseIstruttoria
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.speseIstruttoria.SpeseIstruttoriaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaSpeseIstruttoriaViewModel extends TabListaGenericaTributoViewModel {

    // Componenti
    Window self

    // Services
    SpeseIstruttoriaService speseIstruttoriaService

    // Comuni
    def listaSpese
    def spesaSelezionata
    def filtroAttivo
    def filtri
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')
    }


    @Override
    @Command
    void onRefresh() {

        spesaSelezionata = null

        listaSpese = speseIstruttoriaService.getListaSpeseIstruttoria(tipoTributoSelezionato.tipoTributo, filtri)

        BindUtils.postNotifyChange(null, null, this, "spesaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaSpese")

    }

    @Command
    def onAggiungiSpesaIstruttoria() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpeseIstruttoria.zul", self,
                [tipoTributo   : tipoTributoSelezionato.tipoTributo,
                 tipoOperazione: DettaglioSpeseIstruttoriaViewModel.TipoOperazione.INSERIMENTO],
                { event ->
                    if (event.data) {
                        if (event.data?.spesa) {

                            speseIstruttoriaService.salvaSpesaIstruttoria(event.data.spesa)
                            def message = "Salvataggio avvenuto con successo"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                            onRefresh()
                        }
                    }
                })
    }

    @Command
    def onModificaSpesaIstruttoria() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpeseIstruttoria.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        tipoOperazione: lettura ? DettaglioSpeseIstruttoriaViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioSpeseIstruttoriaViewModel.TipoOperazione.MODIFICA,
                        spesa      : clonaSpesa(spesaSelezionata)
                ], { event ->
            if (event.data) {
                if (event.data?.spesa) {

                    //Si è modificata la primary key composta, occorre eliminare la precedente entity
                    if (primaryKeyModificata(event.data.spesa)) {
                        speseIstruttoriaService.eliminaSpesaIstruttoria(spesaSelezionata)
                    }

                    speseIstruttoriaService.salvaSpesaIstruttoria(event.data.spesa)
                    def message = "Salvataggio avvenuto con successo"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                    onRefresh()
                }
            }
        })
    }

    @Command
    def onDuplicaSpesaIstruttoria() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSpeseIstruttoria.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        tipoOperazione: DettaglioSpeseIstruttoriaViewModel.TipoOperazione.CLONAZIONE,
                        spesa      : clonaSpesa(spesaSelezionata)
                ], { event ->
            if (event.data) {
                if (event.data?.spesa) {

                    speseIstruttoriaService.salvaSpesaIstruttoria(event.data.spesa)
                    def message = "Salvataggio avvenuto con successo"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                    onRefresh()
                }
            }
        })
    }

    @Command
    def onEliminaSpesaIstruttoria() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        speseIstruttoriaService.eliminaSpesaIstruttoria(spesaSelezionata)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        Map fields

        if (listaSpese) {

            fields = [
                    "anno"          : "Anno",
                    "daImporto"     : "Importo Da",
                    "aImporto"      : "Importo A",
                    "spese"         : "Spese",
                    "percInsolvenza": "% Insolvenza"
            ]

            def formatters = [
                    "anno": Converters.decimalToInteger
            ]

            XlsxExporter.exportAndDownload("SpeseIstruttoria_${tipoTributoSelezionato.tipoTributoAttuale}", listaSpese, fields, formatters)
        }
    }

    @Command
    def openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaSpeseIstruttoriaRicerca.zul", self,
                [
                        filtri: filtri
                ], { event ->
            if (event.data) {
                if (event.data?.filtri) {

                    this.filtri = event.data?.filtri
                    controllaFiltro()
                    onRefresh()
                }
            }
        })
    }

    private def clonaSpesa(def spesa) {

        SpeseIstruttoria nuovaSpesa = new SpeseIstruttoria()
        nuovaSpesa.tipoTributo = spesa.tipoTributo
        nuovaSpesa.anno = spesa.anno
        nuovaSpesa.daImporto = spesa.daImporto
        nuovaSpesa.aImporto = spesa.aImporto
        nuovaSpesa.spese = spesa.spese
        nuovaSpesa.percInsolvenza = spesa.percInsolvenza

        return nuovaSpesa
    }

    private def primaryKeyModificata(def spesa) {

        return spesa.anno != spesaSelezionata.anno ||
                spesa.tipoTributo != spesaSelezionata.tipoTributo ||
                spesa.daImporto != spesaSelezionata.daImporto

    }

    private def controllaFiltro() {

        filtroAttivo = filtri.annoDa != null ||
                filtri.annoA != null ||
                filtri.daImportoDa != null ||
                filtri.daImportoA != null ||
                filtri.aImportoDa != null ||
                filtri.aImportoA != null ||
                filtri.daSpese != null ||
                filtri.aSpese != null ||
                filtri.daPercInsolvenza != null ||
                filtri.aPercInsolvenza != null

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

    }


}
