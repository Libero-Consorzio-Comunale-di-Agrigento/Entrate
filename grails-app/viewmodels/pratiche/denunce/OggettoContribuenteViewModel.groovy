package pratiche.denunce

import it.finmatica.tr4.*
import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.contribuenti.CalcoloService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.datiesterni.ImportDatiEsterniService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.AttributoOgcoDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.StoOggettoContribuente
import org.hibernate.criterion.CriteriaSpecification
import org.w3c.dom.Document
import org.xml.sax.InputSource
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.Binder
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.util.media.AMedia
import org.zkoss.zhtml.Filedownload
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.ext.Disable
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import javax.xml.parsers.DocumentBuilder
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.Transformer
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource
import java.text.DecimalFormat
import java.text.SimpleDateFormat

class OggettoContribuenteViewModel {

    @Wire("#oggettoContribuenteWindow > disable")
    List<Disable> allToDisable

    // services
    def springSecurityService
    def grailsApplication
    OggettiService oggettiService
    ImportDatiEsterniService importDatiEsterniService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    DenunceService denunceService
    AliquoteService aliquoteService
    CommonService commonService
    CalcoloService calcoloService
    GestioneAnomalieService gestioneAnomalieService

    // componenti
    Window self

    // dati
    def oggettoContribuente
    def oggettoContribuenteRif = [:]
    def oggettoImposte = [:]

    List listaTipiOggetto
    List listaTipiQualita
    List listaCategorieCatasto
    List listaFonti
    List listaAnniDetrazione
    List listaMotiviDetrazione
    List listaTipiAliquota
    List<AliquotaOgcoDTO> listaAliquote
    String tipoRapporto
    String statoChiusura = ""
    BigDecimal rendita
    def pratica

    // Tipi aliquota valide per l'anno della pratica - Per valore aliquota
    List<TipoAliquota> listaTipiAliquotaAnno

    // Tipi aliquota valide per l'anno della pratica - Per Combo
    def elencoTipiAliquota = []

    String tipoTributoAttuale
    String tipoTributo
    boolean isPertinenza = false
    boolean isPertinenzaRif = false
    boolean modifica
    boolean modificaFlagsPera
    boolean lettura
    boolean creazione = false
    boolean daBonifiche
    boolean aggiornaStato = false
    boolean aggiungiDetrazioniAliquote = false
    boolean isStorica = false
    TipoOggettoDTO tipoOggettoOld
    def salvato = false
    def idOggettoPratica
    def preVal
    int activeItem = 0
    int listSize = 1
    List<OggettoContribuenteDTO> listaId
    //Contitolari
    boolean isCreaOggettoContitolare = false
    AliquotaOgcoDTO aliqOgcoDaInserire
    Popup popupNote
    boolean disabilitaFlags = false
    boolean disabilitaFlagsPera = false
    boolean disabilitaFlagAlRidotta = false
    boolean daAccManImu

    EventListener<Event> isDirtyEvent = null
    boolean isDirty = false

    String lastUpdated
    def utente

    def parametriBandbox = [anno            : null
                            , codFiscale    : ""
                            , oggettoPratica: null
                            , oggettoId     : null
                            , nomeMetodo    : "pertinenzeBandBox"
                            , tipoTributo   : ""]

    List listaFetchOggettiPratica = [
            "oggettoPratica",
            "oggettoPratica.oggetto",
            "oggettoPratica.oggetto.archivioVie"
    ]

    List listaFetchSoggetto = [
            "comuneResidenza"
            ,
            "comuneResidenza.ad4Comune"
            ,
            "comuneResidenza.ad4Comune.provincia"
            ,
            "archivioVie"
    ]

    Map filtri = [contribuente: [codFiscale: ""]]

    def elencoTipiPratica = [
            [codice: TipoPratica.D.tipoPratica, descrizione: TipoPratica.D.descrizione, titoloOggPr: 'Dichiarato', titoloOggPrRif: 'Riferimento'],
            [codice: TipoPratica.A.tipoPratica, descrizione: TipoPratica.A.descrizione, titoloOggPr: 'Accertato', titoloOggPrRif: '__OrigineDato__'],
            [codice: TipoPratica.V.tipoPratica, descrizione: TipoPratica.V.descrizione, titoloOggPr: 'Accertato', titoloOggPrRif: '__OrigineDato__'],
    ]
    String titoloForm
    String titoloOggPr
    String titoloOggPrRif

    @NotifyChange([
            "modifica",
            "isPertinenza",
            "oggettoContribuente",
            "listaTipiOggetto",
            "listaCategorieCatasto",
            "listaAnniDetrazione",
            "listaMotiviDetrazione",
            "listaAliquote",
            "rendita"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ContextParam(ContextType.BINDER) Binder binder
         , @ExecutionArgParam("idOggPr") long idOggPr
         , @ExecutionArgParam("contribuente") String codFiscale
         , @ExecutionArgParam("tipoRapporto") String tr
         , @ExecutionArgParam("tipoTributo") String tt
         , @ExecutionArgParam("idOggetto") long idOggetto
         , @ExecutionArgParam("pratica") def pratica
         , @ExecutionArgParam("oggCo") OggettoContribuenteDTO oggettoAnniPrec
         , @ExecutionArgParam("listaId") List<OggettoContribuenteDTO> listaId
         , @ExecutionArgParam("indexSelezione") int activeItem
         , @ExecutionArgParam("modifica") boolean modifica
         , @ExecutionArgParam("storica") def storica
         , @ExecutionArgParam("daBonifiche") boolean daBonifiche
         , @ExecutionArgParam("preVal") Map preVal
         , @ExecutionArgParam("isCreaContitolare") @Default("false") boolean isCreaContitolare
         , @ExecutionArgParam("modificaFlagsPera") Boolean modificaFlagsPera) {

        this.self = w
        this.preVal = preVal

        if (storica != null) {
            this.isStorica = storica
        }

        if (daBonifiche) {
            this.daBonifiche = daBonifiche
        }

        this.lettura = !modifica

        // Se si imposta modificabile dall'esterno
        if (modifica) {
            // Se sull'oggetto è presente un accertamento/liquidazione non si deve consentire la modifica
            this.modifica = oggettiService.oggettoModificabile(tt, idOggPr, codFiscale)
            // Ne caso ci sia un accertamento
            if (!this.modifica) {
                Clients.showNotification("Esiste un Accertamento in Atto - Non è possibile modificare.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            }
        } else {
            this.modifica = modifica
        }

        this.modificaFlagsPera = (modificaFlagsPera != null) ? modificaFlagsPera : this.modifica

        if (tt) {
            tipoTributo = tt
        }
        this.pratica = pratica

        tipoRapporto = tr
        isCreaOggettoContitolare = isCreaContitolare
        idOggettoPratica = idOggPr

        this.listaId = listaId

        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale == true }

        creazione = idOggetto != -1

        //se idOggetto > 0 significa che voglio associare l'oggetto ad
        //un nuovo ogco. Se idOggetto < 0 significa che andro' in modifica
        //di un ogco esistente
        if (idOggetto > 0 && !oggettoAnniPrec) {
            // devo creare un un nuovo oggetto contribuente
            // se recupero un oggetto inserito in una vecchia pratica recupero i vecchi valori
            OggettoDTO oggetto = Oggetto.get(idOggetto).toDTO([
                    "tipoOggetto",
                    "categoriaCatasto",
                    "archivioVie",
                    "fonte",
                    "riferimentiOggetto"
            ])
            OggettoPraticaDTO oggettoPratica = new OggettoPraticaDTO()
            // imposto alcuni dati
            oggettoPratica.categoriaCatasto = oggetto.categoriaCatasto
            oggettoPratica.classeCatasto = oggetto.classeCatasto
            oggettoPratica.tipoOggetto = oggetto.tipoOggetto
            oggettoPratica.fonte = oggetto.fonte
            oggettoPratica.anno = pratica.anno

            oggetto.addToOggettiPratica(oggettoPratica)
            oggettoContribuente = new OggettoContribuenteDTO()
            // lo associo alla pratica e all'oggettopratica
            oggettoContribuente.contribuente = Contribuente.findByCodFiscale(codFiscale).toDTO(["soggetto"])

            oggettoContribuente.anno = pratica.anno

            oggettoPratica.addToOggettiContribuente(oggettoContribuente)
            this.pratica.addToOggettiPratica(oggettoPratica)

            //Calcolo della rendita e valore dai riferimenti oggetto selezionato
            rendita = oggettiService.getRenditaDaRiferimentiOggetto(idOggetto, oggettoContribuente.anno)

            def classificazione = oggettiService.getClassificazioneDaRiferimentiOggetto(idOggetto, oggettoContribuente.anno)
            def categoria = classificazione.categoria ?: oggetto.categoriaCatasto?.categoriaCatasto
            oggettoContribuente.oggettoPratica.categoriaCatasto = listaCategorieCatasto.find { it.categoriaCatasto == categoria }
            oggettoContribuente.oggettoPratica.classeCatasto = classificazione.classe ?: oggetto.classeCatasto
            ricalcolaValoreOgPr()

            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "oggettoContribuente")
            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "rendita")

        } else if (idOggetto > 0 && oggettoAnniPrec) {
            rendita = oggettiService.getRenditaOggettoPratica(oggettoAnniPrec.oggettoPratica.valore
                    , oggettoAnniPrec.oggettoPratica.tipoOggetto.tipoOggetto
                    , oggettoAnniPrec.oggettoPratica.anno
                    , oggettoAnniPrec.oggettoPratica.categoriaCatasto ?: oggettoAnniPrec.oggettoPratica.oggetto.categoriaCatasto)

            oggettoContribuente = oggettoAnniPrec

            parametriBandbox.anno = pratica.anno
            parametriBandbox.codFiscale = oggettoContribuente?.contribuente?.codFiscale
            parametriBandbox.oggettoId = oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp ? String.valueOf(OggettoPratica.get(oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp?.id)?.oggetto?.id) : ""
            parametriBandbox.tipoTributo = oggettoContribuente?.oggettoPratica?.pratica?.tipoTributo?.tipoTributo
            parametriBandbox.oggettoPraticaRifAp = oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp?.id

            ricalcolaValoreOgPr()
            oggettoAnniPrec.anno = pratica.anno
            onVariatoMP()

            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "rendita")
        } else {
            this.activeItem = activeItem
            //E' stato spostato sopra per il controllo dell'esistenza già del numero ordine
            //this.listaId = listaId
            this.listSize = (isCreaOggettoContitolare) ? 0 : ((listaId) ? listaId.size() : 0)
            if (idOggPr) {
                (isCreaOggettoContitolare) ? caricaContitolare(idOggPr) : caricaImmobile(codFiscale, tr, idOggPr)
            }
        }

