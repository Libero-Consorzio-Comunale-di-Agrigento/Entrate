package pratiche.violazioni

import commons.OrdinamentoMutiColonnaViewModel
import document.FileNameGenerator
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.datiesterni.anagrafetributaria.AllineamentoAnagrafeTributariaService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.TipoAttoDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import it.finmatica.tr4.violazioni.FiltroRicercaViolazioni
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.OpenEvent
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.text.SimpleDateFormat

class ElencoViolazioniViewModel extends OrdinamentoMutiColonnaViewModel {

    @Wire("#includeViolazioniImu, #listBoxViolazioni")
    def listBoxViolazioni

    private static Log log = LogFactory.getLog(ElencoViolazioniViewModel)

    private final MAX_CF_ANAGR_TRIB = 10000

    Window self
    ServletContext servletContext

    // services
    TributiSession tributiSession
    CompetenzeService competenzeService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    ModelliService modelliService
    F24Service f24Service

    JasperService jasperService
    Ad4EnteService ad4EnteService
    RateazioneService rateazioneService
    DocumentaleService documentaleService
    AllineamentoAnagrafeTributariaService allineamentoAnagrafeTributariaService
    IntegrazioneDePagService integrazioneDePagService
    CommonService commonService
    ContribuentiService contribuentiService
    ComunicazioniService comunicazioniService

    def tipoTributo
    def tipoTributoAttuale
    def tipoPratica

    // Paginazione
    def violazioneSelezionata
    def violazioneSelezionataPrecedente = [:]
    def violazioneSelezionataPrecedenteId

    def listaViolazioni
    def listaViolazioniPaginazione = [
            max       : 30,
            offset    : 0,
            activePage: 0
    ]

    // Filtri
    FiltroRicercaViolazioni filtri = null
    Boolean filtroAttivo = false

    def modificaPraticaInline = false
    def listaTipiAtto
    def abilitaSelezioneMultipla = false
    def abilitaStampa = false
    def abilitaPassaggioAPagoPa = false
    def abilitaAnnullaDovutoPagoPa = false
    def praticaOpenable = false

