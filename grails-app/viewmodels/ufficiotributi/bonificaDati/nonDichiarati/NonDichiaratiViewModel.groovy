package ufficiotributi.bonificaDati.nonDichiarati

import document.FileNameGenerator
import groovy.json.JsonSlurper
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.bonificaDati.nonDichiarati.BonificaNonDichiaratiService
import it.finmatica.tr4.catasto.VisuraService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.datiesterni.CatastoCensuarioService
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window
import sportello.contribuenti.SituazioneContribuenteParametri

class NonDichiaratiViewModel {

    Window self

    private final String SIT_CONTR = "SIT_CONTR"

	CompetenzeService competenzeService
    ImposteService imposteService
    BonificaNonDichiaratiService bonificaNonDichiaratiService
    ContribuentiService contribuentiService
    CatastoCensuarioService catastoCensuarioService
    IntegrazioneWEBGISService integrazioneWEBGISService
    VisuraService visuraService

    boolean abilitaSelezioneMultipla = false
    boolean abilitaMappe = false

	boolean modifica = false

    //////////////////////////////////////////////////
    // Generali

    List<Short> listaAnni
    Short anno

    def listaDiritti
    def listaDirittiSelezionati

    //////////////////////////////////////////////////
    // Soggetti

    def listaSoggetti
    def listaSoggettiCompleta

    def listaSoggettiCatasto

    def pagingSoggetti = [
            activePage: 0,
            pageSize  : 15,
            totalSize : 0
    ]

    def filtri = [
            cognome     : "",
            nome        : "",
            codFiscale  : "",
            idSoggetto  : null,
            tipoSoggetto: -1,
            tipoImmobile: "E"
    ]
    def filtroSoggettiAttivo = false

    def soggettoSelezionato
    def soggettiSelezionati = [:]
    def presenzaSoggettiSelezionati = false

    //////////////////////////////////////////////////
    // Oggetti

    def listaOggetti
    def listaOggettiCompleta

    def pagingOggetti = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    def filtriOggetti = [
            immobile    : null,
            sezione     : "",
            foglio      : "",
            numero      : "",
            subalterno  : "",
            zona        : "",
            partita     : "",
            categoria   : "",
            classe      : "",
            indirizzo   : "",
            numCivDa    : "",
            numCivA     : "",
            numCivTipo  : "E",
            tipoImmobile: "E"
    ]
    def filtroOggettiAttivo = false

    def oggettoSelezionato
    def oggettiSelezionati = [:]
    def presenzaOggettiSelezionati = false

    def cbTributi
    def cbTipiPratica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        caricaParametri()

        soggettoSelezionato = null
        oggettoSelezionato = null

		modifica = ((competenzeService.tipoAbilitazioneUtente('ICI') == 'A') ||
					(competenzeService.tipoAbilitazioneUtente('TASI') == 'A'))
		
        abilitaSelezioneMultipla = true
        abilitaMappe = integrazioneWEBGISService.integrazioneAbilitata()

        listaAnni = imposteService.getListaAnni()
        listaDiritti = bonificaNonDichiaratiService.getCodiciDiritto()

        listaDirittiSelezionati = []
        listaDiritti.each {

            if (it.preChecked != 0) {
                listaDirittiSelezionati << it
            }
        }


