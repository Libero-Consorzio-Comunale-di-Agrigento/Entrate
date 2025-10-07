package ufficiotributi.canoneunico

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoCarica
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.versamenti.VersamentiService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.text.SimpleDateFormat
import java.util.Calendar

class DichiarazioneCanoniCUViewModel {

    Window self

    // services
    CommonService commonService
    CanoneUnicoService canoneUnicoService
    ContribuentiService contribuentiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    RateazioneService rateazioneService
    VersamentiService versamentiService
    DenunceService denunceService

    // contreolli
    Bandbox bdRuoliVersamento
    Listbox lbRuoliVersamento
    Popup popupNote
    String notePerPopup

    def selectedTab
    String tabSelezionata = "canoni"

    // Generale
    def concessione = null

    EventListener<Event> isDirtyEvent = null
    Boolean isDirty = false
    Boolean saved = true

    ContribuenteDTO contribuenteRiferimento = null
    boolean modifica = false
    String tipoRapporto

    def listaCanoni = []
    def numCanoni = 0
    def canoneSelezionato
    def listaOggetti = []
    def numOggetti = 0
    def oggettoSelezionato
    List<VersamentoDTO> listaVersamenti = []
    def numVersamenti = 0
    Boolean versamentiCaricati = false
    double totVersamenti = 0.0

    def dovutiRateizzati = []
    def dovutiRateizzatiCaricato = false

    def totCanoni                // Totali, utilizzato in modulo pratiche

    String vecchioNumeroPratica

	def elencoMotivi = []
    def motivoSelezionato = null

    String lastUpdated
    def utente

    // Dati x ettaglio versamenti
    List<RuoloDTO> ruoliVersamento = []
    List<FonteDTO> listaFonti = []

    def listRata = [
            [codice: null, descrizione: ""],
            [codice: 0, descrizione: "Unica"],
            [codice: 1, descrizione: "Prima"],
            [codice: 2, descrizione: "Seconda"],
            [codice: 3, descrizione: "Terza"],
            [codice: 4, descrizione: "Quarta"]
    ]

    // Flag di stato vari
    boolean modificabile = false
    boolean modificaAnno = false
    boolean modificaTipoOccupazione = false
    boolean modificaCanone = false
    boolean modificaVersamenti = false
    boolean chiudibile = false
    boolean convertibile = false
    boolean duplicabile = false
    boolean eliminabile = false
    boolean calcolabile = false

    boolean quadroDenunciante = false

    boolean aggiornaStato = false

    def parametriBandBox = [
            annoTributo      : null,
            tipoTributo      : null,
            tipoOccupazione  : null,
            comuneDenunciante: [
                    denominazione: "",
                    provincia    : "",
                    siglaProv    : "",
            ],
            soggDenunciante  : [
                    id        : null,
                    codFiscale: ""
            ],
            caricaDenunciante: null
    ]

    def listaAnni = null

    List<TipoCaricaDTO> listaCariche = []

    def listTipiOccupazione = [
    ]

