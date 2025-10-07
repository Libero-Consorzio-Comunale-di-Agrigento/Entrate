package pratiche.ravvedimenti

import commons.OrdinamentoMutiColonnaViewModel
import document.FileNameGenerator
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.contribuenti.RavvedimentiService
import it.finmatica.tr4.contribuenti.RavvedimentoReportService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.TipoAttoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.violazioni.FiltroRicercaViolazioni
import net.sf.jmimemagic.Magic
import net.sf.jmimemagic.MagicMatch
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.OpenEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.text.SimpleDateFormat

class ElencoRavvedimentiViewModel extends OrdinamentoMutiColonnaViewModel {


    Window self
    ServletContext servletContext

    // services
    CompetenzeService competenzeService
    RavvedimentiService ravvedimentiService
    RavvedimentoReportService ravvedimentoReportService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    TributiSession tributiSession
    F24Service f24Service
    JasperService jasperService
    DocumentaleService documentaleService
    IntegrazioneDePagService integrazioneDePagService
    CanoneUnicoService canoneUnicoService
    CommonService commonService
    Ad4EnteService ad4EnteService

    def tipoTributo
    def tipoTributoAttuale
    def tipoPratica

    boolean lettura = true
    boolean abilitaCreaRavvedimento = true

    // Al momento manca l'infrastruttura per il Ravvedimento TARI (Vedi caricaDatiF24 piu' avanti, manca il bean)
    boolean abilitaGeneraF24 = true

    boolean abilitaStampa = false
    boolean abilitaSelezioneMultipla = false

    boolean abilitaPassaggioAPagoPa = false
    boolean abilitaAnnullaDovutoPagoPa = false

    // Paginazione
    def ravvedimentoSelezionato
    def ravvedimentoSelezionatoPrecedente = [:]
    def ravvedimentoSelezionatoPrecedenteId

    def listaRavvedimenti

    // totali
    def totaliRavvedimenti = [
            impCalcolata   : 0,
            impVersamenti  : 0,
            impLordo       : 0,
            impRidLordo    : 0,
            impRavvedimenti: 0,
            impRidotto     : 0,
            impVersato     : 0,
            impAddECA      : 0,
            impMagECA      : 0,
            impAddPro      : 0,
            impMagTARES    : 0,
            impInteressi   : 0,
            impSanzioni    : 0,
            impSanzioniRid : 0,
    ]

    // paginazione
    def pagingDetails = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Filtri
    FiltroRicercaViolazioni filtri = null
    def filtroAttivo = false

    def listaTipiAtto

    def ravvedimentiSelezionati = [:]
    def ravvedimentiCF = [:]
    def ravvedimentiObjectSelezionati = [:]
    def selezionePresente = false

    def dePagAbilitato = false
    def dePagAbilitatoTributo = false

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

