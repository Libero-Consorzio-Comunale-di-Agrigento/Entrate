package sportello.contribuenti

import commons.SostituzioneContribuenteViewModel
import document.FileNameGenerator
import grails.plugins.springsecurity.SpringSecurityService
import groovy.json.JsonSlurper
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.*
import it.finmatica.tr4.archivio.FiltroRicercaOggetto
import it.finmatica.tr4.bonificaDati.versamenti.BonificaVersamentiService
import it.finmatica.tr4.catasto.VisuraService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazioni.TipiCanale
import it.finmatica.tr4.contribuenti.*
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.datiesterni.anagrafetributaria.AnagrafeTributariaService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.email.MessaggisticaService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.familiari.FamiliariService
import it.finmatica.tr4.imposte.CompensazioniService
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.portale.IntegrazionePortaleService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import it.finmatica.tr4.smartpnd.SmartPndService
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import it.finmatica.tr4.svuotamenti.SvuotamentiService
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.versamenti.VersamentiService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService
import it.finmatica.zkutils.ordinamentomulticolonna.OrdinamentoMultiColonnaComponent
import net.sf.jmimemagic.Magic
import net.sf.jmimemagic.MagicMatch
import org.apache.commons.lang.SerializationUtils
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.util.resource.Labels
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.Sessions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*
import ufficiotributi.imposte.CompensazioniFunzioniViewModel

import javax.servlet.ServletContext
import java.nio.file.Files
import java.text.DecimalFormat
import java.util.Calendar

class SituazioneContribuenteViewModel extends SostituzioneContribuenteViewModel {

    private Logger log = LoggerFactory.getLogger(SituazioneContribuenteViewModel.class)
    private final String SIT_CONTR = "SIT_CONTR"

    @Wire('#concessioni')
    Tab tabConcessioni

    @Wire('#popupNoteSoggetto')
    Popup popupNoteSoggetto

    @Wire('#pratiche')
    Tab tabPratiche

    // services
    SpringSecurityService springSecurityService
    ContribuentiService contribuentiService
    OggettiService oggettiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    F24Service f24Service
    JasperService jasperService
    Ad4EnteService ad4EnteService
    ImposteService imposteService
    IntegrazioneWEBGISService integrazioneWEBGISService
    CatastoCensuarioService catastoCensuarioService
    DenunceService denunceService
    ModelliService modelliService
    DocumentaleService documentaleService
    IntegrazioneDePagService integrazioneDePagService
    VisuraService visuraService
    VersamentiService versamentiService
    ConfrontoArchivioBancheDatiService confrontoArchivioBancheDatiService
    CompetenzeService competenzeService
    MessaggisticaService messaggisticaService
    AnagrafeTributariaService anagrafeTributariaService
    BonificaVersamentiService bonificaVersamentiService
    CompensazioniService compensazioniService
    FamiliariService familiariService
    ComunicazioniService comunicazioniService
    CommonService commonService
    StatoContribuenteService statoContribuenteService
    SvuotamentiService svuotamentiService
    IntegrazionePortaleService integrazionePortaleService

    ServletContext servletContext

    // componenti
    Window self
    def popupNote
    def noteDocumentoContribuente

    // dati
    SoggettoDTO soggetto
    String tempStringNoteSoggetto

    String codFiscale

    boolean ricaricaListaOggetti = false

    boolean disabilitaStampaF24 = false
    boolean showRendite = false
    boolean showLocazioniOggetto = false
    boolean showDatiMetriciOggetto = false
    boolean showDatiMetriciDettaglioIntestatari = false
    boolean showDatiMetriciDettaglioImmobile = false
    def datiMetriciTipologia = 'TARES'
    def datiMetriciTitolo

    CanoneUnicoService canoneUnicoService
    SmartPndService smartPndService
    RateazioneService rateazioneService

    FiltroRicercaCanoni filtriConcessioni
    Boolean filtriConcessioniAttivo = false

    def listaConcessioni = []
    def numConcessioni = 0
    def concessioneSelezionata = null

    def convertiConcessioni = false

    def listaAnni
    def listaTributiAnni
    def listaPraticheOggetto
    def anno
    def listaPratiche
    def campiOrdinamentoPratiche
    def listaOggettiPratica
    def listaOggetti
    def listaSvuotamenti
    def listaVersamenti
    def listaContatti
    def listaRuoli
    def listaFamiliari
    def listaImposte
    def listaOggettiImposta
    def listaOggettiRuolo
    def listaPraticheRuolo
    def listaDocumenti
    def listaComunicazioniPND = [:]
    def listaAllegati
    def listaContrattiLocazioni
    def listaContrattiUtenze
    def listaDatiMetrici
    def listaDatiMetriciIntestatari
    def datiMetriciAssociati = [:]
    def listaTipiAtto
    def oggettoSelezionato
    def praticaSelezionata
    def praticaOpenableFromFolderPratiche = true
    def praticaSelezionataPrecedenteId
    def impostaSelezionata
    def ruoloSelezionato
    def oggettoRuoloSelezionato
    Map oggettoPraticaSelezionato
    def versamentoSelezionato
    def datiMetriciUiuSelezionata
    def datiMetriciTabSelezionata = 0
    def descrizioneTipoPraticaVersamentoSelezionato = ""
    def ultimoStato = ""
    def modificaPraticaInline = false
    def isRateazione = false
    def familiareSelezionato
    def listaDatiMetriciImmobile

    def totaliSvuotamenti = [quantitaTotale: 0,
                             unitaDiMisura : '']

    def modificaRuolo = false

    def cbTributiVersamentoDettaglio
    def cbTributiVersamentoTrasferisci

    def praticaOggettiTable
    def impostaOggettiTable
    def ruoliDettaglioTable

    def captionlistaOggettiImposta = "Oggetti dell'imposta (0)"

    DocumentoContribuente documentoSelezionato

    def numPratiche = 0
    def numOggetti = 0
    def numVersamenti = 0
    def numImposte = 0
    def numContatti = 0
    def numRuoli = 0
    def numFamiliari = 0
    def imposteContribuenteConta
    def ruoliContribuenteConta
    def numDocumenti = 0
    def numContrattiUtenze = 0
    def numContrattiLocazioni = 0
    int numStatiContribuente = 0

    def latestStatiDescriptions = [:]

    def totaleImposta = 0
    def totaleVersato = 0
    def totaleResiduo = 0
    def visualizzaDovuto
    def aggiornaListaContribuenti = false

    def toolbarLocazioni = true
    def locazioniPaginazione = [max       : 9999,
                                offset    : 0,
                                activePage: 0]

    def utenzePaginazione = [max       : 9999,
                             offset    : 0,
                             activePage: 0]

    def utenzeOrderBy = [[property: 'uted.annoRiferimento', direction: 'desc'],
                         [property: 'uted.tipoUtenza.tipoFornitura', direction: 'desc']]
    def locazioniOrderBy = [[property: 'anno', direction: 'desc'],
                            [property: 'dataStipula', direction: 'desc'],
                            [property: 'dataFine', direction: 'desc']]

    def tipoUtenza = '*'

    def contattoSelezionato

    def forzaCaricamentoTab = ['concessioni': false,
                               'oggetti'    : false,
                               'versamenti' : false,
                               'imposte'    : true,
                               'contatti'   : false,
                               'ruoli'      : true,
                               'familiari'  : false,
                               'contratti'  : true]

    def tipiRavvedimento = ['null': 'Non trattato',
                            'N'   : 'Ravv. su Versamento',
                            'O'   : 'Ravv. su Omessa Denuncia',
                            'I'   : 'Ravv. su Infedele Denuncia']

    def differenzeOggetti = [:]

    def immobiliNonAssociatiCatasto = [:]
    def immobiliNonAssociatiDatiMetrici = [:]
    def datiMetriciSelezionato = null

    String tabSelezionata = "oggetti"

    def tipiTributoActive
    def cbTributi
    def cbTributiLabels = [:]
    def cbTipiPratica

    def cbTipoRuolo = [1: 'P',
                       2: 'S']

    def cbTipoCalcolo = [T: 'Tradizionale',
                         N: 'Normalizzato',
                         X: '']

    def cbTipoEmissione = [A: 'Acconto',
                           S: 'Saldo',
                           T: 'Totale',
                           X: '']

    def cbSpecieRuolo = [ORDINARIO: true,
                         COATTIVO : true]

