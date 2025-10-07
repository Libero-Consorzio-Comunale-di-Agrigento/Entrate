package pratiche.denunce

import document.FileNameGenerator
import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.CostoStorico
import it.finmatica.tr4.TipoCarica
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.TipoCaricaDTO
import it.finmatica.tr4.dto.pratiche.DenunciaIciDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.portale.IntegrazionePortaleService
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.pratiche.DenunciaIci
import it.finmatica.tr4.pratiche.StoDenunciaIci
import it.finmatica.tr4.reports.DenunciaMinisterialeService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.EventQueue
import org.zkoss.zk.ui.event.EventQueues
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class DenunciaImuViewModel extends DenunciaViewModel {

    def springSecurityService
    IntegrazionePortaleService integrazionePortaleService
    DenunciaMinisterialeService denunciaMinisterialeService

    def listaContitolari
    def contSelezionato
    boolean isDirty = false
    def denunciaStorica
    def listaCostiStorici
    def numCostiStorici = 0

    def selectedTab = 0


    def isNuovaDenuncia = false


    @NotifyChange([
            "denuncia",
            "listaOggetti",
            "filtri",
            "listaCariche",
            "modifica",
            "layoutOggCo",
            "lettura"
    ])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("pratica") Long idPratica
         , @ExecutionArgParam("tipoRapporto") String tr
         , @ExecutionArgParam("lettura") boolean lettura
         , @ExecutionArgParam("storica") def storica
         , @ExecutionArgParam("daBonifiche") boolean daBonifiche
         , @ExecutionArgParam("daSC") @Default("") def daSC
         , @ExecutionArgParam("selected") @Default("") def selected
    ) {
        self = w

        if (daBonifiche) {
            this.daBonifiche = daBonifiche
        }

        if (storica != null) {
            this.isStorica = storica
        }

        if (idPratica > 0) {

            denunciaStorica = StoDenunciaIci.get(idPratica)
            if (this.isStorica) {
                denuncia = denunciaStorica.toDTO(listaFetch)
                this.hasStorica = false
            } else {
                denuncia = DenunciaIci.get(idPratica).toDTO(listaFetch)
                this.hasStorica = (denunciaStorica != null)
            }
        } else {
            denuncia = null
        }

        tributoTari = false
        if (denuncia != null) {
            flagCf = denuncia.flagCf
            prefissoTelefonico = denuncia.prefissoTelefonico
            numTelefonico = denuncia.numTelefonico
            flagFirma = denuncia.flagFirma
            flagDenunciante = denuncia.flagDenunciante

            if (this.isStorica) {
                listaOggetti = stoDenunceService.oggettiDenuncia(idPratica, denuncia.pratica.contribuente.codFiscale)
            } else {
                listaOggetti = denunceService.oggettiDenuncia(idPratica, denuncia.pratica.contribuente.codFiscale)
            }

            filtri.denunciante.codFiscale = denuncia.pratica.codFiscaleDen ?: ""
            filtri.contribuente.codFiscale = denuncia.pratica.contribuente.codFiscale ?: ""
            filtri.contribuente.cognome = denuncia.pratica.contribuente?.soggetto?.cognome ?: ""
            filtri.contribuente.nome = denuncia.pratica.contribuente?.soggetto?.nome ?: ""
            filtri.comuneDenunciante.denominazione = denuncia.pratica.comuneDenunciante?.ad4Comune?.denominazione
            //Minimizziamo la sezione Denunciante se non è valorizzato
            isDenunciante = !StringUtils.isEmpty(denuncia.pratica.denunciante)
        } else {
            denuncia = new DenunciaIciDTO()
            denuncia.pratica = new PraticaTributoDTO()
            denuncia.pratica.tipoCarica = new TipoCaricaDTO()
            denuncia.pratica.contribuente = new ContribuenteDTO()
            denuncia.pratica.anno = Calendar.getInstance().get(Calendar.YEAR)
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
            denuncia.pratica.tipoTributo = TipoTributo.get("ICI").toDTO()

            //Se elemento selezionato viene proposta una nuova denuncia per lo stesso contribuente (solo da situazione contribuente)
            if (daSC == true && selected != null && selected != "") {
                setSelectCodFiscaleCon(selected)
            } else {
                onApriMascheraRicercaSoggetto()
            }

            //All'apertura di una nuova denuncia apriamo anche i dati relativi al denunciante
            isDenunciante = true

            isNuovaDenuncia = true
        }

        tipoTributoAttuale = denuncia.pratica.tipoTributo.getTipoTributoAttuale(denuncia.pratica.anno)
        listaCariche = TipoCarica.findAllByIdGreaterThanEquals("0", [sort: "id", order: "asc"]).toDTO()
        tipoRapporto = tr
        modifica = !lettura

        valorePrecedenteAnno = denuncia.pratica.anno

        aggiornaVisualizzazioneDatiIMU()
        aggiornaModificaAnno()
        elencoMotivi = denunceService.elencoMotivazioni(denuncia.pratica.tipoTributo.tipoTributo, (denuncia.pratica.tipoPratica) ? denuncia.pratica.tipoPratica : 'D', denuncia.pratica.anno)
		
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
                            'listaCostiStorici',
                            'costoStoricoSelezionato',
                            'listaOggetti',
                            'oggettiSelezionati',
                            'listaContitolari',
                            'contSelezionato',
                            'denuncia',
                            'datiDichiarazioneENC',
                            'datiDocFA',
                            'rendita',
                            'valore',
                            'isDenunciante',
                            'anno',
                            'tipo',
                            'abilitaModificaAnno',
                            'sbloccaModificaAnnoVisibile',
                            'bloccaModificaAnnoVisibile',
                            'documentoNotaId',
                            'listaTipiTributo',
                            'motivoSelezionato',
                            'elencoMotivi',
                            'note',
                            'elencoMotivi',
                            'parametriBandbox',
                            'rendita',
                            'aggiungiDetrazioniAliquote',
                            'oggettoContribuente',
                            'isPertinenza',
                            'activeItem',
                            'isCreaOggettoContitolare',
                            'cb',
                            'listaAliquote',
                            'listSize',
                            'modifica',
							'lastUpdated',
                            'utente',
                            'isDirty'
                    ])
                    //println(pe.property)

                }
            }
        })
    }


    @Command
    onDuplicaInTasi() {
        Map params = new HashMap()
        params.put("width", "600")

        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]
        def esiste = denunceService.esisteDenunciaInTasi(denuncia.pratica)
        if (esiste) {
            Messagebox.show("Esiste già una denuncia TASI per l'anno " + denuncia.pratica.anno + ", si vuole procedere ugualmente con la duplica?",
                    "Duplica denuncia",
                    buttons,
                    null,
                    Messagebox.QUESTION,
                    null,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                duplicaDenunciaInTasi()
                            }
                        }
                    },
                    params
            )
        } else {
            duplicaDenunciaInTasi()
        }
    }

    @Command
    onSalvaDenuncia(@BindingParam("aggiornaStato") boolean aggiornaStato) {
        this.aggiornaStato = aggiornaStato

        if (!validaMaschera()) {
            return true
        }

        // Se si crea una nuova denuncia e prima di salvare si cambia l'anno, al salvataggio bisogna aggiornare il valore dell'anno precedente
        if (isNuovaDenuncia && valorePrecedenteAnno != null && valorePrecedenteAnno != denuncia.pratica.anno) {
            //Per triggerare l'else nel metodo DenunciaViewModel.onLockUnlockModificaAnno()
            sbloccaModificaAnnoVisibile = false
            onLockUnlockModificaAnno()
            isNuovaDenuncia = false
            BindUtils.postNotifyChange(null, null, this, "isNuovaDenuncia")
            return
        }

        salva()
    }

    void salva() {

        if (salvaDenunciaCheck()) {

            modifica = true

            def salvaDenuncia = denunceService.salvaDenuncia(denuncia, listaFetch, tipoRapporto, flagCf, prefissoTelefonico, numTelefonico, flagFirma, flagDenunciante, "ICI")
            salvaDenunciaPostProcessa(salvaDenuncia)

            aggiornaVisualizzazioneDatiIMU()
            aggiornaModificaAnno()
            elencoMotivi = denunceService.elencoMotivazioni(denuncia.pratica.tipoTributo.tipoTributo, (denuncia.pratica.tipoPratica) ? denuncia.pratica.tipoPratica : 'D', denuncia.pratica.anno)

            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)
            isDirty = false
            valorePrecedenteAnno = denuncia.pratica.anno

			aggiornaDataModifica()
            aggiornaUtente()

            denunciaSalvata = true
            BindUtils.postNotifyChange(null, null, this, "denunciaSalvata")
            BindUtils.postNotifyChange(null, null, this, "isDirty")
            BindUtils.postNotifyChange(null, null, this, "elencoMotivi")
            BindUtils.postNotifyChange(null, null, this, "modifica")
            BindUtils.postNotifyChange(null, null, this, "denuncia")
        }
    }

    @Command
    def onEliminaPratica() {
        boolean esistonoContitolari = denunceService.controlloContitolariPratica(denuncia.pratica.id)
        String messaggio = (esistonoContitolari) ? "Sono presenti contitolari sulla dichiarazione, si vuole procedere all'eliminazione?" : "Eliminare la denuncia?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            if (eliminaPratica()) {
                                chiudi()
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onLockUnlockModificaAnno() {
        super.onLockUnlockModificaAnno {
            this.salva()
        }
    }


    @Command
    onStoricaPopup() {
        def idPratica = denuncia.id
        def parametri = "sezione=PRATICA_STORICA&idPratica=$idPratica&tipoTributo=ICI&tipoRapporto="

        Clients.evalJavaScript("window.open('standalone.zul?$parametri','_blank');")
    }

    @Command
    onChiudiPopup() {
        // Se siamo in sola lettura si esce direttamente
        if (!modifica) {
            chiudi()
            return
        }

        if (isDirty) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                salva()
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
    getContitolari() {
        if (oggCoSelezionato) {
            if (this.isStorica) {
                listaContitolari = stoDenunceService.contitolariOggetto(oggCoSelezionato.oggettoPratica.id)
            } else {
                listaContitolari = denunceService.contitolariOggetto(oggCoSelezionato.oggettoPratica.id)
            }
        }
        BindUtils.postNotifyChange(null, null, this, "listaContitolari")
    }

    @Command
    def getCostiStorici() {

        listaCostiStorici = denunceService.getListaCostiStorici(oggCoSelezionato.oggettoPratica.id)
        BindUtils.postNotifyChange(null, null, this, "listaCostiStorici")
    }

    def getNumeroCostiStorici(){
        if (oggCoSelezionato) {
            getCostiStorici()
            numCostiStorici = listaCostiStorici.size()
            BindUtils.postNotifyChange(null, null, this, "numCostiStorici")
        }
    }

    @Command
    def onSelectTabs() {

        getNumeroCostiStorici()

        if (oggCoSelezionato) {
            if (selectedTab == 0) {
                getContitolari()           // CONTITOLARI
            }
            if (selectedTab == 1) {
                getCostiStorici()          // COSTI STORICI
            }
        }
    }

    @Command
    onApriPopupContitolare(@BindingParam("popup") Component popupContitolare) {
        popupContitolare?.open(self, "middle_center")
    }

    @Command
    onChiudiPopupContitolare(@BindingParam("popup") Component popupContitolare) {
        contSelezionato = null
        popupContitolare.close()
        BindUtils.postNotifyChange(null, null, this, "contSelezionato")
    }

    @Command
    onModificaContitolare(@BindingParam("isCreaContitolare") def isCreaContitolare) {
        if (isCreaContitolare) {
            //Se siamo in creazione di un contitolare controllo se la percentuale del Dichiarante è al 100% chiediamo con un messaggio
            // di conferma se vogliamo proseguire
            if (oggCoSelezionato?.percPossesso == 100) {
                String messaggio = "Il dichiarante possiede già il 100% della proprietà sull'immobile. Vuoi proseguire?"
                Messagebox.show(messaggio, "Gestione Contitolari",
                        Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    apriOggettoContitolare(-1)
                                }
                            }
                        }
                )
            } else {
                apriOggettoContitolare(-1)
            }
            contSelezionato = null
        } else
            apriOggettoContitolare(-1)
    }

    @Command
    onEliminaOggCoContitolare(@BindingParam("ogco") def oggettoContribuente) {
        Map params = new HashMap()
        params.put("width", "600")

        Messagebox.Button[] buttons = [Messagebox.Button.YES, Messagebox.Button.NO]

        String anomalie = ""

        for (def anom : gestioneAnomalieService.anomalieAssociateAdOgCo(oggettoContribuente.toDomain())) {
            anomalie += (anom.idTipoAnomalia + " " + anom.descrizione + " " + anom.tipoTributo + " " + anom.anno + (anom.flagImposta == 'S' ? ' Imposta' : '')) + "\n"
        }

        Messagebox.show("Eliminazione della registrazione?\n\nImmobile: ${oggettoContribuente.oggettoPratica.numOrdine}\n\nL'operazione non potrà essere annullata.\n" +
                (!anomalie.isEmpty() ? "\nAnomalie associate all'oggetto pratica:\n" + anomalie : ""),
                "Oggetti del dichiarante",
                buttons,
                null,
                Messagebox.QUESTION,
                null,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            //SOLO per la tasi eliminare ogco corrisponde ad eliminare ogpr
                            //perchè c'è un rapporto uno ad uno.
                            eliminaOggettoContribuente(oggettoContribuente)
                        }
                    }
                },
                params
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
    def onModificaCostoStorico() {

        commonService.creaPopup("/pratiche/denunce/dettaglioCostiStorici.zul",
                self,
                [
                        costoStorico: costoStoricoSelezionato,
                        modifica    : true
                ],
                { event ->
                    if (event.data?.salvato && event.data?.costoStorico) {

                        denunceService.salvaCostoStorico(event.data.costoStorico)
                        Clients.showNotification("Salvataggio effettuato", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)

                    }
                })

    }

    @Command
    def onAggiungiCostoStorico() {

        CostoStorico costoStorico = new CostoStorico()

        costoStorico.utente = Ad4Utente.get(springSecurityService.currentUser.id)
        costoStorico.oggettoPratica = oggCoSelezionato.oggettoPratica.toDomain()

        commonService.creaPopup("/pratiche/denunce/dettaglioCostiStorici.zul",
                self,
                [
                        costoStorico: costoStorico,
                        modifica    : false
                ],
                { event ->
                    if (event.data?.salvato && event.data?.costoStorico) {

                        denunceService.salvaCostoStorico(event.data.costoStorico)
                        Clients.showNotification("Salvataggio effettuato", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        onSelectTabs()
                    }
                })

    }

    @Command
    def onEliminaCostoStorico() {

        String messaggio = "Sicuri di voler eliminare il costo storico?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            denunceService.eliminaCostoStorico(costoStoricoSelezionato)
                            Clients.showNotification("Eliminazione effettuata", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                            onSelectTabs()
                        }
                    }
                }
        )
    }

    @Command
    def onExportXlsCostiStorici() {

        Map fields

        def converters = [
                anno     : Converters.decimalToInteger,
                oggNumero: { ogg -> oggCoSelezionato.oggettoPratica.id }
        ]

        fields = [
                "oggNumero": "Oggetto",
                "anno"     : "Anno",
                "costo"    : "Costo"
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.COSTI_STORICI,
                [idPratica: denuncia.pratica.id,
                 anno       : denuncia.pratica.anno])

        XlsxExporter.exportAndDownload(nomeFile, listaCostiStorici, fields, converters)
    }

    @Command
    def onValidaPratica() {
        def msg = integrazionePortaleService.validaPratiche([denuncia.pratica.id])

        Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        Events.postEvent(Events.ON_CLOSE, self, [salvato: true])
    }

    @Command
    def onStampaDenunciaMinisteriale(){

        def report = denunciaMinisterialeService.generaDenuncia(denuncia.pratica)

        report = ModelliCommons.finalizzaPagineDocumento(report)

        AMedia amedia = new AMedia("Denuncia_Ministeriale_${denuncia.pratica.contribuente.codFiscale}_${denuncia.pratica.anno}", "pdf", "application/pdf", report)
        Filedownload.save(amedia)
    }


    boolean checkEsisteContitolari(def oggCoSelezionato) {
        def lista
        if (oggCoSelezionato) {
            lista = denunceService.contitolariOggetto(oggCoSelezionato.oggettoPratica.id)
        }
        return (lista?.size() > 0)
    }

    void caricaListaContitolari() {
        if (oggCoSelezionato)
            listaContitolari = denunceService.contitolariOggetto(oggCoSelezionato.oggettoPratica.id)

        BindUtils.postNotifyChange(null, null, this, "listaContitolari")
    }

    protected String eliminaOggettoContribuente(def ogco) {
        super.eliminaOggettoContribuente(ogco)
        getContitolari()
        BindUtils.postNotifyChange(null, null, this, "listaContitolari")
    }

    protected void apriOggettoContitolare(def idOggetto) {
        int indexSelezione = (contSelezionato?.id) ? (listaContitolari?.indexOf(contSelezionato) ?: 0) : 0
        Window w = Executions.createComponents("/pratiche/denunce/oggettoContribuente.zul", self
                , [idOggPr            : contSelezionato ? contSelezionato.oggettoPratica?.id : oggCoSelezionato.oggettoPratica.id
                   , contribuente     : contSelezionato ? contSelezionato?.contribuente?.codFiscale : null
                   , tipoRapporto     : contSelezionato ? contSelezionato?.tipoRapporto : "C"
                   , tipoTributo      : denuncia.pratica.tipoTributo?.tipoTributo
                   , idOggetto        : idOggetto
                   , pratica          : denuncia.pratica
                   , oggCo            : null
                   , listaId          : listaContitolari
                   , indexSelezione   : contSelezionato ? indexSelezione : 0
                   , modifica         : modifica
                   , daBonifiche      : false
                   , isCreaContitolare: contSelezionato ? false : true
        ])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Salva") {
                    def oggCoSalvato = event.data.oggCo
                    def idx = listaContitolari.findIndexOf {
                        it.contribuente.codFiscale == oggCoSalvato.contribuente.codFiscale &&
                                it.oggettoPratica.id == oggCoSalvato.oggettoPratica.id
                    }
                    if (idx >= 0) {
                        listaContitolari[idx] = oggCoSalvato
                    } else {
                        listaContitolari << oggCoSalvato
                    }
                    contSelezionato = null
                    BindUtils.postNotifyChange(null, null, this, "listaContitolari")
                    BindUtils.postNotifyChange(null, null, this, "contSelezionato")
                }
            }
        }
        w.doModal()
    }

    private boolean validaMaschera() {
        def messaggi = []

        if (denuncia.pratica?.anno <= 0) {
            messaggi << ("Indicare l'anno della pratica")
        }

        if (denuncia.pratica.contribuente.codFiscale == null) {
            messaggi << ("Indicare il codice fiscale del dichiarante")
        }

        if (messaggi.size() > 0) {
            messaggi.add(0, "Impossibile salvare la denuncia:")
            Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        }

        return true
    }

    private
    def aggiornaVisualizzazioneDatiIMU() {

        def titoloDocumento = ((denuncia?.pratica?.id ?: 0) != 0) ? denunceService.getTitoloDocumentoPratica(denuncia.pratica.id) : 0
        datiDichiarazioneENC = (titoloDocumento == 26)
        datiDocFA = (titoloDocumento == 22)

        aggiornaDocumentoNota()

        BindUtils.postNotifyChange(null, null, this, "datiDichiarazioneENC")
        BindUtils.postNotifyChange(null, null, this, "datiDocFA")
    }

    private duplicaDenunciaInTasi() {

        if (!controllaDetrOggetti()) {
            Clients.showNotification("Esiste un quadro con Detrazione valorizzata e % Detrazione non valorizzata.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        def msg = denunceService.duplicaInTasi(denuncia.pratica)
        if (!msg.isEmpty()) {
            Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }
    }
}
