package sportello.contribuenti

import document.FileNameGenerator
import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.dto.DTO
import it.finmatica.tr4.*
import it.finmatica.tr4.aliquote.AliquoteService
import it.finmatica.tr4.calcoloindividuale.CalcoloIndividualeBean
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.CalcoloService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.imposte.DetrazioniService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.reports.F24Service
import it.finmatica.tr4.soggetti.SoggettiService
import it.finmatica.tr4.sportello.TipoOggettoCalcolo
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.text.SimpleDateFormat

class CalcoloIndividualeViewModel {

    // services
    SpringSecurityService springSecurityService
    CompetenzeService competenzeService
    ContribuentiService contribuentiService
    CalcoloService calcoloService
    DetrazioniService detrazioniService
    SoggettiService soggettiService
    OggettiService oggettiService
    AliquoteService aliquoteService
    F24Service f24Service
    JasperService jasperService
    TributiSession tributiSession
    ServletContext servletContext
    Ad4EnteService ad4EnteService

    // componenti
    Window self

    // dati
    SoggettoDTO soggetto
    PraticaTributoDTO praticaK

    boolean isDirty = false

    boolean letturaICI            // Uno dei due DEVE essere FALSE, da verificare prima di aprire questa form
    boolean letturaTASI

    List<TipoOggettoDTO> listaTipiOggetto
    List<CategoriaCatastoDTO> listaCategorie
    def listaTipiRapporto = [[valore       : "D"
                              , descrizione: "Proprietario"]
                             , [valore       : "A"
                                , descrizione: "Occupante"]
    ]

    Short anno
    List<TipoAliquotaDTO> listaTipiAliquota
    List<OggettoImpostaDTO> listaOggetti    //tab Oggetti (lista di oggettiImposta della pratica)
    List<OggettoImpostaDTO> listaOggettiEliminati = []
    def listaImposte    //tab Imposta
    OggettoImpostaDTO itemSelezionato
    OggettoImpostaDTO oggDaElaborare
    def immobileSelezionato    //riga in master tab dettagli
    def oggettoImpostaSelezionato
    HashSet<RiferimentoOggettoDTO> renditeOggetto
    def listaDettagliImposta    //tab dettagli
    def listaDettagliImmobile    //tab dettagli gruppo richiudibile
    def listaAcconti
    def listaSaldi
    def listaTotali
    Integer fasciaSoggetto
    boolean modificheDaSalvare = false
    boolean modificheAbilitate = true
    Date dataCalcolo
    String descrizioneTipoCalcolo = ''

    String rbTributi
    Long idCalcolo    //id tabella WEB_CALCOLO_INDIVIDUALE
    BigDecimal valoreTerreniRidotti
    BigDecimal detrazioneStd
    BigDecimal maxPercDetrazione

    int pageSize = 10
    int activePage = 0
    int totalSize = 0
    boolean miniImu = false
    boolean stampaVisibile = false
    boolean visualizzaRendite = false
    boolean visualizzaTabellaDettagli = true    //per visualizzare il detail di tab dettagli
    boolean miniImuVisible = false
    boolean isNuovo = false
    boolean contribuenteEsistente = true
    boolean visualizzaCarica = true
    boolean creaContatto = true
    def espandiDettagli = [:]
    def dettagliEspansi = false
    boolean disabilitaF24Unico = true
    String codFiscale
    int selectedTab
    List<OggettoPraticaDTO> listaPertinenze

    boolean salvaPerStampaF24 = false
    boolean versamentiPerAnno = false

    def aliqAcc = [:]

    def stampaParametri = [riepilogo: false, acconto: false, saldo: false, unico: false, imuTasi: false]

