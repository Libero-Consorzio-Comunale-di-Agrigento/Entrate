package ufficiotributi.datiesterni

import document.FileNameGenerator
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.dto.datiesterni.FornituraAEDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAE
import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAEG1
import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAEG5
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listbox
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.DecimalFormat

class FornitureAEViewModel {

    private Logger log = LoggerFactory.getLogger(FornitureAEViewModel.class)

    Window self

    // services
    def springSecurityService
    TributiSession tributiSession

    DatiGeneraliService datiGeneraliService
    FornitureAEService fornitureAEService

    CommonService commonService

    int selectedTab = 0

    def listProgrDoc = []
    def progrDocSelezionato = null
    def listPorzioni = []
    def porzioneSelezionata = null

    Boolean flagProvincia = false

    /// Filtri G1/D
    FiltroRicercaFornitureAEG1 filtriListG1
    boolean filtroAttivoListG1 = false
    boolean filtroEstesoListG1 = false

    /// Paginazione G1/D
    def pagingListG1 = [
            activePage: 0,
            pageSize  : 30,
            totalSize : 0
    ]

    /// Forniture G1/D
    def listaFornitureG1 = []

    def fornituraG1Selezionata = null
    def selectedForniture = [:]
    def selectedAnyFornitura = false

    /// Filtri G5/M
    FiltroRicercaFornitureAEG5 filtriListG5
    boolean filtroAttivoListG5 = false

    /// Paginazione G5/M
    def pagingListG5 = [
            activePage: 0,
            pageSize  : 30,
            totalSize : 0
    ]

    /// Forniture G5/M
    def listaFornitureG5 = []

    def fornituraG5Selezionata = null

    /// Forniture Provincia (D + M)
    /// Per non duplicare tutto (variabili e codice) che sarbebbe quasi uguale
    /// riutilizziamo quelli del G1, modificando dove serve i filtri e le definizioni
    /// usando il flagProvincia come discriminante
    /// Per i ZUL :
    /// - nel G1 si modificano alcune etichette e colonne
    /// - il G5 viene sostituito dall'M, i filtri rimangono gli stessi del G5
    
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        flagProvincia = datiGeneraliService.flagProvinciaAbilitato()

        listProgrDoc = [
                [codice: null, descrizione: '']
        ]

        def elencoCodici = []

        def elencoProgrDoc = fornitureAEService.getListaProgrDocPerFornitureAE(elencoCodici, flagProvincia)
        elencoProgrDoc.each {
            listProgrDoc << it
        }

        if (!tributiSession.filtroRicercaFornitureAE)
            tributiSession.filtroRicercaFornitureAE = new FiltroRicercaFornitureAE()
        FiltroRicercaFornitureAE filtroFornitureAE = tributiSession.filtroRicercaFornitureAE
        filtriListG1 = filtroFornitureAE.getFiltroG1()
        filtriListG5 = filtroFornitureAE.getFiltroG5()

        Long progrDoc = filtroFornitureAE.progrDocG1 ?: -1
        progrDocSelezionato = listProgrDoc.find { it.codice == progrDoc }

        if (progrDocSelezionato) {
            onCambioDocumentoId()
        }

