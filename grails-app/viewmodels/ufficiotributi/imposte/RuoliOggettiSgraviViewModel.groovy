package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.SgraviService
import it.finmatica.tr4.modelli.ModelliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.DecimalFormat
import java.math.RoundingMode

class RuoliOggettiSgraviViewModel {

    // Componenti
    Window self

    // Services
    SgraviService sgraviService
    CommonService commonService
    DocumentaleService documentaleService
    ModelliService modelliService

    // Comuni
    def ruolo
    def zulIncluso
    def isModifica
    def isClonazione
    def titolo
    def oggettoRuolo
    def praticaRuolo
    //Tabella
    def sgravioSelezionato
    def listaSgravi
    //Form
    def listaMotivi
    def listaTipi
    def sgravio
    def isModificaAddProv
    def isModificaMaggTARES
    def sgravioRecords
    def sgravioRecordsTotali = [:]
    def sgravioRecordsImportiResidui
    def sgravioRecordSelezionato
    //Calcolo Sgravio
    def tipoSelezionato
    def motivoSelezionato
    def tipoSgravioOld = null
    def addProvModificataManualmente = false
    def importoTotale = null
    def codFiscale

    def tipiCalcolo = [
            null: '',
            T   : 'Tradizionale',
            N   : 'Normalizzato'
    ]

    def tipiEmissione = [null: '',
                         A   : 'Acconto',
                         S   : 'Saldo',
                         T   : 'Totale',
                         X   : 'Altro']