    @NotifyChange(["listaCategorie", "listaTipiRapporto", "rbTributi", "selectedTab", "contribuenteEsistente", "anno"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("idSoggetto") long idSoggetto
         , @ExecutionArgParam("tipoTributo") String tipoTributo
         , @ExecutionArgParam("tipoTributoPref") String tipoTributoPref
         , @ExecutionArgParam("annoSelezionato") short annoSelezionato) {

        this.self = w

        selectedTab = 0

        rbTributi = (tipoTributoPref == null) ? 'ICI' : tipoTributoPref

        letturaICI = !competenzeService.utenteAbilitatoScrittura('ICI')
        letturaTASI = !competenzeService.utenteAbilitatoScrittura('TASI')
        if (letturaICI && (rbTributi == 'ICI')) rbTributi = 'TASI'
        if (letturaTASI && (rbTributi == 'TASI')) rbTributi = 'ICI'

        //Viene definito l'anno già selezionato dal folder oggetti della SituazioneContribuente altrimenti anno corrente
        anno = annoSelezionato
        //Veniva preso in considerazione il tipo tributo dell'eventuale pratica selezionata
        //rbTributi = (tipoTributo == null || !tipoTributo.equals("TASI")) ? "ICI" : tipoTributo
        listaCategorie = CategoriaCatasto.findAllByFlagReale(true, [sort: "categoriaCatasto", order: "asc"]).toDTO()
        if (idSoggetto > 0) {
            // se il soggetto ha cf va creato un contribuente da cancellare poi alla fine
            Soggetto s = Soggetto.get(idSoggetto)
            soggetto = s.toDTO(["contribuenti", "comuneResidenza", "comuneResidenza.ad4Comune", "archivioVie"])
            // Il codice fiscale che deve essere usato per interrogare la situazione del contribuente è sempre quello della tabella CONTRIBUENTI.
            // Questo perché il soggetto potrebbe essere legato all'anagrafe e il codice fiscale potrebbe variare (incompleto, provvisorio, uguale ad un altro)
            contribuenteEsistente = soggetto.contribuente
            creaContatto = contribuenteEsistente //se il cont non esiste, non si crea mai il contatto
            //se il cont non esiste, ne creo uno di appoggio
            soggetto.contribuente = soggetto.contribuente ?: (calcoloService.creaContribuente(soggetto))
            codFiscale = soggetto.contribuente.codFiscale
        } else {
            //soggetto = new SoggettoDTO(id: idSoggetto)
            // TODO gestione errore se il soggetto non esiste
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {

                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event

                    if ("versatoAcconto" == pe.property) {
                        salvaPerStampaF24 = true
                        isDirty = true
                        BindUtils.postNotifyChange(null, null, CalcoloIndividualeViewModel.this, "isDirty")
                    } else if (pe.base.class && DTO.class.isAssignableFrom(pe.base.class)) {

                        switch (pe.base.class) {
                            case OggettoContribuenteDTO.class:
                                isDirty |= (OggettoContribuente.metaClass.hasProperty(OggettoContribuente.class, pe.property) ? true : false)
                                break
                            case OggettoImpostaDTO.class:
                                isDirty |= (OggettoImposta.metaClass.hasProperty(OggettoImposta.class, pe.property) ? true : false)
                                break
                            case OggettoPraticaDTO.class:
                                isDirty |= (OggettoPraticaDTO.metaClass.hasProperty(OggettoPraticaDTO.class, pe.property) ? true : false)
                                break
                        }
                        BindUtils.postNotifyChange(null, null, CalcoloIndividualeViewModel.this, "isDirty")
                    }
                }
            }
        })
    }

    @Command
    onChiudiPopup() {

        if (isDirty) {
            Map params = new HashMap()
            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO, Messagebox.Button.CANCEL]
            Messagebox.show("Salvare le modifiche?", "Attenzione", buttons, null, Messagebox.QUESTION, null,
                    new EventListener() {
                        void onEvent(Event e) {
                            switch (e.getName()) {
                                case Messagebox.ON_YES:
                                    onSalvaEChiudi()
                                    break
                                case Messagebox.ON_NO:
                                    Events.postEvent(Events.ON_CLOSE, self, null)
                                    break
                                case Messagebox.ON_CANCEL:
                                    return
                            }
                        }
                    }, params)
        } else {
            Events.postEvent(Events.ON_CLOSE, self, null)
        }
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    //SC 12/03/2015 Prima di chiudere salva
    //per poi verificare se ci sono ancora oggetti nella pratica:
    //se non ce ne sono elimina la pratica.
    @Command
    onSalvaEChiudi() {
        if (onSalva()) {
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @NotifyChange(["modificheAbilitate"])
    @Command
    onUnlock() {
        modificheAbilitate = true
    }

    @NotifyChange(["visualizzaTabellaDettagli", "dataCalcolo", "modificheAbilitate",
            "listaOggetti", "miniImu", "detrazioneStd", "valoreTerreniRidotti"])
    @Command
    onCalcoloIndividuale(@BindingParam("miniImu") int miniImu) {

        //verificaOggetti restituisce true se ci sono oggetti non validi
        if (verificaOggetti()) {
            return
        }
        //onSalva restituisce true se ci sono ancora modifiche da salvare
        if (onSalva()) {
            return
        }
        this.miniImu = miniImu
        dataCalcolo = praticaK.data
        detrazioneStd = 0
        valoreTerreniRidotti = 0
        idCalcolo = calcoloService.proceduraCalcoloIndividuale(praticaK, this.miniImu)
        listaOggetti = calcoloService.refreshOggettiPraticaK(listaOggetti, praticaK)
        tributiSession.idWCIN = idCalcolo
        //Dato che la procedure del calcolo individuale
        //modifica anche dati visibili sul folder Oggetti (come la detrazione)
        //bisogna pulire la cache di hibernate e rileggerli
        //imposte per i vari tipi di oggetto
        componiListaImposte(idCalcolo)
        //valore dei terreni ridotti lo metto in una var a parte per farlo vedere in alto.
        selectedTab = 1
        listaDettagliImposta = calcoloService.dettagliPraticaKPerTipoECategoria(praticaK.id)
        visualizzaTabellaDettagli = true
        modificheAbilitate = false
        disabilitaF24Unico = listaImposte.size() == 0 || !calcoloService.esisteCalcoloPerTipoTributoEData(praticaK)
        BindUtils.postNotifyChange(null, null, this, "listaDettagliImposta")
        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "disabilitaF24Unico")
        BindUtils.postNotifyChange(null, null, this, "selectedTab")
    }

    private verificaOggetti() {

        def messages = []
        boolean result = false

        listaOggetti.each {

            OggettoContribuenteDTO ogCo = it.oggettoContribuente;

			if(ogCo.flagEsclusione) {
				Short mesiPossesso = (ogCo.mesiPossesso ?: 12) 
				if(mesiPossesso != (ogCo.mesiEsclusione ?: mesiPossesso)) {
					messages << "- Oggetto " + ogCo.oggettoPratica.oggetto.id + " in caso di Esclusione i mesi di Esclusione devono essere uguali ai Mesi Possesso."
                }
            }
        }

        if (!messages.isEmpty()) {
            String message = "Attenzione :\n\n" + messages.join("\n")
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 10000, true)
            result = true
        }

        return result
    }

    private componiListaImposte(long wCInId) {

        def notInList = [TipoOggettoCalcolo.DETRAZIONE]
        if (rbTributi.equals("TASI")) {
            notInList.add(TipoOggettoCalcolo.TERRENO)
            notInList.add(TipoOggettoCalcolo.FABBRICATO_D)
        }
        listaImposte = calcoloService.impostePraticaK(wCInId, notInList)

        WebCalcoloIndividuale wCIn = WebCalcoloIndividuale.get(wCInId)
        miniImu = ((wCIn?.tipoCalcolo) ?: "Normale").equals("Mini")

        totaliListaImposte()

        //riassegno notInList per la nuova query che calcola le detrazioni
        //e la detrazione standard (che facciamo vedere a parte in alto)
        notInList = [TipoOggettoCalcolo.TERRENO
                     , TipoOggettoCalcolo.FABBRICATO_D
                     , TipoOggettoCalcolo.AREA
                     , TipoOggettoCalcolo.ABITAZIONE_PRINCIPALE
                     , TipoOggettoCalcolo.RURALE
                     , TipoOggettoCalcolo.ALTRO_FABBRICATO
                     , TipoOggettoCalcolo.FABBRICATO_MERCE]
        def rigaDetrazione = calcoloService.impostePraticaK(wCInId, notInList)
        if (rigaDetrazione.size() > 0) {
            listaImposte.add(rigaDetrazione[0])
            detrazioneStd = (rigaDetrazione[0].saldoDetrazioneStd.equals(rigaDetrazione[0].saldoDetrazione ?: 0)) ? 0 : rigaDetrazione[0].saldoDetrazioneStd
        }
        //valore dei terreni ridotti lo metto in una var a parte per farlo vedere in alto.
        valoreTerreniRidotti = listaImposte[0].valoreTerreniRidotti ?: 0
        //return listaImposte
    }

    private totaliListaImposte() {

        if (versamentiPerAnno) {

            def versato = calcoloService.getVersato(this.codFiscale, this.anno, this.rbTributi)
            // println "Vers : ${versato}"

            def ravvedimento = calcoloService.getVersatoRavvedimenti(this.codFiscale, this.anno, this.rbTributi)
            // println "Ravv : ${ravvedimento}"

            for (def riga in listaImposte) {
                switch (riga.tipo) {
                    case TipoOggettoCalcolo.TERRENO:
                        riga.versatoAcconto = versato.terreniAgricoli + ravvedimento.terreniAgricoli
                        riga.versatoAccontoErario = versato.terreniErariale + ravvedimento.terreniErariale
                        break
                    case TipoOggettoCalcolo.FABBRICATO_D:
                        riga.versatoAcconto = versato.fabbricatiD + ravvedimento.fabbricatiD
                        riga.versatoAccontoErario = versato.fabbricatiDErariale + ravvedimento.fabbricatiDErariale
                        break
                    case TipoOggettoCalcolo.AREA:
                        riga.versatoAcconto = versato.areeFabbricabili + ravvedimento.areeFabbricabili
                        riga.versatoAccontoErario = versato.areeErariale + ravvedimento.areeErariale
                        break
                    case TipoOggettoCalcolo.ABITAZIONE_PRINCIPALE:
                        riga.versatoAcconto = versato.abPrincipale + ravvedimento.abPrincipale
                        break
                    case TipoOggettoCalcolo.RURALE:
                        riga.versatoAcconto = versato.rurali + ravvedimento.rurali
                        riga.versatoAccontoErario = versato.ruraliErariale + ravvedimento.ruraliErariale
                        break
                    case TipoOggettoCalcolo.ALTRO_FABBRICATO:
                        riga.versatoAcconto = versato.altriFabbricati + ravvedimento.altriFabbricati
                        riga.versatoAccontoErario = versato.altriErariale + ravvedimento.altriErariale
                        break
                    case TipoOggettoCalcolo.FABBRICATO_MERCE:
                        riga.versatoAcconto = versato.fabbricatiMerce + ravvedimento.fabbricatiMerce
                        break
                }
                def totale = (riga.saldo ?: 0) + (riga.acconto ?: 0)
                if ((riga.versatoAcconto) && (totale != 0)) {
                    riga.saldo = totale - (riga.versatoAcconto ?: 0)
                    riga.acconto = riga.versatoAcconto
                }
                totale = (riga.saldoErario ?: 0) + (riga.accontoErario ?: 0)
                if ((riga.versatoAccontoErario) && (totale != 0)) {
                    riga.saldoErario = totale - (riga.versatoAccontoErario ?: 0)
                    riga.accontoErario = riga.versatoAccontoErario
                }

                // if (riga.versatoAcconto == 0) riga.versatoAcconto = null
                // if (riga.versatoAccontoErario == 0) riga.versatoAccontoErario = null

                // Si salvano i dati per una corretta stampa del modello F24
                def dett = WebCalcoloDettaglio.get(riga.idDettaglio)
                if (dett) {
                    dett.versAcconto = riga.versatoAcconto
                    dett.versAccontoErar = riga.versAccontoErar
                    dett.acconto = riga.acconto
                    dett.accontoErar = riga.accontoErario
                    dett.saldo = riga.saldo
                    dett.saldoErar = riga.saldoErario
                    dett.save(failOnError: true, flush: true)
                }
            }
        }

        //calcolo i totali per tipo oggetto
        def rigaTotali = [idDettaglio           : 0
                          , tipo                : TipoOggettoCalcolo.TOTALE
                          , versatoAcconto      : 0
                          , versatoAccontoErario: 0
                          , acconto             : 0
                          , accontoErario       : 0
                          , saldo               : 0
                          , saldoErario         : 0
                          , numFabbricati       : null
                          , totaleFabbricati    : 0
                          , valoreTerreniRidotti: 0
                          , saldoDetrazioneStd  : 0]

        for (def rigaImposta in listaImposte) {
            rigaTotali.versatoAcconto += (rigaImposta.versatoAcconto ?: 0).toBigDecimal()
            rigaTotali.versatoAccontoErario += (rigaImposta.versatoAccontoErario ?: 0).toBigDecimal()
            rigaTotali.acconto += (rigaImposta.acconto ?: 0).toBigDecimal()
            rigaTotali.accontoErario += (rigaImposta.accontoErario ?: 0).toBigDecimal()
            rigaTotali.saldo += (rigaImposta.saldo ?: 0).toBigDecimal()
            rigaTotali.saldoErario += (rigaImposta.saldoErario ?: 0).toBigDecimal()
            rigaTotali.numFabbricati = (int) rigaImposta.totaleFabbricati
            rigaTotali.tipoDescrizione = TipoOggettoCalcolo.TOTALE.descrizione
            rigaTotali.codiceTributoComune = ""
            rigaTotali.codiceTributoStato = ""
        }
        if (rigaTotali.versatoAcconto == 0) rigaTotali.versatoAcconto = null
        if (rigaTotali.versatoAccontoErario == 0) rigaTotali.versatoAccontoErario = null
        listaImposte.add(rigaTotali)
    }

    @Command
    onCaricaPraticaK() {

        // Caso di calcolo per non conbtribuente, se non è presente si crea
        if (!Contribuente.findByCodFiscale(soggetto.contribuente.codFiscale)) {
            calcoloService.creaContribuente(Soggetto.get(soggetto.id).toDTO())
        }

        Map params = new HashMap()
        params.put("width", "600")

        def pk = calcoloService.esistePraticaK(rbTributi, anno, soggetto)
        def data = (pk?.contattoContribuente ? pk.contattoContribuente?.data : calcoloService.recuperaUltimoContatto(rbTributi, anno, soggetto.codFiscale)?.data) ?
                new SimpleDateFormat("dd/MM/yyyy").format(pk?.contattoContribuente ? pk.contattoContribuente?.data : calcoloService.recuperaUltimoContatto(rbTributi, anno, soggetto.codFiscale)?.data) :
                null
        if (!creaContatto && pk && data) {

            String triburo = TipoTributo.get(rbTributi).getTipoTributoAttuale(anno)

            Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
            Messagebox.show("""
                                        E’ presente un calcolo individuale $triburo per l'anno $anno del $data
                                        Proseguire eliminando il precedente calcolo e lavorare senza la registrazione di un nuovo contatto?
                    """,
                    "Attenzione",
                    buttons,
                    null,
                    Messagebox.QUESTION,
                    null,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_NO.equals(e.getName())) {
                                creaContatto = true
                                caricaPraticaK(calcoloService.lanciaCaricaPraticaK(rbTributi, anno, dataCalcolo, soggetto
                                        , praticaK, listaOggetti, creaContatto))
                            } else {
                                caricaPraticaK(calcoloService.lanciaCaricaPraticaK(rbTributi, anno, dataCalcolo, soggetto
                                        , praticaK, listaOggetti, creaContatto))
                            }
                        }
                    },
                    params
            )
        } else {
            try {
                caricaPraticaK(calcoloService.lanciaCaricaPraticaK(rbTributi, anno, dataCalcolo, soggetto
                        , praticaK, listaOggetti, creaContatto))
            } catch (Exception e) {
                if (e instanceof Application20999Error) {
                    Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
                    return false
                } else {
                    throw e
                }
            }

        }

        isDirty = false
        BindUtils.postNotifyChange(null, null, this, "isDirty")
    }

    def caricaPraticaK(def ret) {

        List<AliquotaDTO> aliquote = OggettiCache.ALIQUOTE.valore
        //verifica se ci sono aliquote
        if (!(aliquote.findAll {
            it.tipoAliquota.tipoTributo.tipoTributo == "ICI" && it.anno == anno
        })) {
            Clients.showNotification("Aliquote non presenti per l'anno " + anno, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }
        //verifica se ci sono i moltiplicatori

        List<MoltiplicatoreDTO> moltiplicatori = OggettiCache.MOLTIPLICATORI.valore

        if (!(moltiplicatori.find {
            it.anno == anno
        })) {
            Clients.showNotification("Moltiplicatori non presenti per l'anno " + anno, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }
        //la fascia serve per abilitare la modifica di alcuni campi di oggetti_imposta
        //della pratica K che verra' caricata. Il valore dipende dall'anno
        //quindi si ricalcola.
        listaTipiOggetto = OggettiCache.TIPI_OGGETTO.valore.findAll {
            rbTributi in it.oggettiTributo.tipoTributo.tipoTributo
        }
        listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll {
            it.tipoTributo.tipoTributo == rbTributi && anno in it.aliquote.anno
        }
        fasciaSoggetto = soggettiService.fasciaPerData(soggetto.id, java.sql.Date.valueOf(anno + "-01-01"))

        praticaK = ret.pratica
        dataCalcolo = ret.data

        descrizioneTipoCalcolo = dataCalcolo == null ? 'Nuovo Calcolo' : 'Del ' + dataCalcolo.format('dd/MM/yyyy')

        listaOggetti = ret.listaOggetti
        WebCalcoloIndividualeDTO wCIn = praticaK.webCalcoloIndividuale
        idCalcolo = wCIn?.id
        listaImposte = wCIn ? componiListaImposte(idCalcolo) : []
        //listaImposte				= []
        listaDettagliImposta = calcoloService.dettagliPraticaKPerTipoECategoria(praticaK.id)
        visualizzaRendite = false
        visualizzaTabellaDettagli = true
        listaPertinenze = contribuentiService.listaPertinenze(praticaK.anno, soggetto.contribuente.codFiscale, praticaK.
                tipoTributo.tipoTributo, "WEB")
        modificheAbilitate = listaImposte.size() == 0
        visualizzaCarica = false

        gestioneContatti()

        creaAliqAcc()

        if (anno >= 2012) {

            listaOggetti.each {
                it ->
                    //gestioneAliquota(it.tipoAliquota, it)
                    if (it.tipoAliquotaPrec == null) {

                        it.tipoAliquotaPrec = it.tipoAliquota

                        def aliq = aliquoteService.aliquoteLookUp(anno
                                , it.tipoAliquota
                                , fasciaSoggetto
                                , java.sql.Date.valueOf(anno + "-01-01")
                                , it.oggettoContribuente.oggettoPratica.categoriaCatasto?.categoriaCatasto
                                , null
                                , it.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp
                                , praticaK.contribuente.codFiscale)

                        it.aliquotaPrec = aliq.aliquotaAcconto * 100
                        it.aliquotaErarPrec = aliq.aliquotaErariale

                        it.oggettoContribuente.oggettoPratica.indirizzoOcc = ((it.tipoAliquotaPrec?.tipoAliquota) ?: 0).toString().padLeft(2, "0") +
                                ((Long) ((it.aliquotaPrec) ?: 0)).toString().padLeft(6, '0') +
                                ((Long) (it.detrazionePrec ?: 0) * 100).toString().padLeft(15, '0') +
                                ((Long) (it.aliquotaErarPrec ?: 0) * 100).toString().padLeft(6, '0')
                    }
            }
        }

        Clients.evalJavaScript("grepCommaDecimal()")

        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "fasciaSoggetto")
        BindUtils.postNotifyChange(null, null, this, "praticaK")
        BindUtils.postNotifyChange(null, null, this, "dataCalcolo")
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaTipiOggetto")
        BindUtils.postNotifyChange(null, null, this, "listaTipiAliquota")
        BindUtils.postNotifyChange(null, null, this, "listaDettagliImposta")
        BindUtils.postNotifyChange(null, null, this, "visualizzaRendite")
        BindUtils.postNotifyChange(null, null, this, "visualizzaTabellaDettagli")
        BindUtils.postNotifyChange(null, null, this, "modificheAbilitate")
        BindUtils.postNotifyChange(null, null, this, "visualizzaCarica")
        BindUtils.postNotifyChange(null, null, this, "miniImu")
        BindUtils.postNotifyChange(null, null, this, "descrizioneTipoCalcolo")
        BindUtils.postNotifyChange(null, null, this, "listaPertinenze")
        BindUtils.postNotifyChange(null, null, this, "creaContatto")
    }

    @NotifyChange(["listaImposte", "praticaK", "dataCalcolo"
            , "listaOggetti"
            , "listaDettagliImposta", "visualizzaRendite", "visualizzaTabellaDettagli"
            , "listaPertinenze", "modificheAbilitate", "disabilitaF24Unico"])
    @Command
    onRipristina() {
        listaOggettiEliminati = []
        calcoloService.cancellaPratica(praticaK, creaContatto)
        //la cancellazione della pratica potrebbe eliminare il contribuente
        //che ho creato al volo, in quando si partiva da un soggetto non contribuente.
        //quindi lo ricreo
        if (!contribuenteEsistente) {
            soggetto.contribuente = calcoloService.creaContribuente(soggetto)
        }
        def ret = calcoloService.ripristinaPraticaK(rbTributi
                , anno, dataCalcolo, codFiscale
                , praticaK, listaOggetti
                , creaContatto)

        praticaK = ret.pratica
        dataCalcolo = ret.data
        listaOggetti = ret.listaOggetti

        creaAliqAcc()

        idCalcolo = praticaK.webCalcoloIndividuale?.id
        listaImposte = []
        listaDettagliImposta = []
        visualizzaRendite = false
        visualizzaTabellaDettagli = true
        listaPertinenze = contribuentiService.listaPertinenze(praticaK.anno, soggetto.contribuente.codFiscale, praticaK.tipoTributo.tipoTributo, "WEB")
        modificheAbilitate = listaImposte.isEmpty()
        disabilitaF24Unico = true

        gestioneContatti()

        isDirty = false
        BindUtils.postNotifyChange(null, null, this, "isDirty")

        Clients.evalJavaScript("grepCommaDecimal()")
    }

    @Command
    onSelezioneAnnoOggetti() {
        listaOggetti = contribuentiService.oggettiContribuente(soggetto.contribuente.codFiscale, anno)
        //disabledSalva	= listaOggetti == null || listaOggetti?.isEmpty()
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        //	BindUtils.postNotifyChange(null, null, this, "disabledSalva")
    }

    @NotifyChange(["listaOggetti", "listaImposte"
            , "dataCalcolo", "praticaK"
            , "visualizzaRendite", "visualizzaTabellaDettagli"
            , "listaDettagliImposta", "miniImuVisible", "modificheAbilitate"
            , "visualizzaCarica"
            , "selectedTab", "disabilitaF24Unico"])
    @Command
    onChangeTipoTributo() {
        reset()
        if (!contribuenteEsistente) {
            soggetto.contribuente = calcoloService.creaContribuente(soggetto)
        }
        listaOggetti = []
        listaOggettiEliminati = []
        listaImposte = []
        listaDettagliImposta = []
        dataCalcolo = null
        praticaK = null
        visualizzaRendite = false
        visualizzaTabellaDettagli = false
        miniImuVisible = rbTributi.equals("ICI") && anno == 2013
        modificheAbilitate = true
        visualizzaCarica = true
        selectedTab = 0
        disabilitaF24Unico = true

        isDirty = false
        BindUtils.postNotifyChange(null, null, this, "isDirty")
    }

    @NotifyChange(["listaOggetti", "listaImposte"
            , "dataCalcolo", "praticaK"
            , "visualizzaRendite", "visualizzaTabellaDettagli"
            , "listaDettagliImposta", "miniImuVisible"
            , "rbTributi", "modificheAbilitate", "visualizzaCarica"
            , "selectedTab", "disabilitaF24Unico"])
    @Command
    onChangeAnno() {
        reset()
        if (!contribuenteEsistente) {
            soggetto.contribuente = calcoloService.creaContribuente(soggetto)
        }
        listaOggetti = []
        listaOggettiEliminati = []
        listaImposte = []
        listaDettagliImposta = []
        dataCalcolo = null
        praticaK = null
        visualizzaRendite = false
        visualizzaTabellaDettagli = false
        miniImuVisible = rbTributi.equals("ICI") && anno == 2013
        modificheAbilitate = true
        //TASI ha senso solo dal 2014 in poi
        if (((anno ?: 9999) < 2014) && rbTributi.equals("TASI")) {
            rbTributi = "ICI"
        }
        visualizzaCarica = true
        selectedTab = 0
        disabilitaF24Unico = true

        modificheDaSalvare = false

        isDirty = false
        BindUtils.postNotifyChange(null, null, this, "isDirty")

        BindUtils.postNotifyChange(null, null, this, "modificheDaSalvare")
        BindUtils.postNotifyChange(null, null, this, "modificheAbilitate")
    }

    @Command
    onChangePerAnno() {

        // Se si elimina il recupero del versato si effettua il ricalcolo
        if (!versamentiPerAnno) {
            onCalcoloIndividuale(miniImu ? 1 : 0)
        }

        componiListaImposte(idCalcolo)

        if (versamentiPerAnno) {
            listaImposte.each { imp ->
                if ((imp.acconto + imp.saldo > 0 || imp.versatoAcconto > 0) && !(imp.tipo == getTipoOggettoCalcolo('TOTALE')) && !(imp.tipo == getTipoOggettoCalcolo('DETRAZIONE'))) {
                    onChangeVersato(imp.idDettaglio)
                }
                if (rbTributi == 'ICI' && ((imp.accontoErario + imp.saldoErario > 0) || (imp.versatoAccontoErario > 0)) && !(imp.tipo == getTipoOggettoCalcolo('TOTALE')) && !(imp.tipo == getTipoOggettoCalcolo('DETRAZIONE'))) {
                    onChangeVersatoErario(imp.idDettaglio)
                }

            }
        }

        disabilitaF24Unico = listaImposte.size() == 0 || !calcoloService.esisteCalcoloPerTipoTributoEData(praticaK)

        BindUtils.postNotifyChange(null, null, this, "listaImposte")
        BindUtils.postNotifyChange(null, null, this, "disabilitaF24Unico")
    }

    @Command
    onNuovo() {
        listaOggetti*.selezionato = false
        itemSelezionato = null
        ricercaOggetto()
    }

    private creaAliqAcc() {
        aliqAcc = [:]
        listaOggetti.each {
            aliqAcc << [(it.oggettoContribuente.oggettoPratica.id): "${it?.tipoAliquota?.tipoAliquota ?: ''} - ${it?.tipoAliquota?.descrizione ?: ''}"]
        }
    }

    private void ricercaOggetto() {
        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self, [filtri: null, listaVisibile: true, inPratica: true, ricercaContribuente: false])
        w.doModal()
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Oggetto") {
                    OggettoDTO ogge = Oggetto.get(event.data.idOggetto).toDTO(["archivioVie"])
                    if (!OggettoTributo.findByTipoOggettoAndTipoTributo(ogge.tipoOggetto.getDomainObject(), TipoTributo.get(rbTributi))) {
                        Clients.showNotification("Impossibile utilizzare un oggetto di tipo " + ogge.tipoOggetto.tipoOggetto + " con pratiche di tipo " + praticaK?.tipoTributo?.tipoTributo, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                        return
                    }
                    if (ogge.dataCessazione && praticaK.anno > Integer.valueOf(new SimpleDateFormat("yyyy").format(ogge.dataCessazione))) {
                        Clients.showNotification("Anno della Pratica maggiore dell'Anno di Cessazione dell'Oggetto", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                        return
                    }
                    itemSelezionato = new OggettoImpostaDTO()
                    itemSelezionato.selezionato = true
                    new OggettoContribuenteDTO().addToOggettiImposta(itemSelezionato)
                    new OggettoPraticaDTO().addToOggettiContribuente(itemSelezionato.oggettoContribuente)
                    praticaK = praticaK ?: new PraticaTributoDTO()
                    praticaK.addToOggettiPratica(itemSelezionato.oggettoContribuente.oggettoPratica)
                    itemSelezionato.oggettoContribuente.contribuente = soggetto.contribuente
                    itemSelezionato.oggettoContribuente.oggettoPratica.oggetto = ogge
                    itemSelezionato.oggettoContribuente.oggettoPratica.tipoOggetto = ogge.tipoOggetto

                    def classificazione = oggettiService.getClassificazioneDaRiferimentiOggetto(ogge.id, praticaK.anno)
                    def categoriaRIOG = OggettiCache.CATEGORIE_CATASTO.valore.findAll { it.flagReale == true }.find { it.categoriaCatasto == classificazione.categoria }

                    itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto = categoriaRIOG ?: ogge.categoriaCatasto
                    itemSelezionato.oggettoContribuente.oggettoPratica.valore = oggettiService.getRenditaDaRiferimentiOggetto(ogge.id, praticaK.anno)

                    itemSelezionato.oggettoContribuente.oggettoPratica.classeCatasto = ogge.classeCatasto ?: classificazione.classe

                    itemSelezionato.anno = anno
                    listaOggetti << itemSelezionato
                    BindUtils.postNotifyChange(null, null, this, "itemSelezionato")
                    BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                    Clients.evalJavaScript("grepCommaDecimal()")
                }
            }
        }
    }

    @NotifyChange(["listaPertinenze", "listaImposte", "dataCalcolo", "itemSelezionato"
            , "modificheDaSalvare", "listaOggetti", "listaOggettiEliminati"
            , "listaDettagliImposta", "listaDettagliImmobile", "visualizzaCarica", "descrizioneTipoCalcolo"])
    @Command
    onSalva() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        Date oggi = sdf.parse(sdf.format(new Date()))

        gestioneContatti()

        salvaPerStampaF24 = false

        if (selectedTab == 0) {
            modificheDaSalvare = true
            if (validaMaschera()) {
                def ret = calcoloService.salvaOggettiPraticaK(listaOggetti
                        , listaOggettiEliminati
                        , anno
                        , praticaK.id
                        , soggetto.contribuente
                        , dataCalcolo)
                praticaK = ret.pratica
                listaOggetti = ret.listaOggetti
                listaOggettiEliminati = []

                //alla fine del salva la data calcolo è sempre oggi
                //(puo' essere la data del contatto o semplicemente la data di oggi
                //se non si doveva creare il contatto, ma cmq è sempre oggi)
                dataCalcolo = oggi
                itemSelezionato = null
                listaImposte = null
                listaDettagliImposta = null
                listaDettagliImmobile = null
                modificheDaSalvare = false
                listaPertinenze = praticaK ? contribuentiService.listaPertinenze(praticaK?.anno, soggetto.contribuente.codFiscale, praticaK?.tipoTributo?.tipoTributo) : null

                if (listaOggetti.isEmpty()) {
                    calcoloService.cancellaPratica(praticaK, creaContatto)
                    dataCalcolo = null
                    visualizzaCarica = true
                    descrizioneTipoCalcolo = null
                }
            }

            isDirty = false
            BindUtils.postNotifyChange(null, null, this, "isDirty")

            return modificheDaSalvare
        } else if (selectedTab == 1) {
            calcoloService.salvaImposte(listaImposte)
            isDirty = false
        }
    }

    @NotifyChange(["renditeOggetto", "espandiDettagli"])
    @Command
    setSelectedItem(@BindingParam("ogg") def ogg, @BindingParam("index") def index) {
        selezionaItemPratica(ogg)

        renditeOggetto = ogg.oggettoContribuente.oggettoPratica.oggetto.riferimentiOggetto
        BindUtils.postNotifyChange(null, null, this, "itemSelezionato")
        BindUtils.postNotifyChange(null, null, itemSelezionato, "selezionato")
    }

    private selezionaItemPratica(ogg) {
        listaOggetti*.selezionato = false
        itemSelezionato = ogg    //oggettoImposta e suoi dettagli
        itemSelezionato.selezionato = true
    }

    @NotifyChange(["listaOggetti", "itemSelezionato", "renditeOggetto"])
    @Command
    onElimina() {
        //verifica che l'oggetto da eliminare non sia referenziato in altri ogpr.
        //usa l'id per fare il confronto anche nel caso la referenza sia stata impostata
        //ma non ancora salvata.
        for (OggettoImpostaDTO ogim in listaOggetti) {
            if (ogim.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp
                    && ogim.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp.id.equals(oggDaElaborare.oggettoContribuente.oggettoPratica.id)) {
                Clients.showNotification("Esistono riferimenti su Oggetti Pratica (AP). La registrazione di Oggetti Pratica non e' eliminabile.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            }

            isDirty = true
        }


        if (itemSelezionato.equals(oggDaElaborare)) {
            itemSelezionato = null
            renditeOggetto = null
        }
        listaOggettiEliminati << oggDaElaborare
        listaOggetti.remove(oggDaElaborare)
    }

    @NotifyChange(["listaOggetti", "itemSelezionato", "renditeOggetto"])
    @Command
    onEliminaTutti() {
        listaOggettiEliminati.addAll(0, listaOggetti)
        while (listaOggetti.size() > 0) {
            listaOggetti.pop()
        }
        itemSelezionato = null
        renditeOggetto = null
        isDirty = true
        BindUtils.postNotifyChange(null, null, this, "isDirty")
    }

    @Command
    doCheckedFlagEsclusioneRiduzione(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente, "flagEsclusione")
        BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente, "flagRiduzione")
    }

    @NotifyChange(["listaDettagliImmobile"])
    @Command
    setSelectedImmobile(@BindingParam("ogg") def ogg) {
        listaDettagliImposta*.selezionato = false
        immobileSelezionato = ogg
        immobileSelezionato.selezionato = true
        listaDettagliImmobile = disponiListaDettagliImmobile()
        BindUtils.postNotifyChange(null, null, this, "immobileSelezionato")
        BindUtils.postNotifyChange(null, null, immobileSelezionato, "selezionato")
    }

    private boolean validaMaschera() {
        def messaggi = []
        for (item in listaOggetti) {
            if (!item.tipoAliquota) {
                messaggi << ("Oggetto " + item.oggettoContribuente.oggettoPratica.oggetto.id + ": Indicare il tipo aliquota")
            }
            if ((item.oggettoContribuente.mesiPossesso ?: 0) < 0) {
                messaggi << ("Oggetto " + item.oggettoContribuente.oggettoPratica.oggetto.id + ": Indicare i mesi di possesso")
            }
            if ((item.oggettoContribuente.percPossesso ?: 0) == 0) {
                messaggi << ("Oggetto " + item.oggettoContribuente.oggettoPratica.oggetto.id + ": Indicare la percentuale di possesso")
            }
        }

        if (!messaggi.empty) {
            messaggi.add(0, "Impossibile salvare la pratica:")
            Clients.showNotification(messaggi.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }

        return true
    }

    def disponiListaDettagliImmobile() {
        def ret = []
        def lista = calcoloService.dettagliPraticaKPerTabella(praticaK.getDomainObject(), immobileSelezionato.oggetto, immobileSelezionato.categoriaCatastoId)
        def rigaAcconto = [tipo: 'Acconto', terreni: 0, aree: 0, ap: 0, rurali: 0, altri: 0, detrazione: 0, totale: 0, erariale: 0, merce: 0]
        def rigaSaldo = [tipo: 'Saldo', terreni: 0, aree: 0, ap: 0, rurali: 0, altri: 0, detrazione: 0, totale: 0, erariale: 0, merce: 0]
        def rigaTotale = [tipo: 'Totale', terreni: 0, aree: 0, ap: 0, rurali: 0, altri: 0, detrazione: 0, totale: 0, erariale: 0, merce: 0]
        for (l in lista) {
            rigaAcconto.detrazione += l.detrazioneAcconto ?: 0
            rigaAcconto.erariale += l.impostaErarAcconto ?: 0
            rigaAcconto.totale += l.impostaAcconto ?: 0
            rigaSaldo.detrazione += l.detrazioneSaldo ?: 0
            rigaSaldo.erariale += l.impostaErarSaldo ?: 0
            rigaSaldo.totale += l.impostaSaldo ?: 0
            rigaTotale.detrazione += l.detrazione ?: 0
            rigaTotale.erariale += l.impostaErar ?: 0
            rigaTotale.totale += l.imposta ?: 0
            switch (l.tipoOggetto) {
                case 1:
                    rigaAcconto.terreni += l.impostaAcconto ?: 0
                    rigaSaldo.terreni += l.impostaSaldo ?: 0
                    rigaTotale.terreni += l.imposta ?: 0
                    break
                case 2:
                    rigaAcconto.aree += l.impostaAcconto ?: 0
                    rigaSaldo.aree += l.impostaSaldo ?: 0
                    rigaTotale.aree += l.imposta ?: 0
                    break
                default:
                    if ((l.flagAbPrincipale || l.oggettoPraticaRifAp)
                            && ((praticaK.anno >= 2012)
                            || (praticaK.anno < 2012 && l.categoriaCatasto.startsWith("A"))
                    )
                    ) {
                        rigaAcconto.ap += l.impostaAcconto ?: 0
                        rigaSaldo.ap += l.impostaSaldo ?: 0
                        rigaTotale.ap += l.imposta ?: 0
                    } else {
                        if (OggettiCache.ALIQUOTE.valore.find {
                            it.anno == praticaK.anno &&
                                    it.tipoAliquota.tipoAliquota == l.tipoAliquota &&
                                    it.tipoAliquota.tipoTributo.tipoTributo == praticaK.tipoTributo.tipoTributo
                        }.flagFabbricatiMerce == "S") {
                            rigaAcconto.merce += l.impostaAcconto ?: 0
                            rigaSaldo.merce += l.impostaSaldo ?: 0
                            rigaTotale.merce += l.imposta ?: 0
                        } else if (!miniImu && l.impostaErar == null
                                && (!l.flagAbPrincipale
                                || (praticaK.anno < 2012
                                && !l.categoriaCatasto.startsWith("A"))
                        )) {
                            rigaAcconto.rurali += l.impostaAcconto ?: 0
                            rigaSaldo.rurali += l.impostaSaldo ?: 0
                            rigaTotale.rurali += l.imposta ?: 0
                        } else {
                            rigaAcconto.altri += l.impostaAcconto ?: 0
                            rigaSaldo.altri += l.impostaSaldo ?: 0
                            rigaTotale.altri += l.imposta ?: 0
                        }
                    }
                    break
            }
        }
        ret << rigaAcconto
        ret << rigaSaldo
        ret << rigaTotale
        return ret
    }

    @Command
    onChangeVersato(@BindingParam("ogimId") def ogimId) {

        def riga = listaImposte.find { it.idDettaglio == ogimId }    //riga modificata
        def rigaTotali = listaImposte.find { it.idDettaglio == 0 }        //riga dei totali

        //tolgo i vecchi valori dal totale e aggiungo i nuovi
        //aggiorno i valori di riga così alla prossima modifica sono corretti
        rigaTotali.acconto = rigaTotali.acconto - (riga.acconto ?: 0) + (riga.versatoAcconto ?: 0)
        rigaTotali.saldo = rigaTotali.saldo - (riga.saldo ?: 0) //tolgo il vecchio saldo dal totale
        riga.saldo = riga.saldo + (riga.acconto ?: 0) - (riga.versatoAcconto ?: 0)    //aggiorno il valore del saldo
        rigaTotali.saldo = rigaTotali.saldo + (riga.saldo ?: 0) //aggiungo il nuovo saldo al totale
        riga.acconto = riga.versatoAcconto

        //Invece di fare il refresh di tutta la listaImposte,
        //si fa il refresh della sola riga modificata e di quella dei totali.
        BindUtils.postNotifyChange(null, null, riga, "versatoAcconto")
        BindUtils.postNotifyChange(null, null, riga, "acconto")
        BindUtils.postNotifyChange(null, null, riga, "saldo")
        BindUtils.postNotifyChange(null, null, rigaTotali, "acconto")
        BindUtils.postNotifyChange(null, null, rigaTotali, "saldo")
    }

    @Command
    onChangeVersatoErario(@BindingParam("ogimId") def ogimId) {
        def riga = listaImposte.find { it.idDettaglio == ogimId }    //riga modificata
        def rigaTotali = listaImposte.find { it.idDettaglio == 0 }        //riga dei totali

        //tolgo i vecchi valori dal totale e aggiungo i nuovi
        //aggiorno i valori di riga così alla prossima modifica sono corretti
        rigaTotali.accontoErario = rigaTotali.accontoErario - (riga.accontoErario ?: 0) + (riga.versatoAccontoErario ?: 0)
        rigaTotali.saldoErario = rigaTotali.saldoErario - (riga.saldoErario ?: 0) //tolgo il vecchio saldo dal totale
        riga.saldoErario = riga.saldoErario + (riga.accontoErario ?: 0) - (riga.versatoAccontoErario ?: 0)
        rigaTotali.saldoErario = rigaTotali.saldoErario + (riga.saldoErario ?: 0) //aggiungo il nuovo saldo al totale
        riga.accontoErario = riga.versatoAccontoErario

        //Invece di fare il refresh di tutta la listaImposte,
        //si fa il refresh della sola riga modificata e di quella dei totali.
        BindUtils.postNotifyChange(null, null, riga, "versatoAccontoErario")
        BindUtils.postNotifyChange(null, null, riga, "accontoErario")
        BindUtils.postNotifyChange(null, null, riga, "saldoErario")
        BindUtils.postNotifyChange(null, null, rigaTotali, "accontoErario")
        BindUtils.postNotifyChange(null, null, rigaTotali, "saldoErario")
    }

    @NotifyChange(["visualizzaRendite"])
    @Command
    onOpenCloseRendite() {
        visualizzaRendite = !visualizzaRendite
    }

    @NotifyChange(["visualizzaTabellaDettagli", "listaDettagliImmobile"])
    @Command
    onOpenCloseDettagli() {
        visualizzaTabellaDettagli = !visualizzaTabellaDettagli
    }


    @Command
    onClose() {
        //SC 12/11/2014 Oggi abbiamo deciso di non cancellare i valori
        //dalle tabelle di appoggio, in modo da far vedere
        //anche il folder imposta nel caso ci sia già una pratica K
        //così come viene fatto vedere il folder dettagli
        //(questo in pb non viene fatto, si vede solo il folder dettagli,
        //perchè i valori del folder imposta non vengono salvati)
        //contribuentiService.eliminaWCIN(tributiSession.idWCIN)
        reset()
    }

/**
 * Operazioni da fare in 'chiusura' calcolo
 * che puo' essere quando si chiude la maschera
 * o quando si cambiano le impostazioni iniziali.
 * @return
 */
    private reset() {
        if (praticaK) {
            listaOggetti = calcoloService.refreshOggettiPraticaK(listaOggetti, praticaK)
            if (!creaContatto || listaOggetti == null || listaOggetti.size() == 0) {
                //la cancellazione della pratica, in caso di contribuente
                //che prima non esisteva, cancella anche il contribuente,
                //tramite trigger
                calcoloService.cancellaPratica(praticaK, creaContatto)
            }
        }
    }

//metodo per accedere all'enum TipoOggettoCalcolo dallo zul
//usato in calcoloIndividualeImposte.zul
    TipoOggettoCalcolo getTipoOggettoCalcolo(String value) {
        return TipoOggettoCalcolo.getAt(value)
    }

    String getTipoOggettoCalcoloDescrizione(TipoOggettoCalcolo value) {
        return value.getDescrizione()
    }

    @Command
    onChangeMesi(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        if ((itemSelezionato.oggettoContribuente.mesiPossesso ?: 0) == 12) {
            itemSelezionato.oggettoContribuente.mesiPossesso1sem = 6
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente, "mesiPossesso1sem")
        }
    }

    @Command
    onChangeMesiEsclusione(@BindingParam("ogg") def ogg) {

        selezionaItemPratica(ogg)
        def mesiEsclusione = itemSelezionato.oggettoContribuente.mesiEsclusione ?: 0
        def mesiPossesso = itemSelezionato.oggettoContribuente.mesiPossesso ?: 0
        if (mesiEsclusione > mesiPossesso) {
            itemSelezionato.oggettoContribuente.mesiEsclusione = mesiPossesso
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente, "mesiEsclusione")
        }
    }

    @Command
    onChangeDetrazione(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        if ((itemSelezionato.detrazione ?: 0 != 0)
                && (itemSelezionato.detrazioneAcconto ?: 0 == 0)
                && ((itemSelezionato.oggettoContribuente.mesiPossesso ?: 0) != 0)
                && ((itemSelezionato.oggettoContribuente.mesiPossesso1sem ?: 0) != 0)) {
            itemSelezionato.detrazioneAcconto = detrazioniService.calcolaDetrazioneAcconto(anno
                    , itemSelezionato.detrazione
                    , itemSelezionato.oggettoContribuente.mesiPossesso
                    , itemSelezionato.oggettoContribuente.mesiPossesso1sem
                    , praticaK.tipoTributo.getDomainObject())
            itemSelezionato.detrazionePrec = itemSelezionato.detrazioneAcconto
            BindUtils.postNotifyChange(null, null, itemSelezionato, "detrazioneAcconto")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "detrazionePrec")
        }
    }

    @Command
    onChangeRendita(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        BindUtils.postNotifyChange(null, null, itemSelezionato, "valoreDaRendita")
    }

    @Command
    doCheckedImmStorico(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        BindUtils.postNotifyChange(null, null, itemSelezionato, "valoreDaRendita")
    }

    @Command
    onChangeDetrazioneAcconto(@BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        itemSelezionato.detrazionePrec = itemSelezionato.detrazioneAcconto
        BindUtils.postNotifyChange(null, null, itemSelezionato, "detrazionePrec")
    }