    def praticaSalvata = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("pratica") Long idPratica
         , @ExecutionArgParam("tipoRapporto") String tr
         , @ExecutionArgParam("lettura") boolean lt
         , @ExecutionArgParam("selected") def ss
         , @ExecutionArgParam("storica") def st
         , @ExecutionArgParam("daBonifiche") boolean db) {

        this.self = w

        tipoRapporto = tr ?: 'D'
        modifica = !lt

        def annoCorrente = Calendar.getInstance().get(Calendar.YEAR)

        listaAnni = []

        listaCariche = TipoCarica.findAllByIdGreaterThanEquals("0", [sort: "id", order: "asc"]).toDTO()
        listaCariche << new TipoCaricaDTO(id: null, descrizione: "")

        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        String codFiscale

        if (idPratica > 0) {
            concessione = canoneUnicoService.getConcessione()
            concessione = canoneUnicoService.fillConcessioneDaPratica(concessione, idPratica)
            codFiscale = concessione.contribuente
        } else {
            concessione = null
            codFiscale = ""
        }
		
        if (ss) {
            codFiscale = ss?.contribuenti[0]?.codFiscale?.toUpperCase() ?: ss?.codFiscale?.toUpperCase() ?: ss?.partitaIva?.toUpperCase()
        }

        Contribuente contribuenteRaw = canoneUnicoService.ricavaContribuente(codFiscale)
        contribuenteRiferimento = contribuenteRaw.toDTO(["soggetto", "ente"])

        if (contribuenteRiferimento == null) {
            throw new Exception("Contribuente non trovato in banca dati!")
        }

        if (concessione == null) {

            concessione = canoneUnicoService.getConcessione()
            concessione.contribuente = contribuenteRiferimento.codFiscale
            concessione.tipoRapporto = tipoRapporto

            concessione.anno = annoCorrente
            concessione.tipoTributo = parametriBandBox.tipoTributo

            concessione.dataPratica = canoneUnicoService.getDataOdierna()

            concessione.dettagli.tipoOccupazione = null
        }
		
        canoneSelezionato = null

        refresh(true)

        isDirtyEvent = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {
                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    isDirty = isDirty || (pe.property in [
                            'concessione',
                            'denunciante',
                            'caricaDenunciante',
                            'parametriBandBox',
                            'listaVersamenti',
                            'importoVersato',
                            'dataPagamento',
                            'dataReg',
                            'rata',
                            'note',
                            'ruolo',
                            'dataPratica',
                            'motivo',
                            'motivoSelezionato',
                            'indirizzoDen'
                    ])

                    if (pe.property == 'concessione' && saved) {
                        isDirty = false
                        saved = false
                    }
                }
            }
        }

        isDirty = !idPratica

		EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(isDirtyEvent)
    }

    // ############################################################################################################################
    //	Eventi interfaccia
    // ############################################################################################################################

    @Command
    def onApriSoggetto() {

        def idSoggetto = contribuenteRiferimento.soggetto.id

        Window w = Executions.createComponents("/archivio/soggetto.zul", self, [idSoggetto: idSoggetto])
        w.onClose {
            BindUtils.postNotifyChange(null, null, this, "contribuenteRiferimento")
        }
        w.doModal()
    }

    @Command
    def onSelectAnno() {

        def annoTributo = parametriBandBox.annoTributo as Integer

        if (annoTributo < 2021) {
            parametriBandBox.annoTributo = 2021
            annoTributo = parametriBandBox.annoTributo as Integer
        }
        if (annoTributo > 2099) {
            parametriBandBox.annoTributo = 2099
            annoTributo = parametriBandBox.annoTributo as Integer
        }

        if (annoTributo >= 2021) {
            parametriBandBox.tipoTributo = "CUNI"
        } else {
            if (parametriBandBox.tipoTributo == "CUNI") {
                parametriBandBox.tipoTributo = "ICP"
            }
        }

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onCheckTipoTributo() {

        def annoTributo = parametriBandBox.annoTributo as Integer

        if (parametriBandBox.tipoTributo == "CUNI") {
            if (annoTributo < 2021) parametriBandBox.annoTributo = 2021
        } else {
            if (annoTributo >= 2021) {
                parametriBandBox.tipoTributo = "CUNI"
            }
        }

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onSelectTipoOccupazione() {

    }

    @Command
    def onNumeraPratica() {

        /// Rimosso da interfaccia in quanto la numerazione è corretta solo per tipo_pratica in ('A','I','L','V','S')
        PraticaTributoDTO pratica = PraticaTributo.get(concessione.praticaRef).toDTO(['tipoTributo'])
        concessione.numeroPratica = liquidazioniAccertamentiService.numeraPratica(pratica).numero
        BindUtils.postNotifyChange(null, null, this, "concessione")

        isDirty = true
    }

    @Command()
    def onCambiaNumeroPratica() {

        isDirty = true

        if (concessione.numeroPratica) {

            Long praticaId = concessione.praticaRef

            TipoTributo tipoTributo = TipoTributo.get(concessione.tipoTributoPratica);
            def p = PraticaTributo.findAllByTipoTributoAndTipoPraticaAndNumero(tipoTributo, concessione.tipoPratica, concessione.numeroPratica)
            if (p && !p.find { it.id != praticaId }.collect { it }.isEmpty()) {

                def messaggioPratiche = ""

                p.findAll {
                    it.id != praticaId
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
                                        ripristinaNumeroPratica()
                                        break
                                }
                            }
                        }, params)
            }
        }
    }

    def ripristinaNumeroPratica() {

        concessione.numeroPratica = vecchioNumeroPratica
        BindUtils.postNotifyChange(null, null, this, "concessione")
    }

    @Command
    def onSelectCodFiscaleDen(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        SoggettoDTO selectedSoggetto = event?.data

        concessione.dettagli.codFisDen = selectedSoggetto.codFiscale

        String denunciante = selectedSoggetto.cognome ?: ''
        String nome = selectedSoggetto.nome ?: ''
        if (!(nome.isEmpty())) {
            denunciante += ' '
            denunciante += nome
        }
        if (denunciante.isEmpty()) denunciante = selectedSoggetto.cognomeNome
        concessione.dettagli.denunciante = denunciante

        BindUtils.postNotifyChange(null, null, this, "concessione")
    }

    @Command
    def onSelectComuneDen(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def selectedComune = event?.data
        def dettagli = concessione.dettagli

        if (selectedComune != null) {
            dettagli.codComDen = selectedComune.comune
            dettagli.codProDen = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
            dettagli.denComDen = selectedComune.denominazione
            dettagli.denProDen = selectedComune.provincia?.denominazione
            dettagli.sigProDen = selectedComune.provincia?.sigla
        } else {
            dettagli.codComDen = null
            dettagli.codProDen = null
            dettagli.denComDen = null
            dettagli.denProDen = null
            dettagli.sigProDen = null
        }

        parametriBandBox.comuneDenunciante.denominazione = dettagli.denComDen
        parametriBandBox.comuneDenunciante.provincia = dettagli.denProDen
        parametriBandBox.comuneDenunciante.siglaProv = dettagli.sigProDen

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        tabSelezionata = tabId
    }

    @Command
    def onCanoneSelected() {

    }

    @Command
    def onNuovoCanone() {

        modificaCanone(null, true)
    }

    @Command
    def onNuovoCanoneDaCessato() {

        commonService.creaPopup("/ufficiotributi/canoneunico/concessioniCU.zul", self,
                [
                        pratica: concessione.praticaRef as Long
                ],
                { event ->
                    if (event.data?.datiCanoni) {
                        aggiungiCanoni(event.data.datiCanoni)
                    }
                }
        )
    }

    @Command
    def onModificaCanone() {

        modificaCanone(canoneSelezionato)
    }

    @Command
    def onModificaOggetto() {

        Window w = Executions.createComponents("/archivio/oggetto.zul", self,
                [
                        oggetto: oggettoSelezionato.id,
                        lettura: true
                ]
        )
        w.onClose() { event ->
            if (event?.data?.salvato) {

            }
        }
        w.doModal()
    }

    @Command
    def onApriMotivo(@BindingParam("arg") def motivo) {

        Messagebox.show(motivo, "Motivo", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onSelezionaMotivo(@BindingParam("pu") Popup pu) {

        pu.close()
        concessione.dettagli.motivo = motivoSelezionato.motivo
        BindUtils.postNotifyChange(null, null, this, "concessione")
        /// Questo sblocca la riselezione della stessa motivo, altrimenti non possibile
        /// Ad esempio dopo una modifica manuale del valore campo
        motivoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "motivoSelezionato")
    }

    // ############################################################################################################################
    //	Pulsanti
    // ############################################################################################################################

    @Command
    def onRefresh() {

        refresh()
    }

    @Command
    def onRefreshTab() {

        onRefreshCanoni()
        onRefreshOggetti()

        if ((numOggetti != 0) && (numCanoni == 0)) {
            selectedTab = 1
        }
        BindUtils.postNotifyChange(null, null, this, "selectedTab")
    }

    @Command
    def onAggiornamentoCanoni() {
        onRefreshCanoni()
    }

    @Command
    def onRefreshCanoni() {

        listaCanoni = canoneUnicoService.getConcessioniDichiarazione(concessione.tipoTributo, concessione.praticaRef as Long)
        numCanoni = listaCanoni.size()
        canoneSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "numCanoni")
        BindUtils.postNotifyChange(null, null, this, "canoneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaCanoni")
    }

    @Command
    def onRefreshOggetti() {

        listaOggetti = contribuentiService.oggettiPraticaContribuente(concessione.praticaRef, contribuenteRiferimento.codFiscale, concessione.tipoTributo)
        numOggetti = listaOggetti.size()
        oggettoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "numOggetti")
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    @Command
    def onChiudiDichiarazione() {

        def report = canoneUnicoService.dichiarazioneChiudibile(concessione)

        if (report.result == 0) {

            def dataDecorrenza = concessione.dettagli.dataDecorrenza
            def dataChiusura = canoneUnicoService.getChiusuraAnno(-1).getTime()

            if (dataChiusura <= dataDecorrenza) {
                dataChiusura = canoneUnicoService.getDataOdierna()
            }

            boolean trasferisci = true

            Window w = Executions.createComponents("/ufficiotributi/canoneunico/chiudiConcessioneCU.zul", self,
                    [
                            anno          : null,
                            dataDecorrenza: dataDecorrenza,
                            dataChiusura  : dataChiusura,
                            trasferisci   : trasferisci,
                            listaCanoni   : listaCanoni
                    ]
            )
            w.onClose { event ->
                if (event.data) {
                    if (event.data.datiChiusura) {
                        chiudiDichiarazione(event.data.datiChiusura)
                    }
                }
            }
            w.doModal()
        } else {
            visualizzaReport(report, "")
        }
    }

    @Command
    def onEliminaDichiarazione() {

        def report = canoneUnicoService.concessioneEliminabile(concessione)

        if (report.result == 0) {

            String messaggio = "Eliminare la dichiarazione?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                if (eliminaDichiarazione()) {
                                    chiudi(true)
                                }
                            }
                        }
                    }
            )
        } else {

            visualizzaReport(report, "")
        }
    }

    @Command
    def onCalcolaImposta() {

    }

    @Command
    def onSalva() {
        salvaDichiarazione()
    }

    @Command
    def onChiudi() {

        if (isDirty) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                salvaDichiarazione()
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

    // ############################################################################################################################
    //	Versamenti
    // ############################################################################################################################

    @Command
    def onAggiungiVersamento() {

        def rataProposta = null

        PraticaTributoDTO pratica = PraticaTributo.get(concessione.praticaRef).toDTO()

        VersamentoDTO nuovoVersamento = new VersamentoDTO([
                tipoVersamento: TipoEventoDenuncia.U.tipoEventoDenuncia,
                dataReg       : new Date(),
                contribuente  : pratica.contribuente,
                anno          : pratica.anno,
                pratica       : pratica,
                tipoTributo   : pratica.tipoTributo,
                rata          : rataProposta,
                fonte         : listaFonti.find { it.fonte == 6 },
                sequenza      : nextMinSequenza()
        ])

        listaVersamenti.add(nuovoVersamento)

        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onDuplicaVersamento(@BindingParam("vers") def versamento) {

        def nuovoVersamento = new VersamentoDTO()

        InvokerHelper.setProperties(nuovoVersamento, versamento.properties)
        nuovoVersamento.sequenza = nextMinSequenza()
        nuovoVersamento.uuid = UUID.randomUUID().toString().replace('-', '')
        listaVersamenti.add(nuovoVersamento)

        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onCancellaVersamento(@BindingParam("vers") def versamento) {

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
    def onVersatoModificato(@BindingParam("vers") def versamento) {

        Short annoVersamento = concessione.anno

        String message = versamentiService.verificaVersamentoRata(versamento, annoVersamento, dovutiRateizzati, true)

        if (!message.isEmpty()) {
            def report = [
                    message: message,
                    result : 1
            ]
            visualizzaReport(report, '')
        }
    }

    @Command
    def onApriRuoloVersamento(@BindingParam("bd") Bandbox bd) {

        bdRuoliVersamento = bd
    }

    @Command
    def onSelezionaRuoloVersamento(@BindingParam("lb") Listbox lb, @BindingParam("vers") def vers) {

        bdRuoliVersamento?.close()
        bdRuoliVersamento?.text = vers.ruolo.id
        lbRuoliVersamento = lb

        // Boh !, non chiamato da framework : simuliamo, alla peggio lo fa due volte
        onCambiaRuoloVersamento(bdRuoliVersamento, vers)
    }

    @Command
    def onCambiaRuoloVersamento(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def vers) {

        if (!bd.text) {
            vers.ruolo = null
            lbRuoliVersamento.selectedItem = null
        } else {
            def ruoloId = bd.text as Long
            def ruolo = ruoliVersamento.find { it.id == ruoloId }
            if (!ruolo) {
                vers.ruolo = null
                lbRuoliVersamento?.selectedItem = null
                Clients.showNotification("Ruolo non previsto.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                vers.ruolo = ruolo
            }
        }
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onEliminaRuoloVersamento(@BindingParam("vers") def vers) {

        vers.ruolo = null
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    @Command
    def onApriNoteVersamento(@BindingParam("arg") def nota) {

        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onApriPopupNoteVersamento(@BindingParam("popup") Popup popup) {

        popupNote = popup
    }

    @Command
    def onChiudiPopupNoteVersamento() {

        popupNote.close()
        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    // ############################################################################################################################
    //	Funzioni interne
    // ############################################################################################################################

    // Refresh dell'interfaccia
    def refresh(def init = false) {

        listaAnni = canoneUnicoService.getElencoAnni()

        parametriBandBox.annoTributo = concessione.anno as Integer

        if (concessione.anno >= 2021) {
            parametriBandBox.tipoTributo = "CUNI"
        } else {
            parametriBandBox.tipoTributo = concessione.tipoTributo
        }

        listTipiOccupazione = []

        listTipiOccupazione << [codice: TipoOccupazione.P.id, descrizione: TipoOccupazione.P.descrizione, tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE]
        listTipiOccupazione << [codice: TipoOccupazione.T.id, descrizione: TipoOccupazione.T.descrizione, tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA]

        String tipoOccupazione

        if (concessione.tipoEvento == TipoEventoDenuncia.C.tipoEventoDenuncia) {
            tipoOccupazione = TipoEventoDenuncia.C.tipoEventoDenuncia
            listTipiOccupazione << [codice          : TipoEventoDenuncia.C.tipoEventoDenuncia, descrizione: TipoEventoDenuncia.C.descrizione,
                                    tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE]
        } else {
            if (concessione.tipoEvento == TipoEventoDenuncia.V.tipoEventoDenuncia) {
                tipoOccupazione = TipoEventoDenuncia.V.tipoEventoDenuncia
                listTipiOccupazione << [codice          : TipoEventoDenuncia.V.tipoEventoDenuncia, descrizione: TipoEventoDenuncia.V.descrizione,
                                        tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE]
            } else {
                tipoOccupazione = concessione.dettagli.tipoOccupazione
            }
        }

        parametriBandBox.tipoOccupazione = listTipiOccupazione.find { it.codice == tipoOccupazione }

        vecchioNumeroPratica = concessione.numeroPratica

        elencoMotivi = denunceService.elencoMotivazioni(concessione.tipoTributo, concessione.tipoPratica ?: 'D', concessione.anno)
        motivoSelezionato = null

        caricaDovutiRateizzati()
        caricaVersamenti(init)

        onRefreshTab()

        predisponiInterfaccia()

        aggiornaCalcolabile()

        aggiornaDataModifica()
        aggiornaUtente()

        if (!init) {
            BindUtils.postNotifyChange(null, null, this, "elencoMotivi")
            BindUtils.postNotifyChange(null, null, this, "motivoSelezionato")

            BindUtils.postNotifyChange(null, null, this, "listaAnni")
            BindUtils.postNotifyChange(null, null, this, "listTipiOccupazione")
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
            BindUtils.postNotifyChange(null, null, this, "concessione")
        }

    }

    // Modifica il canone o ne crea uno nuovo
    def modificaCanone(def canone, Boolean salvaDich = false) {

        if (salvaDich) {
            if (!salvaDichiarazione()) {
                return
            }
        }

        Window w = Executions.createComponents("/ufficiotributi/canoneunico/concessioneCU.zul", self,
                [
                        contribuente   : contribuenteRiferimento,
                        pratica        : concessione.praticaRef,
                        oggetto        : canone?.oggettoRef,
                        dataRiferimento: canone?.dettagli?.dataDecorrenza,
                        anno           : canone?.anno,
                        lettura        : !modifica
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

    // Elimina la consessione
    def eliminaDichiarazione() {

        def report = canoneUnicoService.eliminaDichiarazione(concessione)

        visualizzaReport(report, "Dichiarazione eliminato con successo !")

        if (report.result == 0) {

            aggiornaStato = true
            return true
        } else {

            return false
        }
    }

    // Aggiunge i canoni selezionati
    def aggiungiCanoni(def datiCanoni) {


        def dettagliSubentro = [
                soggSubentro         : contribuenteRiferimento.soggetto,
                dataInizioOccupazione: datiCanoni.dataInizioOccupazione,
                dataFineOccupazione  : datiCanoni.dataFineOccupazione,
                dataDecorrenza       : datiCanoni.dataDecorrenza,
                dataCessazione       : datiCanoni.dataCessazione,
                canoniInSubentro     : null,
                praticaRef           : concessione.praticaRef
        ]

        def report = canoneUnicoService.subentroConcessioni(datiCanoni.canoni, dettagliSubentro)

        visualizzaReport(report, "Canone/i aggiunto/i con successo !")

        aggiornaStato = true

        refresh()

        if (report.result == 0) {

            return true
        }

        return false
    }

    // Chiude la Dichiarazione creando evento "C"
    def chiudiDichiarazione(def datiChiusura) {

        String successMessage = "Dichiarazione chiusa con successo !"

        Date dataChiusura = datiChiusura.dataChiusura
        Date fineOccupazione = datiChiusura.dataFineOccupazione
        def canoniDaChiudere = datiChiusura.canoniDaChiudere

        def report = canoneUnicoService.chiudiDichiarazione(concessione, dataChiusura, fineOccupazione, canoniDaChiudere)

        if (report.result == 0) {

            concessione = report.concessione
            refresh()

            if (datiChiusura.soggDestinazione) {

                def dettagliSubentro = [
                        soggSubentro         : datiChiusura.soggDestinazione,
                        dataInizioOccupazione: datiChiusura.dataInizioOccupazione,
                        dataFineOccupazione  : null,
                        dataDecorrenza       : datiChiusura.dataDecorrenza,
                        dataCessazione       : null,
                        canoniInSubentro     : datiChiusura.canoniDaChiudere,
                        praticaRef           : 0,
                ]

                report = canoneUnicoService.subentroDichiarazione(concessione, dettagliSubentro)

                successMessage = "Subentro dichiarazione avvenuto con successo !"
            }
        }

        visualizzaReport(report, successMessage)

        aggiornaStato = true

        if (report.result == 0) {

            return true
        }

        return false
    }

    // Salva la dichiarazione
    def salvaDichiarazione() {

        completaDichiarazione()

        if (!verificaDichiarazione()) {
            return false
        }

        def report = canoneUnicoService.salvaDichiarazione(concessione)
        concessione = report.concessione

        versamentiCaricati = false

        visualizzaReport(report, "Dichiarazione salvata con successo")

        refresh(true)

        self.invalidate()

        aggiornaStato = true

        isDirty = false
        saved = true

        praticaSalvata = true

        BindUtils.postNotifyChange(null, null, this, "concessione")
        BindUtils.postNotifyChange(null, null, this, "praticaSalvata")

        return (report.result == 0)
    }

    // Completa la concessione prima di salvare
    def completaDichiarazione() {

        def dettagli = concessione.dettagli

        concessione.anno = parametriBandBox.annoTributo as Short
        concessione.tipoTributo = parametriBandBox.tipoTributo

        dettagli.tipoOccupazione = parametriBandBox.tipoOccupazione?.codice

        dettagli.codFiscaleDen = parametriBandBox.soggDenunciante.codFiscale
        dettagli.tipoCarica = parametriBandBox.caricaDenunciante?.id

        def denominazioneComune = parametriBandBox.comuneDenunciante?.denominazione
        if ((denominazioneComune != null) && (denominazioneComune.size() == 0)) {
            denominazioneComune = null
        }

        if (denominazioneComune == null) {
            onSelectComuneDen(null)
        }

        concessione.codiceTributo = null
        concessione.categoria = null
        concessione.tariffa = null

        concessione.codiceTributoSec = null
        concessione.categoriaSec = null
        concessione.tariffaSec = null

        if (versamentiCaricati) {
            concessione.versamenti = listaVersamenti
        } else {
            concessione.versamenti = null
        }
    }

    // Verifica preliminare della concessione
    def verificaDichiarazione() {

        String message = ""
        boolean result = true

        caricaDovutiRateizzati()

        def report = canoneUnicoService.verificaDichiarazione(concessione, null)
        if (report.result != 0) {
            message = report.message
        }

        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    // Predispone interfaccia dopo assegnazione concessione
    def predisponiInterfaccia() {

        Long praticaId = concessione.praticaRef ?: 0

        def dettagli = concessione.dettagli

        parametriBandBox.soggDenunciante.codFiscale = dettagli.codFisDen

        parametriBandBox.comuneDenunciante.denominazione = dettagli.denComDen
        parametriBandBox.comuneDenunciante.provincia = dettagli.denProDen
        parametriBandBox.comuneDenunciante.siglaProv = dettagli.sigProDen

        def tipoCaricaNum = dettagli.tipoCarica ?: 0
        parametriBandBox.caricaDenunciante = listaCariche.find { it.id == tipoCaricaNum }

        eliminabile = false
        modificabile = false
        convertibile = false
        chiudibile = false
        duplicabile = false

        if (modifica) {
            if (praticaId > 0) {

                if (concessione.anno >= 2021) {
                    eliminabile = true
                    modificabile = true
                }

                if (concessione.tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia,
                                               TipoEventoDenuncia.V.tipoEventoDenuncia]) {

                    if (concessione.dettagli.dataCessazione == null) {
                        chiudibile = true
                    } else {
                        modificabile = false
                    }
                }
            } else {
                modificabile = true
            }
        }

        def oggetti = OggettoPratica.createCriteria().count {
            eq('pratica.id', praticaId)
        }

        if (concessione.tipoEvento != TipoEventoDenuncia.C.tipoEventoDenuncia) {
            modificaCanone = modificabile
            modificaVersamenti = modificabile && (praticaId > 0)
        } else {
            modificaCanone = false
            modificaVersamenti = false
        }

        modificaAnno = (modificabile) ? ((praticaId) ? false : true) : false
        modificaTipoOccupazione = (modificabile) ? ((praticaId) ? false : true) : false

        if (!quadroDenunciante) {
            if ((concessione.dettagli.denunciante ?: "").size() > 0) {
                quadroDenunciante = true
            }
        }

        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "eliminabile")
        BindUtils.postNotifyChange(null, null, this, "convertibile")
        BindUtils.postNotifyChange(null, null, this, "duplicabile")
        BindUtils.postNotifyChange(null, null, this, "chiudibile")

        BindUtils.postNotifyChange(null, null, this, "modificaAnno")
        BindUtils.postNotifyChange(null, null, this, "modificaTipoOccupazione")

        BindUtils.postNotifyChange(null, null, this, "quadroDenunciante")
    }

    // Aggiorna l'attributo calcolabile
    def aggiornaCalcolabile() {

        calcolabile = false

        BindUtils.postNotifyChange(null, null, this, "calcolabile")
    }

    // Carica versamenti pratica
    private caricaVersamenti(def init = false) {

        if (!versamentiCaricati) {

            Long praticaId = concessione.praticaRef ?: 0
            listaVersamenti = liquidazioniAccertamentiService.getVersamentiPratica(praticaId)

            versamentiCaricati = true

            caricaRuoliVersamento()

            if (!init) {
                BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
            }
        }

        aggiornaStatisticheVersamenti()
    }

    // Carica elenco dovuti rateizzati
    void caricaDovutiRateizzati() {

        Long praticaId = concessione.praticaRef ?: 0

        if (!dovutiRateizzatiCaricato && (praticaId > 0)) {
            dovutiRateizzati = versamentiService.getElencoDovutiPerPratica(praticaId,
                    contribuenteRiferimento.codFiscale, parametriBandBox.tipoTributo)
            dovutiRateizzatiCaricato = true
        }
    }

    // Elimina versamento da lista
    private eliminaVersamento(def versamento) {

        // Elimina versamenti appena creati senza sequenza
        listaVersamenti = listaVersamenti.findAll { versamento.sequenza != it.sequenza }

        BindUtils.postNotifyChange(null, null, this, "listaVersamenti")
    }

    // Carica elenco ruoli da versamenti
    private void caricaRuoliVersamento() {

        ruoliVersamento = liquidazioniAccertamentiService.elencoRuoliVersamento(concessione.tipoTributo,
                concessione.anno, concessione.contribuente)
        BindUtils.postNotifyChange(null, null, this, "ruoliVersamento")
    }

    // Aggiorna statistiche versamenti
    def aggiornaStatisticheVersamenti() {

        numVersamenti = listaVersamenti.size()

        totVersamenti = 0

        for (v in listaVersamenti) {
            totVersamenti += v.importoVersato ?: 0
        }

        BindUtils.postNotifyChange(null, null, this, "totVersamenti")
        BindUtils.postNotifyChange(null, null, this, "numVersamenti")
    }

    // Aggiorna data ultima variazione
    private
    def aggiornaDataModifica() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        def date = concessione?.lastUpdatedPratica
        lastUpdated = (date) ? sdf.format(date) : ''
        BindUtils.postNotifyChange(null, null, this, "lastUpdated")
    }


    private
    def aggiornaUtente() {
        utente = concessione?.utentePratica
        BindUtils.postNotifyChange(null, null, this, "utente")
    }

    // Visualizza report
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self,
                            "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self,
                        "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self,
                        "before_center", 10000, true)
                break
        }
    }

    // Chiude form
    private def chiudi(def praticaEliminata = false) {

        if (isDirtyEvent) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(isDirtyEvent)
            isDirtyEvent = null
        }

        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, salvato: praticaSalvata, praticaEliminata: praticaEliminata])
    }

    // Si associa ad un nuovo versamento un numero di sequenza negativa per avere una chiave primaria,
    // la sequenza verrà poi ricalcolata in fase di salvataggio nel db
    private nextMinSequenza() {
        return (listaVersamenti
                .findAll { it.sequenza < 0 }
                .collect { it.sequenza }?.min() ?: 0) - 1
    }
}