    /*
        La funzionalità era stata inizialmente implementata per gestire tutto in un unico viewmode.
        In fase di test è stato richesto di avere dialog separate per visualizzazione elenco e gestione.
        Per la gestione si apre una nuova dialog passando il padre e recuperando le informazioni.
     */

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") def r,
         @ExecutionArgParam("codFiscale") def cf,
         @ExecutionArgParam("oggettoRuolo") def or,
         @ExecutionArgParam("parent") def parent,
         @ExecutionArgParam("praticaRuolo") def praticaRuolo) {

        this.self = w
        this.oggettoRuolo = [:]
        this.codFiscale = cf

        if (!parent) {
            if (praticaRuolo) {
                this.praticaRuolo = praticaRuolo
                this.ruolo = sgraviService.getRuoloCoattivo(
                        [
                                pratica   : praticaRuolo.pratica,
                                codFiscale: cf,
                                ruolo     : r
                        ]
                )
            } else {
                this.oggettoRuolo = or
                this.ruolo = sgraviService.getRuolo(r, cf, oggettoRuolo.sequenza)
            }
            this.zulIncluso = "/ufficiotributi/imposte/ruoliOggettiSgraviTabella.zul"

            this.titolo = "Sgravi su Ruolo"

            this.sgravio = [:]

            this.listaMotivi = sgraviService.getMotiviSgravio()
            this.listaTipi = [D: "Discarico", S: "Sgravio", R: "Rimborso"]

            //Defaults
            this.isModifica = false
            this.isClonazione = false

        } else {
            this.ruolo = parent.ruolo
            if (parent.praticaRuolo) {
                this.praticaRuolo = parent.praticaRuolo
                this.codFiscale = parent.codFiscale
                this.zulIncluso = "/ufficiotributi/imposte/ruoliPraticheSgraviForm.zul"
            } else {
                this.zulIncluso = "/ufficiotributi/imposte/ruoliOggettiSgraviForm.zul"
            }
            this.titolo = "Sgravio su Ruolo"

            this.sgravio = parent.sgravio
            this.sgravio.imposta = this.ruolo.imposta

            if (this.praticaRuolo) {
                if (parent.sgravioSelezionato) {
                    // Apertura di uno sgravio selezionato
                    sgravio.progrSgravio = parent.sgravioSelezionato.progrSgravio
                } else {
                    // FIXME: calcolare qui il progressivo sgravio potrebbe dare problemi di concorrenza.
                    //        Si dovrebbe utilizzare una sequence Oracle.
                    // Creazione di un nuovo sgravio
                    sgravio.progrSgravio = sgraviService.getNextProgrSgravio([
                            ruolo     : this.ruolo.ruolo,
                            codFiscale: this.codFiscale,
                            pratica   : this.praticaRuolo.pratica
                    ])
                }
                fetchSgravioRecords()

                fetchSgravioRecordsTotali()
            }

            this.listaMotivi = parent.listaMotivi
            this.listaTipi = parent.listaTipi

            //Defaults
            this.isModifica = parent.isModifica
            this.isClonazione = parent.isClonazione

            if (!isModifica && !isClonazione) {
                this.sgravio.tipoSgravio = "D"
            }
        }

        this.isModificaAddProv = false
        this.isModificaMaggTARES = (this.ruolo.flagPuntoRaccolta == 'S') ? false : true

        caricaListaSgravi()

        Clients.evalJavaScript("grepCommaDecimal()")
    }

    private fetchSgravioRecords() {
        if (!praticaRuolo) {
            return
        }
        this.sgravioRecords = sgraviService.getSgravioRecords([
                pratica     : this.praticaRuolo.pratica,
                codFiscale  : this.codFiscale,
                ruolo       : this.ruolo.ruolo,
                progrSgravio: this.sgravio.progrSgravio
        ])

        fetchSgravioRecordsImportiResidui()

        BindUtils.postNotifyChange(null, null, this, 'sgravioRecords')
    }

    private fetchSgravioRecordsImportiResidui() {

        sgravioRecords.each { it.residuo = it.importo - (it.importoSgravio ?: 0) - (it.importoSgravato ?: 0) }

        sgravioRecords.each {
            BindUtils.postNotifyChange(null, null, it, 'residuo')
            BindUtils.postNotifyChange(null, null, it, 'importoSgravio')
        }
    }

    private void fetchSgravioRecordsTotali() {
        if (!praticaRuolo) {
            return
        }

        this.sgravioRecordsTotali = [importo        : this.sgravioRecords.sum { it.importo },
                                     importoSgravio : this.sgravioRecords.sum { it.importoSgravio ?: 0 },
                                     importoSgravato: this.sgravioRecords.sum { it.importoSgravato ?: 0 },
                                     residuoARuolo  : this.sgravioRecords.sum { it.residuo ?: 0 }]

        BindUtils.postNotifyChange(null, null, this, 'sgravioRecordsTotali')
    }

    @Command
    def onRefresh() {
        caricaListaSgravi()
        sgravioSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "listaSgravi")
        BindUtils.postNotifyChange(null, null, this, "sgravioSelezionato")
    }

    @Command
    def onSalva() { //Serve per salvare i dati del ruolo modificati (cartella, del, concessione e ruolo)
        if (praticaRuolo) {
            sgraviService.aggiornaDatiSgraviSuRuoloCoattivo(ruolo)
        } else {
            sgraviService.aggiornaDatiSgraviSuRuolo(ruolo)
        }

        Clients.showNotification("Sgravi salvati con successo."
                , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
    }

    @Command
    def onAnnulla() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onSalvaSgravio() {
        // Serve per salvare i dati relativi allo sgravio modificati all'interno del form
        if (praticaRuolo) {
            sgraviService.aggiornaDatiSgraviSuRuoloCoattivo(ruolo)
        } else {
            sgraviService.aggiornaDatiSgraviSuRuolo(ruolo)
        }

        def errori = controllaParametri()
        if (!errori.empty) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 5000, true)
            return
        }

        if (praticaRuolo) {
            if (!sgravioRecords.any { it.importoSgravio != null }) {
                Clients.showNotification("E' necessario compilare almeno uno sgravio."
                        , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
                return false
            }

            if (!sgravioRecords.every { isImportoSgravioValidAndNotify(it) }) {
                return false
            }

            updateSgravioRecords()
            fetchSgravioRecords()
        } else {

            if (isModifica) {
                sgraviService.salvaSgravioSuRuolo(sgravio)
            } else {
                //Nel caso di aggiunta/clonazione devo passare ruolo, codice fiscale e sequenza per poter recuperare il RuoloContribuente,
                //codConcessione e numRuolo per impostarli se valorizzati precedentemente
                sgraviService.salvaSgravioSuRuolo(sgravio,
                        [ruolo         : ruolo.ruolo, codFiscale: ruolo.codFiscale, sequenza: ruolo.sequenza,
                         codConcessione: ruolo.codConcessione, numRuolo: ruolo.numRuolo, oggettoPratica: ruolo.oggettoPratica])
            }
        }


        Clients.showNotification("Sgravio salvato con successo."
                , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
    }

    private updateSgravioRecords() {
        sgravioRecords.each {
            it.motivoSgravio = sgravio.motivoSgravio
            it.tipoSgravio = sgravio.tipoSgravio
            it.progrSgravio = sgravio.progrSgravio

            updateSgravioRecord(it)
        }
    }

    private updateSgravioRecord(sgravioRecord) {
        sgraviService.updateRuoloContribuente(sgravioRecord)

        if (sgravioRecord.importoSgravio) {
            if (sgravioRecord.sequenzaSgravio) {
                sgraviService.updateSgravio(sgravioRecord)
            } else {
                sgraviService.createSgravio(sgravioRecord)
            }
        } else {
            if (sgravioRecord.sequenzaSgravio) {
                sgraviService.deleteSgravio(sgravioRecord)
            }
        }
    }

    @Command
    def onAnnullaSgravio() {
        Events.postEvent(Events.ON_CLOSE, self, [])
    }

    @Command
    def onModificaSgravio() {
        isModifica = true

        tipoSgravioOld = sgravioSelezionato.tipoSgravio

        sgravio = duplica(sgravioSelezionato)

        //Sostituisco l'id del motivo con la entry relativa nella listaMotivi
        //(sgravio.motivoSgravio contiene un intero proveniente dal db -> lo utilizzo per ottenere il MotivoSgravio relativo)
        sgravio.motivoSgravio = listaMotivi.find {
            it.id == sgravio.motivoSgravio
        }

        caricaForm()
    }

    @Command
    def onAggiungiSgravio() {
        if (praticaRuolo) {
            sgravioSelezionato = null
        }
        isModifica = false
        sgravio = [:]
        caricaForm()
    }

    @Command
    def onDuplicaSgravio() {
        isModifica = false
        isClonazione = true
        sgravio = duplica(sgravioSelezionato)

        //Sostituisco l'id del motivo con la entry relativa nella listaMotivi
        //(sgravio.motivoSgravio contiene un intero proveniente dal db -> lo utilizzo per ottenere il MotivoSgravio relativo)
        sgravio.motivoSgravio = listaMotivi.find {
            it.id == sgravio.motivoSgravio
        }

        sgravio.sequenzaSgravio = sgraviService.getNextSequenzaSgravio(ruolo.ruolo,
                ruolo.codFiscale, ruolo.sequenza)

        caricaForm()
    }

    @Command
    def onEliminaSgravio() {

        def messaggio = ""
        messaggio += "Lo Sgravio verrà eliminato e non sarà recuperabile.\n"
        messaggio += "Si conferma l'operazione?"

        Messagebox.show(messaggio, "Eliminazione Sgravio", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {

                    def msgResult
                    if (praticaRuolo) {
                        def sgraviRecords = sgraviService.getSgravioRecords([
                                pratica     : praticaRuolo.pratica,
                                codFiscale  : codFiscale,
                                ruolo       : ruolo.ruolo,
                                progrSgravio: sgravioSelezionato.progrSgravio
                        ])
                        sgraviRecords.each {
                            if (it.sequenzaSgravio) {
                                sgraviService.deleteSgravio(it)
                            }
                        }
                        msgResult = ""
                    } else {
                        msgResult = sgraviService.eliminaSgravio(sgravioSelezionato)
                    }
                    visualizzaRisultatoEliminazione(msgResult)
                    onRefresh()

                }
            }
        })
    }

    @Command
    onChangeTipoSgravio() {
        if ((tipoSgravioOld in ['S', 'D'] && sgravio.tipoSgravio == 'R') ||
                (tipoSgravioOld == 'R' && sgravio.tipoSgravio in ['S', 'D'])) {
            sgravio.flagAutomatico = null
            BindUtils.postNotifyChange(null, null, this, "sgravio")
        }
    }

    @Command
    def onExportXls() {

        Map fields
        String format = "#,###.00"
        DecimalFormat formatter = new DecimalFormat(format)

        if (listaSgravi) {
            fields = [
                    "tipoRuoloStr"            : "Tipo Ruolo",
                    "annoRuolo"               : "Anno",
                    "annoEmissione"           : "Anno Emissione",
                    "progrEmissione"          : "Progr. Emissione",
                    "dataEmissione"           : "Data Emissione",
                    "invioConsorzio"          : "Invio",
                    "ruolo"                   : "Ruolo",
                    "oggetto"                 : "Oggetto",
                    "tipoOggetto"             : "TipoOggetto",
                    "indirizzo"               : "Indirizzo",
                    "sezione"                 : "Sezione",
                    "foglio"                  : "Foglio",
                    "numero"                  : "Numero",
                    "subalterno"              : "Subalterno",
                    "zona"                    : "Zona",
                    "categoriaCatasto"        : "Categoria Catasto",
                    "codiceTributo"           : "Codice Tributo",
                    "categoria"               : "Categoria",
                    "tipoTariffa"             : "Tipo Tariffa",
                    "motivoSgravio"           : "Numero Motivo",
                    "motivoSgravioDescrizione": "Descrizione Motivo",
                    "tipoSgravio"             : "Tipo",
                    "numeroElenco"            : "Numero Elenco",
                    "dataElenco"              : "Data Elenco",
                    "importoStr"              : "Importo",
                    "note"                    : "Note"
            ]

            listaSgravi.each {
                //Converto il valore di importo in un parametro stringa formattato
                it.importoStr = formatter.format(it.importo)
                //Converto il tipoRuolo nel carattere specifico
                it.tipoRuoloStr = it.tipoRuolo == 1 ? "Principale" : "Suppletivo"
                //Imposto altri valori provenienti dal ruolo
                it.annoRuolo = ruolo.annoRuolo
                it.annoEmissione = ruolo.annoEmissione
                it.progrEmissione = ruolo.progrEmissione
                it.dataEmissione = ruolo.dataEmissione
                it.invioConsorzio = ruolo.invioConsorzio
                //Valori oggetto
                it.oggetto = oggettoRuolo.id
                it.tipoOggetto = oggettoRuolo.tipoOggetto
                it.indirizzo = oggettoRuolo.indirizzo
                it.sezione = oggettoRuolo.sezione
                it.foglio = oggettoRuolo.foglio
                it.numero = oggettoRuolo.numero
                it.subalterno = oggettoRuolo.subalterno
                it.zona = oggettoRuolo.zona
                it.categoriaCatasto = oggettoRuolo.categoriaCatasto
                it.codiceTributo = oggettoRuolo.codiceTributo
                it.categoria = oggettoRuolo.categoria
                it.tipoTariffa = oggettoRuolo.tipoTariffa
            }

            String filename = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.SGRAVI_SU_RUOLO,
                    [codFiscale: ruolo.codFiscale,
                     idRuolo: ruolo.ruolo])

            def formatters = [
                    "annoRuolo"     : Converters.decimalToInteger,
                    "annoEmissione" : Converters.decimalToInteger,
                    "progrEmissione": Converters.decimalToInteger,
                    "ruolo"         : Converters.decimalToInteger,
                    "motivoSgravio" : Converters.decimalToInteger,
                    "tipoSgravio"   : { tipoSgr -> tipoSgr == "D" ? "Discarico" : (tipoSgr == "R" ? "Rimborso" : (tipoSgr == "S" ? "Sgravio" : "")) }
            ]

            XlsxExporter.exportAndDownload(filename, listaSgravi, fields, formatters)
        }
    }

    @Command
    def onCalcoloSgravio() {
        commonService.creaPopup(
                "/ufficiotributi/imposte/ruoliOggettiSgraviCalcolo.zul",
                self,
                [ruolo: ruolo],
                { event ->
                    if (event.data) {
                        def result = event.data.result
                        if (result.nota) {
                            Clients.showNotification(result.nota, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 5000, true)
                        }

                        caricaListaSgravi()
                    }
                }
        )
    }

    @Command
    def onStampaLetteraSgravio() {
        stampa("SGR")
    }

    @Command
    def onModificaAddProv() {
        isModificaAddProv = true
        BindUtils.postNotifyChange(null, null, this, "isModificaAddProv")
    }

    @Command
    def onModificaMaggTARES() {
        isModificaMaggTARES = true
        BindUtils.postNotifyChange(null, null, this, "isModificaMaggTARES")
    }

    @Command
    def onCalcolaImporto(@BindingParam("campoModificato") def campoModificato) {

        if (campoModificato == 'netto') {

            if (!addProvModificataManualmente) {
                calcolaAggiornaImporti()
            } else {
                String messaggio = "L'addizionale provinciale e' stata modificata manualmente.\nSi vuole aggiornarla coerentemente con il netto inserito?"
                Messagebox.show(messaggio, "Ricerca Sgravi",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            void onEvent(Event e) {
                                calcolaAggiornaImporti(Messagebox.ON_YES.equals(e.name))
                            }
                        }
                )
            }

        } else {
            if (campoModificato == 'maggTar') {
                /// Se si svuota Magg TARES e Punto di Raccola, riabilita calcolo automatico
                if(sgravio.maggiorazioneTares == null) {
                    if(this.ruolo.flagPuntoRaccolta == 'S') {
                        this.isModificaMaggTARES = false
                        calcolaAggiornaImportiMaggTARES()
                        BindUtils.postNotifyChange(null, null, this, 'isModificaMaggTARES')
                    }
                }
            }

            sgravio.importo = (sgravio.addizionaleEca ?: 0) + (sgravio.maggiorazioneEca ?: 0) +
                    (sgravio.addizionalePro ?: 0) + (sgravio.iva ?: 0) +
                    (sgravio.maggiorazioneTares ?: 0) + (sgravio.nettoSgravi ?: 0)

            BindUtils.postNotifyChange(null, null, this, "sgravio")
        }

        if (campoModificato == 'addProv') {
            addProvModificataManualmente = true
        }
    }

    @Command
    void onChangeImportoRuoloContribuente() {
        calculateImportoTotale()
    }

    @Command
    void onChangeSgravioRecord(@BindingParam("sgravioRecord") def sgravioRecord) {
        if (!praticaRuolo) {
            return
        }

        if (!isImportoSgravioValidAndNotify(sgravioRecord)) {
            BindUtils.postNotifyChange(null, null, this, 'sgravioRecords')
        }

        fetchSgravioRecordsImportiResidui()
        fetchSgravioRecordsTotali()
    }

    private def isImportoSgravioValidAndNotify(def sgravioRecord) {
        if (!sgravioRecord.importoSgravio) {
            // Se null va bene perchè lo sgravio sarà eliminato
            return true
        }
        if (sgravioRecord.importoSgravio < 0) {
            def message = "Sgravio non può essere negativo"
            Clients.showNotification(message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return false
        }
        if (sgravioRecord.importoSgravio > sgravioRecord.importo) {
            def message = "Sgravio non può essere maggiore dell'importo"
            Clients.showNotification(message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return false
        }

        if (sgravioRecord.importoSgravio > sgravioRecord.importo - sgravioRecord.importoSgravato) {
            def message = "È già presente uno sgravio complessivo di ${commonService.formattaValuta(sgravioRecord.importoSgravato)} su cod. $sgravioRecord.tributo per la pratica $praticaRuolo.pratica"
            Clients.showNotification(message
                    , Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return false
        }
        return true
    }

    private stampa(def tipoModello) {

        // def nomeFile = "SGR_${ruolo.annoRuolo}${ruolo.ruolo.toString().padLeft(10, '0')}_${ruolo.codFiscale.padLeft(16, '0')}"

        sgravioSelezionato.codiceTributo = oggettoRuolo.codiceTributo
        sgravioSelezionato.oggetto = oggettoRuolo.id

        def parametri = [
                tipoStampa : ModelliService.TipoStampa.SGRAVIO,
                idDocumento: [
                        sgravio: sgravioSelezionato,
                ],
        ]

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul", self, [parametri: parametri])
    }

    private calcolaAggiornaImporti(def modificaAddProv = true) {

        calcolaAggiornaImportiMaggTARES()

        def importi = sgraviService.calcolaImportiSgravio(sgravio.nettoSgravi, sgravio.maggiorazioneTares, ruolo.ruolo)

        sgravio.addizionaleEca = importi.addEca
        sgravio.maggiorazioneEca = importi.maggEca
        sgravio.iva = importi.iva

        if (modificaAddProv) {
            sgravio.importo = importi.lordo
            sgravio.addizionalePro = importi.addPro
            addProvModificataManualmente = false
        } else {
            sgravio.importo = (sgravio.addizionaleEca ?: 0) + (sgravio.maggiorazioneEca ?: 0) +
                    (sgravio.addizionalePro ?: 0) + (sgravio.iva ?: 0) +
                    (sgravio.maggiorazioneTares ?: 0) + (sgravio.nettoSgravi ?: 0)
        }

        BindUtils.postNotifyChange(null, null, this, "sgravio")
    }

    /// Ricalcola la quota Maggiorazione TARES nei casi di Punto di Raccolta
    private calcolaAggiornaImportiMaggTARES() {

        if(!this.isModificaMaggTARES) {
            if(this.ruolo.flagPuntoRaccolta == 'S') {
                if(sgravio.imposta) {
                    def maggiorazioneTares = ruolo.maggiorazioneTares ?: 0
                    BigDecimal maggTARES = maggiorazioneTares * sgravio.nettoSgravi / sgravio.imposta
                    if(maggTARES > maggiorazioneTares) maggTARES = ruolo.maggiorazioneTares
                    sgravio.maggiorazioneTares = maggTARES.setScale(2, RoundingMode.DOWN)
                }
            }
        }
    }

    //Funzioni d'utilità

    private caricaListaSgravi() {
        if (praticaRuolo) {
            listaSgravi = sgraviService.getSgraviSuRuoloCoattivo([codFiscale: codFiscale, ruolo: ruolo.ruolo, pratica: praticaRuolo.pratica])
        } else {
            listaSgravi = sgraviService.getSgraviSuRuolo(ruolo)
        }
        BindUtils.postNotifyChange(null, null, this, "listaSgravi")

        calculateImportoTotale()
    }

    private calculateImportoTotale() {
        if (!listaSgravi.empty) {
            importoTotale = (listaSgravi.collect { it.importo ?: 0 }).sum()
        } else {
            importoTotale = null
        }
        BindUtils.postNotifyChange(null, null, this, "importoTotale")
    }

    private def caricaForm() {
        zulIncluso = "/ufficiotributi/imposte/ruoliOggettiSgraviTabella.zul"

        commonService.creaPopup(
                "/ufficiotributi/imposte/ruoliOggettiSgravi.zul", self, [parent: this],
                { event ->
                    isModifica = false
                    sgravio = [:]
                    caricaTabella()
                })

        // BindUtils.postNotifyChange(null, null, this, "zulIncluso")
        BindUtils.postNotifyChange(null, null, this, "titolo")
    }

    private def caricaTabella() {
        isClonazione = false
        isModificaAddProv = false
        onRefresh()
    }

    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.isEmpty()) {
            messaggio = "Eliminazione avvenuta con successo"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    private def duplica(def sgravio) {
        def sgravioDuplicato = sgravio.getClass().newInstance(sgravio)

        return sgravioDuplicato
    }

    private def controllaParametri() {

        def errori = []

        if (!sgravio.motivoSgravio) {
            errori << "Il Motivo è obbligatorio"
        }

        return errori
    }
}