//al cambio del tipo aliquota o del pertinenza di
//vanno modificate le aliquote
    @Command
    onSelectTipoAliquota(@ContextParam(ContextType.TRIGGER_EVENT) SelectEvent event, @BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        if (event.getSelectedObjects()[0]) {
            def aliquote = aliquoteService.aliquoteLookUp(anno
                    , event.getSelectedObjects()[0]
                    , fasciaSoggetto
                    , java.sql.Date.valueOf(anno + "-01-01")
                    , itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto?.categoriaCatasto
                    , null
                    , itemSelezionato.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp
                    , praticaK.contribuente.codFiscale)
            //se è stato segnalato un errore riporto indietro il valore
            if (aliquote.size() == 0) {
                BindUtils.postNotifyChange(null, null, itemSelezionato, "tipoAliquota")
                return
            }
            itemSelezionato.tipoAliquota = event.getSelectedObjects()[0]
            itemSelezionato.tipoAliquotaPrec = event.getSelectedObjects()[0]
            itemSelezionato.aliquota = aliquote.aliquota
            if (anno >= 2012) {
                itemSelezionato.aliquotaPrec = aliquote.aliquotaAcconto * 100
                itemSelezionato.aliquotaErarPrec = aliquote.aliquotaErariale
                itemSelezionato.aliquotaErariale = aliquote.aliquotaErariale
                itemSelezionato.aliquotaStd = aliquote.aliquotaStandard


                itemSelezionato.oggettoContribuente.oggettoPratica.indirizzoOcc = ((itemSelezionato.tipoAliquotaPrec?.tipoAliquota) ?: 0).toString().padLeft(2, "0") +
                        ((Long) ((itemSelezionato.aliquotaPrec) ?: 0)).toString().padLeft(6, '0') +
                        ((Long) (itemSelezionato.detrazionePrec ?: 0) * 100).toString().padLeft(15, '0') +
                        ((Long) (itemSelezionato.aliquotaErarPrec ?: 0) * 100).toString().padLeft(6, '0')

            }
            BindUtils.postNotifyChange(null, null, itemSelezionato, "tipoAliquota")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquota")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErariale")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErarPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaStd")
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "indirizzoOcc")
        }
    }

