package ufficiotributi.versamenti

import document.FileNameGenerator
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.WrkVersamenti
import it.finmatica.tr4.bonificaDati.versamenti.BonificaVersamentiService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tributiminori.CanoneUnicoService
import it.finmatica.tr4.versamenti.CampiOrdinamento
import it.finmatica.tr4.versamenti.FiltroRicercaVersamenti
import it.finmatica.tr4.versamenti.VersamentiService
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.OpenEvent
import org.zkoss.zk.ui.event.SortEvent
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.servlet.ServletContext
import java.text.DecimalFormat
import java.text.SimpleDateFormat

class ElencoVersamentiViewModel {

    // componenti
    Window self

    // services
    def springSecurityService
    ServletContext servletContext
    JasperService jasperService
    VersamentiService versamentiService
    TributiSession tributiSession
    CommonService commonService
    CompetenzeService competenzeService
    DatiGeneraliService datiGeneraliService
    BonificaVersamentiService bonificaVersamentiService
	CanoneUnicoService canoneUnicoService
    Ad4EnteService ad4EnteService

    // dati
    def lista
    def selected
    def totali

    // ricerca
    boolean nonDeceduti = false
    boolean deceduti = false
    boolean ricercaAnnullata = false
    def ordinamento
    FiltroRicercaVersamenti parRicerca

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    boolean filtroAttivo = false

    String tipoTributo
    def tipoTributoAttuale
    def tipoAbilitazione = CompetenzeService.TIPO_ABILITAZIONE.LETTURA

    def listaDettaglioAnomalie = null
    def numBonifiche = 0
    def dettaglioAnomaliaSelezionato
    def sortDettagliBy = null
    def anci = false

    def tipiRavvedimento = [
            'null': 'Non trattato',
            'N'   : 'Ravv. su Versamento',
            'O'   : 'Ravv. su Omessa Denuncia',
            'I'   : 'Ravv. su Infedele Denuncia'
    ]

    def pagingAnomalie = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    Boolean anomalieOpened = true
    def sizeQuadroAnomalie

    def cbTributiInScrittura = [:]

    //Definiamo i vari pannell con competenza di lettura default a true
    Map caricaPannello = [ICI  : [zul: "/ufficiotributi/versamenti/versamentiImu.zul", lettura: true],
                          TASI : [zul: "/ufficiotributi/versamenti/versamentiTasi.zul", lettura: true],
                          TARSU: [zul: "/ufficiotributi/versamenti/versamentiTari.zul", lettura: true],
                          ICP  : [zul: "/ufficiotributi/versamenti/versamentiIcp.zul", lettura: true],
                          TOSAP: [zul: "/ufficiotributi/versamenti/versamentiTosap.zul", lettura: true],
                          CUNI : [zul: "/ufficiotributi/versamenti/versamentiCuni.zul", lettura: true]
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("tipoTributo") String tt) {

        this.self = w

        tipoTributo = tt
        tipoTributoAttuale = TipoTributo.findByTipoTributo(tipoTributo)?.tipoTributoAttuale
        ordinamento = [tipo: CampiOrdinamento.ALFA, ascendente: true]

        this.sizeQuadroAnomalie = "30%"

        // Settiamo la competenza di Lettura/Scrittura in funzione alle competenze
        tipoAbilitazione = competenzeService.tipoAbilitazioneUtente(tipoTributo)
        caricaPannello."${tipoTributo}".lettura = (tipoAbilitazione == CompetenzeService.TIPO_ABILITAZIONE.LETTURA)

        parRicerca = tributiSession.filtroRicercaVersamenti ?: new FiltroRicercaVersamenti()
        filtroAttivo = verificaCampiFiltranti()

        if (filtroAttivo) {
            caricaLista(false)
        } else {
            openCloseFiltri()
        }

        inizializzaCompetenze()
    }

    @NotifyChange(["selected"])
    @Command
    onRefresh() {
        caricaLista(false)
        selected = null
    }

    @NotifyChange(["activePage"])
    @Command
    onCerca() {
        activePage = 0
        caricaLista(false)
        selected = null
    }

