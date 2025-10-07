package archivio

import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.ad4.utility.CodiceFiscaleService
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.familiari.FamiliariService
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.lang.StringUtils
import org.codehaus.groovy.runtime.InvokerHelper
import org.hibernate.criterion.CriteriaSpecification
import org.zkoss.bind.BindUtils
import org.zkoss.bind.PropertyChangeEvent
import org.zkoss.bind.annotation.*
import org.zkoss.bind.sys.BinderCtrl
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

import java.text.SimpleDateFormat
import java.util.Calendar

class SoggettoViewModel {

    // componenti
    Window self

    @Wire('#bandBoxComuneRes')
    Textbox bandBoxComuneRes

    @Wire('#bandBoxComuneNas')
    Textbox bandBoxComuneNas

    @Wire('#bandBoxComuneEvento')
    Textbox bandBoxComuneEvento

    @Wire('#popupNoteSoggetto')
    Popup popupNoteSoggetto

    // Servizi
    def springSecurityService
    SoggettiService soggettiService
    DatiGeneraliService datiGeneraliService
    CodiceFiscaleService codiceFiscaleService
    FamiliariService familiariService
    ContribuentiService contribuentiService
    CommonService commonService
    CompetenzeService competenzeService

    // Modello
    SoggettoDTO soggetto
    SoggettoDTO soggettoPresso
    Ad4ComuneDTO comuneCliente
    boolean isDirty = false
    def listaTipiCarica
    def listaAnadev
    def listaEredi
    def listaRecapiti
    def listaTipiRecapito
    def listaTipiTributo

    def listaFamiliari
    def listaFamiliariEsistenti

    def numEredi = 0
    def numRecapiti = 0
    def numFamiliari = 0
    def numDeleghe = 0
    def listaDelegheBancarie
    RecapitoSoggettoDTO selectedRecapito
    def modificaRecapito = false
    def wRecapito
    FamiliareSoggettoDTO selectedFamiliare
    def modificaFamiliare = false
    def modificaErede = false
    def wFamiliare
    def selectedDelega
    def modificaDelega = false
    def wDelega
    boolean soggettoConCF = false
    boolean controlloCodFiscale = false
    boolean isContribuente = false
    Popup popupNote
    boolean integrazioneGDS = false
    boolean modificaStatoExtraGSD = false
    boolean abilitaModifica = false
    boolean verificaCap = false
    EredeSoggettoDTO selectedErede
    def rappresentantePresente = false
    def verificaProvinciaEnte = false
    def flagProvincia = false
    def modificaIndirizzoEmigrato = true
    String tempStringNoteSoggetto

    String capPadded
    String zipPadded

    def isNuovoSoggetto

    def filtri = [soggettoPresso   : [cognomeNome: ""]
                  , intestatarioFam: [cognomeNome: ""]
                  , comuneNascita  : [denominazione: ""]
                  , comuneResidenza: [denominazione: ""]
                  , comuneRap      : [denominazione: ""]
                  , comuneEvento   : [denominazione: ""]
                  , indirizzo      : ""
    ]

    def listaFetch = ["contribuenti"
                      , "comuneResidenza"
                      , "comuneResidenza.ad4Comune"
                      , "comuneResidenza.ad4Comune.provincia"
                      , "comuneResidenza.ad4Comune.stato"
                      , "archivioVie"]

    def listaFetchSoggetto = ["comuneNascita"
                              , "comuneNascita.ad4Comune"
                              , "comuneNascita.ad4Comune.provincia"
                              , "comuneNascita.ad4Comune.stato"
                              , "comuneResidenza"
                              , "comuneResidenza.ad4Comune"
                              , "comuneResidenza.ad4Comune.provincia"
                              , "comuneResidenza.ad4Comune.stato"
                              , "comuneEvento"
                              , "comuneEvento.ad4Comune"
                              , "comuneEvento.ad4Comune.provincia"
                              , "comuneEvento.ad4Comune.stato"
                              , "archivioVie"
                              , "soggettoPresso"
                              , "soggettoPresso.comuneResidenza"
                              , "soggettoPresso.archivioVie"
                              , "soggettoPresso.comuneResidenza.ad4Comune"
                              , "soggettoPresso.comuneResidenza.ad4Comune.provincia"
                              , "soggettoPresso.comuneResidenza.ad4Comune.stato"
                              , "comuneRap"
                              , "comuneRap.ad4Comune.provincia"
                              , "comuneRap.ad4Comune.stato"
                              , "familiariSoggetto"
                              , "erediSoggetto"
                              , "recapitiSoggetto"
    ]

