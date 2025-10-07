package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.*
import it.finmatica.tr4.modelli.ModelliService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.text.SimpleDateFormat
import java.text.DecimalFormat

class ListeDiCaricoRuoliViewModel {

    private static Log log = LogFactory.getLog(ListeDiCaricoRuoliViewModel)

    // services
    def springSecurityService
    ServletContext servletContext
    TributiSession tributiSession
    CompetenzeService competenzeService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    IntegrazioneDePagService integrazioneDePagService
    DocumentaleService documentaleService
    ModelliService modelliService
    CommonService commonService
    JasperService jasperService
    ComunicazioniService comunicazioniService

    // componenti
    Window self

    def dePagAbilitato = false
    Boolean modifica = false

    // tabellati
    def cbTipoRuolo = [
            T: 'P',
            2: 'S'
    ]

    def cbTipoCalcolo = [
            T: 'Tradizionale',
            N: 'Normalizzato',
            X: ''
    ]

    def cbTipoEmissione = [
            A: 'Acconto',
            S: 'Saldo',
            T: 'Totale',
            X: ''
    ]

    def dettagliTabs = [
            utenze  : false,
            pratiche: false
    ]

    List<Short> anno
    List<Short> listaAnni
    TipoTributoDTO tipoTributo
    List<TipoTributoDTO> listaTipiTributo = []

    Popup popupNote

    // Elenco Ruoli
    def selected
    def ruoloSingoloSelezionato
    def listaRuoli = []
    def ruoliSelezionati = [:]
    def selezioneRuoliAttiva = false
    def selezionePresente = { def l -> !l.findAll { it.value }.isEmpty() }

    def ruoliTarPuntuale = false

    def ruoloSelezionato = {
        def l ->
            l.findAll { it.value }.size() == 1 ? listeDiCaricoRuoliService
                    .getListaDiCaricoRuoli([daNumeroRuolo: l.find { it.value }.key,
                                            aNumeroRuolo : l.find { it.value }.key,
                                            tipoTributo  : tipoTributo.tipoTributo])
                    .records[0] : null
    }

    // totali
    def totaliList = [
            importo         : 0,
            sgravio         : 0,
            imposta         : 0,
            eccedenze       : 0,
            addECA          : 0,
            addProv         : 0,
            iva             : 0,
            maggTARES       : 0,
            compensazione   : 0,
            inviato         : 0,
            addProvImp      : 0,
            addProvEcc      : 0,
            addProvTooltip  : null
    ]

    // paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    // ricerca
    FiltroRicercaListeDiCaricoRuoli parRicerca
    boolean filtroAttivoList = false

    int selectedTab = 0

    // Elenco contribuenti ruolo
    def selectedDetail
    def listaDetailsRuolo = []

    def selectedAnyDetails = false
    def selectedDetails = [:]

    // totali
    def totaliDettagli = [
            contribuenti      : 0,
            utenze            : 0,
            importo           : 0,
            sgravio           : 0,
            imposta           : 0,
            eccedenze         : 0,
            addMaggEca        : 0,
            addProv           : 0,
            iva               : 0,
            importoPF         : 0,
            importoPV         : 0,
            maggiorazioneTares: 0,
            compensazione     : 0,
            versato           : 0,
            versatoC          : 0,
            versatoS          : 0,
            dovuto            : 0,
            addProvImp        : 0,
            addProvEcc        : 0,
            addProvTooltip    : null
    ]

    // paginazione
    def pagingDetails = [
            activePage: 0,
            pageSize  : 15,
            totalSize : 0
    ]

    // ricerca
    FiltroRicercaListeDiCaricoRuoliDetails parRicercaDetails
    boolean filtroAttivoDetails = false

    // Elenco utenze ruolo
    def selectedUtenza
    def listaUtenzeRuolo = []

    def selectedAnyUtenza = false
    def selectedUtenze = [:]

    // totali
    def totaliUtenze = [
            contribuenti      : 0,
            utenze            : 0,
            importo           : 0,
            sgravio           : 0,
            imposta           : 0,
            addMaggEca        : 0,
            addProv           : 0,
            iva               : 0,
            importoPF         : 0,
            importoPV         : 0,
            maggiorazioneTares: 0,
            compensazione     : 0
    ]

    // paginazione
    def pagingUtenze = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    // ricerca
    FiltroRicercaListeDiCaricoRuoliUtenze parRicercaUtenze
    boolean filtroAttivoUtenze = false

    // Elenco eccedenze ruolo
    def selectedEccedenza
    def listaEccedenzeRuolo = []

    // ricerca
    FiltroRicercaListeDiCaricoRuoliEccedenze parRicercaEccedenze
    boolean filtroAttivoEccedenze = false

    // totali
    def totaliEccedenze = [
            contribuenti      : 0,
            importoRuolo      : 0,
            imposta           : 0,
            addProv           : 0,
            costoSvuotamento  : 0,
            costoSuperficie   : 0
    ]

    // paginazione
    def pagingEccedenze = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    // Lista pratiche
    def colonnePraticheBase = [
            [label: "Pratica", tooltiptext: "Pratica"],
            [label: "Contribuente", tooltiptext: "Contribuente"],
            [label: "Cod.Fiscale", tooltiptext: "Codice Fiscale"],
            [label: "T.Prat.", tooltiptext: "Tipo Pratica"],
            [label: "Anno", tooltiptext: "Anno"],
            [label: "Numero", tooltiptext: "Numero"],
            [label: "Data Notifica", tooltiptext: "Data Notifica"],
            [label: "Imp.Totale", tooltiptext: "Importo Totale"],
            [label: "Imp.Ridotto", tooltiptext: "Importo Ridotto"],
            [label: "Imp.Versato", tooltiptext: "Importo Versato"]
    ]
    def colonnePraticheExtra = [
            [label: "Ruolo", tooltiptext: "Ruolo"]
    ]

    def colonnePraticheConSanzioni = []

    def listaPraticheRuolo = []
    def praticaRuoloSelezionata = null

    def ultimaSpecieSelezionata = -1

    def visualizzaRuoliSelezionati = false

    def cbTributiInScrittura = [:]

    //Ricerca Pratiche
    FiltroRicercaListeDiCaricoRuoliPratiche parRicercaPratiche
    boolean filtroAttivoPratiche = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        listaAnni = listeDiCaricoRuoliService.getListaAnni()
        listaTipiTributo = competenzeService.tipiTributoUtenza()

        if ((tipoTributo = listaTipiTributo.find { it.tipoTributo == "TARSU" }) == null) {
            tipoTributo = listaTipiTributo[0]
        }

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        if (!tributiSession.filtroRicercaListeDiCaricoRuoli)
            tributiSession.filtroRicercaListeDiCaricoRuoli = new FiltroRicercaListeDiCaricoRuoli()
        parRicerca = tributiSession.filtroRicercaListeDiCaricoRuoli
        verificaCampiFiltrantiList()

        parRicercaDetails = tributiSession.filtroRicercaListeDiCaricoRuoliDetails ?: new FiltroRicercaListeDiCaricoRuoliDetails()
        verificaCampiFiltrantiDetails()
        parRicercaUtenze = tributiSession.filtroRicercaListeDiCaricoRuoliUtenze ?: new FiltroRicercaListeDiCaricoRuoliUtenze()
        verificaCampiFiltrantiUtenze()
        parRicercaPratiche = tributiSession.filtroRicercaListeDiCaricoRuoliPratiche ?: new FiltroRicercaListeDiCaricoRuoliPratiche()
        verificaCampiFiltrantiPratiche()
        parRicercaEccedenze = tributiSession.filtroRicercaListeDiCaricoRuoliEccedenze ?: new FiltroRicercaListeDiCaricoRuoliEccedenze()
        verificaCampiFiltrantiEccedenze()

        aggiornaAbilitazione()
        if (parRicerca.isDirty()) {
            onRicaricaLista()
        } else {
            apriFiltriLista(false)
        }

