package pratiche.denunce

import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.TipoCaricaDTO
import it.finmatica.tr4.dto.VersamentoDTO
import it.finmatica.tr4.dto.pratiche.DenunciaTarsuDTO
import it.finmatica.tr4.dto.pratiche.FamiliarePraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.DenunciaTarsu
import org.apache.commons.lang.StringUtils
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.EventQueue
import org.zkoss.zk.ui.event.EventQueues
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.text.SimpleDateFormat
import java.util.Calendar

class DenunciaTariViewModel extends DenunciaViewModel {

    private static final Logger log = Logger.getLogger(DenunciaTariViewModel.class)

    // Component
    Listbox lbRuoliVersamento
    Bandbox bdRuoliVersamento

    // Service
    CommonService commonService
    OggettiService oggettiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    CompetenzeService competenzeService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Model
    def eventoSelezionato
    List<OggettoContribuenteDTO> listaLocaliAree
    List<VersamentoDTO> listaVersamenti
    def listaFamiliari
    def ruoliVersamento
    def listaFonti
    boolean inserimentoAutomaticoOggetti = false

    boolean isDirty = false
    boolean solaLettura = false

    OggettoContribuenteDTO localeSelezionato

    def oggettiImportoCalcolato

    def ruoli
    def ruoloSelezionato

    def isNuovaDenuncia = false

    def iter
    def iterLettura
    def folderIterVisible = false

    Popup popupNote
    def oldTestoNote
    def flagAnnullamentoOld


