package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.sanzioni.SanzioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listbox
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaSanzioniViewModel extends TabListaGenericaTributoViewModel {

    @Wire("#listBoxSanzioni")
    Listbox listBoxSanzioni

    // Servizi
    SanzioniService sanzioniService

    // Comuni
    def sanzioneSelezionata
    def listaSanzioni

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        this.labels = commonService.getLabelsProperties('dizionario')

        onRefresh()
    }

    @Command
    def onSelectAnno() {
        onRefresh()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    void onRefresh() {
        invalidaLista()

        sanzioneSelezionata = null
        listaSanzioni = generaListaSanzioni()
        BindUtils.postNotifyChange(null, null, this, "listaSanzioni")
        BindUtils.postNotifyChange(null, null, this, "sanzioneSelezionata")
    }

    private void invalidaLista() {
        if (listBoxSanzioni) {
            listBoxSanzioni.invalidate()
        }
    }

    @Command
    def onModificaSanzione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSanzioni.zul", self,
                [
                        tipoTributo        : tipoTributoSelezionato.tipoTributo,
                        sanzioneSelezionata: sanzioneSelezionata.dto,
                        tipoOperazione     : (lettura || sanzioneSelezionata.dto.codSanzione >= 9000) ? DettaglioSanzioniViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioSanzioniViewModel.TipoOperazione.MODIFICA
                ], { event ->
            onRefresh()
        }
        )
    }

    @Command
    def onAggiungiSanzione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSanzioni.zul", self,
                [
                        tipoTributo        : tipoTributoSelezionato.tipoTributo,
                        sanzioneSelezionata: null,
                        tipoOperazione     : DettaglioSanzioniViewModel.TipoOperazione.INSERIMENTO
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onDuplicaSanzione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioSanzioni.zul", self,
                [
                        tipoTributo        : tipoTributoSelezionato.tipoTributo,
                        sanzioneSelezionata: sanzioneSelezionata.dto,
                        tipoOperazione     : DettaglioSanzioniViewModel.TipoOperazione.CLONAZIONE
                ], { event -> onRefresh() }
        )
    }

    @Command
    def onEliminaSanzione() {

        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.OK | Messagebox.CANCEL,
                Messagebox.EXCLAMATION,
                { event ->
                    if (event.getName().equals("onOK")) {
                        sanzioniService.eliminaSanzione(sanzioneSelezionata.dto.toDomain())

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = generaListaSanzioni(mode)

        Map fields = [
                "codSanzione"         : "Codice",
                "sequenza"            : "Sequenza",
                "descrizione"         : "Descrizione",
                "dataInizio"          : "Data Inizio",
                "dataFine"            : "Data Fine",
                "percentuale"         : "Percentuale",
                "sanzione"            : "Sanzione",
                "sanzioneMinima"      : "Sanzione Minima",
                "riduzione"           : "Riduzione",
                "riduzione2"          : "Riduzione 2",
                "flagImposta"         : "Imposta",
                "flagInteressi"       : "Interessi",
                "flagPenaPecuniaria"  : "Pena Pecuniaria",
                "flagCalcoloInteressi": "Calcolo Interessi",
                "tributo"             : "Codice Tributo",
                "codTributoF24"       : "Codice F24",
                "tipoCausale"         : "Tipo Causale",
                "rata"                : "Rata",
                "tipoVersamento"      : "Tipo Versamento",
                "utente"              : "Utente",
                "dataVariazione"      : "Data Variazione"
        ]

        def formatters = [
                "flagImposta"         : Converters.flagString,
                "flagInteressi"       : Converters.flagString,
                "flagPenaPecuniaria"  : Converters.flagString,
                "flagCalcoloInteressi": Converters.flagString
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.SANZIONI,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                        anno       : mode == ExportXlsMode.PARAMETRI ? selectedAnno : null
                ]
        )

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, formatters)
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaSanzioniRicerca.zul",
                self,
                [filtro     : filtro,
                 tipoTributo: tipoTributoSelezionato.tipoTributo],
                { event ->
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
    def onArchiviaEDuplica() {

        commonService.creaPopup('/archivio/dizionari/archiviaEDuplica.zul', self, [
                tipoTributo: tipoTributoSelezionato.tipoTributo
        ]
        ) { data ->
            if (data) {
                onRefresh()
            }
        }

    }

    @Command
    def onRipristinaPeriodoPrecedente() {
        Messagebox.show("Eliminare il periodo attuale con sequenza maggiore di 1 e riattivare il precedente?", "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            try {
                                sanzioniService.ripristinaPeriodoPrecedente(tipoTributoSelezionato.tipoTributo)
                            } catch (Application20999Error ex) {
                                Clients.showNotification(ex.message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
                                return
                            }
                            Clients.showNotification('Operazione eseguita con successo', Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
                            onRefresh()
                        }
                    }
                }
        )
    }

    private generaListaSanzioni(def mode = null) {

        def newFiltri = [:]

        if (!mode || mode == ExportXlsMode.PARAMETRI) {
            filtro.anno = selectedAnno
            newFiltri << [
                    tipoTributo: this.tipoTributoSelezionato.tipoTributo,
                    *          : filtro
            ]
        } else if (mode == ExportXlsMode.TUTTI) {
            newFiltri << [
                    tipoTributo: tipoTributoSelezionato.tipoTributo,
            ]
        }

        return listaSanzioni = sanzioniService.getListaSanzioni(newFiltri)
    }

}
