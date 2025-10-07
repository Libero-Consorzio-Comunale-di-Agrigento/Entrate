package versamenti

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.competenze.CompetenzaScrittura
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.versamenti.VersamentiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.util.Calendar

class VersamentoViewModel {

    private static final Long FONTE_VERSAMENTI = 6

    // Components
    Window self
    Tabbox tbVersamentiTabbox    // Assegnati al run-time
    Listbox lbRuoliVersamento
    Bandbox bdRuoliVersamento

    SpringSecurityService springSecurityService
    CommonService commonService
    ContribuentiService contribuentiService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    VersamentiService versamentiService
    CompetenzeService competenzeService
    IntegrazioneDePagService integrazioneDePagService

    // Generali
    boolean aggiornaStato = false
    // Flag da inviare a parent che indica avvenuta modifica in db che comporta refresh

    boolean singolo                        // Versamento singolo - Vedi pi� avanti nel codice

    boolean esistente
    boolean modifica
    boolean trasferisci

    EventListener<Event> isDirtyEvent = null
    boolean isDirty

    boolean modificaAnno

    boolean modificaSuOggetti
    boolean modificaCumulativi
    boolean modificaSuOggettiInit

    Short anno
    ContribuenteDTO contribuente
    SoggettoDTO soggetto
    VersamentoDTO versamento
    Short annoVersamento
    String annoVC
    String annoVCAttivo
    Short annoVCPerRuoli

    Popup popupNote = null

    def versamentiTab

    def anniConVersamentiSuOggetto
    def anniConVersamentiCumulativi

    List<RuoloDTO> elencoRuoliVersamenti
    def ruoliVersamentiOggetto
    def ruoliVersamentoCumulativo

    def elencoDovutiRateizzati
    def elencoDovutiRateizzatiCaricato = false

    def elencoFatture

    def listaAnniOggettiVersamento
    def annoOggettiVersamentoSelezionato
    def listaOggettiVersamento
    def oggettoVersamentoSelezionato

    def elencoVersamentiOggetto
    def listaVersamentiOggetto
    def versamentoOggettoSelected
    def versamentoOggettoSelectedPrev

    Double totaleVersamentiOggetto

    def listaAnniCumulativo

    def elencoVersamentiCumulativi
    def listaVersamentiCumulativi

    Double dovutoVersamentiCumulativi
    Double totaleVersamentiCumulativi

    def tipoTributo
    String tipoTributoDescr

    def importoTotale
    def tipoPratica
    def praticaPratica
    def numeroPratica
    def numeroPraticaToolTip

    List<FonteDTO> listaFonti

	def listServizi = []

    def listaAnni = null
    def listRata = [
            [codice: 0, descrizione: "Unica"],
            [codice: 1, descrizione: "Prima"],
            [codice: 2, descrizione: "Seconda"],
            [codice: 3, descrizione: "Terza"],
            [codice: 4, descrizione: "Quarta"]
    ]
    def tipiVersamento = [
            'A' : 'Acconto',
            'S' : 'Saldo',
            'U' : 'Unico',
            null: ''
    ]
    def listRataICI = [
            [codice: null, descrizione: ""],
    ]
    def rataSelezionata

    def tipiPratica = [
            [codice: TipoPratica.A.tipoPratica, descrizione: TipoPratica.A.descrizione],
            [codice: TipoPratica.D.tipoPratica, descrizione: TipoPratica.D.descrizione],
            [codice: TipoPratica.L.tipoPratica, descrizione: TipoPratica.L.descrizione],
            [codice: TipoPratica.I.tipoPratica, descrizione: TipoPratica.I.descrizione],
            [codice: TipoPratica.C.tipoPratica, descrizione: TipoPratica.C.descrizione],
            [codice: TipoPratica.K.tipoPratica, descrizione: TipoPratica.K.descrizione],
            [codice: TipoPratica.T.tipoPratica, descrizione: TipoPratica.T.descrizione],
            [codice: TipoPratica.V.tipoPratica, descrizione: TipoPratica.V.descrizione],
            [codice: TipoPratica.G.tipoPratica, descrizione: TipoPratica.G.descrizione],
    ]

