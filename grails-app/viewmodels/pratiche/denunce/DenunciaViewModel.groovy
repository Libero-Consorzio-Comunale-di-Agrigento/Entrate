package pratiche.denunce

import grails.util.Holders
import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.datiesterni.ImportDatiEsterniService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.denunce.StoDenunceService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.OggettoContribuente
import org.hibernate.criterion.CriteriaSpecification
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Checkbox
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

abstract class DenunciaViewModel {
    /*
     * NOTA IMPORTANTE:
     * Per ciascun attributo che viene definito in questa classe e che può essere utilizzato dalle classi che la estendono
     * occorre aggiungere tale variabile all'interno del metodo @Init nella parte della coda degli eventi ed intercettare gli eventi del
     * tipo PropertyChangeEvent, ovvero insieme alla proprietà isDirty.
     * Per evitare che durante la chiusura delle maschere venga richiesto il salvataggio anche se non è stata apportata alcuna modifica.
    */

    // componenti
    Window self

    // Modello
    def denuncia

    boolean hasStorica = false
    boolean isStorica = false

    boolean datiDichiarazioneENC = false
    boolean datiDocFA = false

    boolean sbloccaModificaAnnoVisibile = false
    boolean bloccaModificaAnnoVisibile = false
    boolean abilitaModificaAnno = false

    String lastUpdated
    def utente

    def documentoNotaId = null

    def grailsApplication
    DenunceService denunceService
    OggettiService oggettiService
    GestioneAnomalieService gestioneAnomalieService
    ImportDatiEsterniService importDatiEsterniService
    CommonService commonService = Holders.grailsApplication.mainContext
            .getBean("commonService")
    DocumentaleService documentaleService
    ModelliService modelliService
    ComunicazioniService comunicazioniService

    StoDenunceService stoDenunceService

    def oggCoSelezionato
    List<SoggettoDTO> soggettiList
    def listaOggetti = []
    def oggettiSelezionati = [:]
    def oggettoAttuale = 0

    def costoStoricoSelezionato

    List<TipoCaricaDTO> listaCariche

    boolean tributoTari
    boolean abilitaFlagAnnullato = false

    def praticaAnnullabile = false

    def denunciaSalvata = false

    /*i seguenti attributi, sono stati dichiarati come proprietà del view model per poter
     utilizzare un unico frontespizio per qualsisi tipo di tributo selezionato
     abilitando/disabilitando i campi opportuni */

    boolean flagCf = false
    String prefissoTelefonico = null
    Integer numTelefonico = null
    boolean flagFirma = false
    boolean flagDenunciante = false
    def listaTipiEvento = [
            TipoEventoDenuncia.A
            ,
            TipoEventoDenuncia.R
            ,
            TipoEventoDenuncia.T
            ,
            TipoEventoDenuncia.I
            ,
            TipoEventoDenuncia.V
            ,
            TipoEventoDenuncia.C
            ,
            TipoEventoDenuncia.U
    ]

    boolean modifica
    boolean daBonifiche = false
    boolean aggiornaStato = false
    boolean isDenunciante = false
    String denunciante
    String comuneDenunciante
    String provinciaDenunciante
    def motivoSelezionato
    def elencoMotivi = []
    String tipoRapporto
    String tipoTributoAttuale

    def valorePrecedenteAnno

