package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.Aggio
import it.finmatica.tr4.aggi.AggiService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaAggiViewModel extends TabListaGenericaTributoViewModel {

    // Servizi

    AggiService aggiService

    // Comuni
    def aggioSelezionato
    def listaAggi
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        labels = commonService.getLabelsProperties('dizionario')

        onRefresh()
    }

    @Command
    void onRefresh() {
        aggioSelezionato = null
        listaAggi = aggiService.getListaAggi([
                tipoTributo     : tipoTributoSelezionato.tipoTributo,
                daDataInizio    : filtro.daDataInizio,
                aDataInizio     : filtro.aDataInizio,
                daDataFine      : filtro.daDataFine,
                aDataFine       : filtro.aDataFine,
                daGiornoInizio  : filtro.daGiornoInizio,
                aGiornoInizio: filtro.aGiornoInizio,
                aGiornoFine     : filtro.aGiornoFine,
                daAliquota      : filtro.daAliquota,
                aAliquota       : filtro.aAliquota,
                daImportoMassimo: filtro.daImportoMassimo,
                aImportoMassimo : filtro.aImportoMassimo
        ])
        BindUtils.postNotifyChange(null, null, this, "listaAggi")
        BindUtils.postNotifyChange(null, null, this, "aggioSelezionato")
    }

    @Command
    def onModificaAggio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioAggi.zul", self,
                [
                        tipoTributo     : tipoTributoSelezionato.tipoTributo,
                        aggioSelezionato: aggioSelezionato,
                        isModifica      : true,
                        lettura         : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onAggiungiAggio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioAggi.zul", self,
                [
                        tipoTributo     : tipoTributoSelezionato.tipoTributo,
                        aggioSelezionato: null,
                        isModifica      : false,
                        lettura         : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onDuplicaAggio() {
        commonService.creaPopup("/archivio/dizionari/dettaglioAggi.zul", self,
                [
                        tipoTributo     : tipoTributoSelezionato.tipoTributo,
                        aggioSelezionato: aggioSelezionato,
                        isClonazione    : true,
                        isModifica      : true,
                        lettura         : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onEliminaAggio() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                    Aggio aggio = aggiService.getAggio(aggioSelezionato.tipoTributo, aggioSelezionato.sequenza)
                    aggiService.eliminaAggio(aggio)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXlsAggi() {

        Map fields = [
                "dataInizio"    : "Data Inizio",
                "dataFine"      : "Data Fine",
                "giornoInizio"  : "Giorno Inizio",
                "giornoFine"    : "Giorno Fine",
                "aliquota"      : "Aliquota",
                "importoMassimo": "Importo Massimo"
        ]

        def formatters = [
                "giornoInizio": Converters.decimalToInteger,
                "giornoFine": Converters.decimalToInteger
        ]

        def bigDecimalFormats = [
                "aliquota": getAliquotaFormat()
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.AGGI,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaAggi, fields, formatters, bigDecimalFormats)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaAggiRicerca.zul", self, [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    String getAliquotaFormat() {
        return "#,##0.0000"
    }

}