    @Init(superclass = true)
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("tipoPratica") String tp) {

        this.self = w

        this.sizeElencoViolazioni = "60%"

        tipoTributo = tt ?: '*'        // Tutti i tributi, gestione rateazioni
        tipoTributoAttuale = TipoTributo.findByTipoTributo(tt)?.tipoTributoAttuale
        tipoPratica = tp ?: '*'    // Tutte le pratiche, gestione rateazioni
        listaTipiAtto = [null] + TipoAtto.list().sort { it.tipoAtto }

        lettura = competenzeService.tipoAbilitazioneUtente(tipoTributo) != 'A'
        abilitaCreaRavvedimento = (tipoTributo in ['ICI', 'TASI', 'TARSU', 'CUNI']) && !lettura

        // Il CUNI non ha F24
        abilitaGeneraF24 = (tipoPratica == 'V' && tipoTributo != 'CUNI')
        abilitaSelezioneMultipla = tipoPratica == 'V'

        campiOrdinamento = [
                'COG_NOM'           : [verso: VERSO_ASC, posizione: 0],
                'COD_FISCALE'       : [verso: VERSO_ASC, posizione: 1],
                'ANNO'              : [verso: VERSO_ASC, posizione: 2],
                'STATO_ACCERTAMENTO': [verso: VERSO_ASC, posizione: 3]
        ]

        campiCssOrdinamento = [
                'COG_NOM'           : CSS_ASC,
                'COD_FISCALE'       : CSS_ASC,
                'ANNO'              : CSS_ASC,
                'STATO_ACCERTAMENTO': CSS_ASC
        ]

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

        listaStatiAttiva = tipoPratica in [TipoPratica.V.id, '*']

        preparaFiltri()
        filtroAttivo = filtri.filtroAttivo()

        if (listaStatiAttiva) {

            colonnaImportoRidTitolo = "Imp.Ridotto"
            colonnaImportoRidTooltip = "Importo Ridotto"

            switch (tipoPratica) {
                default:
                    colonnaImportoTitolo = "Importo"
                    colonnaImportoTooltip = "Importo"
                    break
                case TipoPratica.V.id:
                    colonnaImportoTitolo = "Imp.Ravvedimento"
                    colonnaImportoTooltip = "Importo Ravvedimento"
                    break
                case '*':
                    colonnaImportoTitolo = "Imp.Pratica"
                    colonnaImportoTooltip = "Importo Pratica"
                    break
            }

            pagingDetails.pageSize = 20
            BindUtils.postNotifyChange(null, null, this, "pagingDetails")

            ripristinaFiltriListaStati()
            if (filtroAttivo) {
                caricaListaStati()
                caricaRavvedimenti()
            } else {
                if (!ignoraMascheraRicerca) {
                    openCloseFiltri()
                }
            }
        } else {
            if (filtri) {
                caricaRavvedimenti()
            } else {

                openCloseFiltri()
            }
        }

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()
        dePagAbilitatoTributo = dePagAbilitato && tipoTributo in ['TARSU', 'CUNI']
    }

    @Command
    openCloseFiltri() {

        Window w = Executions.createComponents("/pratiche/violazioni/elencoViolazioniRicerca.zul",
                self, [parRicerca : filtri,
                       tipoTributo: tipoTributo,
                       tipoPratica: tipoPratica])

        w.onClose { event ->
            if (event.data) {

                filtri = event.data.mapParametri
                filtroAttivo = filtri.filtroAttivo()

                if (listaStatiAttiva) {

                    filtri.statoAttiSelezionati = []
                    reimpostaFiltriListaStati()

                    caricaListaStati()
                    caricaRavvedimenti(true)
                } else {
                    caricaRavvedimenti(true)
                }

                tributiSession.filtroRicercaViolazioni = filtri
                preparaFiltri()

                resetMultiSelezione()

                ravvedimentoSelezionato = null
                abilitaStampa()
                abilitaPassaggioAPagoPa()
                abilitaAnnullaDovutoPagoPa()
            } else {
                if (filtri == null) {
                    filtri = new FiltroRicercaViolazioni()
                }
                preparaFiltri()
                filtroAttivo = filtri.filtroAttivo()
            }
        }
        w.doModal()
    }

    @Command
    def onStatoClick(@BindingParam("stato") def stato) {

        statoSelezionato = stato
        BindUtils.postNotifyChange(null, null, this, "statoSelezionato")
    }

    @Command
    def onCheckStati() {

        selezionaStati(anyStatoChecked)
        aggiornaSelezioneStati()
        caricaRavvedimenti(true)
    }

    @Command
    def onCheckStato(@BindingParam("stato") def stato) {

        selezionaStato(stato, statiSelezionati[stato.id] ?: false)
        aggiornaSelezioneStati()
        caricaRavvedimenti(true)
    }

    @Command
    def onCheckTipiAtto(@BindingParam("stato") def stato) {

        selezionaStato(stato, statiSelezionati[stato.id] ?: false)
        aggiornaSelezioneStati()
        caricaRavvedimenti(true)
    }

    @Command
    def onCheckTipoAtto(@BindingParam("tipoAtto") def tipoAtto) {

        aggiornaSelezioneStati()
        caricaRavvedimenti(true)
    }

    @Command
    def onOpenDettaglio(@BindingParam("event") def event) {

        def control = null

        // Non funziona, stesso problema di ElencoViolazioniViewModel

        OpenEvent evt = (OpenEvent) event
        def detail = evt?.getTarget()

        String controlId = detail.uuid + '-chdextr'
        control = self.getFellowIfAny(controlId)

        if (control) {
            if (evt.isOpen()) {
                control.setStyle('background: #ECEDF2; border-bottom: 3px solid #506E90;')
            } else {
                control.setStyle('background: #C6CCD6; border-bottom: 1px solid #d0d0d0;')
            }
        }
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

        if (tipoPratica == TipoPratica.V.tipoPratica) {
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
            case TipoPratica.V.id:
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_RAVVEDIMENTI
                break
            case '*':
                generatorTitle = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_PRATICHE_RATEIZZATE
                break
        }

        def fileName = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                generatorTitle,
                [tipoTributo: tipoTributoAttuale])

        XlsxExporter.exportAndDownload(fileName, listaStati.collect { it.tipiAtto }.flatten(), fields, formatters)
    }

    @Command
    def onStampaStatistiche() {

        def datiStatistiche = []
        def statistica = [:]
        def dateFormat = new SimpleDateFormat("dd/MM/yyyy")
        def tipoAttoRateizzato = false

        def visualizzaRidotto = false

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
            case TipoPratica.V.tipoPratica:
                nomeTipoPratiche = FileNameGenerator.GENERATORS_TITLES.STATISTICHE_RAVVEDIMENTI
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
    def onAssegnaStatoTipoAtto() {

        commonService.creaPopup("/pratiche/violazioni/assegnaStatoTipoAtto.zul", self,
                [
                        elencoPratiche: ravvedimentiSelezionati.findAll { k, v -> v }.collect { it.key }
                ]
        )

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

        if (!filtroAttivo) {
            return
        }

        preparaFiltri()

        listaStati = liquidazioniAccertamentiService.caricaListaStati(filtri)
        BindUtils.postNotifyChange(null, null, this, "listaStati")

        applicaFiltroStati()

        self.invalidate()
    }

    @Command
    def onPaging() {

        caricaRavvedimenti()
    }

    @Command
    def onRefresh() {

        caricaListaStati()
        caricaRavvedimenti()
        resetMultiSelezione()
    }

    @Command
    def onChangeStato(@BindingParam("lbRavvedimenti") def lbRavvedimenti) {

        caricaRavvedimenti(true)
        lbRavvedimenti.invalidate()

        resetMultiSelezione()
        ravvedimentoSelezionato = null
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        abilitaAnnullaDovutoPagoPa()
    }

    @Command
    def onModificaRavvedimento() {

        String situazione
        boolean letturaNow = this.lettura
        String zul = "/pratiche/violazioni/liquidazioneImu.zul"

        switch (tipoTributo) {
            case "ICI": situazione = "ravvImu"
                break
            case "TASI": situazione = "ravvTasi"
                break
            case "TARSU": situazione = "ravvTari"
                break
            case "CUNI": situazione = "ravvTribMin"
                break
            default: situazione = "liquidazione"
                break
        }

        def onClose = { event ->
            if (event?.data?.praticaEliminata) {

                onRefresh()
            } else {

                onRefresh()
            }
        }
        creaPopup(zul, [pratica: ravvedimentoSelezionato.pratica, tipoTributo: tipoTributo, situazione: situazione, lettura: letturaNow], onClose)
    }

    @Command
    def onNuovoRavvedimento() {

        def filtri = [
                contribuente     : "s",
                cognomeNome      : "",
                cognome          : "",
                nome             : "",
                indirizzo        : "",
                codFiscale       : "",
                id               : null,
                codFiscaleEscluso: null,
                idEscluso        : null
        ]

        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul", self, [filtri: null, listaVisibile: true, ricercaSoggCont: true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {

                    Contribuente contribuente = canoneUnicoService.creaContribuente(event.data.Soggetto);
                    creaNuovoRavvedimento(contribuente.codFiscale)
                }
            }
        }
        w.doModal()
    }

    // Crea nuovo Ravvedimento dopo Popup e va in modifica
    def creaNuovoRavvedimento(String cfContribuente) {

        def tipoTributoSelezionato = tipoTributo
        def anno = "Tutti"

        if (!(tipoTributoSelezionato in ['ICI', 'TASI', 'TARSU', 'CUNI'])) {
            tipoTributoSelezionato = ""
        }

        Window w = Executions.createComponents("/pratiche/violazioni/creazioneRavvedimentoOperoso.zul", self,
                [anno       : anno,
                 codFiscale : cfContribuente,
                 tipoTributo: tipoTributoSelezionato])

        w.onClose() { event ->
            if (event.data) {
                if (!event.data.pratica) {
                    Clients.showNotification("Ravvedimento non generato.", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                    return
                }

                def filtriContribuente = [
                        tipoTributo: tipoTributo,
                        cf         : cfContribuente
                ]

                def ravvedimentiContribuente = ravvedimentiService.getRavvedimenti(filtriContribuente)
                def elencoRavvedimenti = ravvedimentiContribuente.records
                ravvedimentoSelezionato = elencoRavvedimenti.find { it.pratica == event.data.pratica }

                onModificaRavvedimento()
            }
            caricaListaStati()
            caricaRavvedimenti()
        }

        w.doModal()
    }

    @Command
    onNumeraPratiche(@BindingParam("tp") String tp) {

        Window w = Executions.createComponents("/sportello/contribuenti/numeraPratiche.zul", self, [tipoTributo: tipoTributo, tipoPratica: tp])

        w.onClose() {
            caricaRavvedimenti()
        }

        w.doModal()
    }

    @Command
    onGeneraReportRavvedimento() {

        def idPratica = ravvedimentoSelezionato.pratica
        def cdoFiscale = ravvedimentoSelezionato.codFiscale

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.RAVVEDIMENTO,
                [
                        idDocumento: idPratica,
                        codFiscale : cdoFiscale])

        def pratica = PraticaTributo.get(idPratica)

        def oggetti = tipoTributo != 'CUNI' ?
                liquidazioniAccertamentiService.getOggettiLiquidazioneImu(idPratica) :
                canoneUnicoService.getConcessioniDaPratica(tipoTributo, ravvedimentoSelezionato.pratica)

        def sanzioni = pratica.sanzioniPratica.sort { it.sanzione.codSanzione }

        def debiti = []
        def crediti = []

        if (liquidazioniAccertamentiService.isRavvedimentoSuRuoli(pratica)) {
            debiti = liquidazioniAccertamentiService.getDettagliRuoliDaRavvedimento(idPratica)
            crediti = liquidazioniAccertamentiService.getCreditiDaRavvedimento(idPratica)
        }

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(pratica.contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)
        def versato = calcolaVersato.vers
        versato = (versato == 0 ? null : versato)

        def scheda = ravvedimentoReportService.generaReportRavvedimento(nomeFile, idPratica, oggetti, sanzioni, versato, debiti, crediti)

        Magic parser = new Magic()
        MagicMatch match = parser.getMagicMatch(scheda.toByteArray())

        AMedia amedia = new AMedia(nomeFile, match.extension, match.mimeType, scheda.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    onF24Violazione() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [idDocumento: ravvedimentoSelezionato.pratica,
                 codFiscale : ravvedimentoSelezionato.codFiscale])

        List f24data

        try {
            f24data = f24Service.caricaDatiF24(PraticaTributo.get(ravvedimentoSelezionato.pratica))
        }
        catch (Exception e) {
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
    def onApriStampa() {

        def idPratica = ravvedimentoSelezionato.pratica

        def pratica = PraticaTributo.get(idPratica).toDTO()

        def oggetti = liquidazioniAccertamentiService.getOggettiLiquidazioneImu(idPratica)
        def listaCanoni = canoneUnicoService.getConcessioniDaPratica(tipoTributo, idPratica)

        def sanzioni = pratica.sanzioniPratica.sort { it.sanzione.codSanzione }

        def debiti = []
        def crediti = []

        if (liquidazioniAccertamentiService.isRavvedimentoSuRuoli(pratica)) {
            debiti = liquidazioniAccertamentiService.getDettagliRuoliDaRavvedimento(idPratica)
            crediti = liquidazioniAccertamentiService.getCreditiDaRavvedimento(idPratica)
        }

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(pratica.contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)
        def versato = calcolaVersato.vers
        versato = (versato == 0 ? null : versato)

        def abilitaAgID = false
        if (dePagAbilitato) {
            abilitaAgID = integrazioneDePagService.iuvValorizzatoPratica(idPratica)
        }

        def abilitaF24 = abilitaGeneraF24 && !(pratica.anno < 2012 && pratica.tipoTributo.tipoTributo == 'ICI')

        commonService.creaPopup("/pratiche/dettaglioStampe.zul", self,
                [
                        pratica          : pratica,
                        listaCanoni      : listaCanoni,
                        oggettiImu       : oggetti,
                        sanzioni         : sanzioni,
                        versato          : versato,
                        debiti           : debiti,
                        crediti          : crediti,
                        abilitaGeneraF24 : abilitaF24,
                        abilitaAvvisoAgID: abilitaAgID
                ], {}
        )
    }

    @Command
    onExportXls() {

        Map fields
        def ravvedimenti

        if (tipoTributo == 'ICI') {

            fields = [
                    "pratica"                    : "Pratica",
                    "isResidente"                : "Residente",
                    "cognomeNome"                : "Contribuente",
                    "codFiscale"                 : "Cod.Fiscale",
                    "anno"                       : "Anno",
                    "dataRavv"                   : "Data Ravv.",
                    "tipoRavvedimento"           : "Tipo Ravv.",
                    "clNumero"                   : "Numero",
                    "stato"                      : "Stato",
                    "tipoAtto"                   : "Tipo Atto",
                    "dataRiferimentoRavvedimento": "Data Pagamento",
                    "impCalcolata"               : "Imp.Calcolata",
                    "impVersamenti"              : "Versamenti",
                    "impRavved"                  : "Imp.Ravvedimento",
                    "impRidotto"                 : "Importo Ridotto",

                    "impVersato"                 : "Importo Versato",
                    "resIndirizzo"               : "Indirizzo",
                    "resCAP"                     : "C.A.P.",
                    "resComune"                  : "Comune",
                    "motivo"                     : "Motivo",
                    "note"                       : "Note"
            ]

        } else if (tipoTributo == 'TASI') {

            fields = [
                    "pratica"                    : "Pratica",
                    "isResidente"                : "Residente",
                    "cognomeNome"                : "Contribuente",
                    "codFiscale"                 : "Cod.Fiscale",
                    "anno"                       : "Anno",
                    "dataRavv"                   : "Data Ravv.",
                    "tipoRavvedimento"           : "Tipo Ravv.",
                    "clNumero"                   : "Numero",
                    "stato"                      : "Stato",
                    "tipoAtto"                   : "Tipo Atto",
                    "dataRiferimentoRavvedimento": "Data Pagamento",
                    "impCalcolata"               : "Imp.Calcolata",
                    "impVersamenti"              : "Versamenti",
                    "impRavved"                  : "Imp.Ravvedimento",
                    "impRidotto"                 : "Importo Ridotto",

                    "impVersato"                 : "Importo Versato",
                    "resIndirizzo"               : "Indirizzo",
                    "resCAP"                     : "C.A.P.",
                    "resComune"                  : "Comune",
                    "motivo"                     : "Motivo",
                    "note"                       : "Note",
                    "tipoRapp"                   : "Tipo di Rapp."
            ]

        } else if (tipoTributo in ['CUNI']) {

            fields = [
                    "pratica"                    : "Pratica",
                    "isResidente"                : "Residente",
                    "cognomeNome"                : "Contribuente",
                    "codFiscale"                 : "Cod.Fiscale",
                    "anno"                       : "Anno",
                    "dataRavv"                   : "Data Ravv.",
                    "tipoRavvedimento"           : "Tipo Ravv.",
                    "clNumero"                   : "Numero",
                    "stato"                      : "Stato",
                    "tipoAtto"                   : "Tipo Atto",
                    "dataRiferimentoRavvedimento": "Data Pagamento",
                    "impCalcolata"               : "Imp.Calcolata",
                    "impVersamenti"              : "Versamenti",
                    "impRavved"                  : "Imp.Ravvedimento",
                    "impRidotto"                 : "Importo Ridotto",
                    "impVersato"                 : "Importo Versato",
                    "resIndirizzo"               : "Indirizzo",
                    "resCAP"                     : "C.A.P.",
                    "resComune"                  : "Comune",
                    "motivo"                     : "Motivo",
                    "note"                       : "Note"
            ]

        } else if (tipoTributo in ['TARSU']) {

            fields = [
                    "pratica"                    : "Pratica",
                    "isResidente"                : "Residente",
                    "cognomeNome"                : "Contribuente",
                    "codFiscale"                 : "Cod.Fiscale",
                    "anno"                       : "Anno",
                    "dataRavv"                   : "Data Ravv.",
                    "tipoRavvedimento"           : "Tipo Ravv.",
                    "clNumero"                   : "Numero",
                    "stato"                      : "Stato",
                    "dataRiferimentoRavvedimento": "Data Pagamento",
                    "impCalcolata"               : "Imp.Calcolata",
                    "impVersamenti"              : "Versamenti",
                    'impLordo'                   : 'Imp.Lordo',
                    "impRavved"                  : "Imp.Netto",
                    "impVersato"                 : "Importo Versato",
                    'impAddECA'                  : 'Add.ECA',
                    'impMagECA'                  : 'Mag.ECA',
                    'impAddPro'                  : 'Add.Pro.',
                    'impMagTARES'                : 'C.Pereq.',
                    'impInteressi'               : 'Tot.Int.',
                    'impSanzioni'                : 'Tot.Sanz.',
                    "resIndirizzo"               : "Indirizzo",
                    "resCAP"                     : "C.A.P.",
                    "resComune"                  : "Comune",
                    "motivo"                     : "Motivo",
                    "note"                       : "Note"
            ]
        }

        ravvedimenti = ravvedimentiService.getRavvedimenti(filtri, campiOrdinamento)

        def fileName = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.RAVVEDIMENTI,
                [tipoTributo: TipoTributo.get(tipoTributo).toDTO().tipoTributoAttuale])

        def converters = [
                anno            : Converters.decimalToInteger,
                resCAP          : Converters.decimalToInteger,
                isResidente     : Converters.flagBooleanToString,
                tipoRavvedimento: { s -> ((s == 'D') ? 'Ravv. da Sportello' : ((s == 'V') ? 'Ravv. da Versamento' : null)) }
        ]

        XlsxExporter.exportAndDownload(fileName, ravvedimenti.records, fields, converters)
    }

    @Override
    void caricaLista() {

        caricaRavvedimenti()
    }

    @Command
    onSelezionaRavvedimento() {

        abilitaStampa()
        ravvedimentoSelezionatoPrecedenteId = ravvedimentoSelezionato.id
        InvokerHelper.setProperties(ravvedimentoSelezionatoPrecedente, ravvedimentoSelezionato)
    }

    @Command
    def onCheckRavvedimento(@BindingParam("ravv") def pratica) {

        ravvedimentiCF[pratica.pratica as String] = pratica.codFiscale
        ravvedimentiObjectSelezionati[pratica.pratica as String] = pratica
        selezionePresente()
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        abilitaAnnullaDovutoPagoPa()
    }

    @Command
    def onCheckRavvedimenti() {

        selezionePresente()

        ravvedimentiSelezionati = [:]

        // nessuna selezione -> selezionare tutti
        if (!selezionePresente) {

            caricaTuttiRavvedimenti().each {
                ravvedimentiSelezionati << [(it.id): true]
                ravvedimentiCF[it.id as String] = it.codFiscale
                ravvedimentiObjectSelezionati[it.id as String] = it
            }
        }

        // Si aggiorna la presenza di selezione
        selezionePresente()
        abilitaStampa()
        abilitaPassaggioAPagoPa()
        abilitaAnnullaDovutoPagoPa()

        BindUtils.postNotifyChange(null, null, this, "ravvedimentiSelezionati")
    }

    @Command
    def onPassaggioAPagoPa() {

        if (!PraticaTributo.findAllByIdInListAndNumeroNotIsNotNull(ravvedimentiSelezionati
                .findAll { it.value == true }.collect { it.key as Long }
        ).empty) {

            Clients.showNotification("Nella selezione sono presenti pratiche non numerate",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        } else if (ravvedimentiSelezionati && !ravvedimentiSelezionati.empty) {
            def listaIdSelezionati = ravvedimentiSelezionati.findAll { it.value == true }.collect { it.key as Long }
            passaggioAPagoPa(listaIdSelezionati)
        }

        onRefresh()
        abilitaAnnullaDovutoPagoPa()
    }

    @Command
    def onAnnullaDovuto() {

        if (!dePagAbilitato) {
            return
        }

        ravvedimentiSelezionati.findAll { it.value == true }
                .collect { it.key }
                .each {
                    def pratica = PraticaTributo.get(it)
                    integrazioneDePagService.eliminaDovutoPratica(pratica)
                }
        Clients.showNotification("Annulla dovuto eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

        onRefresh()
        abilitaAnnullaDovutoPagoPa()
    }

    private void passaggioAPagoPa(ArrayList lista) {

        def message = ''

        lista.each { praticaId ->

            String messageNow = ''

            def response = integrazioneDePagService.passaPraticaAPagoPAConNotifica(praticaId, self)

            if (response.inviato) {
                if (tipoTributo in ['TARSU']) {
                    messageNow = liquidazioniAccertamentiService.annullaDovutoRuoliSuRavvedimento(praticaId)
                }
                if (tipoTributo in ['CUNI']) {
                    messageNow = liquidazioniAccertamentiService.annullaDovutoSuViolazione(praticaId)
                }
            }

            if (!messageNow.isEmpty()) {
                if (!message.isEmpty()) {
                    message += "\n\n"
                }
                message += messageNow
            }
        }

        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 15000, true)
        }
    }

    private boolean verificaStampaMassiva() {

        // Gli importi di tutti i ravvedimenti selezionati devono essere congruenti in segno
        def ravvedimenti = recuperaRavvedimentiSelezionati()

        def segnoIncopatibile = (ravvedimenti.find { it.impTotNum >= 0 } != null) && (ravvedimenti.find { it.impTotNum < 0 } != null)
        if (segnoIncopatibile) {
            Clients.showNotification("Nell'elenco sono presenti ravvedimenti con importo totale di segno diverso.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        // Tutti i ravvedimenti devono essere numerati
        def nonNumerata = (ravvedimenti.find { it.clNumero == null } != null)
        if (nonNumerata) {
            Clients.showNotification("Nell'elenco sono presenti ravvedimenti non numerati.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)

            return false
        }

        return true
    }

    private void abilitaStampa() {

        abilitaStampa = (
                // Stampa singola
                ravvedimentoSelezionato // un ravvedimento selezionato
                        && (ravvedimentoSelezionato.clNumero != null)    // deve essere numerata
        ) || (
                // Stampa massiva
                abilitaSelezioneMultipla // selezione multipla abilitata
                        && selezionePresente // uno o più ravvedimenti selezionati
        )
        BindUtils.postNotifyChange(null, null, this, "abilitaStampa")
    }

    private void abilitaPassaggioAPagoPa() {
        abilitaPassaggioAPagoPa = false
        ravvedimentiSelezionati.find {
            if (it.value) {
                def praticaObject = ravvedimentiObjectSelezionati[it.key as String]
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

    private void abilitaAnnullaDovutoPagoPa() {

        abilitaAnnullaDovutoPagoPa = false
        ravvedimentiSelezionati.find {
            if (it.value) {
                def praticaObject = ravvedimentiObjectSelezionati[it.key as String]
                abilitaAnnullaDovutoPagoPa = praticaObject.flagDePag == 'S'

                // stop search
                if (!abilitaAnnullaDovutoPagoPa) {
                    return true
                }

                // continue search
                return false
            }
        }
        BindUtils.postNotifyChange(null, null, this, "abilitaAnnullaDovutoPagoPa")
    }

    private void selezionePresente() {

        selezionePresente = (ravvedimentiSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private def caricaTuttiRavvedimenti() {

        def tuttiRavvedimenti = []

        switch (tipoPratica) {
            case TipoPratica.V.id:
                tuttiRavvedimenti = ravvedimentiService.getRavvedimenti(filtri, null, Integer.MAX_VALUE, 0, true)
                break
            case '*': // Non usato al momento
                //	tuttiRavvedimenti = ravvedimentiService.getRavvedimenti(filtri, null, Integer.MAX_VALUE, 0, true)
                break
        }

        return tuttiRavvedimenti
    }

    private def recuperaRavvedimentiSelezionati() {

        def listaIdSelezionati = ravvedimentiSelezionati.findAll { k, v -> v }.collect { it.key }
        def listaRavvedimenti = caricaTuttiRavvedimenti().findAll {
            it.id in listaIdSelezionati
        }

        return listaRavvedimenti
    }

    private resetMultiSelezione() {

        ravvedimentiSelezionati = [:]
        selezionePresente = false
        BindUtils.postNotifyChange(null, null, this, "ravvedimentiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "selezionePresente")
    }

    private void caricaRavvedimenti(def resetPaginazione = false) {

        if (!filtroAttivo) {
            return
        }

        preparaFiltri()

        if (resetPaginazione) {
            pagingDetails.activePage = 0
        }

        switch (tipoPratica) {
            case TipoPratica.V.tipoPratica:
                listaRavvedimenti = ravvedimentiService.getRavvedimenti(filtri, campiOrdinamento, pagingDetails.pageSize, pagingDetails.activePage)
                break
            case '*':
                listaRavvedimenti = ravvedimentiService.getRavvedimenti(filtri, campiOrdinamento, pagingDetails.pageSize, pagingDetails.activePage)
                break
        }

        if (resetPaginazione) {
            pagingDetails.totalSize = listaRavvedimenti.totalCount
        }

        aggiornaTotali()

        // Se era selezionato una ravvedimento lo riseleziona nel caso di modifiche per permettere a ZK di evidenziare la riga
        if (ravvedimentoSelezionato) {
            ravvedimentoSelezionato = listaRavvedimenti.record.find {
                it.pratica == ravvedimentoSelezionato?.pratica
            }
        }

        ravvedimentiObjectSelezionati.each {
            it.value.flagDePag = listaRavvedimenti.record.find { v -> v.pratica == (it.key as Long) }?.flagDePag
        }

        BindUtils.postNotifyChange(null, null, this, "listaRavvedimenti")
        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "campiCssOrdinamento")
        BindUtils.postNotifyChange(null, null, this, "ravvedimentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
    }

    // Aggiorna totali da lista e notifica UI
    private void aggiornaTotali() {

        def totals = listaRavvedimenti.totals
        totaliRavvedimenti.impCalcolata = totals.impCalcolata
        totaliRavvedimenti.impVersamenti = totals.impVersamenti
        totaliRavvedimenti.impLordo = totals.impLordo
        totaliRavvedimenti.impRidLordo = totals.impRidLordo
        totaliRavvedimenti.impRavvedimenti = totals.impRavvedimenti
        totaliRavvedimenti.impRidotto = totals.impRidotto
        totaliRavvedimenti.impVersato = totals.impVersato
        totaliRavvedimenti.impAddECA = totals.impAddECA
        totaliRavvedimenti.impMagECA = totals.impMagECA
        totaliRavvedimenti.impAddPro = totals.impAddPro
        totaliRavvedimenti.impMagTARES = totals.impMagTARES
        totaliRavvedimenti.impInteressi = totals.impInteressi
        totaliRavvedimenti.impSanzioni = totals.impSanzioni
        totaliRavvedimenti.impSanzioniRid = totals.impSanzioniRid

        BindUtils.postNotifyChange(null, null, this, "totaliRavvedimenti")
    }

    // Prepara i filtri per il caricamento degli stati e delle violazioni
    def preparaFiltri() {

        filtri.tipoTributo = tipoTributo
        filtri.tipoPratica = tipoPratica
    }

    // Crea popup
    private void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }
}
