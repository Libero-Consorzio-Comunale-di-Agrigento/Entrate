package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.ArchivioVieZonaDTO
import it.finmatica.tr4.dto.ArchivioVieZoneDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaVieZonaViewModel extends TabListaGenericaTributoViewModel {

    Window self
    def labels

    CanoneUnicoService canoneUnicoService

    /// Paginazione
    def pagingListZone = [activePage: 0,
                          pageSize  : 25,
                          totalSize : 0]
    def pagingListVieZona = [activePage: 0,
                             pageSize  : 25,
                             totalSize : 0]

    /// Zone
    def elencoZone = []
    def listaZone = []
    def zonaSelezionata = null

    /// Vie Zona
    def elencoVieZona = []
    def listaVieZona = []
    def viaZonaSelezionata = null

    // Ricerca
    def filtroZone = [:]
    def filtroZoneAttivo = false
    def filtroVieZona = [:]
    def filtroVieZonaAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {
        caricaListaZone(true)
        caricaListaVieZona(true)
    }

    /// Zone ####################################################################################

    @Command
    def onCambioPaginaZone() {

        caricaListaZone(false)
    }

    @Command
    def onModificaZona() {

        boolean modificabile = (zonaSelezionata.codZona != 0) ? true : false

        modificaZona(zonaSelezionata.dto, modificabile && !lettura, false)
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
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def report = canoneUnicoService.eliminaZona((zonaSelezionata as LinkedHashMap).dto as ArchivioVieZoneDTO)
                        if (report.result != 0) {
                            Clients.showNotification("${report.message}", Clients.NOTIFICATION_TYPE_ERROR, self,
                                    "before_center", 5000, true)
                            return
                        }

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXlsZone() {

        Map fields = ["codZona"      : "Codice",
                      "sequenza"     : "Sequenza",
                      "denominazione": "Denominazione",
                      "daAnno"       : "Da Anno",
                      "aAnno"        : "A Anno"]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ZONE,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, listaZone, fields)

    }

    @Command
    openCloseFiltriZone() {
        commonService.creaPopup("/archivio/dizionari/listaZoneRicerca.zul", self, [filtro: filtroZone], { event ->
            if (event.data) {
                this.filtroZone = event.data.filtro
                this.filtroZoneAttivo = event.data.isFiltroAttivo

                this.zonaSelezionata = null

                BindUtils.postNotifyChange(null, null, this, "filtroZone")
                BindUtils.postNotifyChange(null, null, this, "filtroZoneAttivo")
                BindUtils.postNotifyChange(null, null, this, "zonaSelezionata")

                onRefresh()
            }
        })
    }

    @Command
    onClickZona(@BindingParam("zona") def zona) {
        caricaListaVieZona(true, true)
    }

    // Vie/Zone #########################################################################

    @Command
    onRefreshVieZona() {
        caricaListaVieZona(true)
    }

    @Command
    def onCambioPaginaVieZona() {

        caricaListaVieZona(false)
    }

    @Command
    def onModificaViaZona() {

        modificaViaZona(null, viaZonaSelezionata.dto, !lettura, false)
    }

    @Command
    def onNuovaViaZona() {

        modificaViaZona(zonaSelezionata, null, true, false)
    }

    @Command
    def onDuplicaViaZona() {

        ArchivioVieZonaDTO viaZonaDaDuplicare = viaZonaSelezionata.dto as ArchivioVieZonaDTO
        ArchivioVieZonaDTO viaZonaDuplicata = new ArchivioVieZonaDTO()

        viaZonaDuplicata.archivioVie = viaZonaDaDuplicare.archivioVie
        viaZonaDuplicata.daNumCiv = viaZonaDaDuplicare.daNumCiv
        viaZonaDuplicata.aNumCiv = viaZonaDaDuplicare.aNumCiv
        viaZonaDuplicata.flagPari = viaZonaDaDuplicare.flagPari
        viaZonaDuplicata.flagDispari = viaZonaDaDuplicare.flagDispari
        viaZonaDuplicata.daChilometro = viaZonaDaDuplicare.daChilometro
        viaZonaDuplicata.aChilometro = viaZonaDaDuplicare.aChilometro
        viaZonaDuplicata.daAnno = viaZonaDaDuplicare.daAnno
        viaZonaDuplicata.aAnno = viaZonaDaDuplicare.aAnno
        viaZonaDuplicata.lato = viaZonaDaDuplicare.lato
        viaZonaDuplicata.codZona = viaZonaDaDuplicare.codZona
        viaZonaDuplicata.sequenzaZona = viaZonaDaDuplicare.sequenzaZona

        modificaViaZona(null, viaZonaDuplicata, true, true)
    }

    @Command
    onEliminaViaZona() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def report = canoneUnicoService.eliminaViaZona(((viaZonaSelezionata as LinkedHashMap).dto) as ArchivioVieZonaDTO)
                        if (report.result != 0) {
                            Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                            return
                        }

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefreshVieZona()
                    }
                })
    }

    @Command
    def onExportXlsVieZone() {

        Map fields = ["codVia"     : "Codice",
                      "sequenza"   : "Sequenza",
                      "denomUff"   : "Denominazione Ufficiale",
                      "daNumCiv"   : "Da Numero Civico",
                      "aNumCiv"    : "A Numero Civico",
                      "flagPari"   : "Pari",
                      "flagDispari": "Dispari",
                      "daKM"       : "Da KM",
                      "aKM"        : "A KM",
                      "lato"       : "Lato",
                      "daAnno"     : "Da Anno",
                      "aAnno"      : "A Anno"]

        def formatters = [daNumCiv     : { value -> value == Integer.MIN_VALUE ? null : value },
                          aNumCiv      : { value -> value == Integer.MAX_VALUE ? null : value },
                          daKM         : { value -> value == -Double.MAX_VALUE ? null : value },
                          aKM          : { value -> value == Double.MAX_VALUE ? null : value },
                          "flagPari"   : Converters.flagBooleanToString,
                          "flagDispari": Converters.flagBooleanToString]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.VIE,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

        XlsxExporter.exportAndDownload(nomeFile, elencoVieZona, fields, formatters)

    }

    @Command
    openCloseFiltriVieZona() {
        commonService.creaPopup("/archivio/dizionari/listaVieZonaRicerca.zul", self, [filtro: filtroVieZona], { event ->
            if (event.data) {
                this.filtroVieZona = event.data.filtro
                this.filtroVieZonaAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtroVieZona")
                BindUtils.postNotifyChange(null, null, this, "filtroVieZonaAttivo")

                onRefreshVieZona()
            }
        })
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

            pagingListZone.activePage = 0

            elencoZone = canoneUnicoService.getElencoZone([daCodice     : filtroZone.daCodice,
                                                           aCodice      : filtroZone.aCodice,
                                                           denominazione: filtroZone.denominazione,
                                                           daDaAnno     : filtroZone.daDaAnno,
                                                           aDaAnno      : filtroZone.aDaAnno,
                                                           daAAnno      : filtroZone.daAAnno,
                                                           aAAnno       : filtroZone.aAAnno,])
            elencoZone.sort { it.codZona * 1000 + it.sequenza }
            BindUtils.postNotifyChange(null, null, this, "elencoZone")

            pagingListZone.totalSize = elencoZone.size()
            BindUtils.postNotifyChange(null, null, this, "pagingListZone")
        }

        int fromIndex = pagingListZone.pageSize * pagingListZone.activePage
        int toIndex = Math.min((fromIndex + pagingListZone.pageSize), pagingListZone.totalSize)
        listaZone = elencoZone.subList(fromIndex, toIndex)

        BindUtils.postNotifyChange(null, null, this, "listaZone")


        zonaSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "zonaSelezionata")
    }

    ///
    /// *** Apre finestra visualizza/modifica della ViaZona
    ///
    private def modificaViaZona(def zona, ArchivioVieZonaDTO viaZona, boolean modifica, boolean duplica) {

        commonService.creaPopup("/archivio/dizionari/dettaglioViaZona.zul", self, [viaZona : viaZona,
                                                                                   modifica: modifica,
                                                                                   duplica: duplica,
                                                                                   zona   : zona],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            caricaListaVieZona(true, true)
                        }
                    }
                })
    }

    ///
    /// *** Rilegge elenco VieZona
    ///
    private def caricaListaVieZona(boolean resetPaginazione, boolean restorePagina = false) {

        if ((elencoVieZona.size() == 0) || resetPaginazione) {

            def activePageOld = pagingListVieZona.activePage

            pagingListVieZona.activePage = 0
            elencoVieZona = zonaSelezionata ?
                    canoneUnicoService.getAssociazioniVieZona([daCodice      : filtroVieZona.daCodice,
                                                               aCodice       : filtroVieZona.aCodice,
                                                               daSequenza    : filtroVieZona.daSequenza,
                                                               aSequenza     : filtroVieZona.aSequenza,
                                                               denomUff      : filtroVieZona.denomUff,
                                                               daDaNumCiv    : filtroVieZona.daDaNumCiv,
                                                               aDaNumCiv     : filtroVieZona.aDaNumCiv,
                                                               daANumCiv     : filtroVieZona.aANumCiv,
                                                               aANumCiv      : filtroVieZona.aANumCiv,
                                                               flagPari      : filtroVieZona.flagPari == 'Con' ? true : filtroVieZona.flagPari == 'Senza' ? false : null,
                                                               flagDispari   : filtroVieZona.flagDispari == 'Con' ? true : filtroVieZona.flagDispari == 'Senza' ? false : null,
                                                               daDaChilometro: filtroVieZona.daDaChilometro,
                                                               aDaChilometro : filtroVieZona.aDaChilometro,
                                                               daAChilometro : filtroVieZona.daAChilometro,
                                                               aAChilometro  : filtroVieZona.aAChilometro,
                                                               lato          : filtroVieZona.lato,
                                                               daDaAnno      : filtroVieZona.daDaAnno,
                                                               aDaAnno       : filtroVieZona.aDaAnno,
                                                               daAAnno       : filtroVieZona.daAAnno,
                                                               aAAnno        : filtroVieZona.aAAnno,
                                                               codiceZona    : zonaSelezionata.codZona,
                                                               sequenzaZona  : zonaSelezionata.sequenza
                    ]) : []
            elencoVieZona.sort { a1, a2 -> a1.denomUff <=> a2.denomUff ?: a1.codVia <=> a2.codVia ?: a1.sequenza <=> a2.sequenza }
            BindUtils.postNotifyChange(null, null, this, "elencoVieZona")

            pagingListVieZona.totalSize = elencoVieZona.size()

            if (restorePagina) {
                if (activePageOld < ((pagingListVieZona.totalSize / pagingListVieZona.pageSize) + 1)) {
                    pagingListVieZona.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingListVieZona")
        }

        int fromIndex = pagingListVieZona.pageSize * pagingListVieZona.activePage
        int toIndex = Math.min((fromIndex + pagingListVieZona.pageSize), pagingListVieZona.totalSize)
        listaVieZona = elencoVieZona.subList(fromIndex, toIndex)

        BindUtils.postNotifyChange(null, null, this, "listaVieZona")

        viaZonaSelezionata = null
        BindUtils.postNotifyChange(null, null, this, "viaZonaSelezionata")
    }


}
