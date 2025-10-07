package elaborazioni

import com.google.gson.Gson
import document.FileNameGenerator
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.datiesterni.anagrafetributaria.AllineamentoAnagrafeTributariaService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.elaborazioni.*
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.jobs.*
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.smartpnd.SmartPndService
import net.sf.jmimemagic.Magic
import net.sf.jmimemagic.MagicMatch
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.DropEvent
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.*

class ElaborazioniViewModel {

    private static Log log = LogFactory.getLog(ElaborazioniViewModel)

    // componenti
    Window self

    @Wire('#timerElaborazioni')
    Timer timerElaborazioni
    @Wire('#cbTimer')
    Checkbox cbTimer
    def tempoSelezionato
    def abilitaTempoDaSelezionare

    // services
    def springSecurityService
    CommonService commonService

    ElaborazioniService elaborazioniService
    IntegrazioneDePagService integrazioneDePagService
    DocumentaleService documentaleService
    AllineamentoAnagrafeTributariaService allineamentoAnagrafeTributariaService
    CompetenzeService competenzeService
    SmartPndService smartPndService
    ComunicazioniService comunicazioniService

    Magic parser

    def dePagAbilitato = false
    def smartPndAbilitato = false
    // Competenze
    def listaTributiAbilitati = []
    def tipoAbilitazioneLetturaTributo = [:]

    def listaElaborazioni
    def elaborazioneSelezionata
    def listaElaborazioniPaginazione = [
            max       : 30,
            offset    : 0,
            activePage: 0
    ]

    def listaDettagli
    def dettagliSelezionati
    def dettaglioSelezionato
    def selezioneDettagliPresente = false
    def listaDettagliPaginazione = [
            max       : 30,
            offset    : 0,
            activePage: 0
    ]

    def dimensioneDettagli = [:]

    def filtroDettagliAttivo = false
    def filtroDettagli

    def filtroElaborazioniAttivo = false
    def filtroElaborazioni

    def tipoMassivaPratica = false
    def tipoBollettazione = false
    def tipoAnagrafeTributaria = false

    def dettagliFiltro = ""
    def titoloDettaglio = "Dettaglio"

    def elaborazioniAperte = [:]

    boolean ultimaAttivitaIsInvioDoc = false

    def destinazioneInvioLabel
    def funzioniDettaglio = [
            controlloATDettaglio: false
    ]
    def anyFunzioniDettaglio = false

    @AfterCompose
    void afterCompose() {
        if (timerElaborazioni) {
            timerElaborazioni.stop()
        }
    }

    @NotifyChange("selezionato")
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        this.dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        verificaCompetenze()