    @NotifyChange(["modifica", "lettura"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("pratica") Long idPratica
         , @ExecutionArgParam("tipoRapporto") String tr
         , @ExecutionArgParam("lettura") boolean lt
         , @ExecutionArgParam("daSC") @Default("") def daSC
         , @ExecutionArgParam("selected") @Default("") def selected) {

        self = w
        tributoTari = true

        listaTipiEvento = [
                TipoEventoDenuncia.I
                , TipoEventoDenuncia.V
                , TipoEventoDenuncia.C
                , TipoEventoDenuncia.U]

        modifica = !lt

        if (idPratica > 0) {

            denuncia = DenunciaTarsu.get(idPratica).toDTO(listaFetch)
            oggettiImportoCalcolato = denunceService.oggettiImportoCalcolatoTarsu(denuncia.pratica.contribuente.codFiscale, denuncia.pratica.id)

            listaLocaliAree = denunceService.getOggettiPratica(idPratica)
            listaVersamenti = denunceService.getVersamenti(idPratica, denuncia.pratica.tipoPratica, denuncia.pratica.tipoTributo.tipoTributo)
            listaFamiliari = denunceService.getFamiliari(idPratica)

            praticaAnnullabile =
                    ((denuncia.pratica.tipoEvento == TipoEventoDenuncia.I && !denunceService.fPraticaAnnullabile(denuncia.pratica.id)?.tipoErrore) ||
                            denuncia.pratica.tipoEvento != TipoEventoDenuncia.I
                    ) && modifica

            filtri.denunciante.codFiscale = denuncia.pratica.codFiscaleDen ?: ""
            filtri.contribuente.codFiscale = denuncia.pratica.contribuente.codFiscale ?: ""
            filtri.contribuente.cognome = denuncia.pratica.contribuente?.soggetto?.cognome ?: ""
            filtri.contribuente.nome = denuncia.pratica.contribuente?.soggetto?.nome ?: ""
            filtri.comuneDenunciante.denominazione = denuncia.pratica.comuneDenunciante?.ad4Comune?.denominazione

        } else {
            denuncia = new DenunciaTarsuDTO()
            denuncia.pratica = new PraticaTributoDTO()
            denuncia.pratica.tipoCarica = new TipoCaricaDTO()
            denuncia.pratica.contribuente = new ContribuenteDTO()
            denuncia.pratica.anno = (short) Calendar.getInstance().get(Calendar.YEAR)
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
            denuncia.pratica.tipoTributo = TipoTributo.get("TARSU").toDTO()

            //Se elemento selezionato viene proposta una nuova denuncia per lo stesso contribuente (solo da situazione contribuente)
            if (daSC == true && selected != null && selected != "") {
                setSelectCodFiscaleCon(selected)
            } else {
                onApriMascheraRicercaSoggetto()
            }

            isNuovaDenuncia = true
        }
        tipoTributoAttuale = denuncia.pratica.tipoTributo.getTipoTributoAttuale(denuncia.pratica.anno)
        listaCariche = TipoCarica.findAllByIdGreaterThanEquals(0, [sort: "id", order: "asc"]).toDTO()
        tipoRapporto = tr

        valorePrecedenteAnno = denuncia.pratica.anno

        aggiornaModificaAnno()
        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        if (idPratica > 0) {
            caricaRuoliVersamento()
        }

        elencoMotivi = denunceService.elencoMotivazioni(denuncia.pratica.tipoTributo.tipoTributo, (denuncia.pratica.tipoPratica) ? denuncia.pratica.tipoPratica : 'D', denuncia.pratica.anno)

        this.inserimentoAutomaticoOggetti = commonService.fInpaValore('DETA_OGGEA')
        this.solaLettura = competenzeService.tipoAbilitazioneUtente('TARSU') == competenzeService.TIPO_ABILITAZIONE.LETTURA

        caricaIter()
        iterLettura = solaLettura
        folderIterVisible = denuncia.pratica.tipoPratica == TipoPratica.D.tipoPratica && denuncia.pratica.tipoTributo.tipoTributo == 'TARSU'

        flagAnnullamentoOld = denuncia.pratica.flagAnnullamento

        aggiornaDataModifica()
        aggiornaUtente()

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {
                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    isDirty = isDirty || !(pe.property in [
                            'oggCoSelezionato',
                            'listaOggetti',
                            'oggettiSelezionati',
                            'listaContitolari',
                            'contSelezionato',
                            'denuncia',
                            'datiDichiarazioneENC',
                            'datiDocFA',
                            'rendita',
                            'valore',
                            'lastUpdated',
                            'utente',
                            'isDirty'
                    ])

                }
            }
        })


    }

    @Command
    def onSalvaDenuncia() {
        if (!validaMaschera()) {
            return
        }

        if (denuncia.pratica.id) {
            def messaggi = []

            def ruolo = denunceService.fCheckOgprARuolo(denuncia.pratica.id)
            if (denunceService.presenzaRavvedimentoOperoso(denuncia, ruolo)) {
                messaggi << "Esistono Ravvedimenti Operosi sul ruolo $ruolo"
            }
            if (!messaggi.empty) {
                def messaggio = "${messaggi.join('\n')}\nSi desidera proseguire?"
                Messagebox.show(messaggio, "Attenzione",
                        Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                        new EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    caricaRuoliVersamento()
                                    salvaDenunciaTari()
                                }
                            }
                        }
                )
            } else {
                caricaRuoliVersamento()
                salvaDenunciaTari()
            }

            return
        }

        salvaDenunciaTari()
        caricaRuoliVersamento()

    }

    @Command
    def onEliminaPratica() {

        def controllo = denunceService.denunciaTarsuEliminabile(denuncia.pratica.id)
        if (controllo) {
            Clients.showNotification(controllo, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }

        String messaggio = "Eliminare la denuncia?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            eliminaDenuncia()
                        }
                    }
                }
        )
    }

    @Command
    def onApriImmobili() {
        int indexSelezione = listaLocaliAree.indexOf(localeSelezionato)
        commonService.creaPopup("pratiche/denunce/oggettoContribuenteTari.zul"
                , self
                , [indexOggetto: indexSelezione, listaOggetti: listaLocaliAree, tipoTributo: tipoTributoAttuale], { e ->

            listaLocaliAree = denunceService.getOggettiPratica(denuncia.pratica.id)
            BindUtils.postNotifyChange(null, null, this, "listaLocaliAree")
        })
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
        denuncia.pratica.iter = iter
        BindUtils.postNotifyChange(null, null, this, "iter")
    }

    /**
     DETA_OGGEA = S
     - I
     -- Da altro contribuente cessato
     -- Inserimento manuale oggetto
     - V
     -- Elenco oggetti da variare
     - C
     -- Elenco oggetti da cessare
     - U
     -- Da altro contribuente cessato
     -- ricerca oggetti

     DETA_OGGEA = n/null
     - I
     -- Da altro contribuente cessato
     -- ricerca oggetti
     - V
     -- Elenco oggetti da variare
     - C
     -- Elenco oggetti da cessare
     - U
     -- Da altro contribuente cessato
     -- ricerca oggetti
     */
    @Command
    def onAggiungiArea() {

        def td = denuncia.pratica.tipoEvento

        if (td in [TipoEventoDenuncia.I, TipoEventoDenuncia.U]) {
            String messaggio = "Inserimento da altro contribuente cessato?"
            Messagebox.show(messaggio, "Locali ed Aree",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES == e.getName()) {
                                ricercaUtenzeTari()
                            } else {
                                if (commonService.fInpaValore('DETA_OGGEA')) {
                                    if (td == TipoEventoDenuncia.I) {
                                        daLocaliAreeEsistenti('crea')
                                    } else {
                                        daLocaliAreeEsistenti('esistente')
                                    }

                                } else {
                                    daLocaliAreeEsistenti('esistente')
                                }
                            }
                        }
                    }
            )
        } else if (denuncia.pratica.tipoEvento in [TipoEventoDenuncia.V, TipoEventoDenuncia.C]) {
            ricercaUtenzeTari()
        }
    }

    @Command
    def onEliminaArea() {

        org.zkoss.zhtml.Messagebox.show("Eliminare il quadro?", "Attenzione", org.zkoss.zhtml.Messagebox.YES | org.zkoss.zhtml.Messagebox.NO, org.zkoss.zhtml.Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (org.zkoss.zhtml.Messagebox.ON_YES.equals(e.getName())) {
                            eliminaArea()
                        }
                    }
                }
        )
    }

    @Command
    def onEliminaVersamento(@BindingParam("vers") VersamentoDTO vers) {
        def title = "Versamento"
        def message = "Eliminare il versamento #${++listaVersamenti.findIndexOf { it.uuid == vers.uuid }}"

        org.zkoss.zhtml.Messagebox.show(message, title, org.zkoss.zhtml.Messagebox.YES | org.zkoss.zhtml.Messagebox.NO, org.zkoss.zhtml.Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (org.zkoss.zhtml.Messagebox.ON_YES.equals(e.getName())) {
                            eliminaVersamento(vers)
                        }
                    }
                }
        )
    }

    @Command
    def onDuplicaVersamento(@BindingParam("vers") VersamentoDTO vers) {

        def versDup = new VersamentoDTO(commonService.getObjProperties(vers, ['sequenza', 'totaleDaVersare', 'descrizioneTributo']))
        versDup.sequenza = (listaVersamenti.collect { it.sequenza }.max() ?: 0) + 1
        listaVersamenti << versDup

        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onCambiaRuoloVersamento(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def v) {

        def vers = listaVersamenti.find { it.uuid = v.uuid }
        if (!bd.text) {
            vers.ruolo = null
            lbRuoliVersamento.selectedItem = null
        } else {
            def ruolo = ruoliVersamento.find { it.id == bd.text }
            if (!ruolo) {
                vers.ruolo = null
                lbRuoliVersamento?.selectedItem = null
                Clients.showNotification("Ruolo non previsto.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            } else {
                vers.ruolo = ruolo
            }
        }

        BindUtils.postNotifyChange(null, null, this, "vers")
    }

    @Command
    def onSelezionaRuoloVersamento(@BindingParam("lb") Listbox lb, @BindingParam("vers") def vers) {
        bdRuoliVersamento?.close()
        bdRuoliVersamento?.text = vers.ruolo.id
        lbRuoliVersamento = lb
    }

    @Command
    def onApriRuoloVersamento(@BindingParam("bd") Bandbox bd) {
        bdRuoliVersamento = bd
    }

    @Command
    def onAggiungiVersamento() {

        listaVersamenti.add(
                new VersamentoDTO([
                        tipoVersamento: 'U',
                        dataReg       : new Date(),
                        contribuente  : denuncia.pratica.contribuente,
                        anno          : denuncia.pratica.anno,
                        pratica       : denuncia.pratica,
                        tipoTributo   : denuncia.pratica.tipoTributo,
                        fonte         : listaFonti.find { it.fonte == 6 },
                        sequenza      : (listaVersamenti.collect { it.sequenza }.max() ?: 0) + 1
                ])
        )

        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onEliminaRuolo(@BindingParam("vers") VersamentoDTO vers) {
        vers.ruolo = null
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onAggiungiFamiliare() {

        def window = self

        commonService.creaPopup("/archivio/listaSoggettiRicerca.zul", self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true], { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    def sogg = event.data.Soggetto
                    listaFamiliari << [
                            cognomeNome  : "${sogg.cognome} ${sogg.nome}".trim(),
                            codFiscale   : sogg.contribuente?.codFiscale ?: sogg.codFiscale,
                            dataNascita  : sogg.dataNas,
                            comuneNascita: (sogg.comuneNascita?.ad4Comune?.denominazione ?: '') +
                                    (sogg.comuneNascita?.ad4Comune?.provincia ? "(${sogg.comuneNascita?.ad4Comune?.provincia?.sigla})" : ''),
                            sesso        : sogg.sesso == 'M' ? 'Maschio' : 'Femmina',
                            ni           : sogg.id
                    ]

                    try {
                        window.getFellow("includeFamiliari").getFellow("lstFamiliari").invalidate()
                    } catch (Exception e) {
                        log.info("lstFamiliari non trovato")
                    }

                    BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
                }
            }
        })
    }

    @Command
    def onEliminaFamiliare(@BindingParam("fam") def familiare) {
        def title = "Familiare"
        def message = "Eliminare il familiare #${++listaFamiliari.findIndexOf { it.ni == familiare.ni }}"

        org.zkoss.zhtml.Messagebox.show(message, title, org.zkoss.zhtml.Messagebox.YES | org.zkoss.zhtml.Messagebox.NO, org.zkoss.zhtml.Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (org.zkoss.zhtml.Messagebox.ON_YES.equals(e.name)) {
                            eliminaFamiliare(familiare)
                        }
                    }
                }
        )
    }

    @Command
    onSelezionaMotivo(@BindingParam("pu") Popup pu) {
        pu.close()
        denuncia.pratica.motivo = motivoSelezionato.motivo
        isDirty = true
        BindUtils.postNotifyChange(null, null, this, "denuncia")
    }

    @Command
    def onToggleFlagAnnullato() {

        if (!abilitaFlagAnnullato && denuncia.pratica.flagAnnullamento && denuncia.pratica.tipoEvento.id == 'C') {
            Clients.showNotification("Non e' possibile ripristinare una denuncia di cessazione", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            return
        }

        if (denuncia.pratica.flagAnnullamento) {
            def verifica = denunceService.fCheckRipristinoAnno(denuncia.pratica.id)
            if (verifica) {
                Clients.showNotification(verifica, Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                return
            }
        } else {
            def ruolo = denunceService.fCheckOgprARuolo(denuncia.pratica.id)
            if (ruolo) {
                def message = "Oggetti già inseriti in ruolo $ruolo.\nProcedere?"
                Messagebox.show(message,
                        "Attenzione",
                        Messagebox.YES | Messagebox.NO,
                        Messagebox.QUESTION,
                        { e ->
                            if (e.getName() == Messagebox.ON_YES) {
                                switchAbilitazioneFlagAnnullato()
                            }
                        })
                return
            }
        }

        switchAbilitazioneFlagAnnullato()
    }

    @Deprecated
    private boolean existOggettiARuolo(minRuoloOggettiDenuncia) {
        minRuoloOggettiDenuncia != null
    }

    private switchAbilitazioneFlagAnnullato() {
        abilitaFlagAnnullato = !abilitaFlagAnnullato
        BindUtils.postNotifyChange(null, null, this, "abilitaFlagAnnullato")
    }

    @Command
    def onInserimentoARuolo() {

        commonService.creaPopup("/ufficiotributi/imposte/listaRuoliPerSelezione.zul", self,
                [idPratica: denuncia.id, codFiscale: denuncia.pratica.contribuente.codFiscale],
                {})
    }

    @Command
    def onSelectLocaleArea() {
        if (localeSelezionato) {
            ruoli = liquidazioniAccertamentiService.getRuoliDenuncia(
                    denuncia.pratica.id,
                    localeSelezionato.oggettoPratica.id,
                    denuncia.pratica.tipoTributo.tipoTributo,
                    localeSelezionato.oggettoPratica.oggetto.id,
                    denuncia.pratica.contribuente.codFiscale)

            BindUtils.postNotifyChange(null, null, this, "ruoli")
        }
    }

    @Command
    def onGestisciSgravi() {

        commonService.creaPopup("/ufficiotributi/imposte/ruoliOggettiSgravi.zul", self,
                [ruolo       : ruoloSelezionato.ruolo.id,
                 codFiscale  : denuncia.pratica.contribuente.codFiscale,
                 oggettoRuolo: ruoloSelezionato.ruoloOggetto],
                {
                    ruoli = liquidazioniAccertamentiService.getRuoliDenuncia(
                            denuncia.pratica.id,
                            localeSelezionato.oggettoPratica.id,
                            denuncia.pratica.tipoTributo.tipoTributo,
                            localeSelezionato.oggettoPratica.oggetto.id,
                            denuncia.pratica.contribuente.codFiscale)

                    ruoloSelezionato = null
                    BindUtils.postNotifyChange(null, null, this, "ruoli")
                    BindUtils.postNotifyChange(null, null, this, "ruoloSelezionato")
                })
    }

    @Command
    def onLockUnlockModificaAnno() {
        super.onLockUnlockModificaAnno {
            this.salva()
        }
    }

    private void emettiRuolo(def ruolo, def codFiscale) {
        def datiEmissione = [:]

        datiEmissione.ruolo = ruolo
        datiEmissione.codFiscale = codFiscale

        commonService.creaPopup("/sportello/contribuenti/emissioneRuolo.zul", self,
                [
                        ruolo              : datiEmissione,
                        lettura            : false,
                        esecuzioneImmediata: true], { e ->
            if (e.data?.elaborato) {
                Clients.showNotification("Inserimento a ruolo eseguito", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
            }
        }
        )
    }

    private boolean validaMaschera() {
        def errori = []

        if (!denuncia.pratica.data) {
            errori << ("Indicare la data di presentazione")
        }

        if (!denunceService.getScadenza('TARSU', denuncia.pratica.anno, 'D')) {
            errori << ("Scadenza Denuncia Non Prevista per l'Anno ${denuncia.pratica.anno}. Inserirla nel Dizionario Generale delle Scadenze")
        }

        if (denuncia.pratica?.anno <= 0) {
            errori << ("Indicare l'anno della pratica")
        }

        if (denuncia.pratica.contribuente.codFiscale == null) {
            errori << ("Indicare il codice fiscale del dichiarante")
        }

        if (denuncia.pratica.tipoEvento == null) {
            errori << ("Indicare il tipo evento")
        }

        if (denuncia.pratica.tipoEvento?.id in ['C', 'V']) {
            def presenzaOggetti = verificaPresenzaOggetti(denuncia.pratica.contribuente.codFiscale)
            if (presenzaOggetti) {
                errori << presenzaOggetti
            }
        }

        // Messaggi di errore
        if (!errori.empty) {
            errori.add(0, "Impossibile salvare la denuncia:")
            Clients.showNotification(StringUtils.join(errori, "\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }

        return true
    }

    private verificaPresenzaOggetti(def codFiscale) {

        // Solo se si è in inserimento
        if (denuncia.pratica.id) {
            return null
        }

        if (denunceService.esistonoOggettiDaVariareCessare(denuncia.pratica.contribuente.codFiscale)) {
            return null
        } else {
            return "Non esistono oggetti da variare o cessare"
        }
    }

    private eliminaVersamento(def vers) {
        listaVersamenti = listaVersamenti.findAll { it.uuid != vers.uuid }
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    private caricaRuoliVersamento() {
        ruoliVersamento = liquidazioniAccertamentiService.elencoRuoliVersamento(
                denuncia.pratica.tipoTributo.tipoTributo,
                denuncia.pratica.anno,
                denuncia.pratica.contribuente.codFiscale)
        BindUtils.postNotifyChange(null, null, this, "ruoliVersamento")
    }

    private eliminaFamiliare(def fam) {
        listaFamiliari = listaFamiliari.findAll { it.ni != fam.ni }
        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
    }

    private void salva() {

        if (salvaDenunciaCheck()) {

            modifica = true

            // Si settano i versamenti
            denuncia.pratica.versamenti?.clear()
            denuncia.pratica.versamenti?.addAll(listaVersamenti)

            // Gestione dei familiari
            denuncia.pratica.familiariPratica?.clear()
            listaFamiliari.each {
                denuncia.pratica.familiariPratica << new FamiliarePraticaDTO(
                        [pratica: denuncia.pratica, soggetto: Soggetto.get(it.ni).toDTO(), rapportoPar: it.rapportoPar]
                )
            }

            def salvaDenuncia = denunceService.salvaDenuncia(denuncia, listaFetch, tipoRapporto, flagCf, prefissoTelefonico, numTelefonico, flagFirma, flagDenunciante, "TARSU")
            salvaDenunciaPostProcessa(salvaDenuncia)

            aggiornaModificaAnno()
            listaVersamenti = denunceService.getVersamenti(denuncia.pratica.id, denuncia.pratica.tipoPratica, denuncia.pratica.tipoTributo.tipoTributo)
            listaFamiliari = denunceService.getFamiliari(denuncia.pratica.id)

            isDirty = false
            abilitaFlagAnnullato = false

            aggiornaDataModifica()
            aggiornaUtente()

            def warnings = []

            // Warning non bloccanti, verranno visualizzati solo se non sono presenti errori
            def dateMaxRuolo = denunceService.dataMaxRuoloTarsu()

            if (denuncia.pratica.data < dateMaxRuolo.maxEmisRuolo) {
                warnings << "Data denuncia ${denuncia.pratica.data.format('dd/MM/yyyy')} precedente all'ultimo ruolo emesso e inviato (${dateMaxRuolo.maxEmisRuolo.format('dd/MM/yyyy')}). Controllare la data presentazione"
            } else if (denuncia.pratica.data < dateMaxRuolo.maxInvioRuolo) {
                warnings << "Data denuncia ${denuncia.pratica.data.format('dd/MM/yyyy')} precedente all'ultimo ruolo emesso (${dateMaxRuolo.maxInvioRuolo.format('dd/MM/yyyy')}). Controllare la data presentazione"
            }

            def dataScadenza = denunceService.getScadenza('TARSU', denuncia.pratica.anno, 'D')?.dataScadenza
            if (denuncia.pratica.data > dataScadenza) {
                warnings << "Data Pratica > Scadenza Denuncia per l'Anno ${denuncia.pratica.anno}"
            }

            if (denunceService.fCheckOgprARuolo(denuncia.pratica.id) && flagAnnullamentoOld != denuncia.pratica.flagAnnullamento) {
                warnings << "E' necessario procedere alla rideterminazione degli importi dovuti (Sgravio o Ricalcolo)"
            }

            if (!warnings.empty) {
                Clients.showNotification(StringUtils.join(warnings, "\n"), Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
            }

            caricaIter()
            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 2000, true)

            flagAnnullamentoOld = denuncia.pratica.flagAnnullamento

            aggiornaDataModifica()
            aggiornaUtente()

            denunciaSalvata = true
            BindUtils.postNotifyChange(null, null, this, "denunciaSalvata")
            BindUtils.postNotifyChange(null, null, this, "isDirty")
            BindUtils.postNotifyChange(null, null, this, "denuncia")
            BindUtils.postNotifyChange(null, null, this, "modifica")
            BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
            BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
            BindUtils.postNotifyChange(null, null, this, "abilitaFlagAnnullato")
        }
    }

    private eliminaDenuncia() {
        denunceService.eliminaPraticaTarsu(denuncia.pratica.id)
        chiudi()
    }

    private ricercaUtenzeTari() {
        commonService.creaPopup("/pratiche/denunce/utenzeTari.zul", self, [pratica: denuncia.pratica.id], { e ->
            if (e.data?.utenze) {

                // In caso di denuncia si verifica che non siano presenti sovrapposizioni
                def periodiOggetto = [:]

                if (denuncia.pratica.tipoPratica == 'D' & denuncia.pratica.tipoEvento.tipoEventoDenuncia == 'I') {
                    e.data?.utenze?.each {
                        def periodi = denunceService.fCheckPeriodiOggetto(
                                null,
                                it.oggetto as Long,
                                'TARSU',
                                denuncia.pratica.tipoPratica,
                                denuncia.pratica.tipoEvento.tipoEventoDenuncia,
                                denuncia.pratica.anno,
                                e.data.data1,
                                e.data.data2,
                                null, null, null, 'I'
                        )
                        if (!periodi.isEmpty()) {
                            periodiOggetto[(it.oggetto)] = periodi
                        }

                    }
                }

                if (periodiOggetto.isEmpty()) {
                    oggettiService.creaOggettoContribuenteTarsuDaLocazioniCessate(
                            denuncia.pratica.id,
                            e.data.utenze,
                            e.data.data1,
                            e.data.data2
                    )

                    listaLocaliAree = denunceService.getOggettiPratica(denuncia.pratica.id)
                    BindUtils.postNotifyChange(null, null, this, "listaLocaliAree")
                } else {
                    def message = ""

                    periodiOggetto.each { k, v ->
                        message += "Esistono periodi intersecanti per l'oggetto $k\n" +
                                "L'oggetto risulta dichiarato da"
                        v.each { periodo ->
                            def contribuente = Contribuente.findByCodFiscale(periodo.COD_FISCALE).toDTO(['soggetto'])
                            message += "\n$contribuente.soggetto.cognomeNome $contribuente.soggetto.codFiscale - Pratica $periodo.PRATICA - Anno $periodo.ANNO"
                        }
                        message += "\n\n"
                    }

                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "top_center", 5000, true)
                }
            }
        })
    }

    private daLocaliAreeEsistenti(def modalita) {
        commonService.creaPopup("pratiche/denunce/oggettoContribuenteTari.zul", self,
                [indexOggetto       : -1, listaOggetti: listaLocaliAree,
                 tipoTributo        : tipoTributoAttuale, idPratica: denuncia.pratica.id,
                 modalitaInserimento: modalita],
                { e ->
                    if (e.data?.ogcoCreata) {
                        listaLocaliAree = denunceService.getOggettiPratica(denuncia.pratica.id)
                        BindUtils.postNotifyChange(null, null, this, "listaLocaliAree")
                    }

                })
    }

    private eliminaArea() {

        def ogprInviatoARuolo = denunceService.fOgPrInviato(localeSelezionato.oggettoPratica.id)
        def errMsg = []

        if (ogprInviatoARuolo) {
            errMsg << "Oggetto pratica con ruolo inviati al consorzio"
        }
        if (!listaVersamenti.empty) {
            errMsg << "Esistono versamenti collegati alla pratica"
        }

        if (errMsg) {
            Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }

        errMsg << denunceService.eliminaOgCoTarsu(localeSelezionato)
        if (errMsg[0]) {
            Clients.showNotification(errMsg.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        } else {
            listaLocaliAree = denunceService.getOggettiPratica(denuncia.pratica.id)
            BindUtils.postNotifyChange(null, null, this, "listaLocaliAree")
            Clients.showNotification("Quadro eliminato", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
        }
    }

    @Command
    def onChiudiPopup() {

        if ((isDirty) && (modifica)) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    { e ->
                        if (Messagebox.ON_YES == e.name) {
                            onSalvaDenuncia()
                            chiudi()
                        } else if (Messagebox.ON_NO.equals(e.name))
                            chiudi()
                    }
            )
        } else {
            chiudi()
        }

    }


/**
 *  Metodo che viene richiamato dal metodo onSalvaDenuncia() solo al momento di creazione di una nuova denuncia
 */
    private def salvaDenunciaTari() {

        // Se si crea una nuova denuncia e prima di salvare si cambia l'anno, al salvataggio bisogna aggiornare il valore dell'anno precedente
        if (isNuovaDenuncia && valorePrecedenteAnno != null && valorePrecedenteAnno != denuncia.pratica.anno) {
            //Per triggerare l'else nel metodo DenunciaViewModel.onLockUnlockModificaAnno()
            sbloccaModificaAnnoVisibile = false
            onLockUnlockModificaAnno()
            isNuovaDenuncia = false
            BindUtils.postNotifyChange(null, null, this, "isNuovaDenuncia")
            return
        }

        // Altrimenti si salva nel modo predefinito
        salva()
    }

    private caricaIter() {
        if (denuncia.pratica.iter) {
            iter = denuncia.pratica.iter.sort { a, b -> b.data <=> a.data ?: b.id <=> a.id }

        } else {
            iter = []
        }
        BindUtils.postNotifyChange(null, null, this, 'iter')
    }

}