    @Command
    def onNuovoVersamento() {

        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
                self,
                [filtri: null, listaVisibile: true, ricercaSoggCont: true]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Soggetto") {
                    nuovoVersamentoSuSoggetto(event.data.Soggetto)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onModificaVersamento() {

        gestioneVersamento(false, false)
    }

    @Command
    openCloseFiltri() {
        Window w = Executions.createComponents("/ufficiotributi/versamenti/elencoVersamentiRicerca.zul", self, [tipoTributo: tipoTributo, parRicerca: parRicerca])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicerca = event.data.parRicerca
                    tributiSession.filtroRicercaVersamenti = parRicerca
                    ricercaAnnullata = false
                    onCerca()
                }
                if (event.data.status == "Chiudi") {
                    ricercaAnnullata = true
                }
            }
            filtroAttivo = verificaCampiFiltranti()
            BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        }
        w.doModal()
    }

    @Command
    onCheckOrdinamento(@BindingParam("valore") String valore) {
        ordinamento.tipo = CampiOrdinamento.getAt(valore)
        ordinamento.ascendente = true
        caricaLista(false)
    }

    @Command
    onChangeStato(@BindingParam("valore") String valore) {
        deceduti = (valore == "Deceduti")
        nonDeceduti = (valore == "Non deceduti")
        activePage = 0
        caricaLista(false)
    }

    @Command
    onChangeOrdinamento(@ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("valore") String valore) {
        ordinamento.tipo = CampiOrdinamento.getAt(valore)
        ordinamento.ascendente = event.isAscending()
        caricaLista(false)
    }

    @Command
    onExportXls() {

        Map fields
        def converters = [
                anno: Converters.decimalToInteger,
                rata: Converters.decimalToInteger,
                ruolo: Converters.decimalToInteger
        ]

        if (tipoTributo != "TARSU") {
            converters << [numBollettino: Converters.decimalToInteger]
        }

        if (tipoTributo == "TARSU" || tipoTributo == 'ICP' || tipoTributo == 'TOSAP' || tipoTributo == 'CUNI') {
            converters << [provvedimento: Converters.decimalToInteger]
        }

        if (tipoTributo == 'ICI') {

            fields = [
                    "contribuente"        : "Contribuente",
                    "codFiscale"          : "Cod.Fiscale",
                    "pratica"             : "Pratica",
                    "tipoPratica"         : "T.Prat.",
                    "anno"                : "Anno",
                    "tipoVersamento"      : "T.Vers.",
                    "rata"                : "Rata",
                    "importoVersato"      : "Imp. Versato",
                    "dataPagamento"       : "Data Pag.",
                    "documentoId"         : "Progr.Doc.",
                    "dataReg"             : "Data Reg.",
                    "fabbricati"          : "Fab.",
                    "terreniAgricoli"     : "Terreni Agr.",
                    "areeFabbricabili"    : "Aree Fabbr.",
                    "abPrincipale"        : "Ab. Principale",
                    "altriFabbricati"     : "Altri Fabbr.",
                    "detrazione"          : "Detrazione",
                    "fonte.fonte"         : "Fonte",
                    "terreniComune"       : "Terreni Comune",
                    "terreniErariale"     : "Terreni Stato",
                    "areeComune"          : "Aree Comune",
                    "areeErariale"        : "Aree Stato",
                    "rurali"              : "Fabbr. Rurali",
                    "ruraliComune"        : "Fabbr. Rurali Comune",
                    "ruraliErariale"      : "Fabbr. Rurali Stato",
                    "altriComune"         : "Altri Fabbr. Comune",
                    "altriErariale"       : "Altri Fabbr. Stato",
                    "fabbricatiD"         : "Fabbr.Uso Prod.",
                    "fabbricatiDComune"   : "Fabbr. D Comune",
                    "fabbricatiDErariale" : "Fabbr. D Stato",
                    "numFabbricatiAb"     : "Num. Fabbr. Ab.",
                    "numFabbricatiRurali" : "Num. Fabbr. Rur.",
                    "numFabbricatiAltri"  : "Num. Fabbr. Altri",
                    "numFabbricatiTerreni": "Num. Fabbr. Ter.",
                    "numFabbricatiAree"   : "Num. Fabbr. Aree",
                    "numFabbricatiD"      : "Num. Fabbr. D"
            ]

        } else if (tipoTributo == 'TASI') {

            fields = [
                    "contribuente"       : "Contribuente",
                    "codFiscale"         : "Cod.Fiscale",
                    "pratica"            : "Pratica",
                    "tipoPratica"        : "T.Prat.",
                    "anno"               : "Anno",
                    "tipoVersamento"     : "T.Vers.",
                    "rata"               : "Rata",
                    "importoVersato"     : "Imp. Versato",
                    "dataPagamento"      : "Data Pag.",
                    "documentoId"        : "Progr.Doc.",
                    "dataReg"            : "Data Reg.",
                    "fabbricati"         : "Fab.",
                    "areeFabbricabili"   : "Aree Fabbr.",
                    "abPrincipale"       : "Ab. Principale",
                    "rurali"             : "Fabbr. Rurali",
                    "altriFabbricati"    : "Altri Fabbr.",
                    "detrazione"         : "Detrazione",
                    "fonte.fonte"        : "Fonte",
                    "numFabbricatiAree"  : "Num. Fabbr. Aree",
                    "numFabbricatiAb"    : "Num. Fabbr. Ab.",
                    "numFabbricatiRurali": "Num. Fabbr. Rur.",
                    "numFabbricatiAltri" : "Num. Fabbr. Altri"
            ]
        } else if (tipoTributo == 'TARSU') {

            fields = [
                    "contribuente"               : "Contribuente",
                    "codFiscale"                 : "Cod.Fiscale",
                    "pratica"                    : "Pratica",
                    "tipoPratica"                : "T.Prat.",
                    "anno"                       : "Anno",
                    "rata"                       : "Rata",
                    "importoVersato"             : "Imp. Versato",
                    "impostaVersato"             : "Imposta",
                    "ruolo"                      : "Ruolo",
                    "numBollettino"              : "N. Bollettino",
                    "addizionalePro"             : "Add.Pro.",
                    "sanzioniVers"               : "Sanzioni",
                    "interessiVers"              : "Interessi",
                    "sanzioniAddPro"             : "Sanz.Add.Pro",
                    "interessiAddPro"            : "Int.Add.Pro",
                    "speseSpedizione"            : "Spese Spedizione",
                    "speseMora"                  : "Spese Mora",
                    "maggiorazioneTares"         : "C.Pereq.",
                    "dataPagamento"              : "Data Pag.",
                    "fonte.fonte"                : "Fonte",
                    "documentoId"                : "Progr. Doc.",
                    "dataReg"                    : "Data Reg.",
                    "importoDovuto"              : "Importo Dovuto",
                    "imposta"                    : "Imposta",
                    "addizionaleMaggiorazioneECA": "ECA",
                    "addizionaleProvinciale"     : "Prov.",
                    "magTar"                     : "C.Pereq.",
                    "sanzioni"                   : "Sanzioni",
                    "interessi"                  : "Interessi",
                    "importoRidotto"             : "Importo Ridotto",
                    "impostaRidotta"             : "Imposta Ridotta",
                    "sanzioniRidotte"            : "Sanzioni Ridotte",
                    "spese"                      : "Spese",
                    "statoPratica"               : "Stato Pratica",
                    "compensazione"              : "Compensazione",
                    "descrizione"                : "Descrizione",
                    "provvedimento"              : "Provvedimento",
                    "ufficioPt"                  : "Ufficio PT",
                    "causale"                    : "Causale",
                    "note"                       : "Note",
                    "fattura"                    : "N. Fattura",
                    "utente"                     : "Utente",
                    "dataVariazione"             : "Data Var.",
            ]
        } else if (tipoTributo == 'ICP' || tipoTributo == 'TOSAP' || tipoTributo == 'CUNI') {

            fields = [
                    "contribuente"     : "Contribuente",
                    "codFiscale"       : "Cod.Fiscale",
                    "pratica"          : "Pratica",
                    "tipoPratica"      : "T.Prat.",
                    "anno"             : "Anno",
                    "rata"             : "Rata",
                    "importoVersato"   : "Imp. Versato",
                    "ruolo"            : "Ruolo",
                    "numBollettino"    : "N. Bollettino",
                    "dataPagamento"    : "Data Pag.",
                    "imposta"          : "Imposta",
                    "sanzioni1"        : "Sanzioni",
                    "interessi"        : "Interessi",
                    "dataRegistrazione": "Data Reg.",
                    "speseSpedizione"  : "Spese Spediz.",
                    "speseMora"        : "Spese Mora",
                    "fonte.fonte"      : "Fonte",
                    "documentoId"      : "Progr.Doc.",
                    "descrizione"      : "Descrizione",
                    "provvedimento"    : "Provvedimento",
                    "ufficioPt"        : "Ufficio PT",
                    "causale"          : "Causale",
                    "note"             : "Note",
                    "fattura"          : "N. Fattura",
                    "utente"           : "Utente",
                    "dataVariazione"   : "Data Var.",
            ]
        }

        //Esegue la ricerca
        caricaLista(true)

        XlsxExporter.exportAndDownload("Versamenti_${TipoTributo.get(tipoTributo).toDTO().tipoTributoAttuale}",
                lista, fields, converters
        )
    }

    /// Interfaccia utente Anomalie #####################################################################################

    @Command
    onRefreshAnomalie() {

        caricaListaAnomalie(false)
        dettaglioAnomaliaSelezionato = null
    }

    @Command
    def onDettagliAnomaliaSort(
            @ContextParam(ContextType.TRIGGER_EVENT) SortEvent event, @BindingParam("property") String property) {

        sortDettagliBy = [property: property, direction: event.ascending ? 'asc' : 'desc']
        onRefreshAnomalie()
    }

    @Command
    def onCambiaStatoAnomalia(@BindingParam("anomaliaSelezionata") def anom) {

        if ((anom.tipoTributo) && (cbTributiInScrittura[anom.tipoTributo] == true)) {
            bonificaVersamentiService.cambiaStato("F24", anom)
            BindUtils.postNotifyChange(null, null, anom, "flagOk")
        }
    }

    @Command
    def onDettaglioVersato(@BindingParam("anomaliaSelezionata") def anom) {

        WrkVersamenti versamento = WrkVersamenti.findByProgressivo(new BigDecimal(anom.id))

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/versamentoDettaglioPopup.zul",
                self,
                [
                        versamento: versamento
                ])

        w.doModal()
    }

    @Command
    def onCorreggiAnomalia(@BindingParam("anomaliaSelezionata") def anom) {

        Boolean lettura = (tipoAbilitazione != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)

        Window w = Executions.createComponents("/ufficiotributi/bonificaDati/versamenti/bonificaVersamento.zul",
                self,
                [id         : dettaglioAnomaliaSelezionato.id,
                 tipoIncasso: "F24",
                 lettura    : lettura
                ])
        w.onClose { event ->
            onRefreshAnomalie()
        }
        w.doModal()
    }

    @Command
    def onEliminaVersamento(@BindingParam("anomaliaSelezionata") def anom) {

        String messaggio = "Eliminazione della registrazione?"

        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            bonificaVersamentiService.eliminaVersamento("F24", anom)
                            onRefreshAnomalie()
                            Clients.showNotification("Versamento eliminato correttamente.", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                        }
                    }
                }
        )
    }

    @Command
    def onApriCaricaArchivi() {

        def readOnly = false

        String codFiscale = (parRicerca.cf ?: '')
        if (codFiscale.isEmpty()) codFiscale = '%'

        def tipiTributo = [:]
        def tt = null

        competenzeService.tipiTributoUtenza().each {
            tipiTributo << [(it.tipoTributo): it.tipoTributoAttuale + ' - ' + it.descrizione]
        }

        tt = tipiTributo.find {
            it.key == tipoTributo
        }

        commonService.creaPopup("/ufficiotributi/bonificaDati/versamenti/bonificaVersamentiCaricaArchivi.zul",
                self,
                [tipoTributo: tt,
                 tipoIncasso: "F24",
                 readOnly   : readOnly,
                 codFiscale : codFiscale
                ],
                { event ->
                    onRefresh()
                }
        )
    }

    @Command
    def onApriAnomalie(@BindingParam("event") def event) {

        OpenEvent evt = (OpenEvent) event
        aggiornaQuadroAnomalie(evt.isOpen())
    }

    @Command
    def onExportAnomalieXls() {

        def listaAnomalie = leggiListaAnomalie(true)
        if (listaAnomalie.numeroRecord == 0) {
            return
        }

        def fields = [
                flagOk              : "Stato",
                anno                : "Anno",
                tributoAttuale      : "Tributo",
                tipoAnomalia        : "Anomalia",
                codFiscale          : "Cod. Fiscale",
                cognomeNome         : "Cognome Nome",
                codFiscaleSogg      : "Cod.Fiscale Sogg.",
                cognomeNomeSogg     : "Cognome Nome Sogg.",
                dataPagamento       : "Data Pagamento",
                importoVersato      : "Importo Versato",
                flagCont            : "Cont.",
                flagRavvedimento    : "Ravv.",
                sanzioneRavvedimento: "Sanz.Ravv.",
                progressivo         : "Prg."
        ]

        def converters = [
                flagOk          : Converters.flagBooleanToString,
                flagCont        : Converters.flagBooleanToString,
                flagRavvedimento: Converters.flagBooleanToString
        ]

        XlsxExporter.exportAndDownload("bonifica_versamenti_dettaglio_${(new Date()).format('yyyyMMdd')}", listaAnomalie.record, fields, converters)
    }

    @Command
    def onVersamentiDoppi() {

        commonService.creaPopup("/ufficiotributi/versamenti/stampeVersamenti.zul", self,
                [
                        titolo: "Versamenti Doppi"
                ],
                { event ->
                    if (event.data?.anno != null) {
                        stampaVersamentiDoppi(event.data.anno, event.data?.ordinamento ?: "alfa")
                    }
                })

    }

    @Command
    def onSquadraturaTotale() {
        commonService.creaPopup("/ufficiotributi/versamenti/stampeVersamenti.zul", self,
                [
                        tipoStampa: "SQ",
                        titolo    : "Squadratura Totale"
                ],
                { event ->
                    if (event.data?.anno != null && event.data?.ordinamento) {
                        stampaSquadraturaTotale(event.data?.codFiscale, event.data.anno, event.data?.scarto, event.data.ordinamento)
                    }
                })
    }

    @Command
    def onTotaleVersamenti() {
        commonService.creaPopup("/ufficiotributi/versamenti/stampeVersamenti.zul", self,
                [
                        tipoStampa: "TV",
                        titolo    : "Totale Versamenti"
                ],
                { event ->
                    if (event.data?.anno != null) {
                        stampaTotaleVersamenti(event.data.anno)
                    }
                })
    }

    @Command
    def onTotaleVersamentiPerGiorno() {
        commonService.creaPopup("/ufficiotributi/versamenti/stampeVersamenti.zul", self,
                [
                        tipoStampa: "TVG",
                        titolo    : "Totale Versamenti per Giorno"
                ],
                { event ->
                    if (event.data?.dal != null && event.data?.al != null && event.data?.ordinamento) {
                        stampaTotaleVersamentiPerGiorno(event.data.dal, event.data.al, event.data.ordinamento)
                    }
                })
    }

    /// Codice interno versamenti #########################################################################################

    private def nuovoVersamentoSuSoggetto(def soggetto) {

        if (soggetto) {
			Contribuente contribuente = canoneUnicoService.creaContribuente(soggetto);
            nuovoVersamento(tipoTributo, contribuente.codFiscale)
        }
    }

    private def nuovoVersamento(String tributo, String codFiscale) {

        Short annoNow = Calendar.getInstance().get(Calendar.YEAR) as Short

        creaPopup("/versamenti/versamento.zul",
                [
                        codFiscale : codFiscale,
                        tipoTributo: tributo,
                        anno       : annoNow,
                        sequenza   : 0,
                        lettura    : false,
                        trasferisci: false
                ],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            caricaLista(false)
                        }
                    }
                }
        )
    }

    private def gestioneVersamento(Boolean lettura, Boolean trasferisci) {

        creaPopup("/versamenti/versamento.zul",
                [
                        codFiscale : selected.codFiscale,
                        tipoTributo: tipoTributo,
                        anno       : selected.anno,
                        sequenza   : selected.sequenza,
                        lettura    : lettura,
                        trasferisci: trasferisci
                ],
                { event ->
                    if (event.data) {
                        if (event.data.aggiornaStato != false) {
                            caricaLista(false)
                        }
                    }
                }
        )
    }

    private void caricaLista(boolean wholeList) {
        def documenti

        preparaParametriRicerca()

        switch (tipoTributo) {
            case "ICI":
                documenti = versamentiService.listaVersamentiImuTasi(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            case "TASI":
                documenti = versamentiService.listaVersamentiImuTasi(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            case "TARSU":
                documenti = versamentiService.listaVersamentiTari(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            case "ICP":
                documenti = versamentiService.listaVersamentiPubblTosapCuni(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            case "TOSAP":
                documenti = versamentiService.listaVersamentiPubblTosapCuni(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            case "CUNI":
                documenti = versamentiService.listaVersamentiPubblTosapCuni(ordinamento.tipo, parRicerca, tipoTributo, pageSize, activePage, wholeList)
                break
            default:
                break
        }

        lista = documenti?.result
        totali = documenti?.totali
        totalSize = documenti?.totali?.totale
        BindUtils.postNotifyChange(null, null, this, "lista")
        BindUtils.postNotifyChange(null, null, this, "totali")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")

        caricaListaAnomalie(wholeList)
    }

    /// Codice interno Anomalie ########################################################################################

    def caricaListaAnomalie(boolean wholeList) {

        listaDettaglioAnomalie = leggiListaAnomalie(wholeList)
        numBonifiche = listaDettaglioAnomalie.numeroRecord
        pagingAnomalie.totalSize = numBonifiche

        BindUtils.postNotifyChange(null, null, this, "listaDettaglioAnomalie")
        BindUtils.postNotifyChange(null, null, this, "numBonifiche")
        BindUtils.postNotifyChange(null, null, this, "pagingAnomalie")

        if (numBonifiche != 0) {

            if (anomalieOpened == false) {
                anomalieOpened = true

                BindUtils.postNotifyChange(null, null, this, "anomalieOpened")
            }
        } else {
            if (anomalieOpened) {
                anomalieOpened = false
                aggiornaQuadroAnomalie(anomalieOpened)

                BindUtils.postNotifyChange(null, null, this, "anomalieOpened")
            }
        }
    }

    def leggiListaAnomalie(boolean wholeList) {

        def paging = [:]
        def filtri = [:]
        def tipoAnomAnno = [:]

        if (wholeList) {
            paging.activePage = 0
            paging.max = Integer.MAX_VALUE
        } else {
            paging.activePage = pagingAnomalie.activePage
            paging.max = pagingAnomalie.pageSize
        }

        def tipiTributoSelezionati = [tipoTributo]

        filtri.tipiTributo = tipiTributoSelezionati

        String cognome = parRicerca.cognome ?: ''
        String nome = parRicerca.nome ?: ''

        if (cognome.isEmpty()) {
            if (nome.isEmpty()) {
                filtri.cognomeNome = null
            } else {
                filtri.cognomeNome = '%/' + nome
            }
        } else {
            if (nome.isEmpty()) {
                filtri.cognomeNome = cognome + '/%'
            } else {
                filtri.cognomeNome = cognome + '/' + nome
            }
        }

        String codFiscale = parRicerca.cf ?: ''
        if (codFiscale.isEmpty()) codFiscale = '%'
        filtri.codiceFiscale = codFiscale

        filtri.ruolo = parRicerca.ruolo
        filtri.annoDa = parRicerca.daAnno
        filtri.annoA = parRicerca.aAnno
        filtri.dataPagamentoDa = parRicerca.daDataPagamento
        filtri.dataPagamentoA = parRicerca.aDataPagamento
        filtri.dataRegistrazioneDa = parRicerca.daDataRegistrazione
        filtri.dataRegistrazioneA = parRicerca.aDataRegistrazione

        filtri.tipoVersamento = (parRicerca.tipoVersamento != null) ? parRicerca.tipoVersamento.codice : ''
        if (filtri.tipoVersamento == '') filtri.tipoVersamento = null
        filtri.documentoId = (parRicerca.progrDocVersamento != null) ? parRicerca.progrDocVersamento.codice : -1
        if (filtri.documentoId == -1) filtri.documentoId = null

        filtri.importoVersatoDa = parRicerca.daImporto as BigDecimal
        filtri.importoVersatoA = parRicerca.aImporto as BigDecimal

        def listaAnomalie = bonificaVersamentiService.getDettagliAnomalie("F24", tipoAnomAnno, paging, filtri, null)

        return listaAnomalie
    }

    def aggiornaQuadroAnomalie(boolean opened) {

    }

    /// Codice interno generico #########################################################################################

    def preparaParametriRicerca() {

        if (!parRicerca.aDataPagamento) {
            parRicerca.aDataPagamento = new Date().clearTime()
        }
        if (!parRicerca.aDataRegistrazione) {
            parRicerca.aDataRegistrazione = new Date().clearTime()
        }
        if (!parRicerca.aDataProvvedimento) {
            parRicerca.aDataProvvedimento = new Date().clearTime()
        }
        if (parRicerca.daImporto) {
            parRicerca.daImporto = String.valueOf(parRicerca.daImporto).replace(".", "")
        }
        if (parRicerca.aImporto) {
            parRicerca.aImporto = String.valueOf(parRicerca.aImporto).replace(".", "")
        }

        return
    }

    boolean verificaCampiFiltranti() {
        return parRicerca ? (parRicerca?.cognome != "" || parRicerca?.nome != ""
                || parRicerca?.cf != "" || parRicerca?.fonte != null
                || parRicerca?.tipoVersamento != null || parRicerca?.ruolo != null
                || parRicerca?.tipoPratica != null || parRicerca?.progrDocVersamento != null
                || parRicerca?.daAnno != null || parRicerca?.aAnno != null
                || parRicerca?.daDataPagamento != null || !parRicerca?.aDataPagamento?.equals(new Date().clearTime())
                || parRicerca?.daDataProvvedimento != null || !parRicerca?.aDataProvvedimento?.equals(new Date().clearTime())
                || parRicerca?.daDataRegistrazione != null || !parRicerca?.aDataRegistrazione?.equals(new Date().clearTime())
                || parRicerca?.daImporto != null || parRicerca?.aImporto != null
                || parRicerca?.rata != null
        ) : false
    }

    ///
    /// *** Quello del commonService da errore al runtime
    ///
    private void creaPopup(String zul, def parametri, def onClose = {}) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }

    private inizializzaCompetenze() {
        competenzeService.tipiTributoUtenzaScrittura().each {
            cbTributiInScrittura << [(it.tipoTributo): true]
        }
    }

    private def stampaVersamentiDoppi(def anno, def ordinamento) {

        SimpleDateFormat sf = new SimpleDateFormat("dd/MM/yyyy")
        List lista = versamentiService.getListaVersamentiDoppi(tipoTributo, anno, ordinamento)

        if (lista.empty) {
            Clients.showNotification("Nessun dato disponibile per l'anno $anno",
                    Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        def datiVersDoppi = []
        def versDoppi = [:]

        def ordinamentoString = ordinamento == "alfa" ? "Alfabetico" : "Codice Fiscale"
        def tipoTributoAttuale = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributo }.getTipoTributoAttuale(anno as Short)

        versDoppi.testata = [
                "tipoTributo"       : tipoTributo,
                "tipoTributoAttuale": tipoTributoAttuale,
                "anno"              : anno,
                "ordinamento"       : ordinamentoString
        ]

        lista.each {
            it.dataPagDesc = sf.format(it.dataPag)
        }

        versDoppi.dati = lista

        datiVersDoppi << versDoppi

        JasperReportDef reportDef = new JasperReportDef(name: 'versamentiDoppi.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiVersDoppi
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])


        def report = jasperService.generateReport(reportDef)

        if (reportDef == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.JASPER,
                    FileNameGenerator.GENERATORS_TITLES.VERSAMENTI_DOPPI,
                    [tipoTributo: tipoTributoAttuale,
                     anno       : anno])

            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }


    private def stampaSquadraturaTotale(def codFiscale, def anno, def scarto, def ordinamento) {

        def listaPrimaPagina = versamentiService.getListaSquadraturaTotalePrimaPagina(tipoTributo, codFiscale, anno, scarto, ordinamento)

        def listaSecondaPagina = versamentiService.getListaSquadraturaTotaleSecondaPagina(tipoTributo, codFiscale, anno, scarto, ordinamento)

        if (listaPrimaPagina.empty && listaSecondaPagina.empty) {
            def message = "Nessun dato disponibile per:\n- Anno $anno\n"
            message += "${codFiscale ? "- Codice Fiscale $codFiscale\n" : ''}"
            def decimalFormat = new DecimalFormat("#,##0.00")
            message += "${scarto != null ? "- Scarto ${decimalFormat.format(scarto)}" : ''}"
            Clients.showNotification(message,
                    Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }

        def datiSquadraturaTotale = []
        def squadraturaTotale = [:]

        def ordinamentoString = ordinamento == "alfa" ? "Alfabetico" : "Codice Fiscale"

        squadraturaTotale.testata = [
                "tipoTributo"       : tipoTributo,
                "tipoTributoAttuale": tipoTributoAttuale,
                "anno"              : anno,
                "ordinamento"       : ordinamentoString
        ]


        squadraturaTotale.dati1 = listaPrimaPagina
        squadraturaTotale.dati2 = formattaDatiSecondaPaginaSquadraturaTotale(tipoTributo, listaSecondaPagina)

        datiSquadraturaTotale << squadraturaTotale

        JasperReportDef reportDef = new JasperReportDef(name: 'squadraturaTotale.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiSquadraturaTotale
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte(),
                               versato      : listaSecondaPagina[0].versato ?: 0])


        def report = jasperService.generateReport(reportDef)

        if (reportDef == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.JASPER,
                    FileNameGenerator.GENERATORS_TITLES.SQUADRATURA_TOTALE,
                    [tipoTributo: tipoTributoAttuale,
                     anno       : anno])

            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }

    private def stampaTotaleVersamenti(def anno) {

        def listaPrimaPagina = versamentiService.getListaTotaleVersamentiPrimaPagina(tipoTributo, anno)

        def listaSecondaPagina = versamentiService.getListaTotaleVersamentiSecondaPagina(tipoTributo, anno)

        def datiTotaleVersamenti = []
        def totaleVersamenti = [:]
        def tipoTributoAttuale = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributo }.getTipoTributoAttuale(anno as Short)

        totaleVersamenti.testata = [
                "tipoTributo"       : tipoTributo,
                "tipoTributoAttuale": tipoTributoAttuale,
                "anno"              : anno
        ]

        def lista = listaPrimaPagina.groupBy { it.tipo }

        totaleVersamenti.datiA = lista.A
        totaleVersamenti.datiB = lista.B
        totaleVersamenti.datiB1 = lista.B1
        totaleVersamenti.datiC = lista.C
        totaleVersamenti.datiC1 = lista.C1
        totaleVersamenti.datiTotali = creaTotaliGeneraliTotaleVersamenti(listaPrimaPagina)
        totaleVersamenti.secondaPagina = formattaDatiSecondaPaginaTotaleVersamenti(tipoTributo, listaSecondaPagina)

        datiTotaleVersamenti << totaleVersamenti

        JasperReportDef reportDef = new JasperReportDef(name: 'totaleVersamenti.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiTotaleVersamenti
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])


        def report = jasperService.generateReport(reportDef)

        if (reportDef == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.JASPER,
                    FileNameGenerator.GENERATORS_TITLES.TOTALE_VERSAMENTI,
                    [tipoTributo: tipoTributoAttuale,
                     anno       : anno])

            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }


    private def stampaTotaleVersamentiPerGiorno(def dal, def al, def ordinamento) {

        def lista = versamentiService.getListaTotaleVersamentiPerGiorno(tipoTributo, dal, al, ordinamento)

        def datiVersamentiTotali = []
        def versamentiTotali = [:]

        versamentiTotali.testata = [
                "tipoTributo"       : tipoTributo,
                "tipoTributoAttuale": tipoTributoAttuale,
                "dal"               : dal,
                "al"                : al,
                "ordinamento"       : ordinamento == 'perm' ? "Permanente" : (ordinamento == 'temp' ? "Temporanea" : "Entrambi")
        ]

        versamentiTotali.dati = lista

        datiVersamentiTotali << versamentiTotali

        JasperReportDef reportDef = new JasperReportDef(name: 'totaleVersamentiPerGiorno.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiVersamentiTotali
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])


        def report = jasperService.generateReport(reportDef)

        if (reportDef == null) {
            Clients.showNotification("La ricerca non ha prodotto alcun risultato.",
                    Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        } else {

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.JASPER,
                    FileNameGenerator.GENERATORS_TITLES.TOTALE_VERSAMENTI_PER_GIORNO,
                    [tipoTributo: tipoTributoAttuale])

            AMedia amedia = new AMedia(nomeFile, "pdf", "application/pdf", report.toByteArray())
            Filedownload.save(amedia)
        }
    }


    private def formattaDatiSecondaPaginaSquadraturaTotale(def tipoTributo, def lista) {

        def entry = lista[0]

        if (tipoTributo == 'ICI') {

            return [
                    [
                            "descrizione"    : "ABITAZIONE PRINCIPALE E RELATIVE PERTINENZE",
                            "comune"         : entry.versatoAbComu ?: 0,
                            "stato"          : 0,
                            "versatoParziali": entry.versatoAbPrincipale ?: 0
                    ],
                    [
                            "descrizione"    : "FABBRICATI RURALI AD USO STRUMENTALE",
                            "comune"         : entry.versatoRuraliComu ?: 0,
                            "stato"          : 0,
                            "versatoParziali": entry.versatoRurali ?: 0
                    ],
                    [
                            "descrizione"    : "TERRENI",
                            "comune"         : entry.versatoTerreniComu ?: 0,
                            "stato"          : entry.versatoTerreniErar ?: 0,
                            "versatoParziali": entry.versatoTerreniAgricoli ?: 0
                    ],
                    [
                            "descrizione"    : "AREE FABBRICABILI",
                            "comune"         : entry.versatoAreeComu ?: 0,
                            "stato"          : entry.versatoAreeErar ?: 0,
                            "versatoParziali": entry.versatoAreeFabbricabili ?: 0
                    ],
                    [
                            "descrizione"    : "ALTRI FABBRICATI",
                            "comune"         : entry.versatoAltriComu ?: 0,
                            "stato"          : entry.versatoAltriErar ?: 0,
                            "versatoParziali": entry.versatoAltriFabbricati ?: 0
                    ],
                    [
                            "descrizione"    : "IMMOBILI AD USO PRODUTTIVO (GRUPPO CATASTALE D)",
                            "comune"         : entry.versatoFabbDComu ?: 0,
                            "stato"          : entry.versatoFabbDErar ?: 0,
                            "versatoParziali": entry.versatoFabbricatiD ?: 0
                    ],
                    [
                            "descrizione"    : "FABBRICATI COSTRUITI E DESTINATI ALLA VENDITA",
                            "comune"         : entry.versatoFabbMerceComu ?: 0,
                            "stato"          : 0,
                            "versatoParziali": entry.versatoFabbricatiMerce ?: 0
                    ]
            ]
        } else {

            return [
                    [
                            "descrizione"    : "ABITAZIONE PRINCIPALE E RELATIVE PERTINENZE",
                            "generale"       : entry.versatoAbComu ?: 0,
                            "versatoParziali": entry.versatoAbPrincipale ?: 0
                    ],
                    [
                            "descrizione"    : "FABBRICATI RURALI AD USO STRUMENTALE",
                            "generale"       : entry.versatoRuraliComu ?: 0,
                            "versatoParziali": entry.versatoRurali ?: 0
                    ],
                    [
                            "descrizione"    : "AREE FABBRICABILI",
                            "generale"       : entry.versatoAreeComu ?: 0,
                            "versatoParziali": entry.versatoAreeFabbricabili ?: 0
                    ],
                    [
                            "descrizione"    : "ALTRI FABBRICATI",
                            "generale"       : (entry.versatoAltriErar ?: 0) + (entry.versatoAltriComu ?: 0),
                            "versatoParziali": entry.versatoAltriFabbricati ?: 0
                    ],

            ]
        }
    }

    private def creaTotaliGeneraliTotaleVersamenti(def lista) {


        def listaResult = []

        lista.groupBy { it.tipoVersamentoDesc }.each {
            if (it.key != null) {
                listaResult << [
                        "tipoVersamentoDesc": it.key,
                        "terreniAgricoli"   : it.value.sum { it.terreniAgricoli },
                        "areeFabbricabili"  : it.value.sum { it.areeFabbricabili },
                        "abPrincipali"      : it.value.sum { it.abPrincipali },
                        "rurali"            : it.value.sum { it.rurali },
                        "altriFabbricati"   : it.value.sum { it.altriFabbricati },
                        "fabbricatiD"       : it.value.sum { it.fabbricatiD },
                        "fabbricatiMerce"   : it.value.sum { it.fabbricatiMerce },
                        "somma"             : it.value.sum { it.somma },
                        "detrazioni"        : it.value.sum { it.detrazioni },
                        "importiVersati"    : it.value.sum { it.importiVersati },
                        "numVersamenti"     : it.value.sum { it.numVersamenti },
                ]
            }
        }

        return listaResult
    }


    private def formattaDatiSecondaPaginaTotaleVersamenti(def tipoTributo, def lista) {


        def entry = lista[0]

        if (tipoTributo == "ICI") {

            return [
                    [
                            "descrizione": "ABITAZIONE PRINCIPALE E RELATIVE PERTINENZE - COMUNE",
                            "codTributo" : 3912,
                            "dovuto"     : entry.dovutoAbComu ?: 0,
                            "versato"    : entry.versatoAbComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "FABBRICATI RURALI AD USO STRUMENTALE - COMUNE",
                            "codTributo" : 3913,
                            "dovuto"     : entry.dovutoRuraliComu ?: 0,
                            "versato"    : entry.versatoRuraliComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "TERRENI - COMUNE",
                            "codTributo" : 3914,
                            "dovuto"     : entry.dovutoTerreniComu ?: 0,
                            "versato"    : entry.versatoTerreniComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "AREE FABBRICABILI - COMUNE",
                            "codTributo" : 3916,
                            "dovuto"     : entry.dovutoAreeComu ?: 0,
                            "versato"    : entry.versatoAreeComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "ALTRI FABBRICATI - COMUNE",
                            "codTributo" : 3918,
                            "dovuto"     : entry.dovutoAltriComu ?: 0,
                            "versato"    : entry.versatoAltriComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "IMMOBILI AD USO PRODUTTIVO (GRUPPO CATASTALE D) - INCREMENTO COMUNE",
                            "codTributo" : 3930,
                            "dovuto"     : entry.dovutoFabbDComu ?: 0,
                            "versato"    : entry.versatoFabbDComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "FABBRICATI COSTRUITI E DESTINATI DALL'IMIPRESA COSTRUTTRICE ALLA VENDITA - COMUNE",
                            "codTributo" : 3939,
                            "dovuto"     : entry.dovutoFabbMerceComu ?: 0,
                            "versato"    : entry.versatoFabbMerceComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "Totale Comune",
                            "dovuto"     : entry.totDovutoComu ?: 0,
                            "versato"    : entry.totVersatoComu ?: 0,
                            "totComue"   : true
                    ],
                    [
                            "descrizione": "TERRENI - STATO",
                            "codTributo" : 3915,
                            "dovuto"     : entry.dovutoTerreniErar ?: 0,
                            "versato"    : entry.versatoTerreniErar ?: 0,
                            "stato"      : true
                    ],
                    [
                            "descrizione": "AREE FABBRICABILI - STATO",
                            "codTributo" : 3917,
                            "dovuto"     : entry.dovutoAreeErar ?: 0,
                            "versato"    : entry.versatoAreeErar ?: 0,
                            "stato"      : true
                    ],
                    [
                            "descrizione": "ALTRI FABBRICATI - STATO",
                            "codTributo" : 3919,
                            "dovuto"     : entry.dovutoAltriErar ?: 0,
                            "versato"    : entry.versatoAltriErar ?: 0,
                            "stato"      : true
                    ],
                    [
                            "descrizione": "IMMOBILI AD USO PRODUTTIVO (GRUPPO CATASTALE D) - STATO",
                            "codTributo" : 3925,
                            "dovuto"     : entry.dovutoFabbDErar ?: 0,
                            "versato"    : entry.versatoFabbDErar ?: 0,
                            "stato"      : true
                    ],
                    [
                            "descrizione": "Totale Stato",
                            "dovuto"     : entry.totDovutoErar ?: 0,
                            "versato"    : entry.totVersatoErar ?: 0,
                            "totStato"   : true
                    ],
                    [
                            "descrizione": "Totale Generale",
                            "dovuto"     : entry.totDovuto ?: 0,
                            "versato"    : entry.totVersato ?: 0,
                            "totGenerali": true
                    ]
            ]

        } else if (tipoTributo == 'TASI') {

            return [
                    [
                            "descrizione": "ABITAZIONE PRINCIPALE E RELATIVE PERTINENZE",
                            "codTributo" : 3958,
                            "dovuto"     : entry.dovutoAbComu ?: 0,
                            "versato"    : entry.versatoAbComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "FABBRICATI RURALI AD USO STRUMENTALE",
                            "codTributo" : 3959,
                            "dovuto"     : entry.dovutoRuraliComu ?: 0,
                            "versato"    : entry.versatoRuraliComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "AREE FABBRICABILI",
                            "codTributo" : 3960,
                            "dovuto"     : entry.dovutoAreeComu ?: 0,
                            "versato"    : entry.versatoAreeComu ?: 0,
                            "comune"     : true
                    ],
                    [
                            "descrizione": "ALTRI FABBRICATI",
                            "codTributo" : 3961,
                            "dovuto"     : entry.dovutoAltriComu ?: 0,
                            "versato"    : entry.versatoAltriComu ?: 0,
                            "comune"     : true
                    ]
            ]

        }


        return lista

    }
}
