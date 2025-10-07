package pratiche.denunce

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Popup
import org.zkoss.zul.Textbox
import org.zkoss.zul.Window

import java.text.DecimalFormat
import java.text.SimpleDateFormat

class OggettoContribuenteTariViewModel {

    private def DM_PERCRID = 80
    private def DM_RID = 'N'

    public static final def MODLITA = [
            CREA     : 'crea',
            ESISTENTE: 'esistente'
    ]

    def ID_COMPONENTI = [
            CMB_TRIBUTO           : 'cmbTributo',
            CMB_CATEGORIA         : 'cmbCategoria',
            CMB_TARIFFA           : 'cmbTariffa',
            DAT_INIZIO_OCCUPAZIONE: 'datInizioOccupazione',
            DAT_INIZIO_DECORRENZA : 'datInizioDecorrenza',
            DAT_FINE_OCCUPAZIONE  : 'datFineOccupazione',
            DAT_CESSAZIONE        : 'datCessazione',
            DEC_SUPERFICIE        : 'decSuperficie',
            DEC_PERC_POSS         : 'decPercPoss',
            INT_NUM_FAM           : 'intNumFam',
            FLAG_DA_DM            : 'flagDaDM',
            FLAG_RID_SUP          : 'flagRidSup',
            FLAG_ANNULLATA        : "flagAnnullata",
            FLAG_PUNTO_RACCOLTA   : "flagPuntoRaccolta"
    ]

    // Componenti
    Window self

    @Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
    List<HtmlBasedComponent> componenti
    Popup popupNote

    // Servizi
    DenunceService denunceService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    ContribuentiService contribuentiService
    CommonService commonService
    OggettiService oggettiService
    IntegrazioneDePagService integrazioneDePagService
    CompetenzeService competenzeService

    // Modello
    PraticaTributoDTO pratica
    ContribuenteDTO contribuente
    OggettoContribuenteDTO oggettoContribuente
    def oggettoContribuenteRif
    def oggettoImposte

    List<TipoOggettoDTO> listaTipologiaOggetto
    List<CategoriaCatastoDTO> listaCategorieCatasto
    List<CodiceTributoDTO> listaCodicitributo
    List<CategoriaDTO> listaCategorie
    List<TariffaDTO> listaTariffe

    List listaTitoliOccupazione = [null,
                                   TitoloOccupazione.PROPRIETA,
                                   TitoloOccupazione.USUFRUTTO,
                                   TitoloOccupazione.LOCATARIO,
                                   TitoloOccupazione.ALTRO]
    List listaNaturaOccupazione = [null,
                                   NaturaOccupazione.SINGOLO,
                                   NaturaOccupazione.NUCLEO,
                                   NaturaOccupazione.COMMERCIALE,
                                   NaturaOccupazione.ALTRO]
    List listaDestinazioneUso = [null,
                                 DestinazioneUso.ABITATIVO,
                                 DestinazioneUso.DISPOSIZIONE,
                                 DestinazioneUso.COMMERCIALE,
                                 DestinazioneUso.BOX,
                                 DestinazioneUso.ALTRO]
    List listaAssenzaCatasto = [null,
                                AssenzaEstremiCatasto.NON_ACCATASTATO,
                                AssenzaEstremiCatasto.NON_ACCATASTABILE,
                                AssenzaEstremiCatasto.ALTRO]
    List<PartizioneOggettoPraticaDTO> listaPartizioni = []
    List<TipoAreaDTO> listaTipiArea

    def listaRuoli = []

    def ruoloSelezionato

    boolean isAbitazionePrincipale

    int selectedTab = 0

    def parametriBandbox = [anno                 : null
                            , codFiscale         : ""
                            , oggettoPratica     : null
                            , oggettoPraticaRifAp: null
                            , oggettoId          : null
                            , nomeMetodo         : "pertinenzeTARIBandBox"
                            , tipoTributo        : ""]

    List listaFetchOggettiPratica = ["oggettoPratica", "oggettoPratica.oggetto", "oggettoPratica.oggetto.archivioVie"]

    //variabili per gestire la navigazione tra gli immobili della pratica
    List<OggettoContribuenteDTO> listaOggetti
    int listSize
    int activeItem
    String tipoTributo
    def preVal

    def ogcoCreata = false

    boolean ogprInviatoARuolo = false
    boolean modificaFAbPriInviatoARuolo = false

    boolean dePagAbilitato = false

    def visualizzaFolderRfid

    Date oldDataDecorrenza = null
    Date oldDataCessazione = null

    def solaLettura = false

    def percRiduzioneSuperficie = null
    def flagRiduzioneSuperficie = false
    def flagDaDatiMetrici = false
    def listaDatiMetrici
    def showDatiMetriciOggetto = false
    def datiMetriciUiuSelezionata
    def labelRiduzioneSuperficie = ""

    def imgDaDMVisible = true

    String lastUpdated
    def utente

    def elencoTipiPratica = [
            [codice: TipoPratica.D.tipoPratica, descrizione: TipoPratica.D.descrizione, titoloOggPr: 'Dichiarato', titoloOggPrRif: 'Riferimento'],
            [codice: TipoPratica.A.tipoPratica, descrizione: TipoPratica.A.descrizione, titoloOggPr: 'Accertato', titoloOggPrRif: 'Dichiarato'],
            [codice: TipoPratica.V.tipoPratica, descrizione: TipoPratica.V.descrizione, titoloOggPr: 'Accertato', titoloOggPrRif: 'Dichiarato'],
    ]
    String titoloForm
    String titoloOggPr
    String titoloOggPrRif

    def model = [:]
    def puntoRaccoltaVisible = false
    def puntoRaccoltaRifVisible = false

    def listaContenitori
    def listaCodiciRfid