        gestioneTabs()
        verificaCompetenze()
    }

    @Command
    onCambioTributo() {

        resetSelezioneRuoli()
        selectedDetailsReset()
        aggiornaAbilitazione()

        if (filtroAttivoList) {
            onRicaricaLista()
        } else {
            apriFiltriLista(true)
        }
    }

    @Command
    onSvuotaTutto() {

        ruoloSingoloSelezionato = null
        selected = null
        listaRuoli = []
        pagingList.activePage = 0
        pagingList.totalSize = 0

        parRicerca.svuotaTutto()
        verificaCampiFiltrantiList()

        BindUtils.postNotifyChange(null, null, this, "ruoloSingoloSelezionato")
        BindUtils.postNotifyChange(null, null, this, "selected")
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")

        BindUtils.postNotifyChange(null, null, this, "pagingList")

        BindUtils.postNotifyChange(null, null, this, "anno")

        onSvuotaTuttoDetails()
    }

    // Aggiorna flag modifica da diritti su tributo
    def aggiornaAbilitazione() {
        modifica = competenzeService.tipoAbilitazioneUtente(tipoTributo.tipoTributo) == 'A'
        BindUtils.postNotifyChange(null, null, this, "modifica")
    }

    // Tab panel
    @Command
    onSelectTabs() {

        switch (selectedTab) {
            case 0:
                verificaCampiFiltrantiDetails()
                onRicaricaListaDettagli()
                break
            case 1:
                verificaCampiFiltrantiUtenze()
                onRicaricaListaUtenze()
                break
            case 2:
                verificaCampiFiltrantiPratiche()
                onRicaricaListaPratiche()
                break
            case 3:
                verificaCampiFiltrantiEccedenze()
                onRicaricaListaEccedenze()
                break
        }
    }

    // Elenco ruoli

    @Command
    onRicaricaLista() {

        resetSelezioneRuoli()

        ricalcolaTotali()
        caricaListaRuoli()
        onRuoloSelected()

        gestioneTabs()
    }

    @Command
    onCambioPagina() {
        caricaListaRuoli()
    }

    @Command
    onRuoloSelected() {

    }

    @Command
    def onNuovaListaDiCarico() {
        modificaListaDiCarico(null)
    }

    @Command
    def onNuovoRuoloCoattivo() {
        modificaRuoloCoattivo(null)
    }

    @Command
    def onDoubleClickRuolo() {

        modificaRuolo(ruoloSingoloSelezionato)
    }

    @Command
    def onModificaRuolo() {

        modificaRuolo(ruoloSingoloSelezionato)
    }

    @Command
    def onInserimentoAutomatico() {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/inserimentoAutomaticoRuolo.zul",
                self,
                [ruolo: ruoloSingoloSelezionato.ruolo]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    onRicaricaLista()
                }
            }
        }
        w.doModal()
    }

    @Command
    onInviaAppIO() {
        def tipoDocumento = documentaleService.recuperaTipoDocumento(null, 'S')
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, tipoDocumento)
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : selectedDetail.codFiscale,
                 tipoTributo      : tipoTributo,
                 tipoComunicazione: tipoComunicazione,
                 pratica          : null,
                 tipologia        : "C",
                 anno             : selected.annoRuolo
                ])
    }

    @Command
    openFiltriLista() {

        apriFiltriLista(false)
    }

    @Command
    listToXls() throws Exception {

        def listaPerExport = []

        def caricoRuoli = listeDiCaricoRuoliService.getListaDiCaricoRuoli(completaParametriList())
        listaPerExport = caricoRuoli.records

        Map fields = [
                "tipoRuolo"             : "T.Ruolo",
                "annoRuolo"             : "Anno",
                "annoEmissione"         : "Anno Em.",
                "progrEmissione"        : "Pr.",
                "dataEmissione"         : "Emissione",
                "invioConsorzio"        : "Invio",
                "tributo"               : "Cod.",
                "importo"               : "Importo",
                "importoLordo"          : "L.",
                "sgravio"               : "Sgravio",
                "imposta"               : "Imposta"
        ]
        if(ruoliTarPuntuale) {
            fields << [ "eccedenze"     : "Eccedenze" ]
        }
        fields << [
                "addMaggEca"            : "ECA",
                "addPro"                : "Add.Prov.",
                "iva"                   : "IVA",
                "maggTares"             : "C.Pereq.",
                "ruolo"                 : "Ruolo",
                "specieRuolo"           : "Sp.",
                "tipoCalcoloDescr"      : "T. Calcolo",
                "tipoEmissioneDescr"    : "T. Em.",
                "flagTariffeRuolo"      : "Tar. Prec.",
                "flagCalcoloTariffaBase": "Tar. Base",
                "compensazione"         : "Compensazione",
                "isRuoloMaster"         : "Master"
        ]

        def converters = [
                tipoRuolo             : { value -> value == 1 ? "Principale" : "Suppletivo" },
                annoRuolo             : Converters.decimalToInteger,
                annoEmissione         : Converters.decimalToInteger,
                progrEmissione        : Converters.decimalToInteger,
                tributo               : Converters.decimalToInteger,
                ruolo                 : Converters.decimalToInteger,
                specieRuolo           : Converters.decimalToInteger,
                flagTariffeRuolo      : Converters.flagString,
                flagCalcoloTariffaBase: Converters.flagString,
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CARICO_RUOLI,
                [tipoTributo: tipoTributo.getTipoTributoAttuale()])
        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields, converters)
    }

    // Elaborazione ruolo o dettagli
    @Command
    def onElaboraRuolo() {

        def ruolo = selected ? selected.ruolo : ruoloSingoloSelezionato.ruolo
        def tipoTributoDescr = selected ? selected.tipoTributo : ruoloSingoloSelezionato.tipoTributo

        Window w = Executions.createComponents("/elaborazioni/creazioneElaborazione.zul",
                null,
                [
                        nomeElaborazione: "COM_${ruolo}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                        tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_RUOLI,
                        tipoTributo     : tipoTributoDescr,
                        ruolo           : ruolo
                ])
        w.doModal()
    }

    @Command
    def onElaboraDettagli() {
        Long ruolo = 0

        if (!selected) {

            def selectedDetailsCount = selectedDetails.findAll { k, v -> v }?.size() ?: 0
            if (selectedDetailsCount > 1) {
                Clients.showNotification("Funzione attiva sul singolo ruolo. Selezionare un solo ruolo dalla lista dei ruoli",
                        Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }
        } else {
            ruolo = selected.ruolo.toLong()
        }

        def tipoTributoDescr = this.tipoTributo.tipoTributo

        def pratiche = []
        int numPratiche = 0

        for (e in selectedDetails) {
            if (e.value != false) {

                String codUnivoco = e.key
                def codPortions = codUnivoco.tokenize("_")
                pratiche << [codFiscale: codPortions[1]]
                numPratiche++

                if (ruolo == 0) {
                    ruolo = codPortions[0] as Long
                }
            }
        }
        if (ruolo == 0) {
            throw new Exception("Impossibile determinare Ruolo del Contribuente !")
        }

        if (numPratiche == 1) {

            def specie = Ruolo.get(ruolo).specieRuolo
            // Coattivo - nessuna stampa attiva
            if (specie) {
                Clients.showNotification("Funzionalità di stampa non attiva per i ruoli coattivi.", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                return
            } else {
                // Ordinario - attiva la stampa solo per TARSU
                if (tipoTributo.tipoTributo != 'TARSU') {
                    Clients.showNotification("Funzionalità di stampa non attiva per i ruoli ordinari ${tipoTributo.getTipoTributoAttuale()}.", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                    return
                }
            }

            def codFiscale = pratiche[0].codFiscale

            def parametriRicerca = completaParametriDetails()
            parametriRicerca.codFiscale = codFiscale
            def caricoDettagli = listeDiCaricoRuoliService.getContribuentiRuolo(parametriRicerca)

            def contribuente = null
            def listDetails = caricoDettagli.records
            if (listDetails.size() == 1) {
                contribuente = listDetails[0]
            }
            if (contribuente == null) {
                throw new Exception("Impossibile ricavare dati Contribuente!")
            }

            def nomeFile = "COM_" + (ruolo as String).padLeft(10, "0") + "_" + codFiscale.padLeft(16, "0")

            def parametri = [

                    tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                    idDocumento: [
                            tipoTributo: tipoTributoDescr,
                            ruolo      : tipoTributoDescr in ['ICI', 'TASI'] ? 0 : ruolo,
                            anno       : selected.annoRuolo,
                            codFiscale : codFiscale,
                            pratica    : tipoTributoDescr in ['ICI', 'TASI'] ? -1 : pratiche[0].id
                    ],
                    nomeFile   : nomeFile,
            ]

            commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
        } else {

            commonService.creaPopup("/elaborazioni/creazioneElaborazione.zul",
                    self,
                    [
                            nomeElaborazione: "COM_${ruolo}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                            tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_RUOLI,
                            tipoTributo     : tipoTributoDescr,
                            ruolo           : ruolo,
                            pratiche        : pratiche
                    ])
        }
    }


// Dettagli del ruolo
    @Command
    onRicaricaListaDettagli() {
        ricalcolaTotaliDettagli()
        caricaListaDettagli()
    }

    @Command
    onCambioPaginaDettagli() {

        caricaListaDettagli()
    }

    @Command
    def onChangeStatoDetails(@BindingParam("lbRuoli") def lbRuoli) {

        ricalcolaTotaliDettagli()
        caricaListaDettagli()
    }

    @Command
    def onChangeVersatoVersusDovuto() {
        ricalcolaTotaliDettagli()
        caricaListaDettagli()
    }

    @Command
    def onChangeSoglia() {
        if ((parRicercaDetails.versatoVersusDovuto as Integer) != -1) {
            onRicaricaListaDettagli()
        }
    }

    @Command
    onSelezionaDetail() {
    }

    @Command
    onCheckAllDetails() {

        selectedAnyDetailsRefresh()

        selectedDetails = [:]

        // Se non era selezionata almeno un elemento allora seleziona tutto
        if (!selectedAnyDetails) {

            //Caricare tutti i dati
            def parametriRicerca = completaParametriDetails()
            def caricoDettagli = listeDiCaricoRuoliService.getContribuentiRuolo(parametriRicerca)
            def listDetails = caricoDettagli.records

            listDetails.each() { d -> (selectedDetails << [(d.codUnivoco): true]) }
        }
        // Si aggiorna la presenza di selezione
        selectedAnyDetailsRefresh()


        BindUtils.postNotifyChange(null, null, this, "selectedDetails")

    }

    @Command
    onCheckDetail(@BindingParam("detail") def detail) {
        selectedAnyDetailsRefresh()
    }

    @Command
    openFiltriDetails() {

        parRicerca.preparaRicercaDetails(parRicercaDetails)

        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoloDettagliRicerca.zul", self, [parRicerca: parRicercaDetails])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicercaDetails = event.data.parRicerca
                    parRicerca.applicaRicercaDetails(parRicercaDetails)
                    tributiSession.filtroRicercaListeDiCaricoRuoliDetails = parRicercaDetails
                    BindUtils.postNotifyChange(null, null, this, "parRicercaDetails")

                    onRicaricaListaDettagli()
                }
            }

            verificaCampiFiltrantiDetails()

            selectedDetail = null
            BindUtils.postNotifyChange(null, null, this, "selectedDetail")
        }
        w.doModal()
    }

    @Command
    detailsToXls(@BindingParam("totale") int totale) throws Exception {

        def listaPerExport = []

        def ruoloSingolo = selected
        def numeroRuolo = (ruoloSingolo) ? ruoloSingolo.ruolo : 'Vari'

        if (totale != 0) {
            def parametriRicerca = completaParametriDetails()
            def caricoDettagli = listeDiCaricoRuoliService.getContribuentiRuolo(parametriRicerca)
            listaPerExport = caricoDettagli.records
        } else {
            listaPerExport = listaDetailsRuolo.clone()
        }

        def converters = [
                comuneResErr                 : { value -> value == 'ERR' ? 'ERRATO' : null },
                capResErr                    : { value -> value == 'ERR' ? 'ERRATO' : null },
                "ruoloSingolo.tipoRuolo"     : { value -> value == 1 ? "Principale" : "Suppletivo" },
                "ruoloSingolo.ruolo"         : Converters.decimalToInteger,
                "ruoloSingolo.progrEmissione": Converters.decimalToInteger,
                ruolo                        : Converters.decimalToInteger,
                "ruoloSingolo.annoRuolo"     : Converters.decimalToInteger,
                "ruoloSingolo.annoEmissione" : Converters.decimalToInteger,
                anno                         : Converters.decimalToInteger
        ]

        listaPerExport.each {

            //Parametri ruolo
            if (ruoloSingolo) {
                it.ruoloSingolo = ruoloSingolo
            }
        }

        Map fieldsRuoloSingolo = [
                "ruoloSingolo.ruolo"         : "Ruolo",
                "ruoloSingolo.tipoRuolo"     : "T.Ruolo",
                "ruoloSingolo.annoRuolo"     : "Anno",
                "ruoloSingolo.annoEmissione" : "Anno Em.",
                "ruoloSingolo.progrEmissione": "Pr.",
                "ruoloSingolo.dataEmissione" : "Emissione",
                "ruoloSingolo.invioConsorzio": "Invio"
        ]

        Map fieldsRuoliMultipli = [
                "ruolo": "Ruolo",
        ]

        Map fields = [
                "cognomeNome"       : "Contribuente",
                "codFiscale"        : "Cod. Fis.",
                "importo"           : "Importo",
                "sgravio"           : "Sgravio",
                "compensazione"     : "Compensazione",
                "versato"           : "Versato",
                "dovuto"            : "Dovuto",
                "imposta"           : "Imposta",
        ]
        if(ruoliTarPuntuale) {
            fields << [ "eccedenze" : "Eccedenze" ]
        }
        fields << [
                "addMaggEca"        : "ECA",
                "addProv"           : "Add Prov.",
                "iva"               : "IVA",
                "importoPF"         : "Quota Fissa",
                "importoPV"         : "Quota Var.",
                "maggiorazioneTares": "C.Pereq.",
                "residente"         : "Residente",
                "statoDescrizione"  : "Stato",
                "dataUltEvento"     : "Data Evento",
                "indirizzoRes"      : "Indirizzo Res.",
                "civicoRes"         : "Civico Res.",
                "comuneRes"         : "Comune Res.",
                "capRes"            : "CAP Res.",
                "cognomeNomeP"      : "Presso",
                "mailPEC"           : "Indirizzo PEC",

                "tariffaBase"       : "Tariffa Base",
                "importoBase"       : "Importo Base",
                "importoSgravioBase": "Sgravio Base",
                "impostaBase"       : "Imposta Base",
                "addMaggECABase"    : "ECA Base",
                "addProvBase"       : "Add Prov. Base",
                "ivaBase"           : "IVA Base",
                "importoPVBase"     : "Quota Fissa Base",
                "importoPFBase"     : "Quota Var. Base",
                "impRiduzionePF"    : "Riduz. Quota Fissa",
                "impRiduzionePV"    : "Riduz. Quota Var.",
        ]

        if (ruoloSingolo) {
            fields = fieldsRuoloSingolo + fields
        } else {
            fields = fields + fieldsRuoliMultipli
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CONTRIBUENTI_A_RUOLO,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 idRuolo    : numeroRuolo])

        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields, converters)
    }

    @Command
    def onPraticheToXls() {

        def listaPerExport = []

        def ruoloSingolo = selected
        def numeroRuolo = (ruoloSingolo) ? ruoloSingolo.ruolo : 'Vari'

        listaPraticheRuolo.each { p ->
            def row = []
            p.each { c ->

                def valore = ''

                switch (c.type) {
                    case "currency":
                        valore = c.label as BigDecimal
                        break
                    default:
                        valore = c.label
                }

                row << [(c.key as String): valore]
            }
            listaPerExport << row.collectEntries()
        }

        List labels = listaPraticheRuolo[0].collect { it.key as String }
        if (ruoloSingolo) {
            labels.remove("ruolo")
        }

        Map fields = [:]
        int index = 0
        labels.each {
            fields << [(it): colonnePraticheConSanzioni[index++].label]
        }

        def fieldsToXls = [:]

        def converters = [
                "ruoloSingolo.tipoRuolo"     : { value -> value == 1 ? "Principale" : "Suppletivo" },
                "ruoloSingolo.ruolo"         : Converters.decimalToInteger,
                "ruoloSingolo.annoRuolo"     : Converters.decimalToInteger,
                "ruoloSingolo.progrEmissione": Converters.decimalToInteger,
                "ruoloSingolo.annoEmissione" : Converters.decimalToInteger,
                pratica                      : Converters.decimalToInteger,
                anno                         : Converters.decimalToInteger
        ]

        if (ruoloSingolo) {
            def fieldsRuoloSingolo = [
                    "ruoloSingolo.ruolo"         : "Ruolo",
                    "ruoloSingolo.tipoRuolo"     : "T.Ruolo",
                    "ruoloSingolo.annoRuolo"     : "Anno",
                    "ruoloSingolo.annoEmissione" : "Anno Em.",
                    "ruoloSingolo.progrEmissione": "Pr.",
                    "ruoloSingolo.dataEmissione" : "Emissione",
                    "ruoloSingolo.invioConsorzio": "Invio"
            ]

            fieldsToXls = fieldsRuoloSingolo + fields

            //Aggiungo parametri ruolo
            listaPerExport.each {
                it.ruoloSingolo = ruoloSingolo
            }
        } else {
            fieldsToXls = fields
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CONTRIBUENTI_A_RUOLO,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 idRuolo    : numeroRuolo])

        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fieldsToXls, converters)
    }

    // Utenze del ruolo
    @Command
    onRicaricaListaUtenze() {

        ricalcolaTotaliUtenze()
        caricaListaUtenze()
    }

    @Command
    onCambioPaginaUtenze() {

        caricaListaUtenze()
    }

    @Command
    onSelezionaUtenza() {

    }

    @Command
    onCheckAllUtenze() {

        selectedAnyUtenzaRefresh()

        selectedUtenze = [:]

        // Se non era selezionata almeno un elemento allora seleziona tutto
        if (!selectedAnyUtenza) {
            //Caricare tutti i dati
            def parametriRicerca = completaParametriUtenze()
            def caricoUtenze = listeDiCaricoRuoliService.getUtenzeRuolo(parametriRicerca)
            def listUtenze = caricoUtenze.records

            listUtenze.each() { d -> (selectedUtenze << [(d.codUnivoco): true]) }
        }
        // Si aggiorna la presenza di selezione
        selectedAnyUtenzaRefresh()

        BindUtils.postNotifyChange(null, null, this, "selectedUtenze")
    }

    @Command
    onCheckUtenza(@BindingParam("utenza") def utenza) {

        selectedAnyUtenzaRefresh()
    }

    @Command
    def onChangeStatoUtenze(@BindingParam("lbRuoli") def lbRuoli) {

        ricalcolaTotaliUtenze()
        caricaListaUtenze()
    }

    // Pratiche del ruolo
    @Command
    onRicaricaListaPratiche() {

        try {
            self.getFellow("includeListBoxDetailsPratiche").getFellow("listBoxDetailsPratiche").invalidate()
        } catch (Exception e) {
            log.error(e)
        }

        caricaListaPratiche()
    }

    @Command
    openFiltriUtenze() {

        parRicerca.preparaRicercaUtenze(parRicercaUtenze)

        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoloUtenzeRicerca.zul", self, [parRicerca: parRicercaUtenze])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicercaUtenze = event.data.parRicerca
                    parRicerca.applicaRicercaUtenze(parRicercaUtenze)
                    tributiSession.filtroRicercaListeDiCaricoRuoliUtenze = parRicercaUtenze
                    BindUtils.postNotifyChange(null, null, this, "parRicercaUtenze")

                    onRicaricaListaUtenze()
                }
            }

            verificaCampiFiltrantiUtenze()

            selectedUtenza = null
            BindUtils.postNotifyChange(null, null, this, "selectedUtenza")
        }
        w.doModal()
    }

    @Command
    def utenzeToXls() throws Exception {

        def listaPerExport = []

        def ruoloSingolo = selected
        def numeroRuolo = (ruoloSingolo) ? ruoloSingolo.ruolo : 'Vari'

        def parametriRicerca = completaParametriUtenze()
        parametriRicerca.perExport = true
        def caricoUtenze = listeDiCaricoRuoliService.getUtenzeRuolo(parametriRicerca)
        listaPerExport = caricoUtenze.records

        def converters = [
                comuneResErr                 : { value -> value == 'ERR' ? 'ERRATO' : null },
                capResErr                    : { value -> value == 'ERR' ? 'ERRATO' : null },
                "ruoloSingolo.tipoRuolo"     : { value -> value == 1 ? "Principale" : "Suppletivo" },
                "ruoloSingolo.progrEmissione": Converters.decimalToInteger,
                oggetto                      : Converters.decimalToInteger,
                "ruoloSingolo.ruolo"         : Converters.decimalToInteger,
                codiceTributo                : Converters.decimalToInteger,
                numeroFamiliari              : Converters.decimalToInteger,
                ruolo                        : Converters.decimalToInteger
        ]

        listaPerExport.each {
            if (ruoloSingolo) {
                it.ruoloSingolo = ruoloSingolo
            }
        }

        Map fieldsRuoloSingolo = [
                "ruoloSingolo.ruolo"         : "Ruolo",
                "ruoloSingolo.tipoRuolo"     : "T.Ruolo",
                "ruoloSingolo.annoRuolo"     : "Anno",
                "ruoloSingolo.annoEmissione" : "Anno Em.",
                "ruoloSingolo.progrEmissione": "Pr.",
                "ruoloSingolo.dataEmissione" : "Emissione",
                "ruoloSingolo.invioConsorzio": "Invio"
        ]
        Map fields = [
                "oggetto"           : "Oggetto",
                "cognomeNome"       : "Contribuente",
                "codFiscale"        : "Cod. Fis.",

                "importo"           : "Importo",
                "sgravio"           : "Sgravio",
                "compensazione"     : "Compensazione",
                "imposta"           : "Imposta",
                "addMaggEca"        : "ECA",
                "addProv"           : "Add Prov.",
                "iva"               : "IVA",
                "importoPF"         : "Quota Fissa",
                "importoPV"         : "Quota Var.",

                "maggiorazioneTares": "C.Pereq.",
                "consistenza"       : "Consistenza",
                "indOgge"           : "Indirizzo",
                "abPrincipale"      : "A.P.",
                "giorniRuolo"       : "GG",
                "residente"         : "Residente",
                "statoDescrizione"  : "Stato",
                "dataUltEvento"     : "Ultima Var.",
                "indirizzoRes"      : "Indirizzo Res.",
                "civicoRes"         : "Civico Res.",
                "comuneRes"         : "Comune Res.",
                "comuneResErr"      : "Anomalia Comune Res.",
                "capRes"            : "CAP Res.",
                "capResErr"         : "Anomalia CAP Res.",
                "cognomeNomeP"      : "Presso",
                "mailPEC"           : "Indirizzo PEC",
                "numeroFamiliari"   : "Componenti",
                "codiceTributo"     : "Cod.Tributo",
                "desCategoria"      : 'Des. Categoria',
                "desTariffa"        : 'Des. Tariffa',
                "tariffaBase"       : "Tariffa Base",
                "importoBase"       : "Importo Base",
                "importoSgravioBase": "Sgravio Base",
                "impostaBase"       : "Imposta Base",
                "addMaggECABase"    : "ECA Base",
                "addProvBase"       : "Add Prov. Base",
                "ivaBase"           : "IVA Base",
                "importoPVBase"     : "Quota Fissa Base",
                "importoPFBase"     : "Quota Var. Base",
                "impRiduzionePF"    : "Riduz. Quota Fissa",
                "impRiduzionePV"    : "Riduz. Quota Var.",
        ]
        Map fieldsRuoliMultipli = [
                "ruolo": "Ruolo",
        ]

        if (ruoloSingolo) {
            fields = fieldsRuoloSingolo + fields
        } else {
            fields = fields + fieldsRuoliMultipli
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.UTENZE_RUOLO,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 idRuolo    : numeroRuolo])
        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields, converters)
    }

    @Command
    def onCheckAllRuoli() {

        if (selezionePresente(ruoliSelezionati)) {
            resetSelezioneRuoli()
        } else {
            ruoliSelezionati.clear()
            ruoliSelezionati <<
                    listeDiCaricoRuoliService.getListaDiCaricoRuoli(completaParametriList())
                            .records.collect { [(it.ruolo): true] }.unique().collectEntries()

            if (isSelezioneValidaRuoli()) {
                ruoliSelezionati.clear()
                BindUtils.postNotifyChange(null, null, this, "ruoliSelezionati")
            }
        }

        selezioneRuoliAttiva = selezionePresente(ruoliSelezionati)
        selected = ruoloSelezionato(ruoliSelezionati)

        gestioneTabs()

        BindUtils.postNotifyChange(null, null, this, "ruoliSelezionati")
        BindUtils.postNotifyChange(null, null, this, "selezioneRuoliAttiva")
        BindUtils.postNotifyChange(null, null, this, "selected")
    }

    @Command
    def onCheckRuolo(@BindingParam("ruolo") def ruolo) {

        if (isSelezioneValidaRuoli()) {
            ruoliSelezionati[ruolo.ruolo] = false
            BindUtils.postNotifyChange(null, null, this, "ruoliSelezionati")
            return
        }

        selezioneRuoliAttiva = selezionePresente(ruoliSelezionati)
        selected = ruoloSelezionato(ruoliSelezionati)

        onSvuotaTuttoDetails()
        onSvuotaTuttoUtenze()
        onSvuotaTuttoPratiche()

        gestioneTabs()

        BindUtils.postNotifyChange(null, null, this, "selezioneRuoliAttiva")
        BindUtils.postNotifyChange(null, null, this, "selected")
    }

    @Command
    def onEmissioneRuolo() {

        def datiEmissione = [:]

        datiEmissione.ruolo = ruoloSingoloSelezionato.ruolo as Long
        datiEmissione.codFiscale = '%'

        Window w = Executions.createComponents("/sportello/contribuenti/emissioneRuolo.zul", self,
                [ruolo: datiEmissione, lettura: false]
        )
        w.onClose() { event ->
            if (event.data)
                if (event.data.elaborato) {
                    onRicaricaLista()
                }
        }
        w.doModal()
    }

    @Command
    def onEliminaRuolo() {

        String messaggio = "Confermi di voler eliminare il Ruolo: ${ruoloSingoloSelezionato.ruolo}?"
        Messagebox.show(messaggio, "Eliminazione Ruolo",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        eliminaContribuenteDaRuolo(ruoloSingoloSelezionato.ruolo as Long, null as String)
                        onRicaricaLista()
                    }
                }
        )
    }

    @Command
    def onGeneraTrasmissione() {

        commonService.creaPopup("/ufficiotributi/imposte/inviaConsorzio.zul", self, [
                elencoIdRuoli: ruoliSelezionati
                        .findAll { it.value }
                        .collect { it.key as Long },
                tipoTributo  : tipoTributo
        ])
    }

    @Command
    def onCancellaPratica() {

        Long pratica = praticaRuoloSelezionata.find { it.key == 'pratica' }?.label as Long
        Long ruolo = praticaRuoloSelezionata.find { it.key == 'ruolo' }?.label as Long

        Map params = new HashMap()
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        Messagebox.show("La pratica verrà eliminata dal ruolo.\nProcedere?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {

                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                listeDiCaricoRuoliService.eliminaPraticaDaRuolo(pratica, ruolo)
                                caricaListaPratiche()
                                break
                        }
                    }
                }
                , params)
    }

    @Command
    def onCancellaContribuente() {

        def codFiscale = selectedDetail.codFiscale
        def ruolo = selectedDetail.ruolo as Long

        if (ruolo == 0) {
            throw new Exception("Impossibile determinare Ruolo del Contribuente !")
        }

        Map params = new HashMap()
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        Messagebox.show("Il contribuente ${codFiscale} verrà eliminato dal ruolo.\nProcedere?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {

                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                eliminaContribuenteDaRuolo(ruolo, codFiscale)
                                caricaListaDettagli()
                                break
                        }
                    }
                }
                , params)
    }

    @Command
    def onVisualizzaRuoliSelezionati() {

        ricalcolaTotali()
        caricaListaRuoli()

        BindUtils.postNotifyChange(null, null, this, "pagingList")
    }

    @Command
    openFiltriPratiche() {

        parRicerca.preparaRicercaPratiche(parRicercaPratiche)

        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoloPraticheRicerca.zul", self, [parRicerca: parRicercaPratiche])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicercaPratiche = event.data.parRicerca
                    parRicerca.applicaRicercaPratiche(parRicercaPratiche)
                    tributiSession.filtroRicercaListeDiCaricoRuoliPratiche = parRicercaPratiche
                    BindUtils.postNotifyChange(null, null, this, "parRicercaPratiche")

                    onRicaricaListaPratiche()
                }
            }

            verificaCampiFiltrantiPratiche()

        }
        w.doModal()
    }

    // Eccedenze del ruolo
    @Command
    onRicaricaListaEccedenze() {

        ricalcolaTotaliEccedenze()
        caricaListaEccedenze()
    }

    @Command
    onCambioPaginaEccedenze() {

        caricaListaEccedenze()
    }

    @Command
    onSelezionaEccedenza() {

    }

    @Command
    void onApriPopupNote(@ContextParam(ContextType.COMPONENT) Popup popupNote) {
        this.popupNote = popupNote
    }

    @Command
    void onChiudiPopupNote() {
        this.popupNote.close()
    }

    @Command
    def onEccedenzeToXls() throws Exception {

        def listaPerExport = []

        def ruoloSingolo = selected
        def numeroRuolo = (ruoloSingolo) ? ruoloSingolo.ruolo : 'Vari'

        def parametriRicerca = completaParametriEccedenze()
        parametriRicerca.perExport = true
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca)
        listaPerExport = caricoEccedenze.records

        listaPerExport.each {
            if (ruoloSingolo) {
                it.ruoloSingolo = ruoloSingolo
            }
        }

        Map fieldsRuoloSingolo = [
                "ruoloSingolo.ruolo"         : "Ruolo",
                "ruoloSingolo.tipoRuolo"     : "T.Ruolo",
                "ruoloSingolo.annoRuolo"     : "Anno",
                "ruoloSingolo.annoEmissione" : "Anno Em.",
                "ruoloSingolo.progrEmissione": "Pr.",
                "ruoloSingolo.dataEmissione" : "Emissione",
                "ruoloSingolo.invioConsorzio": "Invio"
        ]
        Map fieldsRuoliMultipli = [
                "ruolo": "Ruolo",
        ]
        Map fields = [
                "cognomeNome"       : "Contribuente",
                "codFiscale"        : "Codice Fiscale",
                "tributo"           : "Cod.",
                "categoria"         : "Categoria",
                "dataDal"           : "Dal",
                "dataAl"            : "Al",
                "flagDomestica"     : "Domestica",
                "numeroFamiliari"   : "Num.Fam.",
                "importoRuolo"      : "Importo",
                "imposta"           : "Eccedenze",
                "addProv"           : "Add.Prov.",
                "numeroFamiliari"   : "Num.Fam.",
                "importoMinimi"     : "Imp.Minimi",
                "totaleSvuotamenti" : "Tot.Svuot.",
                "superficie"        : "Sup.",
                "costoSvuotamento"  : "Costo Svuot.",
			    "svuotamentiSuperficie" : "Svuot.Sup.",
		        "costoSuperficie"       : "Costo Sup.",
		        "eccedenzaSvuotamenti"  : "Ecc.Svuot.",
                "note"              : "Note",
        ]

        if (ruoloSingolo) {
            fields = fieldsRuoloSingolo + fields
        } else {
            fields = fields + fieldsRuoliMultipli
        }

        def converters = [
                'ruoloSingolo.ruolo'          : Converters.decimalToInteger,
                'ruoloSingolo.tipoRuolo'      : Converters.decimalToInteger,
                'ruoloSingolo.annoRuolo'      : Converters.decimalToInteger,
                'ruoloSingolo.annoEmissione'  : Converters.decimalToInteger,
                'ruoloSingolo.progrEmissione' : Converters.decimalToInteger,
                'ruolo'                       : Converters.decimalToInteger,
                'tributo'                     : Converters.decimalToInteger,
                'categoria'                   : Converters.decimalToInteger,
                'numeroFamiliari'             : Converters.decimalToInteger,
                'flagDomestica'               : { value -> (value) ? 'SI' : 'NO' },
        ]

        def bigDecimalFormats = [
                "costoUnitario"      : '#,##0.00000000'
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ECCEDENZE_RUOLO,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 idRuolo    : numeroRuolo])

        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields, converters, bigDecimalFormats)
    }

    @Command
    def onOpenFiltriEccedenze() {
    
        parRicerca.preparaRicercaEccedenze(parRicercaEccedenze)
        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoloEccedenzeRicerca.zul", self, 
            [
                parRicerca: parRicercaEccedenze
            ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicercaEccedenze = event.data.parRicerca
                    parRicerca.applicaRicercaEccedenze(parRicercaEccedenze)
                    tributiSession.filtroRicercaListeDiCaricoRuoliEccedenze = parRicercaEccedenze
                    BindUtils.postNotifyChange(null, null, this, "parRicercaEccedenze")

                    onRicaricaListaEccedenze()
                }
            }

            verificaCampiFiltrantiEccedenze()

            selectedEccedenza = null
            BindUtils.postNotifyChange(null, null, this, "selectedEccedenza")
        }
        w.doModal()
    }

    @Command
    def onStampaMinutaDiRuolo() {
        commonService.creaPopup("/ufficiotributi/imposte/listeDiCaricoRuoliOrdinamento.zul", self, null,
                { event ->
                    if (event.data) {

                        if (event.data.ordinamento && event.data.filtro) {
                            stampaMinutaDiRuolo(event.data.ordinamento, event.data.filtro)
                        }
                    }
                })

    }

    @Command
    def onStampaRiepilogoPerCategoria() {
        stampaRiepilogoPerCategoria()
    }

    @Command
    def onStampaMinutaPerCategoria() {
        apriRicercaCategorie()
    }

    private def apriRicercaCategorie() {

        commonService.creaPopup("/ufficiotributi/imposte/ricercaCategorieMinutaPerCategoria.zul",
                self,
                [tributo: ruoloSingoloSelezionato.tributo],
                { event ->

                    if (event?.data?.filtri) {
                        stampaMinutaPerCategoria(event.data.filtri)
                    }
                })

    }

    private def stampaMinutaPerCategoria(def filtri) {

        def reportData = []
        def data = [:]
        def dateFormat = new SimpleDateFormat("dd/MM/yyyy")

        def riga = listaRuoli.find { it.ruolo == ruoloSingoloSelezionato.ruolo && it.selezionabile }

        def rate = Ruolo.get(riga.ruolo)?.rate

        data.testata = [
                "specieRuolo"  : riga.specieRuolo,
                "tipoRuolo"    : riga.tipoRuolo == 1 ? "RUOLO PRINCIPALE" : "RUOLO SUPPLETIVO",
                "anno"         : riga.annoRuolo,
                "scadPrimaRata": riga.scadenzaPrimaRata ? dateFormat.format(riga.scadenzaPrimaRata) : null,
                "rate"         : rate
        ]

        def listaFinale = []
        def listaFormattata = listeDiCaricoRuoliService.getMinutaPerCategoria(riga.ruolo, filtri).groupBy({ it.tributo }, { it.categoria }, { it.tariDescr })

        listaFormattata.each { tributo ->
            tributo.value.each { categoria ->

                def indexCat = 0
                def totImportoCategoria = 0
                def totImportoPvCategoria = 0
                def totImportoPfCategoria = 0

                categoria.value.each { tariffa ->
                    totImportoCategoria += tariffa.value.sum { it.importo }
                    totImportoPvCategoria += tariffa.value.sum { it.importoPv }
                    totImportoPfCategoria += tariffa.value.sum { it.importoPf }
                }

                categoria.value.each { tariffa ->

                    indexCat++
                    def totCategoriaPresente = indexCat == categoria.value.size()

                    listaFinale << ["tariffe"              : tariffa.value,
                                    "tributo"              : tributo.key,
                                    "categoria"            : categoria.key,
                                    "tariffaDesc"          : tariffa.key,
                                    "tributoDesc"          : tariffa.value[0].cotrDescr,
                                    "categoriaDesc"        : tariffa.value[0].cateDescr,
                                    "totCategoriaPresente" : totCategoriaPresente,
                                    "totImportoCategoria"  : totImportoCategoria,
                                    "totImportoPvCategoria": totImportoPvCategoria,
                                    "totImportoPfCategoria": totImportoPfCategoria,
                                    "totImportoTariffa"    : tariffa.value.sum { it.importo },
                                    "totImportoPvTariffa"  : tariffa.value.sum { it.importoPv },
                                    "totImportoPfTariffa"  : tariffa.value.sum { it.importoPf }]
                }
            }
        }


        data.dati = listaFinale.sort { a1, a2 -> a1.tributo <=> a2.tributo ?: a1.categoria <=> a2.categoria ?: a1.tariffaDesc <=> a2.tariffaDesc }

        data.extra = [
                totImportoGenerale  : data.dati.sum { it.totImportoTariffa },
                totImportoPfGenerale: data.dati.sum { it.totImportoPfTariffa },
                totImportoPvGenerale: data.dati.sum { it.totImportoPvTariffa }
        ]

        reportData << data
        String nomeFile = "Minuta_di_Ruolo_Per_Categoria_${riga.annoRuolo}_${riga.ruolo}"

        JasperReportDef reportDef = new JasperReportDef(name: 'minutaPerCategoria.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: reportData
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def minutaPerCategoria = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, minutaPerCategoria.toByteArray())
        Filedownload.save(amedia)
    }

    private def stampaMinutaDiRuolo(def ordinamento, def filtro) {

        def reportData = []
        def data = [:]

        def riga = listaRuoli.find { it.ruolo == ruoloSingoloSelezionato.ruolo && it.selezionabile }

        def rate = Ruolo.get(riga.ruolo)?.rate

        def tributi = listeDiCaricoRuoliService.getTributiMinutaDiRuolo(riga.ruolo)
        def tipoTributo = tipoTributo.toDomain()

        def desTributi = [
                "trib1": tributi.trib1 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib1, tipoTributo).descrizioneRuolo : "",
                "trib2": tributi.trib2 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib2, tipoTributo).descrizioneRuolo : "",
                "trib3": tributi.trib3 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib3, tipoTributo).descrizioneRuolo : "",
                "trib4": tributi.trib4 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib4, tipoTributo).descrizioneRuolo : "",
                "trib5": tributi.trib5 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib5, tipoTributo).descrizioneRuolo : "",
                "trib6": tributi.trib6 != "" ? CodiceTributo.findByIdAndTipoTributo(tributi.trib6, tipoTributo).descrizioneRuolo : ""
        ]

        data.testata = [
                "ordinamento1"    : ordinamento,
                "ordinamento2"    : filtro,
                "specieRuolo"     : riga.specieRuolo,
                "tipoRuolo"       : riga.tipoRuolo == 1 ? "RUOLO PRINCIPALE" : "RUOLO SUPPLETIVO",
                "anno"            : riga.annoRuolo,
                "scadPrimaRata"   : riga.scadenzaPrimaRata,
                "rate"            : rate,
                "tributi"         : tributi,
                "desTributi"      : desTributi,
                "scadPrimaRataStr": riga.scadenzaPrimaRata?.format("dd/MM/yyyy")
        ]

        data.dati = listeDiCaricoRuoliService.getMinutaDiRuolo(riga, ordinamento, filtro)

        reportData << data
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.MINUTA_RUOLO,
                [
                        anno   : riga.annoRuolo,
                        idRuolo: riga.ruolo
                ]
        )

        JasperReportDef reportDef = new JasperReportDef(name: 'minutaDiRuolo.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: reportData
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def minutaDiRuolo = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, minutaDiRuolo.toByteArray())
        Filedownload.save(amedia)
    }

    private def stampaRiepilogoPerCategoria() {

        def reportData = []
        def data = [:]

        def riga = listaRuoli.find { it.ruolo == ruoloSingoloSelezionato.ruolo && it.selezionabile }

        data.testata = [
                "specieRuolo"   : riga.specieRuolo,
                "tipoRuolo"     : riga.tipoRuolo == 1 ? "P - Principale" : "S - Suppletivo",
                "annoRuolo"     : riga.annoRuolo,
                "annoEmissione" : riga.annoEmissione,
                "progrEmissione": riga.progrEmissione,
                "numeroRuolo"   : riga.ruolo
        ]

        def totaleGeneraleImporto = 0
        def totaleGeneraleSuperficie = 0
        def totaleGeneraleQuantita = 0


        // I dati vengono formattati in modo da ottenere una lista di tributi, ognuno contenente le categorie con i propri dettagli
        // oltre a ulteriori parametri descrittivi per il report (come i totali)
        data.dati = listeDiCaricoRuoliService.getRiepilogoPerCategoria(riga)
                .groupBy { it.trib }.collect { tipoTributo ->


            def totaleTributoImporto = 0
            def totaleTributoSuperficie = 0
            def totaleTributoQuantita = 0
            def tribDescr = ""

            tipoTributo.value.each {
                totaleTributoImporto += it.imp ?: 0
                totaleTributoSuperficie += it.cons ?: 0
                totaleTributoQuantita += it.quantita ?: 0
                tribDescr = it.tribdescr
            }

            def tribResult = [
                    "tributo"                : tipoTributo.key,
                    "tribDescr"              : tribDescr,
                    "totaleTributoImporto"   : totaleTributoImporto,
                    "totaleTributoSuperficie": totaleTributoSuperficie,
                    "totaleTributoQuantita"  : totaleTributoQuantita,
                    "categorie"              : tipoTributo.value.groupBy { it.cate }.collect { categoria ->

                        def result = [:]

                        result.dettagli = categoria.value
                        result.categoria = categoria.value.cate[0]
                        result.categoriaDesc = categoria.value.cateDesc[0]

                        result.totaleCategoriaImporto = 0
                        result.totaleCategoriaSuperficie = 0
                        result.totaleCategoriaQuantita = 0

                        categoria.value.each {
                            result.totaleCategoriaImporto += it.imp ?: 0
                            result.totaleCategoriaSuperficie += it.cons ?: 0
                            result.totaleCategoriaQuantita += it.quantita ?: 0
                        }

                        result.stampaTotali = categoria.value.size() > 1

                        return result
                    }
            ]

            return tribResult
        }

        data.dati.each {
            totaleGeneraleImporto += it.totaleTributoImporto
            totaleGeneraleSuperficie += it.totaleTributoSuperficie
            totaleGeneraleQuantita += it.totaleTributoQuantita
        }

        reportData << data
        String nomeFile = "Riepilogo_Per_Categoria_${riga.annoRuolo}_${ruoloSingoloSelezionato.ruolo}"

        JasperReportDef reportDef = new JasperReportDef(name: 'riepilogoPerCategoria.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: reportData
                , parameters: [SUBREPORT_DIR             : servletContext.getRealPath('/reports') + "/",
                               "totaleGeneraleImporto"   : totaleGeneraleImporto,
                               "totaleGeneraleSuperficie": totaleGeneraleSuperficie,
                               "totaleGeneraleQuantita"  : totaleGeneraleQuantita])

        def riepilogoPerCategoria = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, riepilogoPerCategoria.toByteArray())
        Filedownload.save(amedia)
    }

    private def eliminaContribuenteDaRuolo(Long ruolo, String codFiscale) {

        try {
            listeDiCaricoRuoliService.eliminaContribuenteDaRuolo(ruolo, codFiscale)
        }
        catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }
    }

    // Apre dettaglio ruolo
    private def modificaRuolo(def ruolo) {

        if (Ruolo.get(ruolo.ruolo as Long).specieRuolo) {
            // Ruolo Coattivo
            modificaRuoloCoattivo(ruoloSingoloSelezionato)
        } else {
            // Lista di Carico
            modificaListaDiCarico(ruoloSingoloSelezionato)
        }
    }

    // Apre dettaglio ruolo ordinario
    private def modificaListaDiCarico(def ruolo) {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/dettaglioListaDiCarico.zul",
                self,
                [
                        ruolo      : ruolo?.ruolo,
                        tipoTributo: tipoTributo.tipoTributo,
                        modifica   : modifica
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    onRicaricaLista()
                }
            }
        }
        w.doModal()
    }

