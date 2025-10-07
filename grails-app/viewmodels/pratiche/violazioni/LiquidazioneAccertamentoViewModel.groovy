package pratiche.violazioni

import document.FileNameGenerator
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.*
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.contribuenti.ParametriRateazione
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.contribuenti.RavvedimentoReportService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.*
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import javax.servlet.ServletContext
import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Calendar

class LiquidazioneAccertamentoViewModel {

    private static Log log = LogFactory.getLog(LiquidazioneAccertamentoViewModel)

    Window self
    ServletContext servletContext
    JasperService jasperService
    IntegrazioneDePagService integrazioneDePagService

    CommonService commonService
    RavvedimentoReportService ravvedimentoReportService
    OggettiService oggettiService
    ImposteService imposteService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    CanoneUnicoService canoneUnicoService
    RateazioneService rateazioneService
    ModelliService modelliService
    F24Service f24Service
    Ad4EnteService ad4EnteService
    DocumentaleService documentaleService
    DenunceService denunceService
    GestioneAnomalieService gestioneAnomalieService
    ComunicazioniService comunicazioniService

    // Generali
    boolean aggiornaStato = false

    boolean abilitaStampa = false
    boolean abilitaGeneraF24 = true
    def dePagAbilitato = false
    def iuvValorizzato = false

    def ruoloCoattivo
    def sgraviAttivi = false

    def praticaDiPraticaTotaleOpenable = false

    // Esistono situazionei hard-coded per compatibilita' tra visualizzatori e tipi tributo - Si veda piu' avanti nel codice
    def listaTitoli = [liquidazione     : "Liquidazione IMU"
                       , accManImu      : "Accertamento IMU"            // Visualizzazione Dettgalio, solo 3.8.7 e superiore
                       , accManImuUnica : "Accertamento IMU"            // Visualizzazione Unica, compatibile 3.8.6 e precedenti
                       , accTotImu      : "Accertamento Totale IMU"
                       , accManTari     : "Accertamento TARI"        // Visualizzazione Dettgalio, solo 3.8.4 e superiore
                       , accManTariUnica: "Accertamento TARI"            // Visualizzazione Unica, compatibile 3.8.3 e precedenti
                       , accAutoTari    : "Accertamento Automatico TARI"
                       , accTotTari     : "Accertamento Totale TARES"
                       , accManTribMin  : "Accertamento TRIB_MIN"
                       , accAutoTribMin : "Accertamento Automatico TRIB_MIN"
                       , accTotTribMin  : "Accertamento Totale TRIB_MIN"
                       , ravvImu        : "Ravvedimento Operoso IMU"
                       , ravvTasi       : "Ravvedimento Operoso TASI"
                       , ravvTari       : "Ravvedimento Operoso TARI"
                       , ravvTribMin    : "Ravvedimento Operoso TRIB_MIN"
                       , solAutoTari    : "Sollecito Automatico TARI"
                       , solAutoTribMin : "Sollecito Automatico TRIB_MIN"
    ]

    def tipiVersamento = ['A': 'Acconto', 'S': 'Saldo', 'U': 'Unico']
    def rateRavvedimento = ['0': 'Rata Unica',
                            '1': "Rata 1",
                            '2': "Rata 2",
                            '3': "Rata 3",
                            '4': "Rata 4"]

    def tipiEventiDenuncia = [
            "A": "Automatico",
            "R": "Rendita",
            "T": "Totale",
            "I": "Iscrizione",
            "V": "Variazione",
            "C": "Cessazione",
            "U": "Unico",
            "S": "Saldo"
    ]

    def cbSpecieRuolo = [
            ORDINARIO: true,
            COATTIVO : true
    ]

    def tipologieRavvedimento = [null: '', 'D': 'Ravv. da Sportello', 'V': 'Ravv. da Versamento']

    def tipiRata
    def tipiCalcoloRata

    def vecchioNumero

    boolean liqImu = false
    boolean accManImu = false
    boolean accManTot = false
    boolean accManTotImu = false
    boolean accManImuUnica = false

    boolean accAutoTari = false
    boolean accManTari = false
    boolean accTotTari = false
    boolean accManTariUnica = false

    boolean accAutoTribMin = false
    boolean accManTribMin = false
    boolean accTotTribMin = false
    boolean ravvTribMin = false
    boolean ravvTari = false
    boolean ravvTariSuRuoli = false

    boolean dic = false
    boolean liq = false
    boolean acc = false

    def versImpostaSenzaPratica = ""
    def praticaRateizzata

    String title
    String situazione
    String accertamento

    BigDecimal versato
    BigDecimal totVersamenti = 0
    BigDecimal totVersamentiRate = 0

    BigDecimal totVersamentiAP = 0
    BigDecimal totVersamentiRurali = 0
    BigDecimal totVersamentiTerreni = 0
    BigDecimal totVersamentiAreeF = 0
    BigDecimal totVersamentiAltriF = 0
    BigDecimal totVersamentiFabbD = 0
    BigDecimal totVersamentiFabbricati = 0
    BigDecimal totVersamentiMerce = 0

    BigDecimal totVersamentiTerreniCom = 0
    BigDecimal totVersamentiTerreniErar = 0
    BigDecimal totVersamentiAreeFCom = 0
    BigDecimal totVersamentiAreeFErar = 0
    BigDecimal totVersamentiAltriFCom = 0
    BigDecimal totVersamentiAltriFErar = 0
    BigDecimal totVersamentiRuraliCom = 0
    BigDecimal totVersamentiRuraliErar = 0
    BigDecimal totVersamentiFabbDCom = 0
    BigDecimal totVersamentiFabbDErar = 0

    BigDecimal totAddPro = 0
    BigDecimal totMaggTares = 0
    BigDecimal totAddProRate = 0
    BigDecimal totMaggTaresRate = 0

    // Totali per frontespizio
    BigDecimal totImportoLordo = 0
    BigDecimal totImportoLordoRid = 0
    BigDecimal totImportoLordoRid2 = 0
    BigDecimal totImportoCalcolato = 0
    BigDecimal totImportoTotale = 0
    BigDecimal totImportoTotaleRid = 0
    BigDecimal totImportoTotaleRid2 = 0
    BigDecimal totImpostaCalcolata = 0      /// Totale lordo tardivo per ravvedimenti TARSU su ruoli, senza oggetti

    def totOggettiAccManuale = [
            // ICI/IMU/TASI
            importo        : 0,
            importoRidotto : 0,
            importoRidotto2: 0,
            versato        : 0,
            // TARES/Tributi Min.
            imposta        : 0,
            impostaLorda   : 0,
            maggTARES      : 0
    ]

    def totCanoni = [
            imposta     : 0,
            impostaLorda: 0
    ]

    PraticaTributoDTO pratica
    ContribuenteDTO contribuente
    def oggettoSelezionato

    Boolean calcoloNormalizzato

    Boolean flagTardivo
    Boolean modificaFlagTardivo

    List listaTipiStato
    List listaTipiAtto
    List listaTipiAliquota
    List listaTipiAliquotaAP

    Set<VersamentoDTO> versamenti
    Set<VersamentoDTO> versamentiRate

    List oggettiImu = []
    List oggettiAccAutomatico
    List oggettiAccManuale
    List oggettiAccManualeDich
    List oggettiAccManTot = []
    List oggettiAccManTotTari = []
    List dichiaratoAccManTotImu
    List liquidatoAccManTotImu
    List accertatoAccManTotImu
    List dichiaratoAccManImu
    List liquidatoAccManImu
    List dichiaratoAccManTari
    List accertatoAccManTari
    List dichiaratoAccManTribMin
    List accertatoAccManTribMin

    List<OggettoContribuenteDTO> listaOggettiAccMan = []

    // Specifico per ravvedimenti CUNI, ripresi da Dichiarazione CUNI per riutilizzo ZUL
    def listaCanoni = []
    def numCanoni = 0
    def canoneSelezionato
    Boolean modificaCanone        // Vedi aggiornaModificaOggetti

    def concessione = [
            praticaRef: 0
    ]
    def parametriBandBox = [
            annoTributo: null
    ]

    //	List importi
    def sanzioni
    List totaliSanzioni
    def controlloSanzioni
    List ruoli
    List listaPraticheRif

    String notePerPopup

    def hasRuoli

    def tipo
    def tipoRapportoCod = 'D'

    def lettura

    Boolean modificaOggetti
    Boolean modificaFlagsPeraOggetti
    Boolean eliminaOggLiqRavv        // Caso speciale : vedi nota pià avanti
    Boolean calcoloImposta

    def listaFonti

    def ruoliVersamento

    Tabbox tbInfoTabBox
    Bandbox bdRuoliVersamento
    Listbox lbRuoliVersamento
    Popup popupNote

    EventListener<Event> eventIsDirty = null
    def isDirty = false
    def isDirtySanzioni = false
    def isDirtyVersamenti = false
    def isDirtyOggetti = false
    def isDirtyIter = false
    def isDirtyRateazione = false
    def inizializzazioneSanzioni = true
    def inizializzazioneVersamenti = true
    def inizializzazioneOggetti = true
    def inizializzazioneIter = true
    def oldTestoNote

    def isNuovoVersamento
    def tipoVersamentoTestataOrig
    def tipoVersamentoRavv
    def rataRavv

    def elencoMotivi = []
    def motivoSelezionato

    def listaSanzioni

    def sanzioniModifica = [:]

    def iter

    String tipoTributoAttuale
    String tipoTributoAttualeDescr
    def tipoPratica
    def tipoRavvedimento

    def rate
    def rateTotali = [
            impRataTot     : null,
            quotaIntTot    : null,
            quotaCapTot    : null,
            aggioTot       : null,
            aggioRimTot    : null,
            dilazioneTot   : null,
            dilazioneRimTot: null,
            importoTot     : null,
            importoArrTot  : null,
            oneriTot       : null,
            sanzioniAccTot : null,
            quotaTefaTot   : null
    ]
    def numeroRate

    def listaTributiF24Interessi
    def listaTributiF24Capitale

    def versamentiCaricati = false
    def sanzioniCaricate = false

    def selectedTabId = 'oggetti'

    ParametriRateazione parametriRateazione

    def aRuolo = null

    def rendite = [:]

    Map filtri = [
            denunciante      : [
                    codFiscale : "",
                    cognomeNome: ""
            ],
            contribuente     : [
                    codFiscale: "",
                    cognome   : "",
                    nome      : ""
            ],
            comuneDenunciante: [
                    denominazione: ""
            ]
    ]

    def listaTipiNotifica

    def numPraticheRif = 0
    def numOggetti = 0
    def numLocaliEdAree = 0
    def numSanzioni = 0
    def numIter = 0
    def numRateazioni = 0
    def numVersamenti = 0
    def numRuoli = 0

    Boolean dichiaratoOpened = true
    def sizeQuadroDichiarato

    def ruoloInviato = false

    Boolean sanzMinimaSuRidGen = false          // Abilitazione generale, disabilita cambio data se esistono sanzioni
    Boolean sanzMinimaSuRid = false             // Abilitazione per pratica, modifica gestione sanzioni e totali

    def soggetto = 'P'
    def tipoOccupazione