    @NotifyChange(["isAbitazionePrincipale", "oggettoContribuente"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("indexOggetto") Long indexOggCo
         , @ExecutionArgParam("listaOggetti") List<OggettoContribuenteDTO> listaOggetti
         , @ExecutionArgParam("tipoTributo") String tt
         , @ExecutionArgParam("preVal") Map preVal
         , @ExecutionArgParam("idPratica") def idPratica
         , @ExecutionArgParam("modalitaInserimento") String modalitaInserimento
         , @ExecutionArgParam("lettura") def lt) {

        DM_PERCRID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_PERCRID' }?.valore?.trim() as Double) ?: 80.0
        DM_RID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_RID' }?.valore?.trim()) ?: 'N'

        if (modalitaInserimento && !(modalitaInserimento in [MODLITA.CREA, MODLITA.ESISTENTE])) {
            throw new RuntimeException("Modalità ${modalitaInserimento} non supportata.")
        }

        this.self = w
        this.listaOggetti = listaOggetti ?: []
        listSize = this.listaOggetti.size()
        activeItem = indexOggCo
        tipoTributo = tt

        this.dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        if (lt) {
            this.solaLettura = true
        } else {
            this.solaLettura = competenzeService.tipoAbilitazioneUtente('TARSU') == competenzeService.TIPO_ABILITAZIONE.LETTURA
        }

        String patternNumero = "#,##0.00"
        DecimalFormat numero = new DecimalFormat(patternNumero)
        this.percRiduzioneSuperficie = DM_PERCRID
        this.labelRiduzioneSuperficie = "Rid. ${numero.format(percRiduzioneSuperficie)} % "

        // Visualizzazione/Modifica
        if (activeItem != -1) {
            oggettoContribuente = this.listaOggetti.get(activeItem)
            this.pratica = PraticaTributo.get(oggettoContribuente.oggettoPratica.pratica.id).toDTO(['contirbuente', 'versamenti', "tipoTributo"])

            oldDataDecorrenza = oggettoContribuente.dataDecorrenza
            oldDataCessazione = oggettoContribuente.dataCessazione

            flagDaDatiMetrici = oggettoContribuente.oggettoPratica.flagDatiMetrici == 'S'
            flagRiduzioneSuperficie = oggettoContribuente.oggettoPratica.percRiduzioneSup != 100.0
        } else {
            // Creazione nuovo locale/area
            if (!idPratica) {
                throw new RuntimeException("Creazione nuova locale/area: idPratica non definito.")
            }

            PraticaTributoDTO pratica = PraticaTributo.get(idPratica).toDTO(['contirbuente', 'versamenti', "tipoTributo"])
            this.pratica = pratica

            oggettoContribuente = new OggettoContribuenteDTO([
                    anno          : pratica.anno,
                    oggettoPratica: new OggettoPraticaDTO([
                            anno           : pratica.anno,
                            pratica        : pratica,
                            tipoOccupazione: determinaTipoOccupazione(pratica)
                    ]),
                    contribuente  : pratica.contribuente
            ])
        }

        contribuente = Contribuente.get(pratica.contribuente.codFiscale)?.toDTO(['soggetto'])

        oggettoContribuenteRif = liquidazioniAccertamentiService.getDatiOggettoPratricaRif(oggettoContribuente, this.pratica.anno)
        leggiImposteOggetto()

        def descrTipoPratica = elencoTipiPratica.find { it.codice == this.pratica.tipoPratica }
        if (descrTipoPratica == null) descrTipoPratica = elencoTipiPratica[0]
        titoloForm = "${descrTipoPratica.descrizione} ${tipoTributo} (${oggettoContribuente.oggettoPratica.pratica.anno})"
        titoloOggPr = descrTipoPratica.titoloOggPr
        titoloOggPrRif = descrTipoPratica.titoloOggPrRif

        caricaDettagliImmobile()    //carica i dettagli che dipendono da oggettoPrt
        listaTipologiaOggetto = OggettiCache.OGGETTI_TRIBUTO.valore.findAll { it.tipoTributo.tipoTributo == "TARSU" }?.tipoOggetto
        listaCategorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore
        listaCodicitributo = [new CodiceTributoDTO()] + OggettiCache.CODICI_TRIBUTO
                .valore
                .findAll { it.tipoTributo?.tipoTributo == 'TARSU' }
                .sort { it.id }
        listaTipiArea = OggettiCache.TIPI_AREA.valore
        this.preVal = preVal

        this.ogprInviatoARuolo = denunceService.fOgPrInviato(oggettoContribuente.oggettoPratica.id)

        // Inserimento ricercando l'oggetto
        if (modalitaInserimento == MODLITA.ESISTENTE) {
            commonService.creaPopup("/archivio/listaOggettiRicerca.zul", self,
                    [filtri: null, listaVisibile: true, inPratica: false, ricercaContribuente: false, tipo: 'TARSU'], { e ->
                if (!e.data) {
                    onChiudiPopup()
                } else {
                    oggettoContribuente.oggettoPratica.oggetto = Oggetto.get(e.data.idOggetto).toDTO(["archivioVie"])
                    BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
                }
            })
        } else if (modalitaInserimento == MODLITA.CREA) {
            commonService.creaPopup('pratiche/denunce/oggettoPerTributo.zul', self,
                    [tipoTributo: 'TARSU'], { e ->
                if (!e.data) {
                    onChiudiPopup()
                } else {
                    oggettoContribuente.oggettoPratica.oggetto = Oggetto.get(e.data.idOggetto).toDTO(["archivioVie"])
                    if (oggettoContribuente.oggettoPratica.pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.U]) {
                        recuperaSupDaDM(false)
                    }
                    BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
                }
            })
        }

        listaContenitori = denunceService.getContenitori()

        visualizzaFolderRfid = pratica.tipoPratica == 'D' &&
                (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'TARI_RFID' }?.valore ?: 'N') == 'S'

        caricaCodiciRfid()
        caricaRuoli()
        puntoRaccoltaVisible = visualizzaPuntoRaccolta(pratica.tipoPratica)
        puntoRaccoltaRifVisible = visualizzaPuntoRaccolta(oggettoContribuenteRif.tipoPratica)