    @NotifyChange(["soggetto", "soggettoPresso", "listaTipiCarica", "listaEredi", "filtri", "soggettoConCF", "verificaCap"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("idSoggetto") long idSoggetto,
         @ExecutionArgParam("codiceFiscale") @Default("") String codice,
         @ExecutionArgParam("nome") @Default("") String nome,
         @ExecutionArgParam("cognome") @Default("") String cognome) {

        this.self = w
        comuneCliente = datiGeneraliService.getComuneCliente()
        integrazioneGDS = datiGeneraliService.integrazioneGSDAbilitata()

        if (idSoggetto > 0) {
            soggetto = Soggetto.get(idSoggetto).toDTO(listaFetchSoggetto)
            soggettoPresso = soggetto.soggettoPresso
            capPadded = soggetto.cap
            capPadded = capPadded?.padLeft(5, '0')
            zipPadded = soggetto.zipcode
            zipPadded = zipPadded?.padLeft(5, '0')
            isContribuente = (Contribuente.findBySoggetto(soggetto.getDomainObject())) ? true : false
            filtri.soggettoPresso.cognomeNome = soggettoPresso?.cognomeNome
            filtri.intestatarioFam.cognomeNome = soggetto.intestatarioFam?.replace("/", " ")
            filtri.comuneNascita.denominazione = soggetto.comuneNascita?.ad4Comune?.denominazione
            filtri.comuneResidenza.denominazione = soggetto.comuneResidenza?.ad4Comune?.denominazione
            filtri.comuneEvento.denominazione = soggetto.comuneEvento?.ad4Comune?.denominazione
            filtri.indirizzo = soggetto.archivioVie ? soggetto.archivioVie?.denomUff?.toUpperCase() : soggetto.denominazioneVia?.toUpperCase()
            filtri.comuneRap.denominazione = soggetto?.comuneRap?.ad4Comune?.denominazione
            listaEredi = EredeSoggetto.createCriteria().list {
                createAlias("soggettoEredeId", "soggEre", CriteriaSpecification.INNER_JOIN)
                createAlias("soggEre.contribuenti", "cont", CriteriaSpecification.LEFT_JOIN)
                eq("soggetto.id", idSoggetto)
            }.toDTO().sort { it.soggettoErede.cognomeNome }
            numEredi = listaEredi?.size()
            listaRecapiti = soggettiService.getListaRecapiti(idSoggetto)
            numRecapiti = listaRecapiti?.size()

            listaAnadev = Anadev.list().toDTO()

            if(soggetto.gsd) {

                def listaDceExtraGSD = Anadce.createCriteria().list {
                    eq('tipoEvento', 'C')
                    'in'("anagrafe", ['RES', 'AIR'])
                }?.toDTO()
                
                def elencoDceExtraGSD = listaDceExtraGSD.collect { it.id }

                if(soggetto.stato?.id in elencoDceExtraGSD) {
                    /// Soggetto GSD ma con uno stato di cessata anagrafe interna
                    /// Elimina gli stati non validi ed abilita modifica stato/data utlimo evento/comune
                    listaAnadev = listaAnadev.findAll { it.id in elencoDceExtraGSD }

                    modificaStatoExtraGSD = true
                }
                else {
                    modificaStatoExtraGSD = false
                }
            }
            else {
                modificaStatoExtraGSD = true
            }

            caricaFamiliari(true)
            numFamiliari = listaFamiliari?.size()
            listaDelegheBancarie = caricaListaDelegheBancarie()
            numDeleghe = listaDelegheBancarie?.size()
            soggettoConCF = soggetto.codFiscale || soggetto.partitaIva
            modificaFamiliare = true
            modificaErede = true
            verificaCap = soggettiService.verificaCAP(soggetto.id)
            isNuovoSoggetto = false
            rappresentantePresente = soggetto.rappresentante != null

            modificaIndirizzoEmigrato = !soggetto.gsd || (soggetto.gsd && soggetto.residente == "NO")

        } else {
            soggetto = new SoggettoDTO()
            soggetto.indirizzoRap = ""
            soggetto.codFiscale = codice
            soggetto.nome = nome
            soggetto.cognome = cognome
            soggettoConCF = false
            listaRecapiti = []
            listaEredi = []
            listaFamiliari = []
            listaDelegheBancarie = []
            numEredi = 0
            numRecapiti = 0
            numFamiliari = 0
            numDeleghe = 0
            modificaFamiliare = false
            modificaErede = false
            isNuovoSoggetto = true
            modificaStatoExtraGSD = true
        }
        listaTipiCarica = TipoCarica.list().toDTO()
        listaTipiRecapito = TipoRecapito.list().toDTO()
        listaTipiTributo = TipoTributo.list().toDTO().sort { it.tipoTributo }

        //Nel caso di Integrazione_gsd is null si possono modificare tutti i campi anche il tipo_residente
        abilitaModifica = !integrazioneGDS

        flagProvincia = datiGeneraliService.flagProvinciaAbilitato()
        def isSameComune = comuneCliente.comune == soggetto.comuneResidenza?.ad4Comune?.comune
        verificaProvinciaEnte = flagProvincia && isSameComune

        tempStringNoteSoggetto = soggetto.note

        EventQueue<Event> queue = EventQueues.lookup(BinderCtrl.DEFAULT_QUEUE_NAME, BinderCtrl.DEFAULT_QUEUE_SCOPE, false)
        queue.subscribe(new EventListener<Event>() {
            @Override
            void onEvent(Event event) throws Exception {
                if (event instanceof PropertyChangeEvent) {
                    PropertyChangeEvent pe = (PropertyChangeEvent) event
                    isDirty = isDirty || !(pe.getProperty() in [
                            'listaFamiliari',
                            'listaEredi',
                            'listaRecapiti',
                            'listaAnadev',
                            'listaTipiCarica',
                            'listaTipiRecapito',
                            'listaTipiTributo',
                            'listaDelegheBancarie',
                            'listaFamiliariEsistenti',
                            'flagDelegaCessata',
                            'selectedRecapito',
                            'selectedDelega',
                            'selectedFamiliare',
                            'filtri',
                            'delega',
                            'tipoTributo',
                            'cognomeNomeInt',
                            'oggettoContribuente',
                            'soggetto',
                            'soggettoConCF',
                            'abilitaModifica',
                            'verificaCap',
                            'integrazioneGDS',
                            'modificaStatoExtraGSD',
                            'isDirty',
                            'numDeleghe',
                            'numRecapiti',
                            'numFamiliari',
                            'numEredi'
                    ])
                }
            }
        })
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findBySoggetto(soggetto.getDomainObject())?.soggetto?.id

        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    onSelectNomeIntestatario(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        soggetto.intestatarioFam = event.getData()?.cognomeNome
    }

    @Command
    onSelectSoggettoPresso(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        soggettoPresso = event.getData() ?: null
        soggetto.soggettoPresso = soggettoPresso
        BindUtils.postNotifyChange(null, null, this, "soggettoPresso")
    }

    @Command
    onChangeSoggettoPresso(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        soggettoPresso = event.getData()
        soggetto.soggettoPresso = soggettoPresso
        BindUtils.postNotifyChange(null, null, this, "soggettoPresso")

    }

    @Command
    onSelectComuneNascita(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event.getData()) {
            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            soggetto.comuneNascita = ad4ComuneTr4DTO
        } else {
            soggetto.comuneNascita = null
        }
        BindUtils.postNotifyChange(null, null, this, "soggetto")
    }

    @Command
    onChangeComuneNacita(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {

        if (event.getValue()?.equals("")) {
            soggetto.comuneNascita = null
        }

        if (soggetto.comuneNascita) {
            soggetto.comuneNascita = null
            soggetto.cap = null
        }

        BindUtils.postNotifyChange(null, null, this, "soggetto")
    }

    @Command
    onSelectComuneRap(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event.getData()) {
            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            soggetto.comuneRap = ad4ComuneTr4DTO
        } else {
            soggetto.comuneRap = null
        }
        BindUtils.postNotifyChange(null, null, this, "soggetto")
    }

    @Command
    def onCambiaComuneResidenza(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (soggetto.comuneResidenza) {
            soggetto.comuneResidenza = null
            soggetto.cap = null
            soggetto.zipcode = null
        } else {
            zipPadded = null
            capPadded = null
        }

        BindUtils.postNotifyChange(null, null, this, "soggetto")
        BindUtils.postNotifyChange(null, null, this, "zipPadded")
        BindUtils.postNotifyChange(null, null, this, "capPadded")
    }

    @Command
    onSelectComuneResidenza(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
        ad4ComuneTr4DTO.ad4Comune = event.getData()
        ad4ComuneTr4DTO.comune = event.getData().comune
        ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
        soggetto.comuneResidenza = ad4ComuneTr4DTO

        if (ad4ComuneTr4DTO.provinciaStato > 200) {
            soggetto.zipcode = ad4ComuneTr4DTO?.ad4Comune?.cap
            zipPadded = soggetto.zipcode
            zipPadded = zipPadded?.padLeft(5, '0')

            soggetto.cap = null
            capPadded = null
        } else {
            soggetto.cap = ad4ComuneTr4DTO?.ad4Comune?.cap
            verificaCap = soggettiService.verificaCAP(soggetto.id)
            capPadded = soggetto.cap
            capPadded = capPadded?.padLeft(5, '0')

            soggetto.zipcode = null
            zipPadded = null
        }


        def isSameComune = comuneCliente.comune == soggetto.comuneResidenza?.ad4Comune?.comune
        verificaProvinciaEnte = flagProvincia && isSameComune

        BindUtils.postNotifyChange(null, null, this, "soggetto")
        BindUtils.postNotifyChange(null, null, this, "verificaCap")
        BindUtils.postNotifyChange(null, null, this, "capPadded")
        BindUtils.postNotifyChange(null, null, this, "zipPadded")
        BindUtils.postNotifyChange(null, null, this, "verificaProvinciaEnte")
    }

    @Command
    onSelectComuneEvento(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
        ad4ComuneTr4DTO.ad4Comune = event.getData()
        ad4ComuneTr4DTO.comune = event.getData().comune
        ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
        soggetto.comuneEvento = ad4ComuneTr4DTO
        BindUtils.postNotifyChange(null, null, this, "soggetto")
    }

    @Command
    def onChangeComuneEvento(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (soggetto.comuneEvento) {
            soggetto.comuneEvento = null
        }

        BindUtils.postNotifyChange(null, null, this, "soggetto")
    }

    @Command
    onChiudiPopup() {
        if (isDirty) {
            String messaggio = "Salvare le modifiche apportate?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                if (salvaSoggetto()) {
                                    chiudi()
                                }
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
    onAggiungiErede() {
        if (!soggetto.id) {
            Messagebox.show("Salvare il soggetto prima di procedere all'inserimento di un erede.", "Gestione Soggetto", Messagebox.OK, Messagebox.ERROR)
            return
        }

        def numeroOrdine = (listaEredi.collect { it.numeroOrdine }.max() ?: 0) + 1

        EredeSoggettoDTO erede = new EredeSoggettoDTO()
        erede.soggetto = soggetto
        erede.soggettoErede = new SoggettoDTO()
        erede.soggettoErede.contribuenti = []
        erede.numeroOrdine = numeroOrdine
        listaEredi << erede
        BindUtils.postNotifyChange(null, null, this, "listaEredi")
    }

    @Command
    onEliminaErede() {

        listaEredi.remove(selectedErede)
        selectedErede = null
        BindUtils.postNotifyChange(null, null, this, "listaEredi")
        BindUtils.postNotifyChange(null, null, this, "selectedErede")

    }

    @Command
    onSelectSoggettoErede(@ContextParam(ContextType.TRIGGER_EVENT) Event event, @BindingParam("arg") EredeSoggettoDTO eredeSoggettoDTO) {
        eredeSoggettoDTO.soggettoErede = event.data
        def componente = event.getTarget()
        componente.value = (event.data.cognomeNome ?: "")
        BindUtils.postNotifyChange(null, null, this, "componente")
        BindUtils.postNotifyChange(null, null, this, "listaEredi")
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        filtri.indirizzo = (event.data.denomUff ?: "")
        soggetto.denominazioneVia = null
        soggetto.archivioVie = event.data
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeTipoResidente(@BindingParam("cb") Checkbox cb) {
        soggetto.tipoResidente = !cb.isChecked()
    }

    @NotifyChange(["soggetto", "soggettoConCF"])
    @Command
    onSalvaSoggetto() {
        // Nel caso esista una periodo aperto propone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
            apriPopupChiusuraPeriodiAperti({ salvaSoggetto() }, new FamiliareSoggettoDTO(soggetto: soggetto))
        } else {
            salvaSoggetto()
        }
    }

    private boolean salvaSoggetto() {
        if (validaMaschera()) {
            soggetto.rappresentante = soggetto.rappresentante?.toUpperCase()
            soggetto.codFiscaleRap = soggetto.codFiscaleRap?.toUpperCase()
            soggetto.indirizzoRap = soggetto.indirizzoRap?.toUpperCase()
            //Viene recuperato dal filtro indirizzo che è calcolato in fase iniziale
            soggetto.denominazioneVia = filtri.indirizzo?.toUpperCase()

            rappresentantePresente = soggetto.rappresentante != null

            if (filtri.comuneRap?.denominazione?.isEmpty()) {
                soggetto.comuneRap = null
            }

            ordinaListaFamiliari()

            if (capPadded) {
                soggetto.cap = Integer.parseInt(capPadded)
            } else {
                soggetto.cap = null
            }

            soggetto.zipcode = zipPadded

            // Se un soggetto GSD precedentemente residente e ora non lo è più, occorre fare l'update del campo COD_VIA a null
            if (soggetto.residente == "NO" && soggetto.gsd) {
                soggetto.archivioVie = null
            }

            soggetto = soggettiService.salvaSoggetto(soggetto, listaEredi, listaRecapiti, listaFamiliari, soggettoPresso, listaFetchSoggetto)
            soggettoConCF = soggetto.codFiscale || soggetto.partitaIva

            verificaCap = soggettiService.verificaCAP(soggetto.id)
            ordinaListaFamiliari()
            caricaFamiliari(true)

            isDirty = false

            BindUtils.postNotifyChange(null, null, this, "verificaCap")

            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)
            isDirty = false
            checkListe()
            BindUtils.postNotifyChange(null, null, this, "isDirty")
            BindUtils.postNotifyChange(null, null, this, "soggetto")
            BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
            BindUtils.postNotifyChange(null, null, this, "listaEredi")
            BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
            BindUtils.postNotifyChange(null, null, this, "rappresentantePresente")

            Clients.showNotification("Salvataggio eseguito.", Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 2000, true)

            return true
        } else {
            return false
        }
    }

    @Command
    onModificaRecapito() {
        if (selectedRecapito) {
            modificaRecapito = true
            wRecapito = Executions.createComponents("/archivio/recapito.zul", self, [recapito: selectedRecapito, modifica: true])
            wRecapito.onClose { e ->
                gestioneRecapito()
            }
            wRecapito.doModal()
            BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
            BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
        }
    }

    @Command
    onAggiungiRecapito() {
        if (!soggetto.id) {
            Messagebox.show("Salvare il soggetto prima di procedere all'inserimento di un recapito.", "Gestione Soggetto", Messagebox.OK, Messagebox.ERROR)
            return
        }
        RecapitoSoggettoDTO recapito = new RecapitoSoggettoDTO(
                comuneRecapito: new Ad4ComuneTr4DTO(ad4Comune: new Ad4ComuneDTO(denominazione: ""))
                , archivioVie: new ArchivioVieDTO()
                , soggetto: soggetto)
        selectedRecapito = recapito
        modificaRecapito = false
        wRecapito = Executions.createComponents("/archivio/recapito.zul", self, [recapito: selectedRecapito, modifica: false])
        wRecapito.onClose { e ->
            gestioneRecapito()
        }
        wRecapito.doModal()
        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onEliminaRecapito() {
        Messagebox.show("Il recapito verrà eliminato. Proseguire?", "Eliminazione Recapito",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            selectedRecapito.toDomain().delete(flush: true)
                            gestioneRecapito()
                            Clients.showNotification("Recapito eliminato con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        }
                    }
                }
        )
        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onDuplicaRecapito() {
        modificaRecapito = true
        wRecapito = Executions.createComponents("/archivio/recapito.zul", self, [recapito: selectedRecapito, modifica: false, duplica: true])
        wRecapito.onClose { e ->
            gestioneRecapito()
        }
        wRecapito.doModal()
        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    @Command
    onCalcoloIndividuale() {
        //Se l'anno selezionato negli oggetti è Tutti viene definito anno corrente
        Calendar calendar = Calendar.getInstance()
        short annoSelezionato = calendar.get(Calendar.YEAR)
        Window w = Executions.createComponents("/sportello/contribuenti/calcoloIndividuale.zul", self
                , [idSoggetto: soggetto.id, tipoTributo: "ICI", tipoTributoPref: "ICI", annoSelezionato: annoSelezionato])
        w.doModal()
    }

    @Command
    onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onCalcolaCodiceFiscale() {
        if (!(soggetto.cognome && soggetto.nome && soggetto.sesso && soggetto.comuneNascita && soggetto.dataNas)) {
            Clients.showNotification("Per calcolare il codice fiscale sono necessari: cognome, nome, sesso, comune e data di nascita."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {
            soggetto.codFiscale = codiceFiscaleService.calcolaCodiceFiscale(soggetto.cognome,
                    soggetto.nome,
                    soggetto.sesso,
                    soggetto.dataNas,
                    soggetto.comuneNascita.comune,
                    soggetto.comuneNascita.provinciaStato)

            BindUtils.postNotifyChange(null, null, this, "soggetto")
            BindUtils.postNotifyChange(null, null, this, "flagCfCalcolato")
        }
    }

    @Command
    onAggiungiFamiliare() {
        if (!soggetto.id) {
            Messagebox.show("Salvare il soggetto prima di procedere all'inserimento di un familiare.", "Gestione Soggetto", Messagebox.OK, Messagebox.ERROR)
            return
        }

        // Nel caso esista una periodo aperto propone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
            apriPopupChiusuraPeriodiAperti(this.&aggiungiFamiliare, new FamiliareSoggettoDTO(soggetto: soggetto))
            return
        }

        aggiungiFamiliare(new FamiliareSoggettoDTO(soggetto: soggetto))
    }

    private aggiungiFamiliare(def familiare) {
        listaFamiliari = [familiare] + listaFamiliari

        BindUtils.postNotifyChange(null, null, this, "soggetto")
        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
    }

    @Command
    onDuplicaFamiliare() {

        def familiareOld = new FamiliareSoggettoDTO()
        InvokerHelper.setProperties(familiareOld, selectedFamiliare.properties)

        // Nel caso esista una periodo aperto propone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
            apriPopupChiusuraPeriodiAperti(this.&duplicaFamiliare, familiareOld)
            return
        }

        duplicaFamiliare(familiareOld)
    }

    private duplicaFamiliare(def familiare) {
        FamiliareSoggettoDTO familiareDaDuplicare = new FamiliareSoggettoDTO(soggetto: soggetto)

        familiareDaDuplicare.soggetto = soggetto
        familiareDaDuplicare.anno = familiare?.anno
        familiareDaDuplicare.dal = familiare?.dal
        familiareDaDuplicare.al = familiare?.al
        familiareDaDuplicare.lastUpdated = null
        familiareDaDuplicare.numeroFamiliari = familiare?.numeroFamiliari

        listaFamiliari = [familiareDaDuplicare] + listaFamiliari

        BindUtils.postNotifyChange(null, null, this, "soggetto")
        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
    }

    @Command
    onEliminaFamiliare() {
        soggetto.removeFromFamiliariSoggetto(selectedFamiliare)
        listaFamiliari.remove(selectedFamiliare)
        isDirty = true
        selectedFamiliare = null

        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
        BindUtils.postNotifyChange(null, null, this, "soggetto")
        BindUtils.postNotifyChange(null, null, this, "selectedFamiliare")
    }

    private def apriPopupChiusuraPeriodiAperti(def azione = null, def familiare = null) {

        String messaggio = "Esistono periodi aperti.\n" +
                "Si desidera chiuderli automaticamente?"

        Window win = (Window) Executions.createComponents('archivio/soggettoFamiliariMessageBox.zul', null,
                [title          : 'Attenzione',
                 message        : messaggio,
                 icon           : Messagebox.QUESTION,
                 checkboxMessage: 'Aggiornare la Data di Variazione con la Data odierna'
                ])
        Button okBtn = (Button) win.getFellow("okBtn")
        Button cancelBtn = (Button) win.getFellow("cancelBtn")
        Checkbox checkbox = (Checkbox) win.getFellow("checkbox")
        okBtn.focus()
        okBtn.addEventListener(Events.ON_CLICK, { e ->
            win.detach()
            chiudiPeriodiFamiliari(checkbox.checked)
            if (azione) {
                azione(familiare)
            }
        });
        cancelBtn.addEventListener(Events.ON_CLICK, { e ->
            win.detach()
        })
        win.doModal()
    }

    private def clonaFamiliare(FamiliareSoggettoDTO familiare) {
        FamiliareSoggettoDTO copiaFamiliare = new FamiliareSoggettoDTO()
        InvokerHelper.setProperties(copiaFamiliare, familiare.properties)
        return copiaFamiliare
    }

    private def chiudiPeriodiFamiliari(updateDataVariazione = true) {
        listaFamiliari = familiariService.chiudiPeriodiAperti(listaFamiliari, false, updateDataVariazione)
        Clients.showNotification("Chiusura periodi avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
    }

    @Command
    def controllaFamiliariPeriodiAperti() {
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
            Clients.showNotification("Sono presenti più periodi aperti.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        }
    }

    @Command
    onModificaDelega() {
        if (selectedDelega) {
            wDelega = Executions.createComponents("/archivio/delega.zul", self, [delega: selectedDelega, modifica: true, duplica: false])
            wDelega.onClose { e ->
                gestioneDelega()
            }
            wDelega.doModal()
            BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
            BindUtils.postNotifyChange(null, null, this, "selectedDelega")
        }
    }

    @Command
    onAggiungiDelega() {
        if (!soggetto.id) {
            Messagebox.show("Salvare il soggetto prima di procedere all'inserimento di una delega.", "Gestione Soggetto", Messagebox.OK, Messagebox.ERROR)
            return
        }

        String codFiscaleContribuente = Contribuente.findBySoggetto(soggetto.getDomainObject())?.codFiscale
        if (codFiscaleContribuente) {
            selectedDelega = null
            wDelega = Executions.createComponents("/archivio/delega.zul", self, [delega: selectedDelega, modifica: false, duplica: false, codFiscale: codFiscaleContribuente])
            wDelega.onClose { e ->
                gestioneDelega()
            }
            wDelega.doModal()
            BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
            BindUtils.postNotifyChange(null, null, this, "selectedDelega")
        }
    }

    @Command
    onEliminaDelega() {
        Messagebox.show("La delega bancaria verrà eliminata. Proseguire?", "Eliminazione Delega",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            DelegheBancarie delega = DelegheBancarie.findByCodFiscaleAndTipoTributo(selectedDelega.codFiscale, selectedDelega.tipoTributo)
                            if (delega) {
                                delega.delete(flush: true)
                            }
                            gestioneDelega()
                            Clients.showNotification("Delega eliminata con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        }
                    }
                }
        )
        BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
        BindUtils.postNotifyChange(null, null, this, "selectedDelega")
    }

    @Command
    onDuplicaDelega() {
        wDelega = Executions.createComponents("/archivio/delega.zul", self, [delega: selectedDelega, modifica: false, duplica: true])
        wDelega.onClose { e ->
            gestioneDelega()
        }
        wDelega.doModal()
        BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
        BindUtils.postNotifyChange(null, null, this, "selectedDelega")
    }

    @Command
    def onApriPopupNote(@BindingParam("popup") Popup popup) {
        popupNote = popup
    }

    @Command
    def onChiudiPopupNote(@BindingParam("familiare") FamiliareSoggettoDTO familiare) {
        popupNote.close()

        if (familiare) {
            onChangeFamiliare(familiare)

            BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
            BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
            BindUtils.postNotifyChange(null, null, this, "soggetto")
        }
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

    @Command
    onCheckFamiliareData(@BindingParam("familiare") FamiliareSoggettoDTO familiare) {


        // Solo un periodo per contribuente può essere aperto, se presente almeno uno viene bloccata la clonazione/aggiunta
        // nel caso si provi ad aggiungere un familiare con ulteriore periodo aperto
        def numeroPeriodiAperti = familiariService.getNumPeriodiAperti(listaFamiliari)

        if (numeroPeriodiAperti > 1 && familiare.al == null) {
            apriPopupChiusuraPeriodiAperti(null, familiare)
            return
        }

        boolean check = false

        def errorMessage = familiariService.verificaFamiliare(
                familiare, listaFamiliari.findAll { it.uuid != familiare.uuid },
                FamiliariService.TipoOperazione.MODIFICA
        )

        if (errorMessage.length() != 0) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            check = true
            return
        }

        //Richiesta di variare la data di variazione
        if (!check) {
            onChangeFamiliare(familiare)
        }

        BindUtils.postNotifyChange(null, null, familiare, "*")
    }


    @Command
    def onChangeFamiliare(@BindingParam("familiare") FamiliareSoggettoDTO familiare) {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")

        if (familiare.lastUpdated == null || sdf.format(familiare.lastUpdated) != sdf.format(new Date())) {
            Messagebox.show("Si desidera aggiornare la Data di Variazione con la Data odierna?", "Numero Familiari",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                familiare.lastUpdated = new Date()
                                BindUtils.postNotifyChange(null, null, familiare, "lastUpdated")
                            }
                        }
                    }
            )
        }
    }

    @NotifyChange(["selectedErede"])
    @Command
    def setEredeSelezionato(@BindingParam("ere") def ere) {
        this.selectedErede = ere
    }

    @NotifyChange(["selectedFamiliare"])
    @Command
    def setFamiliareSelezionato(@BindingParam("familiare") def familiare) {
        this.selectedFamiliare = familiare
    }

    @Command
    def onElimina() {

        String msg = "Si è scelto di eliminare il soggetto ${soggetto.cognome} ${soggetto.nome} (N.Ind. ${soggetto.id}).\n" +
                "Il soggetto verrà eliminato e non sarà recuperabile.\n" +
                "Si conferma l'operazione?"


        Messagebox.show(msg, "Eliminazione Soggetto", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {
                    def messaggio = soggettiService.eliminaSoggetto(soggetto)
                    visualizzaRisultatoEliminazione(messaggio)
                }
            }
        })
    }

    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo!"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            chiudi()
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    protected boolean controlloFamiliariPeriodi(List<FamiliareSoggettoDTO> lista, Date dataDalX, Date dataAlX, int indice) {
        boolean isIntersezioni = false

        if (lista?.size() > 1) {
            int n = lista.size()
            for (i in 0..<n) {

                if (i != indice) {
                    Date dal = lista[i].dal
                    Date al = lista[i].al
                    if (dataDalX == dal || (dataAlX && al && dataAlX == al)) {
                        isIntersezioni = true
                        break
                    } else if ((dataDalX > dal && dataAlX < al && dataAlX != null) || (dataDalX > dal && dataDalX <= al)) {
                        isIntersezioni = true
                    }
                }
            }

            // L'ordine della lista viene cambiato prima di essere passato al metodo, si ripristina quello originale.
            ordinaListaFamiliari()

            return isIntersezioni

        }
    }

    private ordinaListaFamiliari() {
        listaFamiliari.sort { it.anno ? -it.anno : 0 }
        listaFamiliari.sort { it.dal }
        listaFamiliari.reverse(true)
    }

    protected chiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Soggetto", filtri: filtri, Soggetto: (soggetto.id) ? soggetto : null])
    }

    private boolean validaMaschera() {
        def errori = []

        if (soggetto.cognome?.length() <= 0) {
            errori << ("Indicare il cognome del soggetto")
        }

        if (soggetto.tipo?.length() <= 0) {
            errori << ("Indicare il tipo di persona")
        }

        for (erede in listaEredi) {
            if (!erede.numeroOrdine) {
                errori << ("Indicare l'ordine degli eredi")
                break
            }
            if (erede.soggettoErede.id < 0) {
                errori << ("Indicare il soggetto erede")
                break
            }
        }

        // Validazione familiari

        // Verifica che l'anno di dal/al coincida con Anno
        def erroreAnno = listaFamiliari.find {
            it.anno != commonService.yearFromDate(it.dal) ||
                    it.al && it.anno != commonService.yearFromDate(it.al)
        }
        if (erroreAnno) {
            errori << "Gli anni delle date Dal e Al devono coincidere con l'anno ${erroreAnno.anno}"
        }

        // Verifica sulla corretta compilazione dei campi
        def erroreCompilazioneCampi = listaFamiliari.find {
            it.anno == null || it.dal == null || it.numeroFamiliari == null || it.lastUpdated == null
        }
        if (erroreCompilazioneCampi) {
            errori << "Compilare correttamente i campi obbligatori nel folder Familiari"
        }

        // Verifca che non siano stati definiti perisodi con Dal > Al
        def erroreCongruenzaDate = listaFamiliari.find {
            it.dal != null && it.al != null && it.dal > it.al
        }
        if (erroreCongruenzaDate) {
            errori << "Nel folder Familiari la Data Inizio 'Dal' maggiore di Data Fine 'Al'"
        }

        //Clono la lista per evitare modifiche agli oggetti referenziati
        def lista = []
        listaFamiliari.each {
            lista << clonaFamiliare(it)
        }

        // Verifica presenza periodi aperti sui familiari
        if (familiariService.getNumPeriodiAperti(listaFamiliari) > 1) {
            errori << "Sono presenti più periodi aperti"
        }

        // Chiudo i periodi per verificare se esistono intersezioni
        lista = familiariService.chiudiPeriodiAperti(lista)

        // Creo una lista di sole coppie dataInizio-dataFine
        def listaDate = []
        lista.each {
            listaDate << [dataInizio: it.dal, dataFine: it.al]
        }

        //Verifico la presenza di intersezioni
        def intersezioni = commonService.isOverlapping(listaDate)
        if (intersezioni) {
            errori << "Sono presenti delle intersezioni di periodo Dal/Al tra le date dei Familiari"
        }

        //Verifico che si sia selezionato un comune dalla bandbox
        if (!bandBoxComuneRes?.getValue()?.isEmpty() && soggetto.comuneResidenza == null) {
            errori << "Selezionare il Comune di Residenza"
        }

        if (!bandBoxComuneNas?.getValue()?.isEmpty() && soggetto.comuneNascita == null) {
            errori << "Selezionare il Comune di Nascita"
        }

        if (!bandBoxComuneEvento?.getValue()?.isEmpty() && soggetto.comuneEvento == null) {
            errori << "Selezionare il Comune Evento"
        }


        if (errori.size() > 0) {
            errori.add(0, "Impossibile salvare il soggetto:")
            Clients.showNotification(StringUtils.join(errori, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    def gestioneRecapito() {
        listaRecapiti = soggettiService.getListaRecapiti(soggetto.id)
        selectedRecapito = null
        checkListe()
        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "selectedRecapito")
    }

    def gestioneFamiliare() {
        caricaFamiliari(true)
        selectedFamiliare = null
        checkListe()
        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
        BindUtils.postNotifyChange(null, null, this, "selectedFamiliare")
    }

    def caricaListaDelegheBancarie() {
        String codFiscaleContribuente = null
        if (soggetto) {
            codFiscaleContribuente = Contribuente.findBySoggetto(soggetto.getDomainObject())?.codFiscale
            if (codFiscaleContribuente) {
                controlloCodFiscale = !codFiscaleContribuente.equals(soggetto.codFiscale)
                listaDelegheBancarie = soggettiService.listaDelegheBancarie(codFiscaleContribuente)
            }
        }
    }

    def gestioneDelega() {
        listaDelegheBancarie = caricaListaDelegheBancarie()
        selectedDelega = null
        checkListe()
        BindUtils.postNotifyChange(null, null, this, "listaDelegheBancarie")
        BindUtils.postNotifyChange(null, null, this, "selectedDelega")
    }

    private checkListe() {
        numEredi = listaEredi?.size()
        numRecapiti = listaRecapiti?.size()
        numFamiliari = listaFamiliari?.size()
        numDeleghe = listaDelegheBancarie?.size()
        BindUtils.postNotifyChange(null, null, this, "numEredi")
        BindUtils.postNotifyChange(null, null, this, "numRecapiti")
        BindUtils.postNotifyChange(null, null, this, "numFamiliari")
        BindUtils.postNotifyChange(null, null, this, "numDeleghe")
    }

    private def caricaFamiliari(def force = false) {
        if (force) {
            listaFamiliari = contribuentiService.familiariContribuente(soggetto.id)
        } else {
            listaFamiliari = listaFamiliari ?: contribuentiService.familiariContribuente(soggetto.id)
        }

        listaFamiliariEsistenti = listaFamiliari.collectEntries { [(it.uuid): true] }

        BindUtils.postNotifyChange(null, null, this, "listaFamiliari")
        BindUtils.postNotifyChange(null, null, this, "listaFamiliariEsistenti")
    }

}