        openCloseFiltriSoggetti()
    }

    /// Sezione filtri ##########################################################################################################################

    @NotifyChange("listaDirittiSel")
    @Command
    onSelectDiritto() {

    }

    String getListaDirittiSel() {

        listaDirittiSelezionati?.codDiritto?.join(", ")
    }

    /// Sezione soggetti ##########################################################################################################################

    @Command
    openCloseFiltriSoggetti() {

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/nonDichiarati/nonDichiaratiSoggettiRicerca.zul", self, [filtri: filtri])
        w.onClose { event ->
            if (event.data) {

                filtri = event.data.filtri
                filtroSoggettiAttivo()

                onRefreshSoggetti()
            }
        }
        w.doModal()
    }

    private def filtroSoggettiAttivo() {

        filtroSoggettiAttivo = filtri ? ((filtri.cognome) || (filtri.nome) || (filtri.codFiscale) ||
                (filtri.idSoggetto != null) || (filtri.tipoSoggetto != -1)) : false

        BindUtils.postNotifyChange(null, null, this, "filtroSoggettiAttivo")
    }

    @Command
    def onRefreshSoggetti() {
        listaSoggettiCompleta = null
        caricaSoggetti(true)
        resetSoggettiSelezionati()
    }

    @Command
    def onPagingSoggetti() {

        caricaSoggetti()
    }

    @Command
    def onSelezionaSoggetto() {
        listaOggettiCompleta = null
        svuotaFiltriOggetto()
        filtroOggettiAttivo = false
        caricaOggetti(true)
        resetOggettiSelezionati()
        BindUtils.postNotifyChange(null, null, this, "filtroOggetti")
        BindUtils.postNotifyChange(null, null, this, "filtroOggettiAttivo")
    }

    @Command
    def onModificaSoggetto() {

        def ni = soggettoSelezionato?.ni

        if ((ni != null) && (ni > 0)) {

            Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
        }
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("cf") String cf) {
        def ni = Contribuente.findByCodFiscale(cf)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onCheckSoggetto(@BindingParam("sogg") def soggetto) {

        presenzaSoggettiSelezionati()
    }

    @Command
    def onCheckSoggetti() {

        presenzaSoggettiSelezionati()

        soggettiSelezionati = [:]

        // nessuna selezione -> selezionare tutti
        if (!presenzaSoggettiSelezionati) {

            def parRicerca = completaRicercaSoggetti()
            def elencoSoggetti = bonificaNonDichiaratiService.getSoggettiConNonDichiarati(parRicerca)
            def soggettiCompleta = elencoSoggetti.records

            soggettiCompleta.each {
                soggettiSelezionati << [(it.idSoggetto): true]
            }
        }

        presenzaSoggettiSelezionati()

        BindUtils.postNotifyChange(null, null, this, "soggettiSelezionati")
    }

    @Command
    def onInserimentoOggettiRenditeSoggetti() {

        def elencoSoggetti = []
        soggettiSelezionati.each {
            if (it.value != false) {
                elencoSoggetti << (it.key as BigDecimal)
            }
        }
        def numSoggetti = elencoSoggetti.size()

        String messaggio = "Inserire le rendite di tutti gli immobili "
        if (numSoggetti > 1) {
            messaggio += "dei ${numSoggetti} soggetti selezionati?"
        } else {
            messaggio += "del soggetto selezionato ?"
        }
        messaggio += "\n\nL'operazione potrebbe richiedere parecchio tempo!"

        Messagebox.show(messaggio, "Inserimento Oggetto/Rendite massivo",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            inserimentoOggettiRenditeSoggetti()
                        }
                    }
                }
        )
    }

    private inserimentoOggettiRenditeSoggetti() {

        def parRicerca = completaRicercaSoggetti()
        def soggettiNonDichiaranti = bonificaNonDichiaratiService.getSoggettiConNonDichiarati(parRicerca)
        def soggettiCompleta = soggettiNonDichiaranti.records

        def elencoSoggetti = []
        soggettiSelezionati.each {
            if (it.value != false) {
                elencoSoggetti << (it.key as BigDecimal)
            }
        }

        def soggettiDaElaborare = soggettiCompleta.findAll {
            it.idSoggetto in elencoSoggetti
        }

        listaSoggetti = []
        soggettiDaElaborare.each {

            def soggetto = [:]

            soggetto.idSoggetto = it.idSoggetto
            soggetto.codFiscale = it.codFiscale

            listaSoggetti << soggetto
        }

        inserimentoOggettiRenditeDaListe(listaSoggetti, null)
    }

    private resetSoggettiSelezionati() {

        soggettiSelezionati = [:]
        presenzaSoggettiSelezionati = false
        BindUtils.postNotifyChange(null, null, this, "soggettiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "presenzaSoggettiSelezionati")
    }

    private void caricaSoggetti(def resetPaginazione = false) {

        def completa = false
        if (resetPaginazione) {
            pagingSoggetti.activePage = 0
        }

        def parRicerca = completaRicercaSoggetti()

        //Calcolo tutti i soggetti
        if (pagingSoggetti.activePage == 0) {

            if (listaSoggettiCompleta == null) {
                completa = true
                def elencoSoggetti = bonificaNonDichiaratiService.getSoggettiConNonDichiarati(parRicerca, pagingSoggetti.pageSize, pagingSoggetti.activePage)
                listaSoggettiCompleta = elencoSoggetti.records
            }

            pagingSoggetti.totalSize = listaSoggettiCompleta.size()
            listaSoggetti = (pagingSoggetti.totalSize < pagingSoggetti.pageSize) ? listaSoggettiCompleta : listaSoggettiCompleta.subList(0, pagingSoggetti.pageSize - 1)

            if (completa) {
                listaSoggettiCatasto = [:]
                //Controllo dei soggetti collegati al catasto che hanno immobili non dichiarati
                def listaSoggettiCF = listaSoggettiCompleta.codFiscale
                if (listaSoggettiCF) {

                    def listaCF = catastoCensuarioService.getListaAssegnazioniSoggettoCatasto().contribuente.codFiscale

                    listaSoggettiCF?.each {

                        def esisteContribuente = listaCF.find { c -> c == it }
                        if (esisteContribuente) {

                            def lista = catastoCensuarioService.getListaAssegnazioniSoggettoCatasto().findAll { c -> c.contribuente.codFiscale == it }.id_soggetto

                            def elencoSoggettiLegati = bonificaNonDichiaratiService.getSoggettiLegatiNonDichiarati(parRicerca, it)

                            if (elencoSoggettiLegati?.totalCount > 0) {
                                listaSoggettiCatasto.put(it, elencoSoggettiLegati.records)
                            }
                        }
                    }
                }
            }
        } else {

            int soggettiDa = pagingSoggetti.activePage * pagingSoggetti.pageSize - 1
            int soggettiA = ((pagingSoggetti.activePage * pagingSoggetti.pageSize) + pagingSoggetti.pageSize - 1)

            if (soggettiA > pagingSoggetti.totalSize) {
                soggettiA = pagingSoggetti.totalSize
            }

            listaSoggetti = listaSoggettiCompleta.subList(soggettiDa, soggettiA)
        }

        // Se era selezionato una ravvedimento lo riseleziona nel caso di modifiche per permettere a ZK di evidenziare la riga
        def soggettoSelezionatoNew = null
        if (soggettoSelezionato) {
            soggettoSelezionatoNew = listaSoggetti?.find {
                it.idSoggetto == soggettoSelezionato?.idSoggetto
            }
        }
        soggettoSelezionato = soggettoSelezionatoNew

        if (soggettoSelezionato) {
            svuotaFiltriOggetto()
            filtroOggettiAttivo = false
            caricaOggetti(true)
        } else {
            listaOggetti = null
            presenzaOggettiSelezionati = false
            oggettoSelezionato = null
            resetOggettiSelezionati()
            pagingOggetti.activePage = 0
            pagingOggetti.totalSize = 0
        }

        BindUtils.postNotifyChange(null, null, this, "presenzaOggettiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "soggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pagingSoggetti")
        BindUtils.postNotifyChange(null, null, this, "listaSoggetti")
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
        BindUtils.postNotifyChange(null, null, this, "pagingOggetti")
        BindUtils.postNotifyChange(null, null, this, "filtriOggetti")
        BindUtils.postNotifyChange(null, null, this, "filtroOggettiAttivo")
        BindUtils.postNotifyChange(null, null, this, "anno")
    }

    ///
    /// *** Completa filtri per ricerca soggetti
    ///
    private completaRicercaSoggetti() {

        def parRicerca = filtri

        parRicerca.anno = (anno == null) ? 9999 : anno

        parRicerca.diritti = []
        if (listaDirittiSelezionati) {

            listaDirittiSelezionati.each {
                parRicerca.diritti << it.codDiritto
            }
        }

        return parRicerca
    }

    private void presenzaSoggettiSelezionati() {
        presenzaSoggettiSelezionati = (soggettiSelezionati.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "presenzaSoggettiSelezionati")
    }

    private svuotaFiltriOggetto() {
        filtriOggetti.immobile = null
        filtriOggetti.sezione = ""
        filtriOggetti.foglio = ""
        filtriOggetti.numero = ""
        filtriOggetti.subalterno = ""
        filtriOggetti.zona = ""
        filtriOggetti.partita = ""
        filtriOggetti.classe = ""
        filtriOggetti.indirizzo = ""
        filtriOggetti.numCivDa = ""
        filtriOggetti.numCivA = ""
        filtriOggetti.numCivTipo = 'E'        // 'P', 'D' oppure 'E'
    }

    @Command
    def onStampaVisura() {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.VISURA,
                [:])

        def codFiscale = soggettoSelezionato.codFiscale

        def reportVisura = visuraService.generaVisura(codFiscale)

        if (reportVisura == null) {
            Clients.showNotification("In catasto non risultano unita' immobiliari per il contribuente.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {

            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", reportVisura.toByteArray())
            Filedownload.save(amedia)
        }
    }

    @Command
    void onDenunciaDaCatasto() {

        def codFiscale = soggettoSelezionato.codFiscale

        creaPopup("/pratiche/denunce/denunciaDaCatasto.zul",
                [
                        codFiscale: codFiscale
                ],
                {
                    onRefreshSoggetti()
                }
        )
    }

    @Command
    listToXls(@BindingParam("totale") int totale) throws Exception {

        def listaPerExport = []

        if (totale != 0) {

            def parRicerca = completaRicercaSoggetti()
            def elencoSoggetti = bonificaNonDichiaratiService.getSoggettiConNonDichiarati(parRicerca)
            listaPerExport = elencoSoggetti.records
        } else {
            listaPerExport = listaSoggetti
        }

        Map fields = [
                "idSoggetto"     : "ID Soggetto",
                "cognomeNome"    : "Cognome e Nome",
                "codFiscale"     : "Cod.Fiscale / P.IVA",
                "codFiscaleContr": "Cod.Fiscale / P.IVA Contr.",
                "sede"           : "Sede",
                "luogoNascita"   : "Nato a",
                "dataNascita"    : "Il",
                "contribuente"   : "Contr."
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.SOGGETTI_NON_DICHIARANTI,
                [anno: anno])

        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields)
    }

    /// Sezione Oggetti ##########################################################################################################################
    @Command
    openCloseFiltriOggetti() {

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/nonDichiarati/nonDichiaratiRicerca.zul", self, [filtri: filtriOggetti])
        w.onClose { event ->
            if (event.data) {

                filtriOggetti = event.data.filtri
                filtroOggettiAttivo()

                onRefreshOggetti()
            }
        }
        w.doModal()
    }

    private def filtroOggettiAttivo() {

        filtroOggettiAttivo = filtriOggetti ? ((filtriOggetti.immobile != null) ||
                (filtriOggetti.sezione) || (filtriOggetti.foglio) || (filtriOggetti.numero) ||
                (filtriOggetti.subalterno) || (filtriOggetti.zona) || (filtriOggetti.partita) ||
                ((filtriOggetti.categoria != null) && (filtriOggetti.categoria != "")) || (filtriOggetti.classe) ||
                (filtriOggetti.indirizzo) || (filtriOggetti.numCivDa) || (filtriOggetti.numCivA) ||
                (filtriOggetti.numCivTipo != "E") || (filtriOggetti.tipoImmobile != "E")) : false

        BindUtils.postNotifyChange(null, null, this, "filtroOggettiAttivo")
    }

    @Command
    def onPagingOggetti() {

        caricaOggetti()
    }

    @Command
    def onRefreshOggetti() {
        listaOggettiCompleta = null
        caricaOggetti(true)
        resetOggettiSelezionati()
    }

    @Command
    def onSelezionaOggetto() {

    }

    @Command
    def onCheckOggetto(@BindingParam("ogge") def oggetto) {

        presenzaOggettiSelezionati()
    }

    @Command
    def onCheckOggetti() {
        //Se sono stati visualizzati gli oggetti
        if (listaOggetti) {
            presenzaOggettiSelezionati()

            oggettiSelezionati = [:]
            // nessuna selezione -> selezionare tutti
            if (!presenzaOggettiSelezionati) {

                listaOggettiCompleta.each {
                    oggettiSelezionati << [(it.idImmobile): true]
                }
            }

            presenzaOggettiSelezionati()
            BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
        }

    }

    @Command
    def onInserimentoOggettiRendite() {

        def idImmobile = oggettoSelezionato.idImmobile
        def idOggetto = oggettoSelezionato.idOggetto
        def tipoImmobile = oggettoSelezionato.tipoImmobile

        inserimentoOggettiRendite(idImmobile, idOggetto, tipoImmobile)
    }

    @Command
    def onInserimentoOggettiRenditeMassivo() {

        def elencoOggetti = []
        oggettiSelezionati.each {
            if (it.value != false) {
                elencoOggetti << (it.key as BigDecimal)
            }
        }
        def numOggetti = elencoOggetti.size()

        String messaggio = "Inserire le rendite "
        if (numOggetti > 1) {
            messaggio += "dei ${numOggetti} immobili selezionati?"
        } else {
            messaggio += "dell'immobile selezionato?"
        }
        messaggio += "\n\nL'operazione potrebbe richiedere diverso tempo!"

        Messagebox.show(messaggio, "Inserimento Oggetto/Rendite massivo",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            inserimentoOggettiRenditeMassivo()
                        }
                    }
                }
        )
    }

    @Command
    def onInserisciOggetti() {

        String codFiscale = soggettoSelezionato.codFiscale
        String codFiscaleContr = soggettoSelezionato?.codFiscaleContr ?: codFiscale

        def filtriCatasto = [
                codFis           : codFiscale,
                anno             : anno,
                soggettiCollegati: []
        ]

        def elencoImmobili = []
        if (presenzaOggettiSelezionati) {
            oggettiSelezionati.each {
                if (it.value != false) {
                    elencoImmobili << (it.key as BigDecimal)
                }
            }
        } else {
            listaOggetti.each { elencoImmobili << (it.idImmobile as BigDecimal) }
        }

        def oggettiDaCatasto = catastoCensuarioService.getOggettiCatastoUrbano(filtriCatasto)
        def immobiliInCatasto = oggettiDaCatasto.findAll {
            it.IDIMMOBILE in elencoImmobili
        }

        def tipiTributo = cbTributi.clone()
        def tipiPratica = cbTipiPratica.clone()

        Window w = Executions.createComponents("/archivio/oggettiContribuente.zul", self, [
                azione     : 'INSERISCI',
                dati       : [oggetti: immobiliInCatasto, codFiscale: codFiscaleContr],
                zul        : '/sportello/contribuenti/situazioneContribuenteOggettiCatasto.zul',
                annoFiltro : anno,
                tipiTributo: tipiTributo,
                tipiPratica: tipiPratica
        ])

        w.onClose() { event ->
            if (event.data?.oggettiChiusi) {
                onRefreshOggetti()
            }
        }
        w.doModal()
    }

    @Command
    def onVisualizzaMappa() {

        def elencoOggetti = []

        listaOggetti.each {

            def oggetto = [:]
            def idOggetto = it.idImmobile

            def oggettoInElenco = elencoOggetti.find { it.idOggetto == idOggetto }

            if (oggettoInElenco == null) {

                oggetto.idOggetto = it.idImmobile
                oggetto.tipoOggetto = it.tipoImmobile
                oggetto.sezione = it.sezione
                oggetto.foglio = it.foglio
                oggetto.numero = it.numero
                oggetto.subalterno = it.subalterno
                oggetto.estremiCatastoSort = it.estremiCatasto
                oggetto.partita = it.partita
                oggetto.categoriaCatasto = it.categoria
                oggetto.classeCatasto = it.classe
                oggetto.zona = it.zona
                oggetto.indirizzoCompleto = it.indirizzo
                oggetto.indirizzoCompletoSort = it.indirizzo

                oggetto.protocolloCatasto = ""
                oggetto.annoCatasto = ""

                elencoOggetti << oggetto
            }
        }

        Window w = Executions.createComponents("/archivio/oggettiWebGis.zul", self,
                [oggetti: elencoOggetti,
                 zul    : '/archivio/oggettiWebGisArchivio.zul'])
        w.doModal()
    }

    private resetOggettiSelezionati() {

        oggettiSelezionati = [:]
        presenzaOggettiSelezionati = false
        BindUtils.postNotifyChange(null, null, this, "oggettiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "presenzaOggettiSelezionati")
    }

    private void caricaOggetti(def resetPaginazione = false) {

        if (resetPaginazione) {
            pagingOggetti.activePage = 0
        }

        def parRicerca = completaRicercaOggetti()

        //Calcolo tutti gli oggetti
        if (pagingOggetti.activePage == 0) {

            if (listaOggettiCompleta == null) {
                def elencoOggetti = bonificaNonDichiaratiService.getOggettiNonDichiarati(parRicerca, soggettoSelezionato, pagingOggetti.pageSize, pagingOggetti.activePage)
                listaOggettiCompleta = elencoOggetti.records
            }

            pagingOggetti.totalSize = listaOggettiCompleta.size()
            listaOggetti = (pagingOggetti.totalSize < pagingOggetti.pageSize) ? listaOggettiCompleta : listaOggettiCompleta.subList(0, pagingOggetti.pageSize - 1)
        } else {

            int oggettiDa = pagingOggetti.activePage * pagingOggetti.pageSize - 1
            int oggettiA = (pagingOggetti.activePage * pagingOggetti.pageSize) + pagingOggetti.pageSize - 1

            if (oggettiA > pagingOggetti.totalSize) {
                oggettiA = pagingOggetti.totalSize
            }

            listaOggetti = listaOggettiCompleta.subList(oggettiDa, oggettiA)
        }

        // Se era selezionato una ravvedimento lo riseleziona nel caso di modifiche per permettere a ZK di evidenziare la riga
        def oggettoSelezionatoNew = null
        if (oggettoSelezionato) {
            oggettoSelezionatoNew = listaOggetti.find {
                it.idImmobile == oggettoSelezionato?.idImmobile
            }
        }
        oggettoSelezionato = oggettoSelezionatoNew

        BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pagingOggetti")
        BindUtils.postNotifyChange(null, null, this, "listaOggetti")
    }

    ///
    /// *** Completa filtri per ricerca Oggetti
    ///
    private completaRicercaOggetti() {

        def parRicerca = filtriOggetti

        parRicerca.idSoggetto = (soggettoSelezionato?.idSoggetto != null) ? soggettoSelezionato.idSoggetto : 0

        if (soggettoSelezionato) {
            def lista = listaSoggettiCatasto.get(soggettoSelezionato?.codFiscale)?.idSoggetto
            if (lista) {
                lista.each() {
                    parRicerca.idSoggetto += " , " + it
                }
                parRicerca.idSoggetto += " , " + soggettoSelezionato.idSoggetto
            }
        }

        parRicerca.anno = (anno == null) ? 9999 : anno

        parRicerca.diritti = []
        if (listaDirittiSelezionati) {

            listaDirittiSelezionati.each {
                parRicerca.diritti << it.codDiritto
            }
        }

        return parRicerca
    }

    private inserimentoOggettiRendite(def idImmobile, def idOggetto, def tipoImmobile) {

        if (idOggetto == 0) idOggetto = null

        creaPopup("/catasto/inserimentoOggettiRendite.zul",
                [
                        immobile    : idImmobile,
                        oggetto     : idOggetto,
                        tipoImmobile: tipoImmobile
                ],
                { e ->
                    if (e?.data?.esito) {

                        onRefreshOggetti()
                    }
                }
        )
    }

    private inserimentoOggettiRenditeMassivo() {

        String idSoggetto = soggettoSelezionato.idSoggetto
        String codFiscale = soggettoSelezionato.codFiscale

        def elencoImmobili = []
        oggettiSelezionati.each {
            if (it.value != false) {
                elencoImmobili << (it.key as BigDecimal)
            }
        }

        def listaSoggetti = []
        listaSoggetti << [idSoggetto: idSoggetto, codFiscale: codFiscale]

        inserimentoOggettiRenditeDaListe(listaSoggetti, elencoImmobili)
    }

    def inserimentoOggettiRenditeDaListe(def listaSoggetti, def elencoImobili) {

        def elencoSoggetti = []
        listaSoggetti.each {

            it.idSoggetto = (it.idSoggetto as BigDecimal)
            elencoSoggetti << it.idSoggetto
        }

        def parRicerca = completaRicercaOggetti().clone()
        parRicerca.idSoggetto = null
        parRicerca.idSoggetti = elencoSoggetti
        parRicerca.immobili = elencoImobili

        def immobiliDaElaborare = bonificaNonDichiaratiService.preparaListaImmobili(parRicerca, listaSoggetti)
        def totaleImmobili = immobiliDaElaborare.totaleImmobili
        def listaImmobili = immobiliDaElaborare.listaImmobili

        creaPopup("/ufficiotributi/bonificaDati/nonDichiarati/nonDichiaratiRendita.zul",
                [
                        totale  : totaleImmobili,
                        immobili: listaImmobili
                ],
                { e ->
                    onRefreshOggetti()
                }
        )
    }

    private void presenzaOggettiSelezionati() {

        presenzaOggettiSelezionati = (oggettiSelezionati.find { k, v -> v } != null)
        if (!presenzaOggettiSelezionati) {
            oggettoSelezionato = null
            BindUtils.postNotifyChange(null, null, this, "oggettoSelezionato")
        }
        BindUtils.postNotifyChange(null, null, this, "presenzaOggettiSelezionati")
    }

    ///
    /// Carica i paramtetri attivi dalla sezione contribuenti
    ///
    private caricaParametri() {

        SituazioneContribuenteParametri scp
        JsonSlurper jsonSlurper = new JsonSlurper()

        def parametro = contribuentiService.leggiParametroUtente(SIT_CONTR)

        if (parametro) {
            scp = jsonSlurper.parseText(parametro.valore)
        } else {
            scp = new SituazioneContribuenteParametri()
        }

        cbTributi = scp.cbTributi
        cbTipiPratica = scp.cbTipiPratica

        def annoString = scp.annoOggetti ?: 'Tutti'
        if (annoString == 'Tutti') {
            def now = Calendar.instance
            anno = now.get(Calendar.YEAR) - 1
        } else {
            anno = annoString.toShort()
        }
    }

    ///
    /// Crea un popup
    ///
    private void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }
}