        onSelectTabs()
    }

    /// Sezione comune #####################################################################################

    @Command
    def onSelectTabs() {

        switch (selectedTab) {
            case 0: /// G1 / D
                aggiornafiltroAttivoListG1()
                break
            case 1: /// G5
            case 2: /// M
                aggiornafiltroAttivoListG5()
                if (filtroAttivoListG5) {
                    caricaListaG5(true)
                } else {
                    onOpenFiltriListaG5()
                }
                break
        }
    }

    /// Elenco forniture G1 #################################################################################

    @Command
    def onCambioDocumentoId() {

        def progrDoc = progrDocSelezionato?.codice ?: 0
        tributiSession.filtroRicercaFornitureAE.progrDocG1 = progrDoc

        def elencoPorzioni = fornitureAEService.getPorzioniForniture(progrDoc, flagProvincia)

        listPorzioni = []
        listPorzioni << null
        elencoPorzioni.each {
            listPorzioni << it
        }

        String porzioneDoc = tributiSession.filtroRicercaFornitureAE.porzioneDocG1

        porzioneSelezionata = null
        if (porzioneDoc) {
            porzioneSelezionata = elencoPorzioni.find { it.codice == porzioneDoc }
        }
        if (porzioneSelezionata == null) {
            porzioneSelezionata = listPorzioni[0]
        }
        BindUtils.postNotifyChange(null, null, this, "porzioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listPorzioni")

        onRicaricaListaG1()
    }

    @Command
    def onCambioPorzione() {

        tributiSession.filtroRicercaFornitureAE.porzioneDocG1 = porzioneSelezionata?.codice

        onRicaricaListaG1()
    }

    @Command
    def onRicaricaListaG1() {

        try {
            (self.getFellow("fornitureAEG1").getFellow("listBoxFornitureG1")
                    as Listbox)
                    .invalidate()
        } catch (Exception e) {
            log.info "gridSitContrOggetti non caricata."
        }

        aggiornafiltroAttivoListG1()

        caricaListaG1(true)
    }

    @Command
    def onCambioPagina() {

        caricaListaG1(false)
    }

    @Command
    def onFornituraSelected() {

    }

    @Command
    def onCheckFornitura(@BindingParam("detail") def detail) {

        selectedAnyFornituraRefresh()
    }

    @Command
    def onCheckAllForniture() {

        selectedForniture = [:]

        if (!selectedAnyFornitura) {

            def filtriNow = completaFiltriG1()
            def totaleForniture = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
            def elencoForniture = totaleForniture.lista

            elencoForniture.each() { it -> (selectedForniture << [(it.dto.progressivo): true]) }
        }

        BindUtils.postNotifyChange(null, null, this, "selectedForniture")
        selectedAnyFornituraRefresh()
    }

    @Command
    def onModificaFornitura() {

        Boolean modificabile = true

        FornituraAEDTO fornituraDTO = fornituraG1Selezionata.dto

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/dettaglioFornituraAE.zul", self,
                [fornitura: fornituraDTO, ifel: false, modificabile: modificabile, duplica: false])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaG1(false)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onDuplicaFornitura() {

        Boolean modificabile = true

        FornituraAEDTO fornituraDTO = fornituraG1Selezionata.dto

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/dettaglioFornituraAE.zul", self,
                [fornitura: fornituraDTO, ifel: false, modificabile: modificabile, duplica: true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaG1(false)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onModificaFornituraIFEL(@BindingParam("arg") def fornitura) {

        Boolean modificabile = true

        FornituraAEDTO fornituraDTO = fornitura.dto

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/dettaglioFornituraAE.zul", self,
                [fornitura: fornituraDTO, ifel: true, modificabile: modificabile, duplica: false])
        w.onClose { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaG1(false)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onOpenFiltriListaG1() {

        def progrDoc = progrDocSelezionato?.codice

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/fornitureAERicerca.zul", self,
                [
                        filtri       : filtriListG1,
                        progrDoc     : progrDoc,
                        flagProvincia: flagProvincia
                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "cerca") {

                    filtriListG1 = event.data.filtri
                    tributiSession.filtroRicercaFornitureAE.setFiltroG1(filtriListG1)
                    aggiornafiltroAttivoListG1()

                    caricaListaG1(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onAssociaSosspesoContabilita() {

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/associazioneContabile.zul", self, [:])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    associaContabilita(event.data.impostazioni)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onEseguiQuadraturaVersamenti() {

        def ripartizione = porzioneSelezionata

        String msg = fornitureAEService.eseguiEmissioneRiepilogoProvvisori(ripartizione)
        if (msg == null) msg = ''

        if (!(msg.isEmpty())) {
            Messagebox.show(msg, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
            Short result = fornitureAEService.eseguiQuadraturaVersamenti(ripartizione)
            if (result != 0) {
                Messagebox.show("Quaratura errata !", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
            } else {
                Clients.showNotification("Quadratura corretta", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

                onVisualizzaQuadraturaVersamenti()
            }
        }
    }

    @Command
    def onVisualizzaQuadraturaVersamenti() {

        Boolean modificabile = false

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/fornitureAEQuadratura.zul", self,
                [porzione: porzioneSelezionata, modificabile: modificabile])
        w.onClose() { event ->
            if (event.data) {
                if (event.data.aggiornaStato != false) {
                    caricaListaG1(false)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onFornitureToXls() {

        DecimalFormat fmtValuta = new DecimalFormat("€ #,##0.00")

        def progrDoc = (progrDocSelezionato?.codice != null) ? progrDocSelezionato.codice as String : '0000'

        def filtriNow = completaFiltriG1()
        def totaleForniture = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
        def elencoForniture = totaleForniture.lista

        def intestazione = [
                "Forniture AE": progrDocSelezionato?.descrizione ?: '-'
        ]

        def fields = [:]
        if(filtroEstesoListG1) {
            fields << [
                'documento'        : 'Documento',
            ]
        }
        fields << [
                'progressivo'      : 'Progr.',
                'dataFornitura'    : 'Data Fornitura',
                'progrFornitura'   : 'Progr.Fornitura',
                'dataRipartizione' : 'Data Ripartizione',
                'progrRipartizione': 'Progr.Ripartizione',
                'dataBonifico'     : 'Data Bonifico',
        ]
        if(flagProvincia) {
            fields << [
                'enteComunale'     : 'Ente',
            ]
        }
        else {
            fields << [
                'codFiscale'       : 'Cod.Fiscale',
                'flagErrCodFiscale': 'Err.C.F.',
                'dataRiscossione'  : 'Data Risc.',
            ]
        }
        fields << [
                'codTributo'       : 'Cod.Tributo',
                'flagErrCodTributo': 'Err.C.T.',
                'rateazione'       : 'Rateazione',
                'annoRif'          : 'Anno Rif.',
                'flagErrAnno'      : 'Err.A.Rif.',
                'importoDebito'    : 'Imp.Debito',
                'importoCredito'   : 'Imp.Credito',
                'ravvedimento'     : 'Ravvedimento',
                'descrTributo'     : 'Tributo',
                'idOperazione'     : 'ID Operazione',
                'annoAcc'          : 'Anno Acc.Cont.',
                'numeroAcc'        : 'Numero Acc.Cont.',
                'numeroProvvisorio': 'Numero Provv.',
                'dataProvvisorio'  : 'Data Provv.',
                'importoLordo'     : 'Imp.Lordo',
        ]

        Integer xlsRigheMax = Integer.MAX_VALUE

        def datiDaEsportare = []
        def datiOriginali = []
        def datoDaEsportare

        def righeTotali = elencoForniture.size()

        datiOriginali = elencoForniture

        datiOriginali.each {

            datoDaEsportare = [:]

            FornituraAEDTO dto = it.dto

            datoDaEsportare.documento = dto.documentoCaricato.id
            datoDaEsportare.progressivo = dto.progressivo
            datoDaEsportare.progrFornitura = dto.progrFornitura
            datoDaEsportare.progrRipartizione = dto.progrRipartizione
            datoDaEsportare.codFiscale = dto.codFiscale
            datoDaEsportare.enteComunale = it.enteComunale
            datoDaEsportare.codTributo = dto.codTributo
            datoDaEsportare.rateazione = it.rateazione
            datoDaEsportare.annoRif = dto.annoRif
            datoDaEsportare.descrTributo = it.descrTributo
            datoDaEsportare.idOperazione = dto.idOperazione
            datoDaEsportare.annoAcc = dto.annoAcc
            datoDaEsportare.numeroAcc = dto.numeroAcc
            datoDaEsportare.numeroProvvisorio = dto.numeroProvvisorio

            datoDaEsportare.dataFornitura = dto.dataFornitura
            datoDaEsportare.dataRipartizione = dto.dataRipartizione
            datoDaEsportare.dataBonifico = dto.dataBonifico
            datoDaEsportare.dataRiscossione = dto.dataRiscossione
            datoDaEsportare.dataProvvisorio = dto.dataProvvisorio

            datoDaEsportare.flagErrCodFiscale = (dto.flagErrCodFiscale != 0) ? 'S' : 'N'
            datoDaEsportare.flagErrCodTributo = (dto.flagErrCodTributo != 0) ? 'S' : 'N'
            datoDaEsportare.flagErrAnno = (dto.flagErrAnno != 0) ? 'S' : 'N'
            datoDaEsportare.ravvedimento = (dto.ravvedimento != 0) ? 'S' : 'N'

            datoDaEsportare.importoDebito = dto.importoDebito as Double
            datoDaEsportare.importoCredito = dto.importoCredito as Double
            datoDaEsportare.importoNetto = dto.importoNetto as Double
            datoDaEsportare.importoIfel = dto.importoIfel as Double
            datoDaEsportare.importoLordo = dto.importoLordo as Double

            datiDaEsportare << datoDaEsportare
        }

        def parametriFilename = [:]

        if(filtroEstesoListG1) {
            parametriFilename << [date: false]
        }
        else {
            parametriFilename << [progressivo: progrDoc]
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                (flagProvincia) ? FileNameGenerator.GENERATORS_TITLES.FORNITURA_AED :
                                    FileNameGenerator.GENERATORS_TITLES.FORNITURA_AEG1,
                parametriFilename)

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields)
    }

    /// Funzioni interne G1 #################################################################################

    ///
    /// *** Verifica impostazioni filtro G1
    ///
    def aggiornafiltroAttivoListG1() {

        filtroAttivoListG1 = filtriListG1.isDirty()
        filtroEstesoListG1 = filtriListG1.isExtended()

        if(filtroEstesoListG1) {
            progrDocSelezionato = null
            porzioneSelezionata = null
            BindUtils.postNotifyChange(null, null, this, "progrDocSelezionato")
            BindUtils.postNotifyChange(null, null, this, "porzioneSelezionata")
        }

        BindUtils.postNotifyChange(null, null, this, "filtroAttivoListG1")
        BindUtils.postNotifyChange(null, null, this, "filtroEstesoListG1")
    }

    ///
    /// Associa provvisorio a elementi selezionati G1
    ///
    def associaContabilita(def impostazioni) {

        def progDoc = progrDocSelezionato?.codice ?: 0

        List<Integer> forniture = []
        selectedForniture.each { k, v ->
            if (v != false) forniture << (k as Integer)
        }

        def report = fornitureAEService.associaContabilita(progDoc as Integer, forniture, impostazioni.accertamento, 
                                                                        impostazioni.togliAccTributo,impostazioni.provvisorio, 
                                                                                                    impostazioni.togliProvvisorio)

        if (report.result != 0) {
            Messagebox.show(report.message, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
        } else {
		    String message = "Operazione completata."
		    if(!flagProvincia) message += "\n\nSara\' necessario rieseguire la quadratura!";
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 10000, true)
        }

        caricaListaG1(false)

        return
    }

    ///
    /// *** Rilegge elenco forniture G1
    ///
    private def caricaListaG1(boolean resetPaginazione) {

        try {
            (self.getFellow("fornitureAEG1").getFellow("listBoxFornitureG1")
                    as Listbox)
                    .invalidate()
        } catch (Exception e) {
            log.info "listBoxFornitureG1 non caricata."
        }

        if (resetPaginazione) {
            pagingListG1.activePage = 0
        }

        def filtriNow = completaFiltriG1()
        def totaleForniture = fornitureAEService.listaForniture(filtriNow, pagingListG1.pageSize, pagingListG1.activePage)
        listaFornitureG1 = totaleForniture.lista
        pagingListG1.totalSize = totaleForniture.totale

        if (resetPaginazione) {
            selectedFornitureReset()
        }

        BindUtils.postNotifyChange(null, null, this, "pagingListG1")
        BindUtils.postNotifyChange(null, null, this, "listaFornitureG1")
        BindUtils.postNotifyChange(null, null, this, "porzioneSelezionata")
    }

    ///
    /// *** Completa il filtro per la ricerca G1
    ///
    def completaFiltriG1() {

        def filtri = filtriListG1.prepara()

        filtri.tipoRecord = (flagProvincia) ? 'D' : 'G1'

        if(filtriListG1.isExtended()) {
            /// Filtro esteso: ignora sempre progrDocSelezionato e porzioneSelezionata
        }
        else {
            filtri.progDoc = progrDocSelezionato?.codice ?: -1

            if (porzioneSelezionata != null) {
                filtri.dataFornitura = porzioneSelezionata.dataFornitura
                filtri.progFornitura = porzioneSelezionata.progFornitura
                filtri.dataRipartizione = porzioneSelezionata.dataRipartizione
                filtri.progRipartizione = porzioneSelezionata.progRipartizione
                filtri.dataBonifico = porzioneSelezionata.dataBonifico
            } else {
                filtri.dataFornitura = null
                filtri.progFornitura = null
                filtri.dataRipartizione = null
                filtri.progRipartizione = null
                filtri.dataBonifico = null
            }
        }

        return filtri
    }

    ///
    /// Svuota elenco selezione G1 multipla
    ///
    def selectedFornitureReset() {

        selectedForniture = [:]
        BindUtils.postNotifyChange(null, null, this, "selectedForniture")
        selectedAnyFornituraRefresh()
    }

    ///
    /// Ricalcola flag global selezione G1 multipla
    ///
    def selectedAnyFornituraRefresh() {

        selectedAnyFornitura = (selectedForniture.find { k, v -> v } != null)
        BindUtils.postNotifyChange(null, null, this, "selectedAnyFornitura")
    }

    /// Elenco forniture G5 #################################################################################

    @Command
    def onRicaricaListaG5() {

        try {
            (self.getFellow("fornitureAEG1").getFellow("listBoxFornitureG5")
                    as Listbox)
                    .invalidate()
        } catch (Exception e) {
            log.info "gridSitContrOggetti non caricata."
        }

        aggiornafiltroAttivoListG5()

        caricaListaG5(true)
    }

    @Command
    def onCambioPaginaG5() {

        caricaListaG5(false)
    }

    @Command
    def onFornituraG5Selected() {

    }

    @Command
    def onOpenFiltriListaG5() {

        Window w = Executions.createComponents("/ufficiotributi/datiesterni/fornitureAEG5Ricerca.zul", self, [filtri: filtriListG5])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "cerca") {

                    filtriListG5 = event.data.filtri
                    tributiSession.filtroRicercaFornitureAE.setFiltroG5(filtriListG5)
                    aggiornafiltroAttivoListG5()

                    caricaListaG5(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onFornitureG5ToXls() {

        DecimalFormat fmtValuta = new DecimalFormat("€ #,##0.00")

        def filtriNow = completaFiltriG5()
        def totaleForniture = fornitureAEService.listaForniture(filtriNow, Integer.MAX_VALUE, 0)
        def elencoForniture = totaleForniture.lista

        String titolo

        if (flagProvincia) {
            titolo = 'Metadati TEFA'
        } else {
            titolo = 'Identificazioni accredito'
        }

        def intestazione = [
                "Forniture AE": titolo
        ]

        def fields = [:]

        if (flagProvincia) {
            fields << [
                    'documentoId'           : 'Documento',
                    'progressivo'           : 'Progr.',
                    'dataFornitura'         : 'Data Fornitura',
                    'progrFornitura'        : 'Progr.Fornitura',
                    'enteProvinciale'       : 'Provincia',
                    'descrTributo'          : 'Tributo',
                    'importoAccredito'      : 'Imp.Accredito',
                    'dataRipartizione'      : 'Data Rip.',
                    'progrRipartizione'     : 'Prog.Rip.',
                    'dataBonifico'          : 'Data Bonifico',
                    'numeroContoTu'         : 'Conto T.U.',
                    'codMovimento'          : 'Codice Operazione',
                    'dataMandato'           : 'Data Mandato'
            ]
        }
        else {
            fields << [
                    'documentoId'           : 'Documento',
                    'progressivo'           : 'Progr.',
                    'dataFornitura'         : 'Data Fornitura',
                    'progrFornitura'        : 'Progr.Fornitura',
                    'stato'                 : 'Cod.Stato',
                    'desStato'              : 'Des.Stato',
                    'codEnteComunale'       : 'Codice Ente',
                    'importoAccredito'      : 'Imp.Accredito',
                    'cro'                   : 'C.R.O.',
                    'dataAccreditamento'    : 'Data Accr.',
                    'dataRipartizioneOrig'  : 'Data Rip.Orig.',
                    'progrRipartizioneOrig' : 'Prog. Rip.Orig.',
                    'dataBonificoOrig'      : 'Data Bon.Orig.',
                    'descrTributo'          : 'Tributo',
                    'iban'                  : 'IBAN',
                    'sezioneContoTu'        : 'Sezione T.U.',
                    'numeroContoTu'         : 'Conto T.U.',
                    'codMovimento'          : 'Codice Operazione',
                    'desMovimento'          : 'Descrizione',
                    'dataStornoScarto'      : 'Data Storno/Scarto',
                    'dataElaborazioneNuova' : 'Data Elaborazione',
                    'progrElaborazioneNuova': 'Progr.Elaborazione',
            ]
        }

        def parameters = [
                "intestazione"   : intestazione,
                title            : titolo,
                "title.font.size": "12"
        ]

        Integer xlsRigheMax = Integer.MAX_VALUE

        def datiDaEsportare = []
        def datiOriginali = []
        def datoDaEsportare
        def datoPerErrore = null

        def righeTotali = elencoForniture.size()

        datiOriginali = elencoForniture

        datiOriginali.each {

            datoDaEsportare = [:]

            FornituraAEDTO dto = it.dto

            datoDaEsportare.documentoId = dto.documentoCaricato.id

            datoDaEsportare.progressivo = dto.progressivo
            datoDaEsportare.progrFornitura = dto.progrFornitura
            datoDaEsportare.progrRipartizione = dto.progrRipartizione

            datoDaEsportare.progressivo = dto.progressivo
            datoDaEsportare.dataFornitura = dto.dataFornitura
            datoDaEsportare.progrFornitura = dto.progrFornitura
            datoDaEsportare.stato = dto.stato
            datoDaEsportare.desStato = it.desStato
            datoDaEsportare.codEnteComunale = dto.codEnteComunale
            datoDaEsportare.cro = dto.cro as String
            datoDaEsportare.dataAccreditamento = dto.dataAccreditamento
            datoDaEsportare.dataRipartizione = dto.dataRipartizione
            datoDaEsportare.progrRipartizione = dto.progrRipartizione
            datoDaEsportare.dataBonifico = dto.dataBonifico
            datoDaEsportare.dataRipartizioneOrig = dto.dataRipartizioneOrig
            datoDaEsportare.progrRipartizioneOrig = dto.progrRipartizioneOrig
            datoDaEsportare.dataBonificoOrig = dto.dataBonificoOrig
            datoDaEsportare.descrTributo = it.descrTributo
            datoDaEsportare.iban = (dto.iban ?: '').trim()
            datoDaEsportare.sezioneContoTu = dto.sezioneContoTu
            datoDaEsportare.numeroContoTu = dto.numeroContoTu
            datoDaEsportare.codMovimento = dto.codMovimento as String
            datoDaEsportare.desMovimento = (dto.desMovimento ?: '').trim()
            datoDaEsportare.dataStornoScarto = dto.dataStornoScarto
            datoDaEsportare.dataElaborazioneNuova = dto.dataElaborazioneNuova
            datoDaEsportare.progrElaborazioneNuova = dto.progrElaborazioneNuova
            datoDaEsportare.enteProvinciale = it.enteProvinciale
            datoDaEsportare.dataMandato = dto.dataMandato

            datoDaEsportare.importoAccredito = dto.importoAccredito as Double

            datiDaEsportare << datoDaEsportare
        }

        if (datoPerErrore != null) {
            datiDaEsportare << datoPerErrore
        }

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                (flagProvincia) ? FileNameGenerator.GENERATORS_TITLES.FORNITURA_AEM :
                                    FileNameGenerator.GENERATORS_TITLES.FORNITURA_AEG5,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare, fields)

    }

    /// Funzioni interne G5 #################################################################################

    ///
    /// *** Verifica impostazioni filtro
    ///
    def aggiornafiltroAttivoListG5() {

        filtroAttivoListG5 = filtriListG5.isDirty()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoListG5")
    }

    ///
    /// *** Rilegge elenco forniture G5/M
    ///
    private def caricaListaG5(boolean resetPaginazione) {

        if (flagProvincia) {
            try {
                (self.getFellow("fornitureAEM").getFellow("listBoxFornitureM")
                        as Listbox)
                        .invalidate()
            } catch (Exception e) {
                log.info "listBoxFornitureM non caricata."
            }
        } else {
            try {
                (self.getFellow("fornitureAEG5").getFellow("listBoxFornitureG5")
                        as Listbox)
                        .invalidate()
            } catch (Exception e) {
                log.info "listBoxFornitureG5 non caricata."
            }
        }

        if (resetPaginazione != false) {
            pagingListG5.activePage = 0
        }

        def filtriNow = completaFiltriG5()
        def totaleForniture = fornitureAEService.listaForniture(filtriNow, pagingListG5.pageSize, pagingListG5.activePage)
        listaFornitureG5 = totaleForniture.lista
        pagingListG5.totalSize = totaleForniture.totale

        if (resetPaginazione != false) {
            selectedFornitureReset()
        }

        BindUtils.postNotifyChange(null, null, this, "pagingListG5")
        BindUtils.postNotifyChange(null, null, this, "listaFornitureG5")
        BindUtils.postNotifyChange(null, null, this, "porzioneSelezionata")
    }

    ///
    /// *** Completa il filtro per la ricerca
    ///
    def completaFiltriG5() {

        def filtri

        if(flagProvincia) {
            filtri = filtriListG5.preparaTipoM()
        }
        else {
            filtri = filtriListG5.prepara()
            filtri.tipoRecord = 'G5'
        }

        return filtri
    }

    /// Funzioni interne M #################################################################################

}
