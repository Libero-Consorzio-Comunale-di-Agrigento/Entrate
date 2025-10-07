package catasto

import document.FileNameGenerator
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.catasto.VisuraService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class CatastoViewModel {

    Window self
    def catastoCensuarioService
    VisuraService visuraService

    def groupLabel = [immobili   : "/catasto/includeCatastoImmobili.zul",
                      proprietari: "/catasto/includeCatastoProprietari.zul"]

    def filtroAttivo = false

    List<FiltroRicercaOggetto> listaFiltriCatasto
    List<FiltroRicercaOggetto> listaFiltriCatastoOld

    def listaImmobili
    def listaImmobiliPagina
    def immobileSelezionato
    def listaProprietari

    def tipoVisualizzazione = "immobili"
    def tipoOrdinamentoImmobili = "estremi"
    def tipoOrdinamentoProprietari = "alfabetico"
    def topGroupLabel = groupLabel.immobili
    def bottomGroupLabel = groupLabel.proprietari

    def filtroProprietari = []
    def filtroProprietariOld = []

    def proprietarioSelezionato

    def paginazioneTop = [
            activePage: 0,
            pageSize  : 30,
            totalSize : null
    ]

    def paginazioneBottom = [
            activePage: 0,
            pageSize  : 30,
            totalSize : null
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        self = w

    }

    @Command
    def onSwapGroup() {

        topGroupLabel = groupLabel[tipoVisualizzazione]
        bottomGroupLabel = groupLabel.find { it.value != topGroupLabel }.value

        resetView()

        // Si ripristina, se presenti i filtri
        if (topGroupLabel == groupLabel.immobili) {
            listaFiltriCatasto = listaFiltriCatastoOld
            if (filtroAttivo()) {
                caricaListaImmobili()
            }
        } else {
            filtroProprietari = filtroProprietariOld
            if (filtroAttivo()) {
                caricalListaProprietari()
            }
        }

        filtroAttivo()

        BindUtils.postNotifyChange(null, null, this, "topGroupLabel")
        BindUtils.postNotifyChange(null, null, this, "bottomGroupLabel")
    }

    @Command
    def onOrderTopList() {
        if (topGroupLabel == groupLabel.immobili) {
            immobileSelezionato = null
            listaProprietari = null
            caricaListaImmobili()

            BindUtils.postNotifyChange(null, null, this, "immobileSelezionato")
            BindUtils.postNotifyChange(null, null, this, "listaProprietari")
        } else {
            proprietarioSelezionato = null
            listaImmobiliPagina = null
            listaImmobili = null

            caricalListaProprietari()

            BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
            BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
        }
    }

    @Command
    def onRicerca() {

        if (topGroupLabel == groupLabel.immobili) {
            immobileSelezionato = null
            ricercaImmobili()
        } else {
            ricercaProprietari()
        }
    }

    @Command
    def onPaging() {

        if (topGroupLabel == groupLabel.immobili) {
            caricaListaImmobili()
        } else {
            caricalListaProprietari()
        }
    }

    @Command
    def onSelezionaImmobile() {
        if (immobileSelezionato && topGroupLabel == groupLabel.immobili) {
            listaProprietari = catastoCensuarioService.getProprietariCatastoCensuario(immobileSelezionato.IDIMMOBILE, immobileSelezionato.TIPOOGGETTO)
                    .findAll {
                        it.DATAINIZIO <= new java.sql.Date(listaFiltriCatasto[0].validitaAl.time) &&
                                it.DATAFINE >= new java.sql.Date(listaFiltriCatasto[0].validitaDal.time)
                    }

            BindUtils.postNotifyChange(null, null, this, "listaProprietari")
        }
    }

    @Command
    def onSelezionaProprietario() {
        if (proprietarioSelezionato && topGroupLabel == groupLabel.proprietari) {
            def filtri = [
                    idSoggetto: proprietarioSelezionato.idSoggetto,
                    dataDa    : filtroProprietari.validitaDal?.format('ddMMyyyy') ?: '01011850',
                    dataA     : filtroProprietari.validitaAl?.format('ddMMyyyy') ?: '31129999'
            ]
            listaImmobiliPagina = catastoCensuarioService.getImmobiliDaProprietario(filtri, [
                    activePage: 0,
                    pageSize  : Integer.MAX_VALUE,
                    totalSize : null
            ]).data
            BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
        }
    }

    @Command
    def onRefresh() {
        if (topGroupLabel == groupLabel.immobili) {
            if (listaImmobiliPagina) {
                caricaListaImmobili()


                listaProprietari = null
                immobileSelezionato = null

                BindUtils.postNotifyChange(null, null, this, "listaProprietari")
                BindUtils.postNotifyChange(null, null, this, "immobileSelezionato")
            }
        } else {
            if (listaProprietari) {
                caricalListaProprietari()

                listaImmobiliPagina = null
                proprietarioSelezionato = null

                BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
                BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
            }
        }
        resetPaginazione()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("ni") def ni) {
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onExportImmobiliXls() {

        Map fields = [
                "IDFABBRICATO"       : "Immobile",
                "TIPOOGGETTO"        : "T",
                "INDIRIZZOCOMPLETO"  : "Indirizzo",
                "NUMCIV"             : "Num.Civ.",
                "PARTITA"            : "Partita",
                "SEZIONE"            : "Sez.",
                "FOGLIO"             : "Fgl.",
                "NUMERO"             : "Num.",
                "SUBALTERNO"         : "Sub.",
                "ZONA"               : "Zona",
                "CATEGORIACATASTO"   : "Ctg.",
                "CLASSECATASTO"      : "Cl.",
                "CONSISTENZA"        : "Cons.",
                "SUPERFICIE"         : "Sup.",
                "ETTARI"             : "Ettari",
                "ARE"                : "Are",
                "CENTIRARE"          : "Centiare",
                "REDDITODOMINICALE"  : "Rend./Redd.Dom.",
                "REDDITOAGRARIO"     : "Reddito Agrario",
                "QUALITADES"         : "Qualita",
                "SCALA"              : "Sc.",
                "PIANO"              : "Piano",
                "INTERNO"            : "Int.",
                "POSSESSO"           : "Possesso",
                "DATAEFFICACIAINIZIO": "Inizio Efficacia",
                "DATAEFFICACIAFINE"  : "Fine Efficacia",
                "isGraffato": "Graffato",
                "PRINCIPALE": "Sez./Fgl./Num/Sub. Princ.",
                "DATAVALIDITAINIZIO" : "Inizio Val.",
                "DATAVALIDITAFINE"   : "Fine Val.",
                "DESDIRITTO"         : "Diritto",
                "ANNOTAZIONE"        : "Note",
                "TITOLO"             : "Titolo Non COdificato"
        ]

        def excludeColumn = [
                "NUMCIV",
                "ETTARI",
                "ARE",
                "CENTIRARE",
                "QUALITADES",
                "SCALA",
                "PIANO",
                "INTERNO",
                "POSSESSO",
                "DATAVALIDITAINIZIO",
                "DATAVALIDITAFINE",
                "DESDIRITTO",
                "TITOLO"]

        def listaImmobiliXls = []

        if (topGroupLabel == groupLabel.immobili) {

            fields = fields.findAll { k, v -> !(k in excludeColumn) }

            listaImmobiliXls.addAll(listaImmobili)
        } else {
            listaImmobiliXls.addAll(listaImmobiliPagina)
        }

        def formatters =
                [
                        IDFABBRICATO: Converters.decimalToInteger,
                        TIPOOGGETTO: { v -> v as String },
                        isGraffato : Converters.flagBooleanToString

                ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_IMMOBILI_CATASTO,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaImmobiliXls, fields, formatters)
    }

    @Command
    def onExportProprietariXls() {

        Map fields = [
                "COGNOMENOME"        : "Contribuente",
                "CODFISCALE"         : "Codice fiscale",
                "SEDE"               : "Sede",
                "PROVINCIASEDE"      : "Provincia",
                "DATANASCITA"        : "Data Nascita",
                "LUOGONASCITA"       : "Comune di Nascita",
                "PROVINCIANASCITA"   : "Provincia",
                "POSSESSO"           : "Possesso",
                "DATAINIZIO"         : "Inzio Val.",
                "DATAFINE"           : "Fine Val.",
                "DIRITTO"            : "Diritto",
                "TITOLONONCODIFICATO": "Titolo non Codificato"

        ]

        def excludeColumn = [
                "POSSESSO",
                "DATAINIZIOFORMAT",
                "DATAFINEFORMAT",
                "DIRITTO",
                "TITOLONONCODIFICATO"
        ]

        def listaProprietariXls = []

        if (topGroupLabel == groupLabel.proprietari) {

            fields = fields.findAll { k, v -> !(k in excludeColumn) }

            listaProprietariXls = catastoCensuarioService.getProprietari(filtroProprietari,
                    [activePage: 0,
                     pageSize  : Integer.MAX_VALUE,
                     totalSize : null], tipoOrdinamentoProprietari, false).data

        } else {
            listaProprietariXls = listaProprietari
        }

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_PROPRIETARI_CATASTO,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaProprietariXls, fields)
    }

    @Command
    def onStampaVisura() {
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.VISURA,
                [:]
        )

        def reportVisura = visuraService.generaVisura(proprietarioSelezionato.CODFISCALE)

        if (reportVisura == null) {
            Clients.showNotification("In catasto non risultano unita' immobiliari per il contribuente."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportVisura.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    void onDenunciaDaCatasto() {
        creaPopup("/pratiche/denunce/denunciaDaCatasto.zul", [codFiscale: proprietarioSelezionato.CODFISCALE])
    }

    private ricercaImmobili() {
        Window w = Executions.createComponents("/catasto/listaOggettiCatastoRicerca.zul", self,
                [
                        filtri             : listaFiltriCatasto,
                        ricercaContribuente: false,
                        singoloTipoOggetto : false
                ])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    resetPaginazione()
                    listaFiltriCatasto = event.data.filtri

                    // Si salvano i dati di ricerca
                    listaFiltriCatastoOld = event.data.filtri

                    caricaListaImmobili()
                    filtroAttivo()

                    listaProprietari = null
                    immobileSelezionato = null
                    BindUtils.postNotifyChange(null, null, this, "listaProprietari")
                    BindUtils.postNotifyChange(null, null, this, "immobileSelezionato")
                }
            }
        }

        w.doModal()
    }

    private ricercaProprietari() {
        Window w = Executions.createComponents("/catasto/listaProprietariCatastoRicerca.zul", self,
                [
                        filtro: filtroProprietari
                ])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    resetPaginazione()
                    filtroProprietari = event.data.filtro
                    // Si salvano i dati di ricerca
                    filtroProprietariOld = event.data.filtro

                    caricalListaProprietari()
                    filtroAttivo()

                    proprietarioSelezionato = null
                    listaImmobili = null
                    listaImmobiliPagina = null
                    BindUtils.postNotifyChange(null, null, this, "listaImmobili")
                    BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
                    BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
                }
            }
        }

        w.doModal()
    }

    private caricaListaImmobili() {

        if (listaFiltriCatasto == null) {
            return
        }

        // listaImmobili
        switch (listaFiltriCatasto[0].tipoOggettoCatasto) {
            case "F":
                listaImmobili = catastoCensuarioService.getImmobiliCatastoUrbano(listaFiltriCatasto)
                break
            case "T":
                listaImmobili = catastoCensuarioService.getTerreniCatastoUrbano(listaFiltriCatasto)
                break
            case "E":
                listaImmobili = catastoCensuarioService.getImmobiliCatastoUrbano(listaFiltriCatasto) +
                        catastoCensuarioService.getTerreniCatastoUrbano(listaFiltriCatasto)
        }

        if (tipoOrdinamentoImmobili == 'estremi') {
            listaImmobili = listaImmobili.sort { a, b ->
                a.CONTATORE <=> b.CONTATORE ?:
                        a.DATAEFFICACIAINIZIO <=> b.DATAEFFICACIAINIZIO ?:
                                a.DATAEFFICACIAFINE <=> b.DATAEFFICACIAFINE ?:
                                        a.ESTREMICATASTALISORT <=> b.ESTREMICATASTALISORT
            }
        } else {
            listaImmobili = listaImmobili.sort { a, b ->
                a.CONTATORE <=> b.CONTATORE ?:
                        a.DATAEFFICACIAINIZIO <=> b.DATAEFFICACIAINIZIO ?:
                                a.DATAEFFICACIAFINE <=> b.DATAEFFICACIAFINE ?:
                                        a.INDIRIZZOCOMPLETO <=> b.INDIRIZZOCOMPLETO
            }
        }

        listaImmobiliPagina = listaImmobili.collate(paginazioneTop.pageSize)[paginazioneTop.activePage]
        paginazioneTop.totalSize = listaImmobili.size()

        BindUtils.postNotifyChange(null, null, this, "paginazioneTop")
        BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
    }

    private caricalListaProprietari() {
        if (filtroAttivo()) {
            listaProprietari = catastoCensuarioService.getProprietari(filtroProprietari, paginazioneTop, tipoOrdinamentoProprietari, false)
            paginazioneTop.totalSize = listaProprietari.totalCount
            listaProprietari = listaProprietari.data

            BindUtils.postNotifyChange(null, null, this, "listaProprietari")
            BindUtils.postNotifyChange(null, null, this, "paginazioneTop")
        }
    }


    private resetView() {
        listaFiltriCatasto = null
        listaImmobili = null
        listaImmobiliPagina = null
        listaProprietari = null

        resetPaginazione()

        filtroProprietari = []
        filtroAttivo = false

        immobileSelezionato = null
        proprietarioSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaFiltriCatasto")
        BindUtils.postNotifyChange(null, null, this, "listaImmobili")
        BindUtils.postNotifyChange(null, null, this, "listaImmobiliPagina")
        BindUtils.postNotifyChange(null, null, this, "listaProprietari")
        BindUtils.postNotifyChange(null, null, this, "filtroProprietari")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        BindUtils.postNotifyChange(null, null, this, "immobileSelezionato")
        BindUtils.postNotifyChange(null, null, this, "proprietarioSelezionato")
    }

    private resetPaginazione() {
        paginazioneTop = [
                activePage: 0,
                pageSize  : 30,
                totalSize : null
        ]

        paginazioneBottom = [
                activePage: 0,
                pageSize  : 30,
                totalSize : null
        ]

        BindUtils.postNotifyChange(null, null, this, "paginazioneTop")
        BindUtils.postNotifyChange(null, null, this, "paginazioneBottom")
    }

    private filtroAttivo() {

        if (topGroupLabel == groupLabel.immobili) {
            filtroAttivo = listaFiltriCatasto ? !listaFiltriCatasto.isEmpty() : false
        } else {
            filtroAttivo = filtroProprietari.cognome || filtroProprietari.nome || filtroProprietari.codiceFiscale || filtroProprietari.partita
        }

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

        return filtroAttivo
    }

    protected void creaPopup(String zul, def parametri, def onClose = {}) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }
}
