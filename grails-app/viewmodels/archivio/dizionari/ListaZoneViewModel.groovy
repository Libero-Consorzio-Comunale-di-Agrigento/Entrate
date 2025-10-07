package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.ArchivioVieZoneDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaZoneViewModel extends TabListaGenericaTributoViewModel {

    Window self

    CanoneUnicoService canoneUnicoService

    /// Interfaccia
    def filtriList = [
            descrizione: null
    ]
    boolean filtroAttivoList = false

    /// Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    /// Zone
    def elencoZone = []
    def listaZone = []
    def zonaSelezionata = null

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo) {

        super.init(w, tipoTributo)

    }

    /// Elenco zone ####################################################################################

    @Command
    void onRefresh() {

        caricaListaZone(true)
    }

    @Command
    def onCambioPagina() {

        caricaListaZone(false)
    }

    @Command
    def onOpenFiltriLista() {

    }

    @Command
    def onZonaSelected() {

    }

    @Command
    def onModificaZona() {

        boolean modificabile = (zonaSelezionata.codZona != 0) ? true : false

        modificaZona(zonaSelezionata.dto, modificabile, false)
    }

    @Command
    def onNuovaZona() {

        modificaZona(null, true, false)
    }

    @Command
    def onDuplicaZona() {

        ArchivioVieZoneDTO zonaDaDuplicare = (zonaSelezionata as LinkedHashMap).dto as ArchivioVieZoneDTO
        ArchivioVieZoneDTO zonaDuplicata = new ArchivioVieZoneDTO()

        zonaDuplicata.aAnno = zonaDaDuplicare.aAnno
        zonaDuplicata.daAnno = zonaDaDuplicare.daAnno
        zonaDuplicata.codZona = zonaDaDuplicare.codZona
        zonaDuplicata.denominazione = zonaDaDuplicare.denominazione

        modificaZona(zonaDuplicata, true, true)
    }

    @Command
    def onEliminaZona() {

        String messaggio = "Sicuri di voler eliminare la zona ?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            def report = canoneUnicoService.eliminaZona((zonaSelezionata as LinkedHashMap).dto as ArchivioVieZoneDTO)
                            if (report.result == 0) {
                                String message = "Eliminazione eseguita con successo !"
                                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self,
                                        "before_center", 5000, true)
                                onRicaricaLista()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onExportXlsZone() {

        Map fields = [
                "codZona"      : "Codice",
                "sequenza"     : "Sequenza",
                "denominazione": "Denominazione",
                "daAnno"       : "Da anno",
                "aAnno"        : "A anno"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ZONE,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaZone, fields)

    }


    /// Funzioni interne ####################################################################################

    ///
    /// *** Apre finestra visualizza/modifica della Zona
    ///
    private def modificaZona(ArchivioVieZoneDTO zona, boolean modifica, boolean duplica) {

        commonService.creaPopup("/archivio/dizionari/dettaglioZona.zul", self, [zona    : zona,
                                                                                modifica: modifica,
                                                                                duplica : duplica],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            caricaListaZone(true)
                        }
                    }
                }
        )
    }

    ///
    /// *** Rilegge elenco zone
    ///
    private def caricaListaZone(boolean resetPaginazione) {

        if ((elencoZone.size() == 0) || resetPaginazione) {

            pagingList.activePage = 0

            elencoZone = canoneUnicoService.getElencoZone([
                    daCodice     : filtro.daCodice,
                    aCodice      : filtro.aCodice,
                    denominazione: filtro.denominazione,
                    daAnno       : filtro.daAnno,
                    aAnno        : filtro.aAnno
            ])
            elencoZone.sort { it.codZona * 1000 + it.sequenza }

            pagingList.totalSize = elencoZone.size()
            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        listaZone = elencoZone.subList(fromIndex, toIndex)

        BindUtils.postNotifyChange(null, null, this, "listaZone")
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaZoneRicerca.zul", self, [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }
}