        caricaElaborazioni()
        parser = new Magic()
        this.smartPndAbilitato = smartPndService.smartPNDAbilitato()
        this.destinazioneInvioLabel = this.smartPndAbilitato ? SmartPndService.TITOLO_SMART_PND : 'Documentale'
        tempoSelezionato
        abilitaTempoDaSelezionare = true
    }

    @Command
    def onSelezionaElaborazione(@BindingParam("elaborazione") def elab) {

        if (elab != elaborazioneSelezionata) {
            elaborazioneSelezionata = elab
            caricaDettagli(true)
            caricaDettagliSelezionati()

            elab.funzioniRiga.eliminaElab = elaborazioniService.abilitaEliminaElaborazione(elab.id)

            BindUtils.postNotifyChange(null, null, this, "elaborazioneSelezionata")
        }
    }

    @Command
    def onSelezionaDettaglio() {
        // Abilita funzione controlloATDettaglio
        funzioniDettaglio.controlloATDettaglio = dettaglioSelezionato?.controlloAtId != null && dettaglioSelezionato?.note != null

        anyFunzioniDettaglio = funzioniDettaglio.any {
            if (it.value == true) {
                return true
            }
        }

        BindUtils.postNotifyChange(null, null, this, "funzioniDettaglio")
        BindUtils.postNotifyChange(null, null, this, "anyFunzioniDettaglio")
    }

    @Command
    def onOpenDetail(@BindingParam("elaborazione") def elab) {
        elab = listaElaborazioni.record.find { it.id == elab.id }
        elab.attivita = elaborazioniService.listaAttivita(elab.id)
        BindUtils.postNotifyChange(null, null, elab, "attivita")
    }

    @Command
    def onClickDetail(@BindingParam("elaborazione") def elab) {
        elaborazioniAperte[elab.id] = !(elaborazioniAperte[elab.id] ?: false)
    }

    @Command
    def onChangePageElaborazioni() {
        caricaElaborazioni()
    }

    @Command
    def onChangePageDettagli() {
        caricaDettagli()
    }

    @Command
    def onCheckTuttiDettagli() {

        def selezionaTutto = false

        if (selezioneDettagliPresente()) {

            // Si effettua il reset della selezione
            resetDettagliSelezionati()

        } else {

            selezionaTutto = true

            def dettagli =
                    elaborazioniService.listaDettagli(elaborazioneSelezionata.id,
                            [max       : Integer.MAX_VALUE,
                             offset    : 0,
                             activePage: 0],
                            filtroDettagli).record

            dettagli.each {
                dettagliSelezionati[it.id] = true
            }

            selezioneDettagliPresente()

        }

        elaborazioniService.aggiornaSelezioneDettagli(elaborazioneSelezionata.id,
                elaborazioniService.listaDettagliSoloId(elaborazioneSelezionata.id, [
                        max       : Integer.MAX_VALUE,
                        offset    : 0,
                        activePage: 0
                ], filtroDettagli), // tutti i dettagli del filtro
                selezionaTutto)
        BindUtils.postNotifyChange(null, null, this, "dettagliSelezionati")

        valorizzaDettagliFiltro()
    }

    @Command
    def onCheckDettaglio(@BindingParam("dettaglio") def dettaglio) {
        selezioneDettagliPresente()

        elaborazioniService.aggiornaSelezioneDettaglio([(dettaglio.id): dettagliSelezionati[dettaglio.id]])

        valorizzaDettagliFiltro()
    }

    @Command
    def onRefreshElaborazioni() {
        caricaElaborazioni(true)
        resetDettagliSelezionati()
        resetFiltriDettagli()

        // Si settano le attività per le elaborazioni aperte
        listaElaborazioni.record.each {
            if (elaborazioniAperte[it.id]) {
                onOpenDetail(it)
            }
        }
    }

    @Command
    def onRefreshTimerElaborazioni() {
        if (timerElaborazioni.running) {
            stopTimer()
        } else {
            if (tempoSelezionato && cbTimer.isChecked() && attivaTimerSuElaborazioniAttive()) {
                startTimer()
            }
        }
        abilitaTempoDaSelezionare = !abilitaTempoDaSelezionare
        BindUtils.postNotifyChange(null, null, this, "abilitaTempoDaSelezionare")
    }


    @Command
    def onTimerElaborazioni() {
        log.info "Timer attivato  " + elaborazioniAperte
        if (attivaTimerSuElaborazioniAttive()) {
            if (elaborazioniAperte?.size() > 0) {
                listaElaborazioni.record.each {
                    if (elaborazioniAperte[it.id]) {
                        onOpenDetail(it)
                    }
                }
            }
        } else {
            stopTimer()
            if (elaborazioniAperte?.size() > 0) {
                listaElaborazioni.record.each {
                    if (elaborazioniAperte[it.id]) {
                        onOpenDetail(it)
                    }
                }
            }
        }
    }

    boolean attivaTimerSuElaborazioniAttive() {
        if (tempoSelezionato && cbTimer.isChecked()) {
            def totale = elaborazioniService.totaleAttivitaAttive()
            log.info "Attivita attive  " + totale
            return (totale > 0)
        }
        return false
    }

    @Command
    def onSetTimerElaborazioni() {
        if (tempoSelezionato) {
            if (tempoSelezionato.equals("") && cbTimer.isChecked()) {
                stopTimer()
            } else {
                if (cbTimer.isChecked() && attivaTimerSuElaborazioniAttive() && !timerElaborazioni.isRunning()) {
                    startTimer()
                }

                if (timerElaborazioni.getDelay() != Integer.parseInt(tempoSelezionato + "000")) {
                    timerElaborazioni.setDelay(Integer.parseInt(tempoSelezionato + "000"))
                }
            }
        }
    }

    void startTimer() {
        if (tempoSelezionato) {
            timerElaborazioni.setDelay(Integer.parseInt(tempoSelezionato + "000"))
            timerElaborazioni.start()
            log.info "Timer START"
        }
    }

    void stopTimer() {
        if (timerElaborazioni.isRunning()) {
            timerElaborazioni.stop()
            log.info "Timer STOP"
        }
    }

    @Command
    def onRefreshDettagli() {
        caricaDettagli(true)
    }

    @Command
    def onExportDettagliXls() {


        Map fields

        def dettagli

        fields = ["flagSelezionato": "Selezionato"]
        if (tipoMassivaPratica) {
            fields << ["anno"       : "Anno",
                       "tributo"    : "Tributo",
                       "tipoPratica": "Tipo Pratica",
                       "numero"     : "Numero"]
        }
        fields << ["nominativo": "Contribuente",
                   "codFiscale": "Codice Fiscale"]
        if (tipoBollettazione) {
            fields << ["pratica": "Pratica Base"]
        }
        if (!tipoAnagrafeTributaria) {
            fields << ["nomeFile"        : "Nome File",
                       "numPagine"       : "Numero Pagine",
                       "dimensioneString": "Dimensione"]
        }
        if (elaborazioneSelezionata.funzioniRiga.generaDocumenti) {
            fields << ["stampaId": "Stampa"]
        }
        if (elaborazioneSelezionata.funzioniRiga.allegaAvvisoAgid && dePagAbilitato) {
            fields << ["avvisoAgidId": "Avviso AgID"]
        }
        if (elaborazioneSelezionata.funzioniRiga.elaboraPerTipografia) {
            fields << ["tipografiaId": "Tipografia"]
        }
        if (elaborazioneSelezionata.funzioniRiga.inviaADocumentale) {
            fields << ["documentaleId": destinazioneInvioLabel]
        }
        if (elaborazioneSelezionata.funzioniRiga.inviaAppIO) {
            fields << ["appioId": "AppIO"]
        }
        if (elaborazioneSelezionata.funzioniRiga.esportaAT) {
            fields << ["anagrId": "Esp. A.T."]
        }
        if (elaborazioneSelezionata.funzioniRiga.controllaAT) {
            fields << ["controlloAtId": "Contr. A.T."]
        }
        if (elaborazioneSelezionata.funzioniRiga.allineamentoAT) {
            fields << ["allineamentoAtId": "All. A.T."]
        }
        fields << ["note": "Note"]

        dettagli = elaborazioniService.listaDettagli(elaborazioneSelezionata.id, [max       : Integer.MAX_VALUE,
                                                                                  offset    : 0,
                                                                                  activePage: 0]).record

        def dd = dettagli.collate(500).collectEntries {
            elaborazioniService.getDimensioneDocumenti(it.collect { d -> d.id })
        }

        dettagli = dettagli.collect {
            it << [
                    numero          : it.pratica?.numero,
                    anno            : it.pratica?.anno,
                    tipoPratica     : it.pratica?.tipoPratica,
                    tributo         : it.tipoTributoDesc,
                    pratica         : it.pratica?.id,
                    dimensioneString: dd[it.id]?.dimensioneString
            ]
        }

        def formatters = [flagSelezionato: { it == 'S' ? 'S' : 'N' }]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.DETTAGLI,
                [nomeElaborazione: elaborazioneSelezionata.nomeElaborazione])

        XlsxExporter.exportAndDownload(nomeFile, dettagli, fields, formatters)
    }

    @Command
    def onGeneraDocumenti() {

        if (!verificaElaborazione()) {
            return
        }

        def parametri = parametriModelliStampa()

        parametri.generazioneMassiva = true

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                self,
                [
                        parametri: parametri
                ],
                { event ->
                    if (event.data) {

                        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_GENERA_DOCUMENTI)
                        def att = [
                                'codiceUtenteBatch': springSecurityService.currentUser.id,
                                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                                elaborazione       : elaborazioneSelezionata.id,
                                modello            : event.data.modello.modello,
                                flagF24            : (event.data.allegaF24 ? 'S' : null),
                                tipoAttivita       : ta,
                                statoAttivita      : StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                        ]

                        ElaborazioniGeneraDocumentiJob.triggerNow([
                                'codiceUtenteBatch': springSecurityService.currentUser.id,
                                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                                attivita           : elaborazioniService.creaAttivita(att).id,
                                tipiF24            : event.data.tipiF24,
                                ridotto            : event.data.ridotto
                        ])

                        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
                        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
                        onSetTimerElaborazioni()

                    }
                })
    }

    @Command
    def onInvioTipografia() {

        if (!verificaElaborazione()) {
            return
        }

        // Verifiche specifiche per l'invio a tipografia
        def cliente = springSecurityService.principal
        if (!cliente.amministrazione.soggetto.indirizzoResidenza || !cliente.amministrazione.soggetto.cognome ||
                !cliente.amministrazione.soggetto.provinciaResidenza || !cliente.amministrazione.soggetto.capResidenza) {

            Clients.showNotification(
                    "E' necessario valorizzare la tabella AS4_V_SOGGETTI_CORRENTI.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        //Controllo se ci sono documenti non generati
        if (documentiNonGenerati()) return

        def tipoSpedizione = null
        Window w = Executions.createComponents("/elaborazioni/creazioneSpedizione.zul",
                null,
                [idElaborazione: elaborazioneSelezionata.id])
        w.doModal()
        w.onClose() { event ->
            if (event.data) {
                tipoSpedizione = event.data.tipoSpedizione

                def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_INVIO_A_TIPOGRAFIA)
                def att =
                        [
                                elaborazione  : elaborazioneSelezionata.id,
                                tipoAttivita  : ta,
                                statoAttivita : StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO),
                                tipoSpedizione: tipoSpedizione
                        ]

                ElaborazioniInvioATipografiaJob.triggerNow([
                        'codiceUtenteBatch': springSecurityService.currentUser.id,
                        'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                        attivita           : elaborazioniService.creaAttivita(att).id,
                        cliente            : [
                                amm            : springSecurityService.principal.amm(),
                                amministrazione: springSecurityService.principal.amministrazione
                                        .toDTO(["soggetto", "soggetto.provinciaResidenza"])
                        ],
                        tipoLimiteFile     : event.data.tipoLimiteFile,
                        limiteFile         : event.data.limiteFile
                ])

                elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
                BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
                onSetTimerElaborazioni()
            }
        }
    }

    @Command
    def onInviaADocumentale() {

        if (!verificaElaborazione() || documentiNonGenerati()) {
            return
        }

        def parametri = parametriModelliStampa()

        parametri.invioMassivo = true

        commonService.creaPopup("/pratiche/sceltaModelloStampa.zul",
                null,
                [
                        parametri: parametri
                ],
                { event ->
                    if (event.data) {

                        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_INVIO_A_DOCUMENTALE)
                        def att =
                                [
                                        elaborazione          : elaborazioneSelezionata.id,
                                        tipoAttivita          : ta,
                                        statoAttivita         : StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO),
                                        dettaglioComunicazione: event.data.dettaglioComunicazione,
                                        notifica              : smartPndService.smartPNDAbilitato() ?
                                                (event.data.notifica.tipoNotifica != SmartPndService.TipoNotifica.NONE ? 'S' : null) : null,
                                ]

                        ElaborazioniInvioADocumentaleJob.triggerNow([
                                'codiceUtenteBatch'    : springSecurityService.currentUser.id,
                                'codiciEntiBatch'      : springSecurityService.principal.amministrazione.codice,
                                attivita               : elaborazioniService.creaAttivita(att).id,
                                'inviaASmartPnd'       : event.data.inviaASmartPnd,
                                'notifica'             : event.data.notifica,
                                'notificationFeePolicy': event.data.notificationFeePolicy,
                                'physicalComType'      : event.data.physicalComType,
                                cliente                : [
                                        amm            : springSecurityService.principal.amm(),
                                        amministrazione: springSecurityService.principal.amministrazione
                                                .toDTO(["soggetto", "soggetto.provinciaResidenza"])
                                ],
                                'tipoComunicazione'    : event.data.tipoComunicazione,
                                'comunicazioneTesto'   : event.data.comunicazioneTesto,
                                'firma'                : event.data.firma,
                                'oggetto'              : event.data.oggetto ?: event.data.notifica.oggetto,
                                'allegati'             : event.data.allegati
                        ])

                        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
                        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
                        onSetTimerElaborazioni()
                    }
                })
    }

    @Command
    def onAllegaAvvisoAgid() {

        if (!verificaElaborazione()) {
            return
        }

        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_ALLEGA_AVVISO_AGID)
        def att =
                [
                        elaborazione : elaborazioneSelezionata.id,
                        tipoAttivita : ta,
                        statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                ]

        ElaborazioneAvvisiAgidJob.triggerNow([
                'codiceUtenteBatch': springSecurityService.currentUser.id,
                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                attivita           : elaborazioniService.creaAttivita(att).id
        ])

        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
        onSetTimerElaborazioni()
    }

    @Command
    def onInviaAppIO() {

        if (!verificaElaborazione()) {
            return
        }

        def tipoTributo = elaborazioneSelezionata.tipoTributo
        def tipoDocumento = elaborazioniService.recuperaTipoDocumentoDaElaborazione(elaborazioneSelezionata)

        // Le elaborazioni massive raggruppano pratiche dello stesso tipo quindi prendo la prima
        def idPratica = listaDettagli.record.first().pratica?.id
        def tipoComunicazione = comunicazioniService.recuperaTipoComunicazione(idPratica, tipoDocumento)

        commonService.creaPopup("/messaggistica/appio/appio.zul", self, [
                tipoTributo      : tipoTributo,
                tipoComunicazione: tipoComunicazione,
                massiva          : true
        ],
                { e ->
                    if (e.data) {
                        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_INVIO_APPIO)
                        def att =
                                [
                                        elaborazione : elaborazioneSelezionata.id,
                                        tipoAttivita : ta,
                                        testoAppio   : (new Gson()).toJson(e.data),
                                        statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                                ]

                        ElaborazioniInvioAppIOJob.triggerNow([
                                'codiceUtenteBatch': springSecurityService.currentUser.id,
                                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                                attivita           : elaborazioniService.creaAttivita(att).id
                        ])

                        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
                        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
                        onSetTimerElaborazioni()
                    }
                })
    }

    @Command
    def onEsportaAnagrTrib() {

        if (!controllaSoggettiCorrenti()) {
            return
        }

        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_GENERA_ANGR_TRIB)
        def att =
                [
                        elaborazione : elaborazioneSelezionata.id,
                        tipoAttivita : ta,
                        statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                ]

        ElaborazioneMassiva elaborazione = ElaborazioneMassiva.get(elaborazioneSelezionata.id)

        // Si suddivide la lista in sottoliste e si crea un'attivita per ognunga di esse
        List<DettaglioElaborazione> dettagliTotali = elaborazioniService.listaDettagliDaElaborare(
                elaborazione,
                elaborazioniService.dettagliOrderBy
        ).collate(10000)

        dettagliTotali.each {
            AnagrafeTributariaOutputJob.triggerNow([
                    'codiceUtenteBatch': springSecurityService.currentUser.id,
                    'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                    attivita           : elaborazioniService.creaAttivita(att).id,
                    'dettaglio'        : it
            ])
        }

        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
    }

    @Command
    def onControllaAnagrTrib() {

        if (!controllaSoggettiCorrenti()) {
            return
        }

        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_CONTROLLA_ANGR_TRIB)
        def att =
                [
                        elaborazione : elaborazioneSelezionata.id,
                        tipoAttivita : ta,
                        statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                ]

        AnagrafeTributariaControlloJob.triggerNow([
                'codiceUtenteBatch': springSecurityService.currentUser.id,
                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                attivita           : elaborazioniService.creaAttivita(att).id
        ])

        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
    }

    @Command
    def onAllineamentoAnagrTrib() {

        if (!controllaSoggettiCorrenti()) {
            return
        }

        def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_ALLINEAMENTO_ANGR_TRIB)
        def att =
                [
                        elaborazione : elaborazioneSelezionata.id,
                        tipoAttivita : ta,
                        statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                ]

        AnagrafeTributariaAllineamentoJob.triggerNow([
                'codiceUtenteBatch': springSecurityService.currentUser.id,
                'codiciEntiBatch'  : springSecurityService.principal.amministrazione.codice,
                attivita           : elaborazioniService.creaAttivita(att).id
        ])

        elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
        BindUtils.postNotifyChange(null, null, elaborazioneSelezionata, "attivita")
    }

    @Command
    def onScaricaDocumentoDettaglio() {

        dettaglioSelezionato.documento = DettaglioElaborazioneDocumento.get(dettaglioSelezionato.id)?.documento

        MagicMatch match = parser.getMagicMatch(dettaglioSelezionato.documento)
        AMedia amedia = new AMedia(dettaglioSelezionato.nomeFile, match.extension, match.mimeType, dettaglioSelezionato.documento)
        Filedownload.save(amedia)
    }

    @Command
    def onScaricaDocumentoAttivita(@BindingParam("att") def att) {

        def elab = att.elaborazione
        att.documento = AttivitaElaborazioneDocumento.get(att.id)?.documento

        def url = new String(att.documento, "UTF-8")
        if (url.startsWith("URL:")) {
            // Si estrae il percorso
            url = url.substring(4)
        }

        MagicMatch match = parser.getMagicMatch(new File(url), true)

        def fis = new FileInputStream(new File(url))
        def mimeType = new String(att.documento, "UTF-8")
                .toUpperCase().endsWith(".ZIP") ? "application/zip" : match.mimeType
        def extension = new String(att.documento, "UTF-8")
                .toUpperCase().endsWith(".ZIP") ? "zip" : (mimeType == "text/plain" ? 'txt' : match.extension)

        AMedia amedia =
                new AMedia("${elab.nomeElaborazione}_${att.id}.${extension}".replace(" ", "_").toUpperCase(),
                        extension, mimeType, fis)
        Filedownload.save(amedia)
    }

    @Command
    def onAnnullaStampa() {
        sganciaAttivita(ElaborazioniService.TIPO_ATTIVITA.STAMPA)
    }

    @Command
    def onAnnullaTipografia() {
        sganciaAttivita(ElaborazioniService.TIPO_ATTIVITA.TIPOGRAFIA)
    }

    @Command
    def onAnnullaAgID() {
        sganciaAttivita(ElaborazioniService.TIPO_ATTIVITA.AGID)
    }

    @Command
    def onControlloATDettaglio() {

        Long dettaglioId = dettaglioSelezionato.id

        Contribuente contribuente = dettaglioSelezionato.contribuente
        SoggettoDTO soggetto = Soggetto.get(contribuente.soggetto.id).toDTO([
                "contribuenti",
                "comuneResidenza",
                "comuneResidenza.ad4Comune",
                "archivioVie",
                "stato"
        ])

        commonService.creaPopup(
                "/ufficiotributi/anagrafetributaria/dettaglioAnagrafeTributaria.zul", self
                , [soggetto: soggetto],
                { event ->
                    if (event.data?.aggiornato) {
                        controlloATDettaglio(dettaglioId)
                        caricaDettagli(false)
                    }
                }
        )
    }

    @Command
    def onEliminaDettaglio() {
        Messagebox.show("Il dettaglio verrà eliminato. Proseguire?", "Eliminazione Dettaglio",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            DettaglioElaborazione.get(dettaglioSelezionato.id).delete()
                            caricaDettagli(true)
                        }
                    }
                }
        )
    }

    @Command
    def openCloseFiltri() {
        Window w = Executions.createComponents("/elaborazioni/filtriDettagli.zul",
                self, [filtri: filtroDettagli, idElaborazione: elaborazioneSelezionata.id])
        w.onClose { event ->
            if (event.data) {
                gestioneFiltriDettaglio(event.data)
            }

        }
        w.doModal()
    }

    @Command
    def openCloseFiltriElaborazioni() {
        Window w = Executions.createComponents("/elaborazioni/filtriElaborazioni.zul",
                self, [filtri: filtroDettagli])
        w.onClose { event ->
            if (event.data) {
                gestioneFiltriElaborazioni(event.data)
            }

        }
        w.doModal()
    }

    @Command
    def onEliminaElaborazione() {

        Messagebox.show("L'elaborazione verrà eliminata con i dettagli e le attività associate. Proseguire?", "Eliminazione Elaborazione",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            try {
                                DettaglioElaborazione.deleteAll(DettaglioElaborazione.findAllWhere("elaborazione.id": elaborazioneSelezionata.id))
                                AttivitaElaborazione.deleteAll(AttivitaElaborazione.findAllWhere("elaborazione.id": elaborazioneSelezionata.id))
                                ElaborazioneMassiva.get(elaborazioneSelezionata.id).delete()

                                onRefreshElaborazioni()
                            } catch (Exception ex) {

                                commonService.serviceException(ex)
                            }
                        }
                    }
                }
        )
    }

    @Command
    def onEliminaAttivita(@BindingParam("att") def attivita) {

        def idAttivita = attivita.id

        if (attivita.tipoAttivita.id == 6 && esisteRecordSamRisposte(idAttivita)) {
            Clients.showNotification("Attività non eliminabile, esiste un'attività di controllo associata.", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
            return
        }

        Messagebox.show("L'attività verrà eliminata. Proseguire?", "Eliminazione Attività",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set stampaId = null where stampaId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set documentaleId = null where documentaleId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set tipografiaId = null where tipografiaId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set avvisoAgidId = null where avvisoAgidId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set appioId = null where appioId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set anagrId = null where anagrId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set controlloAtId = null where controlloAtId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            DettaglioElaborazione.executeUpdate(
                                    """update DettaglioElaborazione set allineamentoAtId = null where allineamentoAtId = :idAttivita""",
                                    [idAttivita: idAttivita]
                            )

                            AttivitaElaborazione.get(idAttivita).delete()

                            // Elabora per tipografia
                            if (2 == attivita.tipoAttivita.id) {

                                def pathToFolder = elaborazioniService.getPathToDocFolderByIdAttivita(idAttivita)
                                try {
                                    elaborazioniService.eliminaCartellaElaborazione(pathToFolder)
                                } catch (Exception ex) {
                                    if (ex instanceof IOException) {
                                        log.error("Attività ${idAttivita}. Non è stato possibile cancellare la cartella ${pathToFolder}", ex)
                                        Clients.showNotification("Non è stato possibile cancellare la cartella, per l'attività ${idAttivita}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
                                    } else if (ex instanceof IllegalArgumentException) {
                                        log.error("Attività ${idAttivita}. Cartella non trovata al percorso ${pathToFolder}", ex)
                                        Clients.showNotification("Non è stata trovata la cartella da cancellare, per l'attività ${idAttivita}", Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
                                    }
                                }
                            }

                            onRefreshElaborazioni()
                        }
                    }
                }
        )
    }

    @Command
    def onCambiaElaborazione(@ContextParam(ContextType.BIND_CONTEXT) BindContext ctx) {

        DropEvent event = (DropEvent) ctx.triggerEvent
        def dett = event.dragged.getAttribute("foo")
        def elab = event.target.getAttribute("foo")

        // Non si può spostare un dettaglio sulla stessa elaborazione
        if (dett.elaborazione.id == elab.id) {
            Clients.showNotification("Il dettaglio è già associato all'elaborazione ${elab.id}.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        // Elaborazione di partenza e di destinazione devono essere dello stesso tipo
        if ((dett.elaborazione.ruolo != null && elab.tipoPratica != null) || (dett.elaborazione.tipoPratica != null && elab.ruolo != null)) {
            Clients.showNotification("Il dettaglio non può essere spostato in un'elaborazione di tipo diverso da quella di origine.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        // Non si può spostare un dettaglio inviato a tipografia o documentale
        if (dett.tipografiaId != null || dett.documentaleId != null) {
            Clients.showNotification("Sul dettaglio esistono attività di invio a tipografia e/o documentale.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return
        }

        Messagebox.show("Il dettaglio verrà spostato dall'elaborazione ${dett.elaborazione.id} all'elaborazione ${elab.id}. Proseguire?", "Sposta dettaglio",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def dettaglio = DettaglioElaborazione.get(dett.id)
                            dettaglio.elaborazione = ElaborazioneMassiva.get(elab.id)
                            dettaglio.save(failOnError: true, flush: true)
                            caricaElaborazioni(true)
                        }
                    }
                }
        )

    }

    @Command
    def onOpenLogAttivita(@BindingParam("att") def idAttivita) {
        commonService.creaPopup("/elaborazioni/logAttivita.zul", self,
                [idAttivita: idAttivita], {})
    }

    @Command
    def creaElaborazioneAT() {
        elaborazioniService.creaElaborzioneAT(elaborazioneSelezionata.id)
        caricaElaborazioni()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("contribuente") def contribuente) {

        def ni = contribuente?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onOpenVisualizzaSoggettoErede(@BindingParam("erede") def erede) {
        def ni = erede?.id
        if (!ni) {
            Clients.showNotification("Soggetto non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }

        Clients.evalJavaScript("window.open('standalone.zul?sezione=SOGGETTO&idSoggetto=${ni}','_blank');")
    }

    private def verificaElaborazione() {

        // Se esite un'attività in corso non si permette l'esecuzione
        def elencoAttivita = AttivitaElaborazione.findAllByElaborazione(ElaborazioneMassiva.get(elaborazioneSelezionata.id)).sort { -it.id }
        def ultimaAtt = null

        if (elencoAttivita.size() > 0) {
            ultimaAtt = elencoAttivita[0]
        }
        if (ultimaAtt != null && ultimaAtt.statoAttivita.id in ([0, 1] as Long[])) {
            Clients.showNotification("Esiste già un'attività in corso [${ultimaAtt.tipoAttivita.descrizione}].",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return false
        }

        // Si deve selezionare almeno un dettaglio
        if (dettagliSelezionati.find { it.value } == null) {
            Clients.showNotification("Nessun dettaglio selezionato.", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    private gestioneFiltriDettaglio(def data) {
        filtroDettagliAttivo = data.filtriAttivi
        filtroDettagli = data.filtri

        caricaDettagli(true)

        BindUtils.postNotifyChange(null, null, this, "filtroDettagliAttivo")
    }

    private gestioneFiltriElaborazioni(def data) {
        filtroElaborazioniAttivo = data.filtriAttivi
        filtroElaborazioni = data.filtri

        caricaElaborazioni()

        BindUtils.postNotifyChange(null, null, this, "filtroElaborazioniAttivo")
    }

    private resetFiltriDettagli() {
        filtroDettagli = [:]
        filtroDettagliAttivo = false
        BindUtils.postNotifyChange(null, null, this, "filtroDettagli")
        BindUtils.postNotifyChange(null, null, this, "filtroDettagliAttivo")
    }

    private void sganciaAttivita(def tipoAttivita) {
        Messagebox.show("L'informazione sul tipo di attività verrà eliminata. Proseguire?", "Eliminazione Informazione Attività",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            elaborazioniService.sganciaAttivita(dettaglioSelezionato.id, tipoAttivita)
                            caricaDettagli()
                        }
                    }
                }
        )
    }

    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            listaTributiAbilitati.add(it.tipoTributo)
            tipoAbilitazioneLetturaTributo[it.tipoTributo] = competenzeService.tipoAbilitazioneUtente(it.tipoTributo) != 'A'
        }
    }

    private caricaElaborazioni(def reset = false) {

        listaElaborazioni = elaborazioniService.listaElaborazioni(listaElaborazioniPaginazione, filtroElaborazioni, listaTributiAbilitati)
        BindUtils.postNotifyChange(null, null, this, "listaElaborazioni")
        listaElaborazioni.record.collect {
            abilitazioneFunzioni(it)
        }

        if (reset) {
            elaborazioneSelezionata = null
            listaElaborazioniPaginazione = [
                    max       : 30,
                    offset    : 0,
                    activePage: 0
            ]

            listaDettagli = null
            dettagliSelezionati = [:]
            selezioneDettagliPresente = false
            listaDettagliPaginazione = [
                    max       : 30,
                    offset    : 0,
                    activePage: 0
            ]

            BindUtils.postNotifyChange(null, null, this, "elaborazioneSelezionata")
            BindUtils.postNotifyChange(null, null, this, "listaElaborazioniPaginazione")
            BindUtils.postNotifyChange(null, null, this, "listaDettagli")
            BindUtils.postNotifyChange(null, null, this, "dettagliSelezionati")
            BindUtils.postNotifyChange(null, null, this, "selezioneDettagliPresente")
            BindUtils.postNotifyChange(null, null, this, "listaDettagliPaginazione")
            BindUtils.postNotifyChange(null, null, this, "elaborazioniAperte")
        }
    }

    private caricaDettagli(def reset = false) {

        if (elaborazioneSelezionata == null) {
            return
        }

        if (reset) {
            listaDettagliPaginazione = [
                    max       : 30,
                    offset    : 0,
                    activePage: 0
            ]
        }

        //Se la lista delle attività è vuota la ricalcolo
        if (elaborazioneSelezionata.attivita.size() == 0) {
            elaborazioneSelezionata.attivita = elaborazioniService.listaAttivita(elaborazioneSelezionata.id)
        }
        //Controllo se l'ultima attività è di tipo INVIO AL DOCUMENTALE per disabilitare l'operazione di elimina di ciascun dettaglio
        ultimaAttivitaIsInvioDoc = (elaborazioneSelezionata.attivita.size() == 0) ? false : (elaborazioneSelezionata.attivita[0].tipoAttivita.id == 3)

        listaDettagli = elaborazioniService.listaDettagli(
                elaborazioneSelezionata.id,
                listaDettagliPaginazione,
                filtroDettagli,
                elaborazioniService.dettagliOrderBy
        )

        elaborazioneSelezionata.listaDettagli = listaDettagli

        dimensioneDettagli = listaDettagli.record.empty ? [:] :
                elaborazioniService.getDimensioneDocumenti(listaDettagli.record.collect { it.id })
        def dimTot = elaborazioniService.getDimensioneTotaleDocumenti(elaborazioneSelezionata.id)

        def tipoElaborazione = elaborazioneSelezionata.tipoElaborazione?.id
        tipoMassivaPratica = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE
        tipoBollettazione = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA
        tipoAnagrafeTributaria = tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_ANAGRAFE_TRIBUTARIA

        BindUtils.postNotifyChange(null, null, this, "listaDettagli")
        BindUtils.postNotifyChange(null, null, this, "tipoBollettazione")
        BindUtils.postNotifyChange(null, null, this, "tipoMassivaPratica")
        BindUtils.postNotifyChange(null, null, this, "tipoAnagrafeTributaria")
        BindUtils.postNotifyChange(null, null, this, "ultimaAttivitaIsInvioDoc")

        if (reset) {
            caricaDettagliSelezionati()
            valorizzaDettagliFiltro()

            BindUtils.postNotifyChange(null, null, this, "selezioneDettagliPresente")
            BindUtils.postNotifyChange(null, null, this, "listaDettagliPaginazione")
            BindUtils.postNotifyChange(null, null, this, "dimensioneDettagli")
        }

        invalidaListaDettagli()
    }

    private valorizzaDettagliFiltro() {

        def totDettagli = DettaglioElaborazione.countByElaborazione(ElaborazioneMassiva.get(elaborazioneSelezionata.id))
        def dettagliSelezionati = DettaglioElaborazione.countByElaborazioneAndFlagSelezionato(ElaborazioneMassiva.get(elaborazioneSelezionata.id), 'S')
        def totDettagliDimensione = commonService.humanReadableSize(elaborazioniService.getDimensioneTotaleDocumenti(elaborazioneSelezionata.id) ?: 0)
        def dettagliSelezionatiDimensione = commonService.humanReadableSize(elaborazioniService.getDimensioneTotaleDocumenti(elaborazioneSelezionata.id, true) ?: 0)
        def totDettagliPagine = (elaborazioniService.getPagineTotaleDocumenti(elaborazioneSelezionata.id) ?: 0)
        def dettagliSelezionatiPagine = (elaborazioniService.getPagineTotaleDocumenti(elaborazioneSelezionata.id, true) ?: 0)

        dettagliFiltro = "Dettagli selezionati (${dettagliSelezionati} di ${totDettagli}) Dimensione (${dettagliSelezionatiDimensione} di ${totDettagliDimensione}) Pagine (${dettagliSelezionatiPagine} di ${totDettagliPagine})"
        titoloDettaglio = "Dettaglio (${listaDettagli.numeroRecord}/${DettaglioElaborazione.countByElaborazione(ElaborazioneMassiva.get(elaborazioneSelezionata.id))})"

        BindUtils.postNotifyChange(null, null, this, "dettagliFiltro")
        BindUtils.postNotifyChange(null, null, this, "titoloDettaglio")
    }


    private invalidaListaDettagli() {
        try {
            (self.getFellow("lstbDettagli")
                    as Listbox)
                    .invalidate()
        } catch (Exception e) {
            log.info "lstbDettagli non caricata."
        }
    }

    private void caricaDettagliSelezionati() {
        dettagliSelezionati = [:]
        caricaTuttiDettagli().findAll { it.flagSelezionato }.each { dettagliSelezionati[it.id] = true }
        selezioneDettagliPresente()
        BindUtils.postNotifyChange(null, null, this, "dettagliSelezionati")
    }

    private def caricaTuttiDettagli() {
        return elaborazioniService.listaDettagliSoloId(elaborazioneSelezionata.id,
                [
                        max       : Long.MAX_VALUE,
                        offset    : 0,
                        activePage: 0
                ])
    }

    private def selezioneDettagliPresente() {
        selezioneDettagliPresente = (dettagliSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selezioneDettagliPresente")
        return selezioneDettagliPresente
    }

    private resetDettagliSelezionati() {
        dettagliSelezionati = [:]
        selezioneDettagliPresente = false
        BindUtils.postNotifyChange(null, null, this, "dettagliSelezionati")
        BindUtils.postNotifyChange(null, null, this, "selezioneDettagliPresente")
    }

    private boolean documentiNonGenerati() {
        def docNonGenerati = false
        def dettSelCollate = dettagliSelezionati.findAll { it.value }.collect { it.key }.collate(500)
        for (def dettagli in dettSelCollate) {
            docNonGenerati = DettaglioElaborazioneDocumento.countByIdInListAndDocumentoIsNull(
                    dettagli
            ) > 0

            if (docNonGenerati) {
                break
            }
        }

        if (docNonGenerati) {
            Clients.showNotification("Non e' possibile procedere all'invio, esistono documenti per i quali non è stato generato il documento."
                    , Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return docNonGenerati
    }

    private def controlloATDettaglio(Long dettaglioId) {

        List<DettaglioElaborazione> dettagli = []
        DettaglioElaborazione dettaglio

        dettaglio = DettaglioElaborazione.get(dettaglioId)
        dettagli << dettaglio

        Long attivitaId = dettaglio.controlloAtId ?: 0
        AttivitaElaborazione attivita = AttivitaElaborazione.get(attivitaId)

        if (attivita == null) {
            throw new Exception("ATTENZIONE : Impossibile ricavare attivita' di 'Controllo Anagrafe Tributaria' originale (${attivitaId}). Impossiible procedere !!")
        }

        String result = allineamentoAnagrafeTributariaService.controlloAT(dettagli, attivita)

        if (result.isEmpty()) {
            String message = "Controllo Anagrafe Tributaria completato con successo"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            if (result.size() > 1000) {
                result = result.substring(0, 1000)
                result += "\n. . . Altri errori . . .\n"
            }
            String message = "Rilevate anomalie di controllo : \n\n" + result
            Messagebox.show(message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        }

        dettaglio.refresh()
    }

    private def controllaSoggettiCorrenti() {

        // Verifiche specifiche per l'esportazione
        def cliente = springSecurityService.principal
        if (!cliente.amministrazione.soggetto.codiceFiscale) {

            Clients.showNotification(
                    "E' necessario valorizzare la tabella AS4_V_SOGGETTI_CORRENTI.",
                    Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    private abilitazioneFunzioni(def elab) {
        def funzioniElaborazioni = [
                creaElaborazioneAT: elab.tipoElaborazione?.id != ElaborazioniService.TIPO_ELABORAZIONE_ANAGRAFE_TRIBUTARIA
        ]
        elab.funzioniElaborazioni = funzioniElaborazioni

        def funzioniRiga = [:]
        elab.tipoElaborazione?.tipiAttivitaElaborazione?.each { tipoAttivitaElaborazione ->
            def tipoAttivita = tipoAttivitaElaborazione.tipoAttivita
            switch (tipoAttivita.id) {
                case ElaborazioniService.TIPO_ATTIVITA_GENERA_DOCUMENTI:
                    funzioniRiga.generaDocumenti = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_ALLEGA_AVVISO_AGID:
                    funzioniRiga.allegaAvvisoAgid = dePagAbilitato
                    break
                case ElaborazioniService.TIPO_ATTIVITA_INVIO_A_TIPOGRAFIA:
                    funzioniRiga.elaboraPerTipografia = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_INVIO_A_DOCUMENTALE:
                    funzioniRiga.inviaADocumentale = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_INVIO_APPIO:
                    funzioniRiga.inviaAppIO = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_GENERA_ANGR_TRIB:
                    funzioniRiga.esportaAT = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_CONTROLLA_ANGR_TRIB:
                    funzioniRiga.controllaAT = true
                    break
                case ElaborazioniService.TIPO_ATTIVITA_ALLINEAMENTO_ANGR_TRIB:
                    funzioniRiga.allineamentoAT = true
                    break
            }
        }
        // Funzione eliminazione
        funzioniRiga.eliminaElab = elaborazioniService.abilitaEliminaElaborazione(elab.id)

        elab.funzioniRiga = funzioniRiga
    }

    private parametriModelliStampa() {
        def tipoElaborazione = elaborazioneSelezionata.tipoElaborazione.id

        // Per le massive si disabilita alcune funzionalità
        def parametri = [:]

        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE) {
            parametri += [
                    tipoStampa : ModelliService.TipoStampa.PRATICA,
                    idDocumento: DettaglioElaborazione.findByElaborazione(
                            ElaborazioneMassiva.get(elaborazioneSelezionata.id)
                    ).pratica.id
            ]
        } else if (tipoElaborazione in [ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA, ElaborazioniService.TIPO_ELABORAZIONE_RUOLI]) {
            def tipoTributo = elaborazioneSelezionata.tipoTributo.tipoTributo
            if (tipoTributo in ['ICI', 'TASI', 'CUNI', 'ICP', 'TOSAP']) {
                parametri += [

                        tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                        idDocumento: [
                                tipoTributo: tipoTributo,
                                ruolo      : 0,
                                anno       : elaborazioneSelezionata.anno,
                                codFiscale : '',
                                pratica    : -1
                        ]
                ]
            } else if (tipoTributo in ['TARSU']) {

                parametri += [
                        tipoStampa : ModelliService.TipoStampa.COMUNICAZIONE,
                        idDocumento: [
                                ruolo      : elaborazioneSelezionata.ruolo,
                                tipoTributo: tipoTributo,
                                anno       : elaborazioneSelezionata.anno,
                                codFiscale : ''
                        ]
                ]
            }
        } else if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_LETTERA_GENERICA) {
            parametri += [
                    tipoStampa: ModelliService.TipoStampa.LETTERA_GENERICA
            ]
        }

        return parametri
    }

    def esisteRecordSamRisposte(def attivitaId) {

        return elaborazioniService.esisteRecordSamRisposte(attivitaId)

    }

}

