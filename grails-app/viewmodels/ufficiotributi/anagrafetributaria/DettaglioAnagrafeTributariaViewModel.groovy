package ufficiotributi.anagrafetributaria

import document.FileNameGenerator
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.Anadev
import it.finmatica.tr4.Anadce
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.datiesterni.anagrafetributaria.AnagrafeTributariaService
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class DettaglioAnagrafeTributariaViewModel {

    Window self

    AnagrafeTributariaService anagrafeTributariaService
    DatiGeneraliService datiGeneraliService

    SoggettoDTO soggetto
    ContribuenteDTO contribuente
    String codFiscale
    Boolean personaFisica

    def listaRisposte = []
    def rispostaSelected = null
    def listaPartiteIVA = []
    def partiteIVASelected = null
    def numPartiteIVA = 0
    def listaDitte = []
    def dittaSelected = null
    def numDitte = 0
    def listaRappresentanti = []
    def rappresentanteSelected = null
    def numRappresentanti = 0

    def selectedTab
    String tabSelezionata = "partiteIva"

    Boolean aggiornato = false
    boolean modificaStatoExtraGSD = false

    def soggettoConfronto
    def soggettoTemp
    def abilitaModifica = false
    def integrazioneGDS = false
    def dataDomicilioRisposta

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("soggetto") def sg) {

        this.self = w

        soggetto = sg
        contribuente = soggetto.contribuente
        codFiscale = contribuente.codFiscale

        personaFisica = ((soggetto.tipo == '0') || ((soggetto.tipo == '2') && (codFiscale.length() == 16)))

        caricaDatiSoggetto()

        if(soggetto.gsd) {

            def listaDceExtraGSD = Anadce.createCriteria().list {
                eq('tipoEvento', 'C')
                'in'("anagrafe", ['RES', 'AIR'])
            }?.toDTO()
            def elencoDceExtraGSD = listaDceExtraGSD.collect { it.id }

            modificaStatoExtraGSD = false

            if(soggetto.stato?.id in elencoDceExtraGSD) {
                /// Soggetto GSD ma con uno stato di cessata anagrafe interna
                if(soggettoConfronto.dataDecesso == null) {
                    /// Modifica consentita solo se non già deceduto
                    modificaStatoExtraGSD = true
                }
            }
        }
        else {
            modificaStatoExtraGSD = true
        }

        listaRisposte = anagrafeTributariaService.getListaRisposte(codFiscale)
        if (!listaRisposte.empty) {
            rispostaSelected = listaRisposte[0]

            //Dati per il confronto tra l'indirizzo completo della risposta e i singoli campi indirizzo-civico-suffisso del soggetto
            listaRisposte.each {
                // Controlla la presenza di anomalie tra indirizzo, civico e suffisso
                it.anomalieIndirizzo = controllaAnomalieIndirizzo(it.indirizzoDomicilio)
            }
        } else {
            rispostaSelected = null
        }

        integrazioneGDS = datiGeneraliService.integrazioneGSDAbilitata()
        abilitaModifica = !integrazioneGDS

        refreshPannello()
    }

    @Command
    def onRispostaSelected() {

        refreshPannello()
    }

    @Command
    caricaTab(@BindingParam("folder") String tabId) {

        tabSelezionata = tabId
    }

    @Command
    def onVisualizzaSoggetto() {

        def ni = soggetto.id
        Clients.evalJavaScript("window.open('standalone.zul?sezione=SOGGETTO&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onRisposteToXls() {

        def fields = [:]

        if (personaFisica) {
            fields = [
                    'codFiscale'            : 'Ult. Cod.Fis.',

                    'cognome'               : 'Cognome',
                    'nome'                  : 'Nome',
                    'sesso'                 : 'Sesso',

                    'dataNascita'           : 'Data di Nascita',
                    'comuneNascita'         : 'Comune di Nascita',
                    'provinciaNascita'      : 'Prov. di Nascita',

                    'fonteDecessoDescr'     : 'Fonte Decesso',
                    'dataDecesso'           : 'Data Decesso',

                    'comuneDomicilio'       : 'Comune Domicilio',
                    'provinciaDomicilio'    : 'Prov. Domicilio',
                    'capDomicilio'          : 'C.A.P. Domicilio',
                    'indirizzoDomicilio'    : 'Indirizzo Domicilio',
                    'fonteDomicilioDescr'   : 'Fonte Domicilio',
                    'dataDomicilio'         : 'Data Domicilio',

                    'partitaIva'            : 'Partita IVA',
                    'statoPartitaIvaDescr'  : 'Stato Partita IVA',
                    'codAttivita'           : 'Cod. Attivita\'',
                    'tipologiaCodificaDescr': 'Tipologia Cod,',
                    'dataInizioAttivita'    : 'Data Inizio Attivita',
                    'dataFineAttivita'      : 'Data Fine Attivita',

                    'comuneSedeLegale'      : 'Comune Sede Leg.',
                    'provinciaSedeLegale'   : 'Provincia Sede Leg.',
                    'capSedeLegale'         : 'C.A.P. Sede Leg.',
                    'indirizzoSedeLegale'   : 'Indirizzo Sede Leg.',
                    'fonteSedeLegaleDescr'  : 'Fonte Sede Leg.',
                    'dataSedeLegale'        : 'Data Sede Leg.',

                    'codiceRitorno'         : 'Cod. Ritorno',
                    'codiceRitornoEsito'    : 'Esito',
                    'documentoId'           : 'Prog. Doc.'
            ]
        } else {
            fields = [
                    'codFiscale'            : 'Ult. Cod.Fis.',

                    'denominazione'         : 'Denominazione',

                    'presenzaEstinzione'    : 'Cod.Fis. Estinto',
                    'dataEstinzione'        : 'Data Estinzione',

                    'comuneDomicilio'       : 'Comune Domicilio',
                    'provinciaDomicilio'    : 'Prov. Domicilio',
                    'capDomicilio'          : 'C.A.P. Domicilio',
                    'indirizzoDomicilio'    : 'Indirizzo Domicilio',
                    'fonteDomicilioDescr'   : 'Fonte Domicilio',
                    'dataDomicilio'         : 'Data Domicilio',

                    'partitaIva'            : 'Partita IVA',
                    'statoPartitaIvaDescr'  : 'Stato Partita IVA',
                    'codAttivita'           : 'Cod. Attivita\'',
                    'tipologiaCodificaDescr': 'Tipologia Cod,',
                    'dataInizioAttivita'    : 'Data Inizio Attivita',
                    'dataFineAttivita'      : 'Data Fine Attivita',

                    'comuneSedeLegale'      : 'Comune Sede Leg.',
                    'provinciaSedeLegale'   : 'Provincia Sede Leg.',
                    'capSedeLegale'         : 'C.A.P. Sede Leg.',
                    'indirizzoSedeLegale'   : 'Indirizzo Sede Leg.',
                    'fonteSedeLegaleDescr'  : 'Fonte Sede Leg.',
                    'dataSedeLegale'        : 'Data Sede Leg.',

                    'codFiscaleRap'         : 'Cod Fiscale Rappr.',
                    'codiceCaricaDescr'     : 'Tipo carica Rappr.',
                    'dataDecorrenzaRap'     : 'Data Decorrenza Rappr.',

                    'codiceRitorno'         : 'Cod. Ritorno',
                    'codiceRitornoEsito'    : 'Esito',
                    'documentoId'           : 'Prog. Doc.',
            ]
        }

        def datiDaEsportare = []
        def datoDaEsportare

        listaRisposte.each {

            datoDaEsportare = it.clone()

            datoDaEsportare.presenzaEstinzione = datoDaEsportare.presenzaEstinzione ? 'S' : 'N'

            datiDaEsportare << datoDaEsportare
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.AT_RISPOSTE,
                [codFiscale: codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields)
    }

    @Command
    def onPartiteIVAToXls() {

        def fields = [:]

        fields = [
                'partitaIva'            : 'P. IVA',
                'codAttivita'           : 'Cod. Attivita\'',
                'tipologiaCodificaDescr': 'Tipologica Cod.',
                'statoDescr'            : 'Stato',
                'dataCessazione'        : 'Data Cess.',
                'partitaIvaConfluenza'  : 'P. IVA di conf.',
        ]

        def parameters = [
                "intestazione"   : intestazione,
                "title"          : "Elenco Partite IVA",
                "title.font.size": "12"
        ]

        def datiDaEsportare = []
        def datoDaEsportare

        listaPartiteIVA.each {

            datoDaEsportare = it.clone()

            datiDaEsportare << datoDaEsportare
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.AT_PARTITE_IVA,
                [codFiscale: codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields)
    }

    @Command
    def onDitteToXls() {

        def intestazione = [
                "Tipo Dato": "Anagrafe Tributaria"
        ]

        def fields = [
                'codFiscaleDitta'  : 'Cod. Fis.',
                'codiceCaricaDescr': 'Tipo carica',
                'dataDecorrenza'   : 'Decorrenza',
                'dataFineCarica'   : 'Fine Carica',
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.AT_DITTE,
                [codFiscale: codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, listaDitte as List, fields)

    }

    @Command
    def onRappresentantiToXls() {

        def fields = [:]

        fields = [
                'codFiscaleRap'    : 'Cod. Fis.',
                'codiceCaricaDescr': 'Tipo carica',
                'dataDecorrenza'   : 'Decorrenza',
                'dataFineCarica'   : 'Fine Carica',
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.AT_RAPPRESENTANTI,
                [codFiscale: codFiscale])

        XlsxExporter.exportAndDownload(nomeFile, listaRappresentanti as List, fields)

    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropCodiceFiscale(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        soggettoConfronto.codFiscale = event.dragged.label
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropCognome(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        soggettoConfronto.cognome = event.dragged.label
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropNome(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        soggettoConfronto.nome = event.dragged.label
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropSesso(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        soggettoConfronto.sesso = event.dragged.label
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropComuneNascita(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        def idRisposta = event.dragged.parent.value.id
        def risposta = listaRisposte.find {
            it.id == idRisposta
        }

        def comuneNascita = anagrafeTributariaService.getComuneNascita(risposta?.comuneNascita, risposta?.provinciaNascita,
                soggettoConfronto.dataNascita, true)

        soggettoConfronto.comuneNascita = comuneNascita?.ad4Comune

        if (!comuneNascita) {
            Clients.showNotification("Impossibile trovare il Luogo di Nascita nei Dizionari!\n\nNecessaria selezione manuale.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
        }
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    def onSelectComuneNascita(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        soggettoConfronto.comuneNascita = event.getData() ?: null
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropDataNascita(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && soggetto.gsd) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        String pattern = "dd/MM/yyyy"
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(pattern)
        soggettoConfronto.dataNascita = simpleDateFormat.parse(event.dragged.label).toTimestamp()
    }

    @Command
    def onChangeComuneNascita(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (soggettoConfronto.comuneNascita) {
            soggettoConfronto.comuneNascita = null
        }

        BindUtils.postNotifyChange(null, null, this, "soggettoConfronto")
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropDataDecesso(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        /// Modificabile solo se non GSD oppure GSD ma con stato di cessata anagrafe interna
        if (!abilitaModifica && !modificaStatoExtraGSD) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        String pattern = "dd/MM/yyyy"
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(pattern)
        soggettoConfronto.dataDecesso = simpleDateFormat.parse(event.dragged.label).toTimestamp()

        onChangeDataDecesso()
    }

    @Command
    def onChangeDataDecesso() {

        def statoDecesso = personaFisica ? 50 : -1

        if (soggettoConfronto.dataDecesso) {
            soggettoConfronto.stato = statoDecesso
            soggettoConfronto.comuneEvento = null
            BindUtils.postNotifyChange(null, null, this, "soggettoConfronto")
        } else {
            if (soggettoConfronto.statoOriginale == statoDecesso) {
                soggettoConfronto.stato = null
                soggettoConfronto.comuneEvento = null
                BindUtils.postNotifyChange(null, null, this, "soggettoConfronto")
            }
            else {
                soggettoConfronto.stato = soggettoConfronto.statoOriginale
            }
        }
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    def onSelectComuneResidenza(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {
        soggettoConfronto.comuneResidenza = event.getData() ?: null
        soggettoConfronto.cap = event.getData().cap
        sistemaDatiSoggetto()
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropComuneResidenza(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && (soggetto.residente == 'SI' || soggetto.residente == 'NI')) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()
        def idRisposta = event.dragged.parent.value.id
        def risposta = listaRisposte.find {
            it.id == idRisposta
        }

        def comuneResidenza = anagrafeTributariaService.getComuneResidenza(risposta?.comuneDomicilio, risposta?.provinciaDomicilio, true)

        soggettoConfronto.comuneResidenza = comuneResidenza?.ad4Comune

        if (!comuneResidenza) {
            Clients.showNotification("Impossibile trovare il Comune di Residenza nei Dizionari!\n\nNecessaria selezione manuale.",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
        } else {
            if (!risposta.capDomicilio?.isNumber() || risposta.capDomicilio?.length() > 6) {
                Clients.showNotification("Il CAP proveniente dall'Anagrafe Tributaria non è valido", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)

            } else {
                soggettoConfronto.cap = risposta.capDomicilio as Integer
                sistemaDatiSoggetto()
            }
        }
    }

    @Command
    def onChangeComuneResidenza(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (soggettoConfronto.comuneResidenza) {
            soggettoConfronto.comuneResidenza = null
        }

        BindUtils.postNotifyChange(null, null, this, "soggettoConfronto")
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropCap(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && (soggetto.residente == 'SI' || soggetto.residente == 'NI')) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()

        def valoreTrascinato = event.dragged.label

        if (valoreTrascinato?.isNumber() && valoreTrascinato?.length() <= 5) {
            soggettoConfronto.cap = valoreTrascinato
            sistemaDatiSoggetto()
        } else {
            Clients.showNotification("Il CAP proveniente dall'Anagrafe Tributaria non è valido", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        }
    }

    @Command
    @NotifyChange(['soggettoConfronto'])
    onDropIndirizzo(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        if (!abilitaModifica && (soggetto.residente == 'SI' || soggetto.residente == 'NI')) {
            visualizzaMessaggioBloccante()
            return
        }

        DropEvent event = (DropEvent) ctx.getTriggerEvent()

        def indirizzoParsed = anagrafeTributariaService.parseIndirizzo(event.dragged.label)

        soggettoConfronto.civico = indirizzoParsed.civico as Integer
        soggettoConfronto.suffisso = indirizzoParsed.suffisso
        soggettoConfronto.denominazioneVia = indirizzoParsed.indirizzo
        soggettoConfronto.interno = indirizzoParsed.interno as Integer
        soggettoConfronto.scala = indirizzoParsed.scala
        soggettoConfronto.piano = indirizzoParsed.piano

        soggettoConfronto.codiceVia = null
        soggettoConfronto.denomViaEdit = soggettoConfronto.denominazioneVia

        // Per ognuna delle risposte si va a verificare se presentano anomalie con l'indirizzo/civico/suffisso aggiornato
        listaRisposte.each {
            it.anomalieIndirizzo = controllaAnomalieIndirizzo(it.indirizzoDomicilio)
        }


        // Al momento dell'aggiornamento dell'indirizzo, viene salvata la dataDomicilio proveniente dalla risposta
        // per il suo utilizzo durante il salvataggio
        def idRisposta = event.dragged.parent.value.id
        def risposta = listaRisposte.find {
            it.id == idRisposta
        }

        this.dataDomicilioRisposta = risposta.dataDomicilio

        BindUtils.postNotifyChange(null, null, this, "listaRisposte")
    }

    @Command
    def onChangeIndirizzo() {
        // Per ognuna delle risposte si va a verificare se presentano anomalie con l'indirizzo/civico/suffisso aggiornato
        listaRisposte.each {
            it.anomalieIndirizzo = controllaAnomalieIndirizzo(it.indirizzoDomicilio)
        }
        BindUtils.postNotifyChange(null, null, this, "listaRisposte")
    }


    @Command
    def onSalva() {

        if (!verificaSoggetto())
            return

        Messagebox.show("Continuare con l'aggiornamento dei dati del Soggetto?", "Attenzione", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES == e.getName()) {
                            aggiornaSoggetto()
                        }
                    }
                }
        )
    }

    private boolean controllaAnomalieIndirizzo(def indirizzoDomicilio) {

        def parsedIndirizzo = anagrafeTributariaService.parseIndirizzo(indirizzoDomicilio)

        if (soggettoConfronto.codiceVia == null) soggettoConfronto.denominazioneVia = soggettoConfronto.denomViaEdit

        // Si impostano i campi valorizzati a "", dovuti al cancellamento manuale di un campo, con null
        // altrimenti vengono segnalate anomalie non presenti
        soggettoConfronto.denominazioneVia = soggettoConfronto.denominazioneVia?.isEmpty() ? null : soggettoConfronto.denominazioneVia
        soggettoConfronto.suffisso = soggettoConfronto.suffisso?.isEmpty() ? null : soggettoConfronto.suffisso
        soggettoConfronto.scala = soggettoConfronto.scala?.isEmpty() ? null : soggettoConfronto.scala
        soggettoConfronto.piano = soggettoConfronto.piano?.isEmpty() ? null : soggettoConfronto.piano

        // Si controlla se sono presenti anomalie tra le diverse parti dell'indirizzo, basta una anomalia per la segnalazione
        return soggettoConfronto.denominazioneVia != parsedIndirizzo.indirizzo ||
                soggettoConfronto.civico != parsedIndirizzo.civico as Integer ||
                soggettoConfronto.suffisso != parsedIndirizzo.suffisso ||
                soggettoConfronto.interno != parsedIndirizzo.interno as Integer ||
                soggettoConfronto.scala != parsedIndirizzo.scala ||
                soggettoConfronto.piano != parsedIndirizzo.piano
    }

    private def visualizzaMessaggioBloccante() {
        Clients.showNotification("Non è possibile aggiornare il soggetto perchè gestito dai demografici", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
    }

    private def aggiornaSoggetto() {

        def storicizzazioneSoggetto = false
        Soggetto oldSoggetto = Soggetto.get(soggetto.id)

        if (soggettoConfronto.codiceVia == null) soggettoConfronto.denominazioneVia = soggettoConfronto.denomViaEdit

        if (oldSoggetto.codFiscale != soggettoConfronto.codFiscale) {

            //Codice fiscale modificato
            anagrafeTributariaService.cambioCodiceFiscale(soggetto.codFiscale, soggettoConfronto.codFiscale)

            def tipo = oldSoggetto.tipo

            if (tipo == "0" || tipo == "2") {
                oldSoggetto.codFiscale = soggettoConfronto.codFiscale
            } else if (tipo == "1") {
                oldSoggetto.partitaIva = soggettoConfronto.codFiscale
            }
        }

        if (oldSoggetto.archivioVie?.id != soggettoConfronto.codiceVia
                || oldSoggetto.denominazioneVia != soggettoConfronto.denominazioneVia
                || oldSoggetto.numCiv != soggettoConfronto.civico
                || oldSoggetto.suffisso != soggettoConfronto.suffisso) {

            // Indirizzo modificato, chiudo i recapiti INDIRIZZO aperti e creo un recapito storicizzato
            anagrafeTributariaService.storicizzaIndirizzoSoggetto(oldSoggetto)
            storicizzazioneSoggetto = true
        }

        Ad4ComuneDTO comuneNascita = soggettoConfronto.comuneNascita
        def provinciaStatoNascita = comuneNascita?.provincia?.id ?: comuneNascita?.stato?.id

        Ad4ComuneDTO comuneResidenza = soggettoConfronto.comuneResidenza
        def provinciaStatoResidenza = comuneResidenza?.provincia?.id ?: comuneResidenza?.stato?.id

        // Aggiorno dati soggetto
        oldSoggetto.cognome = soggettoConfronto.cognome
        oldSoggetto.nome = soggettoConfronto.nome
        oldSoggetto.sesso = soggettoConfronto.sesso
        oldSoggetto.comuneNascita = Ad4ComuneTr4.findByComuneAndProvinciaStato(comuneNascita?.comune, provinciaStatoNascita)
        oldSoggetto.comuneResidenza = Ad4ComuneTr4.findByComuneAndProvinciaStato(comuneResidenza?.comune, provinciaStatoResidenza)
        oldSoggetto.dataNas = soggettoConfronto.dataNascita
        oldSoggetto.cap = soggettoConfronto.cap as Integer
        oldSoggetto.denominazioneVia = soggettoConfronto.denominazioneVia
        oldSoggetto.numCiv = (soggettoConfronto.civico != null) ? soggettoConfronto.civico as Integer : soggettoConfronto.civico
        oldSoggetto.suffisso = soggettoConfronto.suffisso
        oldSoggetto.interno = soggettoConfronto.interno
        oldSoggetto.scala = soggettoConfronto.scala
        oldSoggetto.piano = soggettoConfronto.piano
        oldSoggetto.stato = Anadev.get(soggettoConfronto.stato)

        if (soggettoConfronto.stato && soggettoConfronto.dataDecesso != null) {
            oldSoggetto.dataUltEve = soggettoConfronto.dataDecesso
        }

        if((soggettoConfronto.comuneEvento == null) && (soggettoConfronto.dataDecesso != null)) {
            /// Data decesso impostato e Comune evento vuoto o svuotato per modifica data decesso
            oldSoggetto.comuneEvento = null
        }

        if (soggettoConfronto.codiceVia == null) {
            oldSoggetto.archivioVie = null
        }

        // Aggiorno il campo note del soggetto nel caso sia stato aggiornato l'indirizzo
        if (storicizzazioneSoggetto) {

            def note = "Agg. automatico da Anagrafe Tributaria del ${new Date().format("dd/MM/yyyy")}"

            // Se il campo dataDomicilio della risposta non è null viene concatenato alla nota
            if (dataDomicilioRisposta != null) {
                note += " - Residenza dal ${dataDomicilioRisposta.format("dd/MM/yyyy")}"
            }

            // Se erano già presenti delle note, vengono concatenate alla fine
            if (oldSoggetto.note != null) {
                note += " - ${oldSoggetto.note}"
            }

            oldSoggetto.note = note
        }

        anagrafeTributariaService.aggiornaSoggetto(oldSoggetto)

        Events.postEvent(Events.ON_CLOSE, self, [aggiornato: true])
    }

    private def verificaSoggetto() {

        String message = ""
        boolean result = true

        String suffisso = soggettoConfronto.suffisso ?: ''
        if (suffisso.size() > 3) {
            message += "- Il barrato del civico puo' avere una lunghezza massima di 3 lettere\n"
        }

        if (message.size() > 0) {

            message = "Attenzione : \n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            result = false
        }

        return result
    }

    // Ricarica il pannello attivo
    def refreshPannello() {

        def rispostaId = rispostaSelected?.id ?: 0

        listaPartiteIVA = anagrafeTributariaService.getListaPartiteIVA(rispostaId)
        numPartiteIVA = listaPartiteIVA.size()
        listaDitte = anagrafeTributariaService.getListaDitte(rispostaId)
        numDitte = listaDitte.size()
        listaRappresentanti = anagrafeTributariaService.getListaRappresentanti(rispostaId)
        numRappresentanti = listaRappresentanti.size()

        BindUtils.postNotifyChange(null, null, this, "numPartiteIVA")
        BindUtils.postNotifyChange(null, null, this, "numDitte")
        BindUtils.postNotifyChange(null, null, this, "numRappresentanti")

        switch (tabSelezionata) {
            case "partiteIva":
                BindUtils.postNotifyChange(null, null, this, "listaPartiteIVA")
                break
            case "elencoDitte":
                BindUtils.postNotifyChange(null, null, this, "listaDitte")
                break
            case "elencoRappLeg":
                BindUtils.postNotifyChange(null, null, this, "listaRappresentanti")
                break
        }
    }

    private def caricaDatiSoggetto() {

        Soggetto sogg = Soggetto.get(soggetto.id)

        def statoDecesso = personaFisica ? 50 : -1

        soggettoConfronto = [
                codFiscale      : sogg.codFiscale,
                cognome         : sogg.cognome,
                nome            : sogg.nome,
                sesso           : sogg.sesso,
                comuneNascita   : sogg.comuneNascita?.ad4Comune?.toDTO() ?: [:],
                dataNascita     : sogg.dataNas,
                comuneResidenza : sogg.comuneResidenza?.ad4Comune?.toDTO() ?: [:],
                cap             : sogg.cap,
                residente       : soggetto.residente,
                denominazioneVia: sogg.denominazioneVia,
                codiceVia       : sogg?.archivioVie?.id,
                denomViaEdit    : sogg?.archivioVie?.id ? sogg.archivioVie.denomUff : sogg.denominazioneVia,    // Viauslizza questo
                indirizzo       : sogg.indirizzo,
                civico          : sogg.numCiv,
                suffisso        : sogg.suffisso,
                interno         : sogg.interno,
                scala           : sogg.scala,
                piano           : sogg.piano,
                dataDecesso     : (sogg.statoId == statoDecesso) ? sogg.dataUltEve : null,
                stato           : sogg.statoId,
                statoOriginale  : sogg.statoId,
                comuneEvento    : sogg.comuneEvento?.ad4Comune?.toDTO() ?: [:],
        ]

        sistemaDatiSoggetto()
    }

    private def sistemaDatiSoggetto() {
        soggettoConfronto.cap = (soggettoConfronto.cap as String)?.padLeft(5, '0')
    }
}