        tipoTributoAttuale = oggettoContribuente?.oggettoPratica?.pratica?.tipoTributo?.getTipoTributoAttuale(oggettoContribuente?.oggettoPratica?.anno)

        if (!isStorica) {
            caricaDatiOggettoRif(false)
        }

        listaTipiOggetto = OggettiCache.OGGETTI_TRIBUTO.valore.findAll { it.tipoTributo.tipoTributo == tt }?.tipoOggetto
        listaTipiQualita = TipoQualita.list().toDTO()
        listaFonti = Fonte.list().toDTO()
        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale == true }
        listaAnniDetrazione = Detrazione.createCriteria().list {
            projections { property("anno") }
            eq("tipoTributo.tipoTributo", tt)
            order("anno", "asc")
        }
        listaMotiviDetrazione = MotivoDetrazione.findAllByTipoTributo(TipoTributo.get(tt)).toDTO()
        listaTipiAliquota = TipoAliquota.findAllByTipoTributo(TipoTributo.get(tt)).toDTO()
        parametriBandbox.anno = this.pratica.anno
        parametriBandbox.tipoTributo = tt
        parametriBandbox.codFiscale = codFiscale
        tipoOggettoOld = oggettoContribuente?.oggettoPratica?.tipoOggetto

        listaAliquote = oggettoContribuente?.aliquoteOgco?.sort { it.dal }

        listaTipiAliquotaAnno = OggettiCache.TIPI_ALIQUOTA.valore.findAll {
            it.tipoTributo.tipoTributo == pratica.tipoTributo.tipoTributo && pratica.anno in it.aliquote.anno
        }
        elencoTipiAliquota = []
        elencoTipiAliquota << [codice: null, descrizione: '']
        listaTipiAliquotaAnno.each {
            def aliquota = [
                    codice     : it.tipoAliquota,
                    descrizione: it.descrizione
            ]
            elencoTipiAliquota << aliquota
        }

        //Controllo se abilitare Pertinenza di...
        abilitaPertinenza()

        //Controllo se è possibile attivare il funzionamneto di inserimento per Detrazioni e Aliquote
        abilitaInsDetrazioneAliquote()

        //Effettua il calcolo del numero di ordine se sono in creazione di un oggetto contribuente
        if (!isCreaContitolare && idOggetto > 0)
            calcoloNumeroOrdine()

        //Controllo dei flags
        checkAbilitaFlag()

        aggiornaDataModifica()
        aggiornaUtente()

        isDirtyEvent = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {

                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    isDirty = isDirty || !(pe.property in [
                            'oggettoContribuente',
                            'oggettoContribuenteRif',
                            'aggiungiDetrazioniAliquote',
                            'filtri',
                            'modifica',
                            'activeItem',
                            'isPertinenza',
                            'isPertinenzaRif',
                            'rendita',
                            'praticaSelezionata',
                            'aliqOgcoDaInserire',
                            'parametriBandbox',
                            'listaTipiQualita',
                            'tipoQualita',
                            'qualita',
                            'isCreaOggettoContitolare',
                            'listaAliquote',
                            'listSize',
                            'oggettoImposte',
                            'disabilitaFlagsPera',
                            'disabilitaFlagAlRidotta',
                            'lastUpdated',
                            'utente',
                            'titoloForm',
                            'titoloOggPr',
                            'titoloOggPrRif',
                            'isDirty'
                    ])
                }
            }
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(isDirtyEvent)
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(oggettoContribuente?.contribuente?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    //Viene calcolato il numero ordine sia nel caso di un OggettoPratica con la seguente logica:
    //se il campo max(num_ordine) da oggetti_pratica per le righe relative alla denuncia contiene il valore "/",
    // si verifica se la parte successiva alla "/" è numerica: se sì, si incrementa di 1 il valore presente dopo la "/", lasciando invariata la parte iniziale
    // se è numerico, si propone il valore max(num_ordine) da oggetti_pratica incrementato di 1
    // se non si verifica alcuna delle condizioni precedenti, non si propone niente.
    private calcoloNumeroOrdine() {
        def numero = denunceService.calcolaNumeroOrdine(pratica.id)
        oggettoContribuente?.oggettoPratica?.numOrdine = numero
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
    }

    private caricaContitolare(long oggettoPratica) {
        oggettoContribuente = new OggettoContribuenteDTO()
        OggettoPraticaDTO oggpr = OggettoPratica.createCriteria().get {
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
            createAlias("categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            eq("id", oggettoPratica)
        }?.toDTO()

        oggettoContribuente.contribuente = new ContribuenteDTO()
        oggettoContribuente.tipoRapporto = "C"
        oggettoContribuente.anno = pratica.anno
        oggettoContribuente.oggettoPratica = oggpr
    }

    @NotifyChange(["rendita"])
    private caricaImmobile(String codFiscale, String tr, long idOggPr) {
        //il criteria su ogpr non basta a filtrare definitivamente l'ogco che mi interessa
        //(nonostante la join)
        //quindi dopo in base al tipo rapporto prendo l'ogco che mi interessa.
        if (isStorica) {

            // Ogco ultima versione da cui recuperare le strutture da associare alla STO
            def ogco = OggettoContribuente.createCriteria().get {
                createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
                //createAlias("ogpr.tipoOggetto", "tiog", CriteriaSpecification.LEFT_JOIN)
                createAlias("aliquoteOgco", "alog", CriteriaSpecification.LEFT_JOIN)
                createAlias("detrazioniOgco", "deog", CriteriaSpecification.LEFT_JOIN)
                createAlias("deog.motivoDetrazione", "mode", CriteriaSpecification.LEFT_JOIN)
                createAlias("attributiOgco", "atog", CriteriaSpecification.LEFT_JOIN)
                createAlias("atog.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)

                eq("contribuente.codFiscale", codFiscale)
                eq("tipoRapporto", tr)
                eq("ogpr.id", idOggPr)

            }?.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])

            oggettoContribuente = StoOggettoContribuente.createCriteria().get {
                createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
                // createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)

                eq("contribuente.codFiscale", codFiscale)
                eq("tipoRapporto", tr)
                eq("ogpr.id", idOggPr)

            }.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])

            oggettoContribuente.oggettoPratica.oggetto.riferimentiOggetto = ogco?.oggettoPratica?.oggetto?.riferimentiOggetto
            oggettoContribuente.detrazioniOgco = ogco?.detrazioniOgco
            oggettoContribuente.aliquoteOgco = ogco?.aliquoteOgco
            oggettoContribuente.attributoOgco = ogco?.attributoOgco

            rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                    , oggettoContribuente.oggettoPratica.tipoOggetto?.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)

        } else {
            oggettoContribuente = OggettoContribuente.createCriteria().get {
                createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
                createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
                //createAlias("ogpr.tipoOggetto", "tiog", CriteriaSpecification.LEFT_JOIN)
                createAlias("aliquoteOgco", "alog", CriteriaSpecification.LEFT_JOIN)
                createAlias("detrazioniOgco", "deog", CriteriaSpecification.LEFT_JOIN)
                createAlias("deog.motivoDetrazione", "mode", CriteriaSpecification.LEFT_JOIN)
                createAlias("attributiOgco", "atog", CriteriaSpecification.LEFT_JOIN)
                createAlias("atog.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)

                eq("contribuente.codFiscale", codFiscale)
                eq("tipoRapporto", tr)
                eq("ogpr.id", idOggPr)

            }?.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])

            rendita = oggettoContribuente?.oggettoPratica?.oggettoPraticaRendita?.rendita
            listaAliquote = oggettoContribuente?.aliquoteOgco?.sort { it.dal }
        }

        parametriBandbox.anno = pratica.anno
        parametriBandbox.codFiscale = oggettoContribuente?.contribuente?.codFiscale
        parametriBandbox.oggettoId = oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp ? String.valueOf(OggettoPratica.get(oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp?.id)?.oggetto?.id) : ""
        parametriBandbox.tipoTributo = oggettoContribuente?.oggettoPratica?.pratica?.tipoTributo?.tipoTributo
        parametriBandbox.oggettoPraticaRifAp = oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp?.id

        //Controllo se abilitare Pertinenza di...
        abilitaPertinenza()

        if (preVal) {
            oggettoContribuente.percPossesso = preVal.percPossesso ?: oggettoContribuente.percPossesso
            oggettoContribuente.mesiPossesso = preVal.mesiPossesso ?: oggettoContribuente.mesiPossesso

            oggettoContribuente.mesiEsclusione = oggettoContribuente.mesiEsclusione != null ? preVal.mesiPossesso : oggettoContribuente.mesiEsclusione
            oggettoContribuente.mesiRiduzione = oggettoContribuente.mesiRiduzione != null ? preVal.mesiPossesso : oggettoContribuente.mesiRiduzione

            impostaMesiPoss1Sem(true)
            onVariatoMP()
        }

        aggiornaDataModifica()
        aggiornaUtente()

        if (!isStorica) {
            caricaDatiOggettoRif(true)
        }

        BindUtils.postNotifyChange(null, null, this, "parametriBandbox")
        BindUtils.postNotifyChange(null, null, this, "rendita")
    }

    @Command
    onChiudiPopup() {

        // Se siamo in sola lettura o se è in visualizzazione la storica si esce direttamente
        if (!modifica) {
            chiudi()
            return
        }

        if (isDirty) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onSalvaOggetto(false)
                                if (salvato)
                                    chiudi()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                chiudi()
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            chiudi()
        }
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()

        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
    }

    void chiudi() {

        if (isDirtyEvent) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(isDirtyEvent)
            isDirtyEvent = null
        }

        Events.postEvent(Events.ON_CLOSE, self, [status       : statoChiusura,
                                                 oggCo        : oggettoContribuente,
                                                 aggiornaStato: aggiornaStato,
                                                 salvato      : salvato])
    }

    private boolean controlloNumeroOrdine() {
        boolean esiste = false
        listaId.each {
            if (it.oggettoPratica.numOrdine.equals(oggettoContribuente.oggettoPratica.numOrdine)) {
                esiste = true
            }
        }
        return esiste
    }

    @Command
    def onEliminaOgCo() {

        String anomalie = ""

        for (def anom : gestioneAnomalieService.anomalieAssociateAdOgCo(oggettoContribuente.toDomain())) {
            anomalie += (anom.idTipoAnomalia + " " + anom.descrizione + " " + anom.tipoTributo + " " + anom.anno + (anom.flagImposta == 'S' ? ' Imposta' : '')) + "\n"
        }

        Messagebox.show("Eliminare il quadro?\n\nL'operazione non potrà essere annullata." +
                (anomalie.isEmpty() ? "" : "\nAnomalie associate all'oggetto pratica:\n" + anomalie),
                "Attenzione", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def errMsg = []
                            if (!pratica.versamenti.empty) {
                                errMsg << "Esistono versamenti collegati alla pratica"
                            }
                            def lista = denunceService.contitolariOggetto(oggettoContribuente.oggettoPratica.id)
                            if (lista?.size() > 0) {
                                errMsg << "Esistono contitolari sul quadro selezionato"
                            }

                            if (errMsg) {
                                errMsg << "La registrazione non è eliminabile"
                                Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                                return
                            }

                            errMsg << denunceService.eliminaOgCo(oggettoContribuente)
                            if (errMsg[0]) {
                                Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                            } else {
                                statoChiusura = "Salva"
                                chiudi()
                                Clients.showNotification("Quadro eliminato", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                            }
                        }
                    }
                }
        )
    }

    @NotifyChange(["oggettoContribuente", "filtri", "modifica"])
    @Command
    onSalvaOggetto(@BindingParam("aggiornaStato") boolean aggiornaStato) {
        this.aggiornaStato = aggiornaStato

        if (validaMaschera()) {

            if (isCreaOggettoContitolare && controlloContitolareEsistente(oggettoContribuente?.contribuente?.codFiscale, tipoRapporto, idOggettoPratica)) {
                def errore = []
                errore << "Errore in verifica integrità Base Dati"
                errore << "Identificazione '" + oggettoContribuente.contribuente.codFiscale + " " + idOggettoPratica + "' già presente in Oggetti Contribuente."
                errore << "La registrazione non può essere inserita."
                Clients.showNotification(errore.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                oggettoContribuente.contribuente.codFiscale = null
                filtri.contribuente.codFiscale = ""
            } else {
                if (controlloNumeroOrdine() && !isCreaOggettoContitolare && creazione) {
                    Messagebox.show("Attenzione! Esiste già un oggetto con quel numero d'ordine. \n Vuoi proseguire?", "Sostituzione oggetto", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                salva()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                oggettoContribuente.oggettoPratica.numOrdine = null
                                BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "numOrdine")
                            }
                        }
                    })
                } else {
                    if (!controlloTitoloEventoMesiPossesso()) {
                        SimpleDateFormat sdf = new SimpleDateFormat(("dd/MM/yyy"))
                        String descrizioneTitolo = (oggettoContribuente.oggettoPratica.titolo == 'A') ? 'Acquisto' : 'Cessazione'

                        def msg = "La Data Evento " + sdf.format(oggettoContribuente.dataEvento).toString() + " di " + descrizioneTitolo + " non è coerente con l'indicazione di Mesi Possesso (" + oggettoContribuente.mesiPossesso.toString() + "), "
                        msg += "Mesi inizio Possesso (" + oggettoContribuente.daMesePossesso.toString() + "), "
                        msg += "Mesi 1 Semestre (" + oggettoContribuente.mesiPossesso1sem.toString() + ")."
                        msg += "\nPer il calcolo vengono usati i mesi."
                        msg += "\n\nCorregere la data evento o le informazioni relative ai mesi (MP/MiP/1S)."
                        Messagebox.show(msg, "",
                                Messagebox.OK, Messagebox.ERROR,
                                new EventListener() {
                                    void onEvent(Event e) {
                                    }
                                }
                        )
                    } else if ((commonService.yearFromDate(oggettoContribuente.dataEvento) ?: oggettoContribuente.anno) != oggettoContribuente.anno) {
                        def msg = "L'anno della data evento non coincide con l'anno della dichiarazione.\nProseguire?"
                        Messagebox.show(msg, "",
                                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                                new EventListener() {
                                    void onEvent(Event e) {
                                        if (Messagebox.ON_YES.equals(e.getName())) {
                                            salva()
                                        }
                                    }
                                }
                        )
                    } else {
                        salva()
                    }
                }
            }
        }
    }

    private salva() {
        if (rendita == null) {
            rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                    , oggettoContribuente.oggettoPratica.tipoOggetto?.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                    , oggettoContribuente.oggettoPratica.pratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)
        }

        if (rendita != null) {
            oggettoContribuente?.oggettoPratica?.oggettoPraticaRendita?.rendita = rendita
        } else {
            oggettoContribuente?.oggettoPratica?.oggettoPraticaRendita = null
        }
        oggettoContribuente?.aliquoteOgco = listaAliquote?.sort { it.dal }
        oggettoContribuente = oggettiService.salvaOggettoContribuente(oggettoContribuente, tipoRapporto, tipoTributo, isCreaOggettoContitolare, pratica)
        statoChiusura = "Salva"

        listaAliquote = oggettoContribuente?.aliquoteOgco?.sort { it.dal }

        //Controllo se abilitare Pertinenza di...
        abilitaPertinenza()

        //Controllo della funzionalità di inserimento delle detrazioni
        abilitaInsDetrazioneAliquote()

        ricalcolaImposteOggetto()
        verificaImposteOggetto()

        salvato = true
        isCreaOggettoContitolare = false
        isDirty = false
        Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)

        BindUtils.postNotifyChange(null, null, this, "isDirty")
        BindUtils.postNotifyChange(null, null, this, "listSize")
        BindUtils.postNotifyChange(null, null, this, "listaAliquote")
        BindUtils.postNotifyChange(null, null, this, "isCreaOggettoContitolare")
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
        BindUtils.postNotifyChange(null, null, this, "aggiungiDetrazioniAliquote")

        aggiornaDataModifica()
        aggiornaUtente()
    }

    private
    def aggiornaDataModifica() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        def date = oggettoContribuente?.lastUpdated
        lastUpdated = (date) ? sdf.format(date) : ''
        BindUtils.postNotifyChange(null, null, this, "lastUpdated")
    }

    private def aggiornaUtente() {
        utente = oggettoContribuente?.utente
        BindUtils.postNotifyChange(null, null, this, "utente")
    }

    @NotifyChange(["oggettoContribuente", "filtri"])
    @Command
    onSelectCodFiscaleCon(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        filtri.contribuente.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
        Contribuente cont = Contribuente.findByCodFiscale(selectedRecord?.codFiscale?.toUpperCase())
        if (!cont) {
            oggettoContribuente.contribuente = new ContribuenteDTO(codFiscale: selectedRecord?.codFiscale)
            oggettoContribuente.contribuente.soggetto = selectedRecord
        } else {
            oggettoContribuente.contribuente = cont.toDTO(["soggetto", "ente"])
        }
    }

    @Command
    onChangeCodFiscaleCon(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event?.target?.oggetto
        if (selectedRecord) {
            Contribuente cont = Contribuente.findByCodFiscale(selectedRecord?.codFiscale?.toUpperCase())
            if (!cont) {
                Soggetto soggetto = Soggetto.findByCodFiscale(selectedRecord?.codFiscale?.toUpperCase())
                if (soggetto) {
                    oggettoContribuente.contribuente = new ContribuenteDTO(codFiscale: selectedRecord?.codFiscale)
                    oggettoContribuente.contribuente.soggetto = soggetto.toDTO()
                } else {
                    if (filtri.contribuente.codFiscale != "" && !event.target.isOpen()) {
                        String messaggio = "Non è stato selezionato alcun soggetto.\n"
                        messaggio += "Il soggetto con codice fiscale ${filtri?.contribuente?.codFiscale?.toUpperCase()} non è presente in anagrafe.\n"
                        messaggio += "Si desidera inserirne uno nuovo?"
                        Messagebox.show(messaggio, "Ricerca soggetto",
                                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                                new EventListener() {
                                    void onEvent(Event e) {
                                        if (Messagebox.ON_YES.equals(e.getName())) {
                                            creaPopupSoggetto("/archivio/soggetto.zul", [idSoggetto: -1, codiceFiscale: filtri.contribuente.codFiscale])
                                        } else if (Messagebox.ON_NO.equals(e.getName())) {
                                            svuotaContribuente()
                                        }
                                    }
                                }
                        )
                    }
                }
            } else {
                oggettoContribuente.contribuente = cont.toDTO(["soggetto", "ente"])
            }

            filtri.contribuente.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
        }

    }

    protected void creaPopupSoggetto(String zul, def parametri) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    (event.data.Soggetto) ? setSelectCodFiscale(event.data.Soggetto) : svuotaContribuente()
                }
            }
        }
        w.doModal()
    }

    def setSelectCodFiscale(def selectedRecord) {
        if (selectedRecord) {
            filtri.contribuente.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
            Contribuente cont = Contribuente.findByCodFiscale(selectedRecord?.codFiscale?.toUpperCase())
            if (!cont) {
                oggettoContribuente.contribuente = new ContribuenteDTO(codFiscale: selectedRecord?.codFiscale)
                oggettoContribuente.contribuente.soggetto = selectedRecord
            } else {
                oggettoContribuente.contribuente = cont.toDTO(["soggetto", "ente"])
            }
            BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    protected void svuotaContribuente() {
        if (oggettoContribuente) oggettoContribuente?.contribuente = null
        filtri.contribuente.codFiscale = ""
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @NotifyChange(["aggiungiDetrazioniAliquote"])
    @Command
    def onCheckAbitazionePrincipale() {

        pulisciImpostaOggetto()

        abilitaInsDetrazioneAliquote()
        BindUtils.postNotifyChange(null, null, this, "aggiungiDetrazioniAliquote")
    }

    //Controllo della funzionalità di inserimento delle detrazioni
    protected void abilitaInsDetrazioneAliquote() {
        aggiungiDetrazioniAliquote = (modifica &&
                (oggettoContribuente?.oggettoPratica?.tipoOggetto?.tipoOggetto == 3 || oggettoContribuente?.oggettoPratica?.tipoOggetto?.tipoOggetto == 55) &&
                (!oggettoContribuente?.flagAbPrincipale) &&
                (!isPertinenza || (oggettoContribuente?.oggettoPratica?.oggettoPraticaRifAp == null)))

    }

    // Controllo della funzionalità di Pertinenza di...
    protected void abilitaPertinenza() {
        isPertinenza = (oggettoContribuente?.oggettoPratica?.categoriaCatasto?.categoriaCatasto ?:
                oggettoContribuente?.oggettoPratica?.oggetto?.categoriaCatasto?.categoriaCatasto)?.startsWith("C") &&
                (oggettoContribuente?.oggettoPratica?.tipoOggetto?.tipoOggetto ?:
                        oggettoContribuente?.oggettoPratica?.oggetto?.tipoOggetto?.tipoOggetto) == 3 &&
                !(oggettoContribuente?.aliquoteOgco?.size() > 0)
        BindUtils.postNotifyChange(null, null, this, "isPertinenza")
    }

    protected void abilitaPertinenzaRif() {

        isPertinenzaRif = oggettoContribuenteRif?.categoriaCatasto?.startsWith("C") && oggettoContribuenteRif?.tipoOggetto == 3
        BindUtils.postNotifyChange(null, null, this, "isPertinenzaRif")
    }

    @Command
    @NotifyChange(["det"])
    onCheckDetrazione(@BindingParam("det") DetrazioneOgcoDTO detOgco) {
        if (detOgco?.anno) {
            Integer annoDetr = detOgco.anno
            def erroreCheckDetrazione = ""

            if (oggettoContribuente?.aliquoteOgco?.size() > 0) {
                oggettoContribuente.aliquoteOgco.each { a ->

                    Integer annoDal = a.dal.year + 1900
                    Integer meseDal = a.dal.month + 1
                    Integer giornoDal = a.dal.getAt(Calendar.DAY_OF_MONTH)
                    Integer annoAl = a.al.year + 1900
                    Integer meseAl = a.al.month + 1
                    Integer giornoAl = a.al.getAt(Calendar.DAY_OF_MONTH)

                    if (annoDetr == annoDal) {
                        if (giornoDal != 1 || meseDal != 1) {
                            erroreCheckDetrazione = "Attenzione: Non è possibile inserire una Detrazione Oggetto per l'anno " + annoDetr + ". Esistono Aliquote Oggetto per porzioni dello stesso anno."
                            detOgco.anno = null
                            Clients.showNotification(erroreCheckDetrazione, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    } else {
                        erroreCheckDetrazione = ""
                    }

                    if (annoDetr == annoAl) {
                        if (giornoAl != 31 || meseAl != 12) {
                            erroreCheckDetrazione = "Attenzione: Non è possibile inserire una Detrazione Oggetto per l'anno " + annoDetr + ". Esistono Aliquote Oggetto per porzioni dello stesso anno."
                            detOgco.anno = null
                            Clients.showNotification(erroreCheckDetrazione, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    } else {
                        erroreCheckDetrazione = ""
                    }
                }
            }
        }
    }

/* Controllo dataDal di una aliquota:
    *  data dal: deve essere il primo del mese e se esistono detrazioni per l'anno della data dal, questa deve essere il 01/01 */

    @NotifyChange(["aliq", "ali"])
    @Command
    onCheckAliquoteDataDal(@BindingParam("aliq") AliquotaOgcoDTO aliqOgco) {
        if (aliqOgco?.dal) {
            Integer giornoDal = aliqOgco.dal.getAt(Calendar.DAY_OF_MONTH)
            Integer meseDal = aliqOgco.dal.month + 1
            Integer annoDal = aliqOgco.dal.year + 1900
            if (giornoDal != 1) {
                aliqOgco.dal = null
                Clients.showNotification("Attenzione:Il giorno del campo Dal deve essere il primo del mese(1).", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                if (listaAliquote.size() > 0) {
                    Set<AttributoOgcoDTO> lista = oggettoContribuente.detrazioniOgco
                    lista.each { it ->
                        if (it.anno == annoDal && meseDal != 1) {
                            aliqOgco.dal = null
                            Clients.showNotification("Attenzione. Sono presenti delle Detrazioni Oggetto.\n La data nel campo Dal, per l'anno " + it.anno + " può essere solo il 1 gennaio.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    }
                }

                //La data Dal non può essere maggiore della data Al
                if (aliqOgco?.dal != null && aliqOgco?.al != null && (aliqOgco?.dal > aliqOgco?.al)) {
                    aliqOgco.dal = null
                    Clients.showNotification("Attenzione. Inizio validità maggiore di Fine validità.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                } else {
                    //Se sono stati definiti entrambe le date dal - al allora si controlla se ci sono intersezioni
                    if (listaAliquote.size() > 0 && aliqOgco?.dal != null && aliqOgco?.al != null) {
                        List<AliquotaOgcoDTO> lista = listaAliquote.sort { it.dal }
                        if (controlloAliquotePeriodi(lista, aliqOgco?.dal, aliqOgco?.al, listaAliquote.indexOf(aliqOgco))) {
                            aliqOgco.dal = null
                            Clients.showNotification("Attenzione. Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Aliquote Oggetto.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    }
                }
            }
        }
    }

    /* Controllo dataAl di una aliquota:
    *  data al: deve essere l'ultimo del mese e se esistono detrazioni per l'anno della data al, questa deve essere il 31/12 */

    @NotifyChange(["aliq", "ali"])
    @Command
    onCheckAliquoteDataAl(@BindingParam("aliq") AliquotaOgcoDTO aliqOgco) {
        if (aliqOgco?.al) {
            Integer giornoAl = aliqOgco.al.getAt(Calendar.DAY_OF_MONTH)
            Integer meseAl = aliqOgco.al.month + 1
            Integer annoAl = aliqOgco.al.year + 1900

            if (!isLastDayOfMonth(annoAl, meseAl, giornoAl)) {
                aliqOgco.al = null
                Clients.showNotification("Attenzione:Il giorno del campo Al deve essere l'ultimo del mese (" + new Date(annoAl, meseAl, 0).getDate() + ").", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                if (listaAliquote.size() > 0) {
                    Set<AttributoOgcoDTO> lista = oggettoContribuente.detrazioniOgco
                    lista.each { it ->
                        if (it.anno == annoAl && meseAl != 12) {
                            aliqOgco.al = null
                            Clients.showNotification("Attenzione. Sono presenti delle Detrazioni Oggetto.\nLa data nel campo Al, per l'anno " + it.anno + " può essere solo il 31 dicembre.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    }
                }

                //La data Dal non può essere maggiore della data Al
                if (aliqOgco?.dal != null && aliqOgco?.al != null && (aliqOgco?.dal > aliqOgco?.al)) {
                    aliqOgco.al = null
                    Clients.showNotification("Attenzione. Inizio validità maggiore di Fine validità.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                } else {
                    if (listaAliquote.size() > 0 && aliqOgco?.dal != null && aliqOgco?.al != null) {
                        List<AliquotaOgcoDTO> lista = listaAliquote.sort { it.dal }
                        if (controlloAliquotePeriodi(lista, aliqOgco?.dal, aliqOgco?.al, listaAliquote.indexOf(aliqOgco))) {
                            aliqOgco.al = null
                            Clients.showNotification("Attenzione. Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Aliquote Oggetto.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                        }
                    }
                }
            }
        }
    }

    protected boolean controlloAliquotePeriodi(List<AliquotaOgcoDTO> lista, Date dataDalX, Date dataAlX, int indice) {
        boolean isIntersezioni = true
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(("dd/MM/yyy"))

        if (lista?.size() > 1) {
            int n = lista.size()
            for (i in 0..<n) {

                if (i != indice) {
                    Date dal = lista.get(i).dal
                    Date al = lista.get(i).al
                    //println "X su dal "+simpleDateFormat.format(dataDalX)+" - "+simpleDateFormat.format(dataAlX)
                    //println "Data su i=" + i + " dal " + simpleDateFormat.format(dal) + " - " + simpleDateFormat.format(al)
                    if (dataDalX == dal || dataAlX == al) {
                        isIntersezioni = true
                        //println "Caso uguali " + isIntersezioni
                        break
                    } else {
                        if (dataDalX < dal && dataAlX < dal && dataAlX < al) {
                            isIntersezioni = false
                            //println "Caso precedente " + isIntersezioni
                        } else {
                            if (dataDalX > dal && dataAlX > al && dataDalX > al) {
                                isIntersezioni = false
                                //println "Caso successivo " + isIntersezioni
                            } else {
                                if (i < n && (i + 1 < n) && dataDalX > al && dataAlX < lista.get(i + 1).dal) {
                                    isIntersezioni = false
                                    //println "Caso interno " + isIntersezioni
                                }
                            }
                        }
                    }
                }
            }
            // println "Ci sono intersezioni????" + isIntersezioni
            return isIntersezioni
        }
    }

    protected boolean isLastDayOfMonth(int year, int month, int day) {
        GregorianCalendar gcal = new GregorianCalendar(year, month - 1, day)
        gcal.add(Calendar.DATE, 1)
        return (gcal.get(Calendar.DAY_OF_MONTH) == 1)
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onAggiungiDetrazione() {
        DetrazioneOgcoDTO detOgco = new DetrazioneOgcoDTO()
        oggettoContribuente.addToDetrazioniOgco(detOgco)

    }

    @NotifyChange(["oggettoContribuente", "listaAliquote"])
    @Command
    onAggiungiAliquota() {
        aliqOgcoDaInserire = new AliquotaOgcoDTO()
        //oggettoContribuente.addToAliquoteOgco(aliqOgcoDaInserire)
        //listaAliquote = oggettoContribuente?.aliquoteOgco?.sort {it.dal}

        aliqOgcoDaInserire.oggettoContribuente = oggettoContribuente
        if (!listaAliquote) {
            listaAliquote = new ArrayList<AliquotaOgcoDTO>()
        }
        listaAliquote.add(aliqOgcoDaInserire)

        //Controllo se abilitare Pertinenza di...
        abilitaPertinenza()
    }

    @NotifyChange(["oggettoContribuente"])
    @Command
    onEliminaDetrazione(@BindingParam("det") DetrazioneOgcoDTO detOgco) {
        oggettoContribuente.removeFromDetrazioniOgco(detOgco)
    }

    @NotifyChange(["oggettoContribuente", "listaAliquote"])
    @Command
    onEliminaAliquota(@BindingParam("aliq") AliquotaOgcoDTO aliqOgco) {
        oggettoContribuente.removeFromAliquoteOgco(aliqOgco)
        listaAliquote = oggettoContribuente?.aliquoteOgco?.sort { it.dal }
        //Controllo se abilitare Pertinenza di...
        abilitaPertinenza()
    }

    @NotifyChange(["rendita"])
    @Command
    onChangeValore() {
        rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                , oggettoContribuente.oggettoPratica?.tipoOggetto?.tipoOggetto
                , oggettoContribuente.oggettoPratica.pratica.anno
                , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)
        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            oggettoContribuente.oggettoPratica.flagValoreRivalutato = true
        }
        BindUtils.postNotifyChange(null, null, this, "rendita")

        pulisciImpostaOggetto()
    }

    @Command
    onChangeRendita() {
        ricalcolaValoreOgPr()
        pulisciImpostaOggetto()
    }

    @Command
    def onChangeParametro() {

        pulisciImpostaOggetto()
    }

    @Command
    def onChangeDetrazione() {
        pulisciImpostaOggetto()
        controllaDetrazione()
    }

    @Command
    def onChangeVersato() {

        ricalcolaImposteOggetto()
    }

    @Command
    onCopiaRendita(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {
        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        RiferimentoOggettoDTO rifOgg = event.dragged.getAttribute("foo")
        rendita = rifOgg.rendita
        oggettoContribuente.oggettoPratica.categoriaCatasto = rifOgg.categoriaCatasto ?: oggettoContribuente.oggettoPratica.categoriaCatasto
        oggettoContribuente.oggettoPratica.classeCatasto = rifOgg.classeCatasto ?: oggettoContribuente.oggettoPratica.classeCatasto
        ricalcolaValoreOgPr()
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "categoriaCatasto")
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "classeCatasto")
        BindUtils.postNotifyChange(null, null, this, "rendita")
    }

    private BigDecimal ricalcolaValore() {
        //Invoca la funzione f_valore_da_rendita
        return oggettiService.valoreDaRendita(rendita
                , oggettoContribuente.oggettoPratica?.tipoOggetto?.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto?.tipoOggetto?.tipoOggetto
                , oggettoContribuente.oggettoPratica.pratica.anno
                , oggettoContribuente.oggettoPratica.categoriaCatasto?.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto?.categoriaCatasto
                , (oggettoContribuente.oggettoPratica.immStorico) ? "S" : "N"
        )
    }

    private def ricalcolaValoreOgPr() {
        oggettoContribuente.oggettoPratica.valore = ricalcolaValore()
        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            oggettoContribuente.oggettoPratica.flagValoreRivalutato = true
        }
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")
    }

    @Command
    onSelectCategoriaCatasto() {
        ricalcolaValoreOgPr()
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")
        abilitaPertinenza()

        reimpostaValoreAliquota()

        pulisciImpostaOggetto()
    }

    @Command
    onSelectTipoOggetto() {
        String message = oggettiService.tipoOggettoModificabileOgCo(tipoTributo, oggettoContribuente.oggettoPratica)

        if (!message.isEmpty()) {
            Messagebox.show(message, "Attenzione.", Messagebox.OK, Messagebox.EXCLAMATION)
            oggettoContribuente.oggettoPratica.tipoOggetto = tipoOggettoOld
            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "tipoOggetto")
        } else {
            ricalcolaValoreOgPr()
            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")
        }

        //Controllo della funzionalità di inserimento delle detrazioni
        abilitaInsDetrazioneAliquote()

        BindUtils.postNotifyChange(null, null, this, "aggiungiDetrazioniAliquote")

        pulisciImpostaOggetto()
    }

    @Command
    doCheckedImmStorico() {
        ricalcolaValoreOgPr()
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "valore")

        pulisciImpostaOggetto()
    }

    @NotifyChange(["aggiungiDetrazioniAliquote"])
    @Command
    onSelectPertinenzaDi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        parametriBandbox.oggettoPraticaRifAp = selectedRecord?.oggettoPratica?.id
        oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = selectedRecord?.oggettoPratica
        isDirty = true
        abilitaInsDetrazioneAliquote()
        BindUtils.postNotifyChange(null, null, this, "aggiungiDetrazioniAliquote")

        reimpostaValoreAliquota()
        pulisciImpostaOggetto()
    }

    //se cancellano l'oggettoId o ne scrivono uno a mano, cancello i valori attualmente presenti per oggettoPraticaRifAp
    //FIXME: devo fare in modo che o cancellano tutto o selezionano per forza dalla combo
    @Command
    onChangePertinenzaDi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        parametriBandbox.oggettoId = ""
        parametriBandbox.oggettoPraticaRifAp = null
        oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = null
    }

    @NotifyChange(["parametriBandbox", "aggiungiDetrazioniAliquote"])
    @Command
    onCancellaPertinenzaDi() {
        parametriBandbox.oggettoId = ""
        parametriBandbox.oggettoPraticaRifAp = null
        oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = null
        abilitaInsDetrazioneAliquote()
        BindUtils.postNotifyChange(null, null, this, "aggiungiDetrazioniAliquote")
    }

    @Command
    def onSelectTipoAliquota() {

        reimpostaValoreAliquota()
        ricalcolaImposteOggetto()
    }

    @NotifyChange([
            "activeItem",
            "isPertinenza",
            "oggettoContribuente",
            "rendita",
            "listaAliquote"
    ])
    @Command
    onImmobilePrecedente() {

        if (isDirty && !lettura && !validaMaschera()) {
            return
        }

        if (isDirty && !lettura) {
            String messaggio = "Salvare le modifiche apportate?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onSalvaOggetto(false)
                                activeItem--
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                                isDirty = false
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                activeItem--
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                                isDirty = false
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            activeItem--
            caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
        }
    }

    @NotifyChange([
            "activeItem",
            "isPertinenza",
            "oggettoContribuente",
            "rendita",
            "listaAliquote"
    ])
    @Command
    onImmobileSuccessivo() {

        if (isDirty && !lettura && !validaMaschera()) {
            return
        }

        if (isDirty && !lettura) {
            String messaggio = "Salvare le modifiche apportate?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onSalvaOggetto(false)
                                activeItem++
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                                isDirty = false
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                activeItem++
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                                isDirty = false
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            activeItem++
            caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
        }
    }

    @NotifyChange([
            "activeItem",
            "isPertinenza",
            "oggettoContribuente",
            "rendita",
            "listaAliquote"
    ])
    @Command
    onImmobileUltimo() {

        if (isDirty && !lettura && !validaMaschera()) {
            return
        }

        if (isDirty && !lettura) {
            String messaggio = "Salvare le modifiche apportate?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onSalvaOggetto(false)
                                activeItem = listSize - 1
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                activeItem = listSize - 1
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            activeItem = listSize - 1
            caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
        }
    }

    @NotifyChange([
            "activeItem",
            "isPertinenza",
            "oggettoContribuente",
            "rendita",
            "listaAliquote"
    ])
    @Command
    onImmobilePrimo() {

        if (isDirty && !lettura && !validaMaschera()) {
            return
        }

        if (isDirty && !lettura) {
            String messaggio = "Salvare le modifiche apportate?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                onSalvaOggetto(false)
                                activeItem = 0
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                activeItem = 0
                                caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
                                changeImmobileRefresh()
                            } else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                                // Nulla da fare
                            }
                        }
                    })
        } else {
            activeItem = 0
            caricaImmobile(listaId.get(activeItem).contribuente.codFiscale, oggettoContribuente.tipoRapporto, listaId.get(activeItem).oggettoPratica.id)
        }
    }

    @Command
    onVariatoTitoloDataEvento() {

        if (oggettoContribuente.oggettoPratica.titolo == "") {
            oggettoContribuente.oggettoPratica.titolo = null

            oggettoContribuente.dataEvento = null

            BindUtils.postNotifyChange(null, null, oggettoContribuente, "dataEvento")

        }

        //Controllo dei flags
        checkAbilitaFlag()

        //Viene effettuato il calcolo se i due valori sono non nulli
        if (oggettoContribuente?.oggettoPratica?.titolo && oggettoContribuente.dataEvento) {

            int annoDataEvento = oggettoContribuente.dataEvento?.getAt(Calendar.YEAR)
            // Calcolare i mesi solo quando ANNO DATA_EVENTO=ANNO DENUNCIA e negli altri casi segnalare la discordanza
            if (oggettoContribuente.oggettoPratica.pratica.anno == annoDataEvento) {
                //chiamata alla funzione F_TITOLO_MESI_POSSESSO
                oggettoContribuente.mesiPossesso = denunceService.calcolaTitoloMesiPossesso(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)

                //chiamata alla funzione F_TITOLO_DA_MESE_POSSESSO
                oggettoContribuente.daMesePossesso = denunceService.calcolaTitoloDaMesiPossesso(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)

                //chiamata alla funzione F_TITOLO_MESI_POSSESSO_1SEM
                oggettoContribuente.mesiPossesso1sem = denunceService.calcolaTitoloMesiPossesso1Sem(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)

                BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso")
                BindUtils.postNotifyChange(null, null, oggettoContribuente, "daMesePossesso")
                BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")
            }
        }
    }

    //Attività #50245 note#18
    private checkAbilitaFlag() {
        disabilitaFlagsPera = oggettoContribuente?.oggettoPratica?.titolo == 'C' && oggettoContribuente.dataEvento
        disabilitaFlagAlRidotta = oggettoContribuente?.oggettoPratica?.titolo == 'C' && oggettoContribuente.dataEvento

        if (disabilitaFlagsPera) {
            oggettoContribuente.flagPossesso = false
            oggettoContribuente.flagEsclusione = false
            oggettoContribuente.flagRiduzione = false
            oggettoContribuente.flagAbPrincipale = false
        }
        if (disabilitaFlagAlRidotta) {
            oggettoContribuente.flagAlRidotta = false
        }

        BindUtils.postNotifyChange(null, null, this, "disabilitaFlagsPera")
        BindUtils.postNotifyChange(null, null, this, "disabilitaFlagAlRidotta")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "flagPossesso")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "flagEsclusione")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "flagRiduzione")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "flagAbPrincipale")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "flagAlRidotta")
    }

    private boolean controlloTitoloEventoMesiPossesso() {

        if (oggettoContribuente.oggettoPratica.titolo && oggettoContribuente.dataEvento &&
                (oggettoContribuente.oggettoPratica.titolo == 'C' || (oggettoContribuente.oggettoPratica.titolo == 'A' && oggettoContribuente.flagPossesso))) {

            int mp = denunceService.calcolaTitoloMesiPossesso(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)
            if (nvl(mp, 0) != nvl(oggettoContribuente.mesiPossesso, 0)) {
                return false
            }

            int mip = denunceService.calcolaTitoloDaMesiPossesso(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)
            if (nvl(mip, 0) != nvl(oggettoContribuente.daMesePossesso, 0)) {
                return false
            }

            int m1s = denunceService.calcolaTitoloMesiPossesso1Sem(oggettoContribuente.oggettoPratica.titolo, oggettoContribuente.dataEvento)
            if (nvl(m1s, 0) != nvl(oggettoContribuente.mesiPossesso1sem, 0)) {
                return false
            }
        }

        return true
    }

    @Command
    def onVariatoPercDetr() {

        controllaDetrazione()

        if (oggettoContribuente.detrazione == null && oggettoContribuente.percDetrazione != null) {

            TipoTributo tipoTributoRaw = TipoTributo.get(this.tipoTributo)
            Detrazione detrazione = Detrazione.findByTipoTributoAndAnno(tipoTributoRaw, pratica.anno)
            if (detrazione) {
                Double perc = oggettoContribuente.percDetrazione
                oggettoContribuente.detrazione = oggettoContribuente?.mesiPossesso != null ?
                        (((detrazione.detrazioneBase ?: 0) * perc * 0.01) / 12) * oggettoContribuente.mesiPossesso :
                        (detrazione.detrazioneBase * perc * 0.01)
                BindUtils.postNotifyChange(null, null, oggettoContribuente, "detrazione")
            }
        }

        pulisciImpostaOggetto()
    }

    /**
     * https://redmine.svi.finmatica.local/issues/39603#note-10
     *
     * modifica mesi possesso MP
     * 	- se si modifica MP con Flag Possesso valorizzato si ricalcola sempre sia MIP per 1S
     *     - se si modifica MP senza flag possesso si valorizzano nulli i MIP e 1S ad esclusione dei MP=12 dove MIP sarà 1 e 1S sarà 6
     * modifica mesi inizio possesso MIP
     *     - solo se Possesso è nullo e 1S nullo al cambio di MIP ricalcoliamo 1S dal MIP
     *     - solo se Possesso ='S' e 1S è nullo al cambio di MIP ricalcoliamo 1S da MP (non da MIP)
     *
     * NON FACCIAMO NESSUN INTERVENTO SU MP, MIP e 1S SE SI CAMBIA IL FLAG POSSESSO.
     *
     */
    @Command
    onVariatoMP() {

        def mesi = denunceService.calcolaMesi(
                oggettoContribuente.mesiPossesso,
                oggettoContribuente.daMesePossesso,
                oggettoContribuente.mesiPossesso1sem,
                oggettoContribuente.flagPossesso,
                'mp'
        )

        if (mesi.mip != -1) {
            oggettoContribuente.daMesePossesso = mesi.mip
        }

        if (mesi.m1s != -1) {
            oggettoContribuente.mesiPossesso1sem = mesi.m1s
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente, "daMesePossesso")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")

        pulisciImpostaOggetto()

        controllaDetrazione()
    }

    /**
     * https://redmine.svi.finmatica.local/issues/39603#note-10
     *
     * modifica mesi possesso MP
     * 	- se si modifica MP con Flag Possesso valorizzato si ricalcola sempre sia MIP per 1S
     *     - se si modifica MP senza flag possesso si valorizzano nulli i MIP e 1S ad esclusione dei MP=12 dove MIP sarà 1 e 1S sarà 6
     * modifica mesi inizio possesso MIP
     *     - solo se Possesso è nullo e 1S nullo al cambio di MIP ricalcoliamo 1S dal MIP
     *     - solo se Possesso ='S' e 1S è nullo al cambio di MIP ricalcoliamo 1S da MP (non da MIP)
     *
     * NON FACCIAMO NESSUN INTERVENTO SU MP, MIP e 1S SE SI CAMBIA IL FLAG POSSESSO.
     *
     */
    @Command
    onVariatoMiP() {

        def mesi = denunceService.calcolaMesi(
                oggettoContribuente.mesiPossesso,
                oggettoContribuente.daMesePossesso,
                oggettoContribuente.mesiPossesso1sem,
                oggettoContribuente.flagPossesso,
                'mip'
        )

        if (mesi.mip != -1) {
            oggettoContribuente.daMesePossesso = mesi.mip
        }

        if (mesi.m1s != -1) {
            oggettoContribuente.mesiPossesso1sem = mesi.m1s
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente, "daMesePossesso")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")

        pulisciImpostaOggetto()
    }


    /* Inserito questo controllo per il cambio del campo 1S ma per il momento non è abilitato
    * Stiamo valutando una soluzione al prossimo rilascio dalla segnalaione Bug #47304*/

    @Command
    onVariato1S() {
        controlloMesiPossesso()
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")

        pulisciImpostaOggetto()
    }

    private static int nvl(Integer value, Number valueWhenNull) {
        return (null != value) ? value : valueWhenNull
    }

    /*  - i mesi possesso del primo semestre non possono essere > 6
        - i mesi possesso del primo semestre non possono essere maggiori dei mesi possesso dell'anno
        - i mesi possesso del primo semestre non possono essere maggiori dei mesi possesso dell'anno - 6
        Si considera:
        - nvl(mesi_possesso,12)
        - nvl(mesiPossesso1sem,0) oppure nvl(mesiPossesso1sem,6) a seconda dei vari contesti
    */

    private void controlloMesiPossesso() {
        if (nvl(oggettoContribuente.mesiPossesso1sem, 0) > 6) {
            Messagebox.show("Attenzione:\nMesi Possesso 1 Semestre > 6 .", "Errore", Messagebox.OK, Messagebox.ERROR)
        } else {
            if (nvl(oggettoContribuente.mesiPossesso1sem, 6) > nvl(oggettoContribuente.mesiPossesso, 12)) {
                Messagebox.show("Attenzione:\nMesi Possesso 1 Semestre > Mesi Possesso .", "Errore", Messagebox.OK, Messagebox.ERROR)
            } else if (nvl(oggettoContribuente.mesiPossesso1sem, 6) < (nvl(oggettoContribuente.mesiPossesso, 12) - 6)) {
                Messagebox.show("Attenzione:\nMesi Possesso 1 Semestre < Mesi Possesso - 6 .", "Errore", Messagebox.OK, Messagebox.ERROR)
            }
        }
    }

    private boolean validaMaschera() {
        def warning = []
        def errori = []

        if (oggettoContribuente.oggettoPratica.numOrdine == null) {
            errori << "Num. Ordine Nullo."
        }

        if (oggettoContribuente?.contribuente?.codFiscale == null) {
            errori << ("Indicare il codice fiscale del contitolare")
        }

        if (oggettoContribuente.percPossesso > 100) {
            errori << "% di Possesso superiore a 100."
        } else {//Questo controllo vale solo per ICI
            if (tipoTributo == "ICI") {
                if (oggettoContribuente.oggettoPratica.id != null && (oggettoContribuente.percPossesso ?: 0 +
                        (denunceService.contitolariOggetto(oggettoContribuente.oggettoPratica.id)
                                .findAll { it.oggettoPratica.numOrdine == oggettoContribuente.oggettoPratica.numOrdine }
                                .sum { it.percPossesso ?: 0 } ?: 0)) > 100) {
                    warning << "Somma delle % di Possesso superiore a 100."
                }
            }
        }

        if (oggettoContribuente.percPossesso == null) {
            errori << "% di Possesso Nulla."
        }

        if (oggettoContribuente.detrazione != null && oggettoContribuente.percDetrazione == null) {
            errori << "Se Detr. è valorizzato, lo deve essere anche il campo % Detr."
        }

        if (oggettoContribuente.oggettoPratica.valore == null) {

            if (calcoloService.richiedeRenditaOgPr(oggettoContribuente.oggettoPratica)) {
                warning << "Valore dell'immobile Nullo."
            }
        }

        if (oggettoContribuente.mesiPossesso == null) {
            warning << "Mesi Possesso Nulli."
        }

        if (oggettoContribuente.daMesePossesso == null) {
            errori << "Mese inizio Possesso Nullo."
        } else {
            if ((oggettoContribuente.daMesePossesso < 0) || (oggettoContribuente.daMesePossesso > 12)) {
                errori << "Il valore di Mese inizio Possesso deve essere comopreso tra 0 e 12."
            } else {
                if (!oggettoContribuente.flagPossesso) {
                    def mesiPoss = oggettoContribuente.mesiPossesso ?: 0
                    if ((mesiPoss + oggettoContribuente.daMesePossesso - 1) > 12) {
                        errori << "Combinazione di Mesi Possesso / Mese inizio Possesso / Possesso incoerente."
                    }
                }
            }
        }

        /*  - i mesi possesso del primo semestre non possono essere > 6
            - i mesi possesso del primo semestre non possono essere maggiori dei mesi possesso dell'anno
            - i mesi possesso del primo semestre non possono essere maggiori dei mesi possesso dell'anno - 6
            Si considera:
            - nvl(mesi_possesso,12)
            - nvl(mesiPossesso1sem,0) oppure nvl(mesiPossesso1sem,6) a seconda dei vari contesti
        */
        if (nvl(oggettoContribuente.mesiPossesso1sem, 0) > 6) {
            errori << "Attenzione:\nMesi Possesso 1 Semestre > 6 ."
        } else {
            if (nvl(oggettoContribuente.mesiPossesso1sem, 6) > nvl(oggettoContribuente.mesiPossesso, 12)) {
                errori << "Attenzione:\nMesi Possesso 1 Semestre > Mesi Possesso ."
            } else if (nvl(oggettoContribuente.mesiPossesso1sem, 6) < (nvl(oggettoContribuente.mesiPossesso, 12) - 6)) {
                errori << "Attenzione:\nMesi Possesso 1 Semestre < Mesi Possesso - 6 ."
            }
        }

        if (errori.size() == 0) {
            String message = checkPeriodiSovrapposti()
            if (!message.isEmpty()) {
                errori << message
            }
        }

        if (oggettoContribuente.flagAbPrincipale && !oggettoContribuente.flagPossesso) {
            errori << "Flag Abitazione Principale e flag di Possesso incoerenti"
        }

        if ((oggettoContribuente.mesiEsclusione ?: 0) + (oggettoContribuente.mesiRiduzione ?: 0) > (oggettoContribuente.mesiPossesso ?: 12)) {
            errori << "Mesi possesso non corretti"
        }

        if (oggettoContribuente?.detrazioniOgco?.size() > 0) {
            boolean detrazioni = false
            oggettoContribuente.detrazioniOgco.each { d ->
                if (d.anno == null || d.motivoDetrazione == null)
                    detrazioni = true
            }
            if (detrazioni)
                errori << ("Compilare correttamente i campi obbligatori nel folder detrazioni")
        }

        boolean aliquote = false
        if (listaAliquote?.size() > 0) {
            for (i in 0..<listaAliquote.size()) {
                def a = listaAliquote.getAt(i)
                if (a.dal == null || a.al == null || a.tipoAliquota == null)
                    aliquote = true
            }

            if (aliquote)
                errori << ("Compilare correttamente i campi obbligatori nel folder aliquote")
            else {
                List<AliquotaOgcoDTO> lista = listaAliquote.sort { it.dal }
                for (i in 0..<listaAliquote.size()) {
                    if (controlloAliquotePeriodi(lista, listaAliquote.getAt(i).dal, listaAliquote.getAt(i).al, i)) {
                        errori << "Sono presenti delle intersezioni di periodo Dal/Al tra le date Aliquote Oggetto."
                        break
                    }
                }
            }
        }

        if (oggettoContribuente.oggettoPratica.tipoQualita != null && oggettoContribuente.oggettoPratica.qualita != null) {
            errori << "I dati identificativi della qualità non possono essere entrambi indicati."
        }

        //	NON bloccante che dice "Attenzione: % di Possesso Nulla!.". Lo stesso controllo deve essere effettuato anche per VALORE e MESI POSSESSO

        if (errori.size() > 0) {
            errori.add(0, "Impossibile salvare l'oggetto:\n")
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        if (warning.size() > 0) {
            warning.add(0, "Attenzione:\n")
            Clients.showNotification(warning.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return true
    }

    private boolean controlloContitolareEsistente(String codFiscale, String tr, long idOggPr) {
        def check = false
        def oggC = OggettoContribuente.createCriteria().get {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggettoPraticaRendita", "ogprre", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogge.archivioVie", "arvi", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogpr.categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
            createAlias("aliquoteOgco", "alog", CriteriaSpecification.LEFT_JOIN)
            createAlias("detrazioniOgco", "deog", CriteriaSpecification.LEFT_JOIN)
            createAlias("deog.motivoDetrazione", "mode", CriteriaSpecification.LEFT_JOIN)
            createAlias("attributiOgco", "atog", CriteriaSpecification.LEFT_JOIN)
            createAlias("atog.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)

            eq("contribuente.codFiscale", codFiscale)
            eq("tipoRapporto", tr)
            eq("ogpr.id", idOggPr)

        }?.toDTO([
                "contribuente",
                "contribuente.soggetto"
        ])

        if (oggC)
            check = true

        return check
    }

    @Command
    def onOpenCategorie() {
        // Risolve il problema di formattazione per descrizioni lunghe
    }

    @Command
    def onOpenQualita() {
        // Risolve il problema di formattazione per descrizioni lunghe
    }

    @Command
    onVisualizzaDocumento() {

        def contenuto = new String(importDatiEsterniService.loadContenuto(oggettoContribuente.attributoOgco.documentoId.id), "UTF-8")

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance()
        DocumentBuilder builder = factory.newDocumentBuilder()
        InputSource is = new InputSource(new StringReader(contenuto))
        Document xmlDocument = builder.parse(is)

        // Use a Transformer for output
        TransformerFactory tFactory = TransformerFactory.newInstance()
        def xsltFile = grailsApplication.mainContext.getResource("xslt/notai.xslt").file
        StreamSource stylesource = new StreamSource(xsltFile)
        Transformer transformer = tFactory.newTransformer(stylesource)

        DOMSource source = new DOMSource(xmlDocument)
        StringWriter writer = new StringWriter()
        StreamResult result = new StreamResult(writer)
        transformer.transform(source, result)

        AMedia amedia = new AMedia(oggettoContribuente.attributoOgco.documentoId.nomeDocumento + ".html", "html", "text/html", writer.toString())
        Filedownload.save(amedia)
    }

    @Command
    def controllaDetrazione() {

        Detrazione detrazione = Detrazione.findByTipoTributoAndAnno(TipoTributo.get(this.tipoTributo), pratica.anno)

        if (detrazione) {

            String format = "#,###.00"
            DecimalFormat df = new DecimalFormat(format)

            Double perc = oggettoContribuente.percDetrazione ?: 0.0

            // Solo se perc valorizzato viene eseguito il calcolo
            if (perc == null) {
                return
            }

            def detrazioneCalcolata = oggettoContribuente?.mesiPossesso != null ?
                    (((detrazione.detrazioneBase ?: 0) * perc * 0.01) / 12) * oggettoContribuente.mesiPossesso :
                    ((detrazione.detrazioneBase ?: 0) * perc * 0.01)

            if (oggettoContribuente.detrazione != null && df.format(detrazioneCalcolata) != df.format(oggettoContribuente.detrazione)) {
                Clients.showNotification("La Detrazione impostata è diversa da quella calcolata", Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 5000, true)
            }
        }
    }

    def changeImmobileRefresh() {
        BindUtils.postNotifyChange(null, null, this, "activeItem")
        BindUtils.postNotifyChange(null, null, this, "isPertinenza")
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
        BindUtils.postNotifyChange(null, null, this, "rendita")
    }

    private impostaMesiPoss1Sem(def sovrascrivi = false) {

        // Si calcola il valore solo se nullo
        if (oggettoContribuente.mesiPossesso1sem != null && !sovrascrivi) {
            impostaDaMesePossesso()
            return
        }

        if (oggettoContribuente.mesiPossesso != null) {

            impostaDaMesePossesso(sovrascrivi)

            def mesi1Sem = null

            if (oggettoContribuente.mesiPossesso == 0) {
                mesi1Sem = 0
            } else if (oggettoContribuente.mesiPossesso == 12) {
                mesi1Sem = 6
            }

            if ((oggettoContribuente.daMesePossesso != null) && (oggettoContribuente.daMesePossesso > 0)) {
                mesi1Sem = 0

                if (oggettoContribuente.daMesePossesso < 7) {
                    if ((oggettoContribuente.mesiPossesso + oggettoContribuente.daMesePossesso) > 7) {
                        mesi1Sem = 7 - oggettoContribuente.daMesePossesso
                    } else {
                        mesi1Sem = oggettoContribuente.mesiPossesso
                    }
                }
            }

            if (mesi1Sem != null) {
                oggettoContribuente.mesiPossesso1sem = mesi1Sem
            }
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente, "daMesePossesso")
        BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")
    }

    private void impostaDaMesePossesso(def sovrascrivi = false) {
        oggettoContribuente.daMesePossesso = 12 - oggettoContribuente.mesiPossesso + 1
        if (oggettoContribuente.daMesePossesso < 1) oggettoContribuente.daMesePossesso = 1

        // Si calcola solo se il valore è null
        if (oggettoContribuente.daMesePossesso != null && !sovrascrivi) {
            return
        }
        if (oggettoContribuente.daMesePossesso < 7) {
            oggettoContribuente.mesiPossesso1sem = 7 - oggettoContribuente.daMesePossesso
        } else {
            oggettoContribuente.mesiPossesso1sem = 0
        }

        if (oggettoContribuente.mesiPossesso != null) {
            //		- se si modifica MP senza flag possesso si valorizzano nulli i MIP e 1S ad esclusione dei MP=12 dove MIP sarà 1 e 1S sarà 6
            if (oggettoContribuente.mesiPossesso != null) {

                if (oggettoContribuente.mesiPossesso == 0) {
                    oggettoContribuente.daMesePossesso = 0
                } else if (oggettoContribuente.mesiPossesso == 12) {
                    oggettoContribuente.daMesePossesso = 1
                } else if ((oggettoContribuente.mesiPossesso > 0) && (oggettoContribuente.mesiPossesso < 12)) {
                    if (oggettoContribuente.mesiPossesso == 12) {

                        oggettoContribuente.daMesePossesso = 1
                        oggettoContribuente.mesiPossesso1sem = 6
                    } else {
                        oggettoContribuente.daMesePossesso = null
                        oggettoContribuente.mesiPossesso1sem = null
                    }
                }
            }

            BindUtils.postNotifyChange(null, null, oggettoContribuente, "daMesePossesso")
            BindUtils.postNotifyChange(null, null, oggettoContribuente, "mesiPossesso1sem")
        }
    }

    def checkPeriodiSovrapposti() {

        String message = ""

        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {

            List<OggettoPraticaDTO> oggettiPratica = denunceService.getOggettiPratica(pratica.id)

            def oggEsistente = oggettiPratica.find { it.oggettoPratica.id == oggettoContribuente.oggettoPratica.id }
            if (oggEsistente) {
                oggettiPratica.remove(oggEsistente)
            }
            oggettiPratica.add(oggettoContribuente)

            def report = liquidazioniAccertamentiService.verificaPeriodiIntersecati(oggettiPratica)

            if (report.result > 0) {
                message += report.message
            }
        }

        return message
    }

    def reimpostaValoreAliquota() {

        Short annoPratica = pratica.anno

        TipoAliquotaDTO tipoAliquota = listaTipiAliquotaAnno.find { it.tipoAliquota == oggettoImposte.tipoAliquota }
        AliquotaDTO aliquota
        if (tipoAliquota) {
            aliquota = tipoAliquota.aliquote.find { it.anno == annoPratica }
        }
        if (aliquota) {
            String tipoTributo = pratica.tipoTributo.tipoTributo
            String codFiscale = oggettoContribuente.contribuente.codFiscale
            def ni = oggettoContribuente.contribuente.soggetto.id

            OggettoPraticaDTO oggPr = oggettoContribuente.oggettoPratica
            OggettoPraticaDTO oggPrAp = oggPr.oggettoPraticaRifAp
            String catCat = oggPr.categoriaCatasto?.categoriaCatasto ?: oggPr.oggetto.categoriaCatasto?.categoriaCatasto

            Integer codiceAliquota = tipoAliquota.tipoAliquota
            Double valoreAliquota = aliquota.aliquota as Double

            valoreAliquota = aliquoteService.fAliquotaAlcaRifAp(annoPratica, codiceAliquota, catCat, valoreAliquota, tipoTributo, oggPr?.id, oggPrAp?.id, codFiscale, false)

            oggettoImposte.aliquota = valoreAliquota
        } else {
            oggettoImposte.aliquota = null
        }

        BindUtils.postNotifyChange(null, null, this, "oggettoImposte")
    }

    protected void caricaDatiOggettoRif(boolean notify = true) {

        String datoRiferimento = 'Riferimento'

        oggettoContribuenteRif = liquidazioniAccertamentiService.getDatiOggettoPratricaLiq(oggettoContribuente, this.pratica.anno)

        if (oggettoContribuenteRif.oggettoId) {
            datoRiferimento = 'Liquidato'
        } else {

            oggettoContribuenteRif = liquidazioniAccertamentiService.getDatiOggettoPratricaRif(oggettoContribuente, this.pratica.anno)
            if (oggettoContribuenteRif.oggettoId) {
                datoRiferimento = 'Dichiarato'
            }
        }

        abilitaPertinenzaRif()

        leggiImposteOggetto()

        def descrTipoPratica = elencoTipiPratica.find { it.codice == this.pratica.tipoPratica }
        if (descrTipoPratica == null) {
            descrTipoPratica = elencoTipiPratica[0]
        }

        titoloForm = "${descrTipoPratica.descrizione} ${tipoTributoAttuale} (${oggettoContribuente.oggettoPratica.pratica.anno})"
        titoloOggPr = descrTipoPratica.titoloOggPr
        titoloOggPrRif = descrTipoPratica.titoloOggPrRif.replace('__OrigineDato__', datoRiferimento);

        if (notify) {
            BindUtils.postNotifyChange(null, null, this, "oggettoContribuenteRif")

            BindUtils.postNotifyChange(null, null, this, "titoloForm")
            BindUtils.postNotifyChange(null, null, this, "titoloOggPr")
            BindUtils.postNotifyChange(null, null, this, "titoloOggPrRif")
        }
    }

    def ricalcolaImposteOggetto() {

        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            ricalcolaImposteOggettoAcc()
        }
    }

    def ricalcolaImposteOggettoAcc() {

        if ((oggettoImposte.tipoAliquota != null) && (oggettoImposte.aliquota != null)) {

            def parametri = [
                    versato     : oggettoImposte.versato,
                    tipoAliquota: oggettoImposte.tipoAliquota,
                    aliquota    : oggettoImposte.aliquota
            ]

            liquidazioniAccertamentiService.calcolaAccertamentoManualeOgCo(pratica.anno, parametri, pratica, oggettoContribuente)
            leggiImposteOggetto()
        } else {
            pulisciImpostaOggetto()
        }
    }

    def verificaImposteOggetto() {

        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            verificaImposteOggettoAcc()
        }
    }

    def verificaImposteOggettoAcc() {

        if ((oggettoImposte.tipoAliquota == null) || (oggettoImposte.aliquota == null)) {

            Clients.showNotification("Attenzione : \n\nAliquota Oggetto non impostata !", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    def leggiImposteOggetto() {

        OggettoPraticaDTO ogPr = oggettoContribuente?.oggettoPratica
        Long ogPrId = ogPr?.id ?: 0
        Short ogPrAnno = pratica?.anno ?: 0
        String codFiscale = pratica.contribuente?.codFiscale ?: '-'
        oggettoImposte = liquidazioniAccertamentiService.getImpostaOggPrIci(ogPrId, ogPrAnno, codFiscale)

        if (!rendita) {

            String catCat = ogPr.categoriaCatasto?.categoriaCatasto ?: ogPr.oggetto.categoriaCatasto?.categoriaCatasto ?: ''
            rendita = oggettiService.getRenditaOggettoPratica(ogPr.valore, ogPr?.tipoOggetto?.tipoOggetto, ogPrAnno, catCat)
            if (!rendita) {
                if (oggettoContribuenteRif.rendita) {
                    rendita = oggettoContribuenteRif.rendita
                }
            }
        }

        BindUtils.postNotifyChange(null, null, this, "oggettoImposte")
    }

    def pulisciImpostaOggetto() {

        oggettoImposte.imposta = null
        BindUtils.postNotifyChange(null, null, this, "oggettoImposte")
    }
}