// Apre dettaglio ruolo coattivo
    private def modificaRuoloCoattivo(def ruolo) {

        Window w = Executions.createComponents(
                "/ufficiotributi/imposte/dettaglioRuoloCoattivo.zul",
                self,
                [
                        ruolo      : ruolo?.ruolo,
                        tipoTributo: tipoTributo.tipoTributo,
                        modifica   : modifica
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    onRicaricaLista()
                }
            }
        }
        w.doModal()
    }

    private resetSelezioneRuoli() {
        ruoliSelezionati.each { it.value = false }
        selezioneRuoliAttiva = selezionePresente(ruoliSelezionati)
        selected = ruoloSelezionato(ruoliSelezionati)
        BindUtils.postNotifyChange(null, null, this, "ruoliSelezionati")
        BindUtils.postNotifyChange(null, null, this, "selected")
        BindUtils.postNotifyChange(null, null, this, "selezioneRuoliAttiva")
    }

    private selectedUtenzeReset() {

        selectedUtenze = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedUtenze")
        selectedAnyUtenzaRefresh()
    }

    private selectedAnyUtenzaRefresh() {

        selectedAnyUtenza = (selectedUtenze.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyUtenza")
    }

    private def verificaCampiFiltrantiUtenze() {

        filtroAttivoUtenze = parRicerca.isDirtyUtenze()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoUtenze")
    }

    private def verificaCampiFiltrantiPratiche() {
        filtroAttivoPratiche = parRicerca.isDirtyPratiche()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoPratiche")
    }

    private def verificaCampiFiltrantiEccedenze() {

        filtroAttivoEccedenze = parRicerca.isDirtyEccedenze()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoEccedenze")
    }

    private void ricalcolaTotaliUtenze() {

        def parametriRicerca = completaParametriUtenze()
        def caricoUtenze = listeDiCaricoRuoliService.getUtenzeRuolo(parametriRicerca)
        def listaPerTotali = caricoUtenze.records

        totaliUtenze.importo = listaPerTotali.sum { it.importo } ?: 0
        totaliUtenze.sgravio = listaPerTotali.sum { it.sgravio } ?: 0
        totaliUtenze.imposta = listaPerTotali.sum { it.imposta } ?: 0
        //	totaliUtenze.addMaggEca = listaPerTotali.sum { it.addMaggEca } ?: 0
        totaliUtenze.addProv = listaPerTotali.sum { it.addProv } ?: 0
        //	totaliUtenze.iva = listaPerTotali.sum { it.iva } ?: 0
        totaliUtenze.importoPF = listaPerTotali.sum { it.importoPF } ?: 0
        totaliUtenze.importoPV = listaPerTotali.sum { it.importoPV } ?: 0
        //	totaliUtenze.maggiorazioneTares = listaPerTotali.sum { it.maggiorazioneTares } ?: 0
        totaliUtenze.utenze = caricoUtenze.totalCount
        totaliUtenze.compensazione = listaPerTotali.sum { it.compensazione } ?: 0

        def contribuentiList = []
        listaPerTotali.each() { c -> (contribuentiList << c.ni) }
        def contribuentiUnique = contribuentiList.unique(false)
        totaliUtenze.contribuenti = contribuentiUnique.size()

        BindUtils.postNotifyChange(null, null, this, "totaliUtenze")

        pagingUtenze.activePage = 0
        pagingUtenze.totalSize = caricoUtenze.totalCount

        BindUtils.postNotifyChange(null, null, this, "pagingUtenze")
    }

    private void ricalcolaTotaliEccedenze() {

        def parametriRicerca = completaParametriEccedenze()
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca)
        def listaPerTotali = caricoEccedenze.records

        totaliEccedenze.importoRuolo = listaPerTotali.sum { it.importoRuolo } ?: 0
        totaliEccedenze.imposta = listaPerTotali.sum { it.imposta } ?: 0
        totaliEccedenze.addProv = listaPerTotali.sum { it.addProv } ?: 0
        totaliEccedenze.costoSvuotamento = listaPerTotali.sum { it.costoSvuotamento } ?: 0
        totaliEccedenze.costoSuperficie = listaPerTotali.sum { it.costoSuperficie ?: 0 } ?: 0

        def contribuentiList = []
        listaPerTotali.each() { c -> (contribuentiList << c.ni) }
        def contribuentiUnique = contribuentiList.unique(false)
        totaliEccedenze.contribuenti = contribuentiUnique.size()

        BindUtils.postNotifyChange(null, null, this, "totaliEccedenze")

        pagingEccedenze.activePage = 0
        pagingEccedenze.totalSize = caricoEccedenze.totalCount

        BindUtils.postNotifyChange(null, null, this, "pagingEccedenze")
    }

    private void ricalcolaTotali() {

        DecimalFormat importoFmt = new DecimalFormat("#,##0.00")

        def parametriRicerca = completaParametriList()
        def caricoRuoli = listeDiCaricoRuoliService.getListaDiCaricoRuoli(parametriRicerca)
        def listaPerTotali = caricoRuoli.records

        svuotaCompensazioniRidondanti(listaPerTotali)

        totaliList.importo = listaPerTotali.sum { it.importo ?:0 } ?: 0
        totaliList.sgravio = listaPerTotali.sum { it.sgravio ?:0 } ?: 0
        totaliList.imposta = listaPerTotali.sum { it.imposta ?:0 } ?: 0
        totaliList.eccedenze = listaPerTotali.sum { it.eccedenze ?:0 } ?: 0
        totaliList.addECA = listaPerTotali.sum { it.addMaggEca ?:0 } ?: 0
        totaliList.addProv = listaPerTotali.sum { it.addPro ?:0 } ?: 0
        totaliList.addProvImp = listaPerTotali.sum { it.addProImp ?:0 } ?: 0
        totaliList.addProvEcc = listaPerTotali.sum { it.addProEcc ?:0 } ?: 0
        totaliList.iva = listaPerTotali.sum { it.iva ?:0 } ?: 0
        totaliList.maggTARES = listaPerTotali.sum { it.maggTares ?:0 } ?: 0
        totaliList.compensazione = listaPerTotali.sum { it.compensazione ?:0 } ?: 0

        def anniErroreCaTa = listaPerTotali.findAll { it.flagErroreCaTa == 'S' } ?.collect { it.annoRuolo }
        anniErroreCaTa = anniErroreCaTa.stream().distinct().collect()
        anniErroreCaTa = anniErroreCaTa.sort { a, b -> a <=> b}

        if(anniErroreCaTa.size() > 0) {
            def anni = anniErroreCaTa.join(', ')
            Clients.showNotification("Configurare la tabella dei carichi TARSU per ${anni}." , 
                                Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 5000, true)
        }

        def tariffaPuntuale = listaPerTotali.count { it.flagTariffaPuntuale  == 'S' }

        if(tariffaPuntuale > 0) {
            totaliList.addProvTooltip = "Da Imposta: " + importoFmt.format(totaliList.addProvImp) + "\n" + 
                                                "Da Eccedenze: " + importoFmt.format(totaliList.addProvEcc)
        }
        else {
            totaliList.addProvTooltip = null
        }

        def listaInviati = listaPerTotali.findAll { it.invioConsorzio != null }
        totaliList.inviato = listaInviati.sum { it.importo ?:0 } ?: 0

        def numRuoliTarPuntuale = listaPerTotali.findAll { it.flagTariffaPuntuale == 'S' } ?.size();
        ruoliTarPuntuale = (numRuoliTarPuntuale ?: 0) > 0

        BindUtils.postNotifyChange(null, null, this, "totaliList")

        pagingList.activePage = 0
        pagingList.totalSize = caricoRuoli.totalCount

        BindUtils.postNotifyChange(null, null, this, "pagingList")
    }

    private void caricaListaRuoli() {

        selected = null
        ruoloSingoloSelezionato = null

        def parametriRicerca = completaParametriList()
        def caricoRuoli = listeDiCaricoRuoliService.getListaDiCaricoRuoli(parametriRicerca, pagingList.pageSize, pagingList.activePage)
        listaRuoli = caricoRuoli.records

        svuotaDatiRidondanti(listaRuoli)

        BindUtils.postNotifyChange(null, null, this, "ruoliTarPuntuale")
        BindUtils.postNotifyChange(null, null, this, "selected")
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
        BindUtils.postNotifyChange(null, null, this, "ruoloSingoloSelezionato")
        
        try {
            self.getFellow("listBoxRuoli").invalidate()
        } catch (Exception e) {
            log.error(e)
        }
    }

    private def apriFiltriLista(boolean ricercaSempre) {

        parRicerca.tipoTributo = tipoTributo?.tipoTributo

        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoliRicerca.zul", self, [parRicerca: parRicerca])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicerca = event.data.parRicerca
                    tributiSession.filtroRicercaListeDiCaricoRuoli = parRicerca
                    BindUtils.postNotifyChange(null, null, this, "parRicerca")

                    if (!ricercaSempre) {
                        onRicaricaLista()
                    }
                }
            }

            if (ricercaSempre) {
                onRicaricaLista()
            }

            verificaCampiFiltrantiList()

            selected = null
            BindUtils.postNotifyChange(null, null, this, "selected")

        }
        w.doModal()
    }

    // Verifica se conflitto di selezione -> return true : conflitto, false tutto ok
    private Boolean isSelezioneValidaRuoli() {

        String message
        Boolean result = false

        def selezione = ruoliSelezionati.findAll { it.value }.collect { it.key }

        if (!listeDiCaricoRuoliService.verificaSelezioneAnnualitaRuoli(selezione)) {

            message = "Non e possibile selezionare ruoli di Annualita' diverse"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            result = true
        } else if (!selezione.empty) {

            if (!listeDiCaricoRuoliService.verificaSelezioneMultiplaRuoli(selezione)) {

                message = "Non e possibile selezionare ruoli Totali con ruoli di Acconto e Saldo"
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                result = true
            } else {

                if (!listeDiCaricoRuoliService.verificaSelezioneSpecieRuoli(selezione)) {

                    message = "Non e possibile selezionare ruoli di Specie diverse"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                    result = true
                } else {

                    if (!Ruolo.get(selezione[0]).specieRuolo) {

                        String annualita = listeDiCaricoRuoliService.verificaSelezioneRuoliTotali(this.tipoTributo.tipoTributo, selezione)

                        if (!annualita.isEmpty()) {

                            message = "Esistono ulteriori ruoli Totali per l'anno ${annualita} non selezionati, potrebbero non venire visualizzati alcuni contribuenti"
                            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                        }
                    }
                }
            }
        }

        return result
    }

    private def completaParametriList() {

        def parametriRicerca = [
                daAnno          : parRicerca?.daAnno,
                aAnno           : parRicerca?.aAnno,
                daAnnoEmissione : parRicerca?.daAnnoEmissione,
                aAnnoEmissione  : parRicerca?.aAnnoEmissione,
                daProgEmissione : parRicerca?.daProgEmissione,
                aProgEmissione  : parRicerca?.aProgEmissione,
                daDataEmissione : parRicerca?.daDataEmissione,
                aDataEmissione  : parRicerca?.aDataEmissione,
                daDataInvio     : parRicerca?.daDataInvio,
                aDataInvio      : parRicerca?.aDataInvio,
                daNumeroRuolo   : parRicerca?.daNumeroRuolo,
                aNumeroRuolo    : parRicerca?.aNumeroRuolo,
                tipoRuolo       : parRicerca?.tipoRuolo?.codice,
                specieRuolo     : parRicerca?.specieRuolo?.codice,
                tipoEmissione   : parRicerca?.tipoEmissione?.codice,
                tipoTributo     : tipoTributo.tipoTributo,
                codiceTributo   : parRicerca?.codiceTributo,
                annoList        : anno,
                ruoliSelezionati: visualizzaRuoliSelezionati ?
                        ruoliSelezionati.findAll { it.value } :
                        null
        ]
        return parametriRicerca
    }

    private def verificaCampiFiltrantiList() {

        filtroAttivoList = parRicerca.isDirty()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoList")
    }