    def versamentoSalvato = false
    def versamentoEliminato = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codFiscale") String codFiscale,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("anno") Short aa,
         @ExecutionArgParam("sequenza") Short sequenza,
         @ExecutionArgParam("lettura") boolean ll,
         @ExecutionArgParam("trasferisci") boolean tr) {

        self = w

        tipoTributo = tt

        def tipoAbilitazione = competenzeService.tipoAbilitazioneUtente(tipoTributo)
        if (tipoAbilitazione != 'A') ll = true
        if (tipoAbilitazione != 'A') tr = false

        modifica = !ll
        trasferisci = tr
        anno = aa

        annoVC = aa as String
        annoVCAttivo = annoVC
        annoVCPerRuoli = -1

        modificaAnno = modifica
        esistente = (sequenza != 0)

        TipoTributo tipoTributoObj = TipoTributo.findByTipoTributo(tipoTributo)
        tipoTributoDescr = tipoTributoObj.getTipoTributoAttuale(anno)

        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

		listServizi = []
		if(tipoTributo == 'CUNI') {
			def elencoServizi = integrazioneDePagService.getElencoServizi(tipoTributo)
			listServizi << [ servizio : null, descrizione : '-' ]
			elencoServizi.each {
				listServizi << it
			}
		}
		
        Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR)
        def anniPrec = commonService.decodificaAnniPresSucc()
        Short annoIniziale = annoCorrente - anniPrec.anniPrec
        Short annoFinale = annoCorrente + anniPrec.anniSucc

        listaAnni = []
        for (def anno = annoFinale; anno >= annoIniziale; anno--) {
            listaAnni << anno.toString()
        }
        if(annoVCAttivo) {
            if(!listaAnni.find { it == annoVCAttivo }) {
                listaAnni << annoVCAttivo
            }
        }

        Contribuente contribuenteRaw = Contribuente.findByCodFiscale(codFiscale)
        if (contribuenteRaw == null) {
            contribuenteRaw = new Contribuente()
            Soggetto soggettoRaw = Soggetto.findByCodFiscale(codFiscale)
            if (soggettoRaw == null) {
                soggettoRaw = Soggetto.findByPartitaIva(codFiscale)
                if (soggettoRaw == null) {
                    throw new Exception("Soggetto ${codFiscale} non trovato !")
                }
            }
            contribuenteRaw.soggetto = soggettoRaw
            contribuenteRaw.codFiscale = codFiscale
            contribuenteRaw.save(flush: true, failOnError: true)
        }

        contribuente = contribuenteRaw.toDTO(["soggetto"])
        soggetto = contribuente.soggetto

        listRata.each {
            listRataICI << it
        }

        // Verifica se versamento singolo
        //	-> Tutti i versamenti ICI o TASI e gli altri versamenti se collegati ad una pratica
        VersamentoDTO versamentoOrg = null
        PraticaTributoDTO praticaVers = null

        if (sequenza) {
            versamentoOrg = versamentiService.getVersamento(codFiscale, anno, tipoTributo, sequenza)
        }
        if (versamentoOrg != null) {
            praticaVers = versamentoOrg.pratica
        }
        singolo = ((praticaVers != null) || (tipoTributo in ['ICI', 'TASI'])) ? true : false

        if (singolo) {
            if (tipoTributo in ['ICI', 'TASI']) {
                this.self.setWidth("60%")
            } else {
                this.self.setWidth("50%")
            }
        } else {
            this.self.setWidth("96%")
        }

        if (singolo) {
            if (versamentoOrg == null) {
                versamentoOrg = new VersamentoDTO()
                versamentoOrg.tipoTributo = tipoTributoObj.toDTO()
                versamentoOrg.anno = anno
                versamentoOrg.contribuente = contribuente
                versamentoOrg.fonte = Fonte.findById(FONTE_VERSAMENTI).toDTO()
            }

            impostaVersamento(versamentoOrg, false)
        } else {
            trasferisci = false

            versamentoOrg = new VersamentoDTO()
            versamentoOrg.tipoTributo = tipoTributoObj.toDTO()

            impostaVersamento(versamentoOrg, false)
        }

        ricaricaDatiVersamentiMultipli()

        isDirty = false
        isDirtyEvent = new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {
                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
					isDirty = isDirty || (pe.property in [
                            'annoVersamento',
                            'tipoVersamento',
                            'rataSelezionata',
                            'importoVersato',
                            'dataPagamento',
                            'detrazione',
                            'terreniAgricoli',
                            'terreniComune',
                            'terreniErariale',
                            'areeFabbricabili',
                            'areeComune',
                            'areeErariale',
                            'abPrincipale',
                            'rurali',
                            'ruraliComune',
                            'ruraliErariale',
                            'altriFabbricati',
                            'altriComune',
                            'altriErariale',
                            'fabbricatiD',
                            'fabbricatiDComune',
                            'fabbricatiDErariale',
                            'fabbricatiMerce',
                            'numFabbricatiTerreni',
                            'numFabbricatiAree',
                            'numFabbricatiAb',
                            'numFabbricatiRurali',
                            'numFabbricatiAltri',
                            'numFabbricatiD',
                            'numFabbricatiMerce',
                            'fabbricati',
                            'fonte',
                            'fonteDTO',
                            'note',
                            'documentoId',
                            'dataReg'
                    ])
                }
            }
        }

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(isDirtyEvent)
    }

    @Command
    def onInitialTimer() {

        if (tbVersamentiTabbox) {

            if (modificaSuOggetti != modificaSuOggettiInit) {

                //
                // Forziamo il refresh altrimenti non compare il '+' sui versamenti
                //
                if (tbVersamentiTabbox) {
                    tbVersamentiTabbox.setSelectedIndex(1)
                    tbVersamentiTabbox.setSelectedIndex(0)
                }
                self.invalidate()
            }
        }
    }

    @Command
    def onCreateVersamentiTabbox(@BindingParam("tabbox") Tabbox tb) {

        tbVersamentiTabbox = tb
    }

    @Command
    def onVersamentoTabs(@BindingParam("tab") def tab) {

        //
        // Applichiamo l'altra pagina, quindi agguiorniamo quella nuova
        //
        switch (tab) {
            case 'versSuOggetto':
                applicaVersamentiCumulativi()
                refreshVersamentiOggettoPerModifica()
                break
            case 'versCumulativi':
                applicaVersamentiOggetto()
                ricavaListaVersamentiCumulativi(false)
                refreshVersamentiCumulativiPerModifica()
                break
        }
    }

    @Command
    def onApriSoggetto() {

        def idSoggetto = soggetto.id

        Window w = Executions.createComponents("/archivio/soggetto.zul", self, [idSoggetto: idSoggetto])
        w.onClose {
            BindUtils.postNotifyChange(null, null, this, "contribuenteRiferimento")
        }
        w.doModal()
    }

    @Command
    def onOpenSituazioneContribuente() {

        def ni = Contribuente.findByCodFiscale(contribuente?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onChangeVersato() {

        if (tipoTributo in ['CUNI', 'ICP', 'TOSAP', 'TARSU']) {
            if ((versamento.imposta ?: 0) == 0) {

                BigDecimal versato = versamento.importoVersato ?: 0
                BigDecimal dovuto = versamento.getTotaleDaVersare()

                if (versato > dovuto) {
                    versamento.imposta = versato - dovuto
                    BindUtils.postNotifyChange(null, null, this, "versamento")
                    aggiornaTotale()
                }
            }
        }
    }

    @Command
    def onChangeTotale() {

        aggiornaTotale()
    }

    @Command
    def onChangeFabbricati() {

        aggiornaFabbricati()
    }

    @Command
    def onScollegaVersamento() {

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
                }
        )
    }

    @Command
    def onCollegaVersamento() {

        Window w = Executions.createComponents("/versamenti/versamentoSelezionaPratica.zul", self,
                [
                        codFiscale : versamento.contribuente.codFiscale,
                        anno       : annoVersamento,
                        tipoTributo: versamento.tipoTributo.tipoTributo
                ]
        )
        w.onClose { event ->
            if (event.data) {

                def praticaId = event.data.pratica
                PraticaTributoDTO pratica = PraticaTributo.findById(praticaId).toDTO()
                collegaVersamentoPratica(pratica)
            }
        }
        w.doModal()
    }

    @Command
    def onDuplicaVersamento() {

        def modifiche

        modifiche = modifica & isDirty

        if (modifiche) {
            String messaggio = "Versamento modificato.\nTutte le modifiche andranno perse\n\nProcedere ?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                duplicaVersamento()
                            }
                        }
                    }
            )
        } else {
            duplicaVersamento()
        }
    }

    @Command
    def onEliminaVersamento() {

        String messaggio = "Confermi di voler eliminare definitivamente il Versamento ?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            if (tipoTributo == 'ICI') {
                                eliminaVersamentoICI()
                            } else if (tipoTributo == 'TASI') {
                                eliminaVersamentoTASI()
                            } else if (tipoTributo == 'TARSU') {
                                eliminaVersamentoTARSU()
                            } else if (tipoTributo == 'ICP') {
                                eliminaVersamentoICP()
                            } else if (tipoTributo == 'TOSAP') {
                                eliminaVersamentoTOSAP()
                            } else if (tipoTributo == 'CUNI') {
                                eliminaVersamentoCUNI()
                            } else {
                                throw new Exception("Funzione non implementata : Elimina Versamento ${tipoTributo}")
                            }
                        }
                    }
                }
        )
    }

    @CompetenzaScrittura(oggetto = "ICI")
    def eliminaVersamentoICI() {
        eliminaVersamento()
    }

    @CompetenzaScrittura(oggetto = "TASI")
    def eliminaVersamentoTASI() {
        eliminaVersamento()
    }

    @CompetenzaScrittura(oggetto = "TARSU")
    def eliminaVersamentoTARSU() {

        if (singolo) {
            eliminaVersamento()
        } else {
            throw new Exception("Funzione non implementata : Elimina Versamento TARSU")
        }
    }

    @CompetenzaScrittura(oggetto = "ICP")
    def eliminaVersamentoICP() {

        if (singolo) {
            eliminaVersamento()
        } else {
            throw new Exception("Funzione non implementata : Elimina Versamento ICP")
        }
    }

    @CompetenzaScrittura(oggetto = "TOSAP")
    def eliminaVersamentoTOSAP() {

        if (singolo) {
            eliminaVersamento()
        } else {
            throw new Exception("Funzione non implementata : Elimina Versamento TOSAP")
        }
    }

    @CompetenzaScrittura(oggetto = "CUNI")
    def eliminaVersamentoCUNI() {

        if (singolo) {
            eliminaVersamento()
        } else {
            throw new Exception("Funzione non implementata : Elimina Versamento CUNI")
        }
    }

    @Command
    def onSalvaVersamento() {

        if (!singolo) {

            applicaVersamentiOggetto()
            if (!validaVersamentiOggetto()) {
                return
            }

            applicaVersamentiCumulativi()
            aggiornaTotaleVersamentiCumulativi()

            if (!validaVersamentiCumulativi()) {
                return
            }
        } else {
            if (!validaVersamento()) {
                return
            }
        }

        String messaggio = "Confermi di voler salvare le modifiche ?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            if (tipoTributo == 'ICI') {
                                salvaVersamentoICI()
                            } else if (tipoTributo == 'TASI') {
                                salvaVersamentoTASI()
                            } else if (tipoTributo == 'TARSU') {
                                salvaVersamentoTARSU()
                            } else if (tipoTributo == 'ICP') {
                                salvaVersamentoICP()
                            } else if (tipoTributo == 'TOSAP') {
                                salvaVersamentoTOSAP()
                            } else if (tipoTributo == 'CUNI') {
                                salvaVersamentoCUNI()
                            } else {
                                throw new Exception("Funzione non implementata : Salva Versamento ${tipoTributo}")
                            }
                        }
                    }
                }
        )
    }

    @CompetenzaScrittura(oggetto = "ICI")
    def salvaVersamentoICI() {

        salvaVersamento()
    }

    @CompetenzaScrittura(oggetto = "TASI")
    def salvaVersamentoTASI() {

        salvaVersamento()
    }

    @CompetenzaScrittura(oggetto = "TARSU")
    def salvaVersamentoTARSU() {

        if (singolo) {
            salvaVersamento()
        } else {
            salvaVersamentoTribMin()
        }
    }

    @CompetenzaScrittura(oggetto = "ICP")
    def salvaVersamentoICP() {

        if (singolo) {
            salvaVersamento()
        } else {
            salvaVersamentoTribMin()
        }
    }

    @CompetenzaScrittura(oggetto = "TOSAP")
    def salvaVersamentoTOSAP() {

        if (singolo) {
            salvaVersamento()
        } else {
            salvaVersamentoTribMin()
        }
    }

    @CompetenzaScrittura(oggetto = "CUNI")
    def salvaVersamentoCUNI() {

        if (singolo) {
            salvaVersamento()
        } else {
            salvaVersamentoTribMin()
        }
    }

    @Command
    onChiudi() {

        def modifiche

        if (singolo) {
            modifiche = modifica && isDirty
        } else {
            modifiche =
                    !checkVersamentiOggettiModificati() ||
                            !checkVersamentiCumulativiModificati()
        }

        if (modifiche) {
            String messaggio = "Chiudere e annullare le eventuali modifiche ?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {

                                chiudi()
                            }
                        }
                    }
            )
        } else {
            chiudi()
        }
    }

    protected chiudi() {

        if (isDirtyEvent) {
            EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
            queue.unsubscribe(isDirtyEvent)
            isDirtyEvent = null
        }

        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, salvato: versamentoSalvato, praticaEliminata: versamentoEliminato])
    }

    @Command
    def onSelezionaAnnoOggettiVersamento() {

        applicaVersamentiOggetto()

        aggiornaRuoliVersamentiOggetto()
        aggiornaOggettiVersamento()

        caricaVersamentiOggetto()
    }

    @Command
    def onSelezionaOggettoVersamento() {

        applicaVersamentiOggetto()

        caricaVersamentiOggetto()
        aggiornaTotaleVersamentiOggetto()
    }

    @Command
    def onVersamentoOggettoSelected() {

    }

    @Command
    def onClickVersamentoOggetto(@BindingParam("versamento") def vers) {

		if (vers) {
			if (versamentoOggettoSelected != vers) {
				versamentoOggettoSelectedPrev = versamentoOggettoSelected
				versamentoOggettoSelected = vers
				BindUtils.postNotifyChange(null, null, this, "versamentoOggettoSelected")
			}
		}
    }

    @Command
    def onSelectVersamentoOggetto() {

    }

    @Command
    def onChangeVersatoVO(@BindingParam("vers") def vers) {

		contrassegnaVersamentiOggettoModificato(vers)
		
        versamentiService.aggiornaImportoVersamento(vers)
		
		aggiornaTotaleVersamentiOggetto()
		
		BindUtils.postNotifyChange(null, null, this, "versamentoOggettoSelected")
    }

    @Command
    def onChangeImportoVO(@BindingParam("vers") def vers) {

		contrassegnaVersamentiOggettoModificato(vers)
		
        versamentiService.aggiornaImportoVersamento(vers)
		
		BindUtils.postNotifyChange(null, null, this, "versamentoOggettoSelected")
    }

    @Command
    def onChangeVO(@BindingParam("vers") def vers) {

		contrassegnaVersamentiOggettoModificato(vers)
    }

    @Command
    def onNuovoVersamentoOggetto() {

        applicaVersamentiOggetto()

        creaVersamentoOggetto(null)

        ricavaListaVersamentiOggetto(true)
    }

    @Command
    def onDuplicaVersamentoOggetto(@BindingParam("versamento") def vers) {

        applicaVersamentiOggetto()

        def originale = elencoVersamentiOggetto.find { it.id == vers.id }
        creaVersamentoOggetto(originale)

        ricavaListaVersamentiOggetto(false)
        aggiornaTotaleVersamentiOggetto()
    }

    @Command
    def onEliminaVersamentoOggetto(@BindingParam("versamento") def vers) {

        def originale = elencoVersamentiOggetto.find { it.id == vers.id }
        originale.esistente = false
        originale.modificato = false

        ricavaListaVersamentiOggetto(false)
        aggiornaTotaleVersamentiOggetto()
    }

    @Command
    def onApriRuoloVO(@BindingParam("bd") Bandbox bd) {

        bdRuoliVersamento = bd
    }

    @Command
    def onSelezionaRuoloVO(@BindingParam("lb") Listbox lb, @BindingParam("vers") def vers) {

        bdRuoliVersamento?.close()
        bdRuoliVersamento?.text = vers.ruolo.id
        lbRuoliVersamento = lb

        onCambiaRuoloVO(bdRuoliVersamento, vers)
    }

    @Command
    def onCambiaRuoloVO(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def vo) {

        def vers = listaVersamentiOggetto.find { it.id == vo.id }
		
		contrassegnaVersamentiOggettoModificato(vers)
		
        if (!bd.text) {
            vers.ruolo = null
            lbRuoliVersamento.selectedItem = null
        } else {
            def ruoloId = bd.text as Long
            def ruolo = ruoliVersamentiOggetto.find { it.id == ruoloId }
            if (!ruolo) {
                vers.ruolo = null
                lbRuoliVersamento?.selectedItem = null
                Clients.showNotification("Ruolo non previsto.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            } else {
                vers.ruolo = ruolo
            }
        }
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiOggetto")
    }

    @Command
    def onEliminaRuoloVO(@BindingParam("vers") def vers) {

        vers.ruolo = null
		
		contrassegnaVersamentiOggettoModificato(vers)
		
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiOggetto")
    }

    @Command
    def onChangeVersatoVC(@BindingParam("vers") def vers) {

		contrassegnaVersamentiCumulativoModificato(vers)
		
        versamentiService.aggiornaImportoVersamento(vers)

        aggiornaTotaleVersamentiCumulativi()
		
        BindUtils.postNotifyChange(null, null, vers, "imposta")
    }

    @Command
    def onChangeImportoVC(@BindingParam("vers") def vers) {
		
		contrassegnaVersamentiCumulativoModificato(vers)
		
        versamentiService.aggiornaImportoVersamento(vers)

        BindUtils.postNotifyChange(null, null, vers, "imposta")
    }

    @Command
    def onChangeVC(@BindingParam("vers") def vers) {

		contrassegnaVersamentiCumulativoModificato(vers)
    }

    @Command
    def onNuovoVersamentoCumulativo() {

        applicaVersamentiCumulativi()

        creaVersamentoCumulativo(null)

        ricavaListaVersamentiCumulativi(true)
    }

    @Command
    def onCambioAnnoVersamentiCumulativi() {

        if (annoVCAttivo != annoVC) {
            boolean modifiche = !checkVersamentiCumulativiModificati()
            if (modifiche) {
                String messaggio = "Dati modificati : Annullare le eventuali modifiche ?"
                Messagebox.show(messaggio, "Attenzione",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    attivaAnnoVersamentiCumulativi(annoVC)
                                } else {
                                    attivaAnnoVersamentiCumulativi(annoVCAttivo)
                                }
                            }
                        }
                )
            } else {
                attivaAnnoVersamentiCumulativi(annoVC)
            }
        }
    }

    @Command
    def onCambioAnnoVersamentoCumulativo(@BindingParam("vers") def vers) {

		contrassegnaVersamentiCumulativoModificato(vers)
		
        if (vers.ruolo != null) {

            vers.ruolo = null
            BindUtils.postNotifyChange(null, null, this, "listaVersamentiCumulativi")
        }
    }

    @Command
    def onDuplicaVersamentoCumulativo(@BindingParam("versamento") def vers) {

        applicaVersamentiCumulativi()

        def originale = elencoVersamentiCumulativi.find { it.id == vers.id }
        creaVersamentoCumulativo(originale)

        ricavaListaVersamentiCumulativi(false)
        aggiornaTotaleVersamentiCumulativi()
    }

    @Command
    def onEliminaVersamentoCumulativo(@BindingParam("versamento") def vers) {

        def originale = elencoVersamentiCumulativi.find { it.id == vers.id }

        def opposto = versamentiService.getVersamentoOpposto(vers)

        // Esiste il versamento opposto in compensazione, si chiede all'utente se desidera cancellarlo
        // In caso negativo, non si cancella nessun versamento
        if (opposto != null) {
            Messagebox.show("Esiste un altro versamento associato alla stessa compensazione.\nSi desidera eliminare entrambi i versamenti?", "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new EventListener() {
                        void onEvent(Event e) {

                            if (Messagebox.ON_YES.equals(e.getName())) {
                                originale.esistente = false
                                originale.modificato = false

                                // Parametro che serve per stabilire se eliminare o meno il versamento opposto
                                originale.eliminaVersOpposto = true

                                versamentoEliminato = true
                                BindUtils.postNotifyChange(null, null, this, "versamentoEliminato")

                                ricavaListaVersamentiCumulativi(false)
                                aggiornaTotaleVersamentiCumulativi()
                            }
                        }
                    }
            )
        } else {
            // Non esiste il versamento opposto in compensazione, si procede normalmente
            originale.esistente = false
            originale.modificato = false

            versamentoEliminato = true
            BindUtils.postNotifyChange(null, null, this, "versamentoEliminato")

            ricavaListaVersamentiCumulativi(false)
            aggiornaTotaleVersamentiCumulativi()
        }
    }

    @Command
    def onApriRuoloVC(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def vers) {

        aggiornaRuoliVersamentoCumulativo(vers.anno)

        bdRuoliVersamento = bd
    }

    @Command
    def onSelezionaRuoloVC(@BindingParam("lb") Listbox lb, @BindingParam("vers") def vers) {

        bdRuoliVersamento?.close()
        bdRuoliVersamento?.text = vers.ruolo.id
        lbRuoliVersamento = lb

        onCambiaRuoloVC(bdRuoliVersamento, vers)
    }

    @Command
    def onCambiaRuoloVC(@BindingParam("bd") Bandbox bd, @BindingParam("vers") def vo) {

        def vers = listaVersamentiCumulativi.find { it.id == vo.id }
		
		contrassegnaVersamentiCumulativoModificato(vers)
		
        if (!bd.text) {
            vers.ruolo = null
            lbRuoliVersamento.selectedItem = null
        } else {
            def ruoloId = bd.text as Long
            def ruolo = ruoliVersamentoCumulativo.find { it.id == ruoloId }
            if (!ruolo) {
                vers.ruolo = null
                lbRuoliVersamento?.selectedItem = null
                Clients.showNotification("Ruolo non previsto.", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            } else {
                vers.ruolo = ruolo
            }
        }
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiCumulativi")
    }

    @Command
    def onEliminaRuoloVC(@BindingParam("vers") def vers) {

        vers.ruolo = null
		
		contrassegnaVersamentiCumulativoModificato(vers)
		
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiCumulativi")
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote() {
        popupNote.close()
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiCumulativi")
    }

    // Imposta versamento singolo attivo
    def impostaVersamento(VersamentoDTO versamentoOrg, Boolean postNotify) {

        versamento = versamentoOrg

        annoVersamento = versamento.anno
        rataSelezionata = listRataICI.find { it.codice == versamento.rata }

        if (postNotify) {
            BindUtils.postNotifyChange(null, null, this, "versamento")
            BindUtils.postNotifyChange(null, null, this, "annoVersamento")
            BindUtils.postNotifyChange(null, null, this, "rataSelezionata")
        }
    }

    // Completa versamento singolo
    def completaVersamento() {

        versamento.rata = rataSelezionata?.codice as Short
    }

    // Valida versamento singolo
    Boolean validaVersamento() {

        def report = [
                message: "",
                result : 0
        ]

        completaVersamento()

        try {
            caricaElencoDovutiRateizzati()
            report = versamentiService.verificaVersamento(versamento, annoVersamento, elencoDovutiRateizzati)
        }
        catch (Exception e) {
            if (e instanceof Application20999Error) {
                report.message = e.getMessage()
                report.result = 2
            } else {
                throw e
            }
        }
        visualizzaReport(report, "")

        return (report.result < 2)
    }

    // Duplica versamewnto singolo
    def duplicaVersamento() {

        def report = [
                message: "",
                result : 0
        ]

        VersamentoDTO versamentoOrg
        VersamentoDTO versamentoDup

        versamentoOrg = versamentiService.getVersamento(contribuente.codFiscale, anno, tipoTributo, versamento.sequenza)

        versamentoDup = new VersamentoDTO()
        versamentoDup.tipoTributo = versamento.tipoTributo
        versamentoDup.anno = versamento.anno
        versamentoDup.contribuente = contribuente
        versamentoDup.fonte = versamento.fonte

        versamentiService.applicaModificheVersamento(versamentoOrg, versamentoDup)

        impostaVersamento(versamentoDup, true)

        visualizzaReport(report, "Duplicazione eseguita !")

        isDirty = true

        esistente = false
        BindUtils.postNotifyChange(null, null, this, "esistente")
    }

    // Elimina versamento singolo
    def eliminaVersamento() {

        def report = [
                message: "",
                result : 0
        ]

        try {
            versamentiService.eliminaVersamento(versamento)
        }
        catch (Exception e) {
            if (e instanceof Application20999Error) {
                report.message = e.getMessage()
                report.result = 2
            } else {
                throw e
            }
        }
        visualizzaReport(report, "Versamento eliminato.")

        versamentoEliminato = true
        BindUtils.postNotifyChange(null, null, this, "versamentoEliminato")

        if (report.result == 0) {
            aggiornaStato = true
            chiudi()
        }
    }

    // Salva versamento singolo
    def salvaVersamento() {

        def report = [
                message: "",
                result : 0
        ]

        completaVersamento()

        try {
            caricaElencoDovutiRateizzati()
            report = versamentiService.verificaVersamento(versamento, annoVersamento, elencoDovutiRateizzati)

            if (report.result < 2) {
                versamento = versamentiService.aggiornaVersamento(versamento, annoVersamento)
            }
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                report.message = e.getMessage()
                report.result = 2
            } else {
                throw e
            }
        }
        visualizzaReport(report, "Versamento aggiornato correttamente.")

        versamentoSalvato = true
        BindUtils.postNotifyChange(null, null, this, "versamentoSalvato")

        if (report.result < 2) {
            aggiornaStato = true
            isDirty = false
        }
    }

    def aggiornaTotale() {

        importoTotale = versamento.getTotaleDaVersare()
        BindUtils.postNotifyChange(null, null, this, "importoTotale")
    }

    def aggiornaFabbricati() {

        versamento.fabbricati = versamento.getTotaleFabbricati()
        BindUtils.postNotifyChange(null, null, this, "versamento")
    }

    def aggiornaDatiPratica() {

        String tipoPraticaId

        tipoPratica = ""
        praticaPratica = ""
        numeroPratica = ""

        Short annoVersPrat = versamento.anno

        if (versamento.pratica != null) {

            tipoPraticaId = versamento.pratica.tipoPratica
            tipoPratica = (tipiPratica.find { it.codice == tipoPraticaId }?.descrizione) ?: ""

            praticaPratica = versamento.pratica.id as String
            numeroPratica = versamento.pratica.numero ?: ""
            annoVersPrat = versamento.pratica.anno

            if (numeroPratica.isEmpty()) {
                numeroPratica = "Senza Numero"
            }

            numeroPraticaToolTip = "Pratica " + praticaPratica
        }

        BindUtils.postNotifyChange(null, null, this, "tipoPratica")
        BindUtils.postNotifyChange(null, null, this, "numeroPratica")

        if (annoVersPrat != annoVersamento) {
            annoVersamento = annoVersPrat
            BindUtils.postNotifyChange(null, null, this, "annoVersamento")
        }
    }

    def collegaVersamentoPratica(PraticaTributoDTO pratica) {

        if (!modifica) {

            try {
                versamentiService.collegaPratica(versamento, pratica)
            }
            catch (Exception e) {
                if (e instanceof Application20999Error) {
                    Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                    return
                } else {
                    throw e
                }
            }

            chiudi()
        } else {
            versamento.pratica = pratica
        }

        isDirty = true

        aggiornaDatiPratica()
    }

    // Ricarica i dati dei Versamenti su Oggetto e/o Cumulativi
    def ricaricaDatiVersamentiMultipli() {

        String codFiscale = contribuente?.codFiscale ?: '-'

        // Svuota tutto pre caricamento
        anniConVersamentiSuOggetto = []
        anniConVersamentiCumulativi = []

        elencoRuoliVersamenti = []
        ruoliVersamentiOggetto = []
        ruoliVersamentoCumulativo = []

        elencoDovutiRateizzati = []
        elencoDovutiRateizzatiCaricato = false

        elencoFatture = []

        listaAnniOggettiVersamento = []
        annoOggettiVersamentoSelezionato = null
        listaOggettiVersamento = []
        oggettoVersamentoSelezionato = null

        elencoVersamentiOggetto = []
        listaVersamentiOggetto = []
        versamentoOggettoSelected = null
        versamentoOggettoSelectedPrev = null

        totaleVersamentiOggetto = 0

        listaAnniCumulativo = []

        elencoVersamentiCumulativi = []
        listaVersamentiCumulativi = []

        dovutoVersamentiCumulativi = 0
        totaleVersamentiCumulativi = 0

        modificaSuOggetti = true
        modificaCumulativi = true

        if (!singolo) {

            caricaStoricoAnniConVersamenti()

            elencoRuoliVersamenti = liquidazioniAccertamentiService.elencoRuoliVersamento(tipoTributo, -1, codFiscale)

            listaAnniOggettiVersamento = versamentiService.getAnnualitaOggettiVersamento(codFiscale, tipoTributo)

            if (listaAnniOggettiVersamento.size() < 1) {
                listaAnniOggettiVersamento << (anno as Short)
            }
            if (listaAnniOggettiVersamento.find { it == anno }) {
                annoOggettiVersamentoSelezionato = anno
            } else {
                annoOggettiVersamentoSelezionato = listaAnniOggettiVersamento[0]
            }

            def elencoFattureNow = versamentiService.getElencoFatture(codFiscale)
            elencoFatture << [numero: null, descrizione: '']
            elencoFattureNow.each {
                elencoFatture << it
            }

            aggiornaListaAnniVersamentiCumulativi()

            caricaVersamentiCumulativi()

            aggiornaRuoliVersamentiOggetto()
            aggiornaOggettiVersamento()

            caricaVersamentiOggetto()
        }

        aggiornaTotale()
        aggiornaDatiPratica()

        aggiornaTotaleVersamentiCumulativi()
        aggiornaDovutoVersamentiCumulativi()

        aggiornaTotaleVersamentiOggetto()

        modificaSuOggettiInit = modificaSuOggetti

        if (!singolo) {

            // Se nuovo e non ci sono versamenti su Oggetti oppure se ci sono versamenti cumulativi passa subito al panel 1
            def sdfCheckOgg = anniConVersamentiSuOggetto.find { it.anno == anno }?.versamenti ?: 0
            def sdfCheckCum = anniConVersamentiCumulativi.find { it.anno == anno }?.versamenti ?: 0
            if ((sdfCheckCum > 0) || ((sdfCheckOgg < 1) && !esistente)) {
                versamentiTab = 1
            }

            if (!esistente && (sdfCheckOgg > 0)) {
                String message = "Attenzione : esistono versamenti sugli Oggetti di Imposta per l\'anno ${anno}\n\n" +
                        "Impossibile aggiungere Versamenti Cumulativi per tale annualita\'"
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 15000, true)
            }
        }
    }

    // Salva versamento multiplo : cumulativo o per oggetto
    def salvaVersamentoTribMin() {

        applicaVersamentiOggetto()
        if (!validaVersamentiOggetto()) {
            return
        }

        applicaVersamentiCumulativi()
        if (!validaVersamentiCumulativi()) {
            return
        }

        try {
            elencoVersamentiOggetto.each {
                salvaVersamentoTribMinSingolo(it)
            }

            elencoVersamentiCumulativi.each {
                salvaVersamentoTribMinSingolo(it)
            }
        }
        catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return
            } else {
                throw e
            }
        }

        esistente = true

        aggiornaStato = true
        isDirty = false

        versamentoSalvato = true
        BindUtils.postNotifyChange(null, null, this, "versamentoSalvato")

        Clients.showNotification("Dati Versamenti aggiornati correttamente.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

        ricaricaDatiVersamentiMultipli()

        self.invalidate()
    }

    // Salva un elemento di un versamento multiplo cumulativo e/o per oggetto
    def salvaVersamentoTribMinSingolo(def versDef) {

        VersamentoDTO versamentoDTO
        Short annoNuovo

        if (versDef.esistente == false) {
            if (versDef.sequenza != 0) {

                versamentoDTO = versamentiService.getVersamento(versDef.codFiscale as String, versDef.annoOrig as Short,
                        versDef.tipoTributo as String, versDef.sequenza as Short)

                versamentiService.eliminaVersamento(versamentoDTO)

                versamentoEliminato = true
                BindUtils.postNotifyChange(null, null, this, "versamentoEliminato")


                // Eliminazione versamento opposto
                if (versDef?.eliminaVersOpposto) {
                    VersamentoDTO versamentoOppostoDTO = versamentiService.getVersamentoOpposto(versDef).toDTO()
                    versamentiService.eliminaVersamento(versamentoOppostoDTO)
                }

                versDef.sequenza = 0
            }
        } else {
            if (versDef.modificato != false) {

                annoNuovo = versDef.anno

                if (versDef.sequenza != 0) {
                    versamentoDTO = versamentiService.getVersamento(versDef.codFiscale as String, versDef.annoOrig as Short,
                            versDef.tipoTributo as String, versDef.sequenza as Short)
                } else {
                    versamentoDTO = null
                }
                if (versamentoDTO == null) {

                    versamentoDTO = new VersamentoDTO()

                    versamentoDTO.contribuente = contribuente
                    versamentoDTO.tipoTributo = TipoTributo.findByTipoTributo(versDef.tipoTributo).toDTO()
                    versamentoDTO.sequenza = 0

                    def oggettoImpostaId = versDef.oggettoImposta ?: -1
                    def oggettoImposta = OggettoImposta.get(oggettoImpostaId)?.toDTO()
                    versamentoDTO.oggettoImposta = oggettoImposta

                    versamentoDTO.anno = 0
                }
				
				def fonteId = versDef.fonte ?: FONTE_VERSAMENTI
				versamentoDTO.fonte = Fonte.findById(fonteId).toDTO()

                versamentiService.applicaModificheVersamento(versDef, versamentoDTO)

                caricaElencoDovutiRateizzati()
                versamentiService.verificaVersamento(versamentoDTO, annoNuovo, elencoDovutiRateizzati)

                versamentiService.aggiornaVersamento(versamentoDTO, annoNuovo)

                versDef.modificato = false
            }
        }

        versamentoSalvato = true
        BindUtils.postNotifyChange(null, null, this, "versamentoSalvato")
    }

    // Ricarica elenco ruoli per versamenti su oggetto
    def aggiornaRuoliVersamentiOggetto() {

        ruoliVersamentiOggetto = elencoRuoliVersamenti.findAll { it.annoRuolo == annoOggettiVersamentoSelezionato }
        BindUtils.postNotifyChange(null, null, this, "ruoliVersamentiOggetto")
    }

    // Ricarica Oggeti di Imposta per anno selezionato
    def aggiornaOggettiVersamento() {

        def anno = annoOggettiVersamentoSelezionato ?: 0

        listaOggettiVersamento = versamentiService.getOggettiVersamento(contribuente.codFiscale, anno, tipoTributo)

        if (listaOggettiVersamento.size() > 0) {
            oggettoVersamentoSelezionato = listaOggettiVersamento[0]
        } else {
            oggettoVersamentoSelezionato = null
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggettiVersamento")
        BindUtils.postNotifyChange(null, null, this, "oggettoVersamentoSelezionato")
    }

    // Carica versamenti per Oggetto di Imposta selezionato
    def caricaVersamentiOggetto() {

        def anno = annoOggettiVersamentoSelezionato ?: 0
        def oggettoImposta = oggettoVersamentoSelezionato?.oggettoImposta ?: 0

        def versamentiOggetto = elencoVersamentiOggetto.findAll { it.anno == anno && it.oggettoImposta == oggettoImposta }
        if (versamentiOggetto.size() < 1) {

            def maxId = elencoVersamentiOggetto.max { it.id ?: 0 }
            def nextId = (maxId?.id ?: 0) + 1

            versamentiOggetto = versamentiService.getVersamentiOggetto(contribuente.codFiscale, anno, tipoTributo, oggettoImposta)
            versamentiOggetto.each {

                it.id = nextId++
                completaVersamentoEsistente(it)

                elencoVersamentiOggetto << it
            }
        }

        refreshVersamentiOggettoPerModifica()

        ricavaListaVersamentiOggetto(false)
    }

    // Refresh flag modifica Versamenti su Oggetti
    def refreshVersamentiOggettoPerModifica() {

        def anno = annoOggettiVersamentoSelezionato ?: 0

        def sdfCheck = anniConVersamentiCumulativi.find { it.anno == anno }?.versamenti ?: 0
        def versamentiCheck = elencoVersamentiCumulativi.findAll { (it.anno == anno) && (it.esistente != false) }
        modificaSuOggetti = !((versamentiCheck.size() > 0) || (sdfCheck > 0))

        BindUtils.postNotifyChange(null, null, this, "modificaSuOggetti")
    }

    // Ricarica versamenti per Oggetto di Imposta selezionato
    def ricavaListaVersamentiOggetto(Boolean select) {

        def anno = annoOggettiVersamentoSelezionato ?: 0
        def oggettoImposta = oggettoVersamentoSelezionato?.oggettoImposta ?: 0

        def versamento
        String versamentoAnno

        def versamentiOggetto = elencoVersamentiOggetto.findAll { it.anno == anno && it.oggettoImposta == oggettoImposta }

        listaVersamentiOggetto = []

        versamentiOggetto.each {

            def originale = it

            if (originale.esistente != false) {

                versamento = originale.clone()
                versamentoAnno = originale.anno.toString()

                versamento.annoCombo = versamentoAnno
                versamento.rataCombo = listRata.find { it.codice == originale.rata }
                versamento.fatturaCombo = elencoFatture.find { it.fattura == originale.fattura }

                listaVersamentiOggetto << versamento
            }
        }

        versamento = null
        if (select && (versamentoOggettoSelected != null)) {
            versamento = listaVersamentiOggetto.find { it.id == versamentoOggettoSelected.id }
        }

        versamentoOggettoSelected = versamento
        versamentoOggettoSelectedPrev = null

        BindUtils.postNotifyChange(null, null, this, "listaVersamentiOggetto")
        BindUtils.postNotifyChange(null, null, this, "versamentoOggettoSelected")
    }

    // Crea versamento su oggetto, nuovo o come copia da template
    def creaVersamentoOggetto(def template, def oggettoImposta = null) {

        Short annoVers = (annoOggettiVersamentoSelezionato ?: 0) as Short

        if (oggettoImposta == null) {
            oggettoImposta = oggettoVersamentoSelezionato?.oggettoImposta ?: 0
        }

        def maxId = elencoVersamentiOggetto.max { it.id ?: 0 }
        def nextId = (maxId?.id ?: 0) + 1

        def nuovoVersamento = creaVersamento(nextId, annoVers, template)
        nuovoVersamento.oggettoImposta = oggettoImposta

        elencoVersamentiOggetto << nuovoVersamento
    }

    // Contrassegna un versamento originale come modificato
	def contrassegnaVersamentiOggettoModificato(def vers) {
		
		def originale
		
		if (vers) {
			if (versamentoOggettoSelectedPrev != vers) {
				originale = elencoVersamentiOggetto.find { it.id == vers.id }
				originale.modificato = true
			}
		}
	}

    // Valida i versamenti su oggetto -> True se tutto ok
    Boolean validaVersamentiOggetto() {

        String message = ""
        String messageThis

        elencoVersamentiOggetto.each {

            if (it.esistente != false) {

                messageThis = validaVersamentoOggetto(it, it.id)
                if (!messageThis.isEmpty()) {
                    message += messageThis
                }
            }
        }

        if (!message.isEmpty()) {
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
        }

        return message.isEmpty()
    }

    // Valida il versamento su oggetto
    String validaVersamentoOggetto(def versamento, def versamentoId) {

        String message = ""
        String prefix = ""

        OggettoImposta oggettoImposta
        OggettoContribuente oggettoContribuente
        OggettoPratica oggettoPratica

        Short annoVers = versamento.anno
        def oggetto = 0

        def oggettiImpostaId = versamento.oggettoImposta
        oggettoImposta = OggettoImposta.get(oggettiImpostaId)
        if (oggettoImposta != null) {

            oggettoContribuente = oggettoImposta.oggettoContribuente
            if (oggettoContribuente != null) {
                oggettoPratica = oggettoContribuente.oggettoPratica
                oggetto = oggettoPratica?.oggetto?.id ?: 0
            }
        }

        if (versamentoId > 0) {
            prefix = "Anno ${annoVers}, Oggetto ${oggetto}, Riga " + (versamentoId as String) + " : "
        }

        if (versamento.importoVersato == null) {
            message += "- " + prefix + "Imp. Versato obbligatorio !\n"
        }
        if (versamento.dataPagamento == null) {
            message += "- " + prefix + "Data Pag. obbligatorio !\n"
        }

        return message
    };

    // Attiva annualit� per versamenti cumulativi, notifica UI, ricarica e aggiorna totali
    def attivaAnnoVersamentiCumulativi(String annoVCNuovo) {

        if (annoVCNuovo != annoVC) {
            annoVC = annoVCNuovo
            BindUtils.postNotifyChange(null, null, this, "annoVC")
        }
        annoVCAttivo = annoVC

        Short annoNuovo = annoVC as Short
        if (annoNuovo != anno) {
            anno = annoNuovo
            BindUtils.postNotifyChange(null, null, this, "anno")

            caricaVersamentiCumulativi()

            aggiornaTotaleVersamentiCumulativi()
            aggiornaDovutoVersamentiCumulativi()
        }
    }

    // Applica modifiche rilevanti a tutti i versamenti su oggetto in elenco
    def applicaVersamentiOggetto() {

        listaVersamentiOggetto.each {
            applicaVersamentoOggetto(it)
        }
    }

    // Applica modifiche rilevanti a versamento su oggetto originale
    def applicaVersamentoOggetto(def modificato) {

        def originale = elencoVersamentiOggetto.find { it.id == modificato.id }

        modificato.anno = (modificato.annoCombo) ? modificato.annoCombo as Short : anno
        modificato.rata = modificato.rataCombo?.codice ?: 0
        modificato.fattura = modificato.fatturaCombo?.fattura ?: null

        originale.anno = modificato.anno
        originale.rata = modificato.rata
        originale.fattura = modificato.fattura

        originale.importoVersato = modificato.importoVersato
        originale.dataPagamento = modificato.dataPagamento
        originale.dataReg = modificato.dataReg
        originale.documentoId = modificato.documentoId

        originale.interessi = modificato.interessi
        originale.sanzioni1 = modificato.sanzioni1
        originale.sanzioni2 = modificato.sanzioni2

        originale.maggiorazioneTares = modificato.maggiorazioneTares

        originale.addizionalePro = modificato.addizionalePro
        originale.sanzioniAddPro = modificato.sanzioniAddPro
        originale.interessiAddPro = modificato.interessiAddPro

        originale.speseSpedizione = modificato.speseSpedizione
        originale.speseMora = modificato.speseMora

        originale.numBollettino = modificato.numBollettino
        originale.rataImposta = modificato.rataImposta
        originale.fattura = modificato.fattura
        originale.descrizione = modificato.descrizione
        originale.provvedimento = modificato.provvedimento
        originale.ufficioPt = modificato.ufficioPt
        originale.causale = modificato.causale
        originale.note = modificato.note

        originale.ruolo = modificato.ruolo
        originale.ruoloId = modificato.ruolo?.id

        originale.idCompensazione = null
        originale.chkCompensazione = false

        originale.fonte = modificato.fonte
        originale.utente = modificato.utente
        originale.dataVariazione = modificato.dataVariazione

        versamentiService.aggiornaImportoVersamento(originale)

        originale.modificato = true

        return originale
    }

    // Aggiorna totali versamenti cumulativi
    def aggiornaTotaleVersamentiOggetto() {

        def listaVersamenti = listaVersamentiOggetto.findAll { it.esistente != false }
        totaleVersamentiOggetto = (listaVersamenti.sum { it.importoVersato ?: 0 } ?: 0)

        BindUtils.postNotifyChange(null, null, this, "totaleVersamentiOggetto")
    }

    // Verifica Versamenti su Oggetto modificati : false -> presenza di modificati		//	o in fase di modifica
    def checkVersamentiOggettiModificati() {

        Boolean result = true

        def inModifica = []    //	listaVersamentiOggetto.findAll { it.modifica != false }
        def modificati = elencoVersamentiOggetto.findAll { (it.modificato != false) || ((it.esistente == false) && (it.sequenza != 0)) }
        if ((inModifica.size() > 0) || (modificati.size() > 0)) {
            result = false
        }

        return result
    }

    // Ricarica eleneco ruoli per versamento cumulativo
    //		Riporta : false -> anno non variato, true -> anno variato
    def aggiornaRuoliVersamentoCumulativo(def annoVersamento) {

        def annoVCSelected = annoVersamento as Short

        if (annoVCPerRuoli != annoVCSelected) {

            ruoliVersamentoCumulativo = elencoRuoliVersamenti.findAll { it.annoRuolo == annoVCSelected }
            BindUtils.postNotifyChange(null, null, this, "ruoliVersamentoCumulativo")

            annoVCPerRuoli = annoVCSelected

            return true
        }

        return false
    }

    // Ricarica lista Anni validi per Versamenti Cumulativi, escludendo quelli con Versamenti su Oggetto
    def aggiornaListaAnniVersamentiCumulativi() {

        listaAnniCumulativo = []
        listaAnni.each {

            def annoToCheck = it
            def annoShort = annoToCheck as Short

            def sdfCheck = anniConVersamentiSuOggetto.find { it.anno == annoShort }?.versamenti ?: 0
            def versamentiCheck = elencoVersamentiOggetto.findAll { (it.anno == annoShort) && (it.esistente != false) }
            def valido = !((versamentiCheck.size() > 0) || (sdfCheck > 0))

            if (valido) {
                listaAnniCumulativo << annoToCheck
            }
        }
    }

    // Carica versamenti cumulativi oppure crea nuovo
    def caricaVersamentiCumulativi() {

        def sdfCheck = anniConVersamentiSuOggetto.find { it.anno == anno }?.versamenti ?: 0

        if (esistente || (sdfCheck > 0)) {
            elencoVersamentiCumulativi = versamentiService.getVersamentiCumulativi(contribuente.codFiscale, anno, tipoTributo)
            elencoVersamentiCumulativi.each {

                completaVersamentoEsistente(it)
            }
        } else {
            elencoVersamentiCumulativi = []
            creaVersamentoCumulativo(null)
        }

        ricavaListaVersamentiCumulativi(true)
    }

    // Refresh flag modifica Versamenti Cumulativi
    def refreshVersamentiCumulativiPerModifica() {

        modificaCumulativi = (listaAnniCumulativo.size() > 0)

        BindUtils.postNotifyChange(null, null, this, "modificaCumulativi")
    }

    // Ricava lista da elenco filtrando per storicizzazione
    def ricavaListaVersamentiCumulativi(Boolean select) {

        String versamentoAnno
        def versamento

        def listAnniEntry

        aggiornaListaAnniVersamentiCumulativi()
        refreshVersamentiCumulativiPerModifica()

        listaVersamentiCumulativi = []

        elencoVersamentiCumulativi.each {

            def originale = it

            if (originale.esistente != false) {

                versamento = originale.clone()
                versamentoAnno = originale.anno.toString()

                versamento.annoCombo = versamentoAnno
                versamento.rataCombo = listRata.find { it.codice == originale.rata }
                versamento.fatturaCombo = elencoFatture.find { it.fattura == originale.fattura }
				versamento.servizioCombo = listServizi.find { it.servizio == originale.servizio }
				
				versamento.fonteDTO = Fonte.findById(versamento.fonte).toDTO()

                listAnniEntry = listaAnniCumulativo.find { it == versamentoAnno }
                if (listAnniEntry == null) {
                    listaAnniCumulativo << versamentoAnno
                }

                listaVersamentiCumulativi << versamento
            }
        }

        BindUtils.postNotifyChange(null, null, this, "listaAnniCumulativo")
        BindUtils.postNotifyChange(null, null, this, "listaVersamentiCumulativi")

        def annoVCInElenco = listaAnniCumulativo.find { it == annoVC }
        if (annoVCInElenco == null) {
            annoVCAttivo = annoVC = null
            BindUtils.postNotifyChange(null, null, this, "annoVC")
        }
    }

    // Crea versamento comulativo, nuovo o come copia da template
    def creaVersamentoCumulativo(def template) {

        Short annoVers = anno

        String annoStr = annoVers as String
        def annoCheck = listaAnniCumulativo.find { it == annoStr }
        if (annoCheck == null) {
            annoVers = listaAnniCumulativo[0] as Short
        }

        def maxId = elencoVersamentiCumulativi.max { it.id ?: 0 }
        def nextId = (maxId?.id ?: 0) + 1

        def nuovoVersamento = creaVersamento(nextId, annoVers, template)
        nuovoVersamento.oggettoImposta = null

        elencoVersamentiCumulativi << nuovoVersamento
    }
	
    // Contrassegna un versamento originale come modificato
	def contrassegnaVersamentiCumulativoModificato(def vers) {
		
		def originale
		
		if (vers) {
			originale = elencoVersamentiCumulativi.find { it.id == vers.id }
			originale.modificato = true
		}
	}

    // Valida i versamento cumulativi -> True se tutto ok
    Boolean validaVersamentiCumulativi() {

        def report = [
                message: "",
                result : 0
        ]

        def reportThis

        listaVersamentiCumulativi.each {

            reportThis = validaVersamentoCumulativo(it, it.id)
            if (reportThis.result > 0) {
                if (reportThis.result > report.result) {
                    report.result = reportThis.result
                }
                report.message += reportThis.message
            }
        }

        reportThis = verificaTotaleVersamentiCumulativi()
        if (reportThis.result > 0) {
            if (reportThis.result > report.result) {
                report.result = reportThis.result
            }
            report.message += reportThis.message
        }

        visualizzaReport(report, "")

        return (reportThis.result < 2)
    }

    // Valida il versamento cumulativo
    def validaVersamentoCumulativo(def versamento, def versamentoId) {

        String message = ""
        Integer result = 0

        String prefix = ""

        if (versamentoId > 0) {
            prefix = "Riga " + (versamentoId as String) + " : "
        }

        if (versamento.importoVersato == null) {
            message += "- " + prefix + "Imp. Versato obbligatorio !\n"
            if (result < 2) result = 2
        }
        if (versamento.dataPagamento == null) {
            message += "- " + prefix + "Data Pag. obbligatorio !\n"
            if (result < 2) result = 2
        }

        caricaElencoDovutiRateizzati()
        String messageRata = versamentiService.verificaVersamentoRata(versamento, versamento.anno as Short, elencoDovutiRateizzati)
        if (!messageRata.isEmpty()) {
            message += "- " + prefix + messageRata.substring(2, messageRata.length())
            if (result < 1) result = 1
        }

        return [result: result, message: message]
    };

    // Applica modifiche rilevanti a tutti i versamenti in elenco
    def applicaVersamentiCumulativi() {

        listaVersamentiCumulativi.each {
            applicaVersamentoCumulativo(it)
        }
    }

    // Applica modifiche rilevanti a versamento originale
    def applicaVersamentoCumulativo(def modificato) {

        def originale = elencoVersamentiCumulativi.find { it.id == modificato.id }

        modificato.anno = (modificato.anno as Short) ?: (modificato.annoCombo as Short) ?: anno
        addAnnoToListaAnniIfMissing(modificato.anno as String)

        modificato.rata = modificato.rataCombo?.codice ?: 0
        modificato.fattura = modificato.fatturaCombo?.fattura
		modificato.servizio = modificato.servizioCombo?.servizio

        originale.anno = modificato.anno
        originale.rata = modificato.rata
        originale.fattura = modificato.fattura
		originale.servizio = modificato.servizio

        originale.importoVersato = modificato.importoVersato
        originale.dataPagamento = modificato.dataPagamento
        originale.dataReg = modificato.dataReg
        originale.documentoId = modificato.documentoId

        originale.interessi = modificato.interessi
        originale.sanzioni1 = modificato.sanzioni1
        originale.sanzioni2 = modificato.sanzioni2

        originale.maggiorazioneTares = modificato.maggiorazioneTares

        originale.addizionalePro = modificato.addizionalePro
        originale.sanzioniAddPro = modificato.sanzioniAddPro
        originale.interessiAddPro = modificato.interessiAddPro

        originale.speseSpedizione = modificato.speseSpedizione
        originale.speseMora = modificato.speseMora

        originale.numBollettino = modificato.numBollettino
        originale.rataImposta = modificato.rataImposta
        originale.fattura = modificato.fattura
        originale.descrizione = modificato.descrizione
        originale.provvedimento = modificato.provvedimento
        originale.ufficioPt = modificato.ufficioPt
        originale.causale = modificato.causale
        originale.note = modificato.note

        originale.ruolo = modificato.ruolo
        originale.ruoloId = modificato.ruolo?.id

        originale.idCompensazione = null
        originale.chkCompensazione = false

		originale.fonteDTO = modificato.fonteDTO
        originale.fonte = modificato.fonteDTO?.fonte
		
        originale.utente = modificato.utente
        originale.dataVariazione = modificato.dataVariazione

        versamentiService.aggiornaImportoVersamento(originale)

        originale.modificato = true

        return originale
    }

    private void addAnnoToListaAnniIfMissing(String anno) {
        if (!listaAnni.contains(anno)) {
            listaAnni << anno
        }
        listaAnni.sort()
    }

    // Aggiorna dovuto versamenti cumulativi
    def aggiornaDovutoVersamentiCumulativi() {

        def oggetti = versamentiService.getOggettiVersamento(contribuente.codFiscale, anno, tipoTributo)

        dovutoVersamentiCumulativi = (oggetti.sum { it.imposta ?: 0 } ?: 0)
        BindUtils.postNotifyChange(null, null, this, "dovutoVersamentiCumulativi")
    }

    // Aggiorna totali versamenti cumulativi
    def aggiornaTotaleVersamentiCumulativi() {

        def listaVersamenti = listaVersamentiCumulativi.findAll { (it.anno == anno) && (it.esistente != false) }
        totaleVersamentiCumulativi = (listaVersamenti.sum { it.importoVersato ?: 0 } ?: 0)

        BindUtils.postNotifyChange(null, null, this, "totaleVersamentiCumulativi")
    }

    // verifica coerenza totali versamento e dovuti
    def verificaTotaleVersamentiCumulativi() {

        String message = ""
        Integer result = 0

        if (totaleVersamentiCumulativi > 0.0) {
            def differenza = Math.round(dovutoVersamentiCumulativi) - totaleVersamentiCumulativi
            if (Math.abs(differenza) > 0.5) {
                message = "- Il totale versato non coincide con la somma arrotondata dell\'imposta\n"
                result = 1
            }
        }

        return [result: result, message: message]
    }

    //
    // Verifica Versamenti Cumulativi modificati : false -> presenza di modificati		//	o in fase di modifica
    //
    def checkVersamentiCumulativiModificati() {

        Boolean result = true

        def inModifica = []    //	listaVersamentiCumulativi.findAll { it.modifica != false }
        def modificati = elencoVersamentiCumulativi.findAll { (it.modificato != false) || ((it.esistente == false) && (it.sequenza != 0)) }
        if ((inModifica.size() > 0) || (modificati.size() > 0)) {
            result = false
        }

        return result
    }

    // Ricarica elenco Annualit� e numero Versamenti per Oggetto e Cumulativi
    def caricaStoricoAnniConVersamenti() {

        anniConVersamentiSuOggetto = versamentiService.getVersamentiOggettoPerAnno(contribuente.codFiscale, tipoTributo)
        anniConVersamentiCumulativi = versamentiService.getVersamentiCumulativiPerAnno(contribuente.codFiscale, tipoTributo)
    }

    // Carica elenco dovuti rateizzati
    def caricaElencoDovutiRateizzati() {

        if (!elencoDovutiRateizzatiCaricato) {
            elencoDovutiRateizzati = versamentiService.getElencoDovutiRateizzati(contribuente.codFiscale, tipoTributo)
            elencoDovutiRateizzatiCaricato = true
        }
    }

    // Completa versamento dopo lettura da banca dati
    def completaVersamentoEsistente(def versamento) {

        versamento.annoOrig = versamento.anno

        versamento.ruolo = elencoRuoliVersamenti.find { it.id == versamento.ruoloId }

        versamento.modificato = false
        versamento.esistente = true

        versamento.modifica = true        //	false;
    }

    //
    // Crea versamento, nuovo o come copia da template
    //
    def creaVersamento(def nextId, def annoVers, def template) {

        def nuovoVersamento

        if (template != null) {
            nuovoVersamento = template.clone()

            nuovoVersamento.id = nextId
            nuovoVersamento.sequenza = 0
            nuovoVersamento.fonte = FONTE_VERSAMENTI

            nuovoVersamento.modifica = true
            nuovoVersamento.esistente = true
            nuovoVersamento.modificato = true
        } else {
            nuovoVersamento = creaVersamentoVuoto(annoVers)

            nuovoVersamento.id = nextId
        }

        return nuovoVersamento
    }

    // Crea versamento
    def creaVersamentoVuoto(Short annoVers) {

        def nuovoVersamento = [
                id                : null,
                codFiscale        : contribuente.codFiscale,
                tipoTributo       : tipoTributo,
                annoOrig          : annoVers,
                sequenza          : 0,
                anno              : annoVers,

                rata              : 0,
                importoVersato    : null,
                dataPagamento     : null,
                dataReg           : null,
                note              : null,

                addizionalePro    : null,
                sanzioni          : null,
                interessi         : null,
                sanzioniAddPro    : null,
                interessiAddPro   : null,
                importo           : null,
                speseSpedizione   : null,
                speseMora         : null,

                numBollettino     : null,
                rataImposta       : null,
                fattura           : null,
                numero            : null,
                maggiorazioneTares: null,
                idCompensazione   : null,
                chkCompensazione  : false,
                descrizione       : null,
                provvedimento     : null,
                ufficioPt         : null,
                causale           : null,

                oggettoImposta    : null,

                ruolo             : null,
                ruoloId           : null,

                fonte             : FONTE_VERSAMENTI,
                utente            : null,
                dataVariazione    : null,

                modifica          : true,
                modificato        : true,
                esistente         : true
        ]

        return nuovoVersamento
    }

    // Visualizza report
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, null, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 10000, true)
                break
        }
    }
}