//al cambio del tipo aliquota o del pertinenza di
//vanno modificate le aliquote
    @Command
    onSelectPertinenza(@ContextParam(ContextType.TRIGGER_EVENT) SelectEvent event, @BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        if (itemSelezionato.tipoAliquota) {
            def aliquote = aliquoteService.aliquoteLookUp(anno
                    , itemSelezionato.tipoAliquota
                    , fasciaSoggetto
                    , java.sql.Date.valueOf(anno + "-01-01")
                    , itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto.categoriaCatasto
                    , null
                    , event.getSelectedObjects()[0]
                    , praticaK.contribuente.codFiscale)
            //se è stato segnalato un errore riporto indietro il valore
            if (aliquote.size() == 0) {
                BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "oggettoPraticaRifAp")
                return
            }
            itemSelezionato.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp = event.getSelectedObjects()[0]
            itemSelezionato.aliquota = aliquote.aliquota
            if (anno >= 2012) {
                itemSelezionato.aliquotaPrec = aliquote.aliquotaAcconto * 100
                itemSelezionato.aliquotaErarPrec = aliquote.aliquotaErariale
                itemSelezionato.aliquotaErariale = aliquote.aliquotaErariale
                itemSelezionato.aliquotaStd = aliquote.aliquotaStd

                itemSelezionato.oggettoContribuente.oggettoPratica.indirizzoOcc = ((itemSelezionato.tipoAliquotaPrec?.tipoAliquota) ?: 0).toString().padLeft(2, "0") +
                        ((Long) ((itemSelezionato.aliquotaPrec) ?: 0)).toString().padLeft(6, '0') +
                        ((Long) (itemSelezionato.detrazionePrec ?: 0) * 100).toString().padLeft(15, '0') +
                        ((Long) (itemSelezionato.aliquotaErarPrec ?: 0) * 100).toString().padLeft(6, '0')
            }
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "oggettoPraticaRifAp")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquota")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErariale")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErarPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaStd")
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "indirizzoOcc")
        }
    }
