package pratiche.denunce

import it.finmatica.tr4.TipoCarica
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.TipoCaricaDTO
import it.finmatica.tr4.dto.pratiche.DenunciaTasiDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.DenunciaTasi
import it.finmatica.tr4.pratiche.StoDenunciaTasi
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.Binder
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.EventQueue
import org.zkoss.zk.ui.event.EventQueues
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class DenunciaTasiViewModel extends DenunciaViewModel {
    // services
    def springSecurityService
    SoggettiService soggettiService

    boolean tributoTari
    boolean isDirty = false

    def denunciaStorica
    def isNuovaDenuncia = false

    // dati
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
         , @ContextParam(ContextType.BINDER) Binder binder
         , @ExecutionArgParam("pratica") Long idPratica
         , @ExecutionArgParam("tipoRapporto") String tr
         , @ExecutionArgParam("lettura") boolean lettura
         , @ExecutionArgParam("storica") def storica
         , @ExecutionArgParam("daSC") @Default("") def daSC
         , @ExecutionArgParam("selected") @Default("") def selected
    ) {
        self = w


        if (storica != null) this.isStorica = storica

        if (idPratica > 0) {

            denunciaStorica = StoDenunciaTasi.get(idPratica)
            if (this.isStorica) {
                denuncia = denunciaStorica.toDTO(listaFetch)
                this.hasStorica = false
            } else {
                denuncia = DenunciaTasi.get(idPratica).toDTO(listaFetch)
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
            denuncia = new DenunciaTasiDTO()
            denuncia.pratica = new PraticaTributoDTO()
            denuncia.pratica.tipoCarica = new TipoCaricaDTO()
            denuncia.pratica.contribuente = new ContribuenteDTO()
            denuncia.pratica.anno = Calendar.getInstance().get(Calendar.YEAR)
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
            denuncia.pratica.tipoTributo = TipoTributo.get("TASI").toDTO()

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
        listaCariche << new TipoCaricaDTO(id: null, descrizione: "")
        tipoRapporto = tr
        modifica = !lettura

        valorePrecedenteAnno = denuncia.pratica.anno

        aggiornaVisualizzazioneDatiTASI()
        aggiornaModificaAnno()
        elencoMotivi = denunceService.elencoMotivazioni(denuncia.pratica.tipoTributo.tipoTributo, (denuncia.pratica.tipoPratica) ? denuncia.pratica.tipoPratica : 'D', denuncia.pratica.anno)

		aggiornaDataModifica()
        aggiornaUtente()

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(new EventListener<Event>() {
            @Override
            public void onEvent(Event event) throws Exception {
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
                            'modifica',
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

                }
            }
        })
    }

    @NotifyChange(["denuncia", "modifica"])
    @Command
    onSalvaDenuncia() {
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

    @NotifyChange(["denuncia", "modifica"])
    void salva() {

        if (salvaDenunciaCheck() != false) {

            modifica = true

            ///	denuncia = denunceService.salvaDenunciaTasi(denuncia,listaFetch,tipoRapporto,flagCf,prefissoTelefonico,numTelefonico,flagFirma,flagDenunciante)
            def salvaDenuncia = denunceService.salvaDenuncia(denuncia, listaFetch, tipoRapporto, flagCf, prefissoTelefonico, numTelefonico, flagFirma, flagDenunciante, "TASI")
            salvaDenunciaPostProcessa(salvaDenuncia)

            aggiornaVisualizzazioneDatiTASI()
            aggiornaModificaAnno()
            elencoMotivi = denunceService.elencoMotivazioni(denuncia.pratica.tipoTributo.tipoTributo, (denuncia.pratica.tipoPratica) ? denuncia.pratica.tipoPratica : 'D', denuncia.pratica.anno)

            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, null, "top_center", 2000, true)
            isDirty = false
            BindUtils.postNotifyChange(null, null, this, "isDirty")
            BindUtils.postNotifyChange(null, null, this, "elencoMotivi")
            BindUtils.postNotifyChange(null, null, this, "denuncia")
			
			aggiornaDataModifica()
            aggiornaUtente()

            denunciaSalvata = true
            BindUtils.postNotifyChange(null, null, this, "denunciaSalvata")
        }
    }

    @Command
    onEliminaPratica() {
        String messaggio = "Eliminare la denuncia?"
        org.zkoss.zul.Messagebox.show(messaggio, "Attenzione",
                org.zkoss.zul.Messagebox.YES | org.zkoss.zul.Messagebox.NO, org.zkoss.zul.Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    public void onEvent(Event e) {
                        if (org.zkoss.zul.Messagebox.ON_YES.equals(e.getName())) {
                            if (eliminaPratica()) {
                                chiudi()
                            }
                        }
                    }
                }
        )
    }

    @Command
    onStoricaPopup() {
        def idPratica = denuncia.id
        def parametri = "sezione=PRATICA_STORICA&idPratica=$idPratica&tipoTributo=TASI&tipoRapporto="

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
                        public void onEvent(Event e) {
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
    getContitolari() {}

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

    @Command
    def onLockUnlockModificaAnno() {
        super.onLockUnlockModificaAnno {
            this.salva()
        }
    }

    private def aggiornaVisualizzazioneDatiTASI() {

        def titoloDocumento = ((denuncia?.pratica?.id ?: 0) != 0) ? denunceService.getTitoloDocumentoPratica(denuncia.pratica.id) : 0
        datiDichiarazioneENC = (titoloDocumento == 26)
        datiDocFA = (titoloDocumento == 22)

        aggiornaDocumentoNota()

        BindUtils.postNotifyChange(null, null, this, "datiDichiarazioneENC")
        BindUtils.postNotifyChange(null, null, this, "datiDocFA")
    }

    @Command
    onSelezionaMotivo(@BindingParam("pu") Popup pu) {
        pu.close()
        denuncia.pratica.motivo = motivoSelezionato.motivo
        isDirty = true
        BindUtils.postNotifyChange(null, null, this, "denuncia")
    }
}