        initModel()
    }

    private caricaCodiciRfid() {
        if (oggettoContribuente.oggettoPratica.oggetto?.id == null) {
            listaCodiciRfid = []
        } else {
            listaCodiciRfid = denunceService.getCodiciRfid([
                    codFiscale: oggettoContribuente.contribuente.codFiscale,
                    idOggetto : oggettoContribuente.oggettoPratica.oggetto.id
            ])
        }
        BindUtils.postNotifyChange(null, null, this, 'listaCodiciRfid')
    }

    private visualizzaPuntoRaccolta(def tipoPratica) {
        tipoPratica == TipoPratica.D.tipoPratica
    }

    private caricaRuoli() {
        if (oggettoContribuente.oggettoPratica.oggetto?.id == null ||
                oggettoContribuente.oggettoPratica.codiceTributo == null ||
                oggettoContribuente.oggettoPratica.id == null
        ) {
            listaRuoli = []
        } else {
            listaRuoli = contribuentiService.getRuoliOggettoContribuente(oggettoContribuente.oggettoPratica.codiceTributo.tipoTributo.tipoTributo
                    , oggettoContribuente.contribuente.codFiscale
                    , oggettoContribuente.oggettoPratica.oggetto.id
                    , oggettoContribuente.oggettoPratica.pratica.id
                    , oggettoContribuente.oggettoPratica.id)
        }

        BindUtils.postNotifyChange(null, null, this, 'listaRuoli')
    }

    @AfterCompose
    void afterCompose(@ContextParam(ContextType.VIEW) Component view) {
        inizializzaInterfaccia()
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

    @Command
    def onRiempiCategoria() {
        riempiCategoria(true)
        annullaOggettoImposte()
    }

    @Command
    def onRiempiTariffa() {
        riempiTariffa(true)

        // E' stata selezionata la categoria, si verifica se domestica
        if (pratica.tipoEvento == TipoEventoDenuncia.I && oggettoContribuente.oggettoPratica.categoria) {
            autoPopolamentoParametri(oggettoContribuente.oggettoPratica.categoria)
        }
        annullaOggettoImposte()
    }

    @Command
    def onCambioTariffa() {
        annullaOggettoImposte()
    }

    @Command
    def onCambioParametri() {
        annullaOggettoImposte()
    }

    @Command
    def onAggiungiPartizione() {
        listaPartizioni << nuovaPartizione(oggettoContribuente.oggettoPratica.id)
        BindUtils.postNotifyChange(null, null, this, "listaPartizioni")
    }

    @Command
    def onEliminaPartizione(@BindingParam("part") PartizioneOggettoPraticaDTO part) {
        def title = "Partizione"
        def message = "Eliminare la partizione #${++listaPartizioni.findIndexOf { it.uuid == part.uuid }}"

        Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaPartizione(part)
                        }
                    }
                }
        )
    }

    @Command
    def onDuplicaPartizione(@BindingParam("part") PartizioneOggettoPraticaDTO part) {

        listaPartizioni << nuovaPartizione(oggettoContribuente.oggettoPratica.id, part)
        BindUtils.postNotifyChange(null, null, this, "listaPartizioni")
    }

    @Command
    def onChiudiPopup() {

        conferma({ chiudi(ogcoCreata ? [ogcoCreata: ogcoCreata, oggCo: oggettoContribuente] : null) })
    }

    def conferma(def azione = {}) {
        if (isDirty()) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.name)) {
                                salva()
                                azione()
                            } else if (Messagebox.ON_NO.equals(e.name))
                                azione()
                        }
                    }
            )
        } else {
            azione()
        }
    }

    def salva() {

        inizializzaInterfaccia()

        if (validaMaschera()) {

            oggettoContribuente.oggettoPratica.flagDatiMetrici = flagDaDatiMetrici ? 'S' : null
            oggettoContribuente.oggettoPratica.percRiduzioneSup = flagRiduzioneSuperficie ? percRiduzioneSuperficie : 100.0

            // Se si e' in creazione di un nuovo oggetto
            ogcoCreata = (activeItem == -1)

            oggettoContribuente = oggettiService.salvaOggettoContribuenteTarsu(oggettoContribuente, listaPartizioni)
            listaPartizioni = denunceService.getPartizioni(oggettoContribuente.oggettoPratica.id)

            denunceService.saveCodiciRfid([
                    codFiscale: oggettoContribuente.contribuente.codFiscale,
                    idOggetto : oggettoContribuente.oggettoPratica.oggetto.id
            ], listaCodiciRfid)
            caricaCodiciRfid()
            caricaRuoli()

            ricalcolaImposteOggetto()

            initModel()

            BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
            BindUtils.postNotifyChange(null, null, this, "listaPartizioni")

            Clients.showNotification("Salvataggio eseguito con successo.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 5000, true)
        }
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

    def chiudi(def result) {

        Events.postEvent(Events.ON_CLOSE, self, result)
    }

    @Command
    def onSelectPertinenzaDi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        parametriBandbox.oggettoPraticaRifAp = selectedRecord?.oggettoPratica?.id
        oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = selectedRecord?.oggettoPratica
    }

    @NotifyChange(["oggettoContribuente.oggettoPratica.tipoOggetto"])
    @Command
    def onSelectTipoOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        oggettoContribuente.oggettoPratica.tipoOggetto = selectedRecord
    }

    @NotifyChange(["parametriBandbox"])
    @Command
    def onCancellaPertinenzaDi() {
        parametriBandbox.oggettoId = ""
        parametriBandbox.oggettoPraticaRifAp = null
        oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = null
    }

    @NotifyChange(["oggettoContribuente", "activeItem"])
    @Command
    def onImmobilePrecedente() {

        isDirty()

        conferma({
            activeItem--
            caricaImmobile(activeItem)
        })
    }

    @NotifyChange(["oggettoContribuente", "activeItem"])
    @Command
    def onImmobileSuccessivo() {

        isDirty()

        conferma({
            activeItem++
            caricaImmobile(activeItem)
        })
    }

    @NotifyChange(["oggettoContribuente", "activeItem"])
    @Command
    def onImmobileUltimo() {
        conferma({
            activeItem = listSize - 1
            caricaImmobile(activeItem)
        })
    }

    @NotifyChange(["oggettoContribuente", "activeItem"])
    @Command
    def onImmobilePrimo() {

        conferma({
            activeItem = 0
            caricaImmobile(activeItem)
        })
    }

    @Command
    def onSalva() {
        salva()
    }

    @Command
    def onInforTariffe() {
        commonService.creaPopup("/pratiche/denunce/infoTariffe.zul", self,
                [params: [
                        tipoTributo: oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo,
                        tributo    : oggettoContribuente.oggettoPratica.codiceTributo.id,
                        categoria  : oggettoContribuente.oggettoPratica.categoria.categoria,
                        tipoTariffa: oggettoContribuente.oggettoPratica.tariffa.tipoTariffa
                ]])
    }

    @Command
    def onModAbPriRuolo() {
        modificaFAbPriInviatoARuolo = !modificaFAbPriInviatoARuolo

        BindUtils.postNotifyChange(null, null, this, "modificaAbPriARuolo")
        BindUtils.postNotifyChange(null, null, this, "ogprInviatoARuolo")
    }

    @Command
    def onCambiaInizioOccupazione() {

        // Se si annulla la data inizio occupazione
        if (!oggettoContribuente.inizioOccupazione) {
            // Si annulla anche la data decorrenza
            oggettoContribuente.dataDecorrenza = null
        } else {

            if (oggettoContribuente.oggettoPratica.tipoOccupazione == TipoOccupazione.T) {

                // Se si valorizza la data occupazione, se la data decorrenza è nulla si setta a data occupazione
                oggettoContribuente.dataDecorrenza = oggettoContribuente.dataDecorrenza ?: oggettoContribuente.inizioOccupazione

            } else {
                oggettoContribuente.dataDecorrenza = denunceService.fGetDecorrenzaCessazione(oggettoContribuente.inizioOccupazione, 0)
            }
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente, "dataDecorrenza")

        annullaOggettoImposte()
    }

    @Command
    def onCambiaFineOccupazione() {

        if (!oggettoContribuente.fineOccupazione) {
            // Si annulla anche la data cessazione
            oggettoContribuente.dataCessazione = null
        } else {
            if (oggettoContribuente.oggettoPratica.tipoOccupazione == TipoOccupazione.T) {

                // Se si valorizza la data fine occupazione, se la data cessazione è nulla si setta a data fine occupazione
                oggettoContribuente.dataCessazione = oggettoContribuente.dataCessazione ?: oggettoContribuente.fineOccupazione

            } else {
                oggettoContribuente.dataCessazione = denunceService.fGetDecorrenzaCessazione(oggettoContribuente.fineOccupazione, 1)
            }
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente, "dataCessazione")

        annullaOggettoImposte()
    }

    /**
     * L'eliminazione può essere eseguita solo se l'oggetto_pratica non risulta inserito in un ruolo inviato a consorzio
     * (funzione F_OGPR_INVIATO) e se non esistono righe nel folder Versamenti.
     * Si esegue la procedure oggetti_pratica_pd: se la procedure restituisce un errore Oracle, l'eliminazione non
     * può essere eseguita.
     */
    @Command
    def onEliminaOgCo() {

        Messagebox.show("Eliminare il quadro?", "Attenzione", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def errMsg = []
                            if (ogprInviatoARuolo) {
                                errMsg << "Oggetto pratica con ruolo inviati al consorzio"
                            }
                            if (!pratica.versamenti.empty) {
                                errMsg << "Esistono versamenti collegati alla pratica"
                            }

                            if (errMsg) {
                                Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                                return
                            }

                            errMsg << denunceService.eliminaOgCoTarsu(oggettoContribuente)
                            if (errMsg[0]) {
                                Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                            } else {
                                chiudi(ogcoCreata ? [ogcoEliminata: true] : null)
                                Clients.showNotification("Quadro eliminato", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onRecuperaSupDaDM() {
        recuperaSupDaDM()
    }

    @Command
    def onSelezionaDatoMetrico() {
        showDatiMetriciOggetto = false
        oggettoContribuente.oggettoPratica.consistenza = DM_RID == 'S' ? (datiMetriciUiuSelezionata.superficieNum ?: 0) * (percRiduzioneSuperficie) / 100 : (datiMetriciUiuSelezionata.superficieNum ?: 0)
        datiMetriciUiuSelezionata = null
        flagDaDatiMetrici = true
        flagRiduzioneSuperficie = (DM_RID == 'S')

        BindUtils.postNotifyChange(null, null, this, "flagDaDatiMetrici")
        BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
        BindUtils.postNotifyChange(null, null, this, "datiMetriciUiuSelezionata")
        BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "consistenza")
    }

    @Command
    def onCheckRiduzioneSuperficie() {

        def consistenza = oggettoContribuente.oggettoPratica.consistenza ?: 0.0
        def percentuale = percRiduzioneSuperficie ?: 100.0

        if (flagRiduzioneSuperficie) {
            oggettoContribuente.oggettoPratica.consistenza = (consistenza * percentuale) / 100
        } else {
            oggettoContribuente.oggettoPratica.consistenza = (consistenza / percentuale) * 100
        }

        BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "consistenza")
    }

    @Command
    def onCheckDatiMetrici() {
        if (!flagDaDatiMetrici) {
            flagRiduzioneSuperficie = false
            BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
        } else {
            recuperaSupDaDM()
        }
    }


    @Command
    void onAggiungiRfid() {
        listaCodiciRfid << nuovoCodiceRfid(oggettoContribuente)
        BindUtils.postNotifyChange(null, null, this, 'listaCodiciRfid')
    }

    @Command
    void onDuplicaRfid(@BindingParam("codRfid") CodiceRfidDTO codRfid) {
        listaCodiciRfid << duplicaCodRfid(codRfid)
        BindUtils.postNotifyChange(null, null, this, "listaCodiciRfid")
    }

    @Command
    void onEliminaRfid(@BindingParam("codRfid") CodiceRfidDTO codRfid) {
        def title = "Codici RFID"
        def message = "Eliminare il Cod.RFID: ${codRfid.codRfid}"

        Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            eliminaCodiceRfid(codRfid)
                        }
                    }
                }
        )
    }

    private autoPopolamentoParametri(CategoriaDTO categoria) {

        if (!categoria) {
            return
        }

        // Se categoria domestica
        if (categoria?.flagDomestica == 'S') {
            // Si recupera, se esiste, il primo quadro di utenza domestica
            def ogprDomestiche = PraticaTributo.get(pratica.id)
                    .oggettiPratica
                    .findAll { it.categoria.flagDomestica == 'S' }
                    .sort { it.id }

            if (!ogprDomestiche.empty) {
                def ogpr = ogprDomestiche[0]
                oggettoContribuente.oggettoPratica.tariffa = ogpr.tariffa.toDTO()
                oggettoContribuente.oggettoPratica.numeroFamiliari = ogpr.numeroFamiliari
                oggettoContribuente.flagAbPrincipale = ogpr.oggettiContribuente[0]?.flagAbPrincipale
                oggettoContribuente.percPossesso = ogpr.oggettiContribuente[0]?.percPossesso
                oggettoContribuente.inizioOccupazione = ogpr.oggettiContribuente[0]?.inizioOccupazione
                oggettoContribuente.dataDecorrenza = ogpr.oggettiContribuente[0]?.dataDecorrenza
            }

        } else {
            // Utenza non domestica
            def ogprNonDomestiche = PraticaTributo.get(pratica.id)
                    .oggettiPratica
                    .findAll { it.categoria.flagDomestica == null }
                    .sort { it.id }

            if (!ogprNonDomestiche.empty) {
                def ogpr = ogprNonDomestiche[0]
                oggettoContribuente.inizioOccupazione = ogpr.oggettiContribuente[0].inizioOccupazione
                oggettoContribuente.dataDecorrenza = ogpr.oggettiContribuente[0].dataDecorrenza
            }
        }

        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
    }

    def annullaOggettoImposte() {

        if (oggettoImposte.impostaLorda != null) {

            oggettoImposte.imposta = null
            oggettoImposte.impostaLorda = null
            oggettoImposte.maggTARES = null

            BindUtils.postNotifyChange(null, null, this, "oggettoImposte")
        }
    }

    private def recuperaSupDaDM(boolean openDialog = true) {
        def filtri = [
                sezione   : oggettoContribuente.oggettoPratica.oggetto.sezione,
                foglio    : oggettoContribuente.oggettoPratica.oggetto.foglio,
                numero    : oggettoContribuente.oggettoPratica.oggetto.numero,
                subalterno: oggettoContribuente.oggettoPratica.oggetto.subalterno
        ]

        listaDatiMetrici = contribuentiService.caricaDatiMetrici(filtri, [max: 999999, offset: 0, activePage: 0], [[property: 'uiu.idUiu', direction: 'asc']]).record

        if (listaDatiMetrici.empty) {
            Clients.showNotification("Nessuna informazione presente nei dati metrici", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        } else if (listaDatiMetrici.size() == 1) {
            oggettoContribuente.oggettoPratica.consistenza = DM_RID == 'S' ? (listaDatiMetrici[0].superficieNum ?: 0) * (percRiduzioneSuperficie) / 100 : (listaDatiMetrici[0].superficieNum ?: 0)
            flagDaDatiMetrici = true
            flagRiduzioneSuperficie = (DM_RID == 'S')

            BindUtils.postNotifyChange(null, null, this, "flagRiduzioneSuperficie")
            BindUtils.postNotifyChange(null, null, oggettoContribuente.oggettoPratica, "consistenza")
            BindUtils.postNotifyChange(null, null, this, "flagDaDatiMetrici")
        } else if (openDialog) {
            showDatiMetriciOggetto = true

            BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
            BindUtils.postNotifyChange(null, null, this, "showDatiMetriciOggetto")
        }
    }

    boolean getModificaAbPriARuolo() {

        // Se siamo in sola lettura
        if (solaLettura) {
            return false
        }

        // Il flag è modificabile sempre se l'ogpr non è inviato a ruolo oppure
        // se è inviato a ruolo ed è espressamente richiesto
        return !ogprInviatoARuolo ||
                (ogprInviatoARuolo && modificaFAbPriInviatoARuolo)
    }

    private riempiCategoria(def reset = false) {
        if (oggettoContribuente?.oggettoPratica?.codiceTributo?.id) {
            listaCategorie = [new CategoriaDTO()] + denunceService.getCategorie(oggettoContribuente.oggettoPratica.codiceTributo.id)
        } else {
            listaCategorie = [new CategoriaDTO()]
        }

        // Si resetta il valore associato alla categoria ed alla tariffa
        if (reset) {
            oggettoContribuente.oggettoPratica.categoria = null
            BindUtils.postNotifyChange(null, null, oggettoContribuente, "oggettoPratica.categoria")
        }

        riempiTariffa(reset)

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    private riempiTariffa(def reset = false) {
        if (oggettoContribuente?.oggettoPratica?.categoria?.id) {
            listaTariffe = [new TariffaDTO()] +
                    denunceService.getTariffe(oggettoContribuente.oggettoPratica.categoria.id,
                            oggettoContribuente.oggettoPratica.pratica.anno).sort { it.id }

        } else {
            listaTariffe = [new TariffaDTO()]
        }

        // Si resetta il valore associato alla tariffa
        if (reset) {
            oggettoContribuente.oggettoPratica.tariffa = null
            BindUtils.postNotifyChange(null, null, oggettoContribuente, "oggettoPratica.tariffa")
        }

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
    }

    private caricaImmobile(int index) {
        listaRuoli = []
        listaPartizioni = []
        oggettoContribuente = listaOggetti.get(index)
        caricaDettagliImmobile()
        selectedTab = 0

        caricaCodiciRfid()

        initModel()

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
        BindUtils.postNotifyChange(null, null, this, "listaPartizioni")
        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
        BindUtils.postNotifyChange(null, null, this, "isAbitazionePrincipale")
        BindUtils.postNotifyChange(null, null, this, "parametriBandbox")
        BindUtils.postNotifyChange(null, null, this, "selectedTab")
        BindUtils.postNotifyChange(null, null, this, "activeItem")
        BindUtils.postNotifyChange(null, null, this, "oggettoContribuente")
    }

    private caricaDettagliImmobile() {
        listaPartizioni = denunceService.getPartizioni(oggettoContribuente.oggettoPratica.id)

        isAbitazionePrincipale = OggettoPratica.createCriteria().count {
            eq("oggettoPraticaRifAp.id", oggettoContribuente.oggettoPratica.id)
        } > 0

        //setto valori per bandbox pertinenze
        parametriBandbox.anno = oggettoContribuente.oggettoPratica.pratica.anno
        parametriBandbox.codFiscale = oggettoContribuente.contribuente.codFiscale
        parametriBandbox.oggettoPratica = oggettoContribuente.oggettoPratica.id
        parametriBandbox.oggettoPraticaRifAp = oggettoContribuente.oggettoPratica.oggettoPraticaRifAp?.id
        parametriBandbox.oggettoId = oggettoContribuente.oggettoPratica.oggettoPraticaRifAp ? String.valueOf(oggettoContribuente.oggettoPratica.oggettoPraticaRifAp?.oggetto?.id) : null

        //serve una stringa per assegnarlo al parametro custom della bandbox
        parametriBandbox.tipoTributo = this.pratica.tipoTributo.tipoTributo

        oggettoContribuente.oggettoPratica.consistenza = preVal?.superficie ?: oggettoContribuente.oggettoPratica.consistenza

        riempiCategoria()
        riempiTariffa()
    }

    private boolean validaMaschera() {

        def warning = []
        def errori = []

        def today = Calendar.getInstance().getTime()

        // Bloccanti
        if (!oggettoContribuente.oggettoPratica.consistenza) {
            errori << "Campo 'Superficie' non valorizzato."
        }

        if (oggettoContribuente.oggettoPratica.pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.V, TipoEventoDenuncia.U]) {
            if (!oggettoContribuente.dataDecorrenza) {
                errori << "Campo 'Data decorrenza' non valorizzato."
            }
        }
        if (pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            if (oggettoContribuente.oggettoPratica.tipoOccupazione == TipoOccupazione.T) {
                if (!oggettoContribuente.dataCessazione) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
            }
        } else {
            if (oggettoContribuente.oggettoPratica.pratica.tipoEvento in [TipoEventoDenuncia.C, TipoEventoDenuncia.U]) {
                if (!oggettoContribuente.dataCessazione) {
                    errori << "Campo 'Data cessazione' non valorizzato."
                }
            }
        }

        if (!oggettoContribuente.oggettoPratica.codiceTributo) {
            errori << "Campo 'Cod. Tributo' non valorizzato."
        }

        if (!oggettoContribuente.oggettoPratica.categoria) {
            errori << "Campo 'Categoria' non valorizzato."
        }

        if (!oggettoContribuente.oggettoPratica.tariffa || !oggettoContribuente.oggettoPratica.tariffa.id) {
            errori << "Campo 'Tariffa' non valorizzato."
        }

        // Se siamo in inserimento o vengono modificate le date di decorrenza e/o cessazione
        if (oggettoContribuente.oggettoPratica.id == null ||
                oldDataDecorrenza != oggettoContribuente.dataDecorrenza || oldDataCessazione != oggettoContribuente.dataCessazione) {

            String message = checkPeriodiSovrapposti()

            if (!message.isEmpty()) {
                oggettoContribuente.dataDecorrenza = oldDataDecorrenza
                oggettoContribuente.dataCessazione = oldDataCessazione
                errori << message
            } else {
                oldDataDecorrenza = oggettoContribuente.dataDecorrenza
                oldDataCessazione = oggettoContribuente.dataCessazione
            }
        }

        def index = 1
        listaPartizioni.each {
            if (!it.tipoArea) {
                errori << "Partizioni #${index++}: campo 'tipoArea' non valorizzato."
            }
            if (it.numero == null) {
                errori << "Partizioni #${index++}: campo 'numero' non valorizzato."
            }
            if (it.consistenzaReale == null) {
                errori << "Partizioni #${index++}: campo 'consistenzaReale' non valorizzato."
            }
            if (it.consistenza == null) {
                errori << "Partizioni #${index++}: campo 'consistenza' non valorizzato."
            }
        }

        index = 1
        listaCodiciRfid.each {
            if (!it.codRfid) {
                errori << "RFID #${index++}: Cod.RFID obbligatorio"
            } else if (!it.contenitore) {
                errori << "RFID #${index++}: Cod.Contenitore obbligatorio"
            } else if ((!it.dataConsegna && it.dataRestituzione) || (it.dataConsegna && it.dataRestituzione && it.dataConsegna > it.dataRestituzione)) {
                errori << "RFID #${index++}: Data Consegna e Data Restituzione non coerenti"
            } else if (listaCodiciRfid.findAll { crfid -> crfid.codRfid == it.codRfid }.size() > 1) {
                errori << "RFID #${index++}: Cod.RFID duplicato"
            }
        }

        // Controlli specifici per tipo occupazione
        if (pratica.tipoPratica != TipoPratica.A.tipoPratica) {
            if (oggettoContribuente.oggettoPratica.tipoOccupazione == TipoOccupazione.T) {
                def occupazioneDa = oggettoContribuente.dataCessazione ?: today
                def occupazioneA = oggettoContribuente.dataDecorrenza ?: today
                // Il periodo di occupazione non può essere superiore a 183 giorni
                // La presenza delle date è verificata più su nel codice
                if ((occupazioneDa - occupazioneA) > 183) {
                    errori << "Occupazione superiore a 183 giorni"
                }
            }
        }

        // Non bloccanti
        if (!listaPartizioni.empty && listaPartizioni*.consistenza.sum() != oggettoContribuente.oggettoPratica.consistenza) {
            warning << "Il totale della Superficie delle Ripartizioni non corrisponde alla Superficie dell'Oggetto"
        }

        def warningPeriodiSovrappostiOggetto = checkPeriodiSovrappostiOggetto()
        if (warningPeriodiSovrappostiOggetto) {
            warning << warningPeriodiSovrappostiOggetto
        }

        // Si visualizzano i messaggi di errore
        if (!errori.empty) {
            errori.add(0, "Impossibile salvare l'oggetto:")
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        } else {
            // Se non ci sono errori si visualizzano evantuali warning
            if (!warning.empty) {
                warning.add(0, "Attenzione:")
                Clients.showNotification(warning.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            }
        }

        return true
    }

    def checkPeriodiSovrapposti() {

        String message = ""

        if (pratica.tipoPratica != TipoPratica.A.tipoPratica) {

            def periodiOggetto = denunceService.fCheckPeriodiOggetto(oggettoContribuente.contribuente.codFiscale,
                    oggettoContribuente.oggettoPratica.oggetto.id,
                    pratica.tipoTributo.tipoTributo, pratica.tipoPratica,
                    pratica.tipoEvento.tipoEventoDenuncia, pratica.anno,
                    oggettoContribuente.dataDecorrenza, oggettoContribuente.dataCessazione,
                    oggettoContribuente.oggettoPratica.id,
                    oldDataDecorrenza, oldDataCessazione,
                    (oggettoContribuente.oggettoPratica.id == null) ? 'I' : 'V')

            if (!periodiOggetto.isEmpty()) {
                message += "Esistono periodi sovrapposti\n" +
                        "L'oggetto risulta dichiarato da"
                periodiOggetto.each { periodo ->
                    def contribuente = Contribuente.findByCodFiscale(periodo.COD_FISCALE).toDTO(['soggetto'])
                    message += "\n$contribuente.soggetto.cognomeNome $contribuente.soggetto.codFiscale - Pratica $periodo.PRATICA - Anno $periodo.ANNO"
                }
            }
        } else {

            def localiEAree = denunceService.getOggettiPratica(pratica.id)

            def oggEsistente = localiEAree.find { it.oggettoPratica.id == oggettoContribuente.oggettoPratica.id }
            if (oggEsistente) {
                localiEAree.remove(oggEsistente)
            }
            localiEAree.add(oggettoContribuente)

            def report = liquidazioniAccertamentiService.verificaPeriodiIntersecati(localiEAree)

            if (report.result > 0) {
                message += report.message
            }
        }

        return message
    }

    def checkPeriodiSovrappostiOggetto() {
        String message = ""
        def periodiOggetto = denunceService.fCheckPeriodiOggetto(
                null,
                oggettoContribuente.oggettoPratica.oggetto.id,
                pratica.tipoTributo.tipoTributo, pratica.tipoPratica,
                pratica.tipoEvento.tipoEventoDenuncia, pratica.anno,
                oggettoContribuente.dataDecorrenza, oggettoContribuente.dataCessazione,
                oggettoContribuente.oggettoPratica.id,
                oldDataDecorrenza, oldDataCessazione,
                (oggettoContribuente.oggettoPratica.id == null) ? 'I' : 'V')

        if (!periodiOggetto.isEmpty()) {
            message += "Esistono periodi intersecanti per l'oggetto $oggettoContribuente.oggettoPratica.oggetto.id\n" +
                    "L'oggetto risulta dichiarato da"
            periodiOggetto.each { periodo ->
                def contribuente = Contribuente.findByCodFiscale(periodo.COD_FISCALE).toDTO(['soggetto'])
                message += "\n$contribuente.soggetto.cognomeNome $contribuente.soggetto.codFiscale - Pratica $periodo.PRATICA - Anno $periodo.ANNO"
            }
        }

        return message
    }

    private eliminaPartizione(def part) {
        listaPartizioni = listaPartizioni.findAll { it.uuid != part.uuid }
        BindUtils.postNotifyChange(null, null, this, "listaPartizioni")
    }

    def ricalcolaImposteOggetto() {

        if (this.pratica.tipoPratica == TipoPratica.A.tipoPratica) {
            ricalcolaImposteOggettoAcc()
        }
    }

    def ricalcolaImposteOggettoAcc() {

        def parametri = [:]

        def report = liquidazioniAccertamentiService.verificaFamiliariAccertamentoTarsu(pratica, oggettoContribuente)
        if (report.result > 0) {
            String message = "Attenzione : " + report.message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
        }

        liquidazioniAccertamentiService.calcolaAccertamentoManualeOgCo(pratica.anno, parametri, pratica, oggettoContribuente)

        leggiImposteOggetto()
    }

    def leggiImposteOggetto() {

        oggettoImposte = liquidazioniAccertamentiService.getImpostaOggPrTarsu(oggettoContribuente?.oggettoPratica?.id ?: 0, pratica.anno, pratica?.contribuente?.codFiscale ?: '-')
        BindUtils.postNotifyChange(null, null, this, "oggettoImposte")
    }

    private inizializzaInterfaccia() {

        // Se si ha la sola abilitazione in lettura
        if (solaLettura) {
            componenti.each {
                it.disabled = true
            }
            return
        }

        componenti = componenti.findAll { !it.id?.empty }

        // Apertura in modifica
        if (oggettoContribuente.oggettoPratica.id != null) {

            def fOgPrInviato = denunceService.fOgPrInviato(oggettoContribuente.oggettoPratica.id)
            def fCessazioniRuolo = denunceService.fCessazioniRuolo(
                    oggettoContribuente.contribuente.codFiscale,
                    oggettoContribuente.oggettoPratica.id,
                    this.pratica.anno)

            // In caso di denuncia di variazione o iscrizione, se l'oggetto_pratica e' presente in un ruolo inviato a consorzio
            if (oggettoContribuente.oggettoPratica.pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.V]) {
                componentById(ID_COMPONENTI.CMB_CATEGORIA).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.CMB_TARIFFA).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.CMB_TRIBUTO).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.DAT_INIZIO_OCCUPAZIONE).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.DAT_INIZIO_DECORRENZA).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.DEC_SUPERFICIE).disabled = fOgPrInviato || flagDaDatiMetrici
                componentById(ID_COMPONENTI.DEC_PERC_POSS).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.INT_NUM_FAM).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.FLAG_DA_DM).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.FLAG_RID_SUP).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.FLAG_ANNULLATA).disabled = fOgPrInviato
                imgDaDMVisible = !fOgPrInviato

                // Sempre disabilitato per tipo_evento != C
                componentById(ID_COMPONENTI.DAT_FINE_OCCUPAZIONE).disabled = true
                componentById(ID_COMPONENTI.DAT_CESSAZIONE).disabled = true

            } else if (oggettoContribuente.oggettoPratica.pratica.tipoEvento == TipoEventoDenuncia.C) {
                // Se pratica di cessazione ed esistono sgravi o la pratica è a ruolo
                componentById(ID_COMPONENTI.CMB_CATEGORIA).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.CMB_TARIFFA).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.CMB_TRIBUTO).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.DAT_FINE_OCCUPAZIONE).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.DAT_CESSAZIONE).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.DEC_SUPERFICIE).disabled = fCessazioniRuolo || flagDaDatiMetrici
                componentById(ID_COMPONENTI.DEC_PERC_POSS).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.INT_NUM_FAM).disabled = fCessazioniRuolo
                componentById(ID_COMPONENTI.FLAG_DA_DM).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.FLAG_RID_SUP).disabled = fOgPrInviato
                componentById(ID_COMPONENTI.FLAG_ANNULLATA).disabled = fOgPrInviato
                imgDaDMVisible = !fOgPrInviato

                // Sempre disabilitato per le cessazioni
                componentById(ID_COMPONENTI.DAT_INIZIO_OCCUPAZIONE).disabled = true
                componentById(ID_COMPONENTI.DAT_INIZIO_DECORRENZA).disabled = true
            } else if (oggettoContribuente.oggettoPratica.pratica.tipoEvento == TipoEventoDenuncia.U) {
                // Al momento nulla da fare
            }
        } else {
            // Inserimento

            if (oggettoContribuente.oggettoPratica.pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.V]) {
                // Sempre disabilitato per tipo_evento != C
                componentById(ID_COMPONENTI.DAT_FINE_OCCUPAZIONE).disabled = true
                componentById(ID_COMPONENTI.DAT_CESSAZIONE).disabled = true

            } else if (oggettoContribuente.oggettoPratica.pratica.tipoEvento == TipoEventoDenuncia.C) {
                // Sempre disabilitato per le cessazioni
                componentById(ID_COMPONENTI.DAT_INIZIO_OCCUPAZIONE).disabled = true
                componentById(ID_COMPONENTI.DAT_INIZIO_DECORRENZA).disabled = true
            } else if (oggettoContribuente.oggettoPratica.pratica.tipoEvento == TipoEventoDenuncia.U) {
                // Al momento nulla da fare
            }
        }

        BindUtils.postNotifyChange(null, null, this, "imgDaDMVisible")
    }

    private componentById(String id) {
        return componenti.find { it.id == id }
    }

    private nuovaPartizione(Long idOgPr, PartizioneOggettoPraticaDTO partDaDuplicare = null) {
        OggettoPraticaDTO ogpr = OggettoPratica.get(idOgPr)?.toDTO(['partizioniOggettoPratica'])
        PartizioneOggettoPraticaDTO newPart = null

        if (!partDaDuplicare) {
            newPart = new PartizioneOggettoPraticaDTO([oggettoPratica: ogpr])
        } else {
            newPart = new PartizioneOggettoPraticaDTO(commonService.getObjProperties(partDaDuplicare, ['sequenza']))
        }

        newPart.sequenza = (listaPartizioni.collect { it.sequenza }.max() ?: 0) + 1

        return newPart
    }

    private nuovoCodiceRfid(def oggettoContribuente) {

        return new CodiceRfidDTO(
                contribuente: oggettoContribuente.contribuente,
                oggetto: oggettoContribuente.oggettoPratica.oggetto)
    }

    private duplicaCodRfid(def codiceRfidDaDuplicare) {
        return new CodiceRfidDTO(commonService.getObjProperties(codiceRfidDaDuplicare, ['codRfid']))
    }

    private eliminaCodiceRfid(def codiceRfid) {
        listaCodiciRfid = listaCodiciRfid.findAll { it.uuid != codiceRfid.uuid }
        BindUtils.postNotifyChange(null, null, this, "listaCodiciRfid")
    }

    private initModel() {

        model.oggettoPratica = oggettoContribuente.oggettoPratica.properties
        model.oggettoContribuente = oggettoContribuente.properties

        model.listaPartizioni = []
        listaPartizioni.each {
            model.listaPartizioni << partizioneToMap(it)
        }

        model.listaCodiciRfid = listaCodiciRfid.collect { commonService.clona(it) }

        aggiornaDataModifica()
        aggiornaUtente()
    }

    private boolean isDirty() {

        def isDirty = model.oggettoPratica != oggettoContribuente.oggettoPratica.properties ||
                model.oggettoContribuente != oggettoContribuente.properties

        // Se le proprietà di oggettoPratica non sono state modificate si controllano le partizioni
        if (!isDirty) {

            if (listaPartizioni.size() != model.listaPartizioni?.size()) {
                isDirty = true
            } else {
                listaPartizioni.each { pop ->

                    def oldPartizione = model.listaPartizioni.find { it.uuid == pop.uuid }

                    // Se non è presente è stata aggiunta
                    if (oldPartizione == null) {
                        isDirty = true
                        return
                    }

                    partizioneToMap(pop).each {
                        if (it.value != oldPartizione[it.key]) {
                            isDirty = true
                            return
                        }
                    }
                    if (isDirty) {
                        return
                    }
                }
            }

            if (listaCodiciRfid.size() != model.listaCodiciRfid?.size()) {
                isDirty = true
            } else {
                listaCodiciRfid.each { cod ->

                    def oldCodiceRfid = codiceRfidToMap(model.listaCodiciRfid.find { it.uuid == cod.uuid })

                    // Se non è presente è stato aggiunto
                    if (oldCodiceRfid == null) {
                        isDirty = true
                        return
                    }

                    codiceRfidToMap(cod).each {
                        if (it.value != oldCodiceRfid[it.key]) {
                            isDirty = true
                            return
                        }
                    }
                    if (isDirty) {
                        return
                    }
                }
            }
        }

        return isDirty
    }

    private partizioneToMap(def partizione) {
        def props = partizione?.properties
        props.note = props.note ?: ''
        props.tipoArea = partizione?.tipoArea?.id
        props.remove('domainObject')
        return props
    }

    private codiceRfidToMap(def codiceRfid) {
        def props = codiceRfid?.properties
        props.codRfid = props.codRfid ?: ''
        props.contenitore = props.contenitore?.id
        props.remove('domainObject')
        return props
    }

    @Command
    void onApriPopupNote(@ContextParam(ContextType.COMPONENT) Popup popupNote) {
        this.popupNote = popupNote

        def index = this.popupNote.getId().replace('popupNote_', '') as Integer
        def savedNote = listaCodiciRfid[index].note

        Textbox textbox = this.popupNote.query('textbox') as Textbox
        textbox.setValue(savedNote)
    }

    @Command
    void onChiudiPopupNote() {
        Textbox textbox = this.popupNote.query('textbox') as Textbox
        def tempNote = textbox.getValue().toUpperCase()

        def index = this.popupNote.getId().replace('popupNote_', '') as Integer
        listaCodiciRfid[index].note = tempNote

        BindUtils.postNotifyChange(null, null, this, 'listaCodiciRfid')

        this.popupNote.close()
    }

    private determinaTipoOccupazione(pratica) {
        return pratica.tipoPratica == TipoPratica.A.tipoPratica ? TipoOccupazione.P :
                pratica.tipoEvento == TipoEventoDenuncia.U ? TipoOccupazione.T : TipoOccupazione.P
    }
}