//al cambio della categoriaCatasto si ricalcolano le aliquote
//e il valore
    @Command
    onSelectCategoriaCatasto(@ContextParam(ContextType.TRIGGER_EVENT) SelectEvent event, @BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        if (itemSelezionato.tipoAliquota) {
            def aliquote = aliquoteService.aliquoteLookUp(anno
                    , itemSelezionato.tipoAliquota
                    , fasciaSoggetto
                    , java.sql.Date.valueOf(anno + "-01-01")
                    , event.getSelectedObjects()[0].categoriaCatasto
                    , null
                    , itemSelezionato.oggettoContribuente.oggettoPratica.oggettoPraticaRifAp
                    , praticaK.contribuente.codFiscale)
            //se è stato segnalato un errore riporto indietro il valore
            if (aliquote.size() == 0) {
                BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "categoriaCatasto")
                return
            }
            itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto = event.getSelectedObjects()[0]
            itemSelezionato.aliquota = aliquote.aliquota
            if (anno >= 2012) {
                itemSelezionato.aliquotaPrec = aliquote.aliquotaAcconto * 100
                itemSelezionato.aliquotaErarPrec = aliquote.aliquotaErariale
                itemSelezionato.aliquotaErariale = aliquote.aliquotaErariale
                itemSelezionato.aliquotaStd = aliquote.aliquotaStd

                itemSelezionato.oggettoContribuente.oggettoPratica.indirizzoOcc = ((itemSelezionato.tipoAliquotaPrec?.tipoAliquota) ?: 0).toString().padLeft(2, "0") +
                        ((Long) ((itemSelezionato.aliquotaPrec) ?: 0)).toString().padLeft(6, '0') +
                        ((Long) (itemSelezionato.detrazionePrec ?: 0) * 100).toString().padLeft(15, '0') +
                        ((Long) (itemSelezionato.aliquotaErarPrec ?: 0) * 100).toString().padLeft(6, '0')
            }
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "categoriaCatasto")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquota")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErariale")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaErarPrec")
            BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaStd")
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "indirizzoOcc")
        }
        itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto = event.getSelectedObjects()[0]
        BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "categoriaCatasto")
        BindUtils.postNotifyChange(null, null, itemSelezionato, "valoreDaRendita")
    }

    @Command
    onSelectTipoAliquotaAcconto(
            @ContextParam(ContextType.TRIGGER_EVENT) SelectEvent event, @BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        //def riga 		= listaOggetti.find {it.idOggettoPratica == ogg.idOggettoPratica} 	//riga modificata
        if (event.getSelectedObjects()[0]) {
            try {
                LinkedHashMap<BigDecimal> aliquote = aliquoteService.aliquoteLookUp(anno
                        , event.getSelectedObjects()[0]
                        , fasciaSoggetto
                        , java.sql.Date.valueOf(anno + "-01-01")
                        , itemSelezionato.oggettoContribuente.oggettoPratica.categoriaCatasto.categoriaCatasto
                        , null
                        , null
                        , praticaK.contribuente.codFiscale)


                itemSelezionato.tipoAliquotaPrec = event.getSelectedObjects()[0]
                itemSelezionato.aliquotaPrec = aliquote.aliquota * 100
                BindUtils.postNotifyChange(null, null, itemSelezionato, "tipoAliquotaPrec")
                BindUtils.postNotifyChange(null, null, itemSelezionato, "aliquotaPrec")
            } catch (Exception e) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            } finally {
                BindUtils.postNotifyChange(null, null, itemSelezionato, "tipoAliquotaPrec")
            }
        }
    }

    @Command
    onSelectTipoOggetto(@ContextParam(ContextType.TRIGGER_EVENT) SelectEvent event, @BindingParam("ogg") def ogg) {
        selezionaItemPratica(ogg)
        List<Long> range = [(long) 3, (long) 4, (long) 5, (long) 6]
        //flagAbPrincipale puo' essere true solo se tipoOggetto in (3,4,5,6)
        //se viene modificato il tipo oggetto, potrebbe cambiare anche il valore
        if (itemSelezionato.oggettoContribuente.flagAbPrincipale &&
                !range.contains(event.getSelectedObjects()[0]?.tipoOggetto)) {
            //Clients.showNotification("Tipo oggetto incompatibile con abitazione principale ", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            Messagebox.show("Tipo oggetto incompatibile con abitazione principale. Si desidera togliere il flag abitazione principale?", "Calcolo individuale",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                itemSelezionato.oggettoContribuente.flagAbPrincipale = false
                                itemSelezionato.oggettoContribuente.oggettoPratica.tipoOggetto = event.getSelectedObjects()[0]
                                BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente, "flagAbPrincipale")
                                BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "tipoOggetto")
                                BindUtils.postNotifyChange(null, null, itemSelezionato, "valoreDaRendita")
                            } else if (Messagebox.ON_CANCEL.equals(e.getName()) || Messagebox.ON_NO.equals(e.getName())) {
                                //Cancel is clicked
                                BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "tipoOggetto")
                            }
                        }
                    }
            )
        } else {
            itemSelezionato.oggettoContribuente.oggettoPratica.tipoOggetto = event.getSelectedObjects()[0]
            BindUtils.postNotifyChange(null, null, itemSelezionato.oggettoContribuente.oggettoPratica, "tipoOggetto")
        }
    }

    @Command
    onElencoStampe() {
        Window w = Executions.createComponents("/sportello/contribuenti/calcoloIndividualeStampe.zul", self,
                [listaImposte        : listaImposte,
                 disabilitaF24Unico  : disabilitaF24Unico,
                 anno                : anno,
                 codFiscale          : codFiscale,
                 listaOggetti        : listaOggetti,
                 valoreTerreniRidotti: valoreTerreniRidotti,
                 rbTributi           : rbTributi,
                 salvaPerStampaF24   : salvaPerStampaF24
                ])
        w.doModal()
    }

    @Command
    onStampa() {
        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.CALCOLO_INDIVIDUALE,
                [:])
        def calcoloIndividuale = []

        CalcoloIndividualeBean calcoloIndividualeBean = new CalcoloIndividualeBean()
        calcoloIndividualeBean.anno = anno
        calcoloIndividualeBean.contribuente = contribuentiService.getDatiTestata(codFiscale)
        calcoloIndividualeBean.tipoTributo = TipoTributo.get(rbTributi).getTipoTributoAttuale(anno)
        calcoloIndividualeBean.listaOggetti = listaOggetti
        calcoloIndividualeBean.listaImposte = listaImposte

        calcoloIndividuale << calcoloIndividualeBean

        JasperReportDef reportDef = new JasperReportDef(name: 'calcoloIndividuale.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: calcoloIndividuale
                , parameters: [SUBREPORT_DIR                  : servletContext.getRealPath('/reports') + "/",
                               ENTE                           : ad4EnteService.getEnte(),
                               valoreTerreniRidotti           : valoreTerreniRidotti,
                               valoreTerreniRidottiFuoriComune: calcoloService.terreniRidottiFuoriComune(codFiscale, anno)])

        def calcolo = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, calcolo.toByteArray())
        Filedownload.save(amedia)
    }

    @Command
    onGeneraF24(@BindingParam("tipoPagamento") int tipoPagamento) {

        if (salvaPerStampaF24) {
            Clients.showNotification("Salvare il calcolo prima di procedere con la stampa.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [:])
        List f24data = f24Service.caricaDatiF24(codFiscale, rbTributi, tipoPagamento, anno)

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)

    }

    @Command
    onGeneraF24Unico(@BindingParam("tipoPagamento") int tipoPagamento) {

        if (salvaPerStampaF24) {
            Clients.showNotification("Salvare il calcolo prima di procedere con la stampa.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [:])
        List f24data = f24Service.caricaDatiF24(codFiscale, "UNICO", tipoPagamento, anno)

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)

        AMedia amedia = new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
        Filedownload.save(amedia)
    }

    @NotifyChange(["espandiDettagli", "dettagliEspansi", "listaOggetti"])
    @Command
    gestisciDettagli() {

        dettagliEspansi = !dettagliEspansi

        def index = 0
        listaOggetti.each {
            espandiDettagli[index++] = dettagliEspansi
        }
    }

    private gestioneContatti() {
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        Date oggi = sdf.parse(sdf.format(new Date()))

        if (creaContatto && (!praticaK.contattoContribuente || (praticaK.contattoContribuente.data < oggi && isDirty))) {
            calcoloService.creaContatto(praticaK, oggi)
        }
    }

    @Command
    onCopia() {

        itemSelezionato = null

        def index = listaOggetti.indexOf(oggDaElaborare)
        OggettoImpostaDTO oggettoDuplicato = new OggettoImpostaDTO()

        InvokerHelper.setProperties(oggettoDuplicato, oggDaElaborare.properties)
        oggettoDuplicato.id = null

        oggettoDuplicato.oggettoContribuente = new OggettoContribuenteDTO()
        oggettoDuplicato.oggettoContribuente.oggettoPratica = new OggettoPraticaDTO()

        OggettoContribuenteDTO ogcoCopia = new OggettoContribuenteDTO()
        InvokerHelper.setProperties(ogcoCopia, oggDaElaborare.oggettoContribuente.properties)
        oggettoDuplicato.oggettoContribuente = ogcoCopia
        oggettoDuplicato.oggettoContribuente.oggettoPratica = new OggettoPraticaDTO()
        InvokerHelper.setProperties(oggettoDuplicato.oggettoContribuente.oggettoPratica, oggDaElaborare.oggettoContribuente.oggettoPratica.properties)
        oggettoDuplicato.oggettoContribuente.oggettoPratica.id = null

        oggettoDuplicato.selezionato = true
        //new OggettoContribuenteDTO().addToOggettiImposta(itemSelezionato)
        //new OggettoPraticaDTO().addToOggettiContribuente(itemSelezionato.oggettoContribuente)
        praticaK = praticaK ?: new PraticaTributoDTO()
        praticaK.addToOggettiPratica(oggettoDuplicato.oggettoContribuente.oggettoPratica)
        oggettoDuplicato.oggettoContribuente.contribuente = soggetto.contribuente
        oggettoDuplicato.oggettoContribuente.oggettoPratica.oggetto = oggDaElaborare.oggettoContribuente.oggettoPratica.oggetto
        oggettoDuplicato.oggettoContribuente.oggettoPratica.tipoOggetto = oggDaElaborare.oggettoContribuente.oggettoPratica.oggetto.tipoOggetto
        oggettoDuplicato.oggettoContribuente.oggettoPratica.categoriaCatasto = oggDaElaborare.oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto
        oggettoDuplicato.anno = anno

        listaOggetti.addAll(index + 1, oggettoDuplicato)

        isDirty = true

        BindUtils.postNotifyChange(null, null, this, "itemSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    @Command
    setSetItemSelezionato(@BindingParam("ogg") def ogg) {
        oggDaElaborare = ogg
    }

}
