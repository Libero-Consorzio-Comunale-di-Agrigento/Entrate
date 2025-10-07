package ufficiotributi.canoneunico

import it.finmatica.tr4.ArchivioVie
import it.finmatica.tr4.TipoCarica
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class ConcessioneCUViewModel {

    Window self

    // services
    CanoneUnicoService canoneUnicoService
    OggettiService oggettiService

    def oggettoRiferimento = null
    def annoRiferimento = null
    def contribuenteRiferimento = null
    PraticaTributoDTO praticaRiferimento = null
    def dataRiferimento = null

    def concessione = null

    boolean lettura = false
    boolean modificabile = false
    boolean modificaFrontespizio = false
    boolean modificaEstremi = false
    boolean selezioneOggetto = false
    boolean chiudibile = false
    boolean convertibile = false
    boolean duplicabile = false
    boolean eliminabile = false
    boolean calcolabile = false

    boolean quadroFrontespizio = true
    boolean quadroDenunciante = false
    boolean quadroPubblicita = false
    boolean quadroOccupazione = false

    boolean aggiornaStato = false

    def giornateTariffa = null

    def cbTributi

    def listaAnni = null

    List<CategoriaDTO> elencoCategorie = []
    List<TariffaDTO> elencoTariffe = []

    List<CodiceTributoDTO> listaCodici = []
    List<CategoriaDTO> listaCategorie = []
    List<TariffaDTO> listaTariffe = []

    List<TipoOggettoDTO> listaTipiOggetto = []
    List<TipoCaricaDTO> listaCariche = []

    def listTipiOccupazione = []

    def listaAssociazioniVie = []
    def listaZone = []

    TariffaDTO tariffaAttiva = null
    TariffaDTO tariffaSecondaria = null

    String lastUpdated
    def utente

    // Uso parziale, solo per bandboxView
    def parametriBandBox = [
            annoTributo         : 2021,
            tipoTributo         : "CUNI",
            comuneDenunciante   : [
                    denominazione: "",
                    provincia    : "",
                    siglaProv    : ""
            ],
            soggDenunciante     : [
                    id        : null,
                    codFiscale: ""
            ],
            caricaDenunciante   : null,
            codiceViaOggetto    : null,
            indirizzoOggetto    : null,
            tipoOggetto         : null,
            comuneOggetto       : [
                    denominazione: "",
                    provincia    : "",
                    siglaProv    : ""
            ],
            tariffaCodice       : null,
            tariffaCategoria    : null,
            tariffaOccupazione  : null,
            tariffaTariffa      : null,
            descrizioneCategoria: null,
            descrizioneTariffa  : '-',
            zonaRilevata        : '--'
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("oggetto") def oggRif,
         @ExecutionArgParam("dataRiferimento") def dataRif,
         @ExecutionArgParam("anno") def annoRif,
         @ExecutionArgParam("contribuente") def contrRif,
         @ExecutionArgParam("pratica") def pratica,
         @ExecutionArgParam("lettura") def lt) {

        this.self = w

        this.lettura = lt ?: false

        contribuenteRiferimento = contrRif

        if ((pratica ?: 0) > 0) {
            praticaRiferimento = PraticaTributo.get(pratica)?.toDTO(["comuneDenunciante", "comuneDenunciante.ad4Comune", "comuneDenunciante.ad4Comune.provincia"])
        } else {
            praticaRiferimento = null
        }
        def pratRef = (praticaRiferimento?.id ?: 0)

        oggettoRiferimento = oggRif ?: 0
        annoRiferimento = annoRif
        dataRiferimento = dataRif

        listaAssociazioniVie = []
        listaZone = []

        def annoCorrente = Calendar.getInstance().get(Calendar.YEAR)

        listaAnni = []

        listaCariche = TipoCarica.findAllByIdGreaterThanEquals("0", [sort: "id", order: "asc"]).toDTO()
        listaCariche << new TipoCaricaDTO(id: null, descrizione: "")

        cbTributi = [
                'ICP'  : false,
                'TOSAP': false,
                'CUNI' : true
        ]

        def tipoPraticaRiferimento = praticaRiferimento?.tipoPratica ?: TipoPratica.D.tipoPratica

        if (oggettoRiferimento != 0) {

            def parametriRicerca = [
                    codFiscale    : contribuenteRiferimento?.codFiscale,
                    anno          : annoRiferimento.toString(),
                    dataRif       : dataRiferimento,
                    tipiTributo   : ['CUNI': true],
                    tipiPratiche  : null,
                    oggettoRif    : oggettoRiferimento,
                    ignoraValidita: tipoPraticaRiferimento == TipoPratica.V.tipoPratica    // In caso di ravvedimento ignora lo storico pratiche
            ]

            def concessioni = canoneUnicoService.getConcessioniContribuente(parametriRicerca)
            if (concessioni.size() > 0) {

                concessione = concessioni[0]
            }
        }

        if (concessione == null) {

            concessione = canoneUnicoService.getConcessione()

            if (pratRef > 0) {
                canoneUnicoService.fillConcessioneDaPratica(concessione, pratRef)
            } else {
                concessione.contribuente = contribuenteRiferimento.codFiscale
                concessione.tipoRapporto = 'D'

                concessione.anno = annoCorrente
                concessione.tipoTributo = "CUNI"

                concessione.dataPratica = canoneUnicoService.getDataOdierna()

                concessione.dettagli.tipoOccupazione = TipoOccupazione.P.id
            }
        } else {
            if (pratRef > 0) {
                if ((concessione.praticaPub == pratRef) || (concessione.praticaOcc == pratRef)) {
                    concessione.praticaRef = pratRef
                }
            }
        }

        //	quadroFrontespizio = (praticaRiferimento) ? false : true;

        onRefresh()

    }

    /// ############################################################################################################################
    ///	Eventi interfaccia
    /// ############################################################################################################################

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

        if (annoTributo >= 2021) {
            parametriBandBox.tipoTributo = "CUNI"
        } else {
            if (parametriBandBox.tipoTributo == "CUNI") {
                parametriBandBox.tipoTributo = "ICP"
            }
        }

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")

        ricaricaTabelleVieZone()

        aggiornaZonaDaIndirizzo()

        ricaricaTariffario()
    }

    @Command
    def onCheckTipoTributo() {

        def annoTributo = parametriBandBox.annoTributo as Integer

        if (parametriBandBox.tipoTributo == "CUNI") {
            if (annoTributo < 2021) parametriBandBox.annoTributo = "2021"
        } else {
            if (annoTributo >= 2021) {
                parametriBandBox.tipoTributo = "CUNI"
            }
        }

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")

        ricaricaTariffario()
    }

    @Command
    def onChangeDataDecorrenza() {

        aggiornaGiornateTariffa()
    }

    @Command
    def onChangeDataCessazione() {

        aggiornaGiornateTariffa()
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
    def onSelectViaOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def selectedVia = event.data

        parametriBandBox.codiceViaOggetto = (selectedVia.id ?: null)
        parametriBandBox.indirizzoOggetto = (selectedVia.denomUff ?: null)

        aggiornaZonaDaIndirizzo()

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onChangeCivicoOggetto() {

        aggiornaZonaDaIndirizzo()

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onChangeChilometricaOggetto() {

        aggiornaZonaDaIndirizzo()

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onSelectComuneOggetto(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def selectedComune = event?.data
        def oggetto = concessione.oggetto

        if (selectedComune != null) {
            oggetto.codCom = selectedComune.comune
            oggetto.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
            oggetto.denCom = selectedComune.denominazione
            oggetto.denPro = selectedComune.provincia?.denominazione
            oggetto.sigPro = selectedComune.provincia?.sigla
        } else {
            oggetto.codCom = null
            oggetto.codPro = null
            oggetto.denCom = null
            oggetto.denPro = null
            oggetto.sigPro = null
        }

        parametriBandBox.comuneOggetto.denominazione = oggetto.denCom
        parametriBandBox.comuneOggetto.provincia = oggetto.denPro
        parametriBandBox.comuneOggetto.siglaProv = oggetto.sigPro

        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
    }

    @Command
    def onSelectCodiceTributo() {

        if (parametriBandBox.tipoTributo == "CUNI") {

            // Non utilizzato
        } else {

            ricaricaTipiOccupazione(true)
            ricaricaCategorie(true)
            ricaricaTariffe(true)
        }
    }

    @Command
    def onSelectTipoOccupazione() {

        if (parametriBandBox.tipoTributo == "CUNI") {

            if (parametriBandBox.tariffaOccupazione != null) {
                concessione.dettagli.tipoOccupazione = parametriBandBox.tariffaOccupazione.codice
            }

            ricaricaCategorieCU(true)

            aggiornaTariffa()
            aggiornaQuadri()
        } else {

            aggiornaGiornateTariffa()
        }

        ricalcolaConsistenzaCambioTariffa()
    }

    @Command
    def onSelectCategoria() {

        if (parametriBandBox.tipoTributo == "CUNI") {

            if (parametriBandBox.tariffaCategoria != null) {
                concessione.categoria = parametriBandBox.tariffaCategoria.categoria
                parametriBandBox.descrizioneCategoria = parametriBandBox.tariffaCategoria?.descrizione
            }

            aggiornaTariffa()
            aggiornaQuadri()
        } else {

            ricaricaTariffe(true)
        }

        ricalcolaConsistenzaCambioTariffa()
    }

    @Command
    def onSelectTariffa() {

        if (parametriBandBox.tipoTributo == "CUNI") {

            ricaricaTipiOccupazione(true)
            ricaricaCategorieCU(true)

            aggiornaTariffa()
            aggiornaQuadri()
        } else {

            // Non serve
        }

        ricalcolaConsistenzaCambioTariffa()
    }

    @Command
    def onChangePubQuantita() {

        def tariffaCodice = tariffaAttiva?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.pubblicita

        Boolean changed = canoneUnicoService.verificaQuantita(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    @Command
    def onChangePubLarghezza() {

        def tariffaCodice = tariffaAttiva?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.pubblicita

        Boolean changed = canoneUnicoService.verificaDimensioni(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    @Command
    def onChangePubProfondita() {

        def tariffaCodice = tariffaAttiva?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.pubblicita

        Boolean changed = canoneUnicoService.verificaDimensioni(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    @Command
    def onChangeOccQuantita() {

        def tariffa = (tariffaSecondaria != null) ? tariffaSecondaria : tariffaAttiva
        def tariffaCodice = tariffa?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.occupazione

        Boolean changed = canoneUnicoService.verificaQuantita(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    @Command
    def onChangeOccLarghezza() {

        def tariffa = (tariffaSecondaria != null) ? tariffaSecondaria : tariffaAttiva
        def tariffaCodice = tariffa?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.occupazione

        Boolean changed = canoneUnicoService.verificaDimensioni(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    @Command
    def onChangeOccProfondita() {

        def tariffa = (tariffaSecondaria != null) ? tariffaSecondaria : tariffaAttiva
        def tariffaCodice = tariffa?.categoria?.codiceTributo?.id ?: 0

        def dati = concessione.occupazione

        Boolean changed = canoneUnicoService.verificaDimensioni(dati)
        ricalcolaConsistenza(tariffaCodice, dati, changed)
    }

    /// ############################################################################################################################
    ///	Pulsanti
    /// ############################################################################################################################

    @Command
    def onSelezionaOggetto() {

        Window w = Executions.createComponents("/archivio/listaOggettiRicerca.zul", self,
                [filtri: null, listaVisibile: true, inPratica: true, ricercaContribuente: false, tipo: parametriBandBox.tipoTributo])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Oggetto") {

                    canoneUnicoService.impostaOggetto(concessione, event.data.idOggetto)
                    onRefresh()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onDettagliOggetto() {

        Window w = Executions.createComponents("/archivio/oggetto.zul", self, [oggetto: concessione.oggettoRef])
        w.onClose { event ->
            if (event.data) {
                if (event.data.salvato) {

                    canoneUnicoService.impostaOggetto(concessione, concessione.oggettoRef)
                    aggiornaStato = true
                    onRefresh()
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAcquisisciGeolocalizzazioneDa() {

        Window w = Executions.createComponents("/archivio/datiGeolocalizzazioneOggetto.zul", self, [lettura : lettura ])
        w.onClose { event ->
            if (event.data) {
                def report = event.data.geolocalizzazione
                if(report.result == 0) {
                    acquisisciGeolocalizzazione(report, false)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAcquisisciGeolocalizzazioneA() {

        Window w = Executions.createComponents("/archivio/datiGeolocalizzazioneOggetto.zul", self, [lettura : lettura ])
        w.onClose { event ->
            if (event.data) {
                def report = event.data.geolocalizzazione
                if(report.result == 0) {
                    acquisisciGeolocalizzazione(report, true)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onGeolocalizzaOggettoDa() {

        String url = canoneUnicoService.getGoogleMapshUrl(concessione, false)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onGeolocalizzaOggettoA() {

        String url = canoneUnicoService.getGoogleMapshUrl(concessione, true)
        Clients.evalJavaScript("window.open('${url}','_blank');")
    }

    @Command
    def onChiudiConcessione() {

        def report = canoneUnicoService.concessioneChiudibile(concessione)

        if (report.result == 0) {

            def dataDecorrenza = concessione.dettagli.dataDecorrenza
            def dataChiusura = canoneUnicoService.getChiusuraAnno(-1).getTime()

            if (dataChiusura <= dataDecorrenza) {
                dataChiusura = canoneUnicoService.getDataOdierna()
            }

            Short annoSubentro = Calendar.getInstance().get(Calendar.YEAR)
            boolean trasferisci = false

            if (parametriBandBox.tipoTributo == "CUNI") {

                report = canoneUnicoService.verificaSubentro(annoSubentro, concessione)

                if (report.result != 0) {

                    Clients.showNotification("${report.message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                } else {
                    trasferisci = true
                }
            } else {
                annoSubentro = ((concessione.anno > 2020) ? concessione.anno : 2020) as Short
            }

            Window w = Executions.createComponents("/ufficiotributi/canoneunico/chiudiConcessioneCU.zul", self,
                    [
                            anno          : annoSubentro,
                            dataDecorrenza: dataDecorrenza,
                            dataChiusura  : dataChiusura,
                            trasferisci   : trasferisci,
                            listaCanoni   : null
                    ]
            )
            w.onClose { event ->
                if (event.data) {
                    if (event.data.datiChiusura) {
                        chiudiConcessione(event.data.datiChiusura)
                    }
                }
            }
            w.doModal()
        } else {

            visualizzaReport(report, "")
        }
    }

    @Command
    def onConvertiConcessione() {

        def annoTributo = Calendar.getInstance().get(Calendar.YEAR)

        def report

        if (concessione.dettagli.dataCessazione == null) {

            report = canoneUnicoService.concessioneChiudibile(concessione)

            if (report.result == 0) {

                def dataDecorrenza = concessione.dettagli.dataDecorrenza
                def dataChiusura = canoneUnicoService.getChiusuraAnno(-1).getTime()

                Window w = Executions.createComponents("/ufficiotributi/canoneunico/chiudiConcessioneCU.zul", self,
                        [anno: null, dataDecorrenza: dataDecorrenza, dataChiusura: dataChiusura])
                w.onClose { event ->
                    if (event.data) {
                        if (event.data.datiChiusura) {
                            chiudiEConvertiConcessione(event.data.datiChiusura)
                        }
                    }
                }
                w.doModal()

                return
            }
        } else {
            report = canoneUnicoService.concessioneConvertibile(concessione, annoTributo)
        }

        if (report.result == 0) {

            String messaggio = "Convertire la concessione a Canone Unico per l'anno ${annoTributo}?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                convertiConcessione()
                            }
                        }
                    }
            )
        } else {

            visualizzaReport(report, "")
        }

    }

    @Command
    def onDuplicaConcessione() {

        def annoTributo = Calendar.getInstance().get(Calendar.YEAR)

        def report = canoneUnicoService.concessioneDuplicabile(concessione, annoTributo)

        if (report.result == 0) {

            String messaggio = "Duplicare il canone per l'anno ${annoTributo}?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                duplicaConcessione()
                            }
                        }
                    }
            )
        } else {

            visualizzaReport(report, "")
        }

    }

    @Command
    def onEliminaConcessione() {

        def report = canoneUnicoService.concessioneEliminabile(concessione)

        if (report.result == 0) {

            String messaggio = "Eliminare la concessione?"

            Messagebox.show(messaggio, "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                if (eliminaConcessione()) {
                                    onChiudi()
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

        def report = canoneUnicoService.verificaCodiciTributo(parametriBandBox.tipoTributo, listaCodici)
        if (report.result != 0) {
            visualizzaReport(report, "")
            return
        }

        if (!completaConcessione()) return
        if (!verificaConcessione()) return

        report = canoneUnicoService.salvaConcessione(concessione)

        visualizzaReport(report, "Concessione salvata con successo !")

        onRefresh()

        aggiornaStato = true
    }

    @Command
    def onRefresh() {

        BindUtils.postNotifyChange(null, null, this, "concessione")

        listaAnni = canoneUnicoService.getElencoAnni()

        parametriBandBox.annoTributo = concessione.anno.toString()

        if (concessione.anno >= 2021) {

            parametriBandBox.tipoTributo = "CUNI"
        } else {
            parametriBandBox.tipoTributo = concessione.tipoTributo
        }

        if (listaAnni.find { it == parametriBandBox.annoTributo } == null) {
            listaAnni << parametriBandBox.annoTributo
        }

        BindUtils.postNotifyChange(null, null, this, "listaAnni")
        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")

        predisponiInterfaccia()

        ricaricaTabelleVieZone()

        aggiornaZonaDaIndirizzo()

        ricaricaTariffario()

        aggiornaGiornateTariffa()

        aggiornaCalcolabile()

        aggiornaDataModifica();

        aggiornaUtente()
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato])
    }

    /// ############################################################################################################################
    ///	Punzioni interne
    /// ############################################################################################################################

    ///
    /// *** Elimina la consessione
    ///
    def eliminaConcessione() {

        def report = canoneUnicoService.eliminaConcessione(concessione)

        visualizzaReport(report, "Canone eliminato con successo !")

        if (report.result == 0) {

            aggiornaStato = true
            return true
        } else {

            return false
        }
    }

    ///
    /// *** Chiude la concessione creando evento "C", quindi lanica procedura di conversione
    ///
    def chiudiEConvertiConcessione(def datiChiusura) {

        Short annoChiusura = datiChiusura.anno
        Date dataChiusura = datiChiusura.dataChiusura
        Date fineOccupazione = datiChiusura.dataFineOccupazione

        def report = canoneUnicoService.chiudiConcessione(concessione, dataChiusura, fineOccupazione, annoChiusura)

        if (report.result == 0) {

            concessione = report.concessione

            Short annoTributo = (annoChiusura) ? (annoChiusura + 1) : Calendar.getInstance().get(Calendar.YEAR)
            report = canoneUnicoService.convertiConcessione(concessione, annoTributo)

            if (report.result == 0) {

                concessione = report.concessione
            }

            onRefresh()
        }

        visualizzaReport(report, "Canone convertito con successo !")

        self.invalidate()

        aggiornaStato = true

        if (report.result == 0) {

            return true
        }

        return false
    }

    ///
    /// *** Chiude la concessione creando evento "C"
    ///
    def chiudiConcessione(def datiChiusura) {

        String successMessage = "Canone chiuso con successo !"

        Date dataChiusura = datiChiusura.dataChiusura
        Date fineOccupazione = datiChiusura.dataFineOccupazione

        def report = canoneUnicoService.chiudiConcessione(concessione, dataChiusura, fineOccupazione)

        if (report.result == 0) {

            concessione = report.concessione
            onRefresh()

            if (datiChiusura.soggDestinazione) {

                def dettagliSubentro = [
                        soggSubentro         : datiChiusura.soggDestinazione,
                        dataInizioOccupazione: datiChiusura.dataInizioOccupazione,
                        dataDecorrenza       : datiChiusura.dataDecorrenza,
                        praticaRef           : 0,
                ]

                report = canoneUnicoService.subentroConcessione(concessione, dettagliSubentro);

                successMessage = "Subentro canone avvenuto con successo !"
            }
        }

        visualizzaReport(report, successMessage)

        aggiornaStato = true

        if (report.result == 0) {

            return true
        }

        return false
    }

    ///
    /// *** Converte la concessione a Canone Unico
    ///
    def convertiConcessione() {

        def annoTributo = Calendar.getInstance().get(Calendar.YEAR)

        def report = canoneUnicoService.convertiConcessione(concessione, annoTributo)

        if (report.result == 0) {

            concessione = report.concessione
            onRefresh()
        }

        visualizzaReport(report, "Canone convertito con successo !")

        self.invalidate()

        if (report.result == 0) {

            return true
        }

        return false
    }

    ///
    /// *** Duplica la concessione
    ///
    def duplicaConcessione() {

        def annoTributo = Calendar.getInstance().get(Calendar.YEAR)

        def report = canoneUnicoService.duplicaConcessione(concessione, annoTributo)

        if (report.result == 0) {

            concessione = report.concessione
            onRefresh()
        }

        visualizzaReport(report, "Canone duplicato con successo !")

        self.invalidate()

        if (report.result == 0) {

            return true
        }

        return false
    }

    ///
    /// *** Completa la concessione prima di salvare
    ///
    def completaConcessione() {

        boolean result = true

        def dettagli = concessione.dettagli

        concessione.tipoTributo = parametriBandBox.tipoTributo

        dettagli.codFisDen = parametriBandBox.soggDenunciante.codFiscale
        dettagli.tipoCarica = parametriBandBox.caricaDenunciante?.id

        String denominazioneComune

        denominazioneComune = parametriBandBox.comuneDenunciante?.denominazione
        if ((denominazioneComune != null) && (denominazioneComune.size() == 0)) denominazioneComune = null

        if (denominazioneComune == null) {
            onSelectComuneDen(null)
        }

        concessione.oggetto.tipoOggetto = parametriBandBox?.tipoOggetto?.tipoOggetto

        denominazioneComune = parametriBandBox.comuneOggetto?.denominazione
        if ((denominazioneComune != null) && (denominazioneComune.size() == 0)) denominazioneComune = null

        if (denominazioneComune == null) {
            onSelectComuneOggetto(null)
        }

        completaIndirizzoOggetto()

        aggiornaTariffa()

        concessione.codiceTributo = null
        concessione.categoria = null
        concessione.tariffa = null

        dettagli.tipoOccupazione = parametriBandBox.tariffaOccupazione?.codice

        concessione.codiceTributoSec = null
        concessione.categoriaSec = null
        concessione.tariffaSec = null

        if (concessione.tipoTributo != "CUNI") {

            concessione.codiceTributo = parametriBandBox.tariffaCodice?.id
            concessione.categoria = parametriBandBox.tariffaCategoria?.categoria
            concessione.tariffa = parametriBandBox.tariffaTariffa?.tipoTariffa
        }
        else {
            if (tariffaAttiva != null) {

                concessione.codiceTributo = tariffaAttiva.categoria.codiceTributo.id
                concessione.categoria = tariffaAttiva.categoria.categoria
                concessione.tariffa = tariffaAttiva.tipoTariffa
            }
            if (tariffaSecondaria != null) {

                concessione.codiceTributoSec = tariffaSecondaria.categoria.codiceTributo.id
                concessione.categoriaSec = tariffaSecondaria.categoria.categoria
                concessione.tariffaSec = tariffaSecondaria.tipoTariffa
            }
        }

        return result
    }

    ///
    /// *** Completa la concessione prima di salvare
    ///
    def completaIndirizzoOggetto() {

        String indirizzoOggetto = parametriBandBox.indirizzoOggetto
        if ((indirizzoOggetto != null) && (indirizzoOggetto.size() == 0)) indirizzoOggetto = null

        ArchivioVieDTO selectedVia = null

        ///
        /// *** Se esiste codice ricava da esso e confronta, se diversi azzera ed uno testo isnerito
        ///
        if ((parametriBandBox.codiceViaOggetto ?: 0) != 0) {
            selectedVia = ArchivioVie.findById(parametriBandBox.codiceViaOggetto)?.toDTO()
            if (selectedVia.denomUff != indirizzoOggetto) {
                selectedVia = null
            }
        }
        if (selectedVia == null) {
            selectedVia = ArchivioVie.findByDenomUffIlike(indirizzoOggetto)?.toDTO()
        }

        if (selectedVia != null) {

            concessione.oggetto.codVia = selectedVia.id
            concessione.oggetto.nomeVia = null
        } else {

            concessione.oggetto.codVia = null
            concessione.oggetto.nomeVia = indirizzoOggetto
        }
    }

    ///
    /// *** Verifica preliminare della concessione
    ///
    def verificaConcessione() {

        String message = ""
        boolean result = true

        def report = canoneUnicoService.verificaConcessione(concessione)
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

    ///
    /// *** Ricarica elenco tipi oggetto per tipo tributo
    ///
    def ricaricaTipiOggetto(boolean select) {

        listaTipiOggetto = canoneUnicoService.getTipiOggetto(parametriBandBox.tipoTributo)

        if (select) {

            def tipoOggetto = concessione.oggetto.tipoOggetto
            parametriBandBox.tipoOggetto = listaTipiOggetto.find { it.tipoOggetto == tipoOggetto }
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }
        BindUtils.postNotifyChange(null, null, this, "listaTipiOggetto")
    }

    ///
    /// *** Ricarica combo tipo occupazione
    ///
    def ricaricaTipiOccupazione(boolean select) {

        boolean permanente
        boolean temporanea

        listTipiOccupazione = []

        if (parametriBandBox.tipoTributo == "CUNI") {

            def descrizioneTariffa = parametriBandBox.tariffaTariffa?.descrizione ?: "-"
            def listaTariffeFull = ricavaListaTariffeFull(descrizioneTariffa)

            permanente = false
            temporanea = false

            listaTariffeFull.each {

                if (it.tipologiaTariffa == TariffaDTO.TAR_TIPOLOGIA_PERMANENTE) permanente = true
                if (it.tipologiaTariffa == TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA) temporanea = true
            }
        } else {
            permanente = true
            temporanea = true
        }

        if (praticaRiferimento != null) {
            switch (praticaRiferimento.tipoEvento.tipoEventoDenuncia) {
                default:
                    break
                case TipoEventoDenuncia.U.tipoEventoDenuncia:
                    permanente = false
                    break
                case [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]:
                    temporanea = false
                    break
            }
        }

        if (permanente != false) {
            String codice = TipoOccupazione.P.tipoOccupazione
            String descrizione = TipoOccupazione.P.descrizione
            listTipiOccupazione << [codice: codice, descrizione: descrizione, tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE]
        }
        if (temporanea != false) {
            String codice = TipoOccupazione.T.tipoOccupazione
            String descrizione = TipoOccupazione.T.descrizione
            listTipiOccupazione << [codice: codice, descrizione: descrizione, tipologiaTariffa: TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA]
        }

        if (select) {

            def tariffaOccupazione = concessione.dettagli.tipoOccupazione
            parametriBandBox.tariffaOccupazione = listTipiOccupazione.find { it?.codice == tariffaOccupazione }
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listTipiOccupazione")
    }

    ///
    /// *** Ricarica combo codici tributo
    ///
    def ricaricaCodiciTributo(boolean select) {

        def annoTributo = parametriBandBox.annoTributo as Integer

        listaCodici = canoneUnicoService.getCodiciTributo(parametriBandBox.tipoTributo, annoTributo)

        def report = canoneUnicoService.verificaCodiciTributo(parametriBandBox.tipoTributo, listaCodici)

        def filtroTariffe = null

        if ((praticaRiferimento != null) && (parametriBandBox.tipoTributo == 'CUNI')) {
            switch (praticaRiferimento.tipoEvento.tipoEventoDenuncia) {
                default:
                    break
                case TipoEventoDenuncia.U.tipoEventoDenuncia:
                    filtroTariffe = [ TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA, TariffaDTO.TAR_TIPOLOGIA_ESENZIONE ]
                    break
                case [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]:
                    filtroTariffe = [ TariffaDTO.TAR_TIPOLOGIA_PERMANENTE, TariffaDTO.TAR_TIPOLOGIA_ESENZIONE ]
                    break
            }
        }

        elencoCategorie = canoneUnicoService.getCategorie(listaCodici)
        elencoTariffe = canoneUnicoService.getTariffe(listaCodici, annoTributo, null, filtroTariffe)

        if (select) {

            def tariffaCodice = concessione.codiceTributo ?: 0
            parametriBandBox.tariffaCodice = listaCodici.find { it.id == tariffaCodice }
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listaCodici")

        visualizzaReport(report, "")
    }

    ///
    /// *** Ricarica combo categorie - Casi ICP e xOSAP
    ///
    def ricaricaCategorie(boolean select) {

        def codiceTributo = parametriBandBox.tariffaCodice?.id ?: 0

        listaCategorie = elencoCategorie.findAll { it.codiceTributo?.id == codiceTributo }

        if (select) {

            def codiceCategoria = concessione.categoria ?: 0
            CategoriaDTO categoria = listaCategorie.find { it.categoria == codiceCategoria }
            parametriBandBox.tariffaCategoria = categoria
            parametriBandBox.descrizioneCategoria = categoria?.descrizione
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    ///
    /// *** Ricarica combo tariffe - Casi ICP e xOSAP
    ///
    def ricaricaTariffe(boolean select) {

        def codiceTributo = parametriBandBox.tariffaCodice?.id ?: 0
        def categoria = parametriBandBox.tariffaCategoria?.id ?: 0

        listaTariffe = elencoTariffe.findAll { it.categoria?.id == categoria && it.categoria?.codiceTributo?.id == codiceTributo }

        if (select) {

            def tariffa = concessione.tariffa ?: 0
            parametriBandBox.tariffaTariffa = listaTariffe.find { it.tipoTariffa == tariffa }
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
    }

    ///
    /// *** Ricarica combo categorie - Casi CU (diventa Zona)
    ///
    def ricaricaCategorieCU(boolean select) {

        def descrizioneTariffa = parametriBandBox.tariffaTariffa?.descrizione ?: "-"
        def listaTariffeFull = ricavaListaTariffeFull(descrizioneTariffa)
        def tipologiaTariffa = parametriBandBox.tariffaOccupazione?.tipologiaTariffa ?: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE

        def codiciTributo = []
        def categorie = []

        listaTariffeFull.each {
            if (it.tipologiaTariffa == tipologiaTariffa) {
                if (it.categoria != null) {
                    categorie << it.categoria.categoria
                    if (it.categoria.codiceTributo != null) {
                        codiciTributo << it.categoria.codiceTributo.id
                    }
                }
            }
        }

        def listaCategorieFull = elencoCategorie.findAll {
            it.codiceTributo?.id in codiciTributo && it.categoria in categorie
        }

        listaCategorie = []

        listaCategorieFull.each {

            def descrizione = it.descrizione
            def inList = listaCategorie.find { it.descrizione == descrizione }
            if (inList == null) {
                listaCategorie << it
            }
        }
        listaCategorie.sort { it.descrizione }

        if (select) {

            def codiceCategoria = concessione.categoria ?: 0
            CategoriaDTO categoria = listaCategorie.find { it.categoria == codiceCategoria }
            if (categoria == null) {
                categoria = listaCategorie.find { it.descrizione == parametriBandBox.descrizioneCategoria }
            }
            parametriBandBox.tariffaCategoria = categoria
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listaCategorie")
    }

    ///
    /// *** Ricarica combo tariffe - Caso CU
    ///
    def ricaricaTariffeCU(boolean select) {

        def listaTariffeFull = ricavaListaTariffeFull()

        listaTariffe = []

        listaTariffeFull.each {

            def descrizione = it.descrizione
            def inList = listaTariffe.find { it.descrizione == descrizione }
            if (inList == null) {
                listaTariffe << it
            }
        }
        listaTariffe.sort { it.descrizione }

        if (select) {

            def codiceTributo = concessione.codiceTributo ?: 0
            def tariffa = concessione.tariffa ?: 0
            parametriBandBox.tariffaTariffa = listaTariffe.find { it.tipoTariffa == tariffa && it.categoria.codiceTributo.id == codiceTributo }
            BindUtils.postNotifyChange(null, null, this, "parametriBandBox")
        }

        BindUtils.postNotifyChange(null, null, this, "listaTariffe")
    }

    ///
    /// *** Ricava elenco tariffe completo per codici
    ///
    def ricavaListaTariffeFull(String descrizioneTariffa) {

        def codiciTributo = []

        listaCodici.each {
            codiciTributo << it.id
        }
        def listaTariffeFull = elencoTariffe.findAll {
            it.categoria?.codiceTributo != null && it.categoria?.codiceTributo?.id in codiciTributo
        }
        if (descrizioneTariffa != null) {
            listaTariffeFull = listaTariffeFull.findAll { it.descrizione == descrizioneTariffa }
        }

        return listaTariffeFull
    }

    ///
    /// *** Ricarica dati correlazione vie/zona
    ///
    def ricaricaTabelleVieZone() {

        def annoTributo = parametriBandBox.annoTributo as Integer

        listaAssociazioniVie = canoneUnicoService.getAssociazioniVieZona([anno: annoTributo])
        listaZone = canoneUnicoService.getElencoZone([anno: annoTributo])
    }

    ///
    /// *** Ricarica le liste del tariffario
    ///
    def ricaricaTariffario() {

        if (parametriBandBox.tipoTributo == "CUNI") {

            ricaricaTipiOggetto(true)

            ricaricaCodiciTributo(false)
            ricaricaTariffeCU(true)
            ricaricaTipiOccupazione(true)
            ricaricaCategorieCU(true)

            aggiornaTariffa()
            aggiornaQuadri()
        } else {

            ricaricaTipiOggetto(true)

            ricaricaCodiciTributo(true)
            ricaricaTipiOccupazione(true)
            ricaricaCategorie(true)
            ricaricaTariffe(true)

            aggiornaQuadri()
        }
    }

    ///
    /// *** Aggiornamento selezione finale tariffa e validazione
    ///
    def aggiornaTariffa() {

        if (parametriBandBox.tipoTributo != "CUNI") {

            tariffaAttiva = parametriBandBox.tariffaTariffa
            tariffaSecondaria = null
            return
        }

        tariffaAttiva = null
        tariffaSecondaria = null

        def descrizioneTariffa = parametriBandBox.tariffaTariffa?.descrizione ?: "-"
        def listaTariffeFull = ricavaListaTariffeFull(descrizioneTariffa)
        def tipologiaTariffa = parametriBandBox.tariffaOccupazione?.tipologiaTariffa ?: -1
        def tariffaCategoria = parametriBandBox.tariffaCategoria

        def categoria = tariffaCategoria?.categoria ?: -1
        def codiceTributo = tariffaCategoria?.codiceTributo?.id ?: -1

        TariffaDTO tariffa = null
        List<TariffaDTO> tariffe = listaTariffeFull.findAll {
            (it.tipologiaTariffa == tipologiaTariffa) && (it.categoria?.categoria == categoria) &&
                    (it.categoria?.codiceTributo?.id == codiceTributo)
        }

        int tariffeNum = tariffe.size()
        if (tariffeNum > 0) tariffa = tariffe[0]

        String descrizione = ""

        switch (tariffeNum) {
            default:
                descrizione = "Piu' di una tariffa soddisfa i criteri impostati !!"
                break
            case 1:
                descrizione = canoneUnicoService.descriviTariffa(tariffa)
                tariffaAttiva = tariffa
                break
            case 0:
                descrizione = "Nessuna tariffa soddisfa i criteri impostati !"
                break
        }

        if ((tariffaAttiva != null) && (tariffaAttiva.tipologiaSecondaria == TariffaDTO.TAR_SECONDARIA_USOSUOLO)) {

            def codiceUsoSuolo = listaCodici.find {
                (it.tipoTributo.tipoTributo == 'TOSAP') ||
                        ((it.tipoTributo.tipoTributo == 'CUNI') && (it.tipoTributoPrec?.tipoTributo == 'TOSAP'))
            }

            def tariffeFull = ricavaListaTariffeFull()

            tariffe = tariffeFull.findAll {
                (it.tipoTariffa == 99) && (it.categoria.categoria == 99) && (it.categoria.codiceTributo?.id == codiceUsoSuolo.id)
            }

            tariffeNum = tariffe.size()

            if (tariffeNum == 1) {
                tariffaSecondaria = tariffe[0]
            } else {
                descrizione = "Errore configurazione tariffa in esenzione - Trovate ${tariffeNum} !"
            }
        }

        parametriBandBox.descrizioneTariffa = descrizione
        BindUtils.postNotifyChange(null, null, this, "parametriBandBox")

        aggiornaGiornateTariffa()

        aggiornaCalcolabile()

    }

    ///
    /// *** Aggiornamento giornate di validità della tariffa
    ///
    def aggiornaGiornateTariffa() {

        def codice = parametriBandBox.tariffaOccupazione?.codice

        if (codice == 'T') {
            giornateTariffa = canoneUnicoService.getGiornateConcessione(concessione)
        } else {
            giornateTariffa = null
        }

        BindUtils.postNotifyChange(null, null, this, "giornateTariffa")
    }

    ///
    /// Predispone interfaccia dopo assegnazione concessione
    ///
    def aggiornaZonaDaIndirizzo() {

        String zonaRilevata = "-"

        completaIndirizzoOggetto()

        if (concessione.oggetto.codVia != null) {

            def zonaDaVia = canoneUnicoService.determinaZonaOggetto(listaAssociazioniVie, concessione.oggetto)
            def codiceZona = zonaDaVia.codiceZona
            def sequenzaZona = zonaDaVia.sequenzaZona

            def zona = listaZone.find { (it.codZona == codiceZona) && (it.sequenza == sequenzaZona) }
            if (zona != null) {
                zonaRilevata = zona.denominazione
            } else {
                zonaRilevata = "-"
            }
        }

        parametriBandBox.zonaRilevata = zonaRilevata

        if (parametriBandBox.zonaRilevata.size() > 1) {
            if (parametriBandBox.tipoTributo == "CUNI") {
                parametriBandBox.descrizioneCategoria = parametriBandBox.zonaRilevata
            }
        }

    }

    ///
    /// *** Ricalcola consistenza su cambio tariffario
    ///
    def ricalcolaConsistenzaCambioTariffa() {

        def tariffaCodice
        def dati

        tariffaCodice = tariffaAttiva?.categoria?.codiceTributo?.id ?: 0
        dati = concessione.pubblicita
        ricalcolaConsistenza(tariffaCodice, dati, false)

        tariffaCodice = 0
        dati = concessione.occupazione
        ricalcolaConsistenza(tariffaCodice, dati, false)
    }

    ///
    /// *** Ricalcola consistenza
    ///
    def ricalcolaConsistenza(def codiceTributo, def dati, boolean changed) {

        if (canoneUnicoService.ricalcolaConsistenza(parametriBandBox.tipoTributo, codiceTributo, dati) != false) {
            changed = true
        }

        if (changed) {
            BindUtils.postNotifyChange(null, null, this, "concessione")
        }
    }

    ///
    /// Acquisisce Geolocalizzazione, aggiorna Oggetto e rinfrescha la maschera
    ///
    private acquisisciGeolocalizzazione(def geoloc, Boolean aLonLat = false) {

        if(aLonLat) {
            concessione.oggetto.aLatitudine = geoloc.latitudine
            concessione.oggetto.aLongitudine = geoloc.longitudine
        }
        else {
            concessione.oggetto.latitudine = geoloc.latitudine
            concessione.oggetto.longitudine = geoloc.longitudine
        }

        if(concessione.oggettoRef) {
            canoneUnicoService.aggiornaGeolocalizzazioneOggetto(concessione, aLonLat)
            aggiornaStato = true
            onRefresh()
        }
        else {
            canoneUnicoService.formatCoordinates(concessione, aLonLat)
            BindUtils.postNotifyChange(null, null, this, "concessione")
        }
    }

    ///
    /// Predispone interfaccia dopo assegnazione concessione
    ///
    def predisponiInterfaccia() {

        def oggetto = concessione.oggetto;

        if ((oggetto.codVia ?: 0) != 0) {

            ArchivioVie viaArchivio = ArchivioVie.findById(oggetto.codVia)
            parametriBandBox.indirizzoOggetto = (viaArchivio != null) ? viaArchivio.denomUff : null
        } else {
            parametriBandBox.indirizzoOggetto = oggetto.nomeVia
        }

        parametriBandBox.comuneOggetto.denominazione = oggetto.denCom
        parametriBandBox.comuneOggetto.provincia = oggetto.denPro
        parametriBandBox.comuneOggetto.siglaProv = oggetto.sigPro

        def dettagli = concessione.dettagli;

        parametriBandBox.soggDenunciante.codFiscale = dettagli.codFisDen

        parametriBandBox.comuneDenunciante.denominazione = dettagli.denComDen
        parametriBandBox.comuneDenunciante.provincia = dettagli.denProDen
        parametriBandBox.comuneDenunciante.siglaProv = dettagli.sigProDen

        def tipoCaricaNum = dettagli.tipoCarica ?: 0
        parametriBandBox.caricaDenunciante = listaCariche.find { it.id == tipoCaricaNum }

        def modificaAbilitata = !lettura

        eliminabile = false
        modificabile = false
        convertibile = false
        chiudibile = false
        duplicabile = false
        selezioneOggetto = false

        if (((concessione.praticaPub ?: 0) > 0) || ((concessione.praticaOcc ?: 0) > 0)) {

            if (concessione.anno >= 2021) {

                eliminabile = modificaAbilitata
                if (concessione.dettagli.dataCessazione == null) {
                    modificabile = modificaAbilitata
                } else {
                    modificabile = modificaAbilitata
                    duplicabile = modificaAbilitata
                }
            } else {
                convertibile = modificaAbilitata
            }

            if (concessione.tipoEvento in [TipoEventoDenuncia.I.tipoEventoDenuncia, TipoEventoDenuncia.V.tipoEventoDenuncia]) {
                if (concessione.dettagli.dataCessazione == null) {
                    chiudibile = modificaAbilitata
                } else {
                    modificabile = false
                    duplicabile = modificaAbilitata
                }
            }
        } else {
            modificabile = modificaAbilitata
            selezioneOggetto = modificabile
        }

        if (concessione.oggettoRef != 0) {
            modificaEstremi = false
        } else {
            modificaEstremi = modificabile
        }

        if (praticaRiferimento) {
            modificaFrontespizio = false
            duplicabile = false
            convertibile = false
            chiudibile = false
        } else {
            modificaFrontespizio = modificabile
        }

        BindUtils.postNotifyChange(null, null, this, "eliminabile")
        BindUtils.postNotifyChange(null, null, this, "convertibile")
        BindUtils.postNotifyChange(null, null, this, "duplicabile")
        BindUtils.postNotifyChange(null, null, this, "chiudibile")
        BindUtils.postNotifyChange(null, null, this, "modificabile")
        BindUtils.postNotifyChange(null, null, this, "modificaFrontespizio")
        BindUtils.postNotifyChange(null, null, this, "modificaEstremi")
        BindUtils.postNotifyChange(null, null, this, "selezioneOggetto")
    }

    ///
    /// Aggiorna l'attributo calcolabile
    ///
    def aggiornaCalcolabile() {

        calcolabile = false

        if ((concessione.oggettoRef != 0) &&
                ((concessione.oggettoPraticaPub != 0) || (concessione.oggettoPraticaOcc != 0))) {

            if (concessione.dettagli.tipoOccupazione == TipoOccupazione.T.id) {

                calcolabile = true
            }
        }

        BindUtils.postNotifyChange(null, null, this, "calcolabile")

    }

    ///
    /// *** Aggiorna situazione dei quadri di dettaglio
    ///
    def aggiornaQuadri() {

        quadroPubblicita = false
        quadroOccupazione = false

        if (parametriBandBox.tipoTributo == "CUNI") {

            if (tariffaAttiva != null) {

                def tariffaCodice = tariffaAttiva.categoria?.codiceTributo?.id ?: 0
                CodiceTributoDTO codiceTributo = listaCodici.find { it.id == tariffaCodice }

                if (codiceTributo != null) {
                    String codiceTributoTxt = (codiceTributo.tipoTributoPrec != null) ? codiceTributo.tipoTributoPrec.tipoTributo : codiceTributo.tipoTributo.tipoTributo
                    if (codiceTributoTxt == 'ICP') {
                        quadroPubblicita = true
                        if (tariffaAttiva.tipologiaSecondaria == TariffaDTO.TAR_SECONDARIA_USOSUOLO) {
                            quadroOccupazione = true
                        }
                    } else {
                        quadroOccupazione = true
                    }
                }
            }
        } else {
            if (parametriBandBox.tipoTributo == "ICP") {
                quadroPubblicita = true
            } else {
                quadroOccupazione = true
            }
        }
        if (!quadroDenunciante) {
            if ((concessione.dettagli.denunciante ?: "").size() > 0) {
                quadroDenunciante = true
            }
        }

        BindUtils.postNotifyChange(null, null, this, "quadroDenunciante")
        BindUtils.postNotifyChange(null, null, this, "quadroPubblicita")
        BindUtils.postNotifyChange(null, null, this, "quadroOccupazione")
    }

    ///
    /// *** Aggiorna data ultima variazione
    ///
    private
    def aggiornaDataModifica() {

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        def date = concessione.lastUpdatedOggetto
        lastUpdated = (date) ? sdf.format(date) : ''
        BindUtils.postNotifyChange(null, null, this, "lastUpdated")
    }

    private def aggiornaUtente() {
        utente = concessione?.utentePratica
        BindUtils.postNotifyChange(null, null, this, "utente")
    }

    ///
    /// *** Visualizza report
    ///
    def visualizzaReport(def report, String messageOnSuccess) {

        switch (report.result) {
            case 0:
                if ((messageOnSuccess ?: '').size() > 0) {
                    String message = messageOnSuccess
                    Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
                break
            case 1:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
                break
            case 2:
                String message = report.message
                Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
                break
        }

    }
}