    List listaFetch = [
            "pratica"
            ,
            "pratica.contribuente"
            ,
            "pratica.contribuente.soggetto"
            ,
            "pratica.comuneDenunciante"
            ,
            "pratica.comuneDenunciante.ad4Comune"
            ,
            "pratica.comuneDenunciante.ad4Comune.provincia"
            ,
            "pratica.tipoTributo"
            ,
            "pratica.rapportiTributo"
            ,
            "pratica.rapportiTributo.contribuente"
            ,
            "pratica.tipoCarica"
            ,
            "pratica.iter"
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

    Map filtri = [denunciante        : [codFiscale: "", cognomeNome: ""]
                  , contribuente     : [codFiscale: "", cognome: "", nome: ""]
                  , comuneDenunciante: [denominazione: ""]]

    Map layoutOggCo = ["TASI" : "/pratiche/denunce/oggettiContribuente.zul"
                       , "IMU": "/pratiche/denunce/oggettiContribuente.zul"]

    @Command
    def onApriMascheraRicercaSoggetto() {
        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    setSelectCodFiscaleCon(event.data.Soggetto)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onChangeCodFiscaleDen(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event?.data) {
            if (filtri.denunciante.codFiscale != "" && !event.target.isOpen()) {
                //Messagebox.show("Soggetto non valido", "Ricerca soggetto", Messagebox.OK, Messagebox.INFORMATION)
                String messaggio = "Non e' stato selezionato alcun soggetto.\n"
                messaggio += "Il soggetto con codice fiscale ${filtri?.denunciante?.codFiscale?.toUpperCase()} non è presente in anagrafe.\n"
                messaggio += "Si desidera inserirne uno nuovo?"
                Messagebox.show(messaggio, "Ricerca soggetto",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    creaPopupSoggetto("/archivio/soggetto.zul", [idSoggetto: -1], true)
                                } else if (Messagebox.ON_NO.equals(e.getName())) {
                                    svuotaDenunciante()
                                }
                            }
                        }
                )
            }
        } else {
            denuncia.pratica.denunciante = ""
            denuncia.pratica.codFiscaleDen = ""
            denuncia.pratica.indirizzoDen = ""
            denuncia.pratica.comuneDenunciante = null
            denuncia.pratica.tipoCarica = null
        }
    }

    @Command
    def onChangeCodFiscaleCon(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (filtri.contribuente.codFiscale != "" && !event.target.isOpen()) {
            String messaggio = "Non è stato selezionato alcun soggetto.\n"
            messaggio += "Il soggetto con codice fiscale ${filtri?.contribuente?.codFiscale?.toUpperCase()} non è presente in anagrafe.\n"
            messaggio += "Si desidera inserirne uno nuovo?"
            Messagebox.show(messaggio, "Ricerca soggetto",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                creaPopupSoggetto("/archivio/soggetto.zul", [idSoggetto: -1])
                            } else if (Messagebox.ON_NO.equals(e.getName())) {
                                svuotaContribuente()
                            }
                        }
                    }
            )
        }
    }

    @NotifyChange(["denuncia", "filtri"])
    @Command
    def onSelectCodFiscaleDen(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        // SOLO se ho selezionato un solo item
        def selectedRecord = event.getData()
        filtri.denunciante.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
        denuncia.pratica.denunciante = selectedRecord?.cognomeNome?.toUpperCase()
        denuncia.pratica.codFiscaleDen = selectedRecord?.codFiscale?.toUpperCase()
        denuncia.pratica.indirizzoDen = selectedRecord?.indirizzo
        denuncia.pratica.comuneDenunciante = selectedRecord?.comuneResidenza
        filtri.comuneDenunciante.denominazione = denuncia.pratica.comuneDenunciante?.ad4Comune?.denominazione
    }

    @NotifyChange(["denuncia", "filtri"])
    @Command
    def onSelectCodFiscaleCon(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        def selectedRecord = event.getData()
        filtri.contribuente.codFiscale = selectedRecord?.codFiscale ?: selectedRecord?.partitaIva
        Contribuente cont = Contribuente.findByCodFiscale(filtri.contribuente.codFiscale)
        if (!cont) {
            denuncia.pratica.contribuente = new ContribuenteDTO(codFiscale: filtri.contribuente.codFiscale)
            denuncia.pratica.contribuente.soggetto = selectedRecord
        } else {
            denuncia.pratica.contribuente = cont.toDTO(["soggetto", "ente"])
        }
    }

    @NotifyChange(["denuncia"])
    @Command
    def onOpenCloseDenunciante() {
        flagDenunciante = !flagDenunciante
        svuotaDenunciante()
    }

    @Command
    def svuotaDenunciante() {
        if (flagDenunciante) {
            denuncia.pratica.denunciante = ""
            denuncia.pratica.codFiscaleDen = ""
            denuncia.pratica.indirizzoDen = ""
            filtri.denunciante.codFiscale = ""
            filtri.denunciante.cognomeNome = ""
            filtri.comuneDenunciante.denominazione = ""
            denuncia.pratica.comuneDenunciante = null
            denuncia.pratica.tipoCarica = null
            BindUtils.postNotifyChange(null, null, this, "denuncia")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    @Command
    def onChiudiPopup() {
        chiudi()
    }

    @Command
    def onOggettoEsistente() {

        oggCoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "oggCoSelezionato")
        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self, [filtri: null, listaVisibile: true, inPratica: true, ricercaContribuente: false, tipo: denuncia.pratica.tipoTributo?.tipoTributo])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Oggetto") {
                    apriOggettoContribuente(event.data.idOggetto)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAnniPrecedenti() {

        oggCoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "oggCoSelezionato")
        Window w = Executions.createComponents("/pratiche/denunce/listaOggettiAnniPrecedenti.zul", self
                , [anno: denuncia.pratica.anno, tipoTributo: denuncia.pratica.tipoTributo?.tipoTributo, contribuente: denuncia.pratica.contribuente.codFiscale, tipoRapporto: tipoRapporto])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Oggetto") {
                    List<OggettoContribuenteDTO> listaOggettiSelezionati = event.data.listaOggettoContribuente

                    if (listaOggettiSelezionati) {
                        if (listaOggettiSelezionati.size() == 1) {
                            def ogCo = listaOggettiSelezionati[0]
                            //Controllo esistenza di Detrazioni o Aliquote prima di aprire il nuovo oggetto contribuente selezionato
                            selezionaOggettoContribuente(ogCo)
                        } else {
                            selezionaListaOggettoContribuente(listaOggettiSelezionati)
                        }
                    }
                }
            }
        }
        w.doModal()
    }

    private selezionaListaOggettoContribuente(List<OggettoContribuenteDTO> listaOggettiSelezionati) {

        int count = listaOggettiSelezionati.size()

        //Controllo Detrazioni ed Aliquote
        int numDetrAliq = 0
        for (int i = 0; i < count; i++) {
            numDetrAliq += controlloEsistenzaDetrAliq(listaOggettiSelezionati.get(i))
        }
        //Se esistono detrazioni ed aliquote su alcuni oggetti
        if (numDetrAliq > 0) {
            String messaggio = "Si vogliono caricare anche Detrazioni e Aliquote sugli Oggetti selezionati?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                inserisciListaOggettoContribuente(listaOggettiSelezionati, true)
                            }
                            if (Messagebox.ON_NO.equals(e.getName())) {
                                inserisciListaOggettoContribuente(listaOggettiSelezionati, false)
                            }
                        }
                    }
            )
        } else {
            inserisciListaOggettoContribuente(listaOggettiSelezionati, false)
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaContitolari")
    }

    private inserisciListaOggettoContribuente(List<OggettoContribuenteDTO> listaOggettiSelezionati, boolean conDetrAliq) {
        OggettoContribuenteDTO oggettoContribuente

        //Refresh dell'elenco di partenza
        listaOggetti = denunceService.oggettiDenuncia(denuncia.pratica.id, denuncia.pratica.contribuente.codFiscale)

        int count = listaOggettiSelezionati.size()
        for (int i = 0; i < count; i++) {
            oggettoContribuente = clonaOggettoContribuente(listaOggettiSelezionati.get(i), conDetrAliq)
            //Calcolo del numero ordine, se non definito metto nulla così lo definisce l'utente dopo
            def numero = denunceService.calcolaNumeroOrdine(oggettoContribuente?.oggettoPratica?.pratica?.id)
            oggettoContribuente.oggettoPratica?.numOrdine = (numero) ? numero : null
            //Setto il mese da inizio possesso nel caso in cui fosse nullo
            oggettoContribuente.daMesePossesso = listaOggettiSelezionati.get(i).daMesePossesso

            /*BigDecimal rendita = oggettiService.getRenditaOggettoPratica(oggettoContribuente.oggettoPratica.valore
                    , oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto
                    , listaOggettiSelezionati.get(i).anno // oggettoContribuente.oggettoPratica.anno
                    , oggettoContribuente.oggettoPratica.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto)

            oggettoContribuente.oggettoPratica.valore = ricalcolaValore(oggettoContribuente, rendita)*/
            oggettoContribuente = oggettiService.salvaOggettoContribuente(oggettoContribuente, tipoRapporto, oggettoContribuente?.oggettoPratica?.pratica?.tipoTributo?.tipoTributo, false, oggettoContribuente?.oggettoPratica)
            denuncia.pratica.addToOggettiPratica(oggettoContribuente.oggettoPratica)
            listaOggetti << oggettoContribuente
        }

        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaContitolari")
    }

    private BigDecimal ricalcolaValore(def oggettoContribuente, def rendita) {
        //Invoca la funzione f_valore_da_rendita
        return oggettiService.valoreDaRendita(rendita
                , oggettoContribuente.oggettoPratica.tipoOggetto.tipoOggetto ?: oggettoContribuente.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                , oggettoContribuente.oggettoPratica.pratica.anno
                , oggettoContribuente.oggettoPratica.categoriaCatasto?.categoriaCatasto ?: oggettoContribuente.oggettoPratica.oggetto.categoriaCatasto?.categoriaCatasto
                , (oggettoContribuente.oggettoPratica.immStorico) ? "S" : "N"
        )
    }

    //Controllo esistenza di Detrazioni o Aliquote
    private int controlloEsistenzaDetrAliq(def ogco) {
        boolean presenzaDetrazioni = denunceService.presenzaDetrazioni(ogco.oggettoPratica, ogco.contribuente.codFiscale, ogco.oggettoPratica.pratica.tipoTributo.tipoTributo)
        boolean presenzaAliquote = denunceService.presenzaAliquote(ogco.oggettoPratica, ogco.contribuente.codFiscale, ogco.oggettoPratica.pratica.tipoTributo.tipoTributo)
        if (presenzaDetrazioni || presenzaAliquote) {
            return 1
        } else {
            return 0
        }
    }

    private selezionaOggettoContribuente(def ogco) {
        OggettoContribuenteDTO ogcoAnnoPrec = null

        //Controllo esistenza di Detrazioni o Aliquote
        boolean presenzaDetrazioni = denunceService.presenzaDetrazioni(ogco.oggettoPratica, ogco.contribuente.codFiscale, ogco.oggettoPratica.pratica.tipoTributo.tipoTributo)
        boolean presenzaAliquote = denunceService.presenzaAliquote(ogco.oggettoPratica, ogco.contribuente.codFiscale, ogco.oggettoPratica.pratica.tipoTributo.tipoTributo)
        if (presenzaDetrazioni || presenzaAliquote) {
            String messaggio = "Si vogliono caricare anche Detrazioni e Aliquote sull'Oggetto?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                ogcoAnnoPrec = clonaOggettoContribuente(ogco, true)
                                apriOggettoContribuente(ogcoAnnoPrec.oggettoPratica.oggetto.id, ogcoAnnoPrec)
                            }
                            if (Messagebox.ON_NO.equals(e.getName())) {
                                ogcoAnnoPrec = clonaOggettoContribuente(ogco, false)
                                apriOggettoContribuente(ogcoAnnoPrec.oggettoPratica.oggetto.id, ogcoAnnoPrec)
                            }
                        }
                    }
            )
        } else {
            ogcoAnnoPrec = clonaOggettoContribuente(ogco, false)
            apriOggettoContribuente(ogcoAnnoPrec.oggettoPratica.oggetto.id, ogcoAnnoPrec)
        }
    }


    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(denuncia?.pratica?.contribuente?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onModificaOggCo() {
        apriOggettoContribuente(-1)
    }

    @NotifyChange(["listaOggetti", "oggCoSelezionato"])
    @Command
    def onDuplicaOggCo() {
        //Controllo esistenza di Detrazioni o Aliquote
        boolean presenzaDetrazioni = denunceService.presenzaDetrazioni(oggCoSelezionato.oggettoPratica, oggCoSelezionato.contribuente.codFiscale, oggCoSelezionato.oggettoPratica.pratica.tipoTributo.tipoTributo)
        boolean presenzaAliquote = denunceService.presenzaAliquote(oggCoSelezionato.oggettoPratica, oggCoSelezionato.contribuente.codFiscale, oggCoSelezionato.oggettoPratica.pratica.tipoTributo.tipoTributo)
        if (presenzaDetrazioni || presenzaAliquote) {
            String messaggio = "Si vogliono caricare anche Detrazioni e Aliquote sull'Oggetto?"
            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                duplicaOggettoContribuente(true)
                            }
                            if (Messagebox.ON_NO.equals(e.getName())) {
                                duplicaOggettoContribuente(false)
                            }
                        }
                    }
            )
        } else {
            duplicaOggettoContribuente(false)
        }
    }

    private duplicaOggettoContribuente(boolean conDetrazioniAliquote) {
        OggettoContribuenteDTO ogcoDuplicato = clonaOggettoContribuente(oggCoSelezionato, conDetrazioniAliquote)
        oggCoSelezionato = null
        apriOggettoContribuente(ogcoDuplicato.oggettoPratica.oggetto.id, ogcoDuplicato)
    }

    @NotifyChange(["listaOggetti"])
    @Command
    def onEliminaOggCo() {
        if (oggettiSelezionati.isEmpty()) {
            eliminazioneOgcoSingola(oggCoSelezionato)
        } else {
            oggettiSelezionati.each {
                eliminazioneOgcoSingola(it.key)
            }

            oggettoAttuale = 0
        }
    }

    def setSelectCodFiscaleCon(def selectedRecord) {
        if (selectedRecord) {

            def codFiscale = (selectedRecord instanceof SoggettoDTO) ?
                    (selectedRecord?.contribuenti[0]?.codFiscale?.toUpperCase() ?: selectedRecord?.codFiscale?.toUpperCase()) ?: selectedRecord?.partitaIva?.toUpperCase() :
                    selectedRecord?.codFiscale?.toUpperCase()

            filtri.contribuente.codFiscale = codFiscale
            String cognomeNome = selectedRecord?.cognomeNome
            filtri.contribuente.cognome = (cognomeNome.indexOf("/") != -1) ? cognomeNome?.substring(0, cognomeNome.indexOf("/")) : cognomeNome
            filtri.contribuente.nome = (cognomeNome.indexOf("/") != -1) ? cognomeNome?.substring(cognomeNome.indexOf("/") + 1, cognomeNome?.length()) : ""
            Contribuente cont = Contribuente.findByCodFiscale(codFiscale)
            if (!cont) {
                denuncia.pratica.contribuente = new ContribuenteDTO(codFiscale: codFiscale)
                denuncia.pratica.contribuente.soggetto = selectedRecord
            } else {
                denuncia.pratica.contribuente = cont.toDTO(["soggetto", "ente"])
            }
            BindUtils.postNotifyChange(null, null, this, "denuncia")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    def setSelectCodFiscaleDen(def selectedRecord) {
        if (selectedRecord) {
            filtri.denunciante.codFiscale = selectedRecord?.codFiscale?.toUpperCase()
            filtri.denunciante.cognomeNome = selectedRecord?.cognomeNome?.toUpperCase()
            denuncia.pratica.denunciante = selectedRecord?.cognomeNome?.toUpperCase()
            denuncia.pratica.codFiscaleDen = selectedRecord?.codFiscale?.toUpperCase()
            BindUtils.postNotifyChange(null, null, this, "denuncia")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    def eliminazioneOgcoSingola(def oggCoDaEliminare) {

        //Nel caso si IMU o ICI si controlla se esistono contitolari sul quadro
        if ((tipoTributoAttuale == "IMU" || tipoTributoAttuale == "ICI") && checkEsisteContitolari(oggCoDaEliminare)) {
            def messaggio = "Esistono contitolari sul quadro selezionato. La registrazione non è eliminabile."
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return false
        } else {

            def numOggettiDaEliminare = oggettiSelezionati.size()
            String oggettoNDiM = ''
            if (numOggettiDaEliminare > 1) {
                oggettoNDiM = ':' + ++oggettoAttuale + '/' + numOggettiDaEliminare
            }

            Map params = new HashMap()
            params.put("width", "600")

            Messagebox.Button[] buttons = [
                    Messagebox.Button.YES,
                    Messagebox.Button.NO
            ]

            String anomalie = ""

            for (def anom : gestioneAnomalieService.anomalieAssociateAdOgCo(oggCoDaEliminare.toDomain())) {
                anomalie += (anom.idTipoAnomalia + " " + anom.descrizione + " " + anom.tipoTributo + " " + anom.anno + (anom.flagImposta == 'S' ? ' Imposta' : '')) + "\n"
            }

            Messagebox.show("Eliminazione della registrazione?\n\nImmobile: ${oggCoDaEliminare.oggettoPratica.numOrdine}\n\nL'operazione non potrà essere annullata." +
                    (!anomalie.isEmpty() ? "\nAnomalie associate all'oggetto pratica:\n" + anomalie : ""),
                    "Oggetti del dichiarante $oggettoNDiM",
                    buttons,
                    null,
                    Messagebox.QUESTION,
                    null,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                //SOLO per la tasi eliminare ogco corrisponde ad eliminare ogpr
                                //perchè c'è un rapporto uno ad uno.
                                eliminaOggettoContribuente(oggCoDaEliminare)
                            }
                        }
                    },
                    params
            )
        }
    }

    protected void apriOggettoContribuente(def idOggetto, def oggettoAnniPrec = null) {

        int indexSelezione = listaOggetti?.indexOf(oggCoSelezionato) ?: 0
        Window w = Executions.createComponents("/pratiche/denunce/oggettoContribuente.zul", self
                , [idOggPr         : oggCoSelezionato ? oggCoSelezionato.oggettoPratica.id : -1
                   , contribuente  : denuncia.pratica.contribuente.codFiscale
                   , tipoRapporto  : oggCoSelezionato ? oggCoSelezionato.tipoRapporto : tipoRapporto
                   , tipoTributo   : denuncia.pratica.tipoTributo?.tipoTributo
                   , idOggetto     : idOggetto
                   , pratica       : denuncia.pratica
                   , oggCo         : oggettoAnniPrec
                   , listaId       : listaOggetti
                   , indexSelezione: indexSelezione
                   , modifica      : modifica
                   , storica       : isStorica
                   , daBonifiche   : false])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Salva") {
                    def oggCoSalvato = event.data.oggCo
                    listaOggetti = denunceService.oggettiDenuncia(denuncia.pratica.id, denuncia.pratica.contribuente.codFiscale)
                    listaOggetti.each {
                        it.oggettoPratica.pratica.tipoTributo = denuncia.pratica.tipoTributo
                    }

                    // Visualizzazione flag AP Issue 50484
                    oggCoSalvato.flagAbPrincipale = listaOggetti.find {
                        it.contribuente.codFiscale == oggCoSalvato.contribuente.codFiscale &&
                                it.oggettoPratica.id == oggCoSalvato.oggettoPratica.id
                    }?.flagAbPrincipale

                    def idx = listaOggetti.findIndexOf {
                        it.contribuente.codFiscale == oggCoSalvato.contribuente.codFiscale &&
                                it.oggettoPratica.id == oggCoSalvato.oggettoPratica.id
                    }
                    if (idx >= 0) {
                        listaOggetti[idx] = oggCoSalvato
                    } else {
                        denuncia.pratica.addToOggettiPratica(oggCoSalvato.oggettoPratica)
                        listaOggetti << oggCoSalvato
                    }
                    oggCoSelezionato = oggCoSalvato
                    getContitolari()
                    BindUtils.postNotifyChange(null, null, this, "listaOggetti")
                    BindUtils.postNotifyChange(null, null, this, "listaContitolari")
                    BindUtils.postNotifyChange(null, null, this, "oggCoSelezionato")
                }
            }
        }
        w.doModal()
    }

    @Command
    def onSelectComuneDen(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        if (event.getData()) {
            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            denuncia.pratica.comuneDenunciante = ad4ComuneTr4DTO
        } else {
            denuncia.pratica.comuneDenunciante = null
        }
        BindUtils.postNotifyChange(null, null, this, "denuncia")
    }

    @NotifyChange(["denuncia"])
    @Command
    def onChangeComuneDen(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {
        denuncia.pratica.comuneDenunciante = null
    }

    @Command
    def onApriNote(@BindingParam("arg") def nota) {
        Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onSelezionaTuttiImmobili() {

        def numOggSel = oggettiSelezionati.size()

        // Si pulisce la selezione
        oggettiSelezionati.clear()

        // Se non erano selezionati tutti gli oggetti si selezionano
        if (listaOggetti.size() != numOggSel) {
            listaOggetti.each {
                oggettiSelezionati << [(it): true]
            }
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
    }

    @Command
    def onSelezionaImmobile(@BindingParam("selezione") def oggCo) {

        if (oggettiSelezionati[oggCo]) {
            oggettiSelezionati.remove(oggCo)
        } else {
            oggettiSelezionati << [(oggCo): true]
        }

        BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
    }

    @Command
    def onVisualizzaDocumentoNota() {

        byte[] documentoNota = denunceService.documentoNota(oggCoSelezionato.attributoOgco.documentoId.id, oggCoSelezionato.attributoOgco.numeroNota)

        AMedia amedia = commonService.fileToAMedia("notai_${denuncia.pratica.contribuente.codFiscale}_${denuncia.pratica.id}.html", documentoNota)
        Filedownload.save(amedia)
    }

    @Command
    def onDatiDichiarazioneENC() {

        Window w = Executions.createComponents("/pratiche/denunce/denunciaDichiarazioneENC.zul", self,
                [
                        idPratica  : denuncia.pratica.id,
                        tipoTributo: denuncia.pratica.tipoTributo.tipoTributo
                ]
        )
        w.doModal()
    }

    @Command
    def onDatiDocFA() {

        def datiDocFa = denunceService.getDocFA(denuncia.pratica.id)

        if (datiDocFa.size() > 0) {

            /*
                Fa cedere sempre e solo il primo.
                In caso di multipli andrebbe utilizzato ModelliService.mergePdf(List<byte[]>) ,
                tuttavia probabilmente va rivisto qualcosa a livello di DB
             */

            def docFa = datiDocFa[0]

            AMedia amedia = new AMedia(docFa.nomeDocumento2, "pdf", "application/pdf", docFa.contenuto2)
            Filedownload.save(amedia)
        } else {

            String title = "Errore"
            String message = "Attenzione :\n\nImpossibile recuperare il documento"
            Messagebox.show(message, title, Messagebox.OK, Messagebox.ERROR)
        }
    }

    @Command
    def onOggettoDatiNotai() {

        Window w = Executions.createComponents("/pratiche/denunce/oggettoDatiNotai.zul", self,
                [
                        oggettoContribuente: oggCoSelezionato
                ]
        )
        w.doModal()
    }

    @Command
    def onOggettoDatiSuccessione() {

        Window w = Executions.createComponents("/pratiche/denunce/successione.zul", self,
                [
                        idSuccessione        : oggCoSelezionato.successione,
                        idOggetto            : oggCoSelezionato.oggettoPratica.oggetto.id,
                        tipoTributo          : denuncia.pratica.tipoTributo.tipoTributo,
                        codFiscaleRiferimento: denuncia.pratica.contribuente.codFiscale
                ]
        )
        w.doModal()
    }

    @Command
    def onOggettoDichiarazioneENC() {

        Window w = Executions.createComponents("/pratiche/denunce/oggettoDichiarazioneENC.zul", self,
                [
                        idOggPratica: oggCoSelezionato.oggettoPratica.id,
                        tipoTributo : denuncia.pratica.tipoTributo.tipoTributo
                ]
        )
        w.doModal()
    }

    @Command
    def onDuplica() {

        if (!controllaDetrOggetti()) {
            Clients.showNotification("Esiste un quadro con Detrazione valorizzata e % Detrazione non valorizzata.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        Window w = Executions.createComponents("/pratiche/denunce/duplicaDenuncia.zul", self, [denuncia: denuncia.pratica.id, tipoTributo: denuncia.pratica.tipoTributo.tipoTributo, tipoRapporto: tipoRapporto, listaOggetti: listaOggetti])
        w.doModal()
    }

    @Command
    boolean checkEsistenzaDetrazioniOgco(@BindingParam("cb") Checkbox cb, @BindingParam("oggCo") def oggCo) {
        cb.checked = denunceService.presenzaDetrazioni(oggCo?.oggettoPratica, oggCo?.contribuente?.codFiscale, oggCo?.oggettoPratica?.pratica?.tipoTributo?.tipoTributo)
        BindUtils.postNotifyChange(null, null, this, "cb")
    }

    @Command
    boolean checkEsistenzaAliquoteOgco(@BindingParam("cb") Checkbox cb, @BindingParam("oggCo") def oggCo) {
        cb.checked = denunceService.presenzaAliquote(oggCo?.oggettoPratica, oggCo?.contribuente?.codFiscale, oggCo?.oggettoPratica?.pratica?.tipoTributo?.tipoTributo)
        BindUtils.postNotifyChange(null, null, this, "cb")
    }

    @Command
    boolean checkEsistenzaUtilizziOgco(@BindingParam("cb") Checkbox cb, @BindingParam("oggCo") def oggCo) {
        cb.checked = denunceService.presenzaUtilizziOggetto(oggCo.oggettoPratica.pratica.tipoTributo.tipoTributo,
                denuncia.pratica.anno,
                oggCo.oggettoPratica.oggetto.id,
                denuncia.pratica.data,
                Date.parse('dd/MM/yyyy', '31/12/9999'))
        BindUtils.postNotifyChange(null, null, this, "cb")
    }


    protected def onLockUnlockModificaAnno(Closure saveMethod) {

        if (sbloccaModificaAnnoVisibile) {

            valorePrecedenteAnno = denuncia.pratica.anno

            abilitaModificaAnno = true
            sbloccaModificaAnnoVisibile = false
            bloccaModificaAnnoVisibile = true
        } else {
            if (valorePrecedenteAnno != denuncia.pratica.anno) {
                saveMethod()

                valorePrecedenteAnno = denuncia.pratica.anno
            }
            abilitaModificaAnno = false
            sbloccaModificaAnnoVisibile = true
            bloccaModificaAnnoVisibile = false
        }

        BindUtils.postNotifyChange(null, null, this, "abilitaModificaAnno")
        BindUtils.postNotifyChange(null, null, this, "valorePrecedenteAnno")
        BindUtils.postNotifyChange(null, null, this, "sbloccaModificaAnnoVisibile")
        BindUtils.postNotifyChange(null, null, this, "bloccaModificaAnnoVisibile")
    }

    @Command
    def onApriMotivo(@BindingParam("arg") def motivo) {
        Messagebox.show(motivo, "Motivo", Messagebox.OK, Messagebox.INFORMATION)
    }

    @Command
    def onStampaDenuncia() {

        def nomeFile = "DEN_" + (denuncia.pratica.id as String).padLeft(10, "0") + "_" + denuncia.pratica.contribuente.codFiscale.padLeft(16, "0")
        def parametri = [
                tipoStampa : ModelliService.TipoStampa.PRATICA,
                idDocumento: denuncia.pratica.id,
                nomeFile   : nomeFile
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    @Command
    def onSelectTabs() {
        // Nulla da fare
    }

    protected def eliminaPratica() {
        def msg = ""
        try {
            msg = denunceService.eliminaPratica(denuncia.pratica)
            if (!msg.isEmpty()) {
                Clients.showNotification(msg, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
                return false
            } else
                return true
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                return false
            } else {
                throw e
            }
        }
    }

    /*
        Verifica se può salvare la denuncia
        Restituisce "true" se tutto ok.
     */

    protected boolean salvaDenunciaCheck() {

        boolean proceed = false

        def checkResult = denunceService.salvaDenunciaCheck(denuncia)
        def result = checkResult.result
        def message = checkResult.message

        switch (result) {
            case 0:
                proceed = true
                break
            case 1:
                proceed = true
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 10000, true)
                break
            case 2:
                proceed = false
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
                break
        }

        return proceed
    }

    // Post processa salvataggio denuncia
    protected def salvaDenunciaPostProcessa(def salvaDenuncia) {

        denuncia = salvaDenuncia.denuncia

        def ravvedimentiPosteriori = salvaDenuncia.ravvedimentiPosteriori
        if (ravvedimentiPosteriori.size() > 0) {

            String messaggio = "Vuoi Aggiornare gli immobili dei ravvedimenti?"
            Messagebox.show(messaggio, "Presenza di Ravvedimenti",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                aggiornaRavvedimentiPosteriori(ravvedimentiPosteriori)
                            }
                        }
                    }
            )
        }
    }

    // Aggiorna i ravvedimenti posteriori della pratica
    protected def aggiornaRavvedimentiPosteriori(def ravvedimenti) {

        def checkResult = denunceService.aggiornaImmobiliRavvedimenti(ravvedimenti)
        def result = checkResult.result
        def message = checkResult.message

        switch (result) {
            case 0:
            case 1:
                String title = "Aggiorna Immobili Ravvedimenti"
                String messaggio = "Aggiorna Immobili completato\n\n${message}"
                Messagebox.show(messaggio, title, Messagebox.OK, Messagebox.INFORMATION)
                break
            case 2:
                String title = "Problema sui Ravvedimenti"
                String messaggio = "Errore durante Aggiorna Immobili !\n\n${message}"
                Messagebox.show(messaggio, title, Messagebox.OK, Messagebox.ERROR)
                break
        }
    }

    // Gestisce box e lucchetto per modifica annualità
    protected def aggiornaModificaAnno() {

        bloccaModificaAnnoVisibile = false
        sbloccaModificaAnnoVisibile = false

        if ((denuncia.id) && (!isStorica)) {

            abilitaModificaAnno = false

            if (denunceService.consentiModificaAnno(denuncia)) {

                sbloccaModificaAnnoVisibile = true
            }
        } else {

            abilitaModificaAnno = true
        }

        BindUtils.postNotifyChange(null, null, this, "abilitaModificaAnno")
        BindUtils.postNotifyChange(null, null, this, "sbloccaModificaAnnoVisibile")
        BindUtils.postNotifyChange(null, null, this, "bloccaModificaAnnoVisibile")
    }

    // Verifica presenza documento nota passandosi gli oggetti
    protected def aggiornaDocumentoNota() {

        documentoNotaId = null

        if (listaOggetti) {

            listaOggetti.each {

                if (it.attributiOgco != null) {
                    if (it.attributiOgco.documentoId != null) {

                        documentoNotaId = it.attributiOgco.documentoId.id
                    }
                }
            }
        }

        BindUtils.postNotifyChange(null, null, this, "documentoNotaId")
    }

    @Deprecated
    protected void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }

    protected chiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato, praticaEliminata: true, salvato: denunciaSalvata])
    }

    protected OggettoContribuenteDTO clonaOggettoContribuente(OggettoContribuenteDTO ogcoDaClonare, boolean conDetrazioniAliquote = false) {

        BigDecimal renditaIniziale = oggettiService.getRenditaOggettoPratica(ogcoDaClonare.oggettoPratica.valore
                , ogcoDaClonare.oggettoPratica.tipoOggetto.tipoOggetto
                , ogcoDaClonare.oggettoPratica.anno
                , ogcoDaClonare.oggettoPratica.categoriaCatasto ?: ogcoDaClonare.oggettoPratica.oggetto.categoriaCatasto)
        BigDecimal valoreAttuale = oggettiService.valoreDaRendita(renditaIniziale
                , ogcoDaClonare.oggettoPratica.tipoOggetto.tipoOggetto ?: ogcoDaClonare.oggettoPratica.oggetto.tipoOggetto.tipoOggetto
                , denuncia.pratica.anno
                , ogcoDaClonare.oggettoPratica.categoriaCatasto?.categoriaCatasto ?: ogcoDaClonare.oggettoPratica.oggetto.categoriaCatasto?.categoriaCatasto
                , (ogcoDaClonare.oggettoPratica.immStorico) ? "S" : "N"
        )

        OggettoContribuenteDTO ogcoDuplicato = new OggettoContribuenteDTO()
        OggettoPraticaDTO ogprDuplicato = new OggettoPraticaDTO()

        ogprDuplicato.categoriaCatasto = ogcoDaClonare.oggettoPratica.categoriaCatasto
        ogprDuplicato.classeCatasto = ogcoDaClonare.oggettoPratica.classeCatasto
        ogprDuplicato.tipoOggetto = ogcoDaClonare.oggettoPratica.tipoOggetto
        ogprDuplicato.fonte = ogcoDaClonare.oggettoPratica.oggetto.fonte
        ogprDuplicato.anno = denuncia.pratica.anno
        ogprDuplicato.valore = valoreAttuale // ogcoDaClonare.oggettoPratica.valore
        ogprDuplicato.oggetto = ogcoDaClonare.oggettoPratica.oggetto

        ogprDuplicato.oggettoPraticaRifAp = ogcoDaClonare.oggettoPratica.oggettoPraticaRifAp

        ogprDuplicato.pratica = denuncia.pratica

        ogcoDuplicato.contribuente = ogcoDaClonare.contribuente
        ogcoDuplicato.contribuente.soggetto = denuncia.pratica.contribuente.soggetto
        ogcoDuplicato.percPossesso = ogcoDaClonare.percPossesso
        ogcoDuplicato.flagPossesso = ogcoDaClonare.flagPossesso
        ogcoDuplicato.flagEsclusione = ogcoDaClonare.flagEsclusione
        ogcoDuplicato.flagRiduzione = ogcoDaClonare.flagRiduzione
        ogcoDuplicato.flagAbPrincipale = ogcoDaClonare.flagAbPrincipale

        ogcoDuplicato.tipoRapporto = (ogcoDaClonare) ? ogcoDaClonare.tipoRapporto : tipoRapporto
        ogcoDuplicato.mesiPossesso = ogcoDaClonare.mesiPossesso
        ogcoDuplicato.mesiPossesso1sem = ogcoDaClonare.mesiPossesso1sem
        ogcoDuplicato.mesiOccupato = ogcoDaClonare.mesiOccupato
        ogcoDuplicato.mesiOccupato1sem = ogcoDaClonare.mesiOccupato1sem
        ogcoDuplicato.mesiEsclusione = ogcoDaClonare.mesiEsclusione
        ogcoDuplicato.mesiRiduzione = ogcoDaClonare.mesiRiduzione
        ogcoDuplicato.mesiAliquotaRidotta = ogcoDaClonare.mesiAliquotaRidotta
        ogcoDuplicato.detrazione = ogcoDaClonare.detrazione
        ogcoDuplicato.percDetrazione = ogcoDaClonare.percDetrazione
        ogcoDuplicato.anno = denuncia.pratica.anno

        // ogprDuplicato.oggettoPraticaRendita = OggettoPraticaRendita.get(ogcoDaClonare.oggettoPratica.id)?.toDTO()
        ogcoDuplicato.oggettoPratica = ogprDuplicato

        // Gestione Aliquote OGCO e Detrazioni OGCO
        if (conDetrazioniAliquote) {

            OggettoContribuenteDTO ogco = OggettoContribuente.createCriteria().get {
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

                eq("contribuente.codFiscale", denuncia.pratica.contribuente.codFiscale)
                eq("tipoRapporto", ogcoDaClonare.tipoRapporto)
                eq("ogpr.id", ogcoDaClonare.oggettoPratica.id)

            }?.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])

            ogco?.aliquoteOgco?.each {
                AliquotaOgcoDTO aOgco = new AliquotaOgcoDTO([dal         : it.dal,
                                                             al          : it.al,
                                                             tipoAliquota: it.tipoAliquota,
                                                             note        : it.note])
                ogcoDuplicato.addToAliquoteOgco(aOgco)
                aOgco.oggettoContribuente = ogcoDuplicato
            }

            ogco?.detrazioniOgco?.each {
                DetrazioneOgcoDTO dOgco = new DetrazioneOgcoDTO([motDetrazione    : it.motDetrazione,
                                                                 anno             : it.anno,
                                                                 detrazione       : it.detrazione,
                                                                 note             : it.note,
                                                                 detrazioneAcconto: it.detrazioneAcconto,
                                                                 motivoDetrazione : it.motivoDetrazione,
                                                                 tipoTributo      : it.tipoTributo])
                ogcoDuplicato.addToDetrazioniOgco(dOgco)
                dOgco.oggettoContribuente = ogcoDuplicato
            }
        }
        return ogcoDuplicato
    }

    protected String eliminaOggettoContribuente(OggettoContribuenteDTO ogco) {
        String message = denunceService.eliminaOgCo(ogco)
        if (message) {
            Messagebox.show(message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            listaOggetti = denunceService.oggettiDenuncia(denuncia.pratica.id, denuncia.pratica.contribuente.codFiscale)

            if (tipoTributoAttuale == "IMU" || tipoTributoAttuale == "ICI") {
                caricaListaContitolari()
            } else {
                oggettiSelezionati.remove(ogco)
            }

            oggCoSelezionato = null
            oggettiSelezionati.clear()

            BindUtils.postNotifyChange(null, null, this, "listaOggetti")
            BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
            BindUtils.postNotifyChange(null, null, this, "oggCoSelezionato")
        }
    }

    protected void eliminaOggettoPratica() {
        denunceService.eliminaOgpr(oggCoSelezionato.oggettoPratica)
        listaOggetti = denunceService.oggettiDenuncia(denuncia.pratica.id, denuncia.pratica.contribuente.codFiscale)
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    protected void svuotaContribuente() {
        denuncia.pratica.contribuente = null
        filtri.contribuente.codFiscale = ""
        BindUtils.postNotifyChange(null, null, this, "denuncia")
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    protected void creaPopupSoggetto(String zul, def parametri, boolean cfDenunciante = false) {
        (cfDenunciante) ? parametri.put("codiceFiscale", filtri?.denunciante?.codFiscale) : parametri.put("codiceFiscale", filtri?.contribuente?.codFiscale)
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    if (!cfDenunciante)
                        (event.data.Soggetto) ? setSelectCodFiscaleCon(event.data.Soggetto) : svuotaContribuente()
                    else
                        (event.data.Soggetto) ? setSelectCodFiscaleDen(event.data.Soggetto) : svuotaDenunciante()
                }
            }
        }
        w.doModal()
    }

    protected boolean controllaDetrOggetti() {

        for (def detr in listaOggetti) {
            if (detr.detrazione != null && detr.percDetrazione == null) {
                return false
            }
        }

        return true
    }

    protected def aggiornaDataModifica() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        def date = denuncia?.pratica?.lastUpdated
        lastUpdated = (date) ? sdf.format(date) : ''
        BindUtils.postNotifyChange(null, null, this, "lastUpdated")
    }

    protected def aggiornaUtente() {
        utente = denuncia?.utente?.id
        BindUtils.postNotifyChange(null, null, this, "utente")
    }
}
