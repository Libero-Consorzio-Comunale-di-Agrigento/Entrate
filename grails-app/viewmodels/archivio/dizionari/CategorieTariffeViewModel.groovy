package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.dto.CategoriaDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.TariffaDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CategorieTariffeViewModel extends TabListaGenericaTributoViewModel {

    CanoneUnicoService canoneUnicoService

    def cbTributiAbilitati = [:]

    // Generali
    List<CodiceTributoDTO> listaCodiciTributo = []
    CodiceTributoDTO codiceTributoSelezionato

    def labels
    def tariffaFormat = CanoneUnicoService.TARIFFA_FORMAT_PATTERN
    def riduzioneFormat = CanoneUnicoService.RIDUZIONE_FORMAT_PATTERN

    Short annoCopiaDa = null

    // Tab panel
    def selectedTab
    String selectedTabId = null

    // Interfaccia
    def filtroCategorie = [:]
    boolean filtroCategorieAttivo = false

    def filtroTariffe = [:]
    boolean filtroTariffeAttivo = false
    boolean filtroTariffeDisabilitato = true

    // Paginazione
    def pagingCategorie = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    def pagingTariffe = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Categorie
    def elencoCategorie = []
    def listaCategorie = []
    def categoriaSelezionata = null

    // Tariffe
    def elencoTariffe = []
    def listaTariffe = []
    def tariffaSelezionata = null
    Boolean elencoTariffeVuoto = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Override
    void onRefresh() {

        pulisciFiltroTariffe()

        caricaCodiciTributo()

        caricaLista(true)
        controllaElencoTariffe()
    }

    @Command
    def onCambioCodiceTributo() {

        caricaLista(true, true)
        controllaElencoTariffe()
    }

    @Command
    def onSelectAnno() {

        ricaricaListaTariffe(false)

        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    def onRicaricaLista() {

        caricaLista(true)
        controllaElencoTariffe()
    }

    def caricaLista(boolean resetPaginazione, boolean restorePagina = false) {

        caricaListaCategorie(resetPaginazione, restorePagina)
        caricaListaTariffe(resetPaginazione, restorePagina)

        self.invalidate()
    }

    @Command
    def onRicaricaListaCategorie() {

        caricaLista(true)
    }

    @Command
    def onCambioPaginaCategorie() {

        caricaListaCategorie(false)
    }

    @Command
    def onNuovaCategoria() {

        modificaCategoria(null, true)
    }

    @Command
    def onModificaCategoria() {

        modificaCategoria(categoriaSelezionata, true)
    }

    @Command
    def onDuplicaCategoria() {

        modificaCategoria(categoriaSelezionata, true, true)
    }

    @Command
    def onEliminaCategoria() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def report = deleteCategoriaAndGetReport()

                        if (report.result != 0) {
                            visualizzaReport(report, "")
                            return
                        }

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        caricaListaCategorie(true, true)
                    }
                })
    }

    @Command
    def onCategorieToXls() {

        def fields = [
                'codiceTributo'   : 'Cod. Tributo',
                'codiceTributoDes': 'Tributo',
                'categoria'       : 'Categoria',
                'descrizione'     : 'Descrizione',
                'flagDomestica'   : 'Domestica',
                'descrizionePrec' : 'Descrizione Precedente',
                'flagGiorni'      : 'Giornaliera'
        ]

        def converters = [
                flagDomestica: Converters.flagBooleanToString,
                flagGiorni   : Converters.flagBooleanToString
        ]

        if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
            fields << ['flagNoDepag': 'No DePag']
            converters << [flagNoDepag: Converters.flagBooleanToString]
        }

        def dizionario = 'Categorie'

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CATEGORIETARIFFE_CATEGORIE,
                [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                 anno       : selectedAnno])

        XlsxExporter.exportAndDownload(nomeFile,
                elencoCategorie,
                fields,
                converters)
    }

    @Command
    def onCopiaParticolareCategorie() {
        modificaCategoria(categoriaSelezionata, true, false, true)
    }

    @Command
    openCloseFiltriCategorie() {
        commonService.creaPopup("/archivio/dizionari/listaCategorieRicerca.zul", self, [tipoTributo: tipoTributoSelezionato.tipoTributo, filtro: filtroCategorie], { event ->
            if (event.data) {
                this.filtroCategorie = event.data.filtro
                this.filtroCategorieAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtroCategorie")
                BindUtils.postNotifyChange(null, null, this, "filtroCategorieAttivo")

                onRefresh()
            }
        })
    }

    @Command
    def onCategoriaSelected() {

        ricaricaListaTariffe(false)
    }

    // Apre finestra visualizza/modifica della categoria
    private def modificaCategoria(def identificativi, boolean modifica, boolean duplica = false, boolean copiaParticolare = false) {

        CategoriaDTO categoriaDTO = null

        if (identificativi) {
            categoriaDTO = canoneUnicoService.getCategoriaDaIdentificativiLista(identificativi)?.toDTO()
        }

        Window w = Executions.createComponents(
                "/archivio/dizionari/dettaglioCategoria.zul",
                self,
                [tipoTributo     : tipoTributoSelezionato.tipoTributo,
                 categoria       : categoriaDTO,
                 codiceTributo   : codiceTributoSelezionato.id,
                 modifica        : modifica && !lettura,
                 duplica         : duplica,
                 copiaParticolare: copiaParticolare]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaCategorie(true, true)
                }
            }
        }
        w.doModal()
    }

    // Elimina la categoria selezionata
    private def deleteCategoriaAndGetReport() {

        def report = [
                message: '',
                result : 0
        ]

        def categoria = categoriaSelezionata

        report.message = canoneUnicoService.checkCategoriaEliminabile(categoria)
        if (report.message.isEmpty()) {

            report = canoneUnicoService.eliminaCategoria(categoria)
        } else {
            report.result = 1
        }

        return report
    }

    // Rilegge elenco
    private def caricaListaCategorie(boolean resetPaginazione, boolean restorePagina = false) {

        def filtriNow = completaFiltriCategorie()

        if ((elencoCategorie.size() == 0) || resetPaginazione) {

            def activePageOld = pagingCategorie.activePage

            elencoCategorie = canoneUnicoService.getElencoCategorie(filtriNow)

            pagingCategorie = [
                    activePage: 0,
                    pageSize  : 25,
                    totalSize : elencoCategorie.size()
            ]

            if (restorePagina) {
                if (activePageOld < (pagingCategorie.totalSize / pagingCategorie.pageSize)) {
                    pagingCategorie.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingCategorie")
        }

        int fromIndex = pagingCategorie.pageSize * pagingCategorie.activePage
        int toIndex = Math.min((fromIndex + pagingCategorie.pageSize), pagingCategorie.totalSize)
        listaCategorie = elencoCategorie.subList(fromIndex, toIndex)
        categoriaSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "categoriaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    // Completa filtri
    private def completaFiltriCategorie() {

        def filtriNow = [
                tipoTributo  : tipoTributoSelezionato.tipoTributo,
                codiceTributo: codiceTributoSelezionato?.id,
                *            : filtroCategorie,
                flagDomestica: filtroCategorie.flagDomestica == 'Con' ? true : (filtroCategorie.flagDomestica == 'Senza' ? false : null),
                flagGiorni   : filtroCategorie.flagGiorni == 'Con' ? true : (filtroCategorie.flagGiorni == 'Senza' ? false : null),
                flagNoDepag  : (tipoTributoSelezionato.tipoTributo != 'CUNI') ? null :
                        (filtroCategorie.flagNoDepag == 'Con' ? true : (filtroCategorie.flagNoDepag == 'Senza' ? false : null))
        ]

        filtriNow.tipoTributo = tipoTributoSelezionato.tipoTributo
        filtriNow.codiceTributo = codiceTributoSelezionato?.id

        return filtriNow
    }

    @Command
    def onRicaricaListaTariffe() {

        ricaricaListaTariffe(false)
    }

    @Command
    def onCambioPaginaTariffe() {

        caricaListaTariffe(false)
    }

    @Command
    def onTariffaSelected() {

    }

    @Command
    def onNuovaTariffa() {

        modificaTariffa(null, true)
    }

    @Command
    def onModificaTariffa() {

        modificaTariffa(tariffaSelezionata.dto, true)
    }

    @Command
    def onDuplicaTariffa() {

        modificaTariffa(tariffaSelezionata.dto, true, true)
    }

    @Command
    def onEliminaTariffa() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        def report = deleteTariffaAndGetReport()

                        if (report.result != 0) {
                            visualizzaReport(report, "")
                            return
                        }

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        caricaListaTariffe(true, true)
                    }
                })
    }

    @Command
    def onTariffeToXls(@BindingParam("modalita") String modalita) {

        def mode = ExportXlsMode[modalita]

        def lista = getListaTariffeForXls(mode)
        def bigDecimalFormats = [
                tariffa          : tariffaFormat,
                tariffaQuotaFissa: tariffaFormat,
                percRiduzione    : riduzioneFormat,
                limite           : tariffaFormat,
                tariffaSuperiore : tariffaFormat]
        if (lista) {

            def fields
            if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
                fields = [
                        'anno'               : 'Anno',
                        'codiceTributo'      : 'Cod. Tributo',
                        'codiceTributoDescr' : 'Tributo',
                        'tipoTariffa'        : 'Tip.Tariffa',
                        'descrizione'        : 'Descrizione',

                        'tipologiaTariffa'   : 'T.Canone',
                        'categoria'          : 'Cod. Zona',
                        'categoriaDescr'     : 'Zona',
                        'tipologiaSecondaria': 'Trib.Sec.',
                        'tariffaQuotaFissa'  : 'Base',
                        'percRiduzione'      : '% Riduz. o Magg.',
                        'tariffa'            : 'Coeff.',
                        'limite'             : 'Limite',
                        'tipologiaCalcolo'   : 'Modalità',
                        'tariffaSuperiore'   : 'Coeff.Sup.',
                        'importoTariffa'     : 'Importo',
                        'flagNoDepag'        : 'No DePag',
                        'flagRuolo'          : 'Sospesa'
                ]
            } else {
                fields = [
                        'anno'                   : 'Anno',
                        'codiceTributo'          : 'Cod. Tributo',
                        'codiceTributoDescr'     : 'Tributo',
                        'tipoTariffa'            : 'Tip.Tariffa',
                        'descrizione'            : 'Descrizione',

                        'categoria'              : 'Cod. Categoria',
                        'categoriaDescr'         : 'Categoria',
                        'flagTariffaBase'        : 'Tar.Base',
                        'tariffa'                : 'Tariffa',
                        'riduzioneQuotaFissa'    : '%Rid.QF',
                        'riduzioneQuotaVariabile': '%Rid.QV',
                        'tariffaQuotaFissa'      : 'Tar.Quota Fissa',
                        'percRiduzione'          : '%Rid.M.T.',
                        'limite'                 : 'Limite',
                        'tariffaSuperiore'       : 'Tar.Sup.',
                        'tariffaPrec'            : 'Tar.Prec.',
                        'limitePrec'             : 'Lim.Prec.',
                        'tariffaSuperiorePrec'   : 'Tar.Sup.Prec.',
                ]

                bigDecimalFormats << [
                        riduzioneQuotaFissa    : riduzioneFormat,
                        riduzioneQuotaVariabile: riduzioneFormat,
                        tariffaPrec            : tariffaFormat,
                        limitePrec             : tariffaFormat,
                        tariffaSuperiorePrec   : tariffaFormat,

                ]
            }

            def formatters = [
                    flagTariffaBase: Converters.flagBooleanToString,
                    flagRuolo      : Converters.flagBooleanToString,
                    importoTariffa : { v -> v?.replace("€", "")?.trim() }
            ]

            if (tipoTributoSelezionato.tipoTributo == 'CUNI') {
                formatters << [flagNoDepag: Converters.flagBooleanToString]
            }

            def filename = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CATEGORIETARIFFE_TARIFFE,
                    [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale,
                     anno       : mode == ExportXlsMode.PARAMETRI ? selectedAnno : null])

            XlsxExporter.exportAndDownload(filename,
                    lista,
                    fields,
                    formatters,
                    bigDecimalFormats)
        }

    }

    private def getListaTariffeForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return elencoTariffe
        }
        if (mode == ExportXlsMode.TUTTI) {
            Map filtroExcel = [tipoTributo: tipoTributoSelezionato.tipoTributo]
            return canoneUnicoService.getElencoTariffe(filtroExcel)
        }
    }

    @Command
    openCloseFiltriTariffe() {
        commonService.creaPopup("/archivio/dizionari/listaTariffeRicerca.zul", self, [filtro: filtroTariffe, tipoTributo: tipoTributoSelezionato], { event ->
            if (event.data) {
                this.filtroTariffe = event.data.filtro
                this.filtroTariffeAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtroTariffe")
                BindUtils.postNotifyChange(null, null, this, "filtroTariffeAttivo")

                caricaListaTariffe(true)
            }
        })
    }

    // Verifica impostazioni filtro
    def aggiornaFiltroAttivoTariffe() {

        filtroAttivoTariffe = (filtroTariffe.codiceTributo != null) ||
                (filtroTariffe.categoria != null) ||
                (filtroTariffe.tipologiaTariffa != null) ||
                (filtroTariffe.descrizione != '')

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoTariffe")
    }

    // Apre finestra visualizza/modifica della tariffa
    private def modificaTariffa(TariffaDTO tariffa,
                                boolean modifica,
                                boolean duplica = false,
                                Short duplicaDaAnno = 0,
                                boolean copiaParticolare = false) {

        Window w = Executions.createComponents(
                "/archivio/dizionari/dettaglioTariffaCU.zul",
                self,
                [
                        tipoTributo     : tipoTributoSelezionato.tipoTributo,
                        annoTributo     : selectedAnno as String,
                        categoria       : categoriaSelezionata,
                        tariffa         : tariffa,
                        modifica        : modifica && !lettura,
                        duplica         : duplica,
                        duplicaDaAnno   : duplicaDaAnno,
                        copiaParticolare: copiaParticolare
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaTariffe(true, true)
                }
            }
        }
        w.doModal()
    }

    // Elimina la tariffa selezionata
    private def deleteTariffaAndGetReport() {

        def report = [
                message: '',
                result : 0
        ]

        def tariffa = tariffaSelezionata.dto

        report.message = canoneUnicoService.checkTariffaEliminabile(tariffa)
        if (report.message.isEmpty()) {
            report = canoneUnicoService.eliminaTariffa(tariffa)
        } else {
            report.result = 1
        }

        return report
    }

    private def ricaricaListaTariffe(Boolean pulisciFiltro) {

        caricaListaTariffe(true)

        controllaElencoTariffe()

        if (pulisciFiltro) {
            pulisciFiltroTariffe()
        }

        filtroTariffeDisabilitato = elencoTariffe.isEmpty()
        BindUtils.postNotifyChange(null, null, this, "filtroTariffeDisabilitato")
    }

    private def pulisciFiltroTariffe() {

        filtroTariffe = [:]
        filtroTariffeAttivo = false
        BindUtils.postNotifyChange(null, null, this, "filtroTariffe")
        BindUtils.postNotifyChange(null, null, this, "filtroTariffeAttivo")
    }

    // Rilegge elenco
    private def caricaListaTariffe(boolean resetPaginazione, boolean restorePagina = false) {

        def filtriNow = completaFiltriTariffe()

        if ((elencoTariffe.isEmpty()) || resetPaginazione) {

            def activePageOld = pagingTariffe.activePage

            pagingTariffe.activePage = 0

            if (filtriNow.categoria) {
                elencoTariffe = canoneUnicoService.getElencoTariffe(filtriNow)
            } else {
                elencoTariffe = []
            }

            pagingTariffe.totalSize = elencoTariffe.size()

            if (restorePagina) {
                if (activePageOld < (pagingTariffe.totalSize / pagingTariffe.pageSize)) {
                    pagingTariffe.activePage = activePageOld
                }
            }

            BindUtils.postNotifyChange(null, null, this, "pagingTariffe")
        }

        int fromIndex = pagingTariffe.pageSize * pagingTariffe.activePage
        int toIndex = Math.min((fromIndex + pagingTariffe.pageSize), pagingTariffe.totalSize)
        listaTariffe = elencoTariffe.subList(fromIndex, toIndex)
        tariffaSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "tariffaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaTariffe")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        def filter = [annoTributo  : selectedAnno,
                      tipoTributo  : tipoTributoSelezionato.tipoTributo,
                      codiceTributo: codiceTributoSelezionato?.id]
        return canoneUnicoService.contaTariffePerAnnualita(filter) == 0 &&
                !canoneUnicoService.getAnnualitaInTariffe(tipoTributoSelezionato.tipoTributo).empty
    }

    void openCopiaAnno() {
        def impostazioni = completaFiltriTariffe()

        impostazioni.tariffaSingola = false

        impostazioni.tipoTributoDes = tipoTributoSelezionato.tipoTributoAttuale + " - " + tipoTributoSelezionato.descrizione
        impostazioni.codiceTributoDes = (codiceTributoSelezionato.id < 0) ? codiceTributoSelezionato.descrizione :
                (codiceTributoSelezionato.id as String) + ' - ' + codiceTributoSelezionato.descrizione

        impostazioni.annoCopiaDa = annoCopiaDa

        commonService.creaPopup("/archivio/dizionari/copiaTariffeDaAnnualita.zul", self, [impostazioni: impostazioni], { event ->
            if (event.data) {
                if (event.data.annoOrigine) {
                    annoCopiaDa = event.data.annoOrigine as Short
                    copiaTariffeDaAnnualita(annoCopiaDa)
                }
            }
        })
    }

    // Verifica quando attivare "Nuova" multiplo su elenco tariffe vuoto
    def controllaElencoTariffe() {

        elencoTariffeVuoto = (elencoTariffe.size() == 0)
        BindUtils.postNotifyChange(null, null, this, "elencoTariffeVuoto")
    }

    @Command
    def onCopiaParticolareTariffe() {
        modificaTariffa(tariffaSelezionata.dto, true, false, null, true)
    }

    @Command
    // Conta le tariffe e se sono zero apre strumento copia
    def onDuplicaDaAnno() {

        if (!(tipoTributoSelezionato.tipoTributo in ['ICI', 'TASI'])) {
            def filtriNow = completaFiltriTariffe()
            def conteggio = canoneUnicoService.contaTariffePerAnnualita(filtriNow)

            if (((conteggio ?: 0) < 1) && (!lettura)) {
                openCopiaAnnoIfEnabled()
            }
        }
    }

    // Completa filtri
    private def completaFiltriTariffe() {

        def filtriNow = [
                annoTributo    : selectedAnno,
                tipoTributo    : tipoTributoSelezionato.tipoTributo,
                codiceTributo  : codiceTributoSelezionato?.id,
                categoria      : categoriaSelezionata,
                *              : filtroTariffe,
                flagRuolo      : filtroTariffe.flagRuolo == 'Con' ? true : (filtroTariffe.flagRuolo == 'Senza' ? false : null),
                flagTariffaBase: filtroTariffe.flagTariffaBase == 'Con' ? true : (filtroTariffe.flagTariffaBase == 'Senza' ? false : null),
                flagNoDepag    : filtroTariffe.flagNoDepag == 'Con' ? true : (filtroTariffe.flagNoDepag == 'Senza' ? false : null)
        ]

        return filtriNow
    }

    // Copia tariffe da altra annualita'
    private def copiaTariffeDaAnnualita(Short annoOrigine) {

        def filtriNow = completaFiltriTariffe()

        Short annoDestinazione = filtriNow.annoTributo
        filtriNow.annoTributo = annoOrigine

        def report = canoneUnicoService.copiaTariffeDaAnnualita(filtriNow, annoDestinazione)

        visualizzaReport(report, "Copia tariffe eseguita")

        ricaricaListaTariffe(false);
    }

    // Copia tariffa da altra annualita'
    private def copiaTariffaDaAnnualita(TariffaDTO tariffa, Short annoOrigine) {

        TariffaDTO tariffaCopia = canoneUnicoService.getTariffaDaAnnualita(tariffa, annoOrigine)

        if (tariffaCopia == null) {
            Clients.showNotification("Tariffa non trovata per l'anno ${annoOrigine}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
        } else {
            modificaTariffa(tariffaSelezionata.dto, true, true, annoOrigine)
        }
    }

    private verificaCompetenze() {
        listaTipiTributo.each {
            cbTributiAbilitati << [(it.tipoTributo): true]
        }
    }

    private caricaCodiciTributo() {
        listaCodiciTributo = canoneUnicoService.getCodiciTributo(tipoTributoSelezionato.tipoTributo, null, true)
        if (codiceTributoSelezionato) {
            codiceTributoSelezionato = listaCodiciTributo.find { it.id == codiceTributoSelezionato.id }
        }
        if (codiceTributoSelezionato == null) {
            codiceTributoSelezionato = listaCodiciTributo[0]
        }
        BindUtils.postNotifyChange(null, null, this, "codiceTributoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaCodiciTributo")
    }

    // Visualizza report
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 10000, true)
                break
        }
    }

    @GlobalCommand
    def setAnnoTributoAttivo(@BindingParam("annoTributo") def annoTributo) {

        this.selectedAnno = annoTributo

        BindUtils.postNotifyChange(null, null, this, "selectedAnno")
    }
}