    def praticaDiPraticaTotaleSelezionata
    Map caricaPannello = ["ICI"  : ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                , lettura   : false
                                                , situazione: "accManImu"]]],
                          "TASI" : ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                , lettura   : false
                                                , situazione: "accManImu"]]],
                          "TARSU": ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManuali.zul"
                                                , lettura   : false
                                                , situazione: "accManTari"]]],
                          "ICP"  : ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                , lettura   : true
                                                , situazione: "accManTribMin"]]],
                          "TOSAP": ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                , lettura   : true
                                                , situazione: "accManTribMin"]]],
                          "CUNI" : ["A": ["U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                , lettura   : true
                                                , situazione: "accManTribMin"]]]]

    def praticaSalvata = false

    def disabilitaDataNotificaSuRateazione = true

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("pratica") def prt,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("tipoPratica") def tp,
         @ExecutionArgParam("tipoEvento") def te,
         @ExecutionArgParam("situazione") String s,
         @ExecutionArgParam("lettura") boolean lt,
         @ExecutionArgParam("soggetto") @Default("") def sogg) {

        this.self = w

        sizeQuadroDichiarato = "25%"

        tipiRata = rateazioneService.tipiRata
        situazione = s

        tipiRata = rateazioneService.tipiRata
        tipiCalcoloRata = rateazioneService.tipiCalcoloRata

        this.soggetto = sogg

        this.parametriRateazione = new ParametriRateazione()

        // Caricamento della pratica
        if (prt) {

            pratica = liquidazioniAccertamentiService.caricaPratica(prt as Long)
            tipoTributoAttuale = pratica.tipoTributo.tipoTributo

            refreshFiltriContribuente()

            pratica.versamenti = []
            pratica.rate = []

            ruoloCoattivo = liquidazioniAccertamentiService.inRuoloCoattivo(pratica)
            // La pratica non è a ruolo oppure è a ruolo ed il ruolo è stato inviato
            ruoloInviato = ruoloCoattivo == null ||
                    (ruoloCoattivo != null &&
                            ruoloCoattivo.invioConsorzio != null)

            sgraviAttivi =
                    ruoloCoattivo?.invioConsorzio != null
        } else {
            TipoTributoDTO tipoTributoDto = TipoTributo.get(tt)?.toDTO()
            if (tipoTributoDto == null) {
                throw new Exception("Tipo Tributo non impostato")
            }
            tipoTributoAttuale = tt

            pratica = new PraticaTributoDTO()
            pratica.tipoCarica = new TipoCaricaDTO()
            pratica.contribuente = new ContribuenteDTO()
            pratica.anno = Calendar.getInstance().get(Calendar.YEAR)
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            pratica.data = sdf.parse(sdf.format(new Date()))

            pratica.tipoTributo = tipoTributoDto
            pratica.tipoPratica = tp
            pratica.tipoEvento = TipoEventoDenuncia."${te}"

            if (tp == TipoPratica.A.tipoPratica) {
                pratica.tipoCalcolo = 'N'
            }

            pratica.versamenti = []
            pratica.sanzioniPratica = []
            pratica.rate = []
            pratica.iter = []

            onApriMascheraRicercaSoggetto()
        }

        if ((situazione == 'accManImu') && (tipoTributoAttuale != 'ICI')) {
            situazione = 'accManImuUnica'
            // Il visualizzatore accManImu al momento non gestisce la TASI, quindi attiviamo la vecchia visualizzazione unica
        }

        if (situazione in ['accManImu', 'accManTari']) {
            String special = pratica.note ?: ''
            if (special.startsWith('VIS_UNICA')) {
                situazione += 'Unica'
                // Trucchetto per attivare la vecchia visualizzazione unica
            }
        }

        tipoVersamentoTestataOrig = pratica.tipoEvento.tipoEventoDenuncia
        tipoVersamentoRavv = pratica.tipoEvento.tipoEventoDenuncia
        rataRavv = pratica.tipoEvento.tipoEventoDenuncia

        vecchioNumero = pratica.numero

        if (pratica.id) {
            // 	Se in ruolo coattivo non è modificabile
            aRuolo = liquidazioniAccertamentiService.inRuoloCoattivo(pratica.toDomain())
        }
        lettura = lt

        tipo = situazione in ["liquidazione", "ravvImu", "ravvTasi", "ravvTari"] ? "liqRavv" : situazione
        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        contribuente = pratica.contribuente
        tipoPratica = pratica.tipoPratica
        tipoRavvedimento = pratica.tipoRavvedimento

        aggiornaFlagCalcoloNormalizzato()

        tipoTributoAttualeDescr = pratica.tipoTributo.getTipoTributoAttuale(pratica.anno)
        switch (situazione) {
            case ["liquidazione", "accManImu", "accTotImu", "accManImuUnica", "ravvImu"]:
                title = listaTitoli[situazione].replace('IMU', tipoTributoAttualeDescr)
                break
            case ["accManTari", "accAutoTari", "accTotTari", "accManTariUnica"]:
                title = listaTitoli[situazione].replace('TARI', tipoTributoAttualeDescr)
                break
            case ["accManTribMin", "accAutoTribMin", "accTotTribMin", "ravvTribMin", "solAutoTribMin"]:
                title = listaTitoli[situazione].replace('TRIB_MIN', tipoTributoAttualeDescr)
                break
            default:
                title = listaTitoli[situazione]
        }

        listaTipiStato = OggettiCache.TIPI_STATO.valore.sort { it.descrizione }
        listaTipiStato = [new TipoStatoDTO([tipoStato: '', descrizione: ''])] + listaTipiStato


        // TODO - Tipo Atto Rateizzato da gestire con la #62142.
        if (pratica.tipoPratica in ['S', 'V']) {
            listaTipiAtto = OggettiCache.TIPI_ATTO.valore.sort { it.tipoAtto }
                    .findAll { it.tipoAtto != 90 }
        } else {

            listaTipiAtto = OggettiCache.TIPI_ATTO.valore.sort { it.tipoAtto }
        }

        listaTipiAtto = [new TipoAttoDTO([tipoAtto: -1, descrizione: ''])] + listaTipiAtto

        listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll {
            it.tipoTributo.tipoTributo == pratica.tipoTributo.tipoTributo && pratica.anno in it.aliquote.anno
        }
        listaTipiAliquotaAP = OggettiCache.TIPI_ALIQUOTA.valore.findAll {
            it.tipoTributo.tipoTributo == pratica.tipoTributo.tipoTributo && (short) (pratica.anno - 1) in it.aliquote.anno
        }

        sistemaRateazione()

        caricaOggetti(tipo)
        caricaRuoli(tipo)

        elencoMotivi = liquidazioniAccertamentiService.elencoMotivazioni(pratica.tipoTributo.tipoTributo, pratica.tipoPratica, pratica.anno)

        caricaSanzioni()

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        controllaIuv()

        abilitaGeneraF24 = pratica.tipoTributo.tipoTributo != 'CUNI'

        listaTipiNotifica = [null] + liquidazioniAccertamentiService.getTipiNotifica()

        // TODO - pratica.tipoNotifica non restituisce correttamente i dati (descrizione e flagModificabile entrambi a null quando invece non lo dovrebbero essere)
        pratica.tipoNotifica = listaTipiNotifica.find {
            it?.tipoNotifica == pratica.tipoNotifica?.tipoNotifica
        }

        rate = rateazioneService.elencoRate(pratica).toDTO(['pratica'])

        inizializzazionePratica()
        refreshElenchiOggetti()
        verificaOggettiAccMan()
        calcolaDisabilitaDataNotificaSuRateazione()
    }

    @Command
    public void updateClientInfo() {

        self.invalidate()
    }

    @AfterCompose
    def afterInit() {

        isDirty = pratica.id == null
        isDirtySanzioni = false
        isDirtyVersamenti = false
        isDirtyOggetti = false
        isDirtyIter = false
        isDirtyRateazione = false

        def props = [
                'sanzioni', 'versamenti', 'oggettiImu', 'iter',
                // Rateazioni
                'numeroRata',
                "dataRateazione",
                'interessiMora',
                'tipologia',
                'calcoloRate',
                'intRateSoloEvasa',
                'oneriRiscossione'
        ]
        def classes = [
                PraticaTributoDTO,
                SanzionePraticaDTO,
                VersamentoDTO,
                ParametriRateazione,
                RataPraticaDTO
        ]
        eventIsDirty = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {

                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    def prop = ((PropertyChangeEvent) event).property

                    // println prop
                    // println pe.base.class

                    if (!(pe.base.class in classes) &&
                            !(prop in props)) {
                        return
                    }

                    // Modifiche alla testata
                    if (!isDirty && pe.base instanceof PraticaTributoDTO) {
                        // log.info "Modificata proprietà [$prop] della testata"
                        isDirty = true

                        // Attività da eseguire sul primo cambio della data di notifica
                        aggiornaModificaOggetti()
                        comandiSanzioniPratica()

                        notificaIsDirty()

                        return
                    }

                    // Sanzioni: se si modifica un elemento della lsita o la lista (aggiunta/clonazione/eliminazione)
                    if (pe.base instanceof SanzionePraticaDTO || prop == "sanzioni") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtySanzioni && !inizializzazioneSanzioni) {
                            // log.info "[Sanzioni] Modificata proprietà [$prop]"
                            isDirtySanzioni = true
                            notificaIsDirty()
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (prop == "sanzioni" && inizializzazioneSanzioni) {
                            inizializzazioneSanzioni = false
                        }

                        calcolaTotaliSanzioni(false)

                        return
                    }

                    // Versamenti: se si modifica un elemento della lsita o la lista (aggiunta/clonazione/eliminazione)
                    if (pe.base instanceof VersamentoDTO || prop == "versamenti") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtyVersamenti && !inizializzazioneVersamenti) {
                            // log.info "[Versamenti] Modificata proprietà [$prop]"
                            isDirtyVersamenti = true
                            notificaIsDirty()
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (prop == "versamenti" && inizializzazioneVersamenti) {
                            inizializzazioneVersamenti = false
                        }

                        return
                    }

                    // Oggetti IMU: se si modifica un elemento della lsita o la lista (aggiunta/clonazione/eliminazione)
                    if (prop == "oggettiImu" || prop == "oggettiAccManuale") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtyOggetti && !inizializzazioneOggetti) {
                            // log.info "[OggettiImu] Modificata proprietà [$prop]"
                            isDirtyOggetti = true
                            notificaIsDirty()
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (inizializzazioneOggetti) {
                            inizializzazioneOggetti = false
                        }

                        return
                    }

                    // Iter: se si modifica un elemento della lsita o la lista (aggiunta/clonazione/eliminazione)
                    if (prop == "iter") {

                        // Se si sta inizializzando la lista non si considera modificata
                        if (!isDirtyIter && !inizializzazioneIter) {
                            // log.info "[Iter] Modificata proprietà [$prop]"
                            isDirtyIter = true
                            notificaIsDirty()
                        }

                        // Se si sta inizializzando la lista si annulla il flag per intercettare le
                        // successive modifiche
                        if (inizializzazioneIter) {
                            inizializzazioneIter = false
                        }

                        return
                    }

                    // Ratezione
                    if (pe.base instanceof ParametriRateazione ||
                            pe.base instanceof RataPraticaDTO) {
                        if (!isDirtyRateazione) {
                            isDirtyRateazione = true
                            notificaIsDirty()
                        }
                    }
                }
            }
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(eventIsDirty)
    }

    @Command
    def notificaIsDirty() {

        comandiSanzioniPratica()
        BindUtils.postNotifyChange(null, null, this, "sanzioniLettura")
        BindUtils.postNotifyChange(null, null, this, "versamentiLettura")
        BindUtils.postNotifyChange(null, null, this, "oggettiLettura")
        BindUtils.postNotifyChange(null, null, this, "frontespizioLettura")
        BindUtils.postNotifyChange(null, null, this, "iterLettura")
        BindUtils.postNotifyChange(null, null, this, "rateazioneLettura")
    }

    @NotifyChange(["dichiaratoAccManTotImu", "liquidatoAccManTotImu", "accertatoAccManTotImu", "accertatoAccManTari", "dic", "liq", "acc"])
    @Command
    onGetDicLiqAcc() {

        def codFiscale = pratica.contribuente.codFiscale
        Long praticaId = oggettoSelezionato?.pratica?.id ?: -1
        def tipoOggetto = oggettoSelezionato?.tipoOggetto?.tipoOggetto

        if (situazione == "accTotImu") {
            dichiaratoAccManTotImu = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTotaleImu(praticaId, codFiscale, pratica.anno, tipoOggetto)
            liquidatoAccManTotImu = liquidazioniAccertamentiService.getLiquidatoAccertamentoManualeTotaleImu(praticaId, codFiscale, pratica.anno)
            accertatoAccManTotImu = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTotaleImu(praticaId, codFiscale, pratica.anno, accertamento)

            dic = !dichiaratoAccManTotImu.empty
            liq = liquidatoAccManTotImu != null
            acc = !accertatoAccManTotImu.empty
        } else if (situazione == "accTotTari") {
            dichiaratoAccManTari = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTari(praticaId, codFiscale, pratica.anno)
            accertatoAccManTari = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTari(praticaId, codFiscale, pratica.anno)

            dic = !dichiaratoAccManTari.empty
            acc = !accertatoAccManTari.empty
        }
    }

    @Command
    onChiudi() {
        if (_modificheIncorso()) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
            Messagebox.show("Salvare le modifiche?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    def esitoPositivo = onSalvaPratica()
                                    if (esitoPositivo) {
                                        chiudi()
                                    }
                                    break
                                case Messagebox.ON_NO:
                                    chiudi()
                                    break
                                case Messagebox.ON_CANCEL:
                                    return
                            }
                        }
                    }, params)
        } else {
            chiudi()
        }
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        // Se si è in modifica in una delle tab, non si permette il cambio tab
        if (_modificheIncorso()) {
            Clients.showNotification("Salvare prima le modifiche in corso.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 2000, true)

            tbInfoTabBox.selectedTab = tbInfoTabBox.tabs.children.find { it.id == selectedTabId }

            return
        }

        switch (tabId) {
            case "ruoli":
                caricaRuoli(tipo)
                break
            case "oggetti":
                caricaOggetti(tipo)
                break
            case "localiEdAree":
                break
            case "canoni":
                break
            case "sanzioni":
                if (!sanzioniCaricate) {
                    caricaSanzioniPratica()
                }
                break
            case "iter":
                caricaIter()
                break
            case "rateazione":

                popolaRateazione()

                caricaVersamenti()
                /// Usiamo il numero non una combo vista l'enorme variabilità del numero rate (48 su SVI)
                if (rate.size > 0) {
                    numeroRate = (1..rate.size)
                } else {
                    numeroRate = [0]
                }
                BindUtils.postNotifyChange(null, null, this, "numeroRate")
                break
            case "versamenti":
                if (!rate) {
                    popolaRateazione()
                }
                /// Usiamo il numero non una combo vista l'enorme variabilità del numero rate (48 su SVI)
                numeroRate = [null] + 0
                if (rate.size > 0) numeroRate += (1..rate.size)
                BindUtils.postNotifyChange(null, null, this, "numeroRate")
                caricaVersamenti()
                break
        }

        this.selectedTabId = tabId
        caricaIndici()
        BindUtils.postNotifyChange(null, null, this, "selectedTabId")
    }

    @Command
    def onApriMascheraRicercaSoggetto() {

        if (soggetto != null && soggetto != "") {
            setSelectCodFiscaleCon(soggetto)
            return
        }

        commonService.creaPopup("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Soggetto") {
                            setSelectCodFiscaleCon(event.data.Soggetto)
                        }
                    }
                })
    }

    @Command
    onModificaSanzione(@BindingParam("sanz") def sanz) {
        commonService.creaPopup(
                "/pratiche/sceltaSanzione.zul",
                self,
                [tipoTributo: pratica.tipoTributo, tipoPratica: pratica.tipoPratica, sanzioneSelezionata: sanz.sanzione],
        ) { e ->
            if (e.data?.sanzioneSelezionata != null) {
                // listaSanzioni.find { it == sanz.sanzione }.sanzione = e.data.sanzioneSelezionata
                sanz.sanzione = e.data.sanzioneSelezionata
                onCambiaSanzione(sanz)
                BindUtils.postNotifyChange(null, null, sanz, "sanzione")
            }

        }
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    onApriMotivo(@BindingParam("arg") def motivo) {
        Messagebox.show(motivo, "Motivo", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    onVisualizzaNote(@BindingParam("popup") Component popupStatoJob, @BindingParam("note") String note) {

        notePerPopup = note.replaceAll(" - ", "\n")
        BindUtils.postNotifyChange(null, null, this, "notePerPopup")

        popupStatoJob.open(self, "after_pointer")
    }

    @Command
    def onRefreshOggettiLiqRavv() {

        caricaOggetti("liqRavv")
        refreshElenchiOggetti()
    }

    @Command
    def onRefreshOggetti() {

        refreshElenchiOggetti()
    }

    @Command
    def onSelezionaOggAccMan() {

        selezionatoOgettoAccMan()
    }

    @Command
    def onAggiungiOggAccMan() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        def ted = pratica.tipoEvento

        if (ted in [TipoEventoDenuncia.I, TipoEventoDenuncia.U]) {

            if ((!oggettiAccManuale.empty) && (dichiaratoAccManImu.empty)) {
                onAggiungiOggAccManPerOmessa()
            } else {
                onAggiungiOggAccManPerInfedele()
            }
        } else {
            throw new Exception("Funzione non implementata")
        }
    }

    @Command
    def onAggiungiOggAccManPerOmessa() {

        salvaPraticaSeDirty(false)

        oggettoSelezionato = null

        oggAccManDaEsistenti()

        gestioneTipoViolazione()
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    @Command
    def onAggiungiOggAccManPerInfedele() {

        salvaPraticaSeDirty(false)

        ricercaOggAccManAccertabili()

        gestioneTipoViolazione()
    }

    @Command
    def onModificaOggAccMan() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        apriOggettoAccMan(-1)
    }

    @Command
    def onEliminaOggLiqRavv() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        OggettoContribuenteDTO oggCo = oggettoSelezionato.oggettiContribuente[0]
        Long oggId = oggCo.oggettoPratica.oggetto.id

        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        String message = "L'oggetto " + oggId + " verrà eliminato. Proseguire?"
        Messagebox.show(message, "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new EventListener() {
                    void onEvent(Event e) {
                        if (e.getName() == Messagebox.ON_YES) {
                            eliminaOggCoLiqRavvCheck(oggCo)
                        }
                    }
                }
        )
    }

    @Command
    def onEliminaOggAccMan() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        eliminaOggettoAccManSingolo(oggettoSelezionato.dto)
    }

    @Command
    def onApriArea() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        caricaSanzioniPratica(false)
        aggiornaModificaOggetti()

        notificaPresenzaSanzioni()

        apriLocaleEdArea(oggettoSelezionato?.dto)
    }

    @Command
    def onAggiungiArea() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        def ted = pratica.tipoEvento

        if (ted in [TipoEventoDenuncia.I, TipoEventoDenuncia.U]) {

            if ((oggettiAccManuale.size() > 0) && (dichiaratoAccManTari.size() == 0)) {
                onAggiungiAreaPerOmessa()
            } else {
                onAggiungiAreaPerInfedele()
            }
        } else {
            if (ted in [TipoEventoDenuncia.V, TipoEventoDenuncia.C]) {
                ricercaUtenzeTRDaCessati()
            }
        }
    }

    @Command
    def onAggiungiAreaPerOmessa() {

        salvaPraticaSeDirty(false)

        String messaggio = "Inserimento da altro contribuente cessato?"
        Messagebox.show(messaggio, "Locali ed Aree", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            ricercaUtenzeTRDaCessati()
                        } else {
                            localeEdAreaDaEsistenti('automatico')
                        }
                    }
                }
        )
    }

    @Command
    def onAggiungiAreaPerInfedele() {

        salvaPraticaSeDirty(false)

        ricercaUtenzeTRAccertabili()
    }

    @Command
    def onEliminaArea() {

        if (!notificaModifichePerOggetti()) {
            return
        }

        Messagebox.show("Eliminare il quadro?", "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaLocaleEdArea()
                        }
                    }
                }
        )
    }

    @Command
    def onCheckTipoCalcolo() {

        if (_modificheIncorso()) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Prima di procedere e' necessario salvare le modifiche.\n\nSi desidera procedere?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    def esitoPositivo = onSalvaPratica()
                                    if (esitoPositivo) {
                                        applicaTipoCalcolo()
                                    }
                                    break
                                case Messagebox.ON_NO:
                                    aggiornaFlagCalcoloNormalizzato()
                                    break
                            }
                        }
                    }, params)
        } else {
            applicaTipoCalcolo()
        }
    }

    @Command
    def onCheckFlagTardivo() {

    }

    @Command
    def onCheckFlagDenuncia() {
        if (!pratica.flagDenuncia && situazione == "accManImu") {

            boolean somePera = oggettiAccManuale.any {
                def ogco = it.dto
                return ogco.flagPossesso || ogco.flagEsclusione || ogco.flagRiduzione || ogco.flagAbPrincipale
            }

            if (somePera) {
                def msg = 'Togliendo il Flag Denuncia, saranno tolti anche i Flag di Possesso, Esclusione, Riduzione, Abitazione Principale inseriti sugli oggetti dell\'accertamento.'
                Map params = new HashMap()
                Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
                Messagebox.show(msg, "Attenzione", buttons, null, Messagebox.QUESTION, null,
                        new EventListener() {
                            void onEvent(Event e) {
                                switch (e.getName()) {
                                    case Messagebox.ON_YES:
                                        if (onSalvaPratica()) { // Salvo frontespizio
                                            oggettiAccManuale.each {
                                                def ogco = it.dto
                                                ogco.flagPossesso = false
                                                ogco.flagEsclusione = false
                                                ogco.flagRiduzione = false
                                                ogco.flagAbPrincipale = false
                                            }
                                            salvaOggetti()
                                            refreshElenchiOggetti()
                                        }
                                        break
                                    case Messagebox.ON_NO:
                                        pratica.flagDenuncia = !pratica.flagDenuncia
                                        refreshPratica()
                                        break
                                }
                            }
                        }, params)
            }
        }
    }

    @Command
    def onApriDichiarato(@BindingParam("event") def event) {

        OpenEvent evt = (OpenEvent) event
        aggiornaQuadroDichiarato(evt.isOpen())
    }

    @Command
    def onCalcolaAccertamento() {

        if (pratica.id &&
                (!pratica.dataNotifica || (pratica.tipoStato?.tipoStato ?: 'D') != 'D')
                && !NotificaOggetto.findAllByPratica(pratica.toDomain()).isEmpty()) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
            Messagebox.show("Esistono delle Notifiche Oggetto con questa pratica. Si desidera Eliminarle?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    calcolaAccertamentoUI(false)
                                    break
                                case Messagebox.ON_NO:
                                    calcolaAccertamentoUI(false, false)
                                    break
                                case Messagebox.CANCEL:
                                    return
                            }
                        }
                    }, params)
        } else {
            calcolaAccertamentoUI(false)
        }
    }

    @Command
    def onReplicaPerAnniSuccessivi() {

        if (_modificheIncorso()) {
            Clients.showNotification("Salvare prima le modifiche in corso.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 2000, true)
            return
        }

        Long praticaId = pratica.id

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
                        aggiornaStato = true
                    }
                }
        )
    }

    @Command
    def onCalcolaSanzioni() {
        calcolaAccertamentoUI(true)
    }

    @Command
    def onAggiornamentoCanoni() {

        onAggiornamentoImmobili()
    }

    @Command
    def onRefreshCanoni() {

        refreshElenchiOggetti()
    }

    @Command
    def onNuovoCanone() {

        modificaCanone(null, true)
    }

    @Command
    def onModificaCanone() {

        modificaCanone(canoneSelezionato)
    }

    @Command
    onCancellaVersamento(@BindingParam("vers") def versamento) {

        String messaggio = "Eliminare il versamento?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaVersamento(versamento)
                        }
                    }
                }
        )
    }

    @Command
    onAggiungiVersamento() {

        isNuovoVersamento = true

        def rataProposta = null
        // Se siamo sulla tab delle rateazioni si propone la prima rata disponibile
        if (selectedTabId == 'rateazione') {
            def ultimaRata = versamenti.max { it.rata }?.rata ?: 0
            rataProposta = (ultimaRata < rate.size) ? (ultimaRata + 1) : ultimaRata
        }

        /// I tributi parzializzati per rate (0,1,2,3,4) usano tipo U poi si lavora su rata
        def tipoVersamento = pratica.tipoEvento.tipoEventoDenuncia in ['T', 'A', '0', '1', '2', '3', '4'] ? 'U' :
                pratica.tipoEvento.tipoEventoDenuncia

        versamenti.add(
                new VersamentoDTO([
                        tipoVersamento: tipoVersamento,
                        dataReg       : new Date(),
                        contribuente  : contribuente,
                        anno          : pratica.anno,
                        pratica       : pratica,
                        tipoTributo   : pratica.tipoTributo,
                        rata          : rataProposta,
                        fonte         : listaFonti.find { it.fonte == 6 },
                        nuovo         : true
                ])
        )

        self.width = "1"
        self.width = "100%"

        invalidaGridVersamenti()
        caricaVersamenti()

        BindUtils.postNotifyChange(null, null, this, "versamenti")
    }

    @Command
    def onCambiaSanzione(@BindingParam("sanz") def sanz) {

        def message = modificaSanzione(sanz, "sanz")

        if (!message.empty) {
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        invalidaGridSanzioni()
        calcolaTotaliSanzioni(false)

        BindUtils.postNotifyChange(null, null, this, "sanzioni")
        BindUtils.postNotifyChange(null, null, this, "sanzioniModifica")
    }

    @Command
    onAggiungiSanzione(@BindingParam("grid") def grid) {

        def nuovaSanzione = new SanzionePraticaDTO([sanzione: new SanzioneDTO([tipoTributo: pratica.tipoTributo]), pratica: pratica])

        sanzioni.add(nuovaSanzione)

        // Se la sanzione è nuova la sanzione minima su riduzione viene gestita correttamente, quindi la lasciamo modificabile
        sanzioniModifica[nuovaSanzione.toString()] = liquidazioniAccertamentiService.modificheSanzioni(this.lettura, null, pratica.dataNotifica, true, false)

        invalidaGridSanzioni()

        aggiornaModificaOggetti()

        BindUtils.postNotifyChange(null, null, this, "sanzioni")
        BindUtils.postNotifyChange(null, null, this, "sanzioniModifica")
    }

    @Command
    onCancellaTutteSanzioni() {

        String messaggio = "Eliminare tutte le sanzioni?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaSanzioni()
                        }
                    }
                }
        )
    }

    @Command
    onCancellaSanzione(@BindingParam("sanz") def sanzione) {
        String messaggio = "Eliminare la sanzione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaSanzione(sanzione)
                        }
                    }
                }
        )
    }

    @Command
    onDuplicaSanzione(@BindingParam("sanz") def sanzione) {
        def nuovaSanzione = new SanzionePraticaDTO()
        InvokerHelper.setProperties(nuovaSanzione, sanzione.properties)

        sanzioni.add(nuovaSanzione)

        /// Se la sanzione è nuova la sanzione minima su riduzione viene gestita correttamente, quindi la lasciamo modificabile
        sanzioniModifica[nuovaSanzione.toString()] = liquidazioniAccertamentiService.modificheSanzioni(this.lettura, null, pratica.dataNotifica, true, false)

        invalidaGridSanzioni()

        calcolaTotaliSanzioni(false)

        BindUtils.postNotifyChange(null, null, this, "sanzioniModifica")
        BindUtils.postNotifyChange(null, null, this, "sanzioni")
    }

    @Command
    onCambiaImportoSanzione(@BindingParam("sanz") def sanzione) {

        def message = modificaSanzione(sanzione, "imp")

        if (!message.empty) {
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    @Command
    onCambiaPercentualeSanzione(@BindingParam("sanz") def sanzione) {

        def message = modificaSanzione(sanzione, "perc")

        if (!message.empty) {
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    private modificaSanzione(def sanzione, def tipoModifica) {

        /// Si recupera la sanzione priciplae, quelle con tipo_causale == 'E' dello spesso periodo della sanzione
        def listSanzPrinc = sanzioni.findAll { it.sanzione.tipoCausale == 'E' }

        /// Per ICI/IMU e TASI prendiamo il tipo_versamento, per gli altri rata

        if (tipoTributoAttuale in ['ICI', 'TASI']) {
            String tipoVers = sanzione.sanzione.tipoVersamento ?: '-'
            listSanzPrinc = listSanzPrinc.findAll { (it.sanzione.tipoVersamento ?: '-') == tipoVers }
        } else {
            Short numRata = sanzione.sanzione.rata ?: 0
            listSanzPrinc = listSanzPrinc.findAll { (it.sanzione.rata ?: 0) == numRata }
        }

        def sanzPrinc = (listSanzPrinc.sum { it.importoTotale ?: 0 } ?: 0)

        def perc = sanzione?.sanzione?.percentuale
        def imp = sanzione?.sanzione?.sanzione
        def rid = sanzione?.sanzione?.riduzione

        def message = ""
        def sanzioneOld = controlloSanzioni[sanzione.toString()]
        def importo = sanzione.importo
        def sanzioneMinima

        def cata = pratica.tipoTributo.tipoTributo == 'TARSU' ? CaricoTarsu.findByAnno(pratica.anno) : null

        switch (tipoModifica) {
            case 'sanz':
                if (sanzione.sanzione.codSanzione in [888 as short, 889 as short]) {
                    sanzione.sanzione = sanzioneOld?.sanzione
                    message = "Le Sanzioni di arrotondamento per conversione Euro non sono inseribili"
                } else {
                    sanzione.importo = (imp ?: (sanzPrinc * (perc ?: 0)) / 100).setScale(2, RoundingMode.HALF_UP)
                    sanzione.percentuale = perc
                    sanzione.riduzione = rid

                    sanzioneMinima = sanzione.sanzione.sanzioneMinima ?: 0
                    if ((sanzioneMinima) && (sanzioneMinima > sanzione.importo)) {
                        def numFormat = new DecimalFormat("##,##0.00")
                        sanzione.note = 'Sanzione minima - Totale sanzioni orig. ' + numFormat.format(sanzione.importo)
                        sanzione.importo = sanzioneMinima
                    }
                }
                break
            case ['perc', 'imp']:
                // Modifica di sanzione per ACC Automatici TARSU
                if (sanzioneOld) {
                    if (tipoModifica == 'imp') {
                        if (sanzioneOld.importo == null) {
                            message = "Impossibile modificare l'importo per questa sanzione"
                        }
                    } else if (tipoModifica == 'perc') {
                        if (sanzioneOld.percentuale == null) {
                            sanzione.percentuale = null
                            message = "Impossibile inserire percentuale per questa sanzione"
                        } else {
                            sanzione.importo = (sanzPrinc * (sanzione.percentuale ?: 0) / 100).setScale(2, RoundingMode.HALF_UP)
                        }
                    }
                } else {
                    sanzione.importo = (sanzPrinc * (sanzione.percentuale ?: 0) / 100).setScale(2, RoundingMode.HALF_UP)
                }
                break
        }

        verificaSanzMinSuRiduzione()

        liquidazioniAccertamentiService.calcoloImportoLordo(sanzione, tipoTributoAttuale, this.sanzMinimaSuRid)

        BindUtils.postNotifyChange(null, null, this, "isDirtySanzioni")
        BindUtils.postNotifyChange(null, null, this, "sanzioni")
        return message
    }

    @Command
    def onDuplicaVersamento(@BindingParam("vers") def versamento) {
        def nuovoVersamento = new VersamentoDTO()
        InvokerHelper.setProperties(nuovoVersamento, versamento.properties)
        nuovoVersamento.sequenza = null
        nuovoVersamento.uuid = UUID.randomUUID().toString().replace('-', '')
        nuovoVersamento.nuovo = true
        nuovoVersamento.rata = null

        versamenti.add(nuovoVersamento)
        BindUtils.postNotifyChange(null, null, this, "versamenti")
    }

    @Command
    def onVersatoModificato(@BindingParam("vers") def versamento) {

        def importoVersato = Math.round(versamento.importoVersato)
        def importoTotale = 0
        def importoRidotto = 0

        if (situazione == 'ravvTari') {
            importoTotale = Math.round(totImportoLordo ?: 0)
            importoRidotto = Math.round(totImportoLordoRid ?: 0)
        } else {
            importoTotale = Math.round(pratica.importoTotale ?: 0)
        }

        if ((importoVersato != importoTotale) && (importoVersato != importoRidotto)) {
            String verboTipoPratica
            switch (pratica.tipoPratica) {
                default:
                    verboTipoPratica = "della Pratica"
                    break
                case TipoPratica.A.tipoPratica:
                    verboTipoPratica = "Accertato"
                    break
                case TipoPratica.L.tipoPratica:
                    verboTipoPratica = "Liquidato"
                    break
                case TipoPratica.V.tipoPratica:
                    verboTipoPratica = "Ravveduto"
                    break
            }
            Clients.showNotification("L'importo Versato è diverso da quello " + verboTipoPratica + " arrotondato.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    @Command
    def onRicalcolaSanzioni() {
        commonService.creaPopup("/pratiche/violazioni/creazioneRavvedimentoOperoso.zul", self,
                [pratica             : pratica.id,
                 calcoloSanzioni     : true,
                 tipoVersamento      : tipoVersamentoRavv,
                 cambioTipoVersamento: false,
                 presentiSanzioni    : !sanzioni.empty],
                { event ->
                    if (event.data) {
                        if (event.data.generateSanzioni) {
                            def praticaRef = PraticaTributo.get(pratica.id).refresh()
                            pratica.sanzioniPratica = praticaRef.sanzioniPratica.toDTO(["pratica", "sanzione"])
                            caricaSanzioniPratica(true)
                        }
                    }
                })
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(contribuente?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onTipoVersamentoModificato(@BindingParam("vers") def versamento) {

        // Versamento manuale, non si ricalcolano le sanzioni
        if (!oggettiImu.empty || !listaCanoni.empty) {
            return
        }

        Map params = new HashMap()
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        Messagebox.show("Le modifiche apportate al versamento verrano salvate e le sanzioni ricalcolate. Proseguire?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new EventListener() {
                    void onEvent(Event e) {

                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                try {
                                    liquidazioniAccertamentiService.cambiaTipoVersamentoRavvedimento(versamento, versamento.tipoVersamento)
                                    versamentiCaricati = false
                                    caricaVersamenti()
                                    caricaSanzioni()
                                    isNuovoVersamento = false
                                } catch (Exception ex) {
                                    if (ex instanceof Application20999Error) {
                                        Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                                        versamentiCaricati = false

                                        if (!isNuovoVersamento) {
                                            caricaVersamenti()
                                        }
                                    } else {
                                        throw ex
                                    }
                                }
                                break
                            case Messagebox.ON_NO:
                                versamentiCaricati = false
                                if (!isNuovoVersamento) {
                                    caricaVersamenti()
                                }
                                return
                        }
                    }
                }, params)
    }

    @Command
    def onTipoVersamentoTestataModificato() {

        if (versamenti.find { it.tipoVersamento != tipoVersamentoRavv } != null) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Esiste un versamento di tipo non coerente con il tipo versamento segnalato, si vuole proseguire?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    notificaRicalcoloSanzioni()
                                    break
                                case Messagebox.ON_NO:
                                    resetTipoVersamentoTestata()
                                    break
                            }
                        }
                    }, params)
        } else {
            notificaRicalcoloSanzioni()
        }

    }

    @Command
    onSalvaPratica() {

        // Fix #60032 se il tipo_violzione della pratica in Hibernate è null si riporta quello modificato dal trigger
        pratica.tipoViolazione = pratica.tipoViolazione ?: PraticaTributo.get(pratica.id)?.refresh()?.tipoViolazione

        def esitoPositivo = false

        if (pratica.id &&
                (!pratica.dataNotifica || (pratica.tipoStato?.tipoStato ?: 'D') != 'D')
                && !NotificaOggetto.findAllByPratica(pratica.toDomain()).isEmpty()) {

            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
            Messagebox.show("Esistono delle Notifiche Oggetto con questa pratica. Si desidera Eliminarle?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    { e ->
                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                esitoPositivo = salvaPratica()
                                break
                            case Messagebox.ON_NO:
                                esitoPositivo = salvaPratica(false)
                                break
                            case Messagebox.CANCEL:
                                return
                        }
                    }, params)
        } else {
            esitoPositivo = salvaPratica()
        }

        if (esitoPositivo) {
            Clients.showNotification("Salvataggio effettuato con successo", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 2000, true)
        }

        self.invalidate()

        calcolaDisabilitaDataNotificaSuRateazione()

        return esitoPositivo
    }

    @Command()
    def onCambiaNumero() {
        // Verifica del numero
        if (pratica.numero) {
            def p = PraticaTributo.findAllByTipoTributoAndTipoPraticaAndNumero(new TipoTributo([tipoTributo: pratica.tipoTributo.tipoTributo]), pratica.tipoPratica, pratica.numero)
            // Esiste un'altra pratica con lo stesso numero
            if (p && !p.find { it.id != pratica.id }.collect { it }.isEmpty()) {

                def messaggioPratiche = ""
                p.findAll {
                    it.id != pratica.id
                }.each {
                    messaggioPratiche += "Pratica: ${it.id}, Anno: ${it.anno}, Codice fiscale: ${it.contribuente.codFiscale}\n"
                }

                Map params = [:]
                params << ["width": 500]
                Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
                Messagebox.show("Esistono altre pratiche con lo stesso numero, tributo, tipo pratica:\n\n$messaggioPratiche\nContinuare?",
                        "Attenzione", buttons, null, Messagebox.QUESTION, null,
                        new EventListener() {
                            void onEvent(Event e) {
                                switch (e.getName()) {
                                    case Messagebox.ON_YES:
                                        break
                                    case Messagebox.ON_NO:
                                        pratica.numero = vecchioNumero
                                        BindUtils.postGlobalCommand(null, null, 'refreshPratica', null)
                                        break
                                }
                            }
                        }, params)
            }
        }
    }

    @Command
    onStampaF24Rate() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [
                        idDocumento: pratica.id,
                        codFiscale : pratica.contribuente.codFiscale])

        if (pratica.importoRate != null && OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == "RATE_F24_A" }?.valore == 'S') {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Gli importi verranno stampati senza arrotondamento. Si desidera proseguire?", "Attenzione", buttons, null, Messagebox.QUESTION, null, {
                if (Messagebox.ON_YES == it.name) {
                    modelliService.generaF24Rate(pratica, nomeFile)
                }
            }, params)
        } else {
            modelliService.generaF24Rate(pratica, nomeFile)
        }
    }

    @Command
    onF24Violazione() {

        if (pratica.tipoTributo.tipoTributo == 'TARSU' && !f24Service.checkF24Tarsu(pratica.id)) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Manca l'indicazione del Codice Tributo F24 nei dizionari delle Sanzioni! Si desidera proseguire?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    sceltaRidottoF24()
                                    break
                                case Messagebox.ON_NO:
                                    break
                            }
                        }
                    }, params)

        } else {
            sceltaRidottoF24()
        }
    }

    @Command
    onStampaAccoglimentoRateazione() {

        def nomeFile = "RAI_${(pratica.id as String).padLeft(10, "0")}_${pratica.contribuente.codFiscale.padLeft(16, " 0 ")}"

        def parametri = [
                tipoStampa : ModelliService.TipoStampa.ISTANZA_RATEAZIONE,
                idDocumento: pratica.id,
                nomeFile   : nomeFile,
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    @Command
    def onGeneraAvvisoAgidPratiche() {

        def avviso = modelliService.generaAvvisiAgidPratica(null, pratica.id)

        if (avviso instanceof String) {
            Clients.showNotification(avviso, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
        } else {
            String nomeFile = "avviso_agid_${pratica.contribuente.codFiscale}"
            def media = commonService.fileToAMedia(nomeFile, avviso)

            Filedownload.save(media)
        }
    }

    @Command
    onStampaAvvisoLiquidazione() {

        def nomeFile = "LIQ_" + (pratica.id as String).padLeft(10, "0") + "_" + pratica.contribuente.codFiscale.padLeft(16, "0")

        def parametri = [
                tipoStampa : ModelliService.TipoStampa.PRATICA,
                idDocumento: pratica.id,
                nomeFile   : nomeFile,
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    @Command
    onStampaAccertamento() {

        def tipoPrt = pratica.tipoPratica == 'A' ? "ACC" : "SOL"
        def nomeFile = "${tipoPrt}_${(pratica.id as String).padLeft(10, "0")}_${pratica.contribuente.codFiscale.padLeft(16, "0")}"

        def parametri = [
                tipoStampa : ModelliService.TipoStampa.PRATICA,
                idDocumento: pratica.id,
                nomeFile   : nomeFile,
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [parametri: parametri])
    }

    @Command
    def onInviaAppIO() {
        def tipoDocumento = documentaleService.recuperaTipoDocumento(pratica.id, 'P')
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(pratica.id, tipoDocumento)
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : pratica.contribuente.codFiscale,
                 tipoTributo      : pratica.tipoTributo,
                 tipoComunicazione: tipoComunicazione,
                 pratica          : pratica.id])
    }

    @Command
    def onOpenSgravio() {

        commonService.creaPopup("/ufficiotributi/imposte/ruoliOggettiSgravi.zul", self,
                [
                        ruolo       : ruoloCoattivo.id,
                        codFiscale  : contribuente.codFiscale,
                        praticaRuolo: pratica
                ],
                { event ->
                    Long praticaId = pratica.id ?: 0
                    if (praticaId) {
                        ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, 0, praticaId, cbSpecieRuolo)
                    } else {
                        ruoli = []
                    }

                    BindUtils.postNotifyChange(null, null, this, "ruoli")
                }
        )
    }

    @Command
    def onStampaPianoRimborso() {

        def reportDef = modelliService.generaPianoRateizzazione(pratica.id, parametriRateazione)
        def pianoRimborsoFile = jasperService.generateReport(reportDef)

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.PIANO_RIMBORSO,
                [idDocumento: pratica.id,
                 codFiscale : pratica.contribuente.codFiscale])

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, pianoRimborsoFile.toByteArray())
        Filedownload.save(amedia)
    }

    @NotifyChange(["pratica"])
    @GlobalCommand
    refreshPratica() {
        BindUtils.postNotifyChange(null, null, this, "pratica")
    }

    @Command
    onSelezionaRuoloVersamento(@BindingParam("lb") Listbox lb, @BindingParam("vers") def vers) {
        bdRuoliVersamento?.close()
        bdRuoliVersamento?.text = vers.ruolo.id
        lbRuoliVersamento = lb
    }

    @Command
    onSelezionaMotivo(@BindingParam("pu") Popup pu) {
        pu.close()
        pratica.motivo = motivoSelezionato.motivo
        BindUtils.postNotifyChange(null, null, this, "pratica")
    }

    @Command
    onCreateInfoTabbox(@BindingParam("tabbox") Tabbox tb) {

        tbInfoTabBox = tb

        if ((tipoPratica == TipoPratica.V.tipoPratica) && (tipoRavvedimento == 'V')) {

            tbInfoTabBox.setSelectedIndex(2)
            caricaSanzioniPratica(true)
        }
    }

    @Command
    onApriRuoloVersamento(@BindingParam("bd") Bandbox bd) {
        bdRuoliVersamento = bd
    }

    @Command
    onCambiaRuoloVersamento(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def v) {

        def vers = versamenti.find { it.uuid == v.uuid }
        if (!bd.text) {
            vers.ruolo = null

            if (!vers.nuovo) {
                vers.nuovo = true
            }

            if (!lbRuoliVersamento) {
                lbRuoliVersamento = (self.getFellow("datiLiqAcc")
                        .getFellow("folderVersamenti")
                        .getFellow("gridVersamenti")
                        .getFellow("lbRuoliVersamento${v.uuid}")
                )
            }

            lbRuoliVersamento.selectedItem = null
        } else {
            def ruolo = ruoliVersamento.find { it.id == bd.text }
            if (!ruolo) {
                vers.ruolo = null
                lbRuoliVersamento?.selectedItem = null
                Clients.showNotification("Ruolo non previsto.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                vers.ruolo = ruolo
            }
        }

        BindUtils.postNotifyChange(null, null, this, "vers")
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup

        def testo = popup?.children
                ?.find { it.class == Hlayout }?.children
                ?.find { it.class == Textbox }?.properties?.value

        // Il popup è stato aperto si registra il testo delle note
        if (popup.visible) {
            oldTestoNote = testo
        }

        // Se si chiude senza cliccare il bottone
        if (!popup.visible) {
            // Se ci sono state modifiche si notificano
            if (testo != oldTestoNote) {
                onChiudiPopupNote()
            }
            // Il popup è stato chiuso si resetta
            oldTestoNote = null
        }
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()

        switch (selectedTabId) {
            case 'versamenti':
                BindUtils.postNotifyChange(null, null, this, "versamenti")
                break
            case 'oggetti':
                BindUtils.postNotifyChange(null, null, this, "oggettiImu")
                break
            case 'iter':
                BindUtils.postNotifyChange(null, null, this, "iter")
                break
            default:
                throw new RuntimeException("Tab id [$selectedTabId] non riconosciuto.")

        }
    }

    @Command
    def onLockUnlockModificaSanzione(@BindingParam("sanz") def sanzione) {

        verificaSanzMinSuRiduzione()

        sanzioniModifica[(sanzione.toString())] =
                liquidazioniAccertamentiService.modificheSanzioni(this.lettura, sanzione.sanzione, pratica.dataNotifica,
                        !sanzioniModifica[(sanzione.toString())].modificheBloccate, this.sanzMinimaSuRid)

        BindUtils.postNotifyChange(null, null, this, "sanzioniModifica")
    }

    @Command
    def onCambiaDataNotifica() {
        // Le logiche sono state spostate nel metodo init nella parte di monitoraggio
        // delle modifiche al frontespizio. Se si cambia la data di notifica
        // il frontespizio diventa dirty ma a questo punto ha ancora il vecchio valore.
    }

    @Command
    def onCambiaTipoAtto() {
        self.invalidate()
    }

    @Command
    def onEliminaPratica() {

        if (pratica.tipoPratica == 'V' && pratica.tipoTributo.tipoTributo == 'CUNI' && pratica.flagDePag == 'S') {
            def message = "Impossibile eliminare il ravvedimento, sanzioni gia' inviate a PagoPA."
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        String messaggio = "Eliminare la pratica?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            if (eliminaPratica()) {
                                chiudi(true)
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onRateTabSelected(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        Tab tab = (Tab) ctx.getComponent()
        Tabpanel tabPanel = tab.linkedPanel

        BindUtils.postNotifyChange(null, null, this, "parametriRateazione")

        if (tabPanel != null) {
            tabPanel.invalidate()
        }
    }

    @Command
    def onRateizzaPratica() {

        impostaRateazione()

        if (!verificaRateazione()) {
            return
        }

        onSalvaPratica()

        try {
            pratica = rateazioneService.rateazione(pratica.id).refresh()
                    .toDTO(["contribuente.soggetto", "tipostato", "sanzioniPratica", "iter"])
            popolaRateazione()
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                throw e
            }
        }
    }

    @Command
    def onAnnullaDatiRateazione() {

        /*
            Si annullano i parametri della rateazione e si salva la pratica con i valori resettati quindi
            si esegue l'inizializzazione dei parametri per gestire i default e mostrarli a video.
         */

        parametriRateazione = new ParametriRateazione()
        impostaRateazione()

        liquidazioniAccertamentiService.salvaRateazionePratica(pratica)

        sistemaRateazione()
        popolaRateazione()

        praticaRateizzata = rateazioneService.praticaRateizzata(pratica.id ?: 0)
        BindUtils.postNotifyChange(null, null, this, "praticaRateizzata")

        // Si setta a false, perché non si vogliono salvare le informazioni sulla rateazione
        // cambiate solo per mostrale a video.
        isDirty = false
    }

    @Command
    def onChangeParametriRateazione() {
        if (parametriRateazione.dataRateazione) {
            parametriRateazione.versatoPreRateazione = rateazioneService.calcolaVersamentiPreRateazione(pratica.id, parametriRateazione.dataRateazione)
            parametriRateazione.tassoAnnuo = rateazioneService.tassoAnnuo(pratica.tipoTributo, parametriRateazione.dataRateazione)?.aliquota
        } else {
            parametriRateazione.versatoPreRateazione = null
        }

        if (parametriRateazione.numeroRata == 1) {
            parametriRateazione.tipologia = 'M'
        }

        BindUtils.postNotifyChange(null, null, this, "parametriRateazione")
    }

    @Command
    def onEliminaRate() {
        Map params = new HashMap()
        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        Messagebox.show("Eliminare le rate?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                new EventListener() {
                    void onEvent(Event e) {
                        switch (e.getName()) {
                            case Messagebox.ON_YES:
                                rate.clear()
                                pratica.importoRate = null
                                isDirtyRateazione = true
                                onSalvaPratica()
                                popolaRateazione()
                                break
                            case Messagebox.CANCEL:
                                return
                        }
                    }
                }, params)
    }

    @Command
    def onExportRateXls() {

        String calcoloRate = pratica?.calcoloRate

        Map fields = [
                "rata"         : "Rata",
                "dataScadenza" : "Scadenza",
                "flagSospFerie": "S.F."
        ]

        if (calcoloRate != null) {
            fields = fields + [
                    "importo"       : "Imp. Rata",
                    "importoArr"    : "Imp. Rata. Arr",
                    "recuperoPagata": "Pag."
            ]

            if (pratica.flagIntRateSoloEvasa) {
                fields = fields + [
                        "oneri": "Sanzioni Acc.",
                ]
            }

            fields = fields + [
                    "importoTotLiq": "Importo Tot. Liq.",
                    "giorniAggio"  : "Giorni Oneri di Ris.",
                    "aliquotaAggio": "Aliquota Oneri di Ris",
                    "aggio"        : "Importo Oneri di Ris",
            ]
            if (calcoloRate == 'C') {
                fields = fields + [
                        "aggioRimodulato": "Imp. Rim. Oneri di Ris",    // Aggio rimodulato solo per 'C'
                ]
            }

            if (pratica.flagIntRateSoloEvasa) {
                fields = fields + [
                        "quotaTassaRes": "Imposta Int. Dil."
                ]
            } else {
                fields = fields + [
                        "quotaTassaRes": "Importo Tot. Liq."
                ]
            }

            if (pratica.tipoTributo.tipoTributo == "TARSU" && pratica.flagIntRateSoloEvasa) {
                fields = fields + ["quotaTefa": "TEFA"]
            }

            fields = fields + [
                    "giorniDilazione"  : "Giorni Int. Dil.",
                    "aliquotaDilazione": "Aliquota Int. Dil.",
                    "dilazione"        : "Importo Int. Dil.",
            ]
            if (calcoloRate != 'V') {
                fields = fields + [
                        "dilazioneRimodulata": "Imp. Rim. Int. Dil."    // Dialzione rimodulata solo per 'C' e 'R'
                ]
            }
        } else {
            fields = fields + [
                    "importoRata"        : "Imp.Rata",
                    "pagata"             : "Pag.",

                    "importoCapitale"    : "Quota Capitale",
                    "tributoCapitaleF24" : "Tributo Capitale",
                    "residuoCapitale"    : "Residuo Capitale",

                    "importoInteressi"   : "Quota Interessi",
                    "tributoInteressiF24": "Tributo Interessi",
                    "residuoInteressi"   : "Residuo Interessi",
            ]
        }

        def converters = [
                recuperoPagata: { r ->
                    !Versamento.createCriteria().list {
                        eq('pratica.id', r.pratica.id)
                        eq('tipoTributo.tipoTributo', r.pratica.tipoTributo.tipoTributo)
                        eq('rata', r.rata as short)

                    }.empty ? 'S' : 'N'
                },
                importoRata   : { row ->
                    (row.importoCapitale ?: 0) + (row.importoInteressi ?: 0) + ((row.aggioRimodulato ? row.aggioRimodulato : row.aggio) ?: 0) +
                            ((row.dilazioneRimodulata ? row.dilazioneRimodulata : row.dilazione) ?: 0)
                },
                importoTotLiq : { row -> (row.importoCapitale + (row.oneri == null ? 0.0 : row.oneri)) },
                quotaTassaRes : { row -> pratica.flagIntRateSoloEvasa ? row.quotaTassa : ((row.importoCapitale != null ? row.importoCapitale : 0) + (row.oneri != null ? row.oneri : 0)) },
                flagSospFerie : Converters.flagString
        ]


        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                pratica.tipoPratica == "A" ? FileNameGenerator.GENERATORS_TITLES.ACC : FileNameGenerator.GENERATORS_TITLES.LIQ,
                [
                        idPratica : pratica.id,
                        codFiscale: pratica.contribuente.soggetto.codFiscale ?: pratica.contribuente.soggetto.partitaIva
                ])

        XlsxExporter.exportAndDownload(nomeFile, rate, fields, converters)
    }

    @Command
    def onNumeraPratica() {
        pratica.numero = liquidazioniAccertamentiService.numeraPratica(pratica).numero
        abilitaStampa()
        aggiornaStato = true
        BindUtils.postNotifyChange(null, null, this, "pratica")
        isDirty = true
    }

    @Command
    def onDetAlOg(@BindingParam("ogg") def ogg) {

        // Abilitato solo per il ravvedimento
        if (tipoPratica != TipoPratica.V.tipoPratica) {
            return
        }

        commonService.creaPopup("/pratiche/detAlOg.zul", self,
                [
                        "idOggPr"   : ogg.id,
                        "codFiscale": pratica.contribuente.codFiscale
                ],
                { e ->
                    if (e?.data?.salvato) {

                        ricalcolaImpostaESanzioni()
                    }
                })
    }

    @Command
    def onAggiornamentoImmobili() {
        String message = liquidazioniAccertamentiService.checkAggImmRavv(pratica.id)

        if ((message != null) && (!message.isEmpty())) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show(message + "\nProcedere?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    aggiornamentoImmobili()
                                    break
                                case Messagebox.ON_NO:
                                    return
                            }
                        }
                    }, params)
        } else {
            aggiornamentoImmobili()
        }
    }

    @Command
    def onApriStampa() {

        def debiti = []
        def crediti = []

        def idPratica = pratica.pratica

        def abilitaAgID = iuvValorizzato
        def abilitaF24 = abilitaGeneraF24 && !(pratica.anno < 2012 && pratica.tipoTributo.tipoTributo == 'ICI')

        if (ravvTariSuRuoli) {
            debiti = liquidazioniAccertamentiService.getDettagliRuoliDaRavvedimento(idPratica)
            crediti = liquidazioniAccertamentiService.getCreditiDaRavvedimento(idPratica)
        }

        commonService.creaPopup("/pratiche/dettaglioStampe.zul", self,
                [
                        pratica          : pratica,
                        listaCanoni      : listaCanoni,
                        oggettiImu       : oggettiImu,
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
    def onSelezionaPraticaDiPraticaTotale() {
        def tipoTributo = pratica.tipoTributo.tipoTributo
        def tipoPratica = praticaDiPraticaTotaleSelezionata.tipoPratica
        def tipoEvento = pratica.tipoTributo.tipoTributo in ['ICI', 'TASI'] ? praticaDiPraticaTotaleSelezionata.tipoEvento.tipoEventoDenuncia : praticaDiPraticaTotaleSelezionata.tipoEvento

        praticaDiPraticaTotaleOpenable = (caricaPannello."${tipoTributo}" && caricaPannello."${tipoTributo}"."${tipoPratica}" && caricaPannello."${tipoTributo}"."${tipoPratica}"?."${tipoEvento}")

        BindUtils.postNotifyChange(null, null, this, 'praticaDiPraticaTotaleOpenable')
    }

    @Command
    def onModificaPraticaDiPraticaTotale() {
        if (!praticaDiPraticaTotaleOpenable) {
            return
        }

        def tipoEvento = pratica.tipoTributo.tipoTributo in ['ICI', 'TASI'] ? praticaDiPraticaTotaleSelezionata.tipoEvento.tipoEventoDenuncia : praticaDiPraticaTotaleSelezionata.tipoEvento

        modificaPratica(praticaDiPraticaTotaleSelezionata.id, pratica.tipoTributo.tipoTributo,
                praticaDiPraticaTotaleSelezionata.tipoPratica, tipoEvento)
    }

    @Command
    def onDebitiCreditiRav() {

        Window w = Executions.createComponents("/pratiche/violazioni/creazioneRavvedimentoOperoso.zul", self,
                [
                        pratica: pratica.id,
                        lettura: true
                ]
        )
        w.onClose() { event ->
            if (event.data) {

            }
        }
        w.doModal()
    }

    @Command
    def onAnnullaDovuto() {

        if (!dePagAbilitato) {
            return
        }

        def result = integrazioneDePagService.eliminaDovutoPratica(pratica.toDomain())

        aggiornaStato = false
        pratica = pratica.toDomain().refresh().toDTO()
        BindUtils.postNotifyChange(null, null, this, "pratica")

        if (result) {
            Clients.showNotification(result, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        } else {
            Clients.showNotification("Annulla dovuto eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }

        controllaIuv()
    }

    @Command
    def onPassaggioAPagoPa() {

        if (!dePagAbilitato) {
            return
        }

        def response = integrazioneDePagService.passaPraticaAPagoPAConNotifica(pratica.id as Long, self)

        if (response.inviato) {
            def message = ''

            if (pratica.tipoTributo.tipoTributo in ['TARSU']) {
                message = liquidazioniAccertamentiService.annullaDovutoRuoliSuRavvedimento(pratica.id as Long)
            }
            if (pratica.tipoTributo.tipoTributo in ['CUNI']) {
                message = liquidazioniAccertamentiService.annullaDovutoSuViolazione(pratica.id as Long)
            }

            if (!message.isEmpty()) {
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 15000, true)
            }
        }

        controllaIuv()

        aggiornaStato = false
        pratica = pratica.toDomain().refresh().toDTO()
        BindUtils.postNotifyChange(null, null, this, "pratica")
    }

    @Command
    def onChangeNumeroRata() {

        if (parametriRateazione.numeroRata == 1) {
            parametriRateazione.tipologia = "M"

            BindUtils.postNotifyChange(null, null, this, "parametriRateazione")

        }
    }

    @Command
    def onChangeSpecieRuolo() {
        refreshElenchiOggetti()
    }

    private def controllaIuv() {

        // Si controlla lo iuv solo se depag è abilitato per risparmiare risorse
        if (dePagAbilitato) {
            iuvValorizzato = integrazioneDePagService.iuvValorizzatoPratica(pratica.id)
        }

        BindUtils.postNotifyChange(null, null, this, "iuvValorizzato")
    }

    private def modificaPratica(def pratica, String violTT, String violTP, String violTE) {

        String zul
        boolean lettura
        String situazione

        zul = caricaPannello."${violTT}"."${violTP}"."${violTE}".zul
        lettura = caricaPannello."${violTT}"."${violTP}"."${violTE}".lettura
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
                {}
        )
    }

    private def caricaIndici() {

        numOggetti = 0

        if (listaPraticheRif) {
            numPraticheRif = listaPraticheRif.size()
        }
        if (oggettiImu) {
            numOggetti += oggettiImu.size()
        }
        if (oggettiAccManTot) {
            numOggetti += oggettiAccManTot.size()
        }
        if (oggettiAccManTotTari) {
            numOggetti += oggettiAccManTotTari.size()
        }
        if (oggettiAccManuale) {
            if (accManImu) {
                numOggetti = oggettiAccManuale.size()
            }
            if (accManTari) {
                numLocaliEdAree = oggettiAccManuale.size()
            }
        }
        if (listaCanoni) {
            numCanoni = listaCanoni.size()
        }
        if (sanzioni) {
            numSanzioni = sanzioni.size()
        }
        if (iter) {
            numIter = iter.size()
        }
        if (rate) {
            numRateazioni = rate.size()
        }
        if (versamenti) {
            numVersamenti = versamenti.size()
        }
        if (ruoli) {
            numRuoli = ruoli.size()
        }

        BindUtils.postNotifyChange(null, null, this, "numPraticheRif")
        BindUtils.postNotifyChange(null, null, this, "numOggetti")
        BindUtils.postNotifyChange(null, null, this, "numLocaliEdAree")
        BindUtils.postNotifyChange(null, null, this, "numCanoni")
        BindUtils.postNotifyChange(null, null, this, "numSanzioni")
        BindUtils.postNotifyChange(null, null, this, "numIter")
        BindUtils.postNotifyChange(null, null, this, "numRateazioni")
        BindUtils.postNotifyChange(null, null, this, "numVersamenti")
        BindUtils.postNotifyChange(null, null, this, "numRuoli")

    }

    def gestioneSanzioni(def sanzione) {
        return sanzioniModifica[sanzione.toString()]
    }

    def getModificheIncorso() {
        return _modificheIncorso()
    }

    def getFrontespizioLettura() {
        return lettura ||
                (!lettura && (aRuolo != null)) ||
                isDirtyOggetti || isDirtySanzioni || isDirtyIter || isDirtyVersamenti || isDirtyRateazione
    }

    def getSanzioniLettura() {
        return lettura || (!lettura && (aRuolo != null)) || ((pratica.id ?: 0) == 0) ||
                isDirty || isDirtyOggetti || isDirtyIter || isDirtyVersamenti || isDirtyRateazione
    }

    def getVersamentiLettura() {
        return lettura || pratica.dataNotifica == null || !ruoloInviato ||
                isDirty || isDirtyOggetti || isDirtySanzioni || isDirtyIter || isDirtyRateazione
    }

    def getOggettiLettura() {
        return lettura ||
                isDirty || isDirtySanzioni || isDirtyIter || isDirtyVersamenti || isDirtyRateazione
    }

    def getIterLettura() {
        return lettura ||
                isDirty || isDirtyOggetti || isDirtySanzioni || isDirtyVersamenti || isDirtyRateazione
    }

    def getRateazioneLettura() {
        return lettura ||
                isDirty || isDirtyOggetti || isDirtySanzioni || isDirtyIter || isDirtyVersamenti
    }

    def tipoRapporto(def tipoRapporto) {
        switch (tipoRapporto) {
            case 'D':
                return 'Proprietario'
                break
            case 'A':
                return 'Occupante'
                break
            default:
                return ''
        }
    }

    private _modificheIncorso() {
        return isDirty ||
                isDirtyOggetti ||
                isDirtySanzioni ||
                isDirtyVersamenti ||
                isDirtyIter ||
                isDirtyRateazione
    }

// Imposta contribuente pratica dopo selezione
    private def setSelectCodFiscaleCon(def selectedRecord) {

        if (selectedRecord) {

            def codFiscale = (selectedRecord instanceof SoggettoDTO) ?
                    (selectedRecord?.contribuenti[0]?.codFiscale?.toUpperCase() ?: selectedRecord?.codFiscale?.toUpperCase()) ?: selectedRecord?.partitaIva?.toUpperCase() :
                    selectedRecord?.codFiscale?.toUpperCase()

            Contribuente cont = Contribuente.findByCodFiscale(codFiscale)
            if (!cont) {
                pratica.contribuente = new ContribuenteDTO(codFiscale: codFiscale)
                pratica.contribuente.soggetto = selectedRecord
            } else {
                pratica.contribuente = cont.toDTO(["soggetto", "ente"])
            }
            BindUtils.postNotifyChange(null, null, this, "pratica")
            contribuente = pratica.contribuente
            BindUtils.postNotifyChange(null, null, this, "contribuente")

            refreshFiltriContribuente()

            self.invalidate()

            // E' stato selezionato il contribuente, il rontespizio è stato modificato
            isDirty = true
        }
    }

// Aggiorna filtri da dati contribuente pratica
    def refreshFiltriContribuente() {

        filtri.denunciante.codFiscale = pratica.codFiscaleDen ?: ""
        filtri.contribuente.codFiscale = pratica.contribuente.codFiscale ?: ""
        filtri.contribuente.cognome = pratica.contribuente?.soggetto?.cognome ?: ""
        filtri.contribuente.nome = pratica.contribuente?.soggetto?.nome ?: ""
        filtri.comuneDenunciante.denominazione = pratica.comuneDenunciante?.ad4Comune?.denominazione
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    private impostaRateazione() {

        pratica.versatoPreRate = parametriRateazione?.versatoPreRateazione
        pratica.dataRateazione = parametriRateazione?.dataRateazione
        pratica.mora = parametriRateazione?.interessiMora
        pratica.numRata = parametriRateazione?.numeroRata
        pratica.tipologiaRate = (parametriRateazione?.tipologia == tipiRata.N) ? null : parametriRateazione?.tipologia

        pratica.calcoloRate = (parametriRateazione?.calcoloRate == tipiCalcoloRata.N) ? null : parametriRateazione?.calcoloRate
        pratica.flagIntRateSoloEvasa = parametriRateazione?.intRateSoloEvasa
        pratica.flagRateOneri = parametriRateazione?.oneriRiscossione
        pratica.scadenzaPrimaRata = parametriRateazione?.scadenzaPrimaRata

        if (pratica.calcoloRate == null) {
            pratica.aliquotaRate = parametriRateazione?.tassoAnnuo
            pratica.importoRate = parametriRateazione?.importoRata
        } else {
            pratica.aliquotaRate = null
            pratica.importoRate = null
        }
    }

    boolean verificaRateazione() {

        String message = ""
        boolean result = true

        if (pratica?.calcoloRate == null) {
            message += "Tipo Calcolo Rate non specificato.\n"
            return
        }
        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    def refreshElenchiOggetti() {

        switch (situazione) {
            case ["liquidazione", "ravvImu", "ravvTasi", "ravvTari"]:
                liqRavv()
                break
            case "accAutoTari":
                accAutoTari()
                break
            case "solAutoTari":
                solAutoTari()
                break
            case "accManImu":
                accManImu()
                break
            case "accManImuUnica":
                accManImuUnica()
                break
            case "accManTari":
                accManTari()
                break
            case "accManTariUnica":
                accManTariUnica()
                break
            case "accTotImu":
                accTotImu()
                break
            case "accTotTari":
                accTotTari()
                break
            case "accAutoTribMin":
                accAutoTribMin()
                break
            case "solAutoTribMin":
                solAutoTribMin()
                break
            case "accManTribMin":
                accManTribMin()
                break
            case "accTotTribMin":
                accTotTribMin()
                break
            case ["ravvTribMin"]:
                ravvTribMin()
                break
        }

        caricaIndici()
        calcolaTotali()

        BindUtils.postNotifyChange(null, null, this, "ruoli")
    }

    private liqRavv() {

        liqImu = true

        ravvTari = situazione in ['ravvTari']
        ravvTariSuRuoli = ravvTari && liquidazioniAccertamentiService.isRavvedimentoSuRuoli(pratica)

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)

        versato = (situazione in ["ravvImu", "ravvTasi", "ravvTari"]) ? calcolaVersato.vers : (calcolaVersato.vers + calcolaVersato.versRavv)

        versato = (versato == 0 ? null : versato)

        Long praticaId = pratica.id ?: 0
        if (praticaId) {
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, 0, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }
    }

    private ravvTribMin() {

        ravvTribMin = true

        abilitaGeneraF24 = pratica.tipoTributo.tipoTributo in ['ICP', 'TOSAP']

        concessione.praticaRef = pratica.id ?: 0
        concessione.tipoPratica = pratica.tipoPratica
        parametriBandBox.annoTributo = pratica.anno

        listaCanoni = canoneUnicoService.getConcessioniDaPratica(tipoTributoAttuale, concessione.praticaRef, false)
        numCanoni = listaCanoni.size()
        canoneSelezionato = null

        ricalcolaImportiOggTribMin()

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)

        versato = calcolaVersato.vers

        versato = (versato == 0 ? null : versato)

        BindUtils.postNotifyChange(null, null, this, "concessione")
        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")

        BindUtils.postNotifyChange(null, null, this, "listaCanoni")
        BindUtils.postNotifyChange(null, null, this, "numCanoni")
        BindUtils.postNotifyChange(null, null, this, "canoneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "versato")
        BindUtils.postNotifyChange(null, null, this, "abilitaGeneraF24")
    }

    private accAutoTari() {

        accertamento = 'A'

        accAutoTari = true

        Long praticaId = pratica.id ?: 0

        oggettiAccAutomatico = liquidazioniAccertamentiService.getOggettiAccertamentoAutomaticoTari(praticaId)

        def oggetti = oggettiAccAutomatico

        if (praticaId) {
            Long oggettoId = 0
            if (!oggetti.empty) {
                tipoOccupazione = oggettiAccAutomatico[0]?.tipoOccupazione?.tipoOccupazione ?: 'P'
                oggettoId = oggettiAccAutomatico[0]?.idOggetto
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        ricalcolaVersatoSuAccertamento()

    }

    private solAutoTari() {

        accertamento = 'A'

        accAutoTari = true

        Long praticaId = pratica.id ?: 0

        oggettiAccAutomatico = liquidazioniAccertamentiService.getOggettiAccertamentoAutomaticoTari(praticaId)

        def oggetti = oggettiAccAutomatico

        if (praticaId) {
            Long oggettoId = 0
            if (oggetti.size() > 0) {
                oggettoId = oggettiAccAutomatico[0]?.idOggetto
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)

        versato = calcolaVersato.vers + calcolaVersato.versRavv

        versato = (versato == 0 ? null : versato)
        totVersamenti = versato

        BindUtils.postNotifyChange(null, null, this, "versato")
        BindUtils.postNotifyChange(null, null, this, "totVersamenti")
    }

    private accManImu() {

        accertamento = 'M'

        accManImu = true
        accManImuUnica = false

        Long praticaId = pratica.id ?: 0
        String codFiscale = contribuente.codFiscale ?: '-'

        listaOggettiAccMan = denunceService.getOggettiPratica(praticaId)

        oggettiAccManuale = []                /// Elenco totale oggetti pratica accertamento
        dichiaratoAccManImu = []            /// Elenco totale oggetti pratica dichiarati

        oggettiAccManualeDich = []
        /// Elenco oggetti pratica dichiarati relativi all'oggetto pratica selezionato

        def elencoOggettiDich = []

        listaOggettiAccMan.each {

            def oggettoPratica = it.oggettoPratica

            String categoriaCat1 = it.oggettoPratica.categoriaCatasto?.categoriaCatasto
            String categoriaCat2 = it.oggettoPratica.oggetto?.categoriaCatasto?.categoriaCatasto

            def oggetto = [
                    id             : oggettoPratica?.id,
                    dto            : it,
                    ///
                    rendita        : -2,
                    ///
                    versato        : null,
                    tipoAliquota   : null,
                    aliquota       : null,
                    desAliquota    : null,
                    desAliquotaFull: null,
                    ///
                    importo        : 0.0,
                    importoRidotto : 0.0,
                    importoRidotto2: 0.0
            ]

            oggetto.oggettoRif = oggettoPratica?.oggettoPraticaRifV?.id
            if (oggetto.oggettoRif == null) {
                oggetto.oggettoRif = oggettoPratica?.oggettoPraticaRif?.id
            }
            if (oggetto.oggettoRif != null) {
                elencoOggettiDich << oggetto.oggettoRif
            }

            oggettiAccManuale << oggetto
        }

        dichiaratoAccManImu = liquidazioniAccertamentiService.getDatiOggettiPratricaRif(tipoTributoAttuale, codFiscale, pratica.anno, elencoOggettiDich)
        liquidatoAccManImu = liquidazioniAccertamentiService.getDatiOggettiPratricaLiq(tipoTributoAttuale, codFiscale, pratica.anno, elencoOggettiDich)

        ricalcolaImportiOggAccMan()

        def report = verificaOggettiAccManImu()
        if (report.result > 0) {
            String message = "Attenzione :\n\n" + report.message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }

        def dicOld = dic
        dic = !dichiaratoAccManImu.empty
        def liqOld = liq
        liq = !liquidatoAccManImu.empty
        def accOld = acc
        acc = false

        oggettoSelezionato = null
        selezionatoOgettoAccMan()

        def oggetti = oggettiAccManuale

        if (praticaId) {
            Long oggettoId = 0
            if (oggetti.size() > 0) {
                OggettoPraticaDTO oggpr = oggetti[0].dto.oggettoPratica
                oggettoId = oggpr.oggetto.id
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        def visp = liquidazioniAccertamentiService.getVersContTribAnno(codFiscale, pratica.tipoTributo?.tipoTributo, pratica.anno)

        if (visp.versato) {
            versImpostaSenzaPratica = "Versamenti (" + pratica.anno + "): " + (new DecimalFormat("##,##0.00")).format(visp.versato) +
                    " - n° Fabbricati: " + (visp.fabbricati ?: 0)
        }

        ricalcolaVersatoSuAccertamento()

        BindUtils.postNotifyChange(null, null, this, "listaOggettiAccMan")
        BindUtils.postNotifyChange(null, null, this, "oggettiAccManuale")
        BindUtils.postNotifyChange(null, null, this, "dichiaratoAccManImu")

        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")

        BindUtils.postNotifyChange(null, null, this, "dic")
        BindUtils.postNotifyChange(null, null, this, "acc")
        BindUtils.postNotifyChange(null, null, this, "liq")
        BindUtils.postNotifyChange(null, null, this, "ruoli")

        if ((acc != accOld) || (dic != dicOld) || (liq != liqOld)) {
            if (dic) {
                if (liq) {
                    sizeQuadroDichiarato = "35%"
                } else {
                    sizeQuadroDichiarato = "25%"
                }
                BindUtils.postNotifyChange(null, null, this, "sizeQuadroDichiarato")
            }
            self.invalidate()
        }
    }

    private accManImuUnica() {

        accertamento = 'M'

        accManTot = true
        accManTotImu = true
        accManImuUnica = true

        oggettiAccManTot = liquidazioniAccertamentiService.getOggettiAccertamentiManualiTotale(pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        oggettoSelezionato = oggettiAccManTot[0]

        if (oggettoSelezionato != null) {
            dichiaratoAccManTotImu = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTotaleImu(pratica.id, pratica.contribuente.codFiscale, pratica.anno, oggettoSelezionato.tipoOggetto.tipoOggetto)
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoSelezionato.oggetto.id, 0, cbSpecieRuolo)
        }

        liquidatoAccManTotImu = liquidazioniAccertamentiService.getLiquidatoAccertamentoManualeTotaleImu(pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        accertatoAccManTotImu = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTotaleImu(pratica.id, pratica.contribuente.codFiscale, pratica.anno, accertamento)

        dic = (dichiaratoAccManTotImu != null && !dichiaratoAccManTotImu.empty)
        liq = liquidatoAccManTotImu != null
        acc = !accertatoAccManTotImu.empty

        def visp = liquidazioniAccertamentiService.getVersContTribAnno(contribuente.codFiscale, pratica.tipoTributo.tipoTributo, pratica.anno)

        if (visp.versato) {
            versImpostaSenzaPratica = "Versamenti (" + pratica.anno + "): " + (new DecimalFormat("##,##0.00")).format(visp.versato) +
                    " - n° Fabbricati: " + (visp.fabbricati ?: 0)
        }

        ricalcolaVersatoSuAccertamento()
    }

    private accManTari() {

        accertamento = 'M'

        accManTari = true
        accManTariUnica = false

        Long praticaId = pratica.id ?: 0
        String codFiscale = contribuente.codFiscale ?: '-'

        listaOggettiAccMan = denunceService.getOggettiPratica(praticaId)

        oggettiAccManuale = []            // Elenco totale oggetti pratica accertamento
        dichiaratoAccManTari = []        // Elenco totale oggetti pratica dichiarati
        accertatoAccManTari = []        // Non serve, vuoto

        oggettiAccManualeDich = []        // Elenco oggetti rpatica dichiarati relativi all'oggetto pratica selezionato

        def elencoOggettiDich = []

        listaOggettiAccMan.each {

            tipoOccupazione = it.oggettoPratica?.tipoOccupazione?.tipoOccupazione ?: 'P'

            def oggettoPratica = it.oggettoPratica

            def oggetto = [
                    id          : oggettoPratica?.id,
                    dto         : it,
                    imposta     : 0.0,
                    impostaLorda: 0.0,
                    maggTARES   : 0.0
            ]

            oggetto.oggettoRif = oggettoPratica?.oggettoPraticaRifV?.id
            if (oggetto.oggettoRif == null) {
                oggetto.oggettoRif = oggettoPratica?.oggettoPraticaRif?.id
            }
            if (oggetto.oggettoRif != null) {
                elencoOggettiDich << oggetto.oggettoRif
            }

            oggettiAccManuale << oggetto
        }

        dichiaratoAccManTari = liquidazioniAccertamentiService.getDatiOggettiPratricaRif(tipoTributoAttuale, codFiscale, pratica.anno, elencoOggettiDich)

        ricalcolaImportiOggAccMan()

        def report = verificaOggettiAccManTari()
        if (report.result > 0) {
            String message = "Attenzione :\n\n" + report.message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }

        def dicOld = dic
        dic = !dichiaratoAccManTari.empty
        def accOld = acc
        acc = !accertatoAccManTari.empty

        oggettoSelezionato = null
        selezionatoOgettoAccMan()

        def oggetti = oggettiAccManuale

        if (praticaId) {
            Long oggettoId = 0
            if (oggetti.size() > 0) {
                OggettoPraticaDTO oggpr = oggetti[0].dto.oggettoPratica
                oggettoId = oggpr.oggetto.id
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        ricalcolaVersatoSuAccertamento()

        BindUtils.postNotifyChange(null, null, this, "listaOggettiAccMan")
        BindUtils.postNotifyChange(null, null, this, "oggettiAccManuale")
        BindUtils.postNotifyChange(null, null, this, "dichiaratoAccManTari")
        BindUtils.postNotifyChange(null, null, this, "accertatoAccManTari")

        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")

        BindUtils.postNotifyChange(null, null, this, "dic")
        BindUtils.postNotifyChange(null, null, this, "acc")
        BindUtils.postNotifyChange(null, null, this, "liq")
        BindUtils.postNotifyChange(null, null, this, "ruoli")

        if ((acc != accOld) || (dic != dicOld)) {
            self.invalidate()
        }
    }

    private accManTariUnica() {

        accertamento = 'M'

        accManTari = false
        accManTariUnica = true

        Long praticaId = pratica.id ?: 0
        String codFiscale = contribuente.codFiscale ?: '-'

        oggettiAccManTot = liquidazioniAccertamentiService.getOggettiAccertamentiManualiTotale(praticaId, codFiscale, pratica.anno)
        dichiaratoAccManTari = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTari(praticaId, codFiscale, pratica.anno)
        accertatoAccManTari = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTari(praticaId, codFiscale, pratica.anno)

        dic = !dichiaratoAccManTari.empty
        acc = !accertatoAccManTari.empty

        def oggetti = oggettiAccManTot

        if (praticaId) {
            Long oggettoId = 0
            if (!oggetti.empty) {
                tipoOccupazione = oggetti[0]?.tipoOccupazione?.tipoOccupazione ?: 'P'
                oggettoId = oggetti[0].oggetto.id
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        ricalcolaVersatoSuAccertamento()
    }

    private accTotImu() {

        accertamento = 'T'

        accManTot = true
        accManTotImu = true

        List<PraticaTributoDTO> praticheFiglie = liquidazioniAccertamentiService.getPraticaAccTot(pratica.id)

        for (figlia in praticheFiglie) {
            oggettiAccManTot.add(liquidazioniAccertamentiService.getOggettiAccertamentiManualiTotale(figlia.id, figlia.contribuente.codFiscale, figlia.anno))
        }
        oggettiAccManTot = oggettiAccManTot.flatten()

        oggettoSelezionato = oggettiAccManTot[0]

        dichiaratoAccManTotImu = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTotaleImu(oggettoSelezionato.pratica.id, pratica.contribuente.codFiscale, pratica.anno, oggettoSelezionato.tipoOggetto.tipoOggetto)
        liquidatoAccManTotImu = liquidazioniAccertamentiService.getLiquidatoAccertamentoManualeTotaleImu(oggettoSelezionato.pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        accertatoAccManTotImu = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTotaleImu(oggettoSelezionato.pratica.id, pratica.contribuente.codFiscale, pratica.anno, accertamento)

        dic = !dichiaratoAccManTotImu?.empty
        liq = !liquidatoAccManTotImu?.empty
        acc = !accertatoAccManTotImu?.empty

        listaPraticheRif = liquidazioniAccertamentiService.getPraticheRif(pratica.id)

        ricalcolaVersatoSuAccertamento()
    }

    private accTotTari() {

        accertamento = 'T'

        accTotTari = true

        Long praticaId = pratica.id
        oggettiAccManTotTari = liquidazioniAccertamentiService.getOggettiAccManTotTari(praticaId, pratica.anno)

        oggettoSelezionato = (oggettiAccManTotTari.size() > 0) ? oggettiAccManTotTari[0] : null

        Long oggPraticaId = ((oggettoSelezionato) ? oggettoSelezionato.pratica.id : praticaId) ?: 0

        dichiaratoAccManTari = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTari(oggPraticaId, pratica.contribuente.codFiscale, pratica.anno)
        accertatoAccManTari = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTari(oggPraticaId, pratica.contribuente.codFiscale, pratica.anno)
        ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettiAccAutomatico ? oggettiAccAutomatico[0]?.idOggetto : null, praticaId, cbSpecieRuolo)

        dic = !dichiaratoAccManTari.empty
        acc = !accertatoAccManTari.empty

        def oggetti = oggettiAccManTotTari

        if (praticaId) {
            Long oggettoId = 0
            if (!oggetti.empty) {
                tipoOccupazione = oggetti[0].tipoOccupazione ?: 'P'
                oggettoId = oggetti[0].oggetto.id
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        listaPraticheRif = liquidazioniAccertamentiService.getPraticheRifAccTot(praticaId)

        ricalcolaVersatoSuAccertamento()
    }

    private accAutoTribMin() {

        accertamento = tipoPratica

        accAutoTribMin = true

        Long praticaId = pratica.id ?: 0

        oggettiAccAutomatico = liquidazioniAccertamentiService.getOggettiAccertamentoAutomaticoTribMin(praticaId)

        def oggetti = oggettiAccAutomatico

        if (praticaId) {
            Long oggettoId = 0
            if (oggetti.size() > 0) {
                oggettoId = oggettiAccAutomatico[0]?.idOggetto
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        ricalcolaVersatoSuAccertamento()

    }

    private solAutoTribMin() {

        accertamento = tipoPratica

        accAutoTribMin = true

        Long praticaId = pratica.id ?: 0

        oggettiAccAutomatico = liquidazioniAccertamentiService.getOggettiAccertamentoAutomaticoTribMin(praticaId)

        def oggetti = oggettiAccAutomatico

        if (praticaId) {
            Long oggettoId = 0
            if (oggetti.size() > 0) {
                oggettoId = oggettiAccAutomatico[0]?.idOggetto
            }
            ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoId, praticaId, cbSpecieRuolo)
        } else {
            ruoli = []
        }

        def calcolaVersato = liquidazioniAccertamentiService.getVersato(contribuente.codFiscale, pratica.anno, pratica.tipoTributo.tipoTributo)

        versato = calcolaVersato.vers + calcolaVersato.versRavv

        versato = (versato == 0 ? null : versato)
        BindUtils.postNotifyChange(null, null, this, "versato")

        totVersamenti = versato
        BindUtils.postNotifyChange(null, null, this, "totVersamenti")
    }

    private accManTribMin() {

        accertamento = 'M'

        accManTot = true
        accManTribMin = true

        oggettiAccManTot = liquidazioniAccertamentiService.getOggettiAccertamentiManualiTotale(pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        dichiaratoAccManTribMin = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTari(pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        accertatoAccManTribMin = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTribMin(pratica.id, pratica.contribuente.codFiscale, pratica.anno)

        dic = !dichiaratoAccManTribMin.empty
        acc = !accertatoAccManTribMin.empty

        ruoli = []

        ricalcolaVersatoSuAccertamento()
    }

    private accTotTribMin() {

        accertamento = 'T'

        accManTot = true
        accManTribMin = true
        accTotTribMin = true

        List<PraticaTributoDTO> praticheFiglie = liquidazioniAccertamentiService.getPraticaAccTot(pratica.id)

        for (figlia in praticheFiglie) {
            oggettiAccManTot.add(liquidazioniAccertamentiService.getOggettiAccertamentiManualiTotale(figlia.id, figlia.contribuente.codFiscale, figlia.anno))
        }
        oggettiAccManTot = oggettiAccManTot.flatten()

        oggettoSelezionato = oggettiAccManTot[0]

        dichiaratoAccManTribMin = liquidazioniAccertamentiService.getDichiaratoAccertamentoManualeTari(oggettoSelezionato.pratica.id, pratica.contribuente.codFiscale, pratica.anno)
        accertatoAccManTribMin = liquidazioniAccertamentiService.getAccertatoAccertamentoManualeTribMin(oggettoSelezionato.pratica.id, pratica.contribuente.codFiscale, pratica.anno)

        dic = !dichiaratoAccManTari.empty
        acc = !accertatoAccManTari.empty

        ruoli = liquidazioniAccertamentiService.getRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale, oggettoSelezionato.oggetto.id, pratica.id, cbSpecieRuolo)

        listaPraticheRif = liquidazioniAccertamentiService.getPraticheRifAccTot(pratica.id)

        ricalcolaVersatoSuAccertamento()
    }

    private ricalcolaImportiOggAccMan() {

        switch (tipoTributoAttuale) {
            case 'ICI':
                ricalcolaImportiOggAccManImu()
                break
            case 'TARSU':
                ricalcolaImportiOggAccManTarsu()
                break
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiAccManuale")
        BindUtils.postNotifyChange(null, null, this, "totOggettiAccManuale")
    }

    private ricalcolaImportiOggAccManImu() {

        totOggettiAccManuale.importo = 0.0
        totOggettiAccManuale.importoRidotto = 0.0
        totOggettiAccManuale.importoRidotto2 = 0.0
        totOggettiAccManuale.versato = 0.0

        oggettiAccManuale.each {

            OggettoContribuenteDTO dto = it.dto
            OggettoPraticaDTO oggPr = dto.oggettoPratica

            it.rendita = oggettiService.getRenditaOggettoPratica(oggPr.valore, oggPr.tipoOggetto?.tipoOggetto, oggPr.anno, oggPr.categoriaCatasto?.categoriaCatasto)

            def result = liquidazioniAccertamentiService.getImpostaOggPrIci(oggPr.id, pratica.anno, pratica.contribuente.codFiscale)
            it.versato = result.versato
            it.tipoAliquota = result.tipoAliquota
            it.aliquota = result.aliquota
            it.desAliquota = result.desAliquota
            it.desAliquotaFull = result.desAliquotaFull
            it.importo = result.imposta

            totOggettiAccManuale.versato += result.versato ?: 0.0
            totOggettiAccManuale.importo += result.imposta ?: 0.0
        }
    }

    private ricalcolaImportiOggAccManTarsu() {

        totOggettiAccManuale.imposta = 0.0
        totOggettiAccManuale.impostaLorda = 0.0
        totOggettiAccManuale.maggTARES = 0.0

        oggettiAccManuale.each {

            OggettoContribuenteDTO dto = it.dto

            def result = liquidazioniAccertamentiService.getImpostaOggPrTarsu(dto.oggettoPratica.id, pratica.anno, pratica.contribuente.codFiscale)
            it.imposta = result.imposta
            it.impostaLorda = result.impostaLorda
            it.maggTARES = result.maggTARES

            totOggettiAccManuale.imposta += it.imposta ?: 0.0
            totOggettiAccManuale.impostaLorda += it.impostaLorda ?: 0.0
            totOggettiAccManuale.maggTARES += it.maggTARES ?: 0.0
        }
    }

    private ricalcolaImportiOggTribMin() {

        totCanoni.imposta = 0.0
        totCanoni.impostaLorda = 0.0

        listaCanoni.each {

            it.imposta = 0
            it.impostaLorda = 0

            def oggPrPub = (it.oggettoPraticaPub ?: 0) as Long
            def oggPrOcc = (it.oggettoPraticaOcc ?: 0) as Long

            if (oggPrPub) {
                def resultPub = liquidazioniAccertamentiService.getImpostaOggPr(oggPrPub, pratica.anno, pratica.contribuente.codFiscale)

                it.imposta = resultPub.imposta
                it.impostaLorda = resultPub.impostaLorda
            }

            if (oggPrOcc) {
                def resultOcc = liquidazioniAccertamentiService.getImpostaOggPr(oggPrOcc, pratica.anno, pratica.contribuente.codFiscale)

                it.imposta = resultOcc.imposta
                it.impostaLorda = resultOcc.impostaLorda
            }

            totCanoni.imposta += it.imposta ?: 0.0
            totCanoni.impostaLorda += it.impostaLorda ?: 0.0
        }

        BindUtils.postNotifyChange(null, null, this, "totCanoni")
    }

    private def verificaOggettiAccMan(Boolean showError = true) {

        def report = [

                result : 0,
                message: ''
        ]

        switch (situazione) {

            case 'accManImu':
                report = verificaOggettiAccManImu()
                break;
            case 'accManTari':
                report = verificaOggettiAccManTari()
                break;
        }

        if (report.result > 0) {

            report.message = "Attenzione :\n\n" + report.message
            if (showError) {
                Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            }
        }

        return report

    }

    private def verificaOggettiAccManTari() {

        def report = liquidazioniAccertamentiService.verificaPeriodiIntersecati(listaOggettiAccMan)

        def reportFam = verificaFamiliariOggAccManTari()

        if (reportFam.result > 0) {
            if (report.result < reportFam.result) {
                report.result = reportFam.result
            }
            if (!report.message.isEmpty()) {
                report.message += "\n\n"
            }
            report.message += reportFam.message
        }

        return report
    }

    private def verificaFamiliariOggAccManTari() {

        String message = ""
        Long result = 0

        List<Long> oggettiAnomali = []

        oggettiAccManuale.each {

            OggettoContribuenteDTO dto = it.dto

            def reportOgCo = liquidazioniAccertamentiService.verificaFamiliariAccertamentoTarsu(pratica, dto)

            if (reportOgCo.result > 0) {
                if (result < reportOgCo.result) result = reportOgCo.result
                Long oggId = dto.oggettoPratica.oggetto.id
                if (oggettiAnomali.indexOf(oggId) < 0) {
                    oggettiAnomali << oggId
                    if (!message.isEmpty()) message += "\n"
                    message += reportOgCo.message + " - Oggetto ${oggId}"
                }
            }
        }

        return [result: result, message: message]
    }

    private def verificaOggettiAccManImu() {

        def report = liquidazioniAccertamentiService.verificaPeriodiIntersecati(listaOggettiAccMan)

        def reportAlq = verificaAliquoteOggAccManImu()

        if (reportAlq.result > 0) {
            if (report.result < reportAlq.result) {
                report.result = reportAlq.result
            }
            if (!report.message.isEmpty()) {
                report.message += "\n\n"
            }
            report.message += reportAlq.message
        }

        return report
    }

    private def verificaAliquoteOggAccManImu() {

        String message = ""
        Long result = 0

        List<Long> oggettiAnomali = []

        oggettiAccManuale.each {

            OggettoContribuenteDTO dto = it.dto

            if ((it.tipoAliquota == null) || (it.aliquota == null)) {
                Long oggId = dto.oggettoPratica.oggetto.id
                if (oggettiAnomali.indexOf(oggId) < 0) {
                    oggettiAnomali << oggId
                }
            }
        }

        if (oggettiAnomali.size() > 0) {
            message = "Aliquota non impostata per "
            if (oggettiAnomali.size() > 1) {
                message += "gli oggetti "
            } else {
                message += "l'oggetto "
            }
            message += oggettiAnomali.join(",")
            result = 2
        }

        return [result: result, message: message]
    }

    private caricaRuoli(def tipo) {

        switch (tipo) {
            case "liqRavv":
                ruoli = ruoli ?: liquidazioniAccertamentiService.getRuoliPratica(pratica.id)
                break
        }

        caricaIndici()

        BindUtils.postNotifyChange(null, null, this, "ruoli")
    }

    private hasRuoli(def tipo) {

        hasRuoli = liquidazioniAccertamentiService.hasRuoli(pratica.tipoTributo.tipoTributo, contribuente.codFiscale ?: '-', 0, pratica.id ?: 0)
        BindUtils.postNotifyChange(null, null, this, "hasRuoli")
    }

    private ricalcolaVersatoSuAccertamento() {

        Double versatoPratica = liquidazioniAccertamentiService.getVersatoPratica(pratica.id ?: 0)
        versato = (versatoPratica == 0) ? null : versatoPratica

        BindUtils.postNotifyChange(null, null, this, "versato")

        totVersamenti = versato
        BindUtils.postNotifyChange(null, null, this, "totVersamenti")
    }

    private caricaVersamenti() {

        totVersamenti = 0
        totMaggTares = 0
        totAddPro = 0

        totVersamentiAP = 0
        totVersamentiRurali = 0
        totVersamentiTerreni = 0
        totVersamentiAreeF = 0
        totVersamentiAltriF = 0
        totVersamentiFabbD = 0
        totVersamentiFabbricati = 0
        totVersamentiMerce = 0

        totVersamentiTerreniCom = 0
        totVersamentiTerreniErar = 0
        totVersamentiAreeFCom = 0
        totVersamentiAreeFErar = 0
        totVersamentiAltriFCom = 0
        totVersamentiAltriFErar = 0
        totVersamentiRuraliCom = 0
        totVersamentiRuraliErar = 0
        totVersamentiFabbDCom = 0
        totVersamentiFabbDErar = 0

        if (!versamentiCaricati) {
            versamentiCaricati = true

            versamenti = liquidazioniAccertamentiService.getVersamentiViolazione(pratica.id)

            caricaRuoliVersamento()

            BindUtils.postNotifyChange(null, null, this, "versamenti")
        }

        versamenti.findAll { !it.eliminato }.each { v ->
            totVersamenti += v.importoVersato ?: 0
            totMaggTares += (v.maggiorazioneTares) ?: 0
            totAddPro += (v.addizionalePro) ?: 0

            totVersamentiAP += (v.abPrincipale ?: 0)
            totVersamentiRurali += (v.rurali ?: 0)
            totVersamentiTerreni += (v.terreniAgricoli ?: 0)
            totVersamentiAreeF += (v.areeFabbricabili ?: 0)
            totVersamentiAltriF += (v.altriFabbricati ?: 0)
            totVersamentiFabbD += (v.fabbricatiD ?: 0)
            totVersamentiFabbricati += (v.fabbricati ?: 0)
            totVersamentiMerce += (v.fabbricatiMerce ?: 0)

            totVersamentiTerreniCom += (v.terreniComune ?: 0)
            totVersamentiTerreniErar += (v.terreniErariale ?: 0)
            totVersamentiAreeFCom += (v.areeComune ?: 0)
            totVersamentiAreeFErar += (v.areeErariale ?: 0)
            totVersamentiRuraliCom += (v.ruraliComune ?: 0)
            totVersamentiRuraliErar += (v.ruraliErariale ?: 0)
            totVersamentiAltriFCom += (v.altriComune ?: 0)
            totVersamentiAltriFErar += (v.altriErariale ?: 0)
            totVersamentiFabbDCom += (v.fabbricatiDComune ?: 0)
            totVersamentiFabbDErar += (v.fabbricatiDErariale ?: 0)
        }

        // Se lo 0 è dovuto al fatto che non vi siano importi definiti nel db si setta a null
        totVersamentiAP = (versamenti.find { it.abPrincipale != null }) ? totVersamentiAP : null
        totVersamentiRurali = (versamenti.find { it.rurali != null }) ? totVersamentiRurali : null
        totVersamentiTerreni = (versamenti.find { it.terreniAgricoli != null }) ? totVersamentiTerreni : null
        totVersamentiAreeF = (versamenti.find { it.areeFabbricabili != null }) ? totVersamentiAreeF : null
        totVersamentiAltriF = (versamenti.find { it.altriFabbricati != null }) ? totVersamentiAltriF : null
        totVersamentiFabbD = (versamenti.find { it.fabbricatiD != null }) ? totVersamentiFabbD : null
        totVersamentiFabbricati = (versamenti.find { it.fabbricati != null }) ? totVersamentiFabbricati : null
        totVersamentiMerce = (versamenti.find { it.fabbricatiMerce != null }) ? totVersamentiMerce : null

        totVersamentiTerreniCom = (versamenti.find { it.terreniComune != null }) ? totVersamentiTerreniCom : null
        totVersamentiTerreniErar = (versamenti.find { it.terreniErariale != null }) ? totVersamentiTerreniErar : null
        totVersamentiAreeFCom = (versamenti.find { it.areeComune != null }) ? totVersamentiAreeFCom : null
        totVersamentiAreeFErar = (versamenti.find { it.areeErariale != null }) ? totVersamentiAreeFErar : null
        totVersamentiAltriFCom = (versamenti.find { it.altriComune != null }) ? totVersamentiAltriFCom : null
        totVersamentiAltriFErar = (versamenti.find { it.altriErariale != null }) ? totVersamentiAltriFErar : null
        totVersamentiRuraliCom = (versamenti.find { it.ruraliComune != null }) ? totVersamentiRuraliCom : null
        totVersamentiRuraliErar = (versamenti.find { it.ruraliErariale != null }) ? totVersamentiRuraliErar : null
        totVersamentiFabbDCom = (versamenti.find { it.fabbricatiDComune != null }) ? totVersamentiFabbDCom : null
        totVersamentiFabbDErar = (versamenti.find { it.fabbricatiDErariale != null }) ? totVersamentiFabbDErar : null

        invalidaGridVersamenti()

        BindUtils.postNotifyChange(null, null, this, "totVersamenti")
        BindUtils.postNotifyChange(null, null, this, "totMaggTares")
        BindUtils.postNotifyChange(null, null, this, "totAddPro")

        BindUtils.postNotifyChange(null, null, this, "totVersamentiAP")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiRurali")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiTerreni")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAreeF")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAltriF")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiFabbD")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiFabbricati")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiMerce")

        BindUtils.postNotifyChange(null, null, this, "totVersamentiTerreniCom")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiTerreniErar")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAreeFCom")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAreeFErar")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAltriFCom")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiAltriFErar")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiRuraliCom")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiRuraliErar")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiFabbDCom")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiFabbDErar")

        caricaIndici()
    }

    private caricaOggetti(def tipo) {
        switch (tipo) {
            case "liqRavv":

                inizializzazioneOggetti = true
                oggettiImu = liquidazioniAccertamentiService.getOggettiLiquidazioneImu(pratica.id)
                oggettiImu.each {
                    if (it.oggetto.tipoOggetto.tipoOggetto in [1L, 3L, 55L]) {
                        rendite["${it.id}-${it.oggetto.id}"] =
                                oggettiService.getRenditaOggettoPratica(
                                        it.valore,
                                        it.tipoOggetto?.tipoOggetto,
                                        it.anno,
                                        it.categoriaCatasto?.categoriaCatasto)
                    }
                }

                BindUtils.postNotifyChange(null, null, this, "oggettiImu")
                caricaIndici()
                break
        }
    }

    private caricaRuoliVersamento() {
        ruoliVersamento = liquidazioniAccertamentiService.elencoRuoliVersamento(pratica.tipoTributo.tipoTributo, pratica.anno, contribuente.codFiscale)
        BindUtils.postNotifyChange(null, null, this, "ruoliVersamento")
    }

    private caricaSanzioni() {

        listaSanzioni = Sanzione.createCriteria().list {
            eq('tipoTributo.tipoTributo', pratica.tipoTributo.tipoTributo)
            ge('codSanzione', (short) 100)
            // Se sollecito si possono inserire solo sanzioni di imposta oppure di spese di notifica
            if (tipoPratica == 'S') {
                'in'('tipoCausale', ['E', 'S'])
            }
            order('codSanzione', 'sequenza')
        }.toDTO()

        BindUtils.postNotifyChange(null, null, this, "listaSanzioni")
    }

    private caricaSanzioniPratica(def forceReload = false) {

        if (!sanzioni || forceReload) {
            if (pratica.id) {
                sanzioni = pratica.sanzioniPratica.sort { sanz1, sanz2 ->
                    sanz1.sanzione.codSanzione <=> sanz2.sanzione.codSanzione ?:
                            sanz1.sanzione.sequenza <=> sanz2.sanzione.sequenza
                }

                controlloSanzioni = [:]

                sanzioni.each {
                    controlloSanzioni << [(it.toString()): [
                            percentuale: it.percentuale,
                            importo    : it.importo,
                            sanzione   : it.sanzione
                    ]]
                }
            } else {
                sanzioni = []
            }
        }

        sanzioniCaricate = true
        inizializzazioneSanzioni = true
        calcolaTotaliSanzioni()

        comandiSanzioniPratica()
        invalidaGridSanzioni()

        caricaIndici()

        verificaSanzMinSuRiduzione()

        sanzioni.each { liquidazioniAccertamentiService.calcoloImportoLordo(it, tipoTributoAttuale, this.sanzMinimaSuRid) }

        BindUtils.postNotifyChange(null, null, this, "sanzioni")

        return sanzioni
    }

    // Carciamento totali per il frontespizio
    def calcolaTotali() {

        totImportoLordo = 0
        totImportoLordoRid = 0
        totImportoLordoRid2 = 0
        totImportoCalcolato = 0
        totImportoTotale = 0
        totImportoTotaleRid = 0
        totImportoTotaleRid2 = 0
        totImpostaCalcolata = 0

        def sanzioniNow

        if (sanzioniCaricate) {
            sanzioniNow = sanzioni
        } else {
            sanzioniNow = pratica.sanzioniPratica
        }

        verificaSanzMinSuRiduzione()

        sanzioniNow.each { liquidazioniAccertamentiService.calcoloImportoLordo(it, tipoTributoAttuale, this.sanzMinimaSuRid) }

        for (sa in sanzioniNow) {
            if (sanzioniCaricate && !sa.eliminato) {
                totImportoLordo += sa.importoLordoCalcolato

                if (sa.sanzione.codSanzione != 88) {
                    totImportoTotaleRid += sa.importoRidCalcolato
                    totImportoLordoRid += sa.importoLordoRidCalcolato
                    totImportoTotaleRid2 += sa.importoRid2Calcolato
                    totImportoLordoRid2 += sa.importoLordoRid2Calcolato
                }

                /// Per i ravvedimenti senza oggetti. Calcolo il non versato
                if ((sa.sanzione.codSanzione in [1, 100, 101]) || (sa.sanzione.tipoCausale == 'E')) {
                    totImpostaCalcolata += sa.importoLordoRidCalcolato
                }
            }
        }

        for (sp in sanzioniNow) {
            totImportoCalcolato += sp.importoLordo
            totImportoTotale += sp.importoTotale
        }

        totImportoLordo = totImportoLordo.setScale(2, RoundingMode.HALF_UP)
        totImportoLordoRid = totImportoLordoRid.setScale(2, RoundingMode.HALF_UP)
        totImportoLordoRid2 = totImportoLordoRid2.setScale(2, RoundingMode.HALF_UP)
        totImportoCalcolato = totImportoCalcolato.setScale(2, RoundingMode.HALF_UP)
        totImportoTotale = totImportoTotale.setScale(2, RoundingMode.HALF_UP)

        BindUtils.postNotifyChange(null, null, this, "totImportoLordo")
        BindUtils.postNotifyChange(null, null, this, "totImportoLordoRid")
        BindUtils.postNotifyChange(null, null, this, "totImportoLordoRid2")
        BindUtils.postNotifyChange(null, null, this, "totImportoCalcolato")
        BindUtils.postNotifyChange(null, null, this, "totImportoTotale")
        BindUtils.postNotifyChange(null, null, this, "totImportoTotaleRid")
        BindUtils.postNotifyChange(null, null, this, "totImportoTotaleRid2")
    }

    private calcolaTotaliSanzioni(def daDatabase = true) {

        if (daDatabase) {
            totaliSanzioni = liquidazioniAccertamentiService.getTotaliSanzioni(pratica.id ?: 0)
        } else {
            // Si azzerano i totali
            totaliSanzioni = [
                    [importoTotale    : 0
                     , totAbPrincipale: 0
                     , totRurali      : 0
                     , totTerreniCom  : 0
                     , totTerreniErar : 0
                     , totAreeCom     : 0
                     , totAreeErar    : 0
                     , totAltriCom    : 0
                     , totAltriErar   : 0
                     , totFabbCom     : 0
                     , totFabbErar    : 0
                     , totFabbMerce   : 0
                    ]
            ]

            sanzioni.findAll { !it.eliminato }.each {
                totaliSanzioni[0]["importoTotale"] += it["importo"] ?: 0
                totaliSanzioni[0]["totAbPrincipale"] += it["abPrincipale"] ?: 0
                totaliSanzioni[0]["totRurali"] += it["rurali"] ?: 0
                totaliSanzioni[0]["totTerreniCom"] += it["terreniComune"] ?: 0
                totaliSanzioni[0]["totTerreniErar"] += it["terreniErariale"] ?: 0
                totaliSanzioni[0]["totAreeCom"] += it["areeComune"] ?: 0
                totaliSanzioni[0]["totAreeErar"] += it["areeErariale"] ?: 0
                totaliSanzioni[0]["totAltriCom"] += it["altriComune"] ?: 0
                totaliSanzioni[0]["totAltriErar"] += it["altriErariale"] ?: 0
                totaliSanzioni[0]["totFabbCom"] += it["fabbricatiDComune"] ?: 0
                totaliSanzioni[0]["totFabbErar"] += it["fabbricatiDErariale"] ?: 0
                totaliSanzioni[0]["totFabbMerce"] += it["fabbricatiMerce"] ?: 0
            }

        }

        calcolaTotali()

        BindUtils.postNotifyChange(null, null, this, "totaliSanzioni")
    }

    private comandiSanzioniPratica() {

        verificaSanzMinSuRiduzione()

        sanzioniModifica.clear()
        sanzioni.each {
            sanzioniModifica << [(it.toString()): liquidazioniAccertamentiService.modificheSanzioni(this.lettura || isDirty, it.sanzione,
                    pratica.dataNotifica, true, this.sanzMinimaSuRid)]
        }

        BindUtils.postNotifyChange(null, null, this, "sanzioniModifica")
    }

    private caricaIter() {

        inizializzazioneIter = true

        if (pratica?.id) {
            iter = pratica.iter.sort { a, b -> b.data <=> a.data ?: b.id <=> a.id }
        } else {
            iter = []
        }
        pratica.iter = iter

        invalidaGridIter()

        caricaIndici()
        BindUtils.postNotifyChange(null, null, this, "iter")
    }

    private eliminaSanzione(def sanzione) {
        sanzione.eliminato = true

        invalidaGridSanzioni()
        calcolaTotaliSanzioni(false)

        aggiornaModificaOggetti()

        BindUtils.postNotifyChange(null, null, this, "sanzioni")
    }

    private eliminaSanzioni() {
        sanzioni*.eliminato = true
        numSanzioni = 0

        invalidaGridSanzioni()
        calcolaTotaliSanzioni(false)

        aggiornaModificaOggetti()

        BindUtils.postNotifyChange(null, null, this, "sanzioni")
        BindUtils.postNotifyChange(null, null, this, "numSanzioni")

        self.invalidate()
    }

    private eliminaVersamento(def versamento) {
        versamento.eliminato = true

        caricaVersamenti()

        BindUtils.postNotifyChange(null, null, this, "versamenti")
    }

    private def eliminaPratica() {
        try {
            salvaPratica(false)

            def message = liquidazioniAccertamentiService.eliminaPratica(pratica)

            if (!message?.replace("\n", "")?.empty) {
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            }

            aggiornaStato = true

            return true
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return false
            } else {
                throw e
            }
        }
    }

    protected void eliminaOggCoLiqRavvCheck(OggettoContribuenteDTO oggCo) {

        OggettoPraticaDTO oggPr = oggCo.oggettoPratica

        if (oggPr.oggettoPraticaRif?.id) {

            def datiPratica = liquidazioniAccertamentiService.getDettagliPraticaDaOggPr(oggPr.oggettoPraticaRif.id)
            def pratLiqRavv = liquidazioniAccertamentiService.getNumPraticheDaOggPrRif(tipoTributoAttuale, ['V', 'L'], oggPr.oggettoPraticaRif.id)

            // pratLiqRavv < 2: lìoggetto pratica per la denuncia è rif solo per al massimo un altro ogpr, quello
            // che si sta cercando di eliminare. Se >=2 vuol dire che è in altre pratiche (L o V)
            if ((datiPratica.id) && (datiPratica.tipoPratica == TipoPratica.D.tipoPratica) && (pratLiqRavv < 2)) {

                String dettagliPratica = "Dichiarazione " + datiPratica.id as String
                dettagliPratica += (datiPratica.numero) ? ", Numero datiPratrica.numero" : ", non numerata"

                Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
                String message = "Eliminare anche l'oggetto dalla denuncia originale?"
                Messagebox.show(message, "Attenzione", buttons, null, Messagebox.QUESTION, null,
                        new EventListener() {
                            void onEvent(Event e) {
                                switch (e.getName()) {
                                    case Messagebox.ON_YES:
                                        eliminaOggCoLiqRavv(oggCo, true)
                                        break
                                    case Messagebox.ON_NO:
                                        eliminaOggCoLiqRavv(oggCo, false)
                                        break
                                    case Messagebox.CANCEL:
                                        return
                                }
                            }
                        }
                )
            } else {
                eliminaOggCoLiqRavv(oggCo, false)
            }
        } else {
            eliminaOggCoLiqRavv(oggCo, false)
        }
    }

    protected void eliminaOggCoLiqRavv(OggettoContribuenteDTO oggCo, Boolean alsoRif) {

        OggettoPraticaDTO oggPr = oggCo.oggettoPratica
        Long oggPrId = oggPr.id
        Long oggId = oggPr.oggetto.id

        Long praticaOggPrRif = 0
        Long oggPrRifId = oggPr.oggettoPraticaRif?.id
        Long oggRifId = 0

        String note

        try {
            if (isDirtyOggetti) {
                salvaPratica()
            }

            denunceService.eliminaOgpr(oggPr)

            if ((alsoRif) && (oggPrRifId)) {
                OggettoPraticaDTO oggPrRif = OggettoPratica.get(oggPrRifId).toDTO()
                praticaOggPrRif = oggPrRif.pratica.id
                oggRifId = oggPrRif.oggetto.id
                denunceService.eliminaOgpr(oggPrRif)
            }

            IterPraticaDTO newIter = new IterPraticaDTO()

            if ((praticaOggPrRif) || (oggRifId)) {
                note = "Eliminato anche oggetto originale da pratica " + ((praticaOggPrRif ?: 0) as String)
            }

            newIter.pratica = pratica
            newIter.data = new Date()
            newIter.motivo = "Rimosso manualmente oggetto " + (oggId as String)
            newIter.note = note
            newIter.stato = pratica.tipoStato
            newIter.tipoAtto = pratica.tipoAtto

            iter.add(newIter)

            isDirtyIter = true
            salvaPratica()

        } catch (Exception ex) {
            throw ex
        }

        caricaOggetti("liqRavv")
        refreshElenchiOggetti()

        oggettoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    protected void apriOggettoAccMan(def idOggetto, def oggettoAnniPrec = null) {

        caricaSanzioniPratica(false)

        notificaPresenzaSanzioni()

        OggettoContribuenteDTO oggco = oggettoSelezionato ? oggettoSelezionato.dto : null

        int indexSelezione = listaOggettiAccMan.indexOf(oggco)
        commonService.creaPopup("/pratiche/denunce/oggettoContribuente.zul", self,
                [
                        idOggPr            : oggco ? oggco.oggettoPratica.id : -1
                        , contribuente     : pratica.contribuente.codFiscale
                        , tipoRapporto     : oggco ? oggco.tipoRapporto : tipoRapportoCod
                        , tipoTributo      : pratica.tipoTributo?.tipoTributo
                        , idOggetto        : idOggetto
                        , pratica          : pratica
                        , oggCo            : oggettoAnniPrec
                        , listaId          : listaOggettiAccMan
                        , indexSelezione   : indexSelezione
                        , modifica         : modificaOggetti
                        , storica          : false
                        , daBonifiche      : false
                        , modificaFlagsPera: modificaFlagsPeraOggetti
                ], { event ->
            if (event.data) {
                if (event.data.status == "Salva") {
                    def oggCoSalvato = event.data.oggCo

                    def idx = oggettiAccManuale.findIndexOf {
                        it.dto.contribuente.codFiscale == oggCoSalvato.contribuente.codFiscale &&
                                it.dto.oggettoPratica.id == oggCoSalvato.oggettoPratica.id
                    }
                    if (idx >= 0) {
                        oggettiAccManuale[idx].dto = oggCoSalvato
                    }

                    refreshElenchiOggetti()

                    oggettoSelezionato = null
                    BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
                }
                if (event.data.status == "") {
                    /// Anche senza salvare potrebbe aver rifatto il calcolo imposta, rileggiamo
                    ricalcolaImportiOggAccMan()
                }

                verificaOggettiAccMan()


                self.invalidate()

            }
        })
    }

    def oggAccManDaEsistenti() {

        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self,
                [filtri: null, listaVisibile: true, inPratica: true, ricercaContribuente: false, tipo: pratica.tipoTributo?.tipoTributo])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Oggetto") {
                    apriOggettoAccMan(event.data.idOggetto)
                }
            }
        }
        w.doModal()
    }

    def ricercaOggAccManAccertabili() {

        // Esiste del dichiarato, quindi disabilita opzioni per Omessa
        Boolean consentiPerOmessa = (dichiaratoAccManImu.size()) ? false : true

        commonService.creaPopup("/pratiche/violazioni/oggettiAccertabili.zul",
                self,
                [
                        tipoTributo      : pratica.tipoTributo.tipoTributo,
                        anno             : pratica.anno,
                        codFiscale       : pratica.contribuente.codFiscale,
                        consentiNuovo    : consentiPerOmessa,
                        consentiDaCessati: false,
                ],
                { e ->
                    if (e.data?.operazione) {

                        switch (e.data?.operazione) {
                            case 'daNuovo':
                                oggAccManDaEsistenti()
                                break
                            default:
                                def oggetto = e.data?.selezione
                                Long oggettoPraticaOrigine = oggetto.id
                                List<OggettoContribuenteDTO> oggCoCreati = []
                                OggettoContribuenteDTO ogCoCreato

                                ogCoCreato = oggettiService.creaOggettoContribuenteDaEsistente(pratica.id, oggettoPraticaOrigine)
                                oggCoCreati << ogCoCreato
                                //      calcolaAccertamentoImpostaOggetti(oggCoCreati)

                                if (tipoTributoAttuale in ['ICI']) {
                                    calcolaImpostaSuDichiarato()
                                }

                                refreshElenchiOggetti()

                                oggettoSelezionato = oggettiAccManuale.find { it.id == ogCoCreato.oggettoPratica.id };
                                selezionatoOgettoAccMan()

                                apriOggettoAccMan(-1)
                                break
                        }
                    }
                }
        )
    }

    def eliminaOggettoAccManSingolo(def oggCoDaEliminare) {

        //Nel caso si IMU o ICI si controlla se esistono contitolari sul quadro
        if ((tipoTributoAttuale == "IMU" || tipoTributoAttuale == "ICI") && checkEsisteContitolari(oggCoDaEliminare)) {
            def messaggio = "Esistono contitolari sul quadro selezionato. La registrazione non è eliminabile."
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        } else {

            String oggettoNDiM = ''

            Map params = new HashMap()
            params.put("width", "600")

            Messagebox.Button[] buttons = [
                    Messagebox.Button.YES,
                    Messagebox.Button.NO
            ]

            String anomalie = ""

            for (def anom : gestioneAnomalieService.anomalieAssociateAdOgCo(oggCoDaEliminare.toDomain())) {
                anomalie += (anom.idTipoAnomalia + " " + anom.descrizione + " " + anom.tipoTributo + " " + anom.anno + (anom.flagImposta == 'S' ? ' Imposta' : '')) + "\n"
            }

            Messagebox.show("Eliminazione della registrazione?\n\nImmobile: ${oggCoDaEliminare.oggettoPratica.numOrdine}\n\nL'operazione non potrà essere annullata." +
                    (!anomalie.isEmpty() ? "\nAnomalie associate all'oggetto pratica:\n" + anomalie : ""),
                    "Oggetti del dichiarante $oggettoNDiM",
                    buttons,
                    null,
                    Messagebox.QUESTION,
                    null,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                //SOLO per la tasi eliminare ogco corrisponde ad eliminare ogpr
                                //perchè c'è un rapporto uno ad uno.
                                eliminaOggettoAccMan(oggCoDaEliminare)

                                gestioneTipoViolazione()
                            }
                        }
                    },
                    params
            )
        }
    }

    protected String eliminaOggettoAccMan(OggettoContribuenteDTO oggCo) {

        String message = denunceService.eliminaOgCo(oggCo)

        if (message) {
            Messagebox.show(message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            refreshElenchiOggetti()
            oggettoSelezionato = null
            BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        }
    }

    boolean checkEsisteContitolari(def oggCo) {

        def lista
        if (oggCo) {
            lista = denunceService.contitolariOggetto(oggCo.oggettoPratica.id)
        }
        return (lista?.size() > 0)
    }

// Ricerca utenze T,R, esistenti da cessati
    private ricercaUtenzeTRDaCessati() {

        List<OggettoContribuenteDTO> oggCoCreated

        commonService.creaPopup("/pratiche/denunce/utenzeTari.zul",
                self,
                [pratica: pratica.id],
                { e ->
                    if (e.data?.utenze) {

                        oggCoCreated = oggettiService.creaOggettoContribuenteTarsuDaLocazioniCessate(pratica.id, e.data.utenze, e.data.data1, e.data.data2)
                        if (accManTari) {
                            calcolaAccertamentoImpostaOggetti(oggCoCreated)
                        }
                        refreshElenchiOggetti()

                        OggettoContribuenteDTO oggCo = oggCoCreated[0]
                        apriLocaleEdArea(oggCo)
                    }

                    gestioneTipoViolazione()
                }
        )
    }

    def apriLocaleEdArea(OggettoContribuenteDTO oggco) {

        def letturaNow = !modificaOggetti

        int indexSelezione = listaOggettiAccMan.indexOf(oggco)
        commonService.creaPopup("pratiche/denunce/oggettoContribuenteTari.zul"
                , self
                , [indexOggetto: indexSelezione, listaOggetti: listaOggettiAccMan, tipoTributo: tipoTributoAttualeDescr, lettura: letturaNow],
                { e ->
                    refreshElenchiOggetti()
                }
        )
    }

// Ricerca utenza da oggetti nuovo o esistente
    private localeEdAreaDaEsistenti(def modalita) {

        if (modalita == 'automatico') {
            if (commonService.fInpaValore('DETA_OGGEA')) {
                if (pratica.tipoEvento == TipoEventoDenuncia.I) {
                    modalita = 'crea'
                } else {
                    modalita = 'esistente'
                }
            } else {
                modalita = 'esistente'
            }
        }

        commonService.creaPopup("pratiche/denunce/oggettoContribuenteTari.zul",
                self,
                [
                        indexOggetto       : -1,
                        listaOggetti       : listaOggettiAccMan,
                        tipoTributo        : tipoTributoAttualeDescr,
                        idPratica          : pratica.id,
                        modalitaInserimento: modalita
                ],
                { e ->
                    if (e.data?.ogcoCreata) {
                        refreshElenchiOggetti()
                        gestioneTipoViolazione()
                    }
                }
        )
    }

// Ricerca utenze T,R, esistentida accertabili per questo C.F.
    def ricercaUtenzeTRAccertabili() {

        // Esiste del dichiarato, quindi disabilita opzioni per Omessa
        Boolean consentiPerOmessa = (dichiaratoAccManTari.size()) ? false : true

        commonService.creaPopup("/pratiche/violazioni/oggettiAccertabili.zul",
                self,
                [
                        tipoTributo      : pratica.tipoTributo.tipoTributo,
                        anno             : pratica.anno,
                        codFiscale       : pratica.contribuente.codFiscale,
                        consentiNuovo    : consentiPerOmessa,
                        consentiDaCessati: consentiPerOmessa,
                ],
                { e ->
                    if (e.data?.operazione) {

                        switch (e.data?.operazione) {
                            case 'daCessato':
                                ricercaUtenzeTRDaCessati()
                                break
                            case 'daNuovo':
                                localeEdAreaDaEsistenti('automatico')
                                break
                            default:
                                def oggetto = e.data?.selezione
                                Long oggettoPraticaOrigine = oggetto.id

                                List<OggettoContribuenteDTO> oggCoCreati = []
                                OggettoContribuenteDTO ogCoCreato

                                ogCoCreato = oggettiService.creaOggettoContribuenteDaEsistente(pratica.id, oggettoPraticaOrigine)
                                oggCoCreati << ogCoCreato
                                calcolaAccertamentoImpostaOggetti(oggCoCreati)

                                refreshElenchiOggetti()
                                apriLocaleEdArea(ogCoCreato)
                                break
                        }
                        gestioneTipoViolazione()
                    }
                }
        )
    }

    private eliminaLocaleEdArea() {

        OggettoContribuenteDTO localeSelezionato = oggettoSelezionato?.dto

        def ogprInviatoARuolo = denunceService.fOgPrInviato(localeSelezionato.oggettoPratica.id)
        def errMsg = []

        if (ogprInviatoARuolo) {
            errMsg << "Oggetto pratica con ruolo inviati al consorzio"
        }
        if (versamenti.size() != 0) {
            errMsg << "Esistono versamenti collegati alla pratica"
        }

        if (errMsg) {
            Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        errMsg << denunceService.eliminaOgCoTarsu(localeSelezionato)

        if (errMsg[0]) {
            Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        } else {
            refreshElenchiOggetti()
            if (listaOggettiAccMan.empty) {
                gestioneTipoViolazione()
            }
            Clients.showNotification("Quadro eliminato", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        }
    }

    def selezionatoOgettoAccMan() {

        oggettiAccManualeDich = []

        if (oggettoSelezionato) {

            switch (situazione) {
                case "accManImu":
                    oggettiAccManualeDich = dichiaratoAccManImu.findAll { it.oggPrAccId == oggettoSelezionato.oggettoRif }
                    oggettiAccManualeDich.addAll(liquidatoAccManImu.findAll { it.oggPrAccId == oggettoSelezionato.oggettoRif })
                    break
                case "accManTari":
                    oggettiAccManualeDich = dichiaratoAccManTari.findAll { it.oggPrAccId == oggettoSelezionato.oggettoRif }
                    break
            }
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiAccManualeDich")
    }

    def apriQuadroDichiarato(boolean opened) {

        if (opened) {

            if (dichiaratoOpened == false) {
                dichiaratoOpened = true
                BindUtils.postNotifyChange(null, null, this, "dichiaratoOpened")
            }
        } else {
            if (dichiaratoOpened != false) {
                dichiaratoOpened = false
                BindUtils.postNotifyChange(null, null, this, "dichiaratoOpened")
                aggiornaQuadroDichiarato(dichiaratoOpened)
            }
        }
    }

    def aggiornaQuadroDichiarato(boolean opened) {

        Clients.evalJavaScript("jq('span#labelDichiarato').remove();")

        if (!opened) {
            Clients.evalJavaScript("jq('.z-south-colpsd').append('<span id=\"labelDichiarato\">Dichiarato</span>');")
            Clients.evalJavaScript("jq('span#labelDichiarato').css({" +
                    "'font-weight': 'Bold', " +
                    "'float':'left',  " +
                    "'color': '#555555', " +
                    "'font-size': '12px', " +
                    "'padding': '3px 6px 3px', " +
                    "'line-height':'15px'});")
        }
    }

// Applica tipo calcolo - Confernma di salvataggio gi� ottenuta
    def applicaTipoCalcolo() {

        def esitoPositivo = onSalvaPratica()
        if (esitoPositivo) {
            if (calcoloNormalizzato) {
                pratica.tipoCalcolo = 'N'
            } else {
                pratica.tipoCalcolo = 'T'
            }

            esitoPositivo = onSalvaPratica()
            if (esitoPositivo) {
                refreshElenchiOggetti()
                if (listaOggettiAccMan.size() > 0) {
                    calcolaAccertamentoUI(false, true)
                }
            }
        }

        aggiornaFlagCalcoloNormalizzato()
    }

// Calcola Accertamento - Interfaccia utente
    def calcolaAccertamentoUI(Boolean soloCalcoloSanzioni = false, Boolean gestioneNotificheOggetto = true) {

        if (_modificheIncorso()) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("Prima di procedere e' necessario salvare le modifiche.\n\nSi desidera procedere?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    def esitoPositivo = onSalvaPratica()
                                    if (esitoPositivo) {
                                        refreshElenchiOggetti()
                                        calcolaAccertamentoUINoDirty(soloCalcoloSanzioni, gestioneNotificheOggetto)
                                    }
                                    break
                                case Messagebox.ON_NO:
                                    break
                            }
                        }
                    }, params)
        } else {
            calcolaAccertamentoUINoDirty(soloCalcoloSanzioni, gestioneNotificheOggetto)
        }
    }

// Calcola Accertamento - Interfaccia utente - Nessuna modifica in corso
    def calcolaAccertamentoUINoDirty(Boolean soloCalcoloSanzioni = false, Boolean gestioneNotificheOggetto = true) {

        def impostazioniCalcolo = [
                calcoloNormalizzato     : calcoloNormalizzato,
                flagTardivo             : flagTardivo,
                interessiDal            : null,
                interessiAl             : null,
                gestioneNotificheOggetto: gestioneNotificheOggetto,
                soloCalcoloSanzioni     : soloCalcoloSanzioni,
                praticaId               : pratica.id
        ]

        if ((soloCalcoloSanzioni) && (tipoTributoAttuale == 'TARSU')) {
            commonService.creaPopup("/pratiche/violazioni/calcoloAccertamentoManuale.zul", self, [impostazioni: impostazioniCalcolo],
                    { event ->
                        if (event.data) {
                            if (event.data.impostazioniCalcolo) {
                                calcolaAccertamento(event.data.impostazioniCalcolo)
                            }
                        }
                    })
        } else {
            calcolaAccertamento(impostazioniCalcolo)
        }
    }

// Calcola Accertamento
    def calcolaAccertamento(def impostazioni) {

        def report = verificaOggettiAccMan(false)

        if (report.result == 0) {
            if (impostazioni.soloCalcoloSanzioni) {
                report = liquidazioniAccertamentiService.calcolaSanzioniAccertamentoManuale(pratica, impostazioni, listaOggettiAccMan)
            } else {
                report = liquidazioniAccertamentiService.calcolaAccertamentoManuale(pratica, impostazioni, listaOggettiAccMan)
            }
        }

        if (report.result == 0) {
            ricalcolaImportiOggAccMan()
            caricaSanzioniPratica(true)

            isDirty = true
            salvaPratica(impostazioni.gestioneNotificheOggetto)
            calcolaTotaliSanzioni(false)
        }

        if (report.result != 0) {
            Clients.showNotification(report.message, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("Calcolo eseguito!", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiAccManuale")
        BindUtils.postNotifyChange(null, null, this, "pratica")

        self.invalidate()
    }

// Calcola imposta oggetti accertamento
    def calcolaAccertamentoImpostaOggetti(List<OggettoContribuenteDTO> oggco) {

        def parametri = [
                flagNormalizzato: null
        ]

        oggco.each {
            liquidazioniAccertamentiService.calcolaAccertamentoManualeOgCo(pratica.anno, parametri, pratica, it)
        }
    }

// Modifica il canone o ne crea uno nuovo
    def modificaCanone(def canone, Boolean salvaDich = false) {

        caricaSanzioniPratica(false)
        aggiornaModificaOggetti()

        if (canone && (tipoPratica != TipoPratica.V.tipoPratica)) {
            notificaPresenzaSanzioni()
        }

        def letturaNow = !modificaCanone

        Window w = Executions.createComponents("/ufficiotributi/canoneunico/concessioneCU.zul", self,
                [
                        contribuente   : contribuente,
                        pratica        : concessione.praticaRef,
                        oggetto        : canone?.oggettoRef,
                        dataRiferimento: canone?.dettagli?.dataDecorrenza,
                        anno           : canone?.anno,
                        lettura        : letturaNow
                ]
        )
        w.onClose() { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    onRefreshCanoni()
                }
            }
        }
        w.doModal()
    }

// Salva pratica
    private salvaPraticaSeDirty(def gestioneNotificheOggetto = true) {

        if (isDirty) {
            salvaPratica(gestioneNotificheOggetto)
        } else {
            verificaOggettiAccMan()
        }
    }

// Salva pratica
    private salvaPratica(def gestioneNotificheOggetto = true) {

        def children = ["contribuente.soggetto", "tipostato", "sanzioniPratica", "iter", "iter.tipoAtto"]
        def esitoPositivo = true

        try {
            // Salvataggio frontespizio
            if (isDirty) {
                pratica.id = salvaFrontespizio(gestioneNotificheOggetto)?.toDTO(children)?.id
            } else if (isDirtyOggetti) {
                salvaOggetti()
            } else if (isDirtySanzioni) {
                salvaSanzioni()
            } else if (isDirtyVersamenti) {
                salvaVeramenti()
            } else if (isDirtyIter) {
                salvaIter()
            } else if (isDirtyRateazione) {
                salvaRateazione()
            } else {
                // Non è stata apportata nessuna modifica non è necessario effettuare il salvataggio
                verificaOggettiAccMan()
                return esitoPositivo
            }

            pratica = pratica?.toDomain()?.refresh()?.toDTO(children)

            inizializzazionePratica()
            verificaOggettiAccMan()

            praticaSalvata = true
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                esitoPositivo = false
            } else {
                throw e
            }
        }

        aggiornaStato = true

        return esitoPositivo
    }

    private salvaFrontespizio(def gestioneNotificheOggetto) {
        return liquidazioniAccertamentiService.salvaFrontespizioPratica(pratica, gestioneNotificheOggetto)
    }

    private salvaOggetti() {
        switch (situazione) {
            case "accManImu":
                def oggettiContribuente = []
                oggettiAccManuale.each {
                    oggettiContribuente << it.dto
                }
                liquidazioniAccertamentiService.salvaOggettiContribuente(oggettiContribuente)
                break
            default:
                liquidazioniAccertamentiService.salvaOggettiPratica(oggettiImu)
                break
        }
    }

    private salvaSanzioni() {
        liquidazioniAccertamentiService.salvaSanzioniPratica(sanzioni)
    }

    private salvaVeramenti() {
        liquidazioniAccertamentiService.salvaVersamentiPratica(versamenti)
    }

    private salvaIter() {
        liquidazioniAccertamentiService.salvaIter(iter)
    }

    private salvaRateazione() {

        if (!rate.isEmpty()) {
            pratica.rate.clear()
            pratica.rate.addAll(rate)
        }

        impostaRateazione()

        liquidazioniAccertamentiService.salvaRateazionePratica(pratica)
    }

// Aggiorna il flag che abilita o meno la modifica degli oggetti
    private void aggiornaModificaOggetti() {

        if (!sanzioniCaricate) {
            caricaSanzioniPratica(false)
        }
        modificaOggetti = !lettura && pratica.id != null && numSanzioni == 0
        calcoloImposta = !lettura && pratica.id != null && pratica.dataNotifica == null && numSanzioni == 0 && situazione in ['accManImu', 'accManTari']

        modificaFlagsPeraOggetti()

        /// Caso speciale per Liquidazionie Ravvedimenti : in questo caso posso eliminare gli oggetti anche se ci sono sanzioni !!
        eliminaOggLiqRavv = !lettura && !oggettiLettura && pratica.id != null && pratica.dataNotifica == null

        /*
            Duplicazione ma indispensabile per riutilizzo folder della dichiarazione, senno va duplicato tutto
            /ufficiotributi/canoneunico/filderCanoni.zul
         */
        modificaCanone = false

        aggiornaFlagTardivo()

        BindUtils.postNotifyChange(null, null, this, "modificaOggetti")
        BindUtils.postNotifyChange(null, null, this, "calcoloImposta")
        BindUtils.postNotifyChange(null, null, this, "modificaCanone")
    }

    def modificaFlagsPeraOggetti() {
        modificaFlagsPeraOggetti = !lettura && !oggettiLettura && pratica.id != null
        if (modificaFlagsPeraOggetti && pratica.tipoPratica == 'A' && pratica.tipoTributo?.tipoTributo in ['ICI', 'TASI']) {
            if (liquidazioniAccertamentiService.inRuoloCoattivo(pratica)) {
                modificaFlagsPeraOggetti = false
            }
            if (situazione == 'accManImu' && !pratica.flagDenuncia) {
                modificaFlagsPeraOggetti = false
            }
        }

    }

// Aggiorna status flag tardivo
    private void aggiornaFlagTardivo() {

        if (dic) {
            // Se c'è del dichiarato stiamo parlando di Infedele, il tardivo viene gestitio tramite anno e data della denuncia
            modificaFlagTardivo = false
            flagTardivo = false
        } else {
            def sanzioniNow

            if (sanzioniCaricate) {
                sanzioniNow = sanzioni
            } else {
                sanzioniNow = pratica.sanzioniPratica
            }

            if (!sanzioniNow.empty) {
                // Omessa : se ci sono sanzioni non possiAmo modificare, aggiorna il flag in base alla presenza di sanzioni per tardivo
                modificaFlagTardivo = false

                def sanztardive = sanzioniNow.findAll { it.sanzione.tipoCausale in ['T', 'TP30'] }
                flagTardivo = sanztardive.size() > 0
            } else {
                // Omessa : nessuna sanzione, modificabile, rimane invarito
                modificaFlagTardivo = true
            }
        }

        BindUtils.postNotifyChange(null, null, this, "flagTardivo")
        BindUtils.postNotifyChange(null, null, this, "modificaFlagTardivo")
    }

// Aggiorna status flag calcolo normalizzato
    private void aggiornaFlagCalcoloNormalizzato() {

        calcoloNormalizzato = pratica.tipoCalcolo == 'N'

        BindUtils.postNotifyChange(null, null, this, "calcoloNormalizzato")
    }

// Verifica presenza sanzioni ed in caso notifica -> true se sanzioni presenti
    def notificaPresenzaSanzioni() {

        String msg = "Per questa pratica sono presenti Sanzioni\n"

        if ((modificaFlagsPeraOggetti) && (tipoTributoAttuale in ['ICI', 'TASI'])) {
            msg += "Sono modificabili i soli flag Possesso/Esclusione/Riduzione/Ab.Principale"
        } else {
            msg += "Impossibile effettuare modifiche"
        }

        if (sanzioni.size() != 0) {
            Clients.showNotification(msg,
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return true
        }

        return false
    }


    def getColspanInteressiDilazione() {

        def baseValue = 4

        // Per visualizzare la colonna 'Oneri Rim.'
        if (parametriRateazione.calcoloRate != 'V') {
            baseValue++
        }

        // Per visualizzare la colonna ''
        if (!parametriRateazione.intRateSoloEvasa) {
            baseValue++
        }

        if (pratica.tipoTributo.tipoTributo == "TARSU") {
            baseValue++
        }

        return baseValue
    }

    private inizializzazionePratica() {

        isDirty = false
        isDirtyOggetti = false
        isDirtySanzioni = false
        isDirtyVersamenti = false
        isDirtyIter = false
        isDirtyRateazione = false
        inizializzazioneSanzioni = true
        inizializzazioneVersamenti = true
        inizializzazioneIter == true
        versamentiCaricati = false

        verificaSanzMinSuRidGen()
        verificaSanzMinSuRiduzione()

        caricaSanzioniPratica(true)
        caricaIter()
        caricaVersamenti()

        praticaRateizzata = rateazioneService.praticaRateizzata(pratica.id ?: 0)
        // Si procede solo se la pratica è rateizzata
        if (!praticaRateizzata) {
            popolaRateazione()
        }

        abilitaStampa()
        aggiornaModificaOggetti()

        /*
            isDirty: se è stata modificata la testata
            isSanzioniDirty: sanzioni modificate
            isVersamentiModificati: versamenti modificati
            inizializzazioneSanzioni: siamo in fase di inizializzazione non si considera come una modifica
            inizializzazioneVsersamenti: siamo in fase di inizializzazione non si considera come una modifica

            Non si possono modificare contemporaneamente sanzioni, interessi e testata
         */

        BindUtils.postNotifyChange(null, null, this, "pratica")
        BindUtils.postNotifyChange(null, null, this, "frontespizioLettura")
        BindUtils.postNotifyChange(null, null, this, "oggettiLettura")
        BindUtils.postNotifyChange(null, null, this, "sanzioniLettura")
        BindUtils.postNotifyChange(null, null, this, "versamentiLettura")
        BindUtils.postNotifyChange(null, null, this, "iterLettura")
        BindUtils.postNotifyChange(null, null, this, "rateazioneLettura")
        BindUtils.postNotifyChange(null, null, this, "praticaRateizzata")
    }

    private void sistemaRateazione() {

        if (pratica.calcoloRate == null) {

            def rate = rateazioneService.elencoRate(pratica)

            if (rate.isEmpty()) {
                pratica.calcoloRate = rateazioneService.getCalcoloRatePredefinito()
                pratica.flagIntRateSoloEvasa = rateazioneService.getIntRateSoloEvasaPredefinito()
                pratica.flagRateOneri = rateazioneService.getRateOneriPredefinito()
            }
        }
    }

    private void popolaRateazione() {

        totVersamentiRate = 0
        totMaggTaresRate = 0
        totAddProRate = 0

        rateTotali.impRataTot = 0
        rateTotali.quotaIntTot = 0
        rateTotali.quotaCapTot = 0
        rateTotali.aggioTot = 0
        rateTotali.aggioRimTot = 0
        rateTotali.dilazioneTot = 0
        rateTotali.dilazioneRimTot = 0
        rateTotali.importoTot = 0
        rateTotali.importoArrTot = 0
        rateTotali.oneriTot = 0
        rateTotali.sanzioniAccTot = 0
        rateTotali.quotaTefaTot = 0
        rateTotali.quotaTassaTot = 0

        parametriRateazione.importoPratica = pratica.tipoTributo.tipoTributo == 'TARSU' ? totImportoCalcolato : pratica.importoTotale
        parametriRateazione.versatoPreRateazione = pratica.versatoPreRate
        parametriRateazione.dataRateazione = pratica.dataRateazione
        parametriRateazione.interessiMora = pratica.mora
        parametriRateazione.numeroRata = pratica.numRata
        parametriRateazione.tipologia = pratica.tipologiaRate == null ? null : pratica.tipologiaRate
        parametriRateazione.importoRata = pratica.importoRate
        parametriRateazione.tassoAnnuo = pratica.aliquotaRate
        parametriRateazione.calcoloRate = pratica.calcoloRate == null ? null : pratica.calcoloRate
        parametriRateazione.intRateSoloEvasa = pratica.flagIntRateSoloEvasa
        parametriRateazione.oneriRiscossione = pratica.flagRateOneri
        parametriRateazione.scadenzaPrimaRata = pratica.scadenzaPrimaRata

        rate = rateazioneService.elencoRate(pratica).toDTO(['pratica'])
        if (rate.size > 0) {
            numeroRate = (1..rate.size)
        } else {
            numeroRate = [0]
        }

        rate.each {

            RataPraticaDTO rata = it

            rateTotali.impRataTot += rata.importoRata()

            rateTotali.quotaCapTot += rata.importoCapitale
            rateTotali.quotaIntTot += rata.importoInteressi

            rateTotali.quotaTassaTot += rata.quotaTassa ?: 0
            rateTotali.aggioTot += rata.aggio ?: 0
            rateTotali.aggioRimTot += rata.aggioRimodulato ?: 0
            rateTotali.dilazioneTot += rata.dilazione ?: 0
            rateTotali.dilazioneRimTot += rata.dilazioneRimodulata ?: 0
            rateTotali.importoTot += rata.importo ?: 0
            rateTotali.importoArrTot += rata.importoArr ?: 0
            rateTotali.oneriTot += rata.oneri ?: 0

            rateTotali.sanzioniAccTot += rata.oneri ?: 0
            rateTotali.quotaTefaTot += rata.quotaTefa ?: 0
        }

        parametriRateazione.readOnly = !rate.empty || lettura

        versamentiRate = rateazioneService.elencoVersamentiRate(pratica)
        for (v in versamentiRate) {
            totVersamentiRate += v.importoVersato ?: 0
            totMaggTaresRate += (v.maggiorazioneTares) ?: 0
            totAddProRate += (v.addizionalePro) ?: 0
        }

        listaTributiF24Interessi = rateazioneService.listaTributiF24(
                pratica.tipoTributo.tipoTributo,
                pratica.tipoTributo.getTipoTributoAttuale(pratica.anno),
                'I'
        )

        listaTributiF24Capitale = rateazioneService.listaTributiF24(
                pratica.tipoTributo.tipoTributo,
                pratica.tipoTributo.getTipoTributoAttuale(pratica.anno),
                'S'
        )

        BindUtils.postNotifyChange(null, null, this, "parametriRateazione")
        BindUtils.postNotifyChange(null, null, this, "rate")
        BindUtils.postNotifyChange(null, null, this, "rateTotali")
        BindUtils.postNotifyChange(null, null, this, "listaTributiF24Interessi")
        BindUtils.postNotifyChange(null, null, this, "listaTributiF24Capitale")
        BindUtils.postNotifyChange(null, null, this, "versamentiRate")
        BindUtils.postNotifyChange(null, null, this, "totVersamentiRate")
        BindUtils.postNotifyChange(null, null, this, "totMaggTaresRate")
        BindUtils.postNotifyChange(null, null, this, "totAddProRate")
        BindUtils.postNotifyChange(null, null, this, "numeroRate")
    }

    private invalidaGridVersamenti() {
        try {
            (self.getFellow("datiLiqAcc")
                    .getFellow("folderVersamenti")
                    .getFellow("gridVersamenti") as Grid)
                    .invalidate()
        } catch (Exception e) {
            log.info("datiLiqAcc.folderVersamenti non caricato.")
        }
    }

    private invalidaGridIter() {
        try {
            (self.getFellow("datiLiqAcc")
                    .getFellow("folderIter")
                    .getFellow("gridIter") as Grid)
                    .invalidate()
        } catch (Exception e) {
            log.info("datiLiqAcc.folderIter non caricato.")
        }
    }

    private invalidaGridSanzioni() {

        try {
            (self.getFellow("datiLiqAcc")
                    .getFellow("folderSanzioni")
                    .getFellow("gridSanzioniICITARSU") as Grid)
                    .invalidate()
            (self.getFellow("datiLiqAcc")
                    .getFellow("folderSanzioni")
                    .getFellow("gridSanzioniTASI") as Grid)
                    .invalidate()
        } catch (Exception e) {
            log.info("datiLiqAcc.folderSanzioni non caricato.")
        }
    }

    private void abilitaStampa() {
        abilitaStampa =
                ((pratica.numero != null) // la pratica deve essere numerata
                        && (
                        (pratica.tipoTributo.tipoTributo == 'ICI' && pratica.anno >= 2012) // Se ICI dal 2012
                                || pratica.tipoTributo.tipoTributo != 'ICI')) // Per TASI tutte le annualità

        BindUtils.postNotifyChange(null, null, this, "abilitaStampa")
    }

    private aggiornamentoImmobili() {

        liquidazioniAccertamentiService.creaRavvedimento(
                pratica.contribuente.codFiscale,
                pratica.anno,
                pratica.data,
                pratica.tipoEvento.tipoEventoDenuncia,
                pratica.tipoRavvedimento,
                pratica.tipoTributo.tipoTributo,
                pratica.id
        )

        ricalcolaImpostaESanzioni()

        switch (situazione) {
            case ["ravvTribMin"]:
                ravvTribMin()
                break
            default:
                caricaOggetti("liqRavv")
                break
        }
    }

    private def calcolaImpostaSuDichiarato() {

        imposteService.proceduraCalcolaImposta(pratica.anno, pratica.contribuente.codFiscale, tipoTributoAttuale, null, null, null)
    }

    private ricalcolaImpostaESanzioni() {

        imposteService.proceduraCalcolaImpostaRavv(pratica.id)
        liquidazioniAccertamentiService.calcolaSanzioniRavvedimento(pratica.id)

        switch (situazione) {
            case ["ravvTribMin"]:
                ravvTribMin()
                break
            default:
                caricaOggetti("liqRavv")
                break
        }

        caricaSanzioniPratica(true)
        pratica = PraticaTributo.get(pratica.id).refresh().toDTO(["contribuente.soggetto", "tipostato", "sanzioniPratica", "iter"])

        BindUtils.postNotifyChange(null, null, this, "pratica")
    }

    private resetTipoVersamentoTestata() {
        tipoVersamentoRavv = tipoVersamentoTestataOrig
        BindUtils.postNotifyChange(null, null, this, "tipoVersamentoRavv")
    }

    def notificaModifichePerOggetti() {
        if (oggettiLettura) {
            Clients.showNotification("Salvare prima le modifiche in corso.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 2000, true)

            return false
        }

        return true
    }

    private notificaRicalcoloSanzioni() {
        // Non ci sono oggetti, ravvedimento automatico
        if (pratica.tipoPratica == TipoPratica.V.tipoPratica && oggettiImu.empty) {
            Clients.showNotification("In fase di salvataggio le sanzioni verranno ricalcolate.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        }
    }

    /// Legge da inpa il valore del flag generale di sanzione minima su riduzione
    private def verificaSanzMinSuRidGen() {

        this.sanzMinimaSuRidGen = false

        if (pratica.tipoPratica in ['A', 'L']) {

            InstallazioneParametro paramSanzMinR = InstallazioneParametro.get('SANZ_MIN_R')
            String valore = paramSanzMinR?.valore ?: ''
            Integer valoreLen = valore.length()

            if ((valoreLen > 0) && (valore.substring(0, 1) == 'S')) {
                this.sanzMinimaSuRidGen = true
            }
        }
    }

    /// Legge da prtr il valore di sanzione minima su riduzione
    private def verificaSanzMinSuRiduzione() {

        if (pratica.tipoPratica in ['A', 'L']) {
            this.sanzMinimaSuRid = liquidazioniAccertamentiService.getFlagSanzRidMinPratica(pratica.pratica)
        } else {
            this.sanzMinimaSuRid = false
        }
    }

    private def sceltaRidottoF24() {
        commonService.creaPopup("/pratiche/sceltaRidottoF24Stampa.zul",
                self, [:],
                { event ->
                    if (event.data?.ridotto) {
                        f24Violazione(event.data.ridotto)
                    }
                })
    }

    private f24Violazione(def ridotto) {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [idDocumento: pratica.id,
                 codFiscale : pratica.contribuente.codFiscale])

        List f24data
        List f24Ridotto
        List f24NonRidotto

        try {
            if (ridotto != 'TUTTI') {
                f24data = f24Service.caricaDatiF24(pratica, 'V', ridotto == 'SI')
            } else {
                f24Ridotto = f24Service.caricaDatiF24(pratica, 'V', true)
                f24NonRidotto = f24Service.caricaDatiF24(pratica, 'V', false)
            }
        } catch (Exception e) {
            Clients.showNotification(e.cause?.detailMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)

            if (e.message == 'NOC_COD_TRIBUTO') {
                return
            }

            throw e
        }

        def f24file
        def reportDef

        if (f24data) {
            reportDef = new JasperReportDef(name: 'f24.jasper'
                    , fileFormat: JasperExportFormat.PDF_FORMAT
                    , reportData: f24data
                    , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

            f24file = jasperService.generateReport(reportDef).toByteArray()
        } else {

            // Vengono creati i due report ridotto e non e poi uniti insieme per aggiungere le pagine bianche
            reportDef = new JasperReportDef(name: 'f24.jasper'
                    , fileFormat: JasperExportFormat.PDF_FORMAT
                    , reportData: f24Ridotto
                    , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

            def fileRidotto = jasperService.generateReport(reportDef)

            reportDef = new JasperReportDef(name: 'f24.jasper'
                    , fileFormat: JasperExportFormat.PDF_FORMAT
                    , reportData: f24NonRidotto
                    , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

            def fileNonRidotto = jasperService.generateReport(reportDef)

            f24file = ModelliCommons.allegaDocumentoPdf(fileRidotto.toByteArray(), fileNonRidotto.toByteArray(), true)
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file)
        Filedownload.save(amedia)
    }

    // Chiude finestra, sganciando gestione proprietà per isDirty
    protected chiudi(Boolean praticaEliminata = false) {

        if (eventIsDirty) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(eventIsDirty)
            eventIsDirty = null
        }

        if (praticaEliminata) {
            Events.postEvent(Events.ON_CLOSE, self, [praticaEliminata: true, aggiornaStato: aggiornaStato])
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [pratica: pratica, aggiornaStato: aggiornaStato, salvato: praticaSalvata])
        }
    }

    // In caso di omessa o infedele, su eliminazione o aggiunta oggetto il valore del campo tipo_violazione potrebbe
    // essere cambiato dal trigger. Si ricarica la testata per allinerla allo stato del db.
    private void gestioneTipoViolazione() {
        pratica = pratica?.toDomain()?.refresh()?.toDTO(["contribuente.soggetto", "tipostato", "sanzioniPratica", "iter"])
        aggiornaStato = true
        BindUtils.postNotifyChange(null, null, this, "pratica")
    }

    void calcolaDisabilitaDataNotificaSuRateazione() {
        // Se la pratica ha una data di notifica e il tipo atto corrisponde a "Rateazione" o se la pratica
        // e` stata rateizzata, disabilita la modifica della data di notifica
        disabilitaDataNotificaSuRateazione = pratica.dataNotifica &&
                (pratica.tipoAtto?.tipoAtto == 90 || rateazioneService.praticaRateizzata((pratica.id ?: 0) as Long))
        BindUtils.postNotifyChange(null, null, this, "disabilitaDataNotificaSuRateazione")
    }
}