    Map caricaPannello = [
            "ICI"  : [
                    "L": ["U": [zul       : "/pratiche/violazioni/liquidazioneImu.zul",
                                lettura   : false,
                                situazione: "liquidazione"],
                          "R": [zul       : "/pratiche/violazioni/liquidazioneImu.zul",
                                lettura   : false,
                                situazione: "liquidazione"]
                    ],
                    "A": ["T"  : [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : false
                                  , situazione: "accTotImu"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManuali.zul"
                                  , lettura   : false
                                  , situazione: "accManImu"]
                    ]
            ],
            "TASI" : [
                    "L": ["U": [zul       : "/pratiche/violazioni/liquidazioneImu.zul",
                                lettura   : false,
                                situazione: "liquidazione"],
                          "R": [zul       : "/pratiche/violazioni/liquidazioneImu.zul",
                                lettura   : false,
                                situazione: "liquidazione"]
                    ],
                    "A": ["T"  : [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : false
                                  , situazione: "accTotImu"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : false
                                  , situazione: "accManImu"]
                    ]
            ],
            "TARSU": [
                    "A": ["A"  : [zul         : "pratiche/violazioni/accertamentoAutomaticoTari.zul"
                                  , lettura   : false
                                  , situazione: "accAutoTari"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManuali.zul"
                                  , lettura   : false
                                  , situazione: "accManTari"]
                          , "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : false
                                  , situazione: "accTotTari"]
                    ],
                    "S": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTari.zul"
                                , lettura   : false
                                , situazione: "solAutoTari"]
                    ]
            ],
            "ICP"  : [
                    "A": ["A"  : [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                  , lettura   : false
                                  , situazione: "accAutoTribMin"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accManTribMin"]
                          , "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accTotTribMin"]
                    ]
            ],
            "TOSAP": [
                    "A": ["A"  : [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                  , lettura   : false
                                  , situazione: "accAutoTribMin"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accManTribMin"]
                          , "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accTotTribMin"]
                    ]
            ],
            "CUNI" : [
                    "A": ["A"  : [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                  , lettura   : false
                                  , situazione: "accAutoTribMin"]
                          , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accManTribMin"]
                          , "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                  , lettura   : true
                                  , situazione: "accTotTribMin"]
                    ],
                    "S": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                , lettura   : false
                                , situazione: "solAutoTribMin"]
                    ]
            ]
    ]

    def praticheSelezionate = [:]
    def praticheCF = [:]
    def praticheObjectSelezionate = [:]
    def selezionePresente = false
    def nuovaPraticaVisible = false

    // Competenze
    def cbTributiAbilitati = [:]
    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true
    ]

    def dePagAbilitato = false

    def tipoAbilitazione = "A"
    Boolean lettura = true

    Boolean elencoViolazioniOpened = true

    @Deprecated
    def sizeElencoViolazioni

    Boolean listaStatiAttiva = false
    def listaStati = []
    def statoSelezionato = null
    def statiSelezionati = [:]
    def statiSelezionatiAll = [:]
    Boolean anyStatoChecked = false
    Boolean allStatoChecked = true

    String colonnaImportoTitolo
    String colonnaImportoTooltip
    String colonnaImportoRidTitolo
    String colonnaImportoRidTooltip

    def disabilitaDataNotificaSuRateazione = [:]

    @Init(superclass = true)
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("tipoPratica") String tp) {

        this.self = w

        this.sizeElencoViolazioni = "60%"

        tipoTributo = tt
        tipoTributoAttuale = TipoTributo.findByTipoTributo(tt)?.tipoTributoAttuale
        tipoPratica = tp ?: '*' // Tutte le pratiche, gestione rateazioni.

        // TODO - Tipo Atto Rateizzato da gestire con la #62142.
        if (tipoPratica == 'S') {
            listaTipiAtto = TipoAtto.list().sort { it.tipoAtto }
                    .findAll { it.tipoAtto != 90 }
        } else {

            listaTipiAtto = TipoAtto.list().sort { it.tipoAtto }
        }

        listaTipiAtto = [new TipoAtto(tipoAtto: null, descrizione: "Nessuno")] + listaTipiAtto

        abilitaSelezioneMultipla = true

        campiOrdinamento = [
                'contribuente'     : [verso: VERSO_ASC, posizione: 0],
                'codFiscale'       : [verso: VERSO_ASC, posizione: 1],
                'anno'             : [verso: VERSO_ASC, posizione: 2],
                'statoAccertamento': [verso: VERSO_ASC, posizione: 3]
        ]

        campiCssOrdinamento = [
                'contribuente'     : CSS_ASC,
                'codFiscale'       : CSS_ASC,
                'anno'             : CSS_ASC,
                'statoAccertamento': CSS_ASC
        ]

        verificaCompetenze()
        tipoAbilitazione = competenzeService.tipoAbilitazioneUtente(tipoTributo)
        lettura = tipoAbilitazione != 'A'

        caricaPannello."${tipoTributo}"."${tipoPratica}".each { k, v ->
            if (v.lettura == false) {
                v.lettura = this.lettura
            }
        }

        filtri = tributiSession.filtroRicercaViolazioni

        Boolean ignoraMascheraRicerca = false

        if (!filtri) {
            filtri = new FiltroRicercaViolazioni()
            filtri.tipoPraticaIniziale = ""
            tributiSession.filtroRicercaViolazioni = filtri
        }

        if (filtri.tipoPraticaIniziale != tipoPratica) {
            filtri.tipoPraticaIniziale = tipoPratica
            ignoraMascheraRicerca = true
        }

        TipoAttoDTO tipoAttoRateizzato = OggettiCache.TIPI_ATTO.valore.find { it.tipoAtto == 90 }

        if (tipoPratica == '*') {
            filtri.resetRateizzate()
            filtri.tipiAttoSelezionati = [tipoAttoRateizzato]
        } else {
            if (filtri.tipiAttoSelezionati) {
                if ((filtri.tipiAttoSelezionati.size() == 1) && (filtri.tipiAttoSelezionati[0] == tipoAttoRateizzato)) {
                    filtri.resetRateizzate()
                    filtri.tipiAttoSelezionati = []
                }
            }
        }

        listaStatiAttiva = tipoPratica in [
                TipoPratica.A.tipoPratica,
                TipoPratica.L.tipoPratica,
                TipoPratica.S.tipoPratica,
                '*'
        ]

        filtroAttivo = filtri.filtroAttivoPerTipoPratica(tipoPratica)

        if (listaStatiAttiva) {

            colonnaImportoRidTitolo = "Imp.Ridotto"
            colonnaImportoRidTooltip = "Importo Ridotto"

            switch (tipoPratica) {
                default:
                    colonnaImportoTitolo = "Importo"
                    colonnaImportoTooltip = "Importo"
                    break
                case TipoPratica.A.tipoPratica:
                    if (tipoTributo in ['TARSU']) {
                        colonnaImportoTitolo = "Imp.Lordo"
                        colonnaImportoTooltip = "Importo Lordo"
                        colonnaImportoRidTitolo = "Rid.Lordo"
                        colonnaImportoRidTooltip = "Ridotto Lordo"
                    } else {
                        colonnaImportoTitolo = "Imp.Accertata"
                        colonnaImportoTooltip = "Imposta Accertata"
                    }
                    break
                case TipoPratica.L.tipoPratica:
                    colonnaImportoTitolo = "Imp.Liquidato"
                    colonnaImportoTooltip = "Importo Liquidato"
                    break
                case TipoPratica.S.tipoPratica:
                    if (tipoTributo in ['TARSU']) {
                        colonnaImportoTitolo = "Imp.Lordo"
                        colonnaImportoTooltip = "Importo Lordo"
                    } else {
                        colonnaImportoTitolo = "--Non Visualizzato--"
                        colonnaImportoTooltip = "--Non Visualizzato--"
                    }
                    break
                case '*':
                    colonnaImportoTitolo = "Imp.Pratica"
                    colonnaImportoTooltip = "Importo Pratica"
                    break
            }

            listaViolazioniPaginazione.max = 20
            BindUtils.postNotifyChange(null, null, this, "listaViolazioniPaginazione")

            ripristinaFiltriListaStati()
            if (filtroAttivo) {
                caricaListaStati()
                caricaViolazioni()
            } else {
                if (!ignoraMascheraRicerca) {
                    openCloseFiltri()
                }
            }
        } else {
            if (filtroAttivo) {
                caricaViolazioni()
            } else {
                openCloseFiltri()
            }
        }

        nuovaPraticaVisible = tipoTributo in ['TARSU', 'ICI'] && tipoPratica in [TipoPratica.A.tipoPratica]

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        BindUtils.postNotifyChange(null, null, this, "abilitaSelezioneMultipla")
    }

    @Command
    def onCambiaTipoAtto() {
        disabilitaDataNotificaSuRateazione[violazioneSelezionata.id] = violazioneSelezionata.dataNotificaDate &&
                (violazioneSelezionata.tipoAtto?.tipoAtto == 90 || rateazioneService.praticaRateizzata((violazioneSelezionata.id ?: 0) as Long))

        BindUtils.postNotifyChange(null, null, this, "disabilitaDataNotificaSuRateazione")
    }

    @Command
    openCloseFiltri() {

        commonService.creaPopup("/pratiche/violazioni/elencoViolazioniRicerca.zul", self,
                [
                        parRicerca      : filtri,
                        tipoTributo     : tipoTributo,
                        tipoPratica     : tipoPratica,
                        listaStatiAttiva: listaStatiAttiva
                ],
                { event ->
                    if (event.data) {
                        filtri = event.data.mapParametri

                        tributiSession.filtroRicercaViolazioni = filtri
                        filtroAttivo = filtri.filtroAttivoPerTipoPratica(this.tipoPratica)

                        if (listaStatiAttiva) {

                            filtri.statoAttiSelezionati = []
                            reimpostaFiltriListaStati()

                            caricaListaStati()
                            caricaViolazioni(true)
                        } else {
                            caricaViolazioni(true)
                        }

                        // Reset della multiselezione
                        resetMultiSelezione()

                        violazioneSelezionata = null
                        abilitaStampa()
                        abilitaPassaggioAPagoPa()
                        calcolaAbilitaAnnullaDovutoPagoPa()

                        self.invalidate()
                    } else {
                        if (filtri == null) {
                            filtri = new FiltroRicercaViolazioni()
                        }
                        filtroAttivo = filtri.filtroAttivoPerTipoPratica(this.tipoPratica)
                    }
                })
    }

    // Selezione stato/Tipo Atto
    @Command
    def onStatoClick(@BindingParam("stato") def stato) {

        statoSelezionato = stato
        BindUtils.postNotifyChange(null, null, this, "statoSelezionato")
    }

    @Command
    def onCheckStati() {

        selezionaStati(anyStatoChecked)
        aggiornaSelezioneStati()
        caricaViolazioni(true)
    }

    @Command
    def onCheckStato(@BindingParam("stato") def stato) {

        selezionaStato(stato, statiSelezionati[stato.id] ?: false)
        aggiornaSelezioneStati()
        caricaViolazioni(true)
    }

    @Command
    def onCheckTipiAtto(@BindingParam("stato") def stato) {

        selezionaStato(stato, statiSelezionati[stato.id] ?: false)
        aggiornaSelezioneStati()
        caricaViolazioni(true)
    }

    @Command
    def onOpenDettaglio(@BindingParam("event") def event) {

        def control = null
        // Questa dovrebbe essere la cella cui appliocare lo stile dinamico

        OpenEvent evt = (OpenEvent) event
        def detail = evt?.getTarget()
        // Questo è il dettaglio, ovvero l'icona + / - con un piccolo bordino, non l'intera cella
        // Se assegno lo stile qui mi tematizza solo ì'immagine ed il suo bordino, nulla di buonio

        String controlId = detail.uuid + '-chdextr'
        control = self.getFellowIfAny(controlId)            // L'uuid è giusto, ma non funziona
        // Provato anche con getChildren e getParent, ma non ne viene fuori nulla

        if (control) {
            if (evt.isOpen()) {
                control.setStyle('background: #ECEDF2; border-bottom: 3px solid #506E90;')
            } else {
                control.setStyle('background: #C6CCD6; border-bottom: 1px solid #d0d0d0;')
            }
        }
    }

    @Command
    def onCheckTipoAtto(@BindingParam("tipoAtto") def tipoAtto) {

        aggiornaSelezioneStati()
        caricaViolazioni(true)
    }

    @Deprecated
    @Command
    def onApriElencoViolazioni(@BindingParam("event") def event) {

        OpenEvent evt = (OpenEvent) event
        aggiornaElencoViolazioni(evt.isOpen())
    }

    @Command
    def onExportStatisticheXls() {

        def fields = [
                'descrStato'    : 'Stato',
                'descrTipoAtto' : 'Tipo Atto',
                'numeroPratiche': 'Numero',
                'numerate'      : 'Numerate',
                'nonNumerate'   : 'Non Numerate',
                'notificate'    : 'Notificati',
                'nonNotificate' : 'Non Notificati',
        ]

        if (tipoPratica == TipoPratica.A.tipoPratica) {
            fields = fields + [
                    'importoTotale' : colonnaImportoTitolo,
                    'importoRidotto': colonnaImportoRidTitolo,
                    'importoVersato': 'Imp.Versato',
            ]
        }
        if (tipoPratica == TipoPratica.L.tipoPratica) {
            fields = fields + [
                    'importoTotale' : colonnaImportoTitolo,
                    'importoRidotto': colonnaImportoRidTitolo,
                    'importoVersato': 'Imp.Versato',
            ]
        }
        if (tipoPratica == TipoPratica.S.tipoPratica) {
            fields = fields + [
                    'importoTotale' : colonnaImportoTitolo,
                    'importoRidotto': colonnaImportoRidTitolo,
                    'importoVersato': 'Imp.Versato',
            ]
        }
        if (tipoPratica == '*') {
            fields = fields + [
                    'importoTotale'    : colonnaImportoTitolo,
                    'importoRateizzato': 'Imp.Rateizzato',
                    'versatoRate'      : 'Imp.Versato',
            ]
        }

        def formatters = [
                "numeroPratiche": Converters.decimalToInteger,
                "numerate"      : Converters.decimalToInteger,
                "nonNumerate"   : Converters.decimalToInteger,
                "notificate"    : Converters.decimalToInteger,
                "nonNotificate" : Converters.decimalToInteger,
        ]

        def generatorTitle

        switch (tipoPratica) {
            default:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_VIOLAZIONI
                break
            case TipoPratica.A.tipoPratica:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_ACCERTAMENTI
                break
            case TipoPratica.L.tipoPratica:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_VIOLAZIONI
                break
            case TipoPratica.S.tipoPratica:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_SOLLECITI
                break
            case '*':
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_PRATICHE_RATEIZZATE
                break
        }

        String fileName = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                generatorTitle,
                [tipoTributo: tipoTributoAttuale])
        XlsxExporter.exportAndDownload(fileName, listaStati.collect { it.tipiAtto }.flatten(), fields, formatters)
    }

    def selezionaStati(Boolean selezione) {

        listaStati.each {
            selezionaStato(it, selezione)
        }
    }

    def selezionaStato(def stato, Boolean selezione) {

        stato.tipiAtto.each {
            statiSelezionati[it.id] = selezione
        }
    }

    def aggiornaSelezioneStati() {

        Boolean selezione
        Boolean totale

        listaStati.each {

            selezione = false
            totale = true

            it.tipiAtto.each {
                if (statiSelezionati[it.id]) {
                    selezione = true
                } else {
                    totale = false
                }
            }
            if (!selezione) totale = true

            statiSelezionati[it.id] = selezione
            statiSelezionatiAll[it.id] = totale
        }

        anyStatoChecked = false
        allStatoChecked = true
        listaStati.each {
            if (statiSelezionati[it.id]) {
                anyStatoChecked = true
                if (!statiSelezionatiAll[it.id]) {
                    allStatoChecked = false
                }
            } else {
                allStatoChecked = false
            }
        }

        aggiornaFiltroStati()

        BindUtils.postNotifyChange(null, null, this, "statiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "statiSelezionatiAll")
        BindUtils.postNotifyChange(null, null, this, "anyStatoChecked")
        BindUtils.postNotifyChange(null, null, this, "allStatoChecked")
    }

    def applicaFiltroStati() {

        def statoAttiSelezionati = filtri.statoAttiSelezionati ?: []

        statiSelezionati = [:]

        listaStati.each {

            def tipiAtto = it.tipiAtto
            tipiAtto.each {
                statiSelezionati[it.id] = it.id in statoAttiSelezionati
            }
        }

        aggiornaSelezioneStati()
    }

    def aggiornaFiltroStati() {

        filtri.statoAttiSelezionati = statiSelezionati.findAll { k, v -> v }.collect { it.key }
        reimpostaFiltriListaStati()
    }

    def aggiornaElencoViolazioni(boolean opened) {

    }

    def ripristinaFiltriListaStati() {

        filtri.statoAttiSelezionati = []
    }

    def reimpostaFiltriListaStati() {

        filtri.statoAttiSelezionatiTributo[tipoTributo] = filtri.statoAttiSelezionati
        tributiSession.filtroRicercaViolazioni = filtri
    }

    def caricaListaStati() {

        if (listaStatiAttiva && filtroAttivo) {
            preparaFiltri()

            listaStati = liquidazioniAccertamentiService.caricaListaStati(filtri)
            BindUtils.postNotifyChange(null, null, this, "listaStati")

            applicaFiltroStati()

            self.invalidate()
        }
    }

    @Command
    def onPaging() {
        caricaViolazioni()
    }

    @Command
    def onRefresh() {
        caricaListaStati()
        caricaViolazioni()
        resetMultiSelezione()
    }

    @Command
    def onChangeStato(@BindingParam("lbViolazioni") def lbViolazioni) {
        caricaViolazioni(true)
        lbViolazioni?.invalidate()

        resetMultiSelezione()
        violazioneSelezionata = null
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        calcolaAbilitaAnnullaDovutoPagoPa()
    }

    @Command
    onDovutoVersato() {
        commonService.creaPopup("/imposta/dovutoVersato.zul", self, [tipoTributo: tipoTributo])
    }

    @Command
    onNuovaPratica() {

        modificaPratica(null, tipoTributo, tipoPratica, 'U')
    }

    @Command
    onModificaPratica() {
        if (!praticaOpenable) {
            return
        }

        if (modificaPraticaInline) {
            Clients.showNotification("E' necessario salvare le modifiche in corso",
                    Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            return
        }


        modificaPratica(violazioneSelezionata.pratica, violazioneSelezionata.tipoTributo, violazioneSelezionata.tipoPratica, violazioneSelezionata.tipoEvento)
    }

    def modificaPratica(def pratica, String violTT, String violTP, String violTE) {

        String zul
        boolean lettura
        String situazione

        zul = caricaPannello."${violTT}"."${violTP}"."${violTE}".zul
        lettura = caricaPannello."${violTT}"."${violTP}"."${violTE}".lettura || this.lettura
        situazione = caricaPannello."${violTT}"."${violTP}"."${violTE}".situazione

        commonService.creaPopup(
                zul,
                self,
                [
                        pratica    : pratica,
                        tipoTributo: violTT,
                        tipoPratica: violTP,
                        tipoEvento : violTE,
                        lettura    : lettura,
                        situazione : situazione,
                        daBonifiche: false
                ],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato) {
                            if (filtroAttivo) {
                                caricaListaStati()
                                caricaViolazioni(true)
                            }
                        }
                    }
                }
        )
    }

    @Command
    onCalcolaAccertamenti() {

        commonService.creaPopup("/sportello/contribuenti/calcoloAccertamenti.zul", self, [
                tributo: tipoTributo,
                anno   : violazioneSelezionata?.anno,
                asynch : true,
        ],
                { event ->
                    if (event?.data?.elaborazioneEseguita) {
                        Clients.showNotification("Elaborazione calcolo accertamenti lanciata con successo",
                                Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)

                        caricaListaStati()
                        caricaViolazioni(true)
                    }
                })
    }

    @Command
    onCalcolaLiquidazione() {

        commonService.creaPopup("/sportello/contribuenti/calcoloLiquidazioniICI.zul", self, [
                tributo: tipoTributo,
                asynch : true,
        ],
                { event ->
                    if (event?.data?.elaborazioneEseguita) {
                        caricaListaStati()
                        caricaViolazioni(true)
                    }
                })
    }

    @Command
    onNumeraPratiche() {

        commonService.creaPopup("/sportello/contribuenti/numeraPratiche.zul", self
                , [tipoTributo: tipoTributo, tipoPratica: tipoPratica],
                {
                    caricaViolazioni()
                })

    }

    @Command
    onDataNotifica(@BindingParam("tp") String tp) {

        commonService.creaPopup("/sportello/contribuenti/dataNotifica.zul", self
                , [tipoTributo: tipoTributo, tipoPratica: tipoPratica], {
            caricaViolazioni()
        })
    }

    @Command
    onExportXls() {

        def violazioni
        def execTime = commonService.timeMe {

            Map fields

            def converters = [:]

            if (tipoPratica == TipoPratica.L.tipoPratica) {

                fields = [
                        "tipoTributoAttuale" : "Tipo Tributo",
                        "flagDePag"          : "DePag",
                        "pratica"            : "Pratica",
                        "isResidente"        : "Residente",
                        "contribuente"       : "Contribuente",
                        "codFiscale"         : "Codice Fiscale",
                        "anno"               : "Anno",
                        "data"               : "Data Liquidazione",
                        "clNumero"           : "Numero",
                        "dataNotifica"       : "Data Notifica",
                        "tipoNotifica"       : "Tipo Notifica",
                        "statoAccertamento"  : "Stato",
                        "tipoAttoDescrizione": "Tipo Atto",
                        "impCNum"            : "Imposta Calcolata",
                        "versamentiNum"      : "Versamenti",
                        "impTotNum"          : "Importo Liquidato",
                        "importoRidottoNum"  : "Importo Ridotto",
                        "totInteressiNum"    : "Interessi",
                        "totSanzioniNum"     : "Sanzioni",
                        "speseNotifica"      : "Spese Notifica",
                        "impVerNum"          : "Importo Versato",
                        "versatoParziale"    : "Ulteriori versamenti sulla pratica",
                        "dataPagamento"      : "Data Pagamento",
                        "dataStampa"         : "Data Stampa",
                        "nominativoPresso"   : "Presso",
                        "indirizzo"          : "Indirizzo",
                        "cap"                : "CAP",
                        "comuneProvincia"    : "Comune",
                        "utenteCreazione"    : "Utente Creazione",
                        "utenteModifica"     : "Utente Modifica",
                        "motivo"             : "Motivo",
                        "note"               : "Note",
                        "ruoloCoattivo"      : "Ruolo"
                ]

                violazioni = liquidazioniAccertamentiService.caricaLiquidazioni(
                        [max       : 999999,
                         offset    : 0,
                         activePage: 0],
                        filtri, campiOrdinamento)
            } else if (tipoPratica == TipoPratica.A.tipoPratica) {
                if (tipoTributo == 'TARSU') {

                    fields = [
                            "tipoTributoAttuale"  : "Tipo Tributo",
                            "flagDePag"           : "DePag",
                            "tipoEventoChar"      : "T",
                            "pratica"             : "Pratica",
                            "isResidente"         : "Residente",
                            "contribuente"        : "Contribuente",
                            "codFiscale"          : "Cod.Fiscale",
                            "anno"                : "Anno",
                            "data"                : "Data Acc.",
                            "tipoEventoViolazione": "T.Ev.",
                            "clNumero"            : "Numero",
                            "dataNotifica"        : "Data Notifica",
                            "tipoNotifica"        : "Tipo Notifica",
                            "statoAccertamento"   : "Stato",
                            "tipoAtto"            : "Tipo Atto",
                            "flagDenuncia"        : "D",
                            "flagAdesione"        : "Ad.",
                            "impAccNum"           : "Importo Lordo",
                            "impRidLordoNum"      : "Ridotto Lordo",
                            "impTotNum"           : "Importo Netto",
                            "impRidNum"           : "Ridotto Netto",
                            "impVerNum"           : "Versato",
                            "versatoParziale"     : "Ulteriori versamenti sulla pratica",
                            "impAddEcaNum"        : "Add.ECA",
                            "impMagEcaNum"        : "Mag.ECA",
                            "impAddProNum"        : "Add.Provinciale",
                            "impMagTaresNum"      : "C.Pereq.",
                            "impInteressiNum"     : "Totale Interessi",
                            "impSanzioniNum"      : "Totale Sanzioni",
                            "impSanzioniRidNum"   : "Sanzioni Ridotte",
                            "speseNotifica"       : "Spese Notifica",
                            "dataPagamento"       : "Data Pag.",
                            "dataNascita"         : "Data di Nascita",
                            "comuneNascita"       : "Comune di Nascita",
                            "sesso"               : "Sesso",
                            "indirizzoPresso"     : "Indirizzo",
                            "cap"                 : "CAP",
                            "comuneProvincia"     : "Comune",
                            "motivo"              : "Motivo",
                            "note"                : "Note",
                            "ruoloCoattivo"       : "Ruolo"
                    ]

                } else if (tipoTributo in ['ICI', 'TASI']) {

                    fields = [
                            "tipoTributoAttuale"  : "Tipo Tributo",
                            "flagDePag"           : "DePag",
                            "tipoEventoChar"      : "T",
                            "pratica"             : "Pratica",
                            "isResidente"         : "Residente",
                            "contribuente"        : "Contribuente",
                            "codFiscale"          : "Cod.Fiscale",
                            "anno"                : "Anno",
                            "data"                : "Data Acc.",
                            "tipoEventoViolazione": "T.Ev.",
                            "clNumero"            : "Numero",
                            "dataNotifica"        : "Data Notifica",
                            "tipoNotifica"        : "Tipo Notifica",
                            "statoAccertamento"   : "Stato",
                            "tipoAtto"            : "Tipo Atto",
                            "impAccNum"           : "Imposta Accertata",
                            "impRidLordoNum"      : "Importo Ridotto",
                            "impInteressiNum"     : "Totale Interessi",
                            "impSanzioniNum"      : "Totale Sanzioni",
                            "speseNotifica"       : "Spese Notifica",
                            "impVerNum"           : "Importo Versato",
                            "versatoParziale"     : "Ulteriori versamenti sulla pratica",
                            "dataPagamento"       : "Data Pag.",
                            "praticaRif"          : "Pratica Rif.",
                            "indirizzoPresso"     : "Indirizzo",
                            "cap"                 : "CAP",
                            "comuneProvincia"     : "Comune",
                            "motivo"              : "Motivo",
                            "note"                : "Note",
                            "ruoloCoattivo"       : "Ruolo"
                    ]

                } else if (tipoTributo in ['CUNI', 'ICP', 'TOSAP']) {

                    fields = [
                            "tipoTributoAttuale": "Tipo Tributo",
                            "flagDePag"         : "DePag",
                            "tipoEventoChar"    : "T",
                            "pratica"           : "Pratica",
                            "isResidente"       : "Residente",
                            "contribuente"      : "Contribuente",
                            "codFiscale"        : "Cod.Fiscale",
                            "anno"              : "Anno",
                            "data"              : "Data Acc.",
                            "tipoEvento"        : "T.Ev.",
                            "clNumero"          : "Numero",
                            "dataNotifica"      : "Data Notifica",
                            "tipoNotifica"      : "Tipo Notifica",
                            "statoAccertamento" : "Stato",
                            "tipoAtto"          : "Tipo Atto",
                            "impAccNum"         : "Imposta Accertata",
                            "impRidLordoNum"    : "Importo Ridotto",
                            "impVerNum"         : "Importo Versato",
                            "versatoParziale"   : "Ulteriori versamenti sulla pratica",
                            "impInteressiNum"   : "Totale Interessi",
                            "impSanzioniNum"    : "Totale Sanzioni",
                            "speseNotifica"     : "Spese Notifica",
                            "dataPagamento"     : "Data Pag.",
                            "praticaRif"        : "Pratica Rif.",
                            "indirizzoPresso"   : "Indirizzo",
                            "cap"               : "CAP",
                            "comuneProvincia"   : "Comune",
                            "motivo"            : "Motivo",
                            "note"              : "Note",
                            "ruoloCoattivo"     : "Ruolo"
                    ]

                }

                converters.tipoAtto = { ta -> ta ? "${ta.tipoAtto} - ${ta.descrizione}" : null }

                violazioni = liquidazioniAccertamentiService.caricaAccertamenti(
                        [max       : 999999,
                         offset    : 0,
                         activePage: 0],
                        filtri, campiOrdinamento)

            } else if (tipoPratica == 'S') {
                if (tipoTributo == 'TARSU') {

                    fields = [
                            "tipoTributoAttuale"  : "Tipo Tributo",
                            "flagDePag"           : "DePag",
                            "pratica"             : "Pratica",
                            "isResidente"         : "Residente",
                            "contribuente"        : "Contribuente",
                            "codFiscale"          : "Cod.Fiscale",
                            "anno"                : "Anno",
                            "data"                : "Data Soll.",
                            "dataScadenza"        : "Data Scad.",
                            "tipoEventoViolazione": "T.Ev.",
                            "clNumero"            : "Numero",
                            "dataNotifica"        : "Data Notifica",
                            "tipoNotifica"        : "Tipo Notifica",
                            "statoAccertamento"   : "Stato",
                            "tipoAtto"            : "Tipo Atto",
                            "impAccNum"           : "Importo Lordo",
                            "impTotNum"           : "Importo Netto",
                            "impAddEcaNum"        : "Add.ECA",
                            "impMagEcaNum"        : "Mag.ECA",
                            "impAddProNum"        : "Add.Provinciale",
                            "impMagTaresNum"      : "C.Pereq.",
                            "impSanzioniNum"      : "Totale Sanzioni",
                            "speseNotifica"       : "Spese Notifica",
                            "dataNascita"         : "Data di Nascita",
                            "comuneNascita"       : "Comune di Nascita",
                            "sesso"               : "Sesso",
                            "indirizzoPresso"     : "Indirizzo",
                            "cap"                 : "CAP",
                            "comuneProvincia"     : "Comune",
                            "motivo"              : "Motivo",
                            "note"                : "Note"
                    ]

                    converters.tipoAtto = { ta -> ta ? "${ta.tipoAtto} - ${ta.descrizione}" : null }

                } else if (tipoTributo == 'CUNI') {

                    fields = [
                            "tipoTributoAttuale"  : "Tipo Tributo",
                            "flagDePag"           : "DePag",
                            "pratica"             : "Pratica",
                            "isResidente"         : "Residente",
                            "contribuente"        : "Contribuente",
                            "codFiscale"          : "Cod.Fiscale",
                            "anno"                : "Anno",
                            "data"                : "Data Soll.",
                            "dataScadenza"        : "Data Scad.",
                            "tipoEventoViolazione": "T.Ev.",
                            "clNumero"            : "Numero",
                            "dataNotifica"        : "Data Notifica",
                            "tipoNotifica"        : "Tipo Notifica",
                            "statoAccertamento"   : "Stato",
                            "tipoAtto"            : "Tipo Atto",
                            "impTotNum"           : "Importo Netto",
                            "impSanzioniNum"      : "Totale Sanzioni",
                            "speseNotifica"       : "Spese Notifica",
                            "dataNascita"         : "Data di Nascita",
                            "comuneNascita"       : "Comune di Nascita",
                            "sesso"               : "Sesso",
                            "indirizzoPresso"     : "Indirizzo",
                            "cap"                 : "CAP",
                            "comuneProvincia"     : "Comune",
                            "motivo"              : "Motivo",
                            "note"                : "Note"
                    ]

                    converters.tipoAtto = { ta -> ta ? "${ta.tipoAtto} - ${ta.descrizione}" : null }
                }

                violazioni = liquidazioniAccertamentiService.caricaAccertamenti(
                        [max       : 999999,
                         offset    : 0,
                         activePage: 0],
                        filtri, campiOrdinamento)

            } else if (tipoPratica == '*') {

                fields = [
                        "pratica"             : "Pratica",
                        "isResidente"         : "Residente",
                        "contribuente"        : "Contribuente",
                        "codFiscale"          : "Codice Fiscale",
                        "tipoPratica"         : "Tipo Pratica",
                        "tipoTributoAttuale"  : "Tipo Tributo",
                        "anno"                : "Anno",
                        "clNumero"            : "Numero",
                        "data"                : "Data",
                        "dataNotifica"        : "Data Notifica",
                        "tipoNotifica"        : "Tipo Notifica",
                        "dataRateazione"      : "Data Rateazione",
                        "impTotNum"           : "Importo Pratica",
                        "importoRateizzatoNum": "Importo Rateizzato",
                        "importoInteressiNum" : "Importo Interessi",
                        "importoDovutoNum"    : "Importo Dovuto",
                        "versatoNum"          : "Importo Versamenti",
                        "importoDaVersareNum" : "Importo Da Versare",
                        "tipologiaRate"       : "Tipo Rata",
                        "numeroRate"          : "Numero Rate",
                        "rateVersate"         : "Rate Versate",
                        "dataPagamento"       : "Data Pag.",
                        "indirizzoPresso"     : "Indirizzo",
                        "cap"                 : "Cap",
                        "comuneProvincia"     : "Comune",
                        "motivo"              : "Motivo",
                        "note"                : "Note"
                ]

                violazioni = liquidazioniAccertamentiService.caricaLiquidazioni(
                        [max       : 999999,
                         offset    : 0,
                         activePage: 0],
                        filtri, campiOrdinamento)


            }

            def generatorTitle
            switch (tipoPratica) {
                case 'L':
                    generatorTitle = FileNameGenerator.GENERATORS_TITLES.LIQUIDAZIONI
                    break
                case 'A':
                    generatorTitle = FileNameGenerator.GENERATORS_TITLES.ACCERTAMENTI
                    break
                case 'S':
                    generatorTitle = FileNameGenerator.GENERATORS_TITLES.SOLLECITI
                    break
                default:
                    generatorTitle = FileNameGenerator.GENERATORS_TITLES.PRATICHE_RATEIZZATE
                    break
            }

            def fileName = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    generatorTitle,
                    [tipoTributo: TipoTributo.get(tipoTributo).toDTO().tipoTributoAttuale])

            converters.anno = Converters.decimalToInteger
            converters.tipoNotifica = { tn -> tn ? "${tn.tipoNotifica} - ${tn.descrizione}" : null }
            converters.ruoloCoattivo = Converters.decimalToInteger
            converters.isResidente = Converters.flagBooleanToString

            XlsxExporter.exportAndDownload(fileName, violazioni.record as List, fields, converters)
        }

        log.info "Generato XLSX di ${violazioni.record.size()} righe in ${execTime}"
    }

    @Command
    onF24Violazione() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [idDocumento: violazioneSelezionata.pratica,
                 codFiscale : violazioneSelezionata.codFiscale])
        List f24data

        try {
            f24data = f24Service.caricaDatiF24(PraticaTributo.get(violazioneSelezionata.pratica))
        } catch (Exception e) {
            Clients.showNotification(e.cause.detailMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)

            if (e.message == 'NOC_COD_TRIBUTO') {
                return
            }

            throw e
        }

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    onStampaAvvisoLiquidazione() {
        // Se stampa singola
        if (!abilitaSelezioneMultipla || !selezionePresente) {

            // def nomeFile = "LIQ_${(violazioneSelezionata.pratica as String).padLeft(10, "0")}_${violazioneSelezionata.codFiscale.padLeft(16, "0")}"
            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.MODELLI,
                    FileNameGenerator.GENERATORS_TITLES.LIQ,
                    [
                            idDocumento: violazioneSelezionata.id,
                            codFiscale : violazioneSelezionata.codFiscale
                    ]
            )

            def parametri = [
                    tipoStampa : ModelliService.TipoStampa.PRATICA,
                    idDocumento: violazioneSelezionata.id,
                    nomeFile   : nomeFile,
            ]

            commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])

        } else {
            // Stampa massiva
            if (!verificaStampaMassiva()) {
                return
            }

            commonService.creaPopup("/elaborazioni/creazioneElaborazione.zul",
                    null,
                    [nomeElaborazione: "LIQ_${tipoTributo == 'ICI' ? 'IMU' : tipoTributo}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                     tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE,
                     tipoTributo     : tipoTributo,
                     tipoPratica     : tipoPratica,
                     pratiche        : praticheSelezionate.findAll { k, v -> v }.collect { [pratica: it.key, codFiscale: praticheCF[it.key as String]] }])


        }
    }

    @Command
    def onStampaPianoRimborso() {
        def pianoRimborso = rateazioneService.pianoRimborso(violazioneSelezionata.id)

        def pratica = PraticaTributo.get(violazioneSelezionata.pratica)

        def listaTributiF24Capitale = rateazioneService.listaTributiF24(
                pratica.tipoTributo.tipoTributo,
                pratica.tipoTributo.getTipoTributoAttuale(violazioneSelezionata.anno as Short),
                'S'
        )

        // Per la stampa dei vecchi modelli (== null) viene visualizzato solo il codice, quindi niente da fare
        // Invece se si tratta dei nuovi modelli (!= null) bisogna visualizzare sia il codice che la descrizione
        if (pratica.calcoloRate != null) {
            pianoRimborso[0].rate.each { rata ->
                // Imposto la descrizione del tributo
                rata.tributoCapitaleF24 = listaTributiF24Capitale.find {
                    it.key == rata.tributoCapitaleF24
                }.value
            }
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.PIANO_RIMBORSO,
                [idDocumento: violazioneSelezionata.pratica,
                 codFiscale : violazioneSelezionata.codFiscale])
        JasperReportDef reportDef = new JasperReportDef(name: 'pianoRimborso.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: pianoRimborso
                , parameters: [SUBREPORT_DIR      : servletContext.getRealPath('/reports') + "/",
                               CALCOLO_RATE       : pratica.calcoloRate,
                               INT_RATE_SOLO_ESAVA: pratica.flagIntRateSoloEvasa])

        def pianoRimborsoFile = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, pianoRimborsoFile.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    onStampaAccertamento() {

        if (!abilitaSelezioneMultipla || !selezionePresente) {

            def nomeFile = "${tipoPratica == 'S' ? "SOL" : "ACC"}_${(violazioneSelezionata.pratica as String).padLeft(10, "0")}_${violazioneSelezionata.codFiscale.padLeft(16, "0")}"

            def parametri = [
                    tipoStampa : ModelliService.TipoStampa.PRATICA,
                    idDocumento: violazioneSelezionata.id,
                    nomeFile   : nomeFile,
            ]

            commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
        } else {
            // Stampa massiva
            if (!verificaStampaMassiva()) {
                return
            }

            commonService.creaPopup("/elaborazioni/creazioneElaborazione.zul",
                    null,
                    [nomeElaborazione: "${tipoPratica == 'S' ? "SOL" : "ACC"}_${TipoTributo.get(tipoTributo).toDTO().getTipoTributoAttuale()}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                     tipoElaborazione: ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE,
                     tipoTributo     : tipoTributo,
                     tipoPratica     : tipoPratica,
                     pratiche        : praticheSelezionate.findAll { k, v -> v }.collect { [pratica: it.key, codFiscale: praticheCF[it.key as String]] }])

        }
    }

    @Command
    def onEliminaSanzioni() {
        String messaggio = "Eliminazione delle sanzioni selezionate. Continuare?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            def idPraticheSelezionate = praticheSelezionate.findAll { k, v -> v }.collect { it.key }

                            idPraticheSelezionate.each {
                                liquidazioniAccertamentiService.eliminaSanzioniProcedure(it)
                            }

                            Clients.showNotification("Eliminazione eseguita", Clients.NOTIFICATION_TYPE_INFO, null,
                                    "middle_center", 5000, true)

                            caricaViolazioni()
                            resetMultiSelezione()

                        }
                    }
                }
        )
    }

    /*
     * Ricalcolo degli interessi: I
     * Ricalcolo delle spese: S
     * Ricalcolo entrambi: E
     */

    @Command
    def onRicalcoloInteressiSpeseNotifica(@BindingParam("tipo") def tipo) {

        if (!(tipo in ['E', 'S'])) {
            throw new IllegalArgumentException("Tipo di ricalcolo non riconosciuto")
        }

        def speseNotifica = (tipo in ['E', 'S'])
        def interessi = (tipo == 'E')

        def praticheNotificate = []
        def praticheDaRicalcolare = []
        def listaIdSelezionati = praticheSelezionate.findAll { k, v -> v }
                .collect { it.key }

        listaIdSelezionati.each {
            PraticaTributo prtr = PraticaTributo.findById(it)
            if (prtr.dataNotifica) {
                praticheNotificate.add(prtr)
            } else {
                praticheDaRicalcolare.add(it)
            }
        }

        if (!praticheNotificate.empty) {
            String message = "Impossibile effettuare i ricalcoli sulle seguenti pratiche gia' notificate:\n"
            def params = [with: 600]

            praticheNotificate.each {
                message += "- Pratica: " + it.id + " Cod. Fiscale: " + it.contribuente.codFiscale + "\n"
            }

            commonService.creaPopup("/commons/simpleMessagebox.zul", self, [
                    title  : 'Attenzione',
                    message: message,
            ], {
                apriRicalcoliInteressiPseseNotifica(praticheDaRicalcolare, interessi, speseNotifica)
            })

        } else {
            apriRicalcoliInteressiPseseNotifica(praticheDaRicalcolare, interessi, speseNotifica)
        }
    }

    @Command
    def onAssegnaStatoTipoAtto() {

        commonService.creaPopup("/pratiche/violazioni/assegnaStatoTipoAtto.zul", self,
                [
                        elencoPratiche: praticheSelezionate.findAll { k, v -> v }
                                .collect { it.key }
                ]
        )

    }

    // Per le liquidazioni si possono ricalcolare interessi e spese notifica, per gli accertamenti solo spese notifica
    private apriRicalcoliInteressiPseseNotifica(praticheDaRicalcolare, def interessi = true, def speseNotifica = true) {

        if (praticheDaRicalcolare.empty) {
            return
        }

        commonService.creaPopup('/pratiche/violazioni/ricalcoliLiquidazione.zul',
                self,
                [tipoTributo         : tipoTributo,
                 interessiEnabled    : interessi,
                 speseNotificaEnabled: speseNotifica],
                { response ->
                    if (!response.data) {
                        return
                    }

                    if (response.data.ricalcoloInteressi) {
                        praticheDaRicalcolare.each {
                            liquidazioniAccertamentiService.ricalcoloInteressi(it)
                        }
                    }

                    if (response.data.ricalcoloSpeseNotifica) {
                        ricalcolaSpeseNotifica(praticheDaRicalcolare, response.data.ricalcoloSpeseNotificaParams)
                    }

                    //Refresh
                    caricaViolazioni()
                    resetMultiSelezione()
                })

    }

    void ricalcolaSpeseNotifica(def praticheDaRicalcolare, def ricalcoloSpeseNotificaParams = null) {
        liquidazioniAccertamentiService.ricalcolaSpeseNotifica(praticheDaRicalcolare, ricalcoloSpeseNotificaParams)
    }

    @Command
    def onReplicaPerAnniSuccessivi() {

        Long praticaId = violazioneSelezionata?.pratica

        String message = liquidazioniAccertamentiService.verificaAccertamentoReplicabile(praticaId)

        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 10000, true)
            return;
        }

        commonService.creaPopup("/pratiche/violazioni/replicaPerAnniSuccessivi.zul", self,
                [
                        pratica: praticaId,
                ],
                { event ->
                    if (event?.data?.elaborazioneEseguita) {
                        caricaListaStati()
                        caricaViolazioni(true)
                    }
                }
        )
    }

    @Override
    void caricaLista() {
        caricaViolazioni()
    }

    @Command
    onStampaF24Rate() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [
                        idDocumento: violazioneSelezionata.pratica,
                        codFiscale : violazioneSelezionata.codFiscale])

        if (violazioneSelezionata.importoRateNum != null && OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "RATE_F24_A" }?.valore == 'S') {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Gli importi verranno stampati senza arrotondamento. Si desidera proseguire?", "Attenzione", buttons, null, Messagebox.QUESTION, null, {
                if (Messagebox.ON_YES == it.name) {
                    modelliService.generaF24Rate(violazioneSelezionata, nomeFile)
                }
            }, params)
        } else {
            modelliService.generaF24Rate(violazioneSelezionata, nomeFile)
        }
    }

    @Command
    def onGeneraAvvisoAgidPratiche() {

        def avviso = modelliService.generaAvvisiAgidPratica(violazioneSelezionata.pratica)

        if (avviso instanceof String) {
            Clients.showNotification(avviso, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }

        def media = commonService.fileToAMedia("avviso_agid_${violazioneSelezionata.codFiscale}", avviso)

        Filedownload.save(media)
    }

    @Command
    onStampaAccoglimentoRateazione() {

        def nomeFile = "RAI_${(violazioneSelezionata.pratica as String).padLeft(10, "0")}_${violazioneSelezionata.codFiscale.padLeft(16, " 0 ")}"

        def parametri = [
                tipoStampa : ModelliService.TipoStampa.ISTANZA_RATEAZIONE,
                idDocumento: violazioneSelezionata.id,
                nomeFile   : nomeFile,
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [parametri: parametri])
    }

    @Command
    def onInviaAppIO() {
        def tipoDocumento = documentaleService.recuperaTipoDocumento(violazioneSelezionata.pratica, 'P')
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(violazioneSelezionata.pratica, tipoDocumento)
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : violazioneSelezionata.codFiscale,
                 tipoTributo      : TipoTributo.findByTipoTributo(violazioneSelezionata.tipoTributo),
                 tipoComunicazione: tipoComunicazione,
                 pratica          : violazioneSelezionata.pratica,
                 tipologia        : "P",
                 anno             : violazioneSelezionata.anno
                ])
    }

    @Command
    onCambiaFiltriRateazione(@BindingParam("lbViolazioni") def lbViolazioni) {
        caricaViolazioni()
        lbViolazioni.invalidate()
    }

    @Command
    onSelezionaViolazione() {
        praticaOpenable = existsViewForPratica()
        BindUtils.postNotifyChange(null, null, this, 'praticaOpenable')

        if (modificaPraticaInline) {

            violazioneSelezionata = listaViolazioni.record.find { it.id == violazioneSelezionataPrecedenteId }

            BindUtils.postNotifyChange(null, null, this, "violazioneSelezionata")
            Messagebox.show("Modifica in corso, impossibile selezionare un'altra pratica.")
            return
        }

        // Rateazioni
        if (tipoPratica == "*") {
            calcolaAbilitaAnnullaDovutoPagoPa()
        }

        abilitaStampa()
        violazioneSelezionataPrecedenteId = violazioneSelezionata.id
        InvokerHelper.setProperties(violazioneSelezionataPrecedente, violazioneSelezionata)
    }

    private boolean existsViewForPratica() {
        String tipoTributo = violazioneSelezionata.tipoTributo
        String tipoPratica = violazioneSelezionata.tipoPratica
        String tipoEvento = violazioneSelezionata.tipoEvento

        return caricaPannello."${tipoTributo}" && caricaPannello."${tipoTributo}"."${tipoPratica}" && caricaPannello."${tipoTributo}"."${tipoPratica}"?."${tipoEvento}"
    }

    def isRateazione = false

    @Command
    @NotifyChange(['modificaPraticaInline'])
    def onModificaPraticaInline() {
        isRateazione = rateazioneService.praticaRateizzata((violazioneSelezionata.id ?: 0) as Long)
        modificaPraticaInline = !modificaPraticaInline
        listBoxViolazioni.invalidate()

        BindUtils.postNotifyChange(null, null, this, "isRateazione")
    }

    @Command
    @NotifyChange(['modificaPraticaInline'])
    def onAnnullaModificaPraticaInline() {
        modificaPraticaInline = false
        listaViolazioni.record.each {
            if (it.id == violazioneSelezionata.id) {
                InvokerHelper.setProperties(it, violazioneSelezionataPrecedente)
                BindUtils.postNotifyChange(null, null, this, "listaViolazioni")
            }
        }
    }

    @Command
    @NotifyChange(['modificaPraticaInline', 'violazioneSelezionataPrecedente'])
    def onAccettaModificaPraticaInline() {
        modificaPraticaInline = false
        def vio = PraticaTributo.get(violazioneSelezionata.id)
        vio.dataNotifica = violazioneSelezionata.dataNotificaDate
        if (violazioneSelezionata?.tipoAtto?.tipoAtto != null) {
            if (violazioneSelezionata?.tipoAtto instanceof TipoAttoDTO) {
                vio.tipoAtto = violazioneSelezionata?.tipoAtto?.toDomain()
            } else {
                vio.tipoAtto = violazioneSelezionata?.tipoAtto
            }
        } else {
            vio.tipoAtto = null
        }

        vio.save(flush: true, failOnError: true)

        violazioneSelezionataPrecedente.dataNotificaDate = violazioneSelezionata.dataNotificaDate
        violazioneSelezionataPrecedente.dataNotifica = violazioneSelezionata.dataNotificaDate?.format("dd/MM/yyyy")

        onRefresh()
    }

    @Command
    def onCheckPratica(@BindingParam("prtr") def pratica) {
        praticheCF[pratica.id as String] = pratica.codFiscale
        praticheObjectSelezionate[pratica.id as String] = pratica
        selezionePresente()
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        calcolaAbilitaAnnullaDovutoPagoPa()
    }

    @Command
    def onCheckPratiche() {
        selezionePresente()

        praticheSelezionate = [:]

        // Se non era selezionata almeno una pratica allora si vogliono selezionare tutte
        if (!selezionePresente) {

            caricaTutteLeViolazioni().each {
                praticheSelezionate << [(it.id): true]
                praticheCF[it.id as String] = it.codFiscale
                praticheObjectSelezionate[it.id as String] = it
            }
        }

        // Si aggiorna la presenza di selezione
        selezionePresente()
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        calcolaAbilitaAnnullaDovutoPagoPa()

        BindUtils.postNotifyChange(null, null, this, "praticheSelezionate")
    }

    @Command
    def onAllineamentoAnagrTrib() {
        if (!verificaAllineamentoAnagrTrib()) {
            return
        }

        commonService.creaPopup("/elaborazioni/creazioneElaborazione.zul",
                null,
                [nomeElaborazione   : "ALLIN_ANAGR_TRIB_${tipoTributo == 'ICI' ? 'IMU' : tipoTributo}_${(new Date().format("ddMMyyyy_hhmmss"))}",
                 tipoElaborazione   : ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE,
                 tipoTributo        : tipoTributo,
                 pratiche           : recuperaViolazioniSelezionate()
                         .unique { it.codFiscale }
                         .sort { it.codFiscale }
                         .collect { [codFiscale: it.codFiscale] },
                 selectAllDetails   : true,
                 autoExportAnagrTrib: true])
    }

    @Command
    def onPassaggioAPagoPa() {

        def listaIdSelezionati =
                praticheSelezionate.findAll { it.value == true }
                        .collect { it.key as Long }

        // Pratiche rateizzate
        if (tipoPratica == '*') {
            passaggioAPagoPa([violazioneSelezionata.id as Long])
        } else if (!listaIdSelezionati.collate(500).collect {
            PraticaTributo.
                    findAllByIdInListAndNumeroNotIsNotNull(it)
        }.flatten().empty) {

            Clients.showNotification("Nella selezione sono presenti pratiche non numerate",
                    Clients.NOTIFICATION_TYPE_ERROR,
                    null, "before_center", 5000, true)

        } else if (praticheSelezionate && !praticheSelezionate.empty) {

            passaggioAPagoPa(listaIdSelezionati)
        }

        caricaViolazioni()
        calcolaAbilitaAnnullaDovutoPagoPa()
    }

    @Command
    def onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onStampaStatistiche() {

        def datiStatistiche = []
        def statistica = [:]
        def dateFormat = new SimpleDateFormat("dd/MM/yyyy")
        def tipoAttoRateizzato = false

        def visualizzaRidotto = true

        def tipiStato = ""
        filtri.tipiStatoSelezionati.each {
            tipiStato += it.descrizione + (filtri.tipiStatoSelezionati.size() > 1 ? ", " : "")
        }

        def tipiAtto = ""
        filtri.tipiAttoSelezionati.each {
            tipiAtto += it.descrizione + (filtri.tipiAttoSelezionati.size() > 1 ? ", " : "")

            if (it.tipoAtto == 90) {
                tipoAttoRateizzato = true
            }
        }

        def tipologiaRate = filtri.tipologiaRate ? (filtri.tipologiaRate == 'M' ? "Mensile" :
                (filtri.tipologiaRate == 'B' ? "Bimestrale" :
                        (filtri.tipologiaRate == 'T' ? "Trimestrale" :
                                (filtri.tipologiaRate == 'Q' ? "Quadrimestrale" :
                                        (filtri.tipologiaRate == 'S' ? "Semestrale" :
                                                (filtri.tipologiaRate == 'A' ? "Annuale" : null)))))) : ""


        statistica.testata = [
                "ente"              : ad4EnteService.getEnte(),
                "tipoPratica"       : tipoPratica,
                "titoloImpLordo"    : colonnaImportoTooltip,
                "titoloImpRidotto"  : (visualizzaRidotto) ? colonnaImportoRidTooltip : '',
                "visibileImpRidotto": visualizzaRidotto,
                "filtri"            : [
                        "cognome"            : filtri.cognome,
                        "nome"               : filtri.nome,
                        "codFiscale"         : filtri.cf,
                        "numIndividuale"     : filtri.numeroIndividuale,
                        "codContribuente"    : filtri.codContribuente,
                        "tipiStato"          : tipiStato,
                        "tipiAtto"           : tipiAtto,
                        "tuttiTipiStato"     : filtri.tuttiTipiStatoSelezionati,
                        "tuttiTipiAtto"      : filtri.tuttiTipiAttoSelezionati,
                        "annoDa"             : filtri.daAnno,
                        "annoA"              : filtri.aAnno,
                        "dataDa"             : filtri.daData ? dateFormat.format(filtri.daData) : null,
                        "dataA"              : filtri.aData ? dateFormat.format(filtri.aData) : null,
                        "numeroDa"           : filtri.daNumeroPratica,
                        "numeroA"            : filtri.aNumeroPratica,
                        "tipoNotifica"       : filtri.tipoNotifica ? filtri.tipoNotifica.tipoNotifica + " - " + filtri.tipoNotifica.descrizione : null,
                        "dataNotificaDa"     : filtri.daDataNotifica ? dateFormat.format(filtri.daDataNotifica) : null,
                        "dataNotificaA"      : filtri.aDataNotifica ? dateFormat.format(filtri.aDataNotifica) : null,
                        "dataNotificaNessuna": filtri.nessunaDataNotifica,
                        "importoDa"          : filtri.daImporto,
                        "importoA"           : filtri.aImporto,
                        "dataPagamentoDa"    : filtri.daDataPagamento ? dateFormat.format(filtri.daDataPagamento) : null,
                        "dataPagamentoA"     : filtri.aDataPagamento ? dateFormat.format(filtri.aDataPagamento) : null,
                        "daStampare"         : filtri.daStampare,
                        "dataStampaDa"       : filtri.daDataStampa ? dateFormat.format(filtri.daDataStampa) : null,
                        "dataStampaA"        : filtri.aDataStampa ? dateFormat.format(filtri.aDataStampa) : null,
                        "tipologiaRate"      : tipologiaRate,
                        "importoRateizzatoDa": filtri.daImportoRateizzato,
                        "importoRateizzatoA" : filtri.aImportoRateizzato,
                        "dataRateazioneDa"   : filtri.daDataRateazione ? dateFormat.format(filtri.daDataRateazione) : null,
                        "dataRateazioneA"    : filtri.aDataRateazione ? dateFormat.format(filtri.aDataRateazione) : null,
                        "tipoAttoRateizzato" : tipoAttoRateizzato
                ]
        ]

        def idSelezionati = filtri.statoAttiSelezionati

        statistica.dati = []

        listaStati.each {
            if (it.id in idSelezionati) {
                statistica.dati << it
            }
        }

        // Escludo i tipi atto non selezionati
        statistica.dati.each { it ->
            it.tipiAtto.each { ta ->
                if (!(ta.id in idSelezionati)) {
                    it.tipiAtto.remove(ta)
                }
            }
        }

        datiStatistiche << statistica

        JasperReportDef reportDef = new JasperReportDef(name: 'statistiche.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiStatistiche
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def statisticheFile = jasperService.generateReport(reportDef)

        def nomeTipoPratiche

        switch (tipoPratica) {
            default:
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_PRATICHE
                break
            case TipoPratica.A.tipoPratica:
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_ACCERTAMENTI
                break
            case TipoPratica.L.tipoPratica:
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_LIQUIDAZIONI
                break
            case TipoPratica.S.tipoPratica:
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_SOLLECITI
                break
            case '*':
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_RATEAZIONI
                break
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                nomeTipoPratiche,
                [tipoTributo: tipoTributoAttuale])

        AMedia amedia = commonService.fileToAMedia(nomeFile, statisticheFile.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onCalcolaSolleciti() {

        commonService.creaPopup("/pratiche/solleciti/calcoloSolleciti.zul", self, [
                tipoTributo      : tipoTributo,
                anno             : violazioneSelezionata?.anno,
                listaContribuenti: null,
                asynch           : true,
        ],
                { event ->
                    if (event.data) {
                        if (event.data?.elaborazioneEseguita == true) {
                            Clients.showNotification("Elaborazione calcolo solleciti lanciata con successo", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                            caricaListaStati()
                            caricaViolazioni(true)
                        } else if (event.data?.elaborazioneEseguita == false && event.data?.isSoloAnno == false) {
                            Clients.showNotification("Pratica non creata", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                        } else if (event.data?.elaborazioneEseguita == false && event.data?.isSoloAnno == true) {
                            // Nel caso si avvia un calcolo singolo senza specificare CF, non è possibile capire se ha creato o no le pratiche per l'anno scelto
                            caricaListaStati()
                            caricaViolazioni(true)
                            Clients.showNotification("Calcolo eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                        }
                    }
                })
    }


    @Command
    def onAnnullaDovuto() {

        if (!dePagAbilitato) {
            return
        }

        // Pratiche rateizzate
        if (tipoPratica == '*') {
            integrazioneDePagService.eliminaDovutoPratica(PraticaTributo.get(violazioneSelezionata.id))
            Clients.showNotification("Annulla dovuto eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

        } else {

            praticheSelezionate.findAll { it.value == true }
                    .collect { it.key }
                    .each {
                        def pratica = PraticaTributo.get(it)
                        integrazioneDePagService.eliminaDovutoPratica(pratica)
                    }
            Clients.showNotification("Annulla dovuto eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }

        caricaViolazioni()
        calcolaAbilitaAnnullaDovutoPagoPa()
    }

    private void passaggioAPagoPa(ArrayList lista) {

        def message = ''

        lista.each { praticaId ->

            def response = integrazioneDePagService.passaPraticaAPagoPAConNotifica(praticaId, self)

            if (response.inviato) {
                def messageNow = ''

                if (tipoTributo in ['CUNI']) {
                    messageNow = liquidazioniAccertamentiService.annullaDovutoSuViolazione(praticaId)
                }

                if (!messageNow.isEmpty()) {
                    if (!message.isEmpty()) {
                        message += "\n\n"
                    }
                    message += messageNow
                }
            }
        }

        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 15000, true)
        }
    }

    private boolean verificaStampaMassiva() {
        // Gli importi di tutte le pratiche selezionate devono essere congruenti in segno
        def violazioni = recuperaViolazioniSelezionate()

        def segnoIncopatibile = (violazioni.find { it.impTotNum >= 0 } != null) && (violazioni.find { it.impTotNum < 0 } != null)
        if (segnoIncopatibile) {
            Clients.showNotification("Nell'elenco sono presenti pratiche con importo totale di segno diverso.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        // Tutte le pratiche devono essere numerate
        def nonNumerata = (violazioni.find { it.clNumero == null } != null)
        if (nonNumerata) {
            Clients.showNotification("Nell'elenco sono presenti pratiche non numerate.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        def tipiEvento = violazioni.collect { it.tipoEvento }.unique().size()

        if (tipiEvento > 1) {
            Clients.showNotification("Selezionare pratiche con lo stesso tipo evento.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        return true

    }

    private verificaAllineamentoAnagrTrib() {
        def violazioni = recuperaViolazioniSelezionate().unique { it.codFiscale }

        if (violazioni.size() > MAX_CF_ANAGR_TRIB) {
            Clients.showNotification("Sono consentiti massimo ${MAX_CF_ANAGR_TRIB} codici fiscali distinti.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        if ((allineamentoAnagrafeTributariaService.datiEnte()?.codiceFiscale ?: "").empty) {
            Clients.showNotification("E' necessario valorizzare il campo COD_FISCALE nella tabella AS4_V_SOGGETTI_CORRENTI.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }


        return true
    }

    private void abilitaStampa() {
        abilitaStampa =
                ( // Satmap singola
                        violazioneSelezionata // deve essere selezionata almeno una violazione
                                && (violazioneSelezionata.clNumero != null) // la pratica deve essere numerata
                                && (
                                (violazioneSelezionata.tipoTributo == 'ICI' && violazioneSelezionata.anno >= 2012) // Se ICI dal 2012
                                        || violazioneSelezionata.tipoTributo != 'ICI') // Per TASI ttutte le annualità
                ) || (
                        // stampa massiva
                        abilitaSelezioneMultipla // la selezione multipla è abilitata
                                && selezionePresente // è stata selezionata almeno una pratica
                )
        BindUtils.postNotifyChange(null, null, this, "abilitaStampa")
    }

    private void abilitaPassaggioAPagoPa() {
        abilitaPassaggioAPagoPa = false
        praticheSelezionate.find {
            if (it.value) {
                def praticaObject = praticheObjectSelezionate[it.key as String]
                abilitaPassaggioAPagoPa = praticaObject.clNumero && praticaObject.impTotNum > 0

                // stop search
                if (!abilitaPassaggioAPagoPa) {
                    return true
                }

                // continue search
                return false
            }
        }
        BindUtils.postNotifyChange(null, null, this, "abilitaPassaggioAPagoPa")
    }

    private void calcolaAbilitaAnnullaDovutoPagoPa() {
        abilitaAnnullaDovutoPagoPa = false

        // Rateazione
        if (tipoPratica == '*') {
            abilitaAnnullaDovutoPagoPa = violazioneSelezionata?.flagDePag == 'S'
        } else {
            praticheSelezionate.find {
                if (it.value) {
                    def praticaObject = praticheObjectSelezionate[it.key as String]
                    abilitaAnnullaDovutoPagoPa = praticaObject.flagDePag == 'S'

                    // stop search
                    if (!abilitaAnnullaDovutoPagoPa) {
                        return true
                    }

                    // continue search
                    return false
                }
            }
        }
        BindUtils.postNotifyChange(null, null, this, "abilitaAnnullaDovutoPagoPa")
    }

    private void selezionePresente() {
        selezionePresente = (praticheSelezionate.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private def caricaTutteLeViolazioni() {

        def tutteViolazioni = []

        switch (tipoPratica) {
            case TipoPratica.L.tipoPratica:
                tutteViolazioni = liquidazioniAccertamentiService.caricaLiquidazioni(null, filtri, null, true)
                break
            case [TipoPratica.A.tipoPratica, TipoPratica.S.tipoPratica]:
                tutteViolazioni = liquidazioniAccertamentiService.caricaAccertamenti(null, filtri, null, true)
                break
            case '*':
                tutteViolazioni = liquidazioniAccertamentiService.caricaLiquidazioni(null, filtri, null, true)
                break
        }

        return tutteViolazioni
    }

    private def recuperaViolazioniSelezionate() {
        def listaIdSelezionati = praticheSelezionate.findAll { k, v -> v }.collect { it.key }
        def listaPratiche = caricaTutteLeViolazioni().findAll {
            it.id in listaIdSelezionati
        }

        return listaPratiche
    }

    private resetMultiSelezione() {
        praticheSelezionate = [:]
        selezionePresente = false
        BindUtils.postNotifyChange(null, null, this, "praticheSelezionate")
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private void caricaViolazioni(def resetPaginazione = false) {

        if (!filtroAttivo) {
            return
        }

        preparaFiltri()
        // Se da TARI si imposta il filtro Tipo Atto su 'Inf. Den.' e poi si passa al tab CUNI, data la mancanza
        // del parametro di filtro (ID), questo viene impostao in OD, che comprende sia 'Inf. Den.' che 'Om. Den.'
        if (tipoTributo in ["CUNI", 'TOSAP', 'ICP'] && filtri.tipoAttoSanzione == "ID") {
            filtri.tipoAttoSanzione = "OD"
        }

        if (resetPaginazione) {
            listaViolazioniPaginazione = [
                    max       : 30,
                    offset    : 0,
                    activePage: 0
            ]
            BindUtils.postNotifyChange(null, null, this, "listaViolazioniPaginazione")
        }

        def filtriNow = filtri.clone()
        if (!listaStatiAttiva) {
            filtriNow.statoAttiSelezionati = null
        }

        switch (tipoPratica) {
            case TipoPratica.L.tipoPratica:
                listaViolazioni = liquidazioniAccertamentiService.caricaLiquidazioni(listaViolazioniPaginazione, filtriNow, campiOrdinamento)
                break
            case [TipoPratica.A.tipoPratica, TipoPratica.S.tipoPratica]:
                listaViolazioni = liquidazioniAccertamentiService.caricaAccertamenti(listaViolazioniPaginazione, filtriNow, campiOrdinamento)
                break
            case '*':
                listaViolazioni = liquidazioniAccertamentiService.caricaLiquidazioni(listaViolazioniPaginazione, filtriNow, campiOrdinamento)
                break
        }

        // Se era selezionata una pratica la si riseleziona nel caso di modifiche per permettere a ZK di evidenziare la riga
        if (violazioneSelezionata) {
            violazioneSelezionata = listaViolazioni.record.find {
                it.pratica == violazioneSelezionata?.pratica
            }
        }

        praticheObjectSelezionate.each {
            it.value.flagDePag = listaViolazioni.record.find { v -> v.pratica == (it.key as Long) }?.flagDePag
        }

        calcolaDisabilitaDataNotificaSuRateazione()

        BindUtils.postNotifyChange(null, null, this, "listaViolazioni")
        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "violazioneSelezionata")
    }

    // Prepara i filtri per il caricamento degli stati e delle violazioni
    def preparaFiltri() {

        filtri.tipoTributo = tipoTributo
        filtri.tipoPratica = tipoPratica

        // Se da TARI si imposta il filtro Tipo Atto su 'Inf. Den.' e poi si passa al tab CUNI, data la mancanza
        // del parametro di filtro (ID), questo viene impostao in OD, che comprende sia 'Inf. Den.' che 'Om. Den.'
        if (tipoTributo in ["CUNI", 'TOSAP', 'ICP'] && filtri.tipoAttoSanzione == "ID") {
            filtri.tipoAttoSanzione = "OD"
        }
    }

    private verificaCompetenze() {
        cbTributiAbilitati = competenzeService.tipiTributoUtenza().collectEntries {
            [(it.tipoTributo): true]
        }

        def ttDesc = [
                ICI  : 'IMU',
                TASI : 'TASI',
                TARSU: 'TARI',
                ICP  : 'PUBBL',
                TOSAP: 'COSAP'
        ]
        cbTributi.each { k, v ->
            if (competenzeService.tipiTributoUtenza().find { it.tipoTributo == k } == null) {
                filtri?.rateizzate?.tributi?."${ttDesc[k]}" = false
            }
        }
    }

    private void calcolaDisabilitaDataNotificaSuRateazione() {
        // Se la pratica ha una data di notifica e il tipo atto corrisponde a "Rateazione" o se la pratica
        // e` stata rateizzata, disabilita la modifica della data di notifica
        listaViolazioni.record.each { pratica ->
            disabilitaDataNotificaSuRateazione[pratica.id] = pratica.dataNotifica &&
                    (pratica.tipoAtto?.tipoAtto == 90 || rateazioneService.praticaRateizzata((pratica.id ?: 0) as Long))
        }
        BindUtils.postNotifyChange(null, null, this, "disabilitaDataNotificaSuRateazione")
    }
}
