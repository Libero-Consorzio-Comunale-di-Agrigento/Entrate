package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.Interessi
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.interessi.InteressiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaInteressiViewModel extends TabListaGenericaTributoViewModel {

    // Servizi

    InteressiService interessiService

    // Comuni
    def interesseSelezionato
    def listaInteressi
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        interesseSelezionato = null
        listaInteressi = generaListaInteressi()
        BindUtils.postNotifyChange(null, null, this, "listaInteressi")
        BindUtils.postNotifyChange(null, null, this, "interesseSelezionato")
    }

    @Command
    def onModificaInteresse() {
        commonService.creaPopup("/archivio/dizionari/dettaglioInteressi.zul", self,
                [
                        tipoTributo         : tipoTributoSelezionato.tipoTributo,
                        interesseSelezionato: interesseSelezionato,
                        isModifica          : true,
                        lettura             : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onAggiungiInteresse() {
        commonService.creaPopup("/archivio/dizionari/dettaglioInteressi.zul", self,
                [
                        tipoTributo         : tipoTributoSelezionato.tipoTributo,
                        interesseSelezionato: null,
                        isModifica          : false,
                        lettura             : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onDuplicaInteresse() {
        commonService.creaPopup("/archivio/dizionari/dettaglioInteressi.zul", self,
                [
                        tipoTributo         : tipoTributoSelezionato.tipoTributo,
                        interesseSelezionato: interesseSelezionato,
                        isClonazione        : true,
                        isModifica          : true,
                        lettura             : lettura
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onEliminaInteresse() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        Interessi interesse = interessiService.getInteresse(interesseSelezionato.tipoTributo, interesseSelezionato.sequenza)
                        interessiService.eliminaInteresse(interesse)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = generaListaInteressi(mode)

        Map fields = [
                "dataInizio"   : "Data Inizio",
                "dataFine"     : "Data Fine",
                "aliquota"     : "Aliquota",
                "tipoInteresse": "Tipo Interesse"
        ]

        def formatters = [
                tipoInteresse: { ti ->
                    ti == 'G' ? 'Giornaliero' :
                            (ti == 'L' ? 'Legale' :
                                    (ti == 'S' ? 'Semestrale' :
                                            (ti == 'R' ? 'Rateazione' : 'Dilazione')))
                }
        ]

        def bigDecimalFormats = [
                "aliquota": getAliquotaFormat()
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.INTERESSI,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                        anno       : mode == ExportXlsMode.PARAMETRI ? selectedAnno : null
                ])

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, formatters, bigDecimalFormats)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaInteressiRicerca.zul", self, [filtro: filtro], { event ->
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
    def onSelectAnno() {
        onRefresh()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    private generaListaInteressi(def mode = null) {
        if (!mode || mode == ExportXlsMode.PARAMETRI) {
            return interessiService.getListaInteressi([
                    tipoTributo  : tipoTributoSelezionato.tipoTributo,
                    daDataInizio : filtro?.daDataInizio,
                    aDataInizio  : filtro?.aDataInizio,
                    daDataFine   : filtro?.daDataFine,
                    aDataFine    : filtro?.aDataFine,
                    daAliquota   : filtro?.daAliquota,
                    aAliquota    : filtro?.aAliquota,
                    tipoInteresse: filtro?.tipoInteresse?.codice,
                    anno         : selectedAnno
            ])
        } else if (mode == ExportXlsMode.TUTTI) {
            return interessiService.getListaInteressi([
                    tipoTributo: tipoTributoSelezionato.tipoTributo,
            ])
        }
    }

    String getAliquotaFormat() {
        return "#,##0.0000"
    }
}