//  Svuota l'importo di compensazione nel caso di codici tributi diversi per lo stesso ruolo
    private void svuotaCompensazioniRidondanti(def listaRuoli) {

        int numRuoli = -1
        listaRuoli.each { numRuoli++ }

        for (int outer = 0; outer < numRuoli; outer++) {

            def outerRuolo = listaRuoli.get(outer)

            for (int inner = outer + 1; inner <= numRuoli; inner++) {

                def innerRuolo = listaRuoli.get(inner)
                if (innerRuolo.ruolo == outerRuolo.ruolo) {

                    innerRuolo.compensazione = 0.0
                } else {
                    break
                }
            }
        }
    }

// Svuota dati ridondanti nel caso di codici tributi diversi per lo stesso ruolo
    private void svuotaDatiRidondanti(def listaRuoli) {

        int numRuoli = -1
        listaRuoli.each {
            it.ruoloDescr = it.ruolo
            numRuoli++
        }

        for (int outer = 0; outer < numRuoli; outer++) {

            def outerRuolo = listaRuoli.get(outer)

            for (int inner = outer + 1; inner <= numRuoli; inner++) {

                def innerRuolo = listaRuoli.get(inner)
                if (innerRuolo.ruolo == outerRuolo.ruolo) {
                    innerRuolo.tipoRuoloDescr = ""
                    innerRuolo.annoRuolo = null
                    innerRuolo.annoEmissione = null
                    innerRuolo.progrEmissione = null
                    innerRuolo.dataEmissione = null
                    innerRuolo.invioConsorzio = null
                    innerRuolo.ruoloDescr = null
                    innerRuolo.specieRuolo = null
                    innerRuolo.tipoCalcoloDescr = ""
                    innerRuolo.tipoEmissioneDescr = ""
                    innerRuolo.compensazione = null
                    innerRuolo.selezionabile = false
                } else {
                    break
                }
            }
        }
    }

    private void ricalcolaTotaliDettagli() {

        DecimalFormat importoFmt = new DecimalFormat("#,##0.00")

        def parametriRicerca = completaParametriDetails()
        def caricoDettagli = listeDiCaricoRuoliService.getContribuentiRuolo(parametriRicerca)
        def listaPerTotali = caricoDettagli.records

        totaliDettagli.importo = listaPerTotali.sum { it.importo ?: 0 } ?: 0
        totaliDettagli.sgravio = listaPerTotali.sum { it.sgravio ?: 0 } ?: 0
        totaliDettagli.imposta = listaPerTotali.sum { it.imposta ?: 0 } ?: 0
        totaliDettagli.eccedenze = listaPerTotali.sum { it.eccedenze ?: 0 } ?: 0
        totaliDettagli.versato = listaPerTotali.sum { it.versato ?: 0 } ?: 0
        totaliDettagli.dovuto = listaPerTotali.sum { it.dovuto ?: 0 } ?: 0
        totaliDettagli.addMaggEca = listaPerTotali.sum { it.addMaggEca ?: 0 } ?: 0
        totaliDettagli.addProv = listaPerTotali.sum { it.addProv ?: 0 } ?: 0
        totaliDettagli.addProvImp = listaPerTotali.sum { it.addProvImp ?:0 } ?: 0
        totaliDettagli.addProvEcc = listaPerTotali.sum { it.addProvEcc ?:0 } ?: 0
        totaliDettagli.iva = listaPerTotali.sum { it.iva ?: 0 } ?: 0
        totaliDettagli.importoPF = listaPerTotali.sum { it.importoPF ?: 0 } ?: 0
        totaliDettagli.importoPV = listaPerTotali.sum { it.importoPV ?: 0 } ?: 0
        totaliDettagli.maggiorazioneTares = listaPerTotali.sum { it.maggiorazioneTares ?: 0 } ?: 0

        totaliDettagli.compensazione = listaPerTotali.sum { it.compensazione ?: 0 } ?: 0
        totaliDettagli.versatoS = listaPerTotali.sum { it.versatoS ?: 0 } ?: 0
        totaliDettagli.versatoC = listaPerTotali.sum { it.versatoC ?: 0 } ?: 0
        totaliDettagli.contribuenti = caricoDettagli.totalCount
        totaliDettagli.utenze = listaPerTotali.sum { it.utenze ?: 0 } ?: 0
        totaliDettagli.compensazione = listaPerTotali.sum { it.compensazione ?: 0 } ?: 0

        def tariffaPuntuale = listaPerTotali.count { it.flagTariffaPuntuale  == 'S' }

        if(tariffaPuntuale > 0) {
            totaliDettagli.addProvTooltip = "Da Imposta: " + importoFmt.format(totaliDettagli.addProvImp) + "\n" + 
                                                "Da Eccedenze: " + importoFmt.format(totaliDettagli.addProvEcc)
        }
        else {
            totaliDettagli.addProvTooltip = null
        }

        BindUtils.postNotifyChange(null, null, this, "totaliDettagli")

        pagingDetails.activePage = 0
        pagingDetails.totalSize = caricoDettagli.totalCount

        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
    }

    private def caricaListaDettagli() {

        if (!selectedAnyDetails) {
            selectedDetails = [:]
        }

        def parametriRicerca = completaParametriDetails()
        def caricoDettagli = listeDiCaricoRuoliService.getContribuentiRuolo(parametriRicerca, pagingDetails.pageSize, pagingDetails.activePage)
        listaDetailsRuolo = caricoDettagli.records

        BindUtils.postNotifyChange(null, null, this, "selectedDetails")
        BindUtils.postNotifyChange(null, null, this, "listaDetailsRuolo")
    }

    private def completaParametriDetails() {

        parRicerca.preparaRicercaDetails(parRicercaDetails)

        def filtroRuoli = determinaFiltriRuoli()

        def deceduti = parRicercaDetails.listDeceduti
        def versatoVersusDovuto = parRicercaDetails.versatoVersusDovuto

        def parametriRicerca = [
                ruoli              : filtroRuoli.ruoli,
                //		tributo            : filtroRuoli.codTributo,			// Non utilizzato per i contribuenti
                cognome            : parRicercaDetails?.cognome,
                nome               : parRicercaDetails?.nome,
                codFiscale         : parRicercaDetails?.codFiscale,
                listDeceduti       : Integer.parseInt(deceduti),
                hasVersamenti      : parRicercaDetails?.hasVersamenti?.codice ?: -1,
                hasPEC             : parRicercaDetails?.hasPEC?.codice ?: -1,
                versatoVersusDovuto: Integer.parseInt(versatoVersusDovuto),
                soglia             : parRicercaDetails.soglia
        ]

        return parametriRicerca
    }

    private def onSvuotaTuttoDetails() {
        selectedAnyDetails = false
        selectedDetail = null
        listaDetailsRuolo = []

        pagingDetails.activePage = 0
        pagingDetails.totalSize = 0

        BindUtils.postNotifyChange(null, null, this, "selectedAnyDetails")
        BindUtils.postNotifyChange(null, null, this, "selectedDetail")
        BindUtils.postNotifyChange(null, null, this, "listaDetailsRuolo")

        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoDetails")
    }

    private def verificaCampiFiltrantiDetails() {

        filtroAttivoDetails = parRicerca.isDirtyDetails()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoDetails")
    }

    private caricaListaUtenze() {

        if (!selectedAnyUtenza) {
            selectedUtenza = null
        }

        def parametriRicerca = completaParametriUtenze()
        def caricoUtenze = listeDiCaricoRuoliService.getUtenzeRuolo(parametriRicerca, pagingUtenze.pageSize, pagingUtenze.activePage)
        listaUtenzeRuolo = caricoUtenze.records

        BindUtils.postNotifyChange(null, null, this, "selectedUtenze")
        BindUtils.postNotifyChange(null, null, this, "listaUtenzeRuolo")
    }

    private caricaListaPratiche() {

        colonnePraticheConSanzioni = []

        // Le pratiche vengono visualizzate solo per i ruoli coattivi
        if (ruoloSingoloSelezionato == null || !Ruolo.get(ruoloSingoloSelezionato.ruolo).specieRuolo) {
            praticaRuoloSelezionata = null
            listaPraticheRuolo = []
            BindUtils.postNotifyChange(null, null, this, "listaPraticheRuolo")
            BindUtils.postNotifyChange(null, null, this, "praticaRuoloSelezionata")
        } else {
            def parametriRicerca = completaParametriPratiche()
            def lista = listeDiCaricoRuoliService.getPraticheRuolo(parametriRicerca)
            listaPraticheRuolo = lista.pratiche
            colonnePraticheConSanzioni = colonnePraticheBase + lista.colonneSanzioni
            if (!selected) {
                colonnePraticheConSanzioni = colonnePraticheConSanzioni + colonnePraticheExtra
            }
            BindUtils.postNotifyChange(null, null, this, "listaPraticheRuolo")
            BindUtils.postNotifyChange(null, null, this, "colonnePraticheConSanzioni")
        }
    }

    private completaParametriUtenze() {

        parRicerca.preparaRicercaUtenze(parRicercaUtenze)

        def filtroRuoli = determinaFiltriRuoli()

        def deceduti = parRicercaUtenze.listDeceduti
        def versatoVersusDovuto = parRicercaUtenze.versatoVersusDovuto

        def parametriRicerca = [
                ruoli              : filtroRuoli.ruoli,
                tributo            : filtroRuoli.codTributo,
                cognome            : parRicercaUtenze?.cognome,
                nome               : parRicercaUtenze?.nome,
                codFiscale         : parRicercaUtenze?.codFiscale,
                listDeceduti       : Integer.parseInt(deceduti),
                versatoVersusDovuto: Integer.parseInt(versatoVersusDovuto),
                hasPEC             : parRicercaUtenze?.hasPEC?.codice ?: -1
        ]

        return parametriRicerca
    }

    private completaParametriPratiche() {

        parRicerca.preparaRicercaPratiche(parRicercaPratiche)

        def filtroRuoli = determinaFiltriRuoli()

        def parametriRicerca = [
                ruoli          : filtroRuoli.ruoli,
                tipoTributo    : tipoTributo.tipoTributo,
                anno           : filtroRuoli.annoRuoli,
                cognome        : parRicercaPratiche?.cognome,
                nome           : parRicercaPratiche?.nome,
                codFiscale     : parRicercaPratiche?.codFiscale,
                hasPEC         : parRicercaPratiche?.hasPEC?.codice ?: -1,
                hasVersamenti  : parRicercaPratiche?.hasVersamenti?.codice ?: -1,
                tipoPratica    : parRicercaPratiche?.tipoPratica ?: "T",
                numeroDa       : parRicercaPratiche?.numeroDa,
                numeroA        : parRicercaPratiche?.numeroA,
                dataNotificaDa : parRicercaPratiche?.dataNotificaDa,
                dataNotificaA  : parRicercaPratiche?.dataNotificaA,
                dataEmissioneDa: parRicercaPratiche?.dataEmissioneDa,
                dataEmissioneA : parRicercaPratiche?.dataEmissioneA
        ]

        return parametriRicerca
    }

    private onSvuotaTuttoUtenze() {

        selectedAnyUtenza = false
        selectedUtenza = null
        listaUtenzeRuolo = []

        pagingUtenze.activePage = 0
        pagingUtenze.totalSize = 0

        BindUtils.postNotifyChange(null, null, this, "selectedAnyUtenza")
        BindUtils.postNotifyChange(null, null, this, "selectedUtenza")
        BindUtils.postNotifyChange(null, null, this, "listaUtenzeRuolo")

        BindUtils.postNotifyChange(null, null, this, "pagingUtenze")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoUtenze")
    }

    private onSvuotaTuttoPratiche() {

        listaPraticheRuolo = []
        praticaRuoloSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "praticaRuoloSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaPraticheRuolo")
    }

    private def selectedDetailsReset() {

        selectedDetails = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedDetails")
        selectedAnyDetailsRefresh()
    }

    private def selectedAnyDetailsRefresh() {

        def selectedDetailsValid = selectedDetails.findAll { k, v -> v }
        def selectedDetailsCount = selectedDetailsValid.size()

        if (selectedDetailsCount == 1) {
            selectedDetail = selectedDetails.find { k, v -> v }.key
        } else {
            selectedDetail = null
        }

        selectedAnyDetails = (selectedDetailsCount != 0)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyDetails")
        BindUtils.postNotifyChange(null, null, this, "selectedDetail")
    }

    private caricaListaEccedenze() {

        def parametriRicerca = completaParametriEccedenze()
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca, pagingEccedenze.pageSize, pagingEccedenze.activePage)
        listaEccedenzeRuolo = caricoEccedenze.records

        selectedEccedenza = null

        BindUtils.postNotifyChange(null, null, this, "selectedEccedenza")
        BindUtils.postNotifyChange(null, null, this, "listaEccedenzeRuolo")
    }

    private completaParametriEccedenze() {

        parRicerca.preparaRicercaEccedenze(parRicercaEccedenze)

        def filtroRuoli = determinaFiltriRuoli()

        def parametriRicerca = [
                ruoli          : filtroRuoli.ruoli,
                tributo        : filtroRuoli.codTributo,
                cognome        : parRicercaEccedenze?.cognome,
                nome           : parRicercaEccedenze?.nome,
                codFiscale     : parRicercaEccedenze?.codFiscale
        ]

        return parametriRicerca
    }

    // Determina filtri base ruoli
    def determinaFiltriRuoli() {

        Long primoRuoloSelezionato
        def ruoli = []
        def codTributo = null
        Short annoRuoli = null

        def ruoliList = ruoliSelezionati.findAll { it.value }
        if (ruoliList.isEmpty()) {
            primoRuoloSelezionato = -1
            ruoli = [-1]
            codTributo = null
        } else {
            primoRuoloSelezionato = ruoliSelezionati.find { it.value }?.key
            ruoli = ruoliList.collect { it.key }
            codTributo = null
        }
        Ruolo ruolo = Ruolo.get(primoRuoloSelezionato)
        annoRuoli = (ruolo) ? ruolo.annoRuolo : -1

        return [ruoli: ruoli, codTributo: codTributo, annoRuoli: annoRuoli]
    }

    private gestioneTabs() {

        def primoRuoloSelezionato = ruoliSelezionati.find { it.value }?.key
        def ruoloId = primoRuoloSelezionato ? primoRuoloSelezionato : ruoloSingoloSelezionato ? ruoloSingoloSelezionato.ruolo : null
        Ruolo ruolo = ruoloId ? Ruolo.get(ruoloId) : null

        if (ruolo && ultimaSpecieSelezionata != (ruolo.specieRuolo ? 1 : 0)) {

            selectedTab = 0
            dettagliTabs.utenze = ruolo && !ruolo.specieRuolo
            dettagliTabs.pratiche = ruolo && ruolo.specieRuolo
            ultimaSpecieSelezionata = ruolo.specieRuolo
            onSelectTabs()
        } else {
            onSelectTabs()
        }

        BindUtils.postNotifyChange(null, null, this, "dettagliTabs")
        BindUtils.postNotifyChange(null, null, this, "selectedTab")
    }

    private verificaCompetenze() {
        cbTributiInScrittura = tributiSession.competenze.findAll { it.tipoAbilitazione == 'A' }
                .collect { [(it.oggetto): true] }.collectEntries()
    }
}