    // mappa degli zul relativi alle pratiche da aprire sulla base di:
    // - Tipo Tributo
    // - Tipo Pratica
    // - Tipo Evento
    Map caricaPannello = ["ICI"    : ["D"  : ["I": [zul      : "/pratiche/denunce/denunciaImu.zul"
                                                    , lettura: false],
                                              "C": [zul      : "/pratiche/denunce/denunciaImu.zul"
                                                    , lettura: false]]
                                      , "L": ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "liquidazione"],
                                              "R": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "liquidazione"]]
                                      , "A": ["T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : true
                                                    , situazione: "accTotImu"],
                                              "U": [zul         : "pratiche/violazioni/accertamentiManuali.zul"
                                                    , lettura   : false
                                                    , situazione: "accManImu"]]
                                      , "V": ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvImu"],
                                              "S": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvImu"],
                                              "A": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvImu"]]]
                          , "TARSU": ["D"  : ["C": [zul      : "/pratiche/denunce/denunciaTari.zul"
                                                    , lettura: false],
                                              "I": [zul      : "/pratiche/denunce/denunciaTari.zul"
                                                    , lettura: false],
                                              "U": [zul      : "/pratiche/denunce/denunciaTari.zul"
                                                    , lettura: false],
                                              "V": [zul      : "/pratiche/denunce/denunciaTari.zul"
                                                    , lettura: false]]
                                      , "A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTari.zul"
                                                    , lettura   : false
                                                    , situazione: "accAutoTari"],
                                              "U": [zul         : "pratiche/violazioni/accertamentiManuali.zul"
                                                    , lettura   : false
                                                    , situazione: "accManTari"],
                                              "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : false
                                                    , situazione: "accTotTari"]]
                                      , "S": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTari.zul"
                                                    , lettura   : false
                                                    , situazione: "solAutoTari"]]
                                      , "V": ["U" : [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTari"],
                                              "R0": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTari"]]]
                          , "TASI" : ["D"  : ["I": [zul      : "/pratiche/denunce/denunciaTasi.zul"
                                                    , lettura: false],
                                              "C": [zul      : "/pratiche/denunce/denunciaTasi.zul"
                                                    , lettura: false]]
                                      , "L": ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "liquidazione"],
                                              "R": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "liquidazione"]]
                                      , "A": ["T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : true
                                                    , situazione: "accTotImu"],
                                              "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : true
                                                    , situazione: "accManImu"]]
                                      , "V": ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvTasi"],
                                              "S": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvTasi"],
                                              "A": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                    , lettura   : false
                                                    , situazione: "ravvTasi"]]]
                          , "ICP"  : ["A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                                  , lettura   : false
                                                  , situazione: "accAutoTribMin"],
                                            "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                  , lettura   : true
                                                  , situazione: "accManTribMin"],
                                            "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                  , lettura   : true
                                                  , situazione: "accTotTribMin"]]]
                          , "TOSAP": ["A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                                  , lettura   : false
                                                  , situazione: "accAutoTribMin"],
                                            "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                  , lettura   : true
                                                  , situazione: "accManTribMin"],
                                            "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                  , lettura   : true
                                                  , situazione: "accTotTribMin"]]]
                          , "CUNI" : ["D"  : ["I": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                                                    , lettura: false],
                                              "U": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                                                    , lettura: false],
                                              "V": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                                                    , lettura: false],
                                              "C": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                                                    , lettura: false]]
                                      , "A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                                    , lettura   : false
                                                    , situazione: "accAutoTribMin"],
                                              "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : true
                                                    , situazione: "accManTribMin"],
                                              "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                                    , lettura   : true
                                                    , situazione: "accTotTribMin"]]
                                      , "V": ["R0": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTribMin"],
                                              "R1": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTribMin"],
                                              "R2": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTribMin"],
                                              "R3": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTribMin"],
                                              "R4": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                                     , lettura   : false
                                                     , situazione: "ravvTribMin"]]
                                      , "S": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                                                    , lettura   : false
                                                    , situazione: "solAutoTribMin"]]]]

    def ordineInizialePratiche = [tipoTributo: [id       : 'tipoTributo',
                                                label    : Labels.getLabel("sportello.label.estesa.tipoTributo"),
                                                verso    : OrdinamentoMultiColonnaComponent.VERSO_ASC,
                                                posizione: 0,
                                                attivo   : true],
                                  tipoPratica: [id       : 'tipoPratica',
                                                label    : Labels.getLabel("sportello.label.estesa.tipoPratica"),
                                                verso    : OrdinamentoMultiColonnaComponent.VERSO_ASC,
                                                posizione: 1,
                                                attivo   : true],
                                  anno       : [id       : 'anno',
                                                label    : Labels.getLabel("sportello.label.estesa.anno"),
                                                verso    : OrdinamentoMultiColonnaComponent.VERSO_DSC,
                                                posizione: 2,
                                                attivo   : true],
                                  data       : [id       : 'data',
                                                label    : Labels.getLabel("sportello.label.estesa.data"),
                                                verso    : OrdinamentoMultiColonnaComponent.VERSO_DSC,
                                                posizione: 3,
                                                attivo   : true],]

    FiltroRicercaOggetto filtroRicercaOggetto
    String mostraOggetti = "tutti"

    int pageSize = 10
    int activePage = 0
    int totalSize = 0

    def abilitaMappe = false

    SituazioneContribuenteParametri scp
    JsonSlurper jsonSlurper = new JsonSlurper()

    def oggettiDaCatasto = []
    def immobileCatastoSelezionato
    def zulOggetti
    def vflexOggCat = '1'

    def dePagAbilitato = false
    def inAnagrafeTributaria = false
    def smartPndAbilitato = false

    // Non utilizzato in questo view model, permette di utilizzare la tabella degli oggetti catastali
    // in altre pagine.
    def azione
    def oggettiSelezionati

    def forceQuery = false

    // Competenze
    def cbTributiAbilitati = [:]
    def cbTributiInScrittura = [:]
    def abilitaRavvOperoso
    def abilitaCalcIndividuale

    boolean filtroRuoliAttivo = false
    boolean filtroSvuotamentiAttivo = false

    def filtroRuoli = [:]
    def filtroSvuotamenti = [:]

    //Bonifiche versamenti
    def numBonifiche = 0
    def listaDettaglioAnomalie
    def dettaglioAnomaliaSelezionato
    def anci = false

    def utilizziTooltipText = [:]
    def alogTooltipText = [:]
    def altricntTooltipText = [:]
    def pertinenzeDiTooltipText = [:]
    def familiariTooltipText = [:]
    def aliquoteMultipleTooltipText = [:]
    def svuotamentiTooltipText = [:]

    def listaMotiviCompensazioni
    def filtriCompensazioni = [:]
    def numCompensazioni = 0
    def numSvuotamenti = 0
    def listaCompensazioni
    def compensazioneSelezionata
    def svuotamentoSelezionato
    def filtroCompensazioniAttivo = false

    def urlPortale
    def aggiornaDovutiDepAgCU = false
    def annullaDovutiDepAgCU = false

    boolean standalone

    def isContribuente = true

    def disabilitaDataNotificaSuRateazione = [:]

    @NotifyChange(["listaPratiche",
            "listaOggetti",
            "listaVersamenti",
            "listaRuoli",
            "listaContatti",
            "listaImposte",
            "listaDocumenti",
            "listaContratti"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idSoggetto") long idSoggetto,
         @ExecutionArgParam("standalone") Boolean standalone) {

        this.self = w

        filtriConcessioni = new FiltroRicercaCanoni()

        // Caricamento iniziale per inizializzare il bean
        caricaParametri()

        // Verifica le competenze
        verificaCompetenze()

        controllaTributiPerVersamenti()

        listaTipiAtto = [null] + TipoAtto.list().sort { it.tipoAtto }.toDTO()
        abilitaMappe = integrazioneWEBGISService.integrazioneAbilitata()

        soggetto = Soggetto.get(idSoggetto).toDTO(["contribuenti",
                                                   "comuneResidenza",
                                                   "comuneResidenza.ad4Comune",
                                                   "archivioVie",
                                                   "stato"])

        if (!soggetto.contribuente) {
            isContribuente = false
        }

        if (isContribuente) {

            // Il codice fiscale che deve essere usato per interrogare la situazione del contribuente è sempre quello della tabella CONTRIBUENTI.
            // Questo perche' il soggetto potrebbe essere legato all'anagrafe e il codice fiscale potrebbe variare (incompleto, provvisorio, uguale ad un altro)

            //Reso variabile globale per non dare errore anche su Inserisic oggetti su Contribuneti (situazioneContribuenteOggettiCatasto.zul)
            codFiscale = soggetto?.contribuente?.codFiscale

            listaAnni = listaAnni ?: contribuentiService.anniOggettiContribuente(soggetto.contribuente.codFiscale, cbTributi, true)
            listaTributiAnni = listaTributiAnni ?: contribuentiService.anniTributo(soggetto.contribuente.codFiscale)

            aggiornaIndiciTab()

            aggiornaUltimoStato()

            onRefresh()

            notificaPresenzaDenunceDaPortale()
        } else {
            aggiornaUltimoStato()
            // Situazione del contribuente aperta tramite un soggetto che non è contribuente

            codFiscale = soggetto?.codFiscale ?: soggetto?.partitaIva

            listaAnni = listaAnni ?: []
            listaTributiAnni = listaTributiAnni ?: []

            if (soggetto.stato) {
                ultimoStato = soggetto.stato.descrizione
                if (soggetto.dataUltEve) {
                    ultimoStato += " il " + soggetto.dataUltEve.format('dd/MM/yyyy')
                }
            }

            // Si attivano i tipi tributo in base ai permessi
            cbTributi.each {
                if (cbTributiInScrittura[it.key]) {
                    it.value = true
                } else {
                    it.value = false
                }
            }

            // Si attivato tutti i tipi pratica
            cbTipiPratica.each {
                it.value = true
            }

            Clients.showNotification("Il soggetto corrente non è un contribuente", Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)

        }

        dePagAbilitato = integrazioneDePagService.dePagAbilitato()
        smartPndAbilitato = smartPndService.smartPNDAbilitato()

        convertiConcessioni = canoneUnicoService.conversioneAbilitata()

        inAnagrafeTributaria = anagrafeTributariaService.inAnagrafeTributaria(soggetto?.contribuente?.codFiscale)

        urlPortale = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'URL_PORTAL' }?.valore

        this.standalone = standalone ?: false

        tempStringNoteSoggetto = soggetto.note

        OggettiCache.TIPI_TRIBUTO.valore.each { tipoTributo -> cbTributiLabels[tipoTributo.tipoTributo] = tipoTributo.tipoTributoAttuale
        }

        tipiTributoActive = OggettiCache.TIPI_TRIBUTO.valore.
                findAll {
                    it.visibileInSportello
                }
                .sort { it.ordine }.collect { it.tipoTributo }

        refreshLastStatiDescriptions()
    }

    @GlobalCommand
    void refreshLastStatiDescriptions() {
        def latestStati = statoContribuenteService.findLatestStatiContribuente([codFiscale])
        latestStatiDescriptions = statoContribuenteService.getStatiContribuenteDescription(latestStati).get(codFiscale)
        aggiornaListaContribuenti = true
        BindUtils.postNotifyChange(null, null, this, "latestStatiDescriptions")
    }

    @AfterCompose
    void postInit() {
        if (!isContribuente) {
            tabPratiche.selected = true
            Events.sendEvent("onSelect", tabPratiche, null);
            onRefresh()
        } else if (cbTributi.count { it.value } == 1 && cbTributi.CUNI) {
            tabConcessioni.selected = true
            Events.sendEvent("onSelect", tabConcessioni, null);
            onRefresh()
        }
    }

    private void aggiornaFiltroRuoliAttivo() {
        filtroRuoliAttivo = filtroRuoli.ruoloDa || filtroRuoli.ruoloA || filtroRuoli.annoDa || filtroRuoli.annoA
        BindUtils.postNotifyChange(null, null, this, "filtroRuoliAttivo")
    }

    private void aggiornaFiltroSvuotamentiAttivo() {
        filtroSvuotamentiAttivo = filtroSvuotamenti.rfid || filtroSvuotamenti.dataSvuotamentoDa || filtroSvuotamenti.dataSvuotamentoA
        BindUtils.postNotifyChange(null, null, this, "filtroSvuotamentiAttivo")
    }

    @Command
    openCloseFiltriRuoli() {

        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteRuoliRicerca.zul",
                self,
                [filtroRuoli: filtroRuoli],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtroRuoli = event.data.parRicerca
                            aggiornaFiltroRuoliAttivo()
                            caricaRuoli(true)
                            aggiornaIndiciTab()
                        }
                        if (event.data.status == "Chiudi") {
                            boolean reset = event.data.resetParams
                            if (reset) {
                                filtroRuoli.ruoloDa = null
                                filtroRuoli.ruoloA = null
                                aggiornaFiltroRuoliAttivo()
                                caricaRuoli(true)
                            }
                        }
                    }
                })
    }

    @Command
    openCloseFiltriSvuotamenti() {

        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteSvuotamentiRicerca.zul",
                self,
                [contribuente     : soggetto.contribuente,
                 filtroSvuotamenti: filtroSvuotamenti],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtroSvuotamenti = event.data.parRicerca
                            aggiornaFiltroSvuotamentiAttivo()
                            caricaSvuotamenti()
                            aggiornaIndiciTab()
                        }
                        if (event.data.status == "Chiudi") {
                            boolean reset = event.data.resetParams
                            if (reset) {
                                filtroRuoli.ruoloDa = null
                                filtroRuoli.ruoloA = null
                                aggiornaFiltroSvuotamentiAttivo()
                                caricaSvuotamenti()
                                aggiornaIndiciTab()
                            }
                        }
                    }
                })
    }

    def aggiornaUltimoStato() {

        if (soggetto?.stato) {
            ultimoStato = soggetto.stato.descrizione
            if (soggetto.dataUltEve) {
                ultimoStato += " il " + soggetto.dataUltEve.format('dd/MM/yyyy')
            }
        } else {
            ultimoStato = ""
        }
        BindUtils.postNotifyChange(null, null, this, "ultimoStato")
    }

    def aggiornaIndiciTab() {

        imposteContribuenteConta = imposteContribuenteConta ?: contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale, true)
        ruoliContribuenteConta = ruoliContribuenteConta ?: contribuentiService.ruoliContribuente(soggetto.contribuente.codFiscale, true)

        if ((listaFamiliari ?: []).empty) {
            caricaFamiliari(true)
        }

        if ((listaContatti ?: []).empty) {
            caricaContatti(true)
        }

        if ((listaDettaglioAnomalie ?: []).empty) {
            caricaVersamentiBonifiche()
        }

        numPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                "count",
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key })[0].count

        numDocumenti = contribuentiService.documentiContribuente(codFiscale, 'count')

        aggiornaIndiceOggetti()

        if ((listaSvuotamenti ?: []).empty) {
            caricaSvuotamenti()
        }

        numVersamenti = contribuentiService.versamentiContribuente(codFiscale, 'count',
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key })

        numImposte = listaImposte == null ? imposteContribuenteConta.findAll { cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica] }.size() : listaImposte.findAll { cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica] }.size()
        numContatti = listaContatti?.size() ?: 0
        numRuoli = listaRuoli == null ? ruoliContribuenteConta.findAll { cbTributi[it.tipoTributo] }.size() : (listaRuoli.findAll { cbTributi[it.tipoTributo] }?.size() ?: 0)
        numFamiliari = listaFamiliari?.size() ?: 0

        numContrattiUtenze = contribuentiService.countUtenze([codFiscale: soggetto.contribuente.codFiscale])
        numContrattiLocazioni = contribuentiService.countLocazioni([codFiscale: soggetto.contribuente.codFiscale])

        numStatiContribuente = statoContribuenteService.countStatiContribuente([codFiscale : soggetto?.contribuente?.codFiscale,
                                                                                tipiTributo: getTipiTributoSelezionati()])

        numSvuotamenti = listaSvuotamenti.size()

        cuAggiornaIndiciTab()

        aggiornaNumeroCompensazioni()

        BindUtils.postNotifyChange(null, null, this, "numBonifiche")
        BindUtils.postNotifyChange(null, null, this, "numPratiche")
        BindUtils.postNotifyChange(null, null, this, "numDocumenti")
        BindUtils.postNotifyChange(null, null, this, "numVersamenti")
        BindUtils.postNotifyChange(null, null, this, "numImposte")
        BindUtils.postNotifyChange(null, null, this, "numContatti")
        BindUtils.postNotifyChange(null, null, this, "numRuoli")
        BindUtils.postNotifyChange(null, null, this, "numFamiliari")
        BindUtils.postNotifyChange(null, null, this, "numContrattiUtenze")
        BindUtils.postNotifyChange(null, null, this, "numContrattiLocazioni")
        BindUtils.postNotifyChange(null, null, this, "numStatiContribuente")
        BindUtils.postNotifyChange(null, null, this, "numSvuotamenti")
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        tabSelezionata = tabId
        aggiornaParametri()

        if (!isContribuente) {
            return
        }

        switch (tabId) {

            case 'oggetti':
                if (forceQuery) {
                    caricaListaContribuentiSotria()
                }

                try {
                    (self.getFellow("includeOggetti").getFellow("gridSitContrOggetti")
                            as Listbox)
                            .invalidate()
                } catch (Exception e) {
                    log.info "gridSitContrOggetti non caricata."
                }
                toolbarLocazioni = false
                BindUtils.postNotifyChange(null, null, this, "toolbarLocazioni")
                break
            case "imposte":
                caricaImposte(forceQuery)
                break
            case "versamenti":
                caricaVersamenti(forceQuery)
                caricaVersamentiBonifiche()
                break
            case 'ruoli':
                caricaRuoli(forceQuery)
                aggiornaIndiciTab()
                break
            case "pratiche":
                caricaPratiche(forceQuery)
                break
            case 'contatti':
                caricaContatti()
                break
            case 'familiari':
                caricaFamiliari()
                if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
                    Clients.showNotification("Attenzione. Sono presenti più periodi aperti.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                }
                break
            case "documenti":
                listaDocumenti = documentiContribuenteSmartPND(codFiscale)
                BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
                documentoSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
                fetchListaAllegati()
                break
            case 'contratti':
                toolbarLocazioni = true
                BindUtils.postNotifyChange(null, null, this, "toolbarLocazioni")

                listaContrattiUtenze = listaContrattiUtenze ?: contribuentiService.caricaUtenze([codFiscale: soggetto.contribuente.codFiscale,
                                                                                                 tipologia : tipoUtenza]
                        , utenzePaginazione,
                        utenzeOrderBy).record
                listaContrattiLocazioni = listaContrattiLocazioni ?: contribuentiService.caricaLocazioni([codFiscale: soggetto.contribuente.codFiscale], locazioniPaginazione,
                        locazioniOrderBy).record
                BindUtils.postNotifyChange(null, null, this, "listaContrattiUtenze")
                BindUtils.postNotifyChange(null, null, this, "listaContrattiLocazioni")

                break
            case 'concessioni':
                cuCaricaListaConcessioni()
                try {
                    (self.getFellow("includeConcessioni").getFellow("gridSitContrConcessioni")
                            as Listbox)
                            .invalidate()
                } catch (Exception e) {
                    log.info "gridSitContrConcessioni non caricata."
                }
                toolbarLocazioni = false
                BindUtils.postNotifyChange(null, null, this, "toolbarLocazioni")
                break
            case 'comTarsu':
                initFiltriCompensazioni()
                caricaCompensazioni()
                break
            case "svuotamentiTarsu":
                caricaSvuotamenti()
                break
            case 'statiContribuente':
                refreshFolderStati()
                break
            default:
                forceQuery = false
        }

        if (forzaCaricamentoTab[tabSelezionata]) {
            onRefresh()
            forzaCaricamentoTab[tabSelezionata] = false
        }
    }

    @Command
    onChiudiPopup() {

        if (modificaPraticaInline) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
            Messagebox.show("Salvare le modifiche?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    def pratica = PraticaTributo.get(praticaSelezionata.id)
                                    pratica.dataNotifica = praticaSelezionata.dataNotificaDate
                                    pratica.tipoAtto = praticaSelezionata.tipoAtto ? praticaSelezionata.tipoAtto.toDomain() : null
                                    pratica.save(flush: true, failOnError: true)
                                    Sessions.getCurrent().removeAttribute("oggettoDaStuazioneContribuente")
                                    Events.postEvent(Events.ON_CLOSE, self, null)
                                    break
                                case Messagebox.ON_NO:
                                    Sessions.getCurrent().removeAttribute("oggettoDaStuazioneContribuente")
                                    Events.postEvent(Events.ON_CLOSE, self, null)
                                    break
                                case Messagebox.ON_CANCEL:
                                    return
                            }
                        }
                    }, params)
        } else {
            Sessions.getCurrent().removeAttribute("oggettoDaStuazioneContribuente")
            Events.postEvent(Events.ON_CLOSE, self, aggiornaListaContribuenti ? [aggiornaListaContribuenti: true] : null)
        }
    }

    private String selezionaTipoTributo() {

        if (cbTributi.ICI) {
            return "ICI"
        } else {
            if (cbTributi.TASI) {
                return "TASI"
            } else {
                return "ICI"
            }
        }
    }

    @Command
    onCalcoloIndividuale() {
        //Se l'anno selezionato negli oggetti è Tutti viene definito anno corrente
        Calendar calendar = Calendar.getInstance()
        short annoCorrente = calendar.get(Calendar.YEAR)
        short annoSelezionato = (anno == "Tutti") ? annoCorrente : Short.valueOf(anno)
        String tipo = selezionaTipoTributo()
        Window w = Executions.createComponents("/sportello/contribuenti/calcoloIndividuale.zul", self
                , [idSoggetto       : soggetto.id, tipoTributo: praticaSelezionata?.tipoTributo?.tipoTributo
                   , tipoTributoPref: tipo, annoSelezionato: annoSelezionato])

        w.onClose() { event ->
            forzaCaricamentoTab.each { it.value = true }
            onRefresh()
        }

        w.doModal()
    }

    @Command
    onModificaPratica() {

        if (!existsViewForPratica()) {
            return
        }

        if (modificaPraticaInline) {
            Clients.showNotification("E' necessario salvare le modifiche in corso",
                    Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            return
        }

        String tipoT = praticaSelezionata.tipoTributo.tipoTributo
        String tipoP = praticaSelezionata.tipoPratica
        String tipoE = praticaSelezionata.tipoEvento
        String tipoR = praticaSelezionata.tipoRapporto

        // Se TASI il tipo_rapporto può essere diverso per il denunciante, per IMU no
        if (praticaSelezionata.tipoTributo.tipoTributo == 'ICI') {
            // Se non si effettua questo controllo si rischia di portare C nella dichiarazione
            // ma una dichiarazione ICI/IMU non può essere creata con un rapporto_tributro di
            // tipo contitolare.
            tipoR = 'D'
        }

        boolean lettura
        boolean datiDLA
        String situazione
        String zul

        zul = caricaPannello."${tipoT}"."${tipoP}"."${tipoE}".zul
        lettura = caricaPannello."${tipoT}"."${tipoP}"."${tipoE}".lettura
        if (!lettura) {
            lettura = competenzeService.tipoAbilitazioneUtente(tipoT) == competenzeService.TIPO_ABILITAZIONE.LETTURA
        }
        situazione = caricaPannello."${tipoT}"."${tipoP}"."${tipoE}".situazione

        def onClose = { event ->
            if (event?.data?.praticaEliminata) {
                if (Soggetto.get(soggetto.id).contribuente == null) {
                    Messagebox.show("Il contribuente è stato eliminato.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION, { evnt -> closeCurrentAndRefreshListaContribuente()
                    })
                } else {
                    caricaPratiche(true)
                    listaOggettiPratica = []
                    praticaSelezionata = null
                    oggettoPraticaSelezionato = null

                    caricaListaContribuentiSotria()

                    BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                    BindUtils.postNotifyChange(null, null, this, "listaPratiche")
                    BindUtils.postNotifyChange(null, null, this, "listaOggettiPratica")
                    BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
                    BindUtils.postNotifyChange(null, null, this, "oggettoPraticaSelezionato")
                }

            } else {
                caricaPratiche(true)
                listaOggettiPratica = []
                praticaSelezionata = null
                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                BindUtils.postNotifyChange(null, null, this, "listaPratiche")
                BindUtils.postNotifyChange(null, null, this, "listaOggettiPratica")
                BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
                BindUtils.postNotifyChange(null, null, this, "oggettoPraticaSelezionato")
            }
        }

        commonService.creaPopup(zul, self,
                [pratica     : praticaSelezionata.id,
                 tipoRapporto: tipoR,
                 lettura     : lettura,
                 situazione  : situazione,
                 daBonifiche : false], onClose)
    }

    private boolean existsViewForPratica() {
        String tipoTributo = praticaSelezionata.tipoTributo.tipoTributo
        String tipoPratica = praticaSelezionata.tipoPratica
        String tipoEvento = praticaSelezionata.tipoEvento

        return caricaPannello."${tipoTributo}" && caricaPannello."${tipoTributo}"."${tipoPratica}" && caricaPannello."${tipoTributo}"."${tipoPratica}"?."${tipoEvento}"
    }

    @Command
    onAnniPrecedenti() {

    }

    @Command
    onChangeTipoTributo() {

        forceQuery = true

        controllaTributiPerVersamenti()

        aggiornaParametri()
        aggiornaAnni()
        aggiornaIndiciTab()

        setTipiTributoFolderStati()

        switch (tabSelezionata) {
            case 'oggetti':
                onRefresh()

                try {
                    (self.getFellow("includeOggetti").getFellow("gridSitContrOggetti")
                            as Listbox)
                            .invalidate()
                } catch (Exception e) {
                    log.info "gridSitContrOggetti non caricata."
                }
                break
            case 'imposte':
            case 'versamenti':
            case 'ruoli':
            case 'pratiche':
            case 'concessioni':
                onRefresh()
                break
            case 'contatti':
                onRefresh()
                break
            case 'familiari':
                // Nulla da fare
                break
            case 'documenti':
                // Nulla da fare
                break
            case 'contratti':
                // Nulla da fare
                break
            case 'statiContribuente':
                refreshFolderStati()
                break
        }

        BindUtils.postNotifyChange(null, null, this, "contaTributiSelezionati")
    }

    private void setTipiTributoFolderStati() {
        try {
            SituazioneContribuenteStatiViewModel folderStatiViewModel =
                    (SituazioneContribuenteStatiViewModel) self.getFellow('includeStatiContribuente')
                            .children[0].getAttribute('vm')
            folderStatiViewModel.setTipiTributo(getTipiTributoSelezionati())

        } catch (Exception e) {
            log.info "includeStatiContribuente non caricata."
        }
    }

    private void refreshFolderStati() {
        try {
            SituazioneContribuenteStatiViewModel folderStatiViewModel =
                    (SituazioneContribuenteStatiViewModel) self.getFellow('includeStatiContribuente')
                            .children[0].getAttribute('vm')
            folderStatiViewModel.onRefresh()

        } catch (Exception e) {
            log.info "includeStatiContribuente non caricata."
        }
    }

    @Command
    onChangeTipoPratica() {

        forceQuery = true

        if (cbTipiPratica.L) {
            cbTipiPratica.I = true
        } else {
            cbTipiPratica.I = false
            cbTipiPratica.L = false
        }

        aggiornaParametri()
        aggiornaAnni()
        aggiornaIndiciTab()

        switch (tabSelezionata) {
            case 'oggetti':
                onRefresh()

                try {
                    (self.getFellow("includeOggetti").getFellow("gridSitContrOggetti")
                            as Listbox)
                            .invalidate()
                } catch (Exception e) {
                    log.info "gridSitContrOggetti non caricata."
                }
                break
            case 'imposte':
                break
            case 'versamenti':
                onRefresh()
                break
            case 'ruoli':
                break
            case 'pratiche':
                onRefresh()
                break
            case 'contatti':
                // Nulla da fare
                break
            case 'familiari':
                break
            case 'documenti':
                break
            case 'contratti':
                break
            case 'concessioni':
                onRefresh()
                break
        }
    }

    @Command
    onChangeSpecieRuolo() {
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
    }

    @Command
    def onCorreggiSuperficieTarsu(@BindingParam("ogg") def ogg, @BindingParam("errore") Boolean errore) {

        if (anno == 'Tutti') {
            Clients.showNotification('Selezionare un anno per attivare la funzionalità di bonifica'
                    , Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 5000, true)

            return
        }

        Window w = null

        w = Executions.createComponents("/sportello/contribuenti/bonificaSuperficieDatiMetrizi.zul", self,
                [anno       : anno,
                 soggetto   : soggetto,
                 oggetto    : oggettoSelezionato,
                 datoMetrico: datiMetriciSelezionato])

        w.onClose() { e ->
            if (e.data?.variazioneCreata) {
                caricaListaContribuentiSotria()
                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    creaAssociazioneOggetti()
                }
                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
            }
        }

        w.doModal()

    }

    @Command
    def onApriOgPr(@BindingParam("ogg") def ogg, @BindingParam("errore") Boolean errore) {

        if (!errore) {
            onModificaOggetto('OGGETTO')
            return
        }

        def listaOggetti = denunceService.oggettiDenuncia(ogg.pratica as Long, soggetto.contribuente.codFiscale)

        def oggCat = oggettiDaCatasto.find { c -> c.IDIMMOBILE == ogg.idImmobile && c.RIGA == ogg.rigaCatastoSelezionata }

        def w = Executions.createComponents("/pratiche/denunce/oggettoContribuente.zul", self,
                [idOggPr       : ogg.oggettoPratica,
                 contribuente  : soggetto.contribuente.codFiscale,
                 tipoRapporto  : ogg.tipoRapporto,
                 tipoTributo   : ogg.tipoTributo,
                 idOggetto     : -1, //ogg.oggetto
                 pratica       : PraticaTributo.get(ogg.pratica).toDTO(),
                 oggPr         : null,
                 oggCo         : null,
                 listaId       : listaOggetti,
                 indexSelezione: 0,
                 modifica      : true,
                 daBonifiche   : false,
                 preVal        : [percPossesso: oggCat.POSSESSOPERC,
                                  mesiPossesso: contribuentiService.calcolaMesi(oggCat.DATAINIZIOVALIDITA,
                                          oggCat.DATAFINEVALIDITA,
                                          anno as Integer)?.mp]])

        w.onClose { e ->
            if (e?.data?.salvato) {

                def oggSel = oggettoSelezionato

                calcolaImposta([ogg.tipoTributo])

                caricaListaContribuentiSotria()

                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    creaAssociazioneOggetti()
                }
                oggettoSelezionato = this.listaOggetti.find { it.key == oggSel.key }
                differenzeOggetti = confrontoArchivioBancheDatiService
                        .aggiornaDifferenzeOggettiCatasto(this.listaOggetti, oggettiDaCatasto, immobiliNonAssociatiCatasto, cbTributi, anno)

                immobileCatastoSelezionato = confrontoArchivioBancheDatiService.oggettoCatastoSelezionato(oggettoSelezionato, oggettiDaCatasto)
                BindUtils.postNotifyChange(null, null, this, "immobileCatastoSelezionato")

                BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
                BindUtils.postNotifyChange(null, null, this, "differenzeOggetti")
                BindUtils.postNotifyChange(null, null, this, "immobileCatastoSelezionato")

            }
        }
        w.doModal()
    }

    private void aggiornaAnni() {

        listaAnni = contribuentiService.anniOggettiContribuente(soggetto.contribuente.codFiscale, cbTributi, true)
        // Si aggiorna l'anno solo se non è Tutti e quello precedentemente selezionato non è in lista
        if (anno != 'Tutti' && !listaAnni.contains(anno as Short)) {
            anno = 'Tutti'
        }

        BindUtils.postNotifyChange(null, null, this, "listaAnni")
        BindUtils.postNotifyChange(null, null, this, "anno")
        BindUtils.postNotifyChange(null, null, this, "numOggetti")

        BindUtils.postNotifyChange(null, null, this, "numConcessioni")
    }

    @Command
    onSelezionaImposta() {
        listaOggettiImposta = contribuentiService.oggettiImposteContribuente(soggetto.contribuente.codFiscale
                , impostaSelezionata.anno
                , impostaSelezionata.tipoTributo
                , impostaSelezionata.tipoPratica)

        captionlistaOggettiImposta = "Oggetti dell'imposta (${listaOggettiImposta.size})"

        switch (impostaSelezionata.tipoTributo) {
            case ['ICI', 'TASI']:
                impostaOggettiTable = "/sportello/contribuenti/situazioneContribuentiImposteOggettiICI.zul"
                break
            case ['TARSU', 'ICP', 'TOSAP']:
                controllaCarichiTarsu(impostaSelezionata.anno)
                impostaOggettiTable = "/sportello/contribuenti/situazioneContribuentiImposteOggettiTARSU.zul"
                break
            case 'CUNI':
                impostaOggettiTable = "/sportello/contribuenti/situazioneContribuentiImposteOggettiCUNI.zul"
                break
            default:
                impostaOggettiTable = "/sportello/contribuenti/situazioneContribuentiImposteOggetti.zul"
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggettiImposta")
        BindUtils.postNotifyChange(null, null, this, "impostaOggettiTable")
        BindUtils.postNotifyChange(null, null, this, "captionlistaOggettiImposta")
    }

    @Command
    onSelezionaPratica() {

        praticaOpenableFromFolderPratiche = existsViewForPratica()
        BindUtils.postNotifyChange(null, null, this, 'praticaOpenable')

        if (modificaPraticaInline) {

            praticaSelezionata = listaPratiche.find { it.id == praticaSelezionataPrecedenteId }

            BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
            Messagebox.show("Modifica in corso, impossibile selezionare un'altra pratica.")
            return
        }

        praticaSelezionataPrecedenteId = praticaSelezionata.id

        listaOggettiPratica = contribuentiService.oggettiPraticaContribuente(praticaSelezionata.id
                , soggetto.contribuente.codFiscale
                , praticaSelezionata.tipoTributo.tipoTributo)

        switch (praticaSelezionata.tipoTributo.tipoTributo) {
            case ['ICI', 'TASI']:
                praticaOggettiTable = "/sportello/contribuenti/situazioneContribuentiPraticheOggettiICI.zul"
                break
            case ['TARSU', 'ICP', 'TOSAP']:
                praticaOggettiTable = "/sportello/contribuenti/situazioneContribuentiPraticheOggettiTARSU.zul"
                break
            case 'CUNI':
                praticaOggettiTable = "/sportello/contribuenti/situazioneContribuentiPraticheOggettiTARSU.zul"
                break
            default:
                praticaOggettiTable = "/sportello/contribuenti/situazioneContribuentiPraticheOggetti.zul"
        }

        oggettoPraticaSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "oggettoPraticaSelezionato")
        BindUtils.postNotifyChange(null, null, this, "praticaOggettiTable")
        BindUtils.postNotifyChange(null, null, this, "listaOggettiPratica")
        BindUtils.postNotifyChange(null, null, this, "disabilitaStampaF24")
    }

    @Command
    onSortPratiche(@BindingParam("valore") String valore) {
        def ordinamentoMultiColonnaPratiche = self.getFellow('includePratiche').getFellow('ordinamentoMultiColonnaPratiche') as OrdinamentoMultiColonnaComponent
        campiOrdinamentoPratiche = ordinamentoMultiColonnaPratiche.cambiaOrdinamento(valore)
        caricaPratiche(true)
        aggiornaParametri()
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamentoPratiche")
    }

    @Command
    onCambiaOrdinamentoPratiche() {
        caricaPratiche(true)
        aggiornaParametri()
        BindUtils.postNotifyChange(null, null, this, "campiOrdinamentoPratiche")
    }

    @Command
    def onClickOggettoRuolo(@BindingParam("popup") Component popup) {
        popup.visible = true
    }

    @Command
    def onSelezionaRuolo(@BindingParam("popup") Component popup) {

        ruoloSelezionato.anyDovutiRuolo = integrazioneDePagService.dePagAbilitato() ? !integrazioneDePagService.determinaDovutiRuolo(ruoloSelezionato.codFiscale, ruoloSelezionato.ruolo).empty : false


        def modificaRuoloNew = modificaRuoloAbititato(ruoloSelezionato.tipoTributo)

        if (modificaRuolo != modificaRuoloNew) {
            modificaRuolo = modificaRuoloNew
            BindUtils.postNotifyChange(null, null, this, "modificaRuolo")
        }

        if (ruoloSelezionato.specie.toUpperCase() == 'COATTIVO') {
            ruoliDettaglioTable = '/sportello/contribuenti/situazioneContribuenteRuoliPratiche.zul'
            listaPraticheRuolo = contribuentiService.praticheRuolo(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo)
            BindUtils.postNotifyChange(null, null, this, "listaPraticheRuolo")
            this.praticaSelezionata = null
            BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
        } else {
            ruoliDettaglioTable = '/sportello/contribuenti/situazioneContribuenteRuoliOggetti.zul'
            listaOggettiRuolo = contribuentiService.oggettiRuolo(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo)
            oggettoRuoloSelezionato = null
            BindUtils.postNotifyChange(null, null, this, "listaOggettiRuolo")
            BindUtils.postNotifyChange(null, null, this, "oggettoRuoloSelezionato")
        }

        popup.visible = true

        BindUtils.postNotifyChange(null, null, this, "ruoliDettaglioTable")
    }

    @Command
    def onEmissioneRuolo() {

        def lettura = true

        commonService.creaPopup("/sportello/contribuenti/emissioneRuolo.zul", self,
                [ruolo: ruoloSelezionato, lettura: lettura],
                { event ->
                    if (event.data) if (event.data.elaborato) {
                        caricaRuoli(true)
                        aggiornaIndiciTab()
                    }
                })
    }

    @Command
    def onEliminaRuolo() {

        String messaggio = "Confermi di voler eliminare il contribuente selezionato dal Ruolo?"
        Messagebox.show(messaggio, "Eliminazione Ruolo",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaRuolo()
                            caricaRuoli(true)
                            aggiornaIndiciTab()
                        }
                    }
                })
    }

    def eliminaRuolo() {

        try {
            listeDiCaricoRuoliService.eliminaContribuenteDaRuolo(ruoloSelezionato.ruolo, codFiscale)
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }
    }

    def modificaRuoloAbititato(String tipoTributo) {
        return (competenzeService.tipoAbilitazioneUtente(tipoTributo) == competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
    }

    @Command
    def onAggiornaDovutoDePag() {
        def message = integrazioneDePagService.aggiornaDovutoPagoPa(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo)

        if (message.empty) {
            message = integrazioneDePagService.aggiornaDovutoRuolo(soggetto.contribuente.codFiscale,
                    ruoloSelezionato.ruolo)
        }

        if (!message.empty) {
            Clients.showNotification(message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
        } else {
            Clients.showNotification("Aggiornamento dovuto PagoPa eseguito."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 5000, true)
        }

    }

    @Command
    def onAnnullaDovutoDePag() {

        def message = integrazioneDePagService.eliminaDovutoRuolo(soggetto.contribuente.codFiscale,
                ruoloSelezionato.ruolo)

        if (!message.empty) {
            Clients.showNotification(message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
        } else {
            Clients.showNotification("Aggiornamento dovuto PagoPa eseguito."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 5000, true)
        }

        onRefresh()

    }

    @Command
    def onAggiornaDovutoDePagCuni() {
        integrazioneDePagService.aggiornaDovutoImposta(codFiscale, anno, 'CUNI')
    }

    @Command
    def onClickOggettoImposta(@BindingParam("popup") Component popupSgravio) {
        popupSgravio.visible = true
    }

    @Command
    def onTooltipInfoOggettiImposta(@BindingParam("sorgente") String sorgente,
                                    @BindingParam("oggettoImposta") def oggettoImposta) {
        if (sorgente == 'aliquoteMultiple') {
            if (!oggettoImposta.hasAliquoteMultiple) {
                return
            }
            aliquoteMultipleTooltipText[oggettoImposta.oggetto] = contribuentiService.getElencoAliquote(oggettoImposta, [codFiscale : soggetto.contribuente.codFiscale,
                                                                                                                         anno       : impostaSelezionata.anno,
                                                                                                                         tipoTributo: impostaSelezionata.tipoTributo])
            BindUtils.postNotifyChange(null, null, this, 'aliquoteMultipleTooltipText')
        }
    }

    @Command
    def onSelezioneAnnoOggetti() {

        aggiornaParametri()
        onRefresh()

        aggiornaIndiceOggetti()
    }

    @Command
    def onSelezionaOggettoCatasto() {

        oggettoSelezionato = listaOggetti.findAll {
            cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
        }.find {
            it.idImmobile == immobileCatastoSelezionato.IDIMMOBILE && it.rigaCatastoSelezionata == immobileCatastoSelezionato.RIGA
        }

        if (!oggettoSelezionato) {
            oggettoSelezionato = listaOggetti.findAll {
                cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
            }.find {
                it.idImmobile == immobileCatastoSelezionato.IDIMMOBILE
            }
        }


        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    @Command
    def onSelezionaOggetto(@BindingParam("popup") Component popup) {

        // Se sono visualizzati i dati metrici
        if (scp.tipoVisualizzazioneOggetti == 'D') {

            if (scp.tipoVisualizzazioneDatiMetrici == 'DO') {
                caricaDatiMetrici()
                creaAssociazioneOggetti()
            }

            datiMetriciSelezionato = confrontoArchivioBancheDatiService.datiMetriciSelezionato(oggettoSelezionato, listaDatiMetrici)
            BindUtils.postNotifyChange(null, null, this, "datiMetriciSelezionato")
        } else if (scp.tipoVisualizzazioneOggetti == 'P') {

            listaPraticheOggetto = contribuentiService.praticheOggettoContribuente(oggettoSelezionato.oggetto
                    , soggetto.contribuente.codFiscale
                    , oggettoSelezionato.tipoTributo)

            BindUtils.postNotifyChange(null, null, this, "listaPraticheOggetto")

        } else if (scp.tipoVisualizzazioneOggetti == 'C') {

            immobileCatastoSelezionato = confrontoArchivioBancheDatiService.oggettoCatastoSelezionato(oggettoSelezionato, oggettiDaCatasto)
            BindUtils.postNotifyChange(null, null, this, "immobileCatastoSelezionato")
        }
    }

    @Command
    def onSelezionaDatoMetrico() {
        oggettoSelezionato = listaOggetti.findAll {
            cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
        }.find {
            it.idImmobile == datiMetriciSelezionato.immobile
        }
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    @Command
    def onCopiaIdImmobile(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        DropEvent event = (DropEvent) ctx.triggerEvent
        def oggSorgente = event.dragged.getAttribute("foo")
        def oggDestinazione = event.target.parent.getAttribute("foo")
        def idOggetto = oggDestinazione.oggetto

        // oggDestinazione può venire da catasto o da dati metrici
        oggDestinazione.idImmobile = oggSorgente.IDIMMOBILE ?: oggSorgente.immobile

        def oggDaAggiornare = Oggetto.get(oggDestinazione.oggetto)
        oggDaAggiornare.idImmobile = oggSorgente.IDIMMOBILE ?: oggSorgente.immobile
        oggDaAggiornare.save(flush: true, failOnError: true)

        listaOggetti.findAll { it.oggetto == idOggetto }.each {
            it.idImmobile = oggSorgente.IDIMMOBILE ?: oggSorgente.immobile
        }

        listaOggetti.findAll { it.oggetto == idOggetto }.each {
            BindUtils.postNotifyChange(null, null, it, "idImmobile")
            BindUtils.postNotifyChange(null, null, it, "righeCatasto")
            BindUtils.postNotifyChange(null, null, it, "rigaCatastoSelezionata")
        }

        creaAssociazioneOggetti()

        oggettoSelezionato = oggDestinazione
        oggettoSelezionato.key = "${oggDestinazione.oggetto}-${oggSorgente.IDIMMOBILE}-${oggDestinazione.tipoTributo}"

        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")

        (self.getFellow("includeOggetti").getFellow("gridSitContrOggetti") as Listbox).children[0].invalidate()
    }

    @Command
    def onCancellaIdImmobile(@BindingParam("arg") def ogg) {

        def oggDaAggiornare = Oggetto.get(ogg.oggetto)
        oggDaAggiornare.idImmobile = null
        oggDaAggiornare.save(flush: true, failOnError: true)

        listaOggetti.findAll { it.oggetto == oggDaAggiornare.id }.each {
            it.idImmobile = null
            it.righeCatasto = []
            it.rigaCatastoSelezionata = null
        }

        listaOggetti.findAll { it.oggetto == oggDaAggiornare.id }.each {
            BindUtils.postNotifyChange(null, null, it, "idImmobile")
            BindUtils.postNotifyChange(null, null, it, "righeCatasto")
            BindUtils.postNotifyChange(null, null, it, "rigaCatastoSelezionata")
        }

        creaAssociazioneOggetti()

        (self.getFellow("includeOggetti").getFellow("gridSitContrOggetti") as Listbox).children[0].invalidate()
    }

    @Command
    def onVisualizzaLocazioniOggetto() {

        def filtri = [sezione   : oggettoSelezionato.sezione,
                      foglio    : oggettoSelezionato.foglio,
                      numero    : oggettoSelezionato.numero,
                      subalterno: oggettoSelezionato.subalterno]

        // Ricarca locazioni sull'oggetto
        listaContrattiLocazioni = contribuentiService.caricaLocazioni(filtri, [offset: 999999, activePage: 0], locazioniOrderBy).record

        showLocazioniOggetto = true
        BindUtils.postNotifyChange(null, null, this, "showLocazioniOggetto")
        BindUtils.postNotifyChange(null, null, this, "listaContrattiLocazioni")

    }

    @Command
    def onVisualizzaDatiMetriciOggetto() {

        datiMetriciTipologia = 'TARES'
        datiMetriciUiuSelezionata = null
        datiMetriciTabSelezionata = 0

        datiMetriciTitolo = "Oggetto: $oggettoSelezionato.oggetto - Sez.: ${oggettoSelezionato.sezione ?: ''} - Fgl.: ${oggettoSelezionato.foglio ?: ''} - Num.: ${oggettoSelezionato.numero ?: ''} - Sub.: ${oggettoSelezionato.subalterno ?: ''}"

        def filtri = [sezione   : oggettoSelezionato.sezione,
                      foglio    : oggettoSelezionato.foglio,
                      numero    : oggettoSelezionato.numero,
                      subalterno: oggettoSelezionato.subalterno,
                      tipologia : datiMetriciTipologia]

        listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,
                [max: Integer.MAX_VALUE, activePage: 0],
                [[property: 'uiu.idUiu', direction: 'asc']]).record

        showDatiMetriciOggetto = true
        BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
        BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciTitolo")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciUiuSelezionata")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciTabSelezionata")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciTipologia")
    }

    @Command
    def caricaIntestatariUiu() {


        listaDatiMetriciIntestatari = datiMetriciUiuSelezionata.intestatari

        BindUtils.postNotifyChange(null, null, this, "listaDatiMetriciIntestatari")
    }

    @Command
    @NotifyChange("listaContrattiUtenze")
    def onCambiaOrdinamentoUtenze(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {

        def sortBy = [[property: valore, direction: event.ascending ? 'asc' : 'desc']]

        listaContrattiUtenze = contribuentiService.caricaUtenze([codFiscale: soggetto.contribuente.codFiscale,
                                                                 tipologia : tipoUtenza],
                utenzePaginazione,
                sortBy).record
    }

    @Command
    def onCambiaOrdinamentoDettaglioLocazioni(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event,
                                              @BindingParam("valore") String valore,
                                              @BindingParam("rowNum") def rowNum) {


        listaContrattiLocazioni.find { it.row == rowNum }.dettagli = listaContrattiLocazioni.find { it.row == rowNum }.dettagli
                .sort { a, b -> b.tipoSoggetto <=> a.tipoSoggetto ?: (event.ascending ? (a."$valore" <=> b."$valore") : (b."$valore" <=> a."$valore"))
                }

        BindUtils.postNotifyChange(null, null,
                listaContrattiLocazioni.find { it.row == rowNum }, "dettagli")

    }

    @Command
    def onCambiaOrdinamentoDatiMetrici(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
        def sortBy = [[property: valore, direction: event.ascending ? 'asc' : 'desc']]

        def filtri = [sezione   : oggettoSelezionato.sezione,
                      foglio    : oggettoSelezionato.foglio,
                      numero    : oggettoSelezionato.numero,
                      subalterno: oggettoSelezionato.subalterno,
                      tipologia : datiMetriciTipologia]

        listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,
                [max: Integer.MAX_VALUE, activePage: 0],
                sortBy).record

        BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
    }

    @Command
    def onSelezionaDatiMetriciTipologia() {
        datiMetriciUiuSelezionata = null
        datiMetriciTabSelezionata = 0

        datiMetriciTitolo = "Oggetto: $oggettoSelezionato.oggetto - Sez.: ${oggettoSelezionato.sezione ?: ''} - Fgl.: ${oggettoSelezionato.foglio ?: ''} Num.: ${oggettoSelezionato.numero ?: ''} Sub.: ${oggettoSelezionato.subalterno ?: ''}"

        def filtri = [sezione   : oggettoSelezionato.sezione,
                      foglio    : oggettoSelezionato.foglio,
                      numero    : oggettoSelezionato.numero,
                      subalterno: oggettoSelezionato.subalterno,
                      tipologia : datiMetriciTipologia]

        listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,
                [max: Integer.MAX_VALUE, activePage: 0],
                [[property: 'uiu.idUiu', direction: 'asc']]).record

        showDatiMetriciOggetto = true
        BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
        BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciTitolo")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciUiuSelezionata")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciTabSelezionata")
    }

    @Command
    def onCambiaOrdinamentoDatiMetriciIntestatari(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
        listaDatiMetriciIntestatari = listaDatiMetriciIntestatari.sort {
            it."$valore"
        }

        if (!event.ascending) {
            listaDatiMetriciIntestatari = listaDatiMetriciIntestatari.reverse()
        }

        BindUtils.postNotifyChange(null, null, this, "listaDatiMetriciIntestatari")

    }

    @Command
    def stampaLocazioni() {

        def datiLocazioni = []
        def locazioni = [:]
        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.CONTRATTI_LOCAZIONI,
                [codFiscale: soggetto.contribuente.codFiscale])

        locazioni.testata = ["contribuente": soggetto.cognomeNome,
                             "codFiscale"  : soggetto.contribuente.codFiscale,
                             "indirizzo"   : soggetto.indirizzo]

        def contratti = contribuentiService.caricaLocazioni([codFiscale: soggetto.contribuente.codFiscale],
                [max: 999999, offset: 0, activePage: 0], locazioniOrderBy).record
        contratti.each {
            it.codFiscale = soggetto.contribuente.codFiscale
            it.cognomeNome = soggetto.cognomeNome
            it.immAccatastamento = it.immAccatastamento ? 'S' : ''
        }

        locazioni.dati = contratti

        datiLocazioni << locazioni

        JasperReportDef reportDef = new JasperReportDef(name: 'contrattiLocazioni.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiLocazioni
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])

        def report = locazioni.dati == null ? null : jasperService.generateReport(reportDef)

        if (report == null) {
            Clients.showNotification("Errore nella generazione della stampa"
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
        Filedownload.save(amedia)

    }

    @Command
    def locazioniToXls() {

        def fields = ['codFiscale'        : 'Codice Fiscale',
                      'cognomeNome'       : 'Cognome Nome',
                      'ufficio'           : 'Ufficio',
                      'anno'              : 'Anno',
                      'numero'            : 'Num.Reg.',
                      'sottoNumero'       : 'Sotto Num.Reg.',
                      'progressivoNegozio': 'Prog.Negozio',
                      'dataRegistrazione' : 'Registrazione',
                      'dataStipula'       : 'Stipula',
                      'indirizzo'         : 'Indirizzo',
                      'sezUrbComCat'      : 'Sez.',
                      'foglio'            : 'Fgl.',
                      'particellaNum'     : 'Num.',
                      'subalterno'        : 'Sub.',
                      'dataInizio'        : 'Inizio',
                      'dataFine'          : 'Fine',
                      'tipoSoggetto'      : 'Tipo Soggetto',
                      'dataSubentro'      : 'Subentro',
                      'dataCessazione'    : 'Cessione',
                      'codiceOggetto'     : 'Cod. Oggetto',
                      'codiceNegozio'     : 'Cod. Negozio',
                      'importoCanone'     : 'Canone',
                      'tipoCanone'        : 'Tipo Canone',
                      'immAccatastamento' : 'In Accatastamento',
                      'tipoCatasto'       : 'Catasto',
                      'flagIp'            : 'Int./Porz.',
                      'documentoId'       : 'Doc.Id.',
                      'codFiscaleOrig'    : 'Codice Fiscale Origine',]

        def contratti = contribuentiService.caricaLocazioni([codFiscale: soggetto.contribuente.codFiscale],
                [max: 999999, offset: 0, activePage: 0], locazioniOrderBy).record

        contratti.each {
            it.codFiscaleOrig = it.codFiscale
            it.codFiscale = soggetto.contribuente.codFiscale
            it.cognomeNome = soggetto.cognomeNome
            it.immAccatastamento = it.immAccatastamento ? 'S' : 'N'
        }

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.LOCAZIONI,
                [codFiscale: soggetto.contribuente.codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, contratti as List, fields)
    }

    @Command
    def utenzeToXls() {

        def fields = ['anno'                   : 'Anno',
                      'fornitura'              : 'Fornitura',
                      'cfErogante'             : 'C.F. Erogante',
                      'titolare'               : 'Titolare',
                      'utenza.descrizioneBreve': 'Utenza',
                      'indirizzo'              : 'Indirizzo',
                      'fatturato'              : 'Fatturato',
                      'consumo'                : 'Consumo',
                      'mesiFatturazione'       : 'Mesi Fatt.',
                      'documentoId'            : 'Doc.Id',
                      'cfTitolare'             : 'Codice Fiscale',]

        def contratti = contribuentiService.caricaUtenze([codFiscale: soggetto.contribuente.codFiscale,
                                                          tipologia : tipoUtenza]
                , utenzePaginazione,
                utenzeOrderBy).record

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.UTENZE,
                [codFiscale: soggetto.contribuente.codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, contratti as List, fields)
    }

    // TODO: standardizzare con converters
    @Command
    def contattiToXls() {

        def listaC = []

        Map fields = ["codFiscale"     : "Codice Fiscale",
                      "cognomeNome"    : "Cognome Nome",
                      "data"           : "Data",
                      "numero"         : "Numero",
                      "anno"           : "Anno",
                      "tipoRichiedente": "Richiedente",
                      "tipoContatto"   : "Contatto",
                      "tipoTributo"    : "Tributo",
                      "testo"          : "Testo"]

        String nomeFile = "ElencoContatti_${soggetto.contribuente.codFiscale}"

        listaContatti.each { it ->
            def contatto = [:]
            contatto.cognomeNome = it.contribuente.soggetto.cognomeNome
            contatto.codFiscale = it.contribuente.codFiscale
            contatto.data = it.data
            contatto.numero = it.numero
            contatto.anno = it.anno

            contatto.tipoRichiedente = (it.tipoRichiedente) ? it.tipoRichiedente.tipoRichiedente + " - " + it.tipoRichiedente.descrizione : ""
            contatto.tipoContatto = (it.tipoContatto) ? it.tipoContatto.tipoContatto + " - " + it.tipoContatto.descrizione : ""

            contatto.tipoTributo = it.tipoTributo?.tipoTributo
            contatto.testo = it.testo

            listaC << contatto
        }

        XlsxExporter.exportAndDownload(nomeFile, listaC, fields)
    }

    @Command
    def onAggiungiContatto() {
        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteContattiDettaglio.zul", self,
                [tipoOperazione: ContattiDettaglioViewModel.TipoOperazione.INSERIMENTO,
                 contribuente  : soggetto.contribuente.toDomain()], { e -> onRefresh()
        })
    }

    @Command
    def onModificaContatto() {
        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteContattiDettaglio.zul", self,
                [tipoOperazione     : ContattiDettaglioViewModel.TipoOperazione.MODIFICA,
                 contribuente       : soggetto.contribuente.toDomain(),
                 contattoSelezionato: contattoSelezionato.toDomain()], { e -> onRefresh()
        })
    }

    @Command
    def onDuplicaContatto() {

        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteContattiDettaglio.zul", self,
                [tipoOperazione     : ContattiDettaglioViewModel.TipoOperazione.CLONAZIONE,
                 contribuente       : soggetto.contribuente.toDomain(),
                 contattoSelezionato: contattoSelezionato.toDomain()], { e -> onRefresh()
        })
    }

    @Command
    def onEliminaContatto() {

        Messagebox.show("Si è scelto di eliminare il contatto\nVuoi procedere con l'eliminazione?", "Elimina Contatto", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {

                    contribuentiService.eliminaContatto(contattoSelezionato.toDomain())
                    Clients.showNotification("Eliminazione avvenuta con successo", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

                    if (Soggetto.get(soggetto.id).contribuente == null) {
                        Messagebox.show("Il contribuente è stato eliminato.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION, new EventListener() {
                            void onEvent(Event evnt) throws Exception {
                                closeCurrentAndRefreshListaContribuente()
                            }
                        })
                    } else {
                        onRefresh()
                    }


                }
            }
        })

    }


    @Command
    def ruoliToXls() throws Exception {

        def formatters = [:]

        Map fields = ["codFiscale"          : "Codice Fiscale",
                      "cognomeNome"         : "Cognome Nome",
                      "descrizioneTributo"  : "Tipo Tributo",
                      "tipoRuoloStr"        : "Tipo Ruolo",
                      "anno"                : "Anno Ruolo",
                      "annoEmissione"       : "Anno Emissione",
                      "progrEmissione"      : "Progr. Emissione",
                      "dataEmissione"       : "Data emissione",
                      "invioConsorzio"      : "Invio Consorzio",
                      "codiceTributo.id"    : "Codice Tributo",
                      "importo"             : "Importo",
                      "importoLordoStr"     : "Importo Lordo",
                      "sgravio"             : "Sgravio",
                      "specie"              : "Specie Ruolo",
                      "descrizioneCalcolo"  : "Tipo Calcolo",
                      "descrizioneEmissione": "Tipo Emissione",
                      "compensazione"       : "Compensazione",
                      "ruolo"               : "Ruolo",
                      "imposta"             : "Imposta",
                      "addMaggEca"          : "ECA",
                      "addProv"             : "Prov.",
                      "iva"                 : "IVA",
                      "maggiorazioneTares"  : "Componenti Perequative"]

        String nomeFile = "ElencoRuoli_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaRuoli, fields, formatters)

    }

    @Command
    def imposteToXls() {

        Map fields = ["codFiscale"          : "Codice Fiscale",
                      "cognomeNome"         : "Cognome Nome",
                      "descrTipoTributo"    : "Tipo Tributo",
                      "anno"                : "Anno",
                      "imposta"             : "Imposta",
                      "impostaLorda"        : "Imposta Lorda",
                      "dovuto"              : "Dovuto",
                      "versato"             : "Versato",
                      "residuo"             : "Residuo",
                      "aRuolo"              : "A Ruolo",
                      "impostaAcconto"      : "Imposta Acconto",
                      "impostaErariale"     : "Imposta Erariale",
                      "impostaMini"         : "Imposta Mini IMU",
                      "addMaggEca"          : "Addizionale e Maggiorazione ECA",
                      "addPro"              : "Addizionale Provinciale",
                      "iva"                 : "IVA",
                      "maggiorazioneTares"  : "Componenti Perequative",
                      "accertamentoPresente": "Acc.",
                      "liquidazionePresente": "Liq.",
                      "versamentoPresente"  : "Vers.",
                      "dataVariazione"      : "Data Ultima Variazione",]

        def converters = [impostaLorda        : { v ->
            def impostaLorda = (v.maggiorazioneTares ?: 0) + (v.addMaggEca ?: 0) + (v.addPro ?: 0) + (v.iva ?: 0)

            return impostaLorda == 0 ? null : v.imposta + impostaLorda

        },
                          dovuto              : { v ->
                              if (v.tipoTributo != 'TARSU') {
                                  return v.imposte ?: 0
                              } else {
                                  return v.imposta + (v.maggiorazioneTares ?: 0) + (v.addMaggEca ?: 0) + (v.addPro ?: 0) + (v.iva ?: 0) - (v.csgravio ?: 0)
                              }
                          },
                          accertamentoPresente: Converters.flagBooleanToString,
                          liquidazionePresente: Converters.flagBooleanToString,
                          versamentoPresente  : Converters.flagBooleanToString,
                          residuo             : { v -> v as BigDecimal }

        ]

        String nomeFile = "ElencoImposte_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaImposte.findAll {
            cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
        }, fields, converters)
    }

    @Command
    def versamentiToPdf() throws Exception {
        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.VERSAMENTI,
                [:])
        List<ContribuenteDTO> versamenti = new ArrayList<ContribuenteDTO>()

        ContribuenteDTO contribuenteDTO = contribuentiService.getDatiContribuente(soggetto.contribuente.codFiscale,
                getTipiTributoSelezionati(), cbTipiPratica.findAll { k, v -> v }.collect { it.key })
        contribuenteDTO.versamenti = new TreeSet<VersamentoDTO>(listaVersamenti ?: contribuentiService.versamentiContribuente(soggetto.contribuente.codFiscale,
                'list',
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key }))

        versamenti.add(contribuenteDTO)

        JasperReportDef reportDef = new JasperReportDef(name: 'versamentiContribuente.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: versamenti
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ENTE         : ad4EnteService.getEnte()])

        def scheda = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, scheda.toByteArray())
        Filedownload.save(amedia)
    }


    @Command
    def versamentiToXls() {

        Map fields = ["contribuente.codFiscale"          : "Codice Fiscale",
                      "contribuente.soggetto.cognomeNome": "Cognome Nome",
                      "tipoTributo"                      : "Tipo Tributo",
                      "anno"                             : "Anno",
                      "pratica.tipoPratica"              : "Tipo Pratica",
                      "tipoVersamento"                   : "Tipo Versamento",
                      "rata"                             : "Rata",
                      "importoVersato"                   : "Importo Versato",
                      "dataPagamento"                    : "Data Pagamento",
                      "ruolo.id"                         : "Ruolo",
                      "fabbricati"                       : "Fabbricati",
                      "terreniAgricoli"                  : "Terreni Agricoli",
                      "areeFabbricabili"                 : "Aree Fabbricabili",
                      "abPrincipale"                     : "Abitazione Principale",
                      "altriFabbricati"                  : "Altri Fabbricati",
                      "detrazione"                       : "Detrazione",
                      "rurali"                           : "Fabbricati Rurali",
                      "fabbricatiD"                      : "Fabbricati Uso Produttivo",
                      "fabbricatiMerce"                  : "Fabbricati Merce",
                      "addizionalePro"                   : "Addizionale TEFA",
                      "maggiorazioneTares"               : "Componenti Perequative",
                      "fonte.fonte"                      : "Fonte",
                      "idCompensazione"                  : "Compensazione"]

        String nomeFile = "ElencoVersamenti_${soggetto.contribuente.codFiscale}"

        def converters = ["tipoTributo": { v -> v?.getTipoTributoAttuale() }]

        XlsxExporter.exportAndDownload(nomeFile, listaVersamenti, fields, converters)

    }

    @Command
    def praticheToXls() {

        def converters = [:]

        Map fields

        if (cbTributi.ICP || cbTributi.TOSAP || cbTributi.CUNI) {
            fields = ["codFiscale"                 : "Codice Fiscale",
                      "cognomeNome"                : "Cognome Nome",
                      "indirizzoRes"               : "Indirizzo",
                      "comuneRes"                  : "Comune",
                      "provinciaRes"               : "Provincia",
                      "flagDePag"                  : "DePag",
                      "descrizioneTributo"         : "Tipo Tributo",
                      "anno"                       : "Anno",
                      "tipoPratica"                : "Tipo Pratica",
                      "tipoEventoViolazione"       : "Tipo Evento",
                      "data"                       : "Data",
                      "numero"                     : "Numero",
                      "stato"                      : "Stato",
                      "dataRiferimentoRavvedimento": "Data Rif.Ravv.",
                      "dataNotifica"               : "Data Notifica",
                      "tipoNotifica"               : "Tipo Notifica",
                      "tipoRapporto"               : "Tipo Rapporto",
                      "id"                         : "Pratica",
                      "praticaSuccessiva"          : "Pratica Successiva",
                      "utenteModifica"             : "Utente Modifica",
                      "motivo"                     : "Motivo",
                      "note"                       : "Note",
                      "denunciante"                : "Denunciante",
                      "codFiscaleDen"              : "Cod. Fis. Den.",
                      "caricaDen"                  : "Carica Den.",
                      "indirizzoDen"               : "Indirizzo Den.",
                      "comuneDen"                  : "Comune Den.",
                      "provinciaDen"               : "Prov. Den.",]
        } else {
            fields = ["codFiscale"                 : "Codice Fiscale",
                      "cognomeNome"                : "Cognome Nome",
                      "flagDePag"                  : "DePag",
                      "descrizioneTributo"         : "Tipo Tributo",
                      "anno"                       : "Anno",
                      "tipoPratica"                : "Tipo Pratica",
                      "tipoEventoViolazione"       : "Tipo Evento",
                      "data"                       : "Data",
                      "numero"                     : "Numero",
                      "stato"                      : "Stato",
                      "dataRiferimentoRavvedimento": "Data Rif.Ravv.",
                      "dataNotifica"               : "Data Notifica",
                      "tipoNotifica"               : "Tipo Notifica",
                      "tipoRapporto"               : "Tipo Rapporto",
                      "id"                         : "Pratica",
                      "praticaSuccessiva"          : "Pratica Successiva",
                      "utenteModifica"             : "Utente Modifica"]
        }

        String nomeFile = "ElencoPratiche_${soggetto.contribuente.codFiscale}"

        converters << ["tipoNotifica": { tn -> tn ? "${tn.tipoNotifica} - ${tn.descrizione}" : null }]
        converters << ["tipoEventoViolazione": { tev -> tev ? tev.toString() : "" }]

        def listToExport = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                "exportxls",
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key },
                campiOrdinamentoPratiche)

        XlsxExporter.exportAndDownload(nomeFile, listToExport, fields, converters)
    }

    @Command
    def praticheOggettoToXls() {

        def oggetto = oggettoSelezionato.oggetto
        def converters = [:]

        Map fields = ["descrizioneTributo"  : "Tributo",
                      "anno"                : "Anno",
                      "tipoPratica"         : "Tipo Pratica",
                      "tipoEventoViolazione": "Tipo Evento",
                      "data"                : "Data",
                      "numero"              : "Numero",
                      "stato"               : "Stato",
                      "dataNotifica"        : "Data Notifica",
                      "tipoNotifica"        : "Tipo Notifica",
                      "tipoRapporto"        : "Tipo Rapporto",
                      "id"                  : "Pratica",
                      "praticaSuccessiva"   : "Pratica Successiva"]

        String nomeFile = "ElencoPratiche_${oggetto}_${soggetto.contribuente.codFiscale}"

        converters.tipoNotifica = { tn -> tn ? "${tn.tipoNotifica} - ${tn.descrizione}" : null }
        converters << ["tipoEventoViolazione": { tev -> tev ? tev.toString() : "" }]

        XlsxExporter.exportAndDownload(nomeFile, listaPraticheOggetto, fields, converters)
    }

    @Command
    def datiMetriciOggettoToXls() {

        Map fields = ["immobile"               : "Immobile",
                      "indirizzo"              : "Indirizzo",
                      "sezioneCat"             : "Sezione",
                      "foglioCat"              : "Foglio",
                      "numeroCat"              : "Numero",
                      "subalternoCat"          : "Subalterno",
                      "categoriaCat"           : "Categoria Catasto",
                      "superficie"             : "Superficie",
                      "esitoSuperficie"        : "Esito Superficie",
                      "superficieTotale"       : "Superficie Totale",
                      "superficieConvenzionale": "Superficie Convenzionale",
                      "data"                   : "Data",
                      "numero"                 : "Numero",
                      "raccolta"               : "Raccolta",
                      "beneComune"             : "Bene Comune",
                      "inizioValidita"         : "Inizio Validita",
                      "fineValidita"           : "Fine Validita",
                      "dataCertificazione"     : "Data Certificazione",
                      "dataProvvedimento"      : "Data Provvedimento",
                      "protocolloProvvedimento": "Protocollo Provvedimento",
                      "documentoId"            : "Documemento Id"]

        String nomeFile = "ElencoDatiMetrici_${soggetto.contribuente.codFiscale}"

        def formatters = ["beneComune": Converters.flagBooleanToString]

        XlsxExporter.exportAndDownload(nomeFile, listaDatiMetrici, fields, formatters)
    }

    @Command
    def catastoOggettoToXls() {

        Map fields = ["IDFABBRICATO"       : "Immobile",
                      "TIPOOGGETTO"        : "T",
                      "INDIRIZZOCOMPLETO"  : "Indirizzo",
                      "SEZIONE"            : "Sezione",
                      "FOGLIO"             : "Foglio",
                      "NUMERO"             : "Numero",
                      "SUBALTERNO"         : "Subalterno",
                      "ZONA"               : "Zona",
                      "CATEGORIACATASTO"   : "Categoria Catasto",
                      "CLASSECATASTO"      : "Classe Catasto",
                      "CONSISTENZA"        : "Consistenza",
                      "SUPERFICIE"         : "Superfice",
                      "RENDITA"            : "Rendita",
                      "REDDITODOMINICALE"  : "Reddito Domenicale",
                      "REDDITOAGRARIO"     : "Reddito Agrario",
                      "PARTITA"            : "Partita",
                      "POSSESSO"           : "Possesso",
                      "DATAEFFICACIAINIZIO": "Inizio Efficace",
                      "DATAEFFICACIAFINE"  : "Fine Efficace",
                      "DATAINIZIOVALIDITA" : "Inizio Validita",
                      "DATAFINEVALIDITA"   : "Fine Validita",
                      "DIRITTO"            : "Diritto",
                      "ANNOTAZIONE"        : "Note",
                      "COD_FISCALE"        : "Codice Fiscale"]

        String nomeFile = "ElencoCatasto_${soggetto.contribuente.codFiscale}"

        def formatters = ["IDFABBRICATO": Converters.decimalToInteger]

        XlsxExporter.exportAndDownload(nomeFile, oggettiDaCatasto, fields, formatters)
    }

    @Command
    def oggettiToXls() {

        Map fields = ["idImmobile"      : "Immobile",
                      "oggetto"         : "Oggetto",
                      "tipoOggetto"     : "Tipo Oggetto",
                      "indirizzo"       : "Indirizzo",
                      "sezione"         : "Sezione",
                      "foglio"          : "Foglio",
                      "numero"          : "Numero",
                      "subalterno"      : "Subalterno",
                      "categoriaCatasto": "Categoria Catasto",
                      "classeCatasto"   : "Classe Catasto",
                      "rendita"         : "Rendita",
                      "valore"          : "Valore",
                      "percPossesso"    : "Percentuale Possesso",
                      "mesiPossesso"    : "Mesi Possesso",
                      "mesiEsclusione"  : "Mesi Esclusione",
                      "mesiRiduzione"   : "Mesi Riduzione",
                      "flagPossesso"    : "Flag Possesso",
                      "flagEsclusione"  : "Flag Exclusione",
                      "flagRiduzione"   : "Flag Riduzione",]
        if (cbTributi.TARSU) {
            fields += ["flagPuntoRaccolta": "Punto di raccolta",
                       "flagRfid"         : "Svuotamenti"]

        }
        fields += ["flagAbPrincipale"     : "Flag AbPrincipale",
                   "flagPertinenzaDi"     : "Flag PertinenzaDi",
                   "immStorico"           : "Imm.Storico",
                   "flagAliquoteOgco"     : "Flag AliquotaOgco",
                   "flagUtilizziOggetto"  : "Flag UtilizzaOgg",
                   "tributo"              : "Codice Tributo",
                   "categoria"            : "Categoria",
                   "tipoTariffa"          : "Tipo Tariffa",
                   "consistenza"          : "Consistenza",
                   "numeroFamiliari"      : "NumeroFamiliari",
                   "dataDecorrenza"       : "Decorrenza",
                   "dataCessazione"       : "Cessazione",
                   "flagContenzioso"      : "Flag Contenzioso",
                   "flagAltriContribuenti": "Flag AltriContr.",
                   "tributoDescrizione"   : "Tipo Tributo",
                   "anno"                 : "Anno",
                   "tipoPratica"          : "Tipo Pratica",
                   "tipoEventoViolazione" : "Tipo Evento",
                   "tipoRapporto"         : "Tipo Rapporto"]

        def formatters = ["idImmobile"    : Converters.decimalToInteger,
                          "oggetto"       : Converters.decimalToInteger,
                          "anno"          : Converters.decimalToInteger,
                          "consistenza"   : Converters.decimalToInteger,
                          "categoria"     : Converters.decimalToInteger,
                          "tipoTariffa"   : Converters.decimalToInteger,
                          "mesiPossesso"  : Converters.decimalToInteger,
                          "mesiEsclusione": Converters.decimalToInteger,
                          "mesiRiduzione" : Converters.decimalToInteger,
                          "tipoOggetto"   : Converters.decimalToInteger,
                          "tributo"       : Converters.decimalToInteger]
        if (cbTributi.TARSU) {
            formatters += ["flagPuntoRaccolta": Converters.flagString,
                           "flagRfid"         : Converters.flagString]
        }

        String nomeFile = "ElencoOggetti_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaOggetti, fields, formatters)
    }

    @Command
    def oggettiPraticaToXls() {

        String tipoTributo = praticaSelezionata.tipoTributo.tipoTributo

        Map fields = ["id"         : "Oggetto",
                      "tipoOggetto": "Tipo Oggetto",
                      "indirizzo"  : "Indirizzo",
                      "sezione"    : "Sezione",
                      "foglio"     : "Foglio",
                      "numero"     : "Numero",
                      "subalterno" : "Subalterno"]

        Map tariFields = ["categoriaCatasto"  : "Categoria Catasto",
                          "consistenza"       : "Consistenza",
                          "dataDecorrenza"    : "Decorrenza",
                          "dataCessazione"    : "Cessazione",
                          "inizioOccupazione" : "Inizio Occupazione",
                          "fineOccupazione"   : "Fine Occupazione",
                          "codiceTributo"     : "Codice Tributo",
                          "categoria"         : "Categoria",
                          "tipoTariffa"       : "Tipo Tariffa",
                          "descrizioneTariffa": "Descrizione Tariffa",
                          "flagAbPrincipale"  : "Flag AbPrincipale"]

        Map cuniFields = ["categoriaCatasto"    : "Categoria Catasto",
                          "dataDecorrenza"      : "Decorrenza",
                          "dataCessazione"      : "Cessazione",
                          "inizioOccupazione"   : "Inizio Occupazione",
                          "fineOccupazione"     : "Fine Occupazione",
                          "flagAbPrincipale"    : "Flag AbPrincipale",
                          "esenzione"           : "Esenzione",
                          "tipoOccupazione"     : "Tipo Occ.",
                          "codiceTributo"       : "Codice Tributo",
                          "desCodiceTributo"    : "Descr. Tributo",
                          "categoria"           : "Categoria",
                          "descrizioneCategoria": "Descr. Categoria",
                          "tipoTariffa"         : "Tipo Tariffa",
                          "descrizioneTariffa"  : "Descr. Tariffa",
                          "tariffa"             : "Val. Tariffa",
                          "inizioConcessione"   : "Inizio Conc.",
                          "fineConcessione"     : "Fine Conc.",
                          "numConcessione"      : "Num. Conc.",
                          "dataConcessione"     : "Data Conc.",
                          "larghezza"           : "Larghezza",
                          "profondita"          : "Profondita",
                          "quantita"            : "Quantita\"",
                          "consistenzaReale"    : "Superficie",
                          "consistenza"         : "Sup. Tassabile",
                          "percPossesso"        : "% Possesso",
                          "noteOgPr"            : "Note Ogg.",]

        Map iciFields = ["zona"             : "Zona",
                         "protocolloCatasto": "Prot.Catasto",
                         "annoCatasto"      : "Anno Catasto",
                         "partita"          : "Partita",
                         "categoriaCatasto" : "Cat. Catasto",
                         "classeCatasto"    : "Classe Catasto",
                         "percPossesso"     : "Perc Possesso",
                         "mesiPossesso"     : "Mesi Possesso",
                         "tipoTariffa"      : "Tipo Tariffa",
                         "mesiEsclusione"   : "Mesi Esclusione",
                         "mesiRiduzione"    : "Mesi Riduzione",
                         "flagPossesso"     : "Flag Possesso",
                         "flagEsclusione"   : "Flag Esclusione",
                         "flagRiduzione"    : "Flag Riduzione",
                         "rendita"          : "Rendita",
                         "valore"           : "Valore",
                         "flagProvvisorio"  : "Flag Provvisorio",
                         "detrazione"       : "Detrazione"]

        Map denuncianteFields = ["codFiscale"  : "Codice Fiscale",
                                 "cognomeNome" : "Cognome Nome",
                                 "indirizzoRes": "Indirizzo",
                                 "comuneRes"   : "Comune",
                                 "provinciaRes": "Provincia",]

        Map praticaFields = ["flagDePag"           : "DePag",
                             "desTipoTributo"      : "Tipo Tributo",
                             "anno"                : "Anno",
                             "tipoPratica"         : "Tipo Pratica",
                             "tipoEventoViolazione": "Tipo Evento",
                             "data"                : "Data",
                             "numero"              : "Numero",
                             "stato"               : "Stato",
                             "dataNotifica"        : "Data Notifica",
                             "tipoNotifica"        : "Tipo Notifica",
                             "tipoRapporto"        : "Tipo Rapporto",
                             "praticaId"           : "Pratica",
                             "praticaSuccessiva"   : "Pratica Successiva",
                             "motivoPrat"          : "Motivo",
                             "notePrat"            : "Note",]

        Map defaultFields = ["categoriaCatasto": "Cat. Catasto"]

        def formatters = [:]

        switch (tipoTributo) {
            case ["ICI", "TASI"]:
                fields += iciFields
                formatters = ["percPossesso"   : Converters.decimalToInteger,
                              "flagPossesso"   : Converters.flagBooleanToString,
                              "flagEsclusione" : Converters.flagBooleanToString,
                              "flagRiduzione"  : Converters.flagBooleanToString,
                              "flagProvvisorio": Converters.flagBooleanToString]
                break
            case 'TARSU':
                fields += tariFields
                formatters = ["consistenza"     : Converters.decimalToInteger,
                              "flagAbPrincipale": Converters.flagBooleanToString]
                break
            case ['ICP', 'TOSAP', 'CUNI']:
                fields = denuncianteFields + fields
                fields += praticaFields
                fields += cuniFields
                formatters = ["quantita"            : Converters.decimalToInteger,
                              "flagAbPrincipale"    : Converters.flagBooleanToString,
                              "esenzione"           : Converters.flagBooleanToString,
                              "tipoNotifica"        : { tn -> tn ? "${tn.tipoNotifica} - ${tn.descrizione}" : null },
                              "tipoEventoViolazione": { tev -> tev ? tev.toString() : "" }]
                break
            default:
                fields += defaultFields
                formatters = [:]
        }

        String nomeFile = "ElencoOggettiPratica_${tipoTributo}_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaOggettiPratica, fields, formatters)
    }

    @Command
    def oggettiRuoloToXls() {

        String ruolo = ruoloSelezionato.ruolo

        Map fields = ["id"              : "Oggetto",
                      "tipoOggetto"     : "Tipo Oggetto",
                      "indirizzo"       : "Indirizzo",
                      "sezione"         : "Sezione",
                      "foglio"          : "Foglio",
                      "numero"          : "Numero",
                      "subalterno"      : "Subalterno",
                      "zona"            : "Zona",
                      "categoriaCatasto": "Categoria Catasto",
                      "codiceTributo"   : "Codice Tributo",
                      "categoria"       : "Categoria",
                      "tipoTariffa"     : "Tipo Tariffa",
                      "consistenza"     : "Consistenza",
                      "importo"         : "Importo",
                      "sgravio"         : "Sgravio",
                      "mesiRuolo"       : "Mesi Ruolo",
                      "giorniRuolo"     : "Giorni Ruolo"]


        String nomeFile = "ElencoOggettiRuolo_${ruolo}_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaOggettiRuolo, fields)
    }

    @Command
    def praticheRuoloToXls() {
        def fields = ["descrizioneTributo"  : "Tributo",
                      "anno"                : "Anno",
                      "tipoPratica"         : "Tipo Pratica",
                      "tipoEventoViolazione": "Tipo Evento",
                      "data"                : "Data",
                      "numero"              : "Numero",
                      "stato"               : "Stato",
                      "dataNotifica"        : "Data Notifica",
                      "tipoNotifica"        : "Tipo Notifica",
                      "tipoRapporto"        : "Tipo Rapporto",
                      "importoSgravio"      : "Sgravio",
                      "id"                  : "Pratica",
                      "praticaSuccessiva"   : "Pratica Successiva"]

        def converters = ["tipoNotifica"        : { tn -> tn ? "${tn.tipoNotifica} - ${tn.descrizione}" : null },
                          "tipoEventoViolazione": { tev -> tev ? tev.toString() : "" }]

        String nomeFile = "ElencoPraticheRuolo_${ruoloSelezionato.ruolo}_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaPraticheRuolo, fields, converters)
    }


    @Command
    def oggettiImpostaToXls() {

        def annoImposta = impostaSelezionata.anno
        def tipoTributo = impostaSelezionata.tipoTributo

        def commonFields = ["annoImposta"     : "Anno",
                            "oggetto"         : "Oggetto",
                            "tipoOggetto"     : "TipoOggetto",
                            "indirizzoOggetto": "Indirizzo",
                            "sezione"         : "Sezione",
                            "foglio"          : "Foglio",
                            "numero"          : "Numero",
                            "subalterno"      : "Subalterno",
                            "zona"            : "Zona"]

        // Table ICI
        def iciFields = ["protocollo"       : "Protocollo",
                         "anno"             : "Anno",
                         "partita"          : "Partita",
                         "categoriaCatasto" : "Categoria Catasto",
                         "classe"           : "Classse",
                         "tipoPratica"      : "Tipo Pratica",
                         "imposta"          : "Imposta",
                         "tipoRapporto"     : "Tipo Rapporto",
                         "tipoAliquotaDescr": "Tipo Aliquota",
                         "aliquota"         : "Aliquota",
                         "impostaAcconto"   : "Imposta Acconto"]

        // CUNI
        def cuniFields = ["categoriaCatasto": "Categoria Catasto",
                          "tipoPratica"     : "Tipo Pratica",
                          "codiceTributo"   : "Codice Tributo",
                          "categoria"       : "Categoria",
                          "tipoTariffa"     : "Tipo Tariffa",
                          "consistenza"     : "Consistenza",
                          "imposta"         : "Imposta"]

        // TARSU
        def tarsuFields = ["categoriaCatasto"  : "Categoria Catasto",
                           "tipoPratica"       : "Tipo Pratica",
                           "codiceTributo"     : "Codice Tributo",
                           "categoria"         : "Categoria",
                           "tipoTariffa"       : "Tipo Tariffa",
                           "consistenza"       : "Consistenza",
                           "impostaLorda"      : "Imposta Lorda",
                           "aRuolo"            : "A Ruolo",
                           "maggiorazioneTares": "Componenti Perequative"]


        // DEFAULT ( codiciTributo : ICI, TARSU, ICP )
        def defaultFields = ["categoriaCatasto": "Categoria Catasto",
                             "tipoPratica"     : "Tipo Pratica",
                             "imposta"         : "Imposta"]

        def fields = commonFields
        def converters = [annoImposta: { annoImposta }]

        switch (tipoTributo) {

            case ["ICI", "TASI"]:
                fields += iciFields
                converters << ["tipoAliquotaDescr": { record -> record.tipoAliquota == null ? "" : "${record.tipoAliquota} - ${record.descrizioneALiquota}"
                }]
                break
            case ['TARSU', 'ICP', "TOSAP"]:
                converters << ["impostaLorda": { record ->
                    def impostaLorda = (record.imposta ?: 0) + (record.maggiorazioneTares ?: 0) + (record.addMaggEca ?: 0) + (record.addPro ?: 0) + (record.iva ?: 0)
                    return impostaLorda == 0 ? null : impostaLorda
                }]
                converters << ["aRuolo": Converters.flagEmptyToString]
                fields += tarsuFields
                break
            case "CUNI":
                fields += cuniFields
                break
            default:
                fields += defaultFields
        }

        String nomeFile = "oggetti_imposta_${soggetto.contribuente.codFiscale}_${impostaSelezionata.descrTipoTributo}_${annoImposta}"

        XlsxExporter.exportAndDownload(nomeFile, listaOggettiImposta, fields, converters)

    }

    @Command
    def familiariToXls() throws Exception {

        Map fields = ["soggetto.codFiscale" : "Codice Fiscale",
                      "soggetto.cognomeNome": "Cognome Nome",
                      "anno"                : "Anno",
                      "dal"                 : "Dal",
                      "al"                  : "Al",
                      "numeroFamiliari"     : "Numero Familiari",
                      "note"                : "Note",
                      "lastUpdated"         : "Data Variazione"]

        String nomeFile = "ElencoFamiliari_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaFamiliari, fields)

    }

    @Command
    def documentiToXls() throws Exception {

        Map fields = ["sequenza"         : "Sequenza"
                      , "titolo"         : "Titolo"
                      , "nomeFile"       : "Nome File"
                      , "dataInserimento": "Data Inserimento"
                      , "validitaDal"    : "Inizio Validità"
                      , "validitaAl"     : "Fine Validità"]

        if (smartPndAbilitato) {

            fields += ["idComunicazionePnd"        : "Num.S.PND",
                       "tipoCanaleDescr"           : "Tipo Canale",
                       'smartPndComunicazioneStato': 'Stato S.PND',
                       'tipoComunicazioneDescr'    : 'Tipo Com.S.PND']
        }

        fields += ["informazioni": "Informazioni"
                   , "note"      : "Note"]

        String nomeFile = "ElencoDocumenti_${soggetto.contribuente.codFiscale}"

        def lista = listaDocumenti.collect {
            [sequenza          : it.sequenza,
             titolo            : it.titolo,
             nomeFile          : it.nomeFile,
             dataInserimento   : it.dataInserimento,
             validitaDal       : it.validitaDal,
             validitaAl        : it.validitaAl,
             informazioni      : it.informazioni,
             note              : it.note,
             idComunicazionePnd: it.idComunicazionePnd]
        }

        def converters = [:]

        if (smartPndAbilitato) {
            converters << ['tipoCanaleDescr'           : { doc -> listaComunicazioniPND[doc.idComunicazionePnd]?.tipoCanaleDescr ?: '' },
                           'smartPndComunicazioneStato': { doc ->
                               /// println doc
                               return listaComunicazioniPND[doc.idComunicazionePnd]?.smartPndComunicazione?.stato ?: ''
                           },
                           'tipoComunicazioneDescr'    : { doc -> listaComunicazioniPND[doc.idComunicazionePnd]?.smartPndComunicazione?.tipoComunicazioneDescr ?: '' }]
        }

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, converters)

    }

    @Command
    def allegatiToXls() throws Exception {
        Map fields = ["sequenza"         : "Sequenza"
                      , "titolo"         : "Titolo"
                      , "nomeFile"       : "Nome File"
                      , "dataInserimento": "Data Inserimento"
                      , "validitaDal"    : "Inizio Validità"
                      , "validitaAl"     : "Fine Validità"
                      , "informazioni"   : "Informazioni"
                      , "note"           : "Note"]
        String nomeFile = "ElencoAllegati_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaAllegati, fields)
    }

    @Command
    def onRefresh() {

        if (!isContribuente) {
            return
        }

        aggiornaParametri()
        aggiornaAnni()

        switch (tabSelezionata) {
            case "oggetti":
                caricaListaContribuentiSotria()
                calcolaVisualizzaDovuto()
                aggiornaIndiciTab()
                listaPraticheOggetto = []
                oggettoSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                BindUtils.postNotifyChange(null, null, this, "listaPraticheOggetto")
                def filtriCatasto = [codFis: soggetto.contribuente.codFiscale, anno: anno]

                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    if (scp.tipoVisualizzazioneTipoOggetto == 'CF') {
                        filtriCatasto << [tipoOggetto: "CF"]
                    } else if (scp.tipoVisualizzazioneTipoOggetto == 'CT') {
                        filtriCatasto << [tipoOggetto: "CT"]
                    }
                }

                def soggettiCollegati = []

                catastoCensuarioService.getIDProprietariDaCFContribuente(codFiscale).data.each() { sogg -> soggettiCollegati << sogg.IDSOGGETTO
                }

                filtriCatasto.soggettiCatastoCollegati = soggettiCollegati
                oggettiDaCatasto = catastoCensuarioService.getOggettiCatastoUrbano(filtriCatasto)

                differenzeOggetti = confrontoArchivioBancheDatiService.aggiornaDifferenzeOggettiCatasto(listaOggetti, oggettiDaCatasto, immobiliNonAssociatiCatasto, cbTributi, anno)
                creaAssociazioneOggetti()
                BindUtils.postNotifyChange(null, null, this, "oggettiDaCatasto")

                if (scp.tipoVisualizzazioneOggetti == 'D') {
                    caricaDatiMetrici()
                }

                if (!confrontoArchivioBancheDatiService.abilitaConfronti(listaOggetti.size)) {
                    Clients.showNotification("Controlli disabilitati per il superamento della soglia definita nel parametro [SC_OGG_VER].", Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
                }
                break
            case "imposte":
                caricaImposte(true)
                break
            case "versamenti":
                caricaVersamenti(true)
                caricaVersamentiBonifiche()
                break
            case "ruoli":
                caricaRuoli(true)
                aggiornaIndiciTab()
                break
            case "pratiche":
                caricaPratiche(true)
                break
            case "contatti":
                caricaContatti(true)
                aggiornaIndiciTab()
                break
            case "familiari":
                caricaFamiliari(true)
                if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
                    Clients.showNotification("Attenzione. Sono presenti più periodi aperti.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
                }
                break
            case "documenti":
                documentoSelezionato = null
                listaDocumenti = documentiContribuenteSmartPND(soggetto.contribuente.codFiscale)
                documentoSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
                BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
                BindUtils.postNotifyChange(null, null, this, "documentoSelezionato")
                fetchListaAllegati()
                break
            case "contratti":
                listaContrattiUtenze = contribuentiService.caricaUtenze([codFiscale: soggetto.contribuente.codFiscale,
                                                                         tipologia : tipoUtenza]
                        , utenzePaginazione,
                        utenzeOrderBy).record
                listaContrattiLocazioni = contribuentiService.caricaLocazioni([codFiscale: soggetto.contribuente.codFiscale], locazioniPaginazione,
                        locazioniOrderBy).record
                BindUtils.postNotifyChange(null, null, this, "listaContrattiUtenze")
                BindUtils.postNotifyChange(null, null, this, "listaContrattiLocazioni")
                break
            case "concessioni":
                cuCaricaListaConcessioni()
                inizializzaDovutoDePagCuni()
                concessioneSelezionata = null
                BindUtils.postNotifyChange(null, null, this, "listaConcessioni")
                BindUtils.postNotifyChange(null, null, this, "concessioneSelezionata")
                break
            case "comTarsu":
                caricaCompensazioni()
                break
            case "svuotamentiTarsu":
                caricaListaContribuentiSotria()
                caricaSvuotamenti()
                svuotamentoSelezionato = null
                BindUtils.postNotifyChange(null, null, this, "svuotamentoSelezionato")
                break
        }
    }

    @Command
    def onSelezionaTipoUtenze(@BindingParam('grid') Grid grid) {
        listaContrattiUtenze = contribuentiService.caricaUtenze([codFiscale: soggetto.contribuente.codFiscale,
                                                                 tipologia : tipoUtenza]
                , utenzePaginazione,
                utenzeOrderBy).record


        BindUtils.postNotifyChange(null, null, this, "listaContrattiUtenze")
    }

    @Command
    def onRuoliOggetto() {
        creaPopup("/sportello/contribuenti/ruoliEsgravi.zul", [oggetto: oggettoSelezionato, contribuente: soggetto.contribuente])
    }

    @Command
    def onVisualizzaStoricoProprietari() {
        creaPopup("/sportello/contribuenti/storicoProprietari.zul", [oggetto: oggettoSelezionato.oggetto])
    }

    @Command
    def onVisualizzaInformazioniCatasto() {
        creaPopup("/sportello/contribuenti/informazioniCatastoCensuario.zul", [oggetto: oggettoSelezionato])
    }

    @Command
    def onVisualizzaInformazioniCatastoImmobile() {

        if (!immobileCatastoSelezionato.SEZIONE && !immobileCatastoSelezionato.FOGLIO && !immobileCatastoSelezionato.NUMERO & !immobileCatastoSelezionato.SUBALTERNO) {
            return
        }

        creaPopup("/sportello/contribuenti/informazioniCatastoCensuario.zul",
                [oggetto: immobileCatastoSelezionato])
    }

    @Command
    def onVisualizzaRendite() {

        Window w = Executions.createComponents("/sportello/contribuenti/situazioneContribuenteRenditeOggetto.zul", self,
                [oggettoSelezionato: oggettoSelezionato])
        w.doModal()
    }

    @Command
    def onVisualizzaContribuentiOggetto() {
        Window w = Executions.createComponents("/sportello/contribuenti/contribuentiOggetto.zul", self,
                [oggetto  : (tabSelezionata == 'pratiche' ? oggettoPraticaSelezionato.id : oggettoSelezionato.oggetto),
                 pratica  : null,
                 anno     : anno,
                 listaAnni: listaAnni])
        w.onClose() { event ->
            if (event.data) {
                closeAndOpenContribuente(event.data.idSoggetto)
            }
        }
        w.doModal()

    }

    @Command
    def onVisualizzaContribuentiOggettoPratica() {
        Window w = Executions.createComponents("/sportello/contribuenti/contribuentiOggetto.zul", self,
                [oggetto  : (tabSelezionata == 'pratiche' ? oggettoPraticaSelezionato.id : oggettoSelezionato.oggetto),
                 pratica  : praticaSelezionata.id,
                 anno     : anno,
                 listaAnni: listaAnni])
        w.onClose() { event ->
            if (event.data) {
                closeAndOpenContribuente(event.data.idSoggetto)
            }
        }
        w.doModal()

    }

    @Command
    def onSostituisciOggetto() {
        Long idNewOggetto
        filtroRicercaOggetto = new FiltroRicercaOggetto()
        filtroRicercaOggetto.indirizzo = oggettoSelezionato.indirizzo
        filtroRicercaOggetto.numCiv = oggettoSelezionato.numCiv
        filtroRicercaOggetto.interno = oggettoSelezionato.interno
        filtroRicercaOggetto.scala = oggettoSelezionato.scala
        filtroRicercaOggetto.sezione = oggettoSelezionato.sezione
        filtroRicercaOggetto.foglio = oggettoSelezionato.foglio
        filtroRicercaOggetto.numero = oggettoSelezionato.numero
        filtroRicercaOggetto.subalterno = oggettoSelezionato.subalterno
        filtroRicercaOggetto.partita = oggettoSelezionato.partita

        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self, [filtri: [filtroRicercaOggetto], listaVisibile: true, inPratica: true, ricercaContribuente: false])
        w.onClose { event ->
            if (event.data) {
                idNewOggetto = event.data.idOggetto
                Map dettaglioOggetto = [tipoTributo   : oggettoSelezionato.tipoTributo
                                        , cfContr     : soggetto.contribuente.codFiscale
                                        , idOldOggetto: oggettoSelezionato.oggetto
                                        , idNewOggetto: idNewOggetto]
                Window wSostituzione = Executions.createComponents("/sportello/contribuenti/sostituzioneOggetto.zul", self, [dettaglioOggetto: dettaglioOggetto, sostituisciDaAnomalie: false])
                wSostituzione.onClose { e ->
                    if (e.data) {
                        caricaListaContribuentiSotria()
                        oggettoSelezionato = null

                        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
                    }
                }

                wSostituzione.doModal()
            }
        }
        w.doModal()
    }

    @Command
    def onSostituisciRFID() {

        Window w = Executions.createComponents("/sportello/contribuenti/sostituzioneRFID.zul", self,
                [oggetto    : oggettoSelezionato,
                 codFiscale : soggetto.contribuente.codFiscale,
                 tipiTributo: ['TARSU'],
                 tipiPratica: ['D']])
        w.onClose { e ->
            if (e.data) {
                caricaListaContribuentiSotria()
                oggettoSelezionato = null

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
            }
        }
        w.doModal()
    }

    @Command
    def onModificaOggetto(@BindingParam("contesto") String contesto) {

        modificaOggetto(contesto)
    }

    @Command
    def onModificaOggettoCorrezione(@BindingParam("errore") errore) {

        if (!errore) {
            modificaOggetto("OGGETTO")
            return
        }

        modificaOggetto("OGGETTO", errore)
    }

    @Command
    onF24Violazione() {

        if (praticaSelezionata.tipoTributo.tipoTributo == 'TARSU' && !f24Service.checkF24Tarsu(praticaSelezionata.id)) {
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
    def onF24Ruolo(@BindingParam("tipo") String tipo) {

        List f24data = f24Service.caricaDatiF24(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo, tipo)

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [:])
        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])


        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onF24Imposte(@BindingParam("tipo") String tipo) {

        def tipoVersamento = ''
        def dovutoVersato = ''

        switch (tipo) {
            case 'ACCONTO':
                tipoVersamento = 'A'
                break
            case 'SALDO_DOVUTO':
                tipoVersamento = 'S'
                dovutoVersato = 'D'
                break
            case 'SALDO_VERSATO':
                tipoVersamento = 'S'
                dovutoVersato = 'V'
                break
            case 'UNICO':
                tipoVersamento = 'U'
                break
            default:
                throw new RuntimeException("Tipo non supportato [$tipo]")
        }

        List f24data = f24Service.caricaDatiF24(impostaSelezionata.anno as short,
                impostaSelezionata.tipoTributo,
                soggetto.contribuente.codFiscale,
                tipoVersamento,
                dovutoVersato)

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [:])
        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])


        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onStampaComunicazioneF24() {
        def importo = impostaSelezionata.imposta
        def rimborso = (importo < 0)
        def praticaBase = (impostaSelezionata.praticaBase != null) ? impostaSelezionata.praticaBase : -1
        def tipoModello = "COM_${impostaSelezionata.tipoTributo}"
        if (rimborso) tipoModello += 'R'

        def nomeFile = "COM_" + impostaSelezionata.descrTipoTributo + "_" + codFiscale.padLeft(16, "0")

        def parametri = [

                tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                idDocumento: [tipoTributo: impostaSelezionata.tipoTributo,
                              ruolo      : 0,
                              anno       : impostaSelezionata.anno,
                              codFiscale : soggetto.contribuente.codFiscale,
                              pratica    : praticaBase],
                nomeFile   : nomeFile,]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", null, [parametri: parametri])
    }

    @Command
    def onF24Bianco() {
        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [:])
        List f24data = f24Service.caricaDatiF24(soggetto.contribuente.codFiscale)
        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onSchedaOggetti() {

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.SCHEDA_OGGETTI,
                [:])
        List<ContribuenteDTO> schedaOggetti = new ArrayList<ContribuenteDTO>()
        ContribuenteDTO contribuenteDTO = contribuentiService.getDatiContribuente(soggetto.contribuente.codFiscale, true,
                getTipiTributoSelezionati(), cbTipiPratica.findAll { k, v -> v }.collect { it.key })

        contribuenteDTO.versamenti = new TreeSet<VersamentoDTO>(listaVersamenti ?: contribuentiService.versamentiContribuente(soggetto.contribuente.codFiscale,
                'list',
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key }))

        schedaOggetti.add(contribuenteDTO)
        JasperReportDef reportDef = new JasperReportDef(name: 'schedaContribuenteOggetti.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: schedaOggetti
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ENTE         : ad4EnteService.getEnte()])

        def scheda = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, scheda.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onSchedaPratiche() {

        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.SCHEDA_PRATICHE,
                [:])
        List<ContribuenteDTO> schedaPratiche = new ArrayList<ContribuenteDTO>()

        ContribuenteDTO contribuenteDTO = contribuentiService.getDatiContribuente(soggetto.contribuente.codFiscale,
                getTipiTributoSelezionati(), cbTipiPratica.findAll { k, v -> v }.collect { it.key })

        contribuenteDTO.versamenti = new TreeSet<VersamentoDTO>(listaVersamenti ?: contribuentiService.versamentiContribuente(soggetto.contribuente.codFiscale,
                'list',
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key }))

        schedaPratiche.add(contribuenteDTO)
        JasperReportDef reportDef = new JasperReportDef(name: 'schedaContribuentePratiche.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: schedaPratiche
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ENTE         : ad4EnteService.getEnte()])

        def scheda = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, scheda.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onStampaDenuncia() {

        def nomeFile = "DEN_" + (praticaSelezionata.id as String).padLeft(10, "0") + "_" + soggetto.contribuente.codFiscale.padLeft(16, "0")

        def parametri = [tipoStampa : ModelliService.TipoStampa.PRATICA,
                         idDocumento: praticaSelezionata.id,
                         nomeFile   : nomeFile,]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [parametri: parametri])
    }

    @Command
    def onLetteraGenerica() {

        def nomeFile = ""

        def parametri = [tipoStampa: ModelliService.TipoStampa.LETTERA_GENERICA,
                         soggetto  : soggetto]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [parametri: parametri])
    }

    @Command
    def onAvvisoDiPagamentoTari() {

        def nomeFile = "COM_" + (ruoloSelezionato.ruolo as String).padLeft(10, "0") + "_" + ruoloSelezionato.codFiscale.padLeft(16, "0")

        def parametri = [tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                         idDocumento: [ruolo     : ruoloSelezionato.ruolo,
                                       anno      : ruoloSelezionato.anno,
                                       codFiscale: ruoloSelezionato.codFiscale],
                         nomeFile   : nomeFile,]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [parametri: parametri])

    }

    @Command
    def onCalcolaImposta() {
        Window w = Executions.createComponents("/ufficiotributi/imposte/calcoloImposta.zul", self
                , [anno: null, tipoTributo: null, cognomeNome: soggetto.cognomeNome, codFiscale: soggetto.contribuente.codFiscale])
        w.onClose { event ->
            if (event?.data?.calcoloEseguito) {
                listaImposte = contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)
                calcolaVisualizzaDovuto()
                onRefresh()
                BindUtils.postNotifyChange(null, null, this, "listaImposte")
            }
        }
        w.doModal()
    }

    @Command
    def onPassaggioAPagoPa() {
        if (praticaSelezionata) {
            def response = integrazioneDePagService.passaPraticaAPagoPAConNotifica(praticaSelezionata.id, self)
        }
    }

    @Command
    def onSelezionaVersamento(@BindingParam("popup") Component popup) {
        if (versamentoSelezionato.pratica?.tipoPratica) {
            descrizioneTipoPraticaVersamentoSelezionato = liquidazioniAccertamentiService.getDescrizioneTipoPratica(versamentoSelezionato.pratica.tipoPratica,
                    versamentoSelezionato.tipoTributo.tipoTributo,
                    versamentoSelezionato.pratica.anno)
        } else {
            descrizioneTipoPraticaVersamentoSelezionato = ''
        }

        popup.visible = true

        BindUtils.postNotifyChange(null, null, this, "descrizioneTipoPraticaVersamentoSelezionato")
    }

    @Command
    def onNuovoVersamentoTribAtt() {

        def tributo = cbTributi.find { k, v -> v }.collect { it.key }

        nuovoVersamento(tributo)
    }

    @Command
    def onNuovoVersamento(@BindingParam("tributo") String tributo) {

        nuovoVersamento(tributo)
    }

    @Command
    def onModificaVersamento() {

        gestioneVersamento(false, false)
    }

    @Command
    def onTrasferisciVersamento() {

        // Via breve, elenco diretto oppure scollega subito

        if (versamentoSelezionato.pratica == null) {
            collegaVersamento()
        } else {
            scollegaVersamento()
        }
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
        if (popup?.id?.startsWith("popupNote_")) {
            noteDocumentoContribuente = documentoSelezionato.note
            BindUtils.postNotifyChange(null, null, this, "noteDocumentoContribuente")
        }
    }

    @Command
    def onChiudiPopupNote(@BindingParam("doc") DocumentoContribuente documentoContribuente) {
        documentoSelezionato.note = noteDocumentoContribuente
        contribuentiService.caricaDocumento(documentoContribuente)
        BindUtils.postNotifyChange(null, null, documentoSelezionato, "note")
        popupNote.close()
    }

    @Command
    def onApriNoteSoggetto() {
        tempStringNoteSoggetto = soggetto.note
        BindUtils.postNotifyChange(null, null, this, "tempStringNoteSoggetto")
    }

    @Command
    def onChiudiNoteSoggetto() {
        soggetto.note = tempStringNoteSoggetto
        BindUtils.postNotifyChange(null, null, this, "soggetto")

        popupNoteSoggetto.close()
    }

    private def scollegaVersamento() {

        VersamentoDTO versamento = versamentoSelezionato

        def descrizionePratica = versamentiService.getDescrizionePraticaDaVersamento(versamento)

        String messaggio = "Confermi di voler scollegare il versamento dalla pratica ${descrizionePratica} ?"
        Messagebox.show(messaggio, "Scollega versamento",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            collegaVersamentoPratica(null)
                        }
                    }
                })
    }

    private def collegaVersamento() {

        VersamentoDTO versamento = versamentoSelezionato

        Window w = Executions.createComponents("/versamenti/versamentoSelezionaPratica.zul", self,
                [codFiscale : versamento.contribuente.codFiscale,
                 anno       : versamento.anno,
                 tipoTributo: versamento.tipoTributo.tipoTributo])
        w.onClose { event ->
            if (event.data) {

                def praticaId = event.data.pratica
                PraticaTributoDTO pratica = PraticaTributo.findById(praticaId).toDTO()
                collegaVersamentoPratica(pratica)
            }
        }
        w.doModal()
    }

    def collegaVersamentoPratica(PraticaTributoDTO pratica) {

        VersamentoDTO versamento = versamentoSelezionato

        try {
            versamentiService.collegaPratica(versamento, pratica)
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }

        caricaVersamenti(true)
    }

    private short getAnnoAttivo() {

        Short annoNow

        if (anno == 'Tutti') {
            annoNow = Calendar.getInstance().get(Calendar.YEAR) as Short
        } else {
            annoNow = anno as Short
        }

        return annoNow
    }

    private def nuovoVersamento(String tributo) {

        Short annoNow = getAnnoAttivo()

        Boolean trasferisci = cbTributiVersamentoTrasferisci[tributo]

        creaPopup("/versamenti/versamento.zul",
                [codFiscale : codFiscale,
                 tipoTributo: tributo,
                 anno       : annoNow,
                 sequenza   : 0,
                 lettura    : false,
                 trasferisci: trasferisci],
                { event ->
                    if (event.data) {

                        if (!isContribuente && event.data?.salvato) {
                            Events.postEvent(Events.ON_CLOSE, self, [status                        : "refreshSC",
                                                                     idSoggetto                    : soggetto.id,
                                                                     aggiornaLista                 : true,
                                                                     aggiornaSituazioneContribuente: true])
                        } else if (isContribuente) {
                            if (event.data.aggiornaStato) {
                                caricaVersamenti(true)
                            }
                        }

                    }
                })
    }

    private def gestioneVersamento(Boolean lettura, Boolean trasferisci) {

        commonService.creaPopup("/versamenti/versamento.zul",
                self,
                [codFiscale : versamentoSelezionato.contribuente.codFiscale,
                 tipoTributo: versamentoSelezionato.tipoTributo.tipoTributo,
                 anno       : versamentoSelezionato.anno,
                 sequenza   : versamentoSelezionato.sequenza,
                 lettura    : lettura,
                 trasferisci: trasferisci],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato) {
                            caricaVersamenti(true)
                            aggiornaIndiciTab()
                            if (Soggetto.get(soggetto.id).contribuente == null) {
                                Messagebox.show("Il contribuente è stato eliminato.", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION, new EventListener() {
                                    void onEvent(Event evnt) throws Exception {
                                        closeCurrentAndRefreshListaContribuente()
                                    }
                                })
                            }
                        }
                    }
                })
    }

    private def caricaRuoli(def force = false) {
        if (force) {
            listaRuoli = contribuentiService.ruoliContribuente(soggetto.contribuente.codFiscale, false, filtroRuoli)
        } else {
            listaRuoli = listaRuoli ?: contribuentiService.ruoliContribuente(soggetto.contribuente.codFiscale)
        }

        def anniErroreCaTa = listaRuoli.findAll { it.flagErroreCaTa == 'S' }?.collect { it.anno }
        anniErroreCaTa = anniErroreCaTa.stream().distinct().collect()
        anniErroreCaTa = anniErroreCaTa.sort { a, b -> a <=> b }

        if (anniErroreCaTa.size() > 0) {
            def anni = anniErroreCaTa.join(', ')
            Clients.showNotification("Configurare la tabella dei carichi TARSU per ${anni}.",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 5000, true)
        }

        ruoloSelezionato = null
        listaOggettiRuolo = []
        oggettoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
        BindUtils.postNotifyChange(null, null, this, "ruoloSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaOggettiRuolo")
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    private def caricaFamiliari(def force = false) {
        if (force) {
            listaFamiliari = contribuentiService.familiariContribuente(soggetto.id)
        } else {
            listaFamiliari = listaFamiliari ?: contribuentiService.familiariContribuente(soggetto.id)
        }

        familiareSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
        BindUtils.postNotifyChange(null, null, this, "familiareSelezionato")
    }

    @Command
    def onAggiungiFamiliare() {

        //Se è già presente un periodo aperto si propone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 0) {
            apriPopupChiusuraPeriodiFamiliariAperti(listaFamiliari, FamiliariService.TipoOperazione.INSERIMENTO)
        } else {
            apriDialogGestioneFamiliari(FamiliariService.TipoOperazione.INSERIMENTO)
        }

    }

    @Command
    def onEliminaFamiliare() {

        String msg = "Si è scelto di eliminare il familiare:\n" + "La familiare verrà eliminato e non sarà recuperabile.\n" + "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Familiare", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName() == "onOK") {
                    FamiliareSoggetto familiare =
                            contribuentiService.getFamiliareContribuente(familiareSelezionato.soggetto,
                                    familiareSelezionato.anno,
                                    familiareSelezionato.dal)
                    contribuentiService.eliminaFamiliareContribuente(familiare)

                    Clients.showNotification("Eliminazione avvenuta con successo",
                            Clients.NOTIFICATION_TYPE_INFO, self,
                            "before_center", 5000, true)
                    onRefresh()
                }
            }
        })
    }

    @Command
    def onDuplicaFamiliare() {

        //Se è già presente un periodo aperto si propone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 0) {
            apriPopupChiusuraPeriodiFamiliariAperti(listaFamiliari, FamiliariService.TipoOperazione.CLONAZIONE)
        } else {
            apriDialogGestioneFamiliari(FamiliariService.TipoOperazione.CLONAZIONE)
        }

    }

    @Command
    def onModificaFamiliare() {
        apriDialogGestioneFamiliari(FamiliariService.TipoOperazione.MODIFICA)
    }

    private def apriDialogGestioneFamiliari(FamiliariService.TipoOperazione tipoOperazione, def familiare = null) {

        familiare = familiare ?: familiareSelezionato

        commonService.creaPopup("/sportello/contribuenti/dettagliFamiliariContribuente.zul", self,
                [tipoOperazione: tipoOperazione,
                 familiare     : tipoOperazione in [FamiliariService.TipoOperazione.MODIFICA,
                                                    FamiliariService.TipoOperazione.CLONAZIONE] ? familiare : new FamiliareSoggettoDTO([soggetto: soggetto]),
                 listaFamiliari: listaFamiliari], { e -> onRefresh()
        })
    }

    private def apriPopupChiusuraPeriodiFamiliariAperti(def listaFamiliari, def tipoOperazione = null) {

        String msg = "Esistono periodi aperti.\n" + "Si desidera chiuderli automaticamente?"

        Messagebox.show(msg, "Attenzione.", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName() == "onOK") {

                    def familiareTemp = null

                    // Siamo nel caso di modifica/clonazione
                    if (tipoOperazione in [FamiliariService.TipoOperazione.MODIFICA,
                                           FamiliariService.TipoOperazione.CLONAZIONE]) {
                        familiareTemp = new FamiliareSoggettoDTO()
                        InvokerHelper.setProperties(familiareTemp, familiareSelezionato.properties)
                    }

                    familiariService.chiudiPeriodiAperti(listaFamiliari, true)
                    Clients.showNotification("Chiusura periodi avvenuta con successo",
                            Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

                    // Siamo nel caso di modifica/clonazione
                    if (tipoOperazione != null) {
                        apriDialogGestioneFamiliari(tipoOperazione, familiareTemp)
                    }

                    onRefresh()
                }
            }
        })

    }

    private def caricaContatti(def force = false) {
        if (force) {
            listaContatti = contribuentiService.contattiContribuente(soggetto.contribuente.codFiscale,
                    getTipiTributoSelezionati())
        } else {
            listaContatti = listaContatti ?: contribuentiService.contattiContribuente(soggetto.contribuente.codFiscale,
                    getTipiTributoSelezionati())
        }

        contattoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaContatti")
        BindUtils.postNotifyChange(null, null, this, "contattoSelezionato")
    }

    private def caricaPratiche(def force = false) {

        if (force) {
            listaPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                    "list",
                    getTipiTributoSelezionati(),
                    cbTipiPratica.findAll { k, v -> v }.collect { it.key },
                    campiOrdinamentoPratiche)
        } else {
            listaPratiche = listaPratiche ?: contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                    "list",
                    getTipiTributoSelezionati(),
                    cbTipiPratica.findAll { k, v -> v }.collect { it.key },
                    campiOrdinamentoPratiche)
        }

        calcolaDisabilitaDataNotificaSuRateazione()

        listaOggettiPratica = []
        praticaSelezionata = null
        oggettoPraticaSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "listaPratiche")
        BindUtils.postNotifyChange(null, null, this, "listaOggettiPratica")
        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "oggettoPraticaSelezionato")
    }

    private def caricaVersamenti(def force = false) {

        if (force) {
            listaVersamenti = contribuentiService.versamentiContribuente(soggetto.contribuente.codFiscale,
                    'list',
                    getTipiTributoSelezionati(),
                    cbTipiPratica.findAll { k, v -> v }.collect { it.key })
        } else {
            listaVersamenti = listaVersamenti ?: contribuentiService.versamentiContribuente(soggetto.contribuente.codFiscale,
                    'list',
                    getTipiTributoSelezionati(),
                    cbTipiPratica.findAll { k, v -> v }.collect { it.key })
        }

        versamentoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
        BindUtils.postNotifyChange(null, null, this, "versamentoSelezionato")
    }

    private def caricaImposte(force = false) {
        if (force) {
            listaImposte = contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)
            aliquoteMultipleTooltipText = [:]
            BindUtils.postNotifyChange(null, null, this, 'aliquoteMultipleTooltipText')
        } else {
            listaImposte = listaImposte ?: contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)
        }
        impostaSelezionata = null
        listaOggettiImposta = []
        oggettoSelezionato = null
        controllaCarichiTarsu()
        calcolaVisualizzaDovuto()
        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "impostaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaOggettiImposta")
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
    }

    @Command
    def onDovutoVersato() {
        creaPopup("/imposta/dovutoVersato.zul", [cognomeNome: soggetto.cognomeNome, codFiscale: soggetto.contribuente.codFiscale, idSoggetto: soggetto.id])
    }

    @Command
    def onCalcolaLiquidazione(@BindingParam("tributo") String tributo) {

        Window w = Executions.createComponents("/sportello/contribuenti/calcoloLiquidazioniICI.zul", self
                , [tributo: tributo, cognomeNome: soggetto.cognomeNome, codFiscale: soggetto.contribuente.codFiscale, modificaCognomeNomeCodFiscale: true])

        w.onClose() { event ->
            if (event.data && (event.data).elaborazioneEseguita) {
                forzaCaricamentoTab.each { it.value = true }
                onRefresh()
            }
        }

        w.doModal()
    }

    @Command
    def onCambiaTipoAtto() {
        disabilitaDataNotificaSuRateazione[praticaSelezionata.id] = praticaSelezionata.dataNotificaDate && (praticaSelezionata.tipoAtto?.tipoAtto == 90 || rateazioneService.praticaRateizzata((praticaSelezionata.id ?: 0) as Long))

        BindUtils.postNotifyChange(null, null, this, "disabilitaDataNotificaSuRateazione")
    }

    @Command
    def onCalcolaAccertamento() {

        commonService.creaPopup("/sportello/contribuenti/calcoloAccertamenti.zul", self,
                [tributo                      : null,
                 anno                         : null,
                 modalitaCognomeNomeCodFiscale: 'D',
                 modalitaAnno                 : 'N',
                 codFiscale                   : soggetto?.contribuente?.codFiscale,
                 cognomeNome                  : soggetto?.cognomeNome],
                { event ->
                    if (event.data && (event.data).elaborazioneEseguita) {
                        forzaCaricamentoTab.each { it.value = true }
                        onRefresh()
                    }
                })
    }

    @Command
    def onCalcolaSolleciti() {

        commonService.creaPopup("/pratiche/solleciti/calcoloSolleciti.zul", self,
                [tipoTributo                  : null,
                 anno                         : null,
                 cognomeNome                  : soggetto?.cognomeNome,
                 codFiscale                   : soggetto?.contribuente?.codFiscale,
                 listaContribuenti            : null,
                 modalitaCognomeNomeCodFiscale: "D",
                 modalitaTipoTributo          : "V"],
                { event ->
                    if (event.data) {
                        if ((event.data)?.elaborazioneEseguita == true) {
                            Clients.showNotification("Pratica creata", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                            onRefresh()
                        } else if ((event.data)?.elaborazioneEseguita == false && (event.data)?.isSoloAnno == false) {
                            Clients.showNotification("Pratica non creata", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                        } else if ((event.data)?.elaborazioneEseguita == false && (event.data)?.isSoloAnno == true) {
                            // Nel caso si avvia un calcolo singolo senza specificare CF, non è possibile capire se ha creato o no le pratiche per l'anno scelto
                            Clients.showNotification("Calcolo eseguito", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                })
    }


    @Command
    def onComponentiDellaFamiglia() {
        Window w = Executions.createComponents("/sportello/contribuenti/componentiDellaFamiglia.zul", self
                , [sogg: soggetto, modificaCognomeNomeCodFiscale: true])

        w.doModal()
    }

    @Command
    def onEventiResidenzeStoriche() {

        Window w = Executions.createComponents("/sportello/contribuenti/eventiResidenzeStoriche.zul", self
                , [sogg: soggetto])
        w.doModal()
    }

    @Command
    def onCalcoloFamiliariSoggetto() {

        String titolo = "Calcolo del Numero Familiari del Soggetto: " + soggetto.cognome + " " + soggetto.nome
        String contribuenteDescr = "Contribuente:    " + soggetto.cognome + " " + soggetto.nome + " - " + soggetto.codFiscale

        commonService.creaPopup("/archivio/calcoloFamiliari.zul", self,
                [idSoggetto       : soggetto?.id ?: -1,
                 titolo           : titolo,
                 contribuenteDescr: contribuenteDescr])
    }

    @Command
    def onAnagrafeTributaria() {

        commonService.creaPopup("/ufficiotributi/anagrafetributaria/dettaglioAnagrafeTributaria.zul", self
                , [soggetto: soggetto],
                { event ->
                    if (event.data?.aggiornato) {
                        soggetto = Soggetto.get(soggetto.id).toDTO(["contribuenti",
                                                                    "comuneResidenza",
                                                                    "comuneResidenza.ad4Comune",
                                                                    "archivioVie",
                                                                    "stato"])
                        codFiscale = soggetto?.contribuente?.codFiscale

                        aggiornaUltimoStato()

                        BindUtils.postNotifyChange(null, null, this, "soggetto")
                        BindUtils.postNotifyChange(null, null, this, "codFiscale")
                    }
                })
    }

    @Command
    def onVisualizzaDocumento() {

        // Se inviato al documentale
        if (documentoSelezionato.idComunicazionePnd != null) {

            try {
                def comunicazione = smartPndService.getComunicazione(documentoSelezionato.idComunicazionePnd)

                commonService.creaPopup("/sportello/contribuenti/smartPndComunicazione.zul",
                        null,
                        [comunicazione: comunicazione])
            } catch (Exception e) {
                log.error("Errore durante la visualizzazione della comunicazione PND", e)
                Clients.showNotification("Impossibile contattare ${SmartPndService.TITOLO_SMART_PND}:\n${e.message}",
                        Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            }
        } else if (documentoSelezionato.idDocumentoGdm != null) {
            def url = documentaleService.urlInGDM(documentoSelezionato.idDocumentoGdm)

            log.info "Apertura Documentale: ${url}"

            Clients.evalJavaScript("window.open('${url}','_blank');")
        } else if (documentoSelezionato.idMessaggio != null) {
            creaPopup("/messaggistica/messaggio.zul", [codFiscale: soggetto.contribuente.codFiscale,
                                                       sequenza  : documentoSelezionato.sequenza])
        } else if ((documentoSelezionato?.nomeFile?.lastIndexOf('.') ?: -1) >= 0) {


            String extension = ""

            int i = documentoSelezionato.nomeFile.lastIndexOf('.')
            if (i >= 0) {
                extension = documentoSelezionato.nomeFile.substring(i + 1)
            }

            String mimeType

            if (documentoSelezionato.documento) {
                Magic parser = new Magic()
                MagicMatch match = parser.getMagicMatch(documentoSelezionato.documento)
                mimeType = match.mimeType

            } else {
                mimeType = Files.probeContentType(new File(documentoSelezionato.nomeFile).toPath())
            }

            AMedia amedia = new AMedia(documentoSelezionato.nomeFile, extension, mimeType, documentoSelezionato.documento ?: [] as byte[])
            Filedownload.save(amedia)
        } else {
            Clients.showNotification("Documento non valido.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        }
    }

    @Command
    def onOpenFinestraCaricamento(@BindingParam("azione") String azione) {

        Window w = Executions.createComponents("/sportello/contribuenti/caricaDocumento.zul", null,
                [documento    : (azione == 'visualizza' ? commonService.clona(documentoSelezionato) : new DocumentoContribuente([contribuente: soggetto.contribuente.domainObject])),
                 daDocumentale: documentoSelezionato?.idDocumentoGdm != null])
        w.doModal()
        w.onClose() {
            onRefresh()
            BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")
            BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
        }
    }

    @Command
    def onEliminaDocumento() {

        Messagebox.show("Eliminazione della registrazione?", "Documenti Contribuente", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {
            void onEvent(Event evt) throws InterruptedException {
                if (evt.getName().equals("onOK")) {

                    DocumentoContribuente.get(documentoSelezionato).delete(failOnError: true, flush: true)
                    onRefresh()
                    BindUtils.postNotifyChange(null, null, this, "listaDocumentiCaricati")
                    BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
                }
            }
        })

    }

    @Command
    def onSelezionaDocumento() {
        fetchListaAllegati()
    }

    private fetchListaAllegati() {
        listaAllegati = documentoSelezionato ? contribuentiService.allegatiDocumentoContribuente(documentoSelezionato).toDTO() : []
        BindUtils.postNotifyChange(null, null, this, 'listaAllegati')
    }

    @Command
    def onVisualizzaMappa() {

        Window w = Executions.createComponents("/archivio/oggettiWebGis.zul", self
                , [oggetti: listaOggetti,
                   zul    : '/archivio/oggettiWebGisCruscotto.zul'])

        w.doModal()
    }

    @Command
    def onChiudiOggetti() {

        def listaOggettiDaChiudere = listaOggetti.findAll {
            it.flagPossesso && ((it.tipoPratica == 'D' && it.tipoEvento != 'C') || it.tipoPratica == 'A')
        }

        Window w = Executions.createComponents("/archivio/oggettiContribuente.zul", self
                , [azione     : 'CHIUDI',
                   dati       : [oggetti: listaOggettiDaChiudere, codFiscale: soggetto.contribuente.codFiscale],
                   zul        : '/archivio/oggettiWebGisCruscotto.zul',
                   tipiTributo: cbTributi,
                   tipiPratica: cbTipiPratica,
                   annoFiltro : anno != 'Tutti' ? anno as Long : null],)

        w.onClose() { event ->
            if (event.data?.oggettiChiusi) {
                caricaListaContribuentiSotria()

                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    creaAssociazioneOggetti()
                }

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
            }

        }

        w.doModal()
    }

    @Command
    def onChiudiOggettiTarsu() {
        commonService.creaPopup("/pratiche/denunce/utenzeTari.zul", self, [tipoEvento  : TipoEventoDenuncia.C,
                                                                           contribuente: soggetto.contribuente,
                                                                           anno        : anno != 'Tutti' ? anno as short : null], { e ->
            if (e.data?.utenze) {
                contribuentiService.chiudiOggettiTarsu(e.data.anno,
                        soggetto.contribuente,
                        e.data.utenze,
                        e.data.data1,
                        e.data.data2,
                        e.data.soggDest,
                        e.data.inizioOccupazione,
                        e.data.dataDecorrenza,
                        e.data.dataDel,
                        e.data.numero)

                caricaListaContribuentiSotria()

                if (scp.tipoVisualizzazioneOggetti == 'D') {
                    creaAssociazioneOggetti()
                }

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")

            }
        })
    }

    @Command
    def onInserisciOggetti() {

        // Mappa degli id immobili non associati
        def listaImmobiliDaVisualizzare = immobiliNonAssociatiCatasto.findAll { k, v -> v }.collect { k, v -> k.substring(0, k.indexOf('-')) as BigDecimal }

        def immobiliInCatasto = oggettiDaCatasto.findAll {
            it.IDIMMOBILE in listaImmobiliDaVisualizzare
        }

        def tipiTributo = cbTributi.clone()
        def tipiPratica = cbTipiPratica.clone()

        commonService.creaPopup("/archivio/oggettiContribuente.zul", self
                , [azione     : 'INSERISCI',
                   dati       : [oggetti: immobiliInCatasto, codFiscale: soggetto.contribuente.codFiscale],
                   zul        : '/sportello/contribuenti/situazioneContribuenteOggettiCatasto.zul',
                   annoFiltro : anno,
                   tipiTributo: tipiTributo,
                   tipiPratica: tipiPratica],) { event ->
            if (event.data?.oggettiChiusi) {
                caricaListaContribuentiSotria()

                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    creaAssociazioneOggetti()
                }

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
            }

            if (event.data?.pratica) {

                if (event.data?.pratica?.tipoPratica != 'A') {
                    return
                }
                def tipoRapporto = 'D'
                Clients.evalJavaScript("window.open('standalone.zul?sezione=VIOLAZIONE&idPratica=${event.data?.pratica?.id}&tipoRapporto=$tipoRapporto&lettura=false','_blank');")
            }
        }
    }

    @Command
    onInserisciOggettiTarsu() {
        commonService.creaPopup("/archivio/oggettiDaDatiMetrici.zul", self,
                [contribuente: soggetto.contribuente,
                 anno        : anno as short,
                 immobili    : listaDatiMetrici
                         .findAll { immobiliNonAssociatiDatiMetrici[it.immobile] }
                         .collect { it.immobile }]) { event ->
            if (event?.data?.dichiarazioneCreata) {
                caricaListaContribuentiSotria()

                if (scp.tipoVisualizzazioneOggetti == 'D') {
                    creaAssociazioneOggetti()
                }

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
            }

            if (event.data?.pratica) {
                if (event.data?.pratica?.tipoPratica != 'A') {
                    return
                }
                def tipoRapporto = 'E'
                Clients.evalJavaScript("window.open('standalone.zul?sezione=VIOLAZIONE&idPratica=${event.data?.pratica?.id}&tipoRapporto=$tipoRapporto&lettura=false','_blank');")
            }

        }
    }

    @Command
    def onSelezionaTipoVisualizzazioneOggetti(@BindingParam("tipo") String tipo) {

        scp.tipoVisualizzazioneOggetti = tipo
        selezionaZulOggetti(tipo)
        onRefresh()
    }

    @Command
    def onSelezionaTipoVisualizzazioneDatiMetrici(@BindingParam("tipo") String tipo) {

        scp.tipoVisualizzazioneDatiMetrici = tipo
        onSelezionaTipoVisualizzazioneOggetti('D')
    }

    @Command
    def onSelezionaTipoVisualizzazioneTipoOggetto(@BindingParam("tipo") String tipo) {

        scp.tipoVisualizzazioneTipoOggetto = tipo
        onSelezionaTipoVisualizzazioneOggetti('C')
    }

    @Command
    def invalidaIncludeOggetti() {
        (self.getFellow("includeOggetti")
                .getFellow("includeOggettiPraticheCatasto")).invalidate()
    }

    @Command
    void onInserimentoOggettiRenditeCorrezione(@BindingParam("errore") Boolean errore) {

        if (!errore) {
            onModificaOggetto('OGGETTO')
            return
        }

        inserimentoOggettiRendite(true)
    }

    @Command
    void onInserimentoOggettiRendite() {

        inserimentoOggettiRendite()
    }

    @Command
    def onOpenBonifiche(@BindingParam("ogpr") Long ogpr, @BindingParam("ogg") Long oggetto) {

        def elencoTipiAnomalia = contribuentiService.anomalieOggetto(anno, soggetto.contribuente.codFiscale, ogpr, oggetto).join("-")

        Clients.evalJavaScript("window.open('standalone.zul?sezione=ANOMALIE&anno=${anno}&elencoAnom=${elencoTipiAnomalia}&oggetto=${oggetto}','_blank');")
    }

    @Command
    def onSelezioneRigaCatasto() {
        differenzeOggetti = confrontoArchivioBancheDatiService.aggiornaDifferenzeOggettiCatasto(listaOggetti, oggettiDaCatasto, immobiliNonAssociatiCatasto, cbTributi, anno)

        BindUtils.postNotifyChange(null, null, this, "oggettiDaCatasto")
        BindUtils.postNotifyChange(null, null, this, "differenzeOggetti")
        BindUtils.postNotifyChange(null, null, this, "immobiliNonAssociati")
    }


    @Command
    @NotifyChange(['modificaPraticaInline'])
    def onModificaPraticaInline() {
        modificaPraticaInline = true
        isRateazione = rateazioneService.praticaRateizzata((praticaSelezionata.id ?: 0) as Long)
        BindUtils.postNotifyChange(null, null, this, "isRateazione")
    }

    @Command
    @NotifyChange(['modificaPraticaInline', 'listaPratiche'])
    def onAnnullaModificaPraticaInline() {
        modificaPraticaInline = false
        listaPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                "list",
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key })
        try {
            (self.getFellow("includePratiche").getFellow("praticheListbox")
                    as Listbox)
                    .invalidate()
        } catch (Exception e) {
            log.info "praticheListbox non caricata."
        }

    }

    @Command
    @NotifyChange(['modificaPraticaInline'])
    def onAccettaModificaPraticaInline() {
        modificaPraticaInline = false
        salvaPraticaInline()
    }

    @Command
    def onAggiornaDovuti() {
        calcolaVisualizzaDovuto()
    }

    @Command
    def onApriInGDM() {
        def url = documentaleService.urlInGDM(documentoSelezionato.idDocumentoGdm)

        log.info "Apertura Documentale: ${url}"

        Executions.getCurrent().sendRedirect(url, "_blank")

    }

    @Command
    def onRavvedimentoOperoso() {

        def tipoTributoSelzionato = ""

        if (cbTributi.findAll { it.value }.size() == 1) {
            tipoTributoSelzionato = (cbTributi.find { it.value }.key as String)
            if (!(tipoTributoSelzionato in ['ICI', 'TASI', 'CUNI'])) {
                tipoTributoSelzionato = ""
            }
        }

        commonService.creaPopup("/pratiche/violazioni/creazioneRavvedimentoOperoso.zul",
                self,
                [anno       : anno,
                 codFiscale : soggetto.contribuente.codFiscale,
                 tipoTributo: tipoTributoSelzionato],
                { event ->
                    if (event.data) {
                        if (!event.data.pratica) {
                            Clients.showNotification("Ravvedimento non generato.", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                            return
                        }

                        listaPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                                "list",
                                getTipiTributoSelezionati(),
                                cbTipiPratica.findAll { k, v -> v }.collect { it.key })
                        BindUtils.postNotifyChange(null, null, this, "listaPratiche")

                        def ultimoRavvedimentoGenerato = listaPratiche.find { it.id == event.data.pratica }
                        if (ultimoRavvedimentoGenerato != null) {
                            praticaSelezionata = ultimoRavvedimentoGenerato
                            onModificaPratica()

                            BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
                        } else {
                            Clients.showNotification("Ravvedimento generato correttamente. Per visualizzarlo settare i filtri opportunamente."
                                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 5000, true)
                        }

                    }
                })
    }

    @Command
    def onVisuraPerSoggetto() {
        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.VISURA,
                [:])

        def reportVisura = visuraService.generaVisura(soggetto.contribuente.codFiscale)

        if (reportVisura == null) {
            Clients.showNotification("In catasto non risultano unita' immobiliari per il contribuente."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

            return
        }

        AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportVisura.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    def onNuovaDenunciaTribAtt() {
        def tributiSelezionati = cbTributi.find { k, v -> v }

        onNuovaDenuncia(tributiSelezionati.key)

    }

    @Command
    def onNuovaDenuncia(@BindingParam("tributo") String tributo) {

        def zul = ""
        switch (tributo) {
            case 'ICI':
                zul = '/pratiche/denunce/denunciaImu.zul'
                break
            case 'TASI':
                zul = '/pratiche/denunce/denunciaTasi.zul'
                break
            case 'TARSU':
                zul = '/pratiche/denunce/denunciaTari.zul'
                break
            case 'CUNI':
                zul = '/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul'
                break
            default:
                Clients.showNotification("Tipo tributo [${tributo}] non supportato.", Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
                return
        }

        creaPopup(zul,
                [pratica: -1, tipoRapporto: "D", lettura: false, daBonifiche: false, selected: soggetto, daSC: true],
                { e ->

                    if (!isContribuente && e.data?.salvato) {
                        Events.postEvent(Events.ON_CLOSE, self, [status                        : "refreshSC",
                                                                 idSoggetto                    : soggetto.id,
                                                                 aggiornaLista                 : true,
                                                                 aggiornaSituazioneContribuente: true])
                    } else if (isContribuente) {
                        listaPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                                "list",
                                getTipiTributoSelezionati(),
                                cbTipiPratica.findAll { k, v -> v }.collect { it.key })
                        BindUtils.postNotifyChange(null, null, this, "listaPratiche")
                    }
                })
    }

    @Command
    def onNuovoAccertamento(@BindingParam("tributo") String tributo) {

        def zul = ""
        def situazione = ""

        switch (tributo) {
            case 'ICI':
                zul = "/pratiche/violazioni/accertamentiManuali.zul"
                situazione = "accManImu"
                break
            case 'TARSU':
                zul = "/pratiche/violazioni/accertamentiManuali.zul"
                situazione = "accManTari"
                break
            default:
                Clients.showNotification("Tipo tributo [${tributo}] non supportato.", Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
                return
        }

        commonService.creaPopup(zul,
                self,
                [pratica    : null,
                 tipoTributo: tributo,
                 tipoPratica: "A",
                 tipoEvento : "U",
                 lettura    : false,
                 situazione : situazione,
                 daBonifiche: false,
                 soggetto   : soggetto],
                { e ->

                    if (!isContribuente && e.data?.salvato) {
                        Events.postEvent(Events.ON_CLOSE, self, [status                        : "refreshSC",
                                                                 idSoggetto                    : soggetto.id,
                                                                 aggiornaLista                 : true,
                                                                 aggiornaSituazioneContribuente: true])
                    } else if (isContribuente) {
                        listaPratiche = contribuentiService.praticheContribuente(soggetto.contribuente.codFiscale,
                                "list",
                                getTipiTributoSelezionati(),
                                cbTipiPratica.findAll { k, v -> v }.collect { it.key })
                        BindUtils.postNotifyChange(null, null, this, "listaPratiche")
                    }

                })
    }

    @Command
    def onInviaEmail() {

        creaPopup("/messaggistica/email/email.zul", [codFiscale: soggetto.contribuente.codFiscale],
                { e ->
                    if (e?.data?.esito == 'inviato') {
                        listaDocumenti = contribuentiService.documentiContribuente(soggetto.contribuente.codFiscale)
                        BindUtils.postNotifyChange(null, null, this, "listaDocumenti")
                    }
                })
    }

    @Command
    def onInviaAppIOGeneirca() {
        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : soggetto.contribuente.codFiscale,
                 tipoTributo      : OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == 'TRASV' },
                 tipoComunicazione: "LGE",
                 pratica          : null,
                 anno             : null,
                 ruolo            : null,
                 tipologia        : "G"])
    }

    @Command
    def onInviaAppIO() {
        def tipoComunicazione = ""
        def tipoTributo = ""
        def tipologia = ""
        def pratica
        def ruolo
        if (tabSelezionata == 'pratiche' && praticaSelezionata) {
            def tipoDocumento = documentaleService.recuperaTipoDocumento(praticaSelezionata.id, 'P')
            tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(praticaSelezionata.id, tipoDocumento)
            tipoTributo = praticaSelezionata.tipoTributo
            tipologia = 'P'
            pratica = praticaSelezionata
        } else if (tabSelezionata == 'concessioni') {
            tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, 'C')
            tipoTributo = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == 'CUNI' }
            tipologia = 'C'
        } else if (tabSelezionata == 'ruoli') {
            tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(null, 'S')
            tipoTributo = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == 'TARSU' }
            tipologia = 'S'
            ruolo = ruoloSelezionato
        }

        commonService.creaPopup("/messaggistica/appio/appio.zul",
                self,
                [codFiscale       : soggetto.contribuente.codFiscale,
                 tipoTributo      : tipoTributo,
                 tipoComunicazione: tipoComunicazione,
                 pratica          : pratica?.id,
                 anno             : anno == 'Tutti' ? Calendar.getInstance().get(Calendar.YEAR) : anno,
                 ruolo            : ruolo?.ruolo,
                 tipologia        : tipologia])
    }

    @Command
    def onShowDatiMetriciDettaglioImmobile() {
        showDatiMetriciDettaglioImmobile = true
        listaDatiMetriciImmobile = contribuentiService.caricaDatiMetriciImmobile([uiuId: datiMetriciSelezionato.uiuId])

        BindUtils.postNotifyChange(null, null, this, "showDatiMetriciDettaglioImmobile")
        BindUtils.postNotifyChange(null, null, this, "listaDatiMetriciImmobile")
    }


    @Command
    def onShowDatiMetriciDettaglioIntestatari() {
        showDatiMetriciDettaglioIntestatari = true
        BindUtils.postNotifyChange(null, null, this, "showDatiMetriciDettaglioIntestatari")
    }

    @Command
    def onVisualizzaContribuente(@BindingParam("ni") Long ni) {
        if ((ni != null) && (ni > 0)) {
            Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
        }
    }

    @Command
    def onVisualizzaSoggetto() {
        def ni = soggetto.id

        if (!ni) {
            Clients.showNotification("Soggetto non trovato.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=SOGGETTO&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onGeneraAvvisoAgidPratiche() {

        def avviso = modelliService.generaAvvisiAgidPratica(praticaSelezionata.id)

        if (avviso instanceof String) {
            Clients.showNotification(avviso, Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return
        }

        def media = commonService.fileToAMedia("avviso_agid_${soggetto.contribuente.codFiscale}", avviso)

        Filedownload.save(media)
    }

    @Command
    def onGeneraAvvisoAgid() {

        def avviso = modelliService.generaAvvisiAgidImposte(null, impostaSelezionata.codFiscale,
                impostaSelezionata.anno, impostaSelezionata.tipoTributo)

        if (avviso instanceof String) {
            Clients.showNotification(avviso
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
        } else {
            AMedia amedia = new AMedia("avviso_agid_${impostaSelezionata.codFiscale}", "pdf", "application/x-pdf", avviso)
            Filedownload.save(amedia)
        }
    }

    @Command
    def onInserimentoARuolo() {

        commonService.creaPopup("/ufficiotributi/imposte/listaRuoliPerSelezione.zul", self,
                [idPratica: praticaSelezionata.id, codFiscale: codFiscale],
                {})
    }

    @Command
    def onReplicaPerAnniSuccessivi() {

        Long praticaId = praticaSelezionata.id

        String message = liquidazioniAccertamentiService.verificaAccertamentoReplicabile(praticaId)

        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 10000, true)
            return;
        }

        commonService.creaPopup("/pratiche/violazioni/replicaPerAnniSuccessivi.zul", self,
                [pratica: praticaId,],
                { event ->
                    if (event?.data?.elaborazioneEseguita) {
                        caricaPratiche(true)
                    }
                })
    }

    private salvaPraticaInline() {
        def pratica = PraticaTributo.get(praticaSelezionata.id)
        pratica.dataNotifica = praticaSelezionata.dataNotificaDate
        pratica.tipoAtto = praticaSelezionata.tipoAtto ? praticaSelezionata.tipoAtto.toDomain() : null
        praticaSelezionata.utenteModifica = pratica.save(flush: true, failOnError: true)?.utente

        BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
    }

    private caricaParametri() {
        def parametro = contribuentiService.leggiParametroUtente(SIT_CONTR)

        // Se i parametri sono stati definiti
        if (parametro) {
            scp = jsonSlurper.parseText(parametro.valore)

            scp.tipoVisualizzazioneDatiMetrici = scp.tipoVisualizzazioneDatiMetrici ?: 'DC'
        } else {
            // Parametri non trovati si utilizzano quelli di default
            scp = new SituazioneContribuenteParametri()
        }

        cbTributi = scp.cbTributi
        cbTipiPratica = scp.cbTipiPratica
        // tabSelezionata = scp.idTab
        anno = scp.annoOggetti ?: 'Tutti'
        campiOrdinamentoPratiche = scp.ordinePratiche ?: SerializationUtils.clone(ordineInizialePratiche)
        SerializationUtils.clone(ordineInizialePratiche)

        selezionaZulOggetti(scp.tipoVisualizzazioneOggetti)
    }

    private selezionaZulOggetti(def tipo) {
        differenzeOggetti = [:]
        switch (tipo) {
            case 'P':
                zulOggetti = 'sportello/contribuenti/situazioneContribuenteOggettiPratiche.zul'
                break
            case 'C':
                zulOggetti = 'sportello/contribuenti/situazioneContribuenteOggettiCatasto.zul'
                break
            case 'D':
                // Nulla da fare
                break
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "zulOggetti")
    }

    private aggiornaParametri() {

        scp.cbTributi = cbTributi
        scp.cbTipiPratica = cbTipiPratica
        scp.idTab = tabSelezionata
        scp.annoOggetti = anno
        scp.ordinePratiche = campiOrdinamentoPratiche

        contribuentiService.creaParametroUtente(SIT_CONTR, scp.toJson(), "Parametri situazione contribuente.")
    }

    private controllaTributiPerVersamenti() {

        cbTributiVersamentoDettaglio = ['ICI'  : true,
                                        'TASI' : true,
                                        'TARSU': true,
                                        'ICP'  : true,
                                        'TOSAP': true,
                                        'CUNI' : true]
        cbTributiVersamentoTrasferisci = ['ICI'  : cbTributiInScrittura['ICI'] ?: false,
                                          'TASI' : cbTributiInScrittura['TASI'] ?: false,
                                          'TARSU': cbTributiInScrittura['TARSU'] ?: false,
                                          'ICP'  : cbTributiInScrittura['ICP'] ?: false,
                                          'TOSAP': cbTributiInScrittura['TOSAP'] ?: false,
                                          'CUNI' : cbTributiInScrittura['CUNI'] ?: false]

        BindUtils.postNotifyChange(null, null, this, "cbTributiVersamentoDettaglio")
        BindUtils.postNotifyChange(null, null, this, "cbTributiVersamentoTrasferisci")
    }

    private caricaListaContribuentiSotria() {

        // Null nel caso non sia da applicare il filtro
        def filtroTipoOggetto

        if (scp.tipoVisualizzazioneOggetti == 'C') {
            if (scp.tipoVisualizzazioneTipoOggetto == 'CF') {
                filtroTipoOggetto = "CF"
            } else if (scp.tipoVisualizzazioneTipoOggetto == 'CT') {
                filtroTipoOggetto = "CT"
            }
        }

        listaOggetti = contribuentiService.oggettiContribuenteStoria(soggetto.contribuente.codFiscale,
                getTipiTributoSelezionati(),
                cbTipiPratica.findAll { k, v -> v }.collect { it.key },
                filtroTipoOggetto)

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    private creaAssociazioneOggetti() {
        // Confronto con catasto
        if (scp.tipoVisualizzazioneOggetti == 'C') {
            confrontoArchivioBancheDatiService.creaAssociazioneOggettiConCatasto(listaOggetti, oggettiDaCatasto, cbTributi, cbTipiPratica)
            differenzeOggetti = confrontoArchivioBancheDatiService.aggiornaDifferenzeOggettiCatasto(listaOggetti, oggettiDaCatasto, immobiliNonAssociatiCatasto, cbTributi, anno)
            BindUtils.postNotifyChange(null, null, this, "differenzeOggetti")
            BindUtils.postNotifyChange(null, null, this, "immobiliNonAssociatiCatasto")
        } else if (scp.tipoVisualizzazioneOggetti == 'D') {
            // Confronto con dati metrici
            differenzeOggetti = confrontoArchivioBancheDatiService.aggiornaDifferenzeOggettiDatiMetrici(listaOggetti, listaDatiMetrici, immobiliNonAssociatiDatiMetrici, cbTributi, anno)
            immobiliNonAssociatiDatiMetrici << confrontoArchivioBancheDatiService.immobiliNonAssociatiDatiMetrici(listaOggetti, listaDatiMetrici)
            BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")

            confrontoArchivioBancheDatiService.creaAssociazioneOggettiConDatiMetrici(listaOggetti, listaDatiMetrici, cbTributi, cbTipiPratica, datiMetriciAssociati)

            BindUtils.postNotifyChange(null, null, this, "datiMetriciAssociati")
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    private def calcolaImposta(def tipiTributo) {

        if (anno != 'Tutti') {
            tipiTributo.each {

                def tipoTributo = (it == 'IMU' ? 'ICI' : it)

                imposteService.proceduraCalcolaImposta(anno as Integer, soggetto.contribuente.codFiscale,
                        tipoTributo,
                        'T', null, null)
            }

            listaImposte = contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)

            calcolaVisualizzaDovuto()

            BindUtils.postNotifyChange(null, null, this, "listaImposte")
        }
    }

    def calcolaTotaliImposta(def tipoTributo) {

        // L'imposta è univoca per tributo ed anno, effettuare le sum nonintroduce eccessivo ritardo.
        // Potrebbe tornare utile per sviluppi futuri.
        String patternValuta = "€ #,###.00"
        DecimalFormat valuta = new DecimalFormat(patternValuta)
        valuta.setMinimumIntegerDigits(1)

        def totImpostaNum = listaImposte.findAll {
            it.tipoTributo == tipoTributo && it.anno == (anno as Integer)
        }.sum {
            if (it.tipoTributo != 'TARSU') it.imposta ?: 0 else ((it.imposta + it.maggiorazioneTares + it.addMaggEca + it.addPro + it.iva) ?: 0)
        }
        totaleImposta = "Imposta: " + (totImpostaNum ? valuta.format(totImpostaNum) : '')
        totaleVersato = "Versato: " + valuta.format(listaImposte.findAll {
            it.tipoTributo == tipoTributo && it.anno == (anno as Integer)
        }.sum {
            it.versato ?: 0
        } ?: 0)
        //Calcolo del Totale Residuo in funzione al tipo tributo TARSU
        totaleResiduo = "Residuo: " + (totImpostaNum ? valuta.format(listaImposte.findAll {
            it.tipoTributo == tipoTributo && it.anno == (anno as Integer)
        }.sum {
            if (it.tipoTributo != 'TARSU') (it.imposta ?: 0) - (it.versato ?: 0) else (((it.imposta + it.maggiorazioneTares + it.addMaggEca + it.addPro + it.iva) ?: 0) - (it.versato ?: 0))
        } ?: 0) : '')

        BindUtils.postNotifyChange(null, null, this, "totaleImposta")
        BindUtils.postNotifyChange(null, null, this, "totaleVersato")
        BindUtils.postNotifyChange(null, null, this, "totaleResiduo")

    }

    private controllaCarichiTarsu(def annoImposta = null) {

        def gestioneTarsu = contribuentiService.checkTipoTributo('TARSU')

        if (!gestioneTarsu) {
            return
        }

        def annoAttuale = (new Date())[Calendar.YEAR]
        def anni = ""
        def rangeAnniControllo = annoImposta ? (annoImposta..annoImposta).toSet() : ((annoAttuale - 4)..annoAttuale).toSet()

        rangeAnniControllo.sort { it }.each {
            if (!OggettiCache.CARICHI_TARSU.valore.find { ct -> (ct.anno as Integer) == (it as Integer) }) {
                anni += "${it}, "
            }
        }
        if (anni.lastIndexOf(",") > -1) {
            anni = anni.substring(0, anni.lastIndexOf(","))
        }

        if (cbTributiAbilitati['TARSU'] && !anni.isEmpty()) {
            Clients.showNotification("Configurare la tabella dei carichi TARSU per ${anni}."
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
        }
    }

    private inserimentoOggettiRendite(def aggiornaImposta = false) {

        creaPopup("/catasto/inserimentoOggettiRendite.zul", [immobile    : oggettoSelezionato.idImmobile,
                                                             oggetto     : oggettoSelezionato.oggetto,
                                                             tipoImmobile: oggettoSelezionato.tipoOggetto == 3 ? 'F' : 'T'],
                { e ->
                    if (e?.data?.esito) {

                        def oggSel = oggettoSelezionato
                        caricaListaContribuentiSotria()
                        if (scp.tipoVisualizzazioneOggetti == 'C') {
                            creaAssociazioneOggetti()
                        }

                        if (aggiornaImposta) {
                            calcolaImposta(['ICI', 'TASI'])
                        }

                        if (oggSel.key != null) {
                            oggettoSelezionato = this.listaOggetti.find {
                                it.key?.startsWith(oggSel.key)
                            }
                            BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
                        }
                        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                    }
                })
    }

    private calcolaVisualizzaDovuto() {

        def tributiSelezionati = getTipiTributoSelezionati()

        visualizzaDovuto = tributiSelezionati.size() == 1 && anno != 'Tutti'
        if (visualizzaDovuto) {
            listaImposte = contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)
            calcolaTotaliImposta(tributiSelezionati.first())
        }

        BindUtils.postNotifyChange(null, null, this, "visualizzaDovuto")
    }

    private modificaOggetto(def contesto, def aggiornaImposta = false) {

        def oggettoDaModificare
        if (contesto == 'OGGETTO') {
            oggettoDaModificare = oggettoSelezionato.oggetto
        } else if (contesto == 'PRATICA') {
            oggettoDaModificare = oggettoPraticaSelezionato.id
        }

        Window w = Executions.createComponents("/archivio/oggetto.zul", self, [oggetto: oggettoDaModificare])

        w.onClose() { event ->
            if (event?.data?.salvato) {
                caricaListaContribuentiSotria()
                if (scp.tipoVisualizzazioneOggetti == 'C') {
                    creaAssociazioneOggetti()
                }

                if (aggiornaImposta) {
                    calcolaImposta([oggettoSelezionato.tipoTributo])
                }

                oggettoSelezionato = listaOggetti.findAll {
                    cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
                }.find { it.oggetto == oggettoDaModificare }

                BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
            }
        }
        w.doModal()
    }

    private caricaDatiMetrici() {
        // Se non si e' in visualizzazione dei dati metrici non si caricano i dati
        if (scp.tipoVisualizzazioneOggetti != 'D') {
            return
        }

        listaDatiMetrici = []

        // Dati metrici associati al contribuente
        if (scp.tipoVisualizzazioneDatiMetrici == 'DC') {
            log.info "Visualizzazione dati metrici per contribuente"
            if (soggetto) {
                def filtri = [codFiscale: [soggetto.contribuente.codFiscale] + contribuentiService
                        .soggettiAssociati(soggetto.contribuente.codFiscale)
                        .collect { it.codFiscaleRic },
                              tipologia : ['TARSU', 'TARES'],
                              anno      : anno]

                listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,
                        [max: Integer.MAX_VALUE, activePage: 0],
                        [[property: 'uiu.idUiu', direction: 'asc']]).record
            }
        } else if (scp.tipoVisualizzazioneDatiMetrici == 'DO') {
            // Dati metrici associati agli oggetti
            log.info "Visualizzazione dati metrici per oggetto"
            if (oggettoSelezionato != null) {
                def filtri = [sezione   : oggettoSelezionato.sezione,
                              foglio    : oggettoSelezionato.foglio,
                              numero    : oggettoSelezionato.numero,
                              subalterno: oggettoSelezionato.subalterno,
                              tipologia : ['TARSU', 'TARES'],
                              anno      : anno]

                listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri,
                        [max: Integer.MAX_VALUE, activePage: 0],
                        [[property: 'uiu.idUiu', direction: 'asc']]).record
            }
        }
        zulOggetti = 'sportello/contribuenti/situazioneContribuenteOggettiDatiMetrici.zul'

        creaAssociazioneOggetti()
        differenzeOggetti = confrontoArchivioBancheDatiService.aggiornaDifferenzeOggettiDatiMetrici(listaOggetti,
                listaDatiMetrici, immobiliNonAssociatiDatiMetrici, cbTributi, anno)

        BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
    }

    private caricaOggettiCatasto() {
        // Se non si e' in visualizzazione del catasto non si caricano i dati
        if (scp.tipoVisualizzazioneOggetti != 'C') {
            return
        }

        if (soggetto) {
            onRefresh()
        }
    }

/**
 * @deprecated
 * Sostituire con {@link it.finmatica.tr4.commons.ComonService#creaPopup}
 *
 * @param zul
 * @param parametri
 * @param onClose
 */
    @Deprecated
    private void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }

    private def sceltaRidottoF24() {
        commonService.creaPopup("/pratiche/sceltaRidottoF24Stampa.zul",
                self, [:],
                { event ->
                    if (event.data?.ridotto) {
                        generaF24(event.data.ridotto)
                    }
                })
    }

    private def generaF24(def ridotto) {
        String nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [idDocumento: praticaSelezionata.id,
                 codFiscale : soggetto.contribuente.codFiscale])

        List f24data
        List f24Ridotto
        List f24NonRidotto

        try {
            // TODO: fix temporanea per 59693, verrà gestita correttamente con la #55422
            if (ridotto != 'TUTTI') {
                f24data = f24Service.caricaDatiF24(praticaSelezionata, 'V', ridotto == 'SI')
            } else {
                f24Ridotto = f24Service.caricaDatiF24(praticaSelezionata, 'V', true)
                f24NonRidotto = f24Service.caricaDatiF24(praticaSelezionata, 'V', false)
            }

        } catch (Exception e) {
            Clients.showNotification(e.cause?.detailMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)

            if (e?.message == 'NOC_COD_TRIBUTO') {
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

    @Command
    def onConvertiConcessioni() {

        String messaggio = "Convertire i Canoni a Canone Unico per l'anno corrente?\n\nNota : il processo non potra' essere annullato"

        Messagebox.show(messaggio, "Conversione Canoni",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            cnConvertiConcessioni()
                        }
                    }
                })
    }

    @Command
    def onChiudiConcessioni() {

        def dataDecorrenza = null
        def dataChiusura = canoneUnicoService.getDataOdierna()

        boolean trasferisci = true

        Window w = Executions.createComponents("/ufficiotributi/canoneunico/chiudiConcessioneCU.zul", self,
                [anno          : null,
                 dataDecorrenza: dataDecorrenza,
                 dataChiusura  : dataChiusura,
                 trasferisci   : trasferisci,
                 listaCanoni   : listaConcessioni])
        w.onClose { event ->
            if (event.data) {
                if (event.data.datiChiusura) {
                    cnChiudiConcessioni(event.data.datiChiusura)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onCalcolaDenunciaSingola() {

        def denuncia = praticaSelezionata

        Short annoCanone = denuncia.anno as Short
        String tipoTributoBase = denuncia.tipoTributo.tipoTributo
        def praticaBase = denuncia.id

        cuCalcolaConcessioneSingola(tipoTributoBase, annoCanone, praticaBase)
    }

    @Command
    def onCalcolaConcessioneSingola() {

        def concessione = concessioneSelezionata

        def annoCanone = concessione.anno
        String tipoTributo = concessione.tipoTributo
        def praticaBase = (tipoTributo == 'ICP') ? concessione.praticaPub : concessione.praticaOcc

        cuCalcolaConcessioneSingola(tipoTributo, annoCanone, praticaBase)
    }

    @Command
    def onAnnullaDepagDenuncia() {

        if (praticaSelezionata.tipoTributo.tipoTributo == 'CUNI') {

            Short annoCanone = getAnnoAttivo()

            def denuncia = praticaSelezionata

            def concessione = canoneUnicoService.getConcessione()
            canoneUnicoService.fillConcessioneDaPratica(concessione, denuncia.id)

            def concessioni = []
            concessioni << concessione

            cuAnnullaDepagConcessioni(concessioni, annoCanone)

            onRefresh()
        } else {
            def message = integrazioneDePagService.eliminaDovutoPratica(PraticaTributo.get(praticaSelezionata.id))
            if (message.isEmpty()) {
                Clients.showNotification("Dovuto Depag annullato con successo", Clients.NOTIFICATION_TYPE_INFO,
                        null, "top_center", 3000, true)
            } else {
                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR,
                        null, "top_center", 3000, true)
            }
            onRefresh()
        }
    }

    @Command
    def onAnnullaDepagConcessioneSingola() {

        Short annoCanone = getAnnoAttivo()

        def concessioni = []
        concessioni << concessioneSelezionata

        cuAnnullaDepagConcessioni(concessioni, annoCanone)

        onRefresh()
    }

    @Command
    def onStampaConcessioniAP() {

        Short annoCanone = getAnnoAttivo()

        String tipoTributoBase = ''
        def praticaBase = -1

        if (annoCanone >= 2021) {
            if (cbTributi['CUNI']) {
                tipoTributoBase = 'CUNI'
            }
        } else {
            if (cbTributi['ICP']) {
                tipoTributoBase = 'ICP'
            } else if (cbTributi['TOSAP']) {
                tipoTributoBase = 'TOSAP'
            } else if (cbTributi['CUNI']) {
                tipoTributoBase = 'CUNI'
            }
        }

        if (tipoTributoBase.isEmpty()) {

            Messagebox.show("Stampa non disponibile per questo/i tipo tributo/i", "Errore", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {

            cuStampaConcessioni(tipoTributoBase, annoCanone, praticaBase)
        }
    }

    @Command
    def onStampaDenunciaCUNI() {

        def denuncia = praticaSelezionata

        Short annoCanone = denuncia.anno as Short
        String tipoTributoBase = denuncia.tipoTributo.tipoTributo
        def praticaBase = denuncia.id

        cuStampaConcessioni(tipoTributoBase, annoCanone, praticaBase)
    }

    @Command
    def onOpenFiltriConcessioni() {

        commonService.creaPopup("/sportello/contribuenti/situazioneContribuenteConcessioniRicerca.zul",
                self,
                [anno: anno, filtri: filtriConcessioni],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtriConcessioni = event.data.filtri
                            cuAggiornaFiltriConcessioniAttivo()
                            cuCaricaListaConcessioni()
                            aggiornaIndiciTab()
                        }
                    }
                })
    }

    @Command
    def onSelezioneAnnoConcessioni() {

        aggiornaIndiciTab()
        aggiornaParametri()
        calcolaVisualizzaDovuto()

        cuCaricaListaConcessioni()

        inizializzaDovutoDePagCuni()
        BindUtils.postNotifyChange(null, null, this, "listaConcessioni")
        BindUtils.postNotifyChange(null, null, this, "visualizzaDovuto")
    }

    @Command
    def onGeolocalizzaOggetto() {

        def oggetto = oggettoSelezionato

        String url = oggettiService.getGoogleMapshUrl(null, oggetto.latitudine, oggetto.longitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onGeolocalizzaSvuotamento() {

        String url = oggettiService.getGoogleMapshUrl(null, svuotamentoSelezionato.latitudine, svuotamentoSelezionato.longitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onGeolocalizzaConcessione() {

        String url = canoneUnicoService.getGoogleMapshUrl(concessioneSelezionata)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    private inizializzaDovutoDePagCuni() {

        Short annoCanone = getAnnoAttivo()

        if (dePagAbilitato && anno != 'Tutti') {
            aggiornaDovutiDepAgCU = !integrazioneDePagService.determinaDovutiImposta(soggetto.contribuente.codFiscale, annoCanone, "CUNI", null)?.isEmpty()
            annullaDovutiDepAgCU = aggiornaDovutiDepAgCU
        }

        BindUtils.postNotifyChange(null, null, this, "annullaDovutiDepAgCU")
        BindUtils.postNotifyChange(null, null, this, "aggiornaDovutiDepAgCU")
    }

    @Command
    def onSelezionaConcessione() {

    }

    @Command
    def onModificaConcessione(@BindingParam("contesto") String contesto) {
        Boolean concessioneInSolaLettura = !cbTributiInScrittura[concessioneSelezionata.tipoTributoPratica]
        Window w = Executions.createComponents("/ufficiotributi/canoneunico/concessioneCU.zul", self,
                [contribuente   : soggetto.contribuente,
                 oggetto        : concessioneSelezionata.oggettoRef,
                 dataRiferimento: concessioneSelezionata.dettagli.dataDecorrenza,
                 anno           : concessioneSelezionata.anno,
                 lettura        : concessioneInSolaLettura])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.aggiornaStato) {
                    onRefresh()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onConcessioniToXls() {

        canoneUnicoService.canoniToXls(anno, listaConcessioni, [codFiscale: soggetto.contribuente.codFiscale], false)
    }

    @Command
    def onTooltipInfoOggetti(@BindingParam("sorgente") String sorgente, @BindingParam("uuid") String uuid) {
        def ogg = listaOggetti.find { it.uuid == uuid }

        if (anno != 'Tutti') {
            switch (sorgente) {
                case 'utilizzi':
                    utilizziTooltipText[uuid] = utilizziTooltipText[uuid] ?: oggettiService.tooltipUtilizzi(ogg.oggetto, , ogg.tipoTributo, anno as String)
                    BindUtils.postNotifyChange(null, null, this, "utilizziTooltipText")
                    break
                case 'alog':
                    alogTooltipText[uuid] = alogTooltipText[uuid] ?: oggettiService.tooltipAlOg(ogg.oggettoPratica, codFiscale, anno as Integer)
                    BindUtils.postNotifyChange(null, null, this, "alogTooltipText")
                    break
                case 'altricnt':
                    altricntTooltipText[uuid] = altricntTooltipText[uuid] ?: oggettiService.tooltipAltriContribuenti(ogg.tipoTributo, codFiscale, anno as Integer, ogg.oggetto as Long)
                    BindUtils.postNotifyChange(null, null, this, "altricntTooltipText")
                    break
                case 'pertinenzaDi':
                    pertinenzeDiTooltipText[uuid] = pertinenzeDiTooltipText[uuid] ?: oggettiService.tooltipPertinenzaDi(ogg.oggettoPraticaRifAp)
                    BindUtils.postNotifyChange(null, null, this, "pertinenzeDiTooltipText")
                    break
                case 'familiari':
                    familiariTooltipText[uuid] = familiariTooltipText[uuid] ?: oggettiService.tooltipFamiliari(codFiscale, anno as Long)
                    BindUtils.postNotifyChange(null, null, this, "familiariTooltipText")
                    break
                case 'svuotamenti':
                    svuotamentiTooltipText[uuid] = svuotamentiTooltipText[uuid] ?: oggettiService.tooltipSvuotamenti(codFiscale, ogg.oggetto)
                    BindUtils.postNotifyChange(null, null, this, "svuotamentiTooltipText")
                    break
            }
        }
    }

    @Command
    def onOggettoARuoloSgravi() {
        commonService.creaPopup("/ufficiotributi/imposte/ruoliOggettiSgravi.zul", self,
                [ruolo       : ruoloSelezionato.ruolo,
                 codFiscale  : ruoloSelezionato.codFiscale,
                 oggettoRuolo: oggettoRuoloSelezionato],
                { event ->
                    def rs = ruoloSelezionato
                    onRefresh()

                    ruoloSelezionato = listaRuoli.find { it.ruolo == rs.ruolo }
                    listaOggettiRuolo = contribuentiService.oggettiRuolo(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo)
                    oggettoRuoloSelezionato = listaOggettiRuolo.find { it.id == oggettoRuoloSelezionato.id }

                    BindUtils.postNotifyChange(null, null, this, "ruoloSelezionato")
                    BindUtils.postNotifyChange(null, null, this, "listaOggettiRuolo")
                    BindUtils.postNotifyChange(null, null, this, "oggettoRuoloSelezionato")
                })
    }

    @Command
    def onPraticheARuoloSgravi() {
        commonService.creaPopup("/ufficiotributi/imposte/ruoliOggettiSgravi.zul", self,
                [ruolo       : ruoloSelezionato.ruolo,
                 codFiscale  : ruoloSelezionato.codFiscale,
                 praticaRuolo: praticaSelezionata],
                { event ->
                    def rs = ruoloSelezionato
                    onRefresh()

                    ruoloSelezionato = listaRuoli.find { it.ruolo == rs.ruolo }
                    listaPraticheRuolo = contribuentiService.praticheRuolo(soggetto.contribuente.codFiscale, ruoloSelezionato.ruolo)
                    praticaSelezionata = listaPraticheRuolo.find { it.id == praticaSelezionata.id }

                    BindUtils.postNotifyChange(null, null, this, "ruoloSelezionato")
                    BindUtils.postNotifyChange(null, null, this, "listaPraticheRuolo")
                    BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
                })
    }

    @Command
    def onEccedenzeRUolo() {
        commonService.creaPopup("/ufficiotributi/imposte/ruoliEccedenze.zul", self,
                [ruolo     : ruoloSelezionato.ruolo,
                 codFiscale: ruoloSelezionato.codFiscale])
    }

    //Versamenti bonifiche
    @Command
    def caricaVersamentiBonifiche() {

        def paging = [max       : Integer.MAX_VALUE,
                      offset    : 0,
                      activePage: 0]

        def tipiTributoSelezionati = getTipiTributoSelezionati()

        if (tipiTributoSelezionati.size() > 0) {

            listaDettaglioAnomalie = bonificaVersamentiService.getDettagliAnomalie("F24", [:], paging,
                    [codiceFiscale: codFiscale,
                     tipiTributo  : tipiTributoSelezionati], null)

            if (anyAnomaliaWithCausaleNull()) {
                def message = "Versamenti in Bonifiche senza Anomalia valorizzata"
                Messagebox.show(message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
            }

            numBonifiche = listaDettaglioAnomalie.record.size()

        } else {
            listaDettaglioAnomalie = null
            numBonifiche = 0
        }

        BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomalie")
        BindUtils.postNotifyChange(null, null, this, "numBonifiche")

    }

    private boolean anyAnomaliaWithCausaleNull() {
        listaDettaglioAnomalie.record.any { it.tipoAnomalia == null }
    }

    @Command
    def onDettagliAnomaliaSort() {
        // Non implementato nella situazione del contribuente
    }

    @Command
    def onCorreggiAnomalia(@BindingParam("anomaliaSelezionata") def anom) {

        String tipoTributoAnomalia = dettaglioAnomaliaSelezionato.tipoTributo
        Boolean scrittura = (tipoTributoAnomalia != null) ? cbTributiInScrittura[tipoTributoAnomalia] : null
        Boolean lettura = (scrittura != null) ? !scrittura : true

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/bonificaVersamento.zul",
                self,
                [id         : dettaglioAnomaliaSelezionato.id,
                 tipoIncasso: "F24",
                 lettura    : lettura])
        w.onClose { event -> onRefresh()
        }
        w.doModal()
    }

    @Command
    def onCambiaStatoAnomalia(@BindingParam("anomaliaSelezionata") def anom) {

        if ((anom.tipoTributo) && (cbTributiInScrittura[anom.tipoTributo] == true)) {
            bonificaVersamentiService.cambiaStato("F24", anom)
            BindUtils.postNotifyChange(null, null, anom, "flagOk")
        }
    }

    @Command
    def onDettaglioVersamentiToXls() {

        def tipiTributoSelezionati = getTipiTributoSelezionati()

        def datiExportVersamenti =
                bonificaVersamentiService.versamentiToXlsx([codiceFiscale: codFiscale,
                                                            tipiTributo  : tipiTributoSelezionati], [:],
                        null)

        def listaVersamenti = datiExportVersamenti.versamenti
        def campi = datiExportVersamenti.campi

        XlsxExporter.exportAndDownload('bonifica_versamenti_dettaglio_' + (new Date()).format('yyyyMMdd'),
                listaVersamenti, campi)
    }

    @Command
    def onEliminaVersamento(@BindingParam("anomaliaSelezionata") def anom) {

        String messaggio = "Eliminazione della registrazione?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.CANCEL | Messagebox.YES, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            bonificaVersamentiService.eliminaVersamento("F24", anom)
                            onRefresh()
                            Clients.showNotification("Versamento eliminato correttamente.", Clients.NOTIFICATION_TYPE_INFO,
                                    null, "middle_center", 3000, true)
                        }
                    }
                })
    }

    @Command
    def onDettaglioVersato(@BindingParam("anomaliaSelezionata") def anom) {

        // Solo per WRK
        def versamento = WrkVersamenti.findByProgressivo(new BigDecimal(anom.id))

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/versamentoDettaglioPopup.zul",
                self,
                [versamento: versamento])

        w.doModal()
    }

    @Command
    def onApriCaricaArchivi() {

        def tipiTributo = [:]
        def tt = null
        def readOnly = false

        //Ottengo la lista dei tipitributo selezionati
        def tributi = getTipiTributoSelezionati()

        //Se è selezionato solo un tipotributo, lo passo alla maschera
        if (tributi.size() == 1) {

            competenzeService.tipiTributoUtenza().each {
                tipiTributo << [(it.tipoTributo): it.tipoTributoAttuale + ' - ' + it.descrizione]
            }

            tt = tipiTributo.find {
                it.key == tributi.getAt(0)
            }
        }

        commonService.creaPopup("/ufficiotributi/bonificaDati/versamenti/bonificaVersamentiCaricaArchivi.zul",
                self,
                [tipoTributo: tt,
                 tipoIncasso: "F24",
                 readOnly   : readOnly,
                 codFiscale : codFiscale],
                { event -> onRefresh()
                })
    }

    //Compensazioni TARSU

    @Command
    def onRicercaCompensazioni() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniRicerca.zul", self, [filtri: filtriCompensazioni], { e ->
            if (e.data?.filtriAggiornati) {
                filtriCompensazioni = e.data.filtriAggiornati
                onRefresh()
            }
        })
    }

    @Command
    def onCalcoloCompensazioni() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.CALCOLO_COMPENSAZIONI,
                 codFiscale        : soggetto.contribuente.codFiscale,
                 modalitaCodFiscale: 'D',
                 modalitaAnno      : 'N'], { e ->

            if (!e.data) {
                return
            }

            if (!e.data?.messaggio?.trim()) {

                def numCompPrecedente = listaCompensazioni.size()
                caricaCompensazioni()

                if (listaCompensazioni.size != numCompPrecedente) {
                    Clients.showNotification("Calcolo compensazioni eseguito", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                } else {
                    Clients.showNotification("Nessuna compensazione generata", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                }
            } else {
                Clients.showNotification(e.data.messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            }

        })
    }

    @Command
    def onGeneraVersamenti() {
        commonService.creaPopup("/ufficiotributi/imposte/compensazioniFunzioni.zul", self,
                [tipoFunzione      : CompensazioniFunzioniViewModel.TipoFunzione.GENERA_VERSAMENTI,
                 codFiscale        : soggetto.contribuente.codFiscale,
                 anno              : compensazioneSelezionata.anno,
                 tipoTributo       : compensazioneSelezionata.desTitr,
                 modalitaCodFiscale: 'D',
                 modalitaAnno      : 'N'], { e ->

            if (!e.data) {
                return
            }

            if (!e.data?.messaggio?.trim()) {

                caricaVersamenti(true)
                aggiornaIndiciTab()
                caricaCompensazioni()

                if (e.data?.numVersamenti > 0) {
                    Clients.showNotification("Inserimento versamenti eseguito", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                } else {
                    Clients.showNotification("Nessun versamento generato", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                }
            } else {
                Clients.showNotification(e.data.messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            }
        })
    }

    @Command
    def onExportCompensazioniXls() {

        def fields
        def listaCompensazioniTotale = compensazioniService.getListaCompensazioni(filtriCompensazioni,
                [activePage: 0,
                 pageSize  : Integer.MAX_VALUE,
                 totalSize : 0]).records

        fields = ["desTitr"               : "Tipo Tributo",
                  "anno"                  : "Anno",
                  "desMotivoCompensazione": "Motivo",
                  "compensazione"         : "Compensazione",
                  "flagAutomatico"        : "Auto",
                  "flagVers"              : "Vers.",
                  "note"                  : "Note"]

        def converters = ["flagVers"      : Converters.flagString,
                          "flagAutomatico": Converters.flagString,
                          "anno"          : Converters.decimalToInteger,]

        def nomeFile = "compensazioni_" + soggetto.contribuente.codFiscale
        XlsxExporter.exportAndDownload(nomeFile, listaCompensazioniTotale, fields, converters)
    }

    @Command
    def onModificaCompensazione() {

        commonService.creaPopup("/ufficiotributi/imposte/dettaglioCompensazione.zul", self,
                [isModifica              : true,
                 isClonazione            : false,
                 codFiscale              : soggetto.contribuente.codFiscale,
                 compensazioneSelezionata: compensazioneSelezionata], { e -> onRefresh()
        })

    }

    @Command
    def onAggiungiCompensazione() {
        commonService.creaPopup("/ufficiotributi/imposte/dettaglioCompensazione.zul", self,
                [isModifica: false,
                 codFiscale: soggetto.contribuente.codFiscale], { e -> onRefresh()
        })
    }

    @Command
    def onDuplicaCompensazione() {

        commonService.creaPopup("/ufficiotributi/imposte/dettaglioCompensazione.zul", self,
                [isModifica              : true,
                 isClonazione            : true,
                 codFiscale              : soggetto.contribuente.codFiscale,
                 compensazioneSelezionata: compensazioneSelezionata], { e -> onRefresh()
        })
    }

    @Command
    def onEliminaCompensazione() {

        String msg = "Si è scelto di eliminare la compensazione:\n" + "La compensazione verrà eliminata e non sarà recuperabile.\n" + "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Compensazione", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName() == "onOK") {
                    def compensazione =
                            compensazioniService.getCompensazione(compensazioneSelezionata.idCompensazione)
                    def messaggio = compensazioniService.eliminaCompensazione(compensazione)
                    visualizzaRisultatoEliminazione(messaggio)
                    onRefresh()
                }
            }
        })
    }

    @Command
    def onContribuentiSuOggetto() {


        commonService.creaPopup("/sportello/contribuenti/contribuentiOggetto.zul", self,
                [oggetto: oggettoSelezionato.oggetto,
                 pratica: null,
                 anno   : "Tutti",],
                { event -> onRefresh()
                })

    }

    @Command
    def onContribuentiSuOggettoConcessioni() {

        commonService.creaPopup("/sportello/contribuenti/contribuentiOggetto.zul", self,
                [oggetto: concessioneSelezionata.oggettoRef,
                 pratica: null,
                 anno   : "Tutti"],
                { event -> onRefresh()
                })

    }

    @Command()
    def onPortale() {
        def url = commonService.costruisceUrlPortale(codFiscale)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onSostituzioneContribuente() {

        Long idOriginale = soggetto.id
        String cfOriginale = soggetto.contribuente.codFiscale

        def filtri = [contribuente     : "-",
                      cognomeNome      : "",
                      cognome          : "",
                      nome             : "",
                      indirizzo        : "",
                      codFiscale       : "",
                      id               : null,
                      codFiscaleEscluso: null,
                      idEscluso        : idOriginale]

        Window w = Executions.createComponents("/sportello/contribuenti/listaContribuentiRicerca.zul", self,
                [filtri         : filtri,
                 listaVisibile  : true,
                 ricercaSoggCont: true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Sogggetto") {
                    Long idDestinazione = event.data.idSoggetto
                    String cfDestinazione = event.data.cfSoggetto
                    sostituisciContribuenteCheck(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAggiornaContribuente() {

        commonService.creaPopup("/sportello/contribuenti/dettagliContribuente.zul",
                self,
                [soggetto: soggetto],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Salva") {
                            closeCurrentAndOpenContribuenteAndRefreshListaContribuente(soggetto.id)
                        }
                    }
                })
    }

    @Command
    def onSoggettiCatasto() {

        Long idSoggetto = soggetto.id

        commonService.creaPopup("/sportello/contribuenti/soggettiACatasto.zul", self, [idSoggetto: idSoggetto],
                { event ->
                    if (event?.data) {
                        if (event?.data?.isDirty) {
                            closeCurrentAndOpenContribuenteAndRefreshListaContribuente(soggetto.id)
                        }
                    }
                })
    }

    @Command
    def onAnnullaDovuto() {

        if (!dePagAbilitato) {
            return
        }

        def result = integrazioneDePagService.eliminaDovutoImposta(soggetto.contribuente.codFiscale, anno, "CUNI", null)

        if (result) {
            Clients.showNotification(result, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        } else {
            Clients.showNotification("Annulla dovuto eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }

        onRefresh()
    }

    @Command
    def onModificaSvuotamento() {

        commonService.creaPopup("/ufficiotributi/svuotamenti/dettaglioSvuotamento.zul", self,
                [isModifica            : true,
                 isClonazione          : false,
                 svuotamentoSelezionato: svuotamentoSelezionato], { e ->

            if (e.data?.salvato) {
                onRefresh()
            }
        })
    }

    @Command
    def onAggiungiSvuotamento() {
        commonService.creaPopup("/ufficiotributi/svuotamenti/dettaglioSvuotamento.zul", self,
                [isModifica : false,
                 codFiscale : soggetto.contribuente.codFiscale,
                 solaLettura: !cbTributiInScrittura['TARSU']], { e ->
            if (e.data?.salvato) {
                onRefresh()
            }
        })
    }

    @Command
    def onDuplicaSvuotamento() {

        def svuotamentoClone = svuotamentoSelezionato.getClass().newInstance(svuotamentoSelezionato)
        svuotamentoClone.sequenza = null

        commonService.creaPopup("/ufficiotributi/svuotamenti/dettaglioSvuotamento.zul", self,
                [isModifica            : true,
                 isClonazione          : true,
                 codFiscale            : soggetto.contribuente.codFiscale,
                 svuotamentoSelezionato: svuotamentoClone], { e -> onRefresh()
        })
    }

    @Command
    def onEliminaSvuotamento() {

        String msg = "Si è scelto di eliminare lo svuotamento:\n" + "Lo svuotamento verrà eliminato e non sarà recuperabile.\n" + "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione Svuotamento", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION) { event ->

            if (Messagebox.ON_OK == event.getName()) {
                svuotamentiService.eliminaSvuotamento(soggetto.contribuente.toDomain(),
                        svuotamentoSelezionato.oggetto,
                        svuotamentoSelezionato.codRfid,
                        svuotamentoSelezionato.sequenza)
                onRefresh()
            }
        }
    }


    @Command
    def onExportXlsSvuotamenti() {

        Map fields = ["oggetto"          : "Oggetto",
                      "tipoOggetto"      : "Tipo Oggetto",
                      "indirizzo"        : "Indirizzo",
                      "sezione"          : "Sezione",
                      "foglio"           : "Foglio",
                      "numero"           : "Numero",
                      "subalterno"       : "Subalterno",
                      "categoriaCatasto" : "Categoria Catasto",
                      "classeCatasto"    : "Classe Catasto",
                      "tributo"          : "Codice Tributo",
                      "categoria"        : "Categoria",
                      "tipoTariffa"      : "Tipo Tariffa",
                      "consistenza"      : "Consistenza",
                      "flagPuntoRaccolta": "Punto di raccolta",
                      "flagAbPrincipale" : "Flag AbPrincipale",
                      "numeroFamiliari"  : "NumeroFamiliari",
                      "dataDecorrenza"   : "Decorrenza",
                      "dataCessazione"   : "Cessazione",
                      "codRfid"          : "Codice Rfid",
                      "dataSvuotamento"  : "Data svuotamento",
                      "quantitaStr"      : "Quantità",
                      'documentoId'      : 'Doc.Id',
                      "note"             : "Note"]

        def formatters = ["oggetto"        : Converters.decimalToInteger,
                          "anno"           : Converters.decimalToInteger,
                          "consistenza"    : Converters.decimalToInteger,
                          "percPossesso"   : Converters.decimalToInteger,
                          "categoria"      : Converters.decimalToInteger,
                          "tipoTariffa"    : Converters.decimalToInteger,
                          "tipoOggetto"    : Converters.decimalToInteger,
                          "tributo"        : Converters.decimalToInteger,
                          "quantita"       : Converters.decimalToInteger,
                          "numeroFamiliari": Converters.decimalToInteger,
                          "documentoId"    : Converters.decimalToInteger]

        def dateFormmatters = ["dataSvuotamento": "dd/MM/yyyy HH:mm:ss"]

        String nomeFile = "Svuotamenti_${soggetto.contribuente.codFiscale}"

        XlsxExporter.exportAndDownload(nomeFile, listaSvuotamenti, fields, formatters, [:], dateFormmatters)
    }

    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    private def caricaCompensazioni() {

        filtriCompensazioni.codFiscale = soggetto.contribuente.codFiscale

        def result = compensazioniService.getListaCompensazioni(filtriCompensazioni,
                [activePage: 0,
                 pageSize  : Integer.MAX_VALUE,
                 totalSize : 0])

        listaCompensazioni = result.records

        compensazioneSelezionata = null

        listaMotiviCompensazioni = compensazioniService.getMotivi()

        controllaFiltroCompensazioniAttivo()

        BindUtils.postNotifyChange(null, null, this, "compensazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaCompensazioni")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviCompensazioni")

    }

    private def caricaSvuotamenti() {
        listaSvuotamenti = contribuentiService.getListaSvuotamenti(listaOggetti, codFiscale, anno, filtroSvuotamenti)

        totaliSvuotamenti.quantitaTotale = listaSvuotamenti.sum { it.quantita ?: 0 } ?: 0
        totaliSvuotamenti.unitaDiMisura = listaSvuotamenti.find { (it.quantita ?: 0) > 0 }?.unitaDiMisura ?: ''

        BindUtils.postNotifyChange(null, null, this, "totaliSvuotamenti")
        BindUtils.postNotifyChange(null, null, this, "listaSvuotamenti")
    }

    private def initFiltriCompensazioni() {

        listaMotiviCompensazioni = compensazioniService.getMotivi()

        filtriCompensazioni = [tipoTributo    : "TARSU",
                               annoDa         : null,
                               annoA          : null,
                               compensazioneDa: null,
                               compensazioneA : null,
                               motivoDa       : listaMotiviCompensazioni[0],
                               motivoA        : listaMotiviCompensazioni.reverse()[0]]
    }

    private def controllaFiltroCompensazioniAttivo() {

        filtroCompensazioniAttivo = (filtriCompensazioni.tipoTributo != "TARSU") || (filtriCompensazioni.annoDa != null) || (filtriCompensazioni.annoA != null) || (filtriCompensazioni.compensazioneDa != null) || (filtriCompensazioni.compensazioneA != null) || (filtriCompensazioni.motivoDa.motivoCompensazione != listaMotiviCompensazioni[0].motivoCompensazione) || (filtriCompensazioni.motivoA.motivoCompensazione != listaMotiviCompensazioni.reverse()[0].motivoCompensazione)

        BindUtils.postNotifyChange(null, null, this, "filtroCompensazioniAttivo")
    }

    private def aggiornaNumeroCompensazioni() {

        initFiltriCompensazioni()

        filtriCompensazioni.codFiscale = soggetto.contribuente.codFiscale

        numCompensazioni = compensazioniService.getCountCompensazioni(filtriCompensazioni)

    }

    def getContaTributiSelezionati() {
        cbTributi.values().findAll { it }.size()
    }

    def getSingleTributoSelezionato() {
        List tributiSelected = cbTributi.findAll { it.value }.collect { it.key }
        if (tributiSelected.size() != 1) {
            throw new IllegalStateException("Impossibile restituire l'unico tipo tributo selezionato se non è selezionato solo un tipo tributo")
        }
        return tributiSelected.first()
    }

    private aggiornaIndiceOggetti() {
        numOggetti = listaOggetti?.size ?: 0
        numSvuotamenti = listaSvuotamenti?.size ?: 0

        BindUtils.postNotifyChange(null, null, this, "numOggetti")
        BindUtils.postNotifyChange(null, null, this, "numSvuotamenti")
    }

    private void cuAggiornaFiltriConcessioniAttivo() {

        filtriConcessioniAttivo = filtriConcessioni.isDirty()
        BindUtils.postNotifyChange(null, null, this, "filtriConcessioniAttivo")
    }

    private cuCaricaListaConcessioni() {

        listaConcessioni = []

        if (cbTributi.CUNI) {
            def parametriRicerca = [codFiscale     : soggetto.contribuente.codFiscale,
                                    anno           : anno.toString(),
                                    tipiTributo    : cbTributi.clone(),
                                    tipiPratiche   : cbTipiPratica.clone(),
                                    filtriAggiunti : filtriConcessioni,
                                    perDateValidita: true]

            listaConcessioni = canoneUnicoService.getConcessioniContribuente(parametriRicerca).sort { can1, can2 -> (can1.indirizzoOgg <=> can2.indirizzoOgg) ?: (can1.oggetto.daKM <=> can2.oggetto.daKM) ?: (can1.dettagli.numeroConcessione <=> can2.dettagli.numeroConcessione) ?: (can1.dettagli.dataConcessione <=> can2.dettagli.dataConcessione)
            }

        }
        BindUtils.postNotifyChange(null, null, this, "listaConcessioni")
    }

    private cnConvertiConcessioni() {

        def stats = [:]

        def report = canoneUnicoService.convertiConcessioniContribuente(listaConcessioni, stats)

        def icon = null

        switch (report.result) {
            default:
                icon = Messagebox.QUESTION
                break
            case 0:
                icon = Messagebox.INFORMATION
                break
            case 1:
                icon = Messagebox.EXCLAMATION
                break
            case 2:
                icon = Messagebox.ERROR
                break
        }
        Messagebox.show(report.message, "Report Conversione", Messagebox.OK, icon)

        onRefresh()
    }

    private def cnChiudiConcessioni(def datiChiusura) {

        String successMessage = "Canoni chiusi con successo"

        Date dataChiusura = datiChiusura.dataChiusura
        Date fineOccupazione = datiChiusura.dataFineOccupazione

        def elencoCanoniDaChiudere = datiChiusura.canoniDaChiudere
        def canoniDaChiudere = listaConcessioni.findAll { it.oggettoPraticaRef in elencoCanoniDaChiudere }

        def report = canoneUnicoService.chiudiConcessioni(canoniDaChiudere, dataChiusura, fineOccupazione)

        if (report.result == 0) {

            if (datiChiusura.soggDestinazione) {

                def dettagliSubentro = [soggSubentro         : datiChiusura.soggDestinazione,
                                        dataInizioOccupazione: datiChiusura.dataInizioOccupazione,
                                        dataDecorrenza       : datiChiusura.dataDecorrenza,
                                        praticaRef           : 0,]

                report = canoneUnicoService.subentroConcessioni(canoniDaChiudere, dettagliSubentro)

                successMessage = "Trasferimento canoni avvenuto con successo"
            }
        }

        visualizzaReport(report, successMessage)

        listaPratiche = null
        BindUtils.postNotifyChange(null, null, this, "listaPratiche")

        onRefresh()
    }

    private def cuCalcolaConcessioneSingola(def tipoTributoBase, def anno, def praticaBase) {

        String tipoTributoNow

        if (anno >= 2021) {
            tipoTributoNow = 'CUNI'
        } else {
            tipoTributoNow = tipoTributoBase
        }

        TipoTributoDTO tipoTributo = TipoTributo.findByTipoTributo(tipoTributoNow).toDTO()
        String codFiscale = soggetto.contribuente.codFiscale
        String cognomeNome = soggetto.cognomeNome

        Window w = Executions.createComponents("/ufficiotributi/imposte/calcoloImposta.zul", self,
                [anno: anno, tipoTributo: tipoTributo, cognomeNome: cognomeNome, codFiscale: codFiscale, pratica: praticaBase])
        w.onClose { event ->
            if (event?.data?.calcoloEseguito) {
                listaImposte = contribuentiService.imposteContribuente(soggetto.contribuente.codFiscale)
                calcolaVisualizzaDovuto()
                BindUtils.postNotifyChange(null, null, this, "listaImposte")
                onRefresh()
            }
        }
        w.doModal()
    }

    private cuAnnullaDepagConcessioni(def concessioni, Short annoRiferimento) {

        def report = canoneUnicoService.annullaDepagConcessioni(concessioni, annoRiferimento)

        visualizzaReport(report, "Dovuto Depag annullato con successo")
    }

    private cuStampaConcessioni(String tipoTributoBase, Short anno, def praticaBase) {

        String tipoTributoNow

        if (anno >= 2021) {
            tipoTributoNow = 'CUNI'
        } else {
            tipoTributoNow = tipoTributoBase
        }

        Long ruolo = -1
        Long ruoloAgid = 0
        Long elaborazione = 1

        String codFiscale = soggetto.contribuente.codFiscale

        def nomeFile = FileNameGenerator.generateFileName(FileNameGenerator.GENERATORS_TYPE.MODELLI,
                FileNameGenerator.GENERATORS_TITLES.COM,
                [tipoTributo   : tipoTributoNow,
                 anno          : anno,
                 idElaborazione: elaborazione,
                 codFiscale    : codFiscale])

        def parametri = [

                tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                idDocumento: [tipoTributo: tipoTributoNow,
                              ruolo      : ruoloAgid,
                              anno       : anno,
                              codFiscale : codFiscale,
                              pratica    : praticaBase],
                nomeFile   : nomeFile,]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    private cuAggiornaIndiciTab() {

        numConcessioni = 0

        if (cbTributi.CUNI) {

            def parametriRicerca = [codFiscale     : soggetto.contribuente.codFiscale,
                                    anno           : anno.toString(),
                                    tipiTributo    : cbTributi.clone(),
                                    tipiPratiche   : cbTipiPratica.clone(),
                                    perDateValidita: true]
            numConcessioni = canoneUnicoService.getConcessioniContribuente(parametriRicerca, true)
        }

        BindUtils.postNotifyChange(null, null, this, "numConcessioni")
    }

    private visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                break
        }
    }

    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
            if (competenzeService.utenteAbilitatoScrittura(it.tipoTributo)) {
                cbTributiInScrittura << [(it.tipoTributo): true]
            }
        }

        cbTributi.each { k, v ->
            if (competenzeService.tipiTributoUtenza().find { it.tipoTributo == k } == null) {
                cbTributi[k] = false
            }
        }

        abilitaRavvOperoso = cbTributiInScrittura.ICI || cbTributiInScrittura.TASI || cbTributiInScrittura.CUNI
        abilitaCalcIndividuale = cbTributiInScrittura.ICI || cbTributiInScrittura.TASI
    }

    @Override
    void closeAndOpenContribuente(def idSoggetto) {
        if (standalone) {
            Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${idSoggetto}','_self');")
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [aggiornaSituazioneContribuente: true, idSoggetto: idSoggetto])
        }
    }

    @GlobalCommand("closeCurrentAndRefreshListaContribuente")
    void closeCurrentAndRefreshListaContribuente() {
        if (!standalone) {
            Events.postEvent(Events.ON_CLOSE, self, [aggiornaListaContribuenti: true])
        }
    }

    private void closeCurrentAndOpenContribuenteAndRefreshListaContribuente(def idSoggetto) {
        if (standalone) {
            Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${idSoggetto}','_self');")
        } else {
            Events.postEvent(Events.ON_CLOSE, self, [aggiornaSituazioneContribuente: true, idSoggetto: idSoggetto, aggiornaListaContribuenti: true])
        }
    }

    List<String> getTipiTributoSelezionati() {
        return cbTributi.findAll { it.value == true }
                .collect { it.key }
    }

    def documentiContribuenteSmartPND(String codFiscale) {

        def tipiCanale = TipiCanale.findAll()

        def lista = contribuentiService.documentiContribuente(codFiscale, "list")
        if (smartPndService.smartPNDAbilitato()) {
            listaComunicazioniPND = [:]

            lista.each {

                if (it.idComunicazionePnd != null) {

                    def comunicazione = null
                    if (it.idComunicazionePnd != null) {
                        try {
                            comunicazione = it.idComunicazionePnd ? smartPndService.getComunicazione(it.idComunicazionePnd) : null
                        } catch (Exception e) {
                            log.error("Errore nel recupero della comunicazione ${it.idComunicazionePnd}", e)
                        }
                    }

                    listaComunicazioniPND << [(it.idComunicazionePnd): [smartPndComunicazione: comunicazione,
                                                                        tipoCanaleDescr      : it.tipoCanale != null ? tipiCanale.find { tc -> tc.id == (it.tipoCanale as Long) }?.descrizione : null]]
                }

            }
        }

        BindUtils.postNotifyChange(null, null, this, "listaComunicazioniPND")

        return lista
    }

    private void calcolaDisabilitaDataNotificaSuRateazione() {
        // Se la pratica ha una data di notifica e il tipo atto corrisponde a "Rateazione" o se la pratica
        // e` stata rateizzata, disabilita la modifica della data di notifica
        listaPratiche.each { pratica -> disabilitaDataNotificaSuRateazione[pratica.id] = pratica.dataNotifica && (pratica.tipoAtto?.tipoAtto == 90 || rateazioneService.praticaRateizzata((pratica.id ?: 0) as Long))
        }
        BindUtils.postNotifyChange(null, null, this, "disabilitaDataNotificaSuRateazione")
    }

    private void notificaPresenzaDenunceDaPortale() {
        def msg = ""
        // TODO: per ora si gestisce solo ICI, in seguito si dovrà abilitare per CUNI e TARI
        competenzeService.tipiTributoUtenza().find {
            cbTributi[it.tipoTributo] && it.tipoTributo in ['ICI']
        }.each {
            def msgTributo = integrazionePortaleService.praticheDaImportare(it.tipoTributo, codFiscale)
            if (msgTributo?.trim()) {
                msg += "$msgTributo\n"
            }
        }

        if (msg?.trim()) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_WARNING, null, "top_center", 10000, true)
        }
    }
}
