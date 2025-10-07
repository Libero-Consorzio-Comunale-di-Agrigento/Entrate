package pratiche

import document.FileNameGenerator
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class PraticheOggettoViewModel {

    Window self
    OggettoDTO oggetto
    def listaPraticheOggetto = []
    def praticaSelezionata
    def lista
    Long idPratica
    def praticaOpenable = true

    def cbTributi = [
            TASI   : true
            , ICI  : true
            , TARSU: true
            , ICP  : true
            , TOSAP: true
            , CUNI : true]

    def cbTipiPratica = [
            D  : true    // dichiarazione D
            , A: true    // accertamento A
            , L: true    // liquidazione L
            , I: true    // infrazioni I
            , R: true    // ravvedimenti R
            , V: true]   // ravvedimenti operosi V

    // mappa degli zul relativi alle pratiche da aprire sulla base di:
    // - Tipo Tributo
    // - Tipo Pratica
    // - Tipo Evento
    Map caricaPannello = [
            "ICI"    : [

                    "D"  : ["I"  : [zul      : "/pratiche/denunce/denunciaImu.zul"
                                    , lettura: true]
                            , "C": [zul      : "/pratiche/denunce/denunciaImu.zul"
                                    , lettura: true]
                    ]
                    , "L": ["U"  : [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                    , lettura   : false
                                    , situazione: "liquidazione"]
                            , "R": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                    , lettura   : false
                                    , situazione: "liquidazione"]
            ]
                    , "A": ["T"  : [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                    , lettura   : true
                                    , situazione: "accTotImu"]
                            , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                                    , lettura   : true
                                    , situazione: "accManImu"]
            ], "V"       : ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                  , lettura   : false
                                  , situazione: "ravvImu"],
                            "S": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                  , lettura   : false
                                  , situazione: "ravvImu"],
                            "A": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                                  , lettura   : false
                                  , situazione: "ravvImu"]
            ]
            ]
            , "TARSU": [
            "D"  : ["C"  : [zul      : "/pratiche/denunce/denunciaTari.zul"
                            , lettura: true]
                    , "I": [zul      : "/pratiche/denunce/denunciaTari.zul"
                            , lettura: true]
                    , "U": [zul      : "/pratiche/denunce/denunciaTari.zul"
                            , lettura: true]
                    , "V": [zul      : "/pratiche/denunce/denunciaTari.zul"
                            , lettura: true]
            ]
            , "A": ["A"  : [zul         : "pratiche/violazioni/accertamentoAutomaticoTari.zul"
                            , lettura   : false
                            , situazione: "accAutoTari"]
                    , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                            , lettura   : false
                            , situazione: "accManTari"]
                    , "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                            , lettura   : true
                            , situazione: "accTotTari"]
    ]
    ]
            , "ICP"  : [
            "A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                        , lettura   : false
                        , situazione: "accAutoTribMin"],
                  "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                        , lettura   : true
                        , situazione: "accManTribMin"],
                  "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                        , lettura   : true
                        , situazione: "accTotTribMin"]
            ]
    ]
            , "TOSAP": [
            "A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                        , lettura   : false
                        , situazione: "accAutoTribMin"],
                  "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                        , lettura   : true
                        , situazione: "accManTribMin"],
                  "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                        , lettura   : true
                        , situazione: "accTotTribMin"]
            ]
    ]
            , "TASI" : [
            "D"  : ["I"  : [zul      : "/pratiche/denunce/denunciaTasi.zul"
                            , lettura: false]
                    , "C": [zul      : "/pratiche/denunce/denunciaTasi.zul"
                            , lettura: false]
            ]
            , "L": ["U"  : [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                            , lettura   : false
                            , situazione: "liquidazione"]
                    , "R": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                            , lettura   : false
                            , situazione: "liquidazione"]
    ]
            , "A": ["T"  : [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                            , lettura   : true
                            , situazione: "accTotImu"]
                    , "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                            , lettura   : true
                            , situazione: "accManImu"]
    ], "V"       : ["U": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                          , lettura   : false
                          , situazione: "ravvTasi"],
                    "S": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                          , lettura   : false
                          , situazione: "ravvTasi"],
                    "A": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                          , lettura   : false
                          , situazione: "ravvTasi"]
    ]
    ], "CUNI" : [
            "D"  : ["I": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                          , lettura: false],
                    "U": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                          , lettura: false],
                    "C": [zul      : "/ufficiotributi/canoneunico/dichiarazioneCanoniCU.zul"
                          , lettura: false]
            ]
            , "A": ["A": [zul         : "pratiche/violazioni/accertamentoAutomaticoTribMin.zul"
                          , lettura   : false
                          , situazione: "accAutoTribMin"],
                    "U": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                          , lettura   : true
                          , situazione: "accManTribMin"],
                    "T": [zul         : "pratiche/violazioni/accertamentiManualiTotale.zul"
                          , lettura   : true
                          , situazione: "accTotTribMin"]
    ]
            , "V": ["R0": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                           , lettura   : false
                           , situazione: "ravvTribMin"],
                    "R1": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                           , lettura   : false
                           , situazione: "ravvTribMin"],
                    "R2": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                           , lettura   : false
                           , situazione: "ravvTribMin"],
                    "R3": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                           , lettura   : false
                           , situazione: "ravvTribMin"],
                    "R4": [zul         : "/pratiche/violazioni/liquidazioneImu.zul"
                           , lettura   : false
                           , situazione: "ravvTribMin"]
    ]
    ]
    ]

    ContribuentiService contribuentiService
    CompetenzeService competenzeService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("oggetto") long idOggetto) {
        this.self = w
        oggetto = Oggetto.get(idOggetto).toDTO(["archivioVie", "tipoOggetto", "categoriaCatasto"])
        caricaLista()

        this.cbTributi.TASI = lista.tributiPratiche.TASI
        this.cbTributi.ICI = lista.tributiPratiche.ICI
        this.cbTributi.TARSU = lista.tributiPratiche.TARSU
        this.cbTributi.ICP = lista.tributiPratiche.ICP
        this.cbTributi.TOSAP = lista.tributiPratiche.TOSAP
        this.cbTributi.CUNI = lista.tributiPratiche.CUNI

        cbTipiPratica.D = lista.tributiPratiche.D
        cbTipiPratica.A = lista.tributiPratiche.A
        cbTipiPratica.L = lista.tributiPratiche.L
        cbTipiPratica.V = lista.tributiPratiche.V
    }

    @Command
    onChangeTipoTributo() {
        caricaLista()
    }

    @Command
    onChangeTipoPratica() {
        caricaLista()
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onSelezioneAnno() {
        caricaLista()
    }

    @Command
    onSelezionaPratica() {
        praticaOpenable = existsViewForPratica()
        BindUtils.postNotifyChange(null, null, this, 'praticaOpenable')
    }

    private boolean existsViewForPratica() {
        String tipoTributo = praticaSelezionata.tipoTributo.tipoTributo
        String tipoPratica = praticaSelezionata.tipoPratica
        String tipoEvento = praticaSelezionata.tipoEvento

        return caricaPannello."${tipoTributo}" && caricaPannello."${tipoTributo}"."${tipoPratica}" && caricaPannello."${tipoTributo}"."${tipoPratica}"?."${tipoEvento}"
    }

    @Command
    onModificaPratica() {

        if (!praticaOpenable) {
            return
        }

        boolean lettura
        String situazione
        String zul

        zul = caricaPannello."${praticaSelezionata.tipoTributo.tipoTributo}"
                ."${praticaSelezionata.tipoPratica}"."${praticaSelezionata.tipoEvento}".zul
        lettura = caricaPannello."${praticaSelezionata.tipoTributo.tipoTributo}"
                    ."${praticaSelezionata.tipoPratica}"."${praticaSelezionata.tipoEvento}".lettura
        if (!lettura) {
            lettura = competenzeService.tipoAbilitazioneUtente(praticaSelezionata.tipoTributo.tipoTributo) == competenzeService.TIPO_ABILITAZIONE.LETTURA
        }
        situazione = caricaPannello."${praticaSelezionata.tipoTributo.tipoTributo}"
                ."${praticaSelezionata.tipoPratica}"."${praticaSelezionata.tipoEvento}".situazione

        def onClose = {
            List<String> listaTipi = []
            praticaSelezionata = null
            cbTributi.each { tr -> if (tr.value) listaTipi.add(tr.key) }
            List<String> listaPratiche = []
            cbTipiPratica.each { tp -> if (tp.value) listaPratiche.add(tp.key) }
            lista = contribuentiService.praticheOggettoContribuente(oggetto.id, null, null, listaTipi, listaPratiche)
            listaPraticheOggetto = lista.lista
            BindUtils.postNotifyChange(null, null, this, "listaPraticheOggetto")
            BindUtils.postNotifyChange(null, null, this, "praticaSelezionata")
        }

        creaPopup(zul, [pratica: praticaSelezionata.id, tipoRapporto: praticaSelezionata.tipoRapporto, lettura: lettura, situazione: situazione, daBonifiche: false], onClose)
    }

    @Command
    def praticheToXls() {

        Map fields = [
                'descrizioneTributo': 'Tributo',
                'anno'              : 'Anno',
                'tipoPratica'       : 'Tipo Pratica',
                "tipoEvento.id"     : 'Tipo Evento',
                "data"              : 'Data',
                "numero"            : 'Numero',
                "stato"             : 'Stato',
                "dataNotifica"      : 'Data Notifica',
                "tipoRapporto"      : 'Rapporto',
                "id"                : 'Pratica',
                "praticaSuccessiva" : 'Pratica Successiva'
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_PRATICHE,
                [idOggetto: oggetto.id])

        XlsxExporter.exportAndDownload(nomeFile, listaPraticheOggetto, fields)
    }

    private caricaLista() {
        List<String> listaTipi = []
        cbTributi.each { it -> if (it.value) listaTipi.add(it.key) }
        List<String> listaPratiche = []
        cbTipiPratica.each { it -> if (it.value) listaPratiche.add(it.key) }
        lista = contribuentiService.praticheOggettoContribuente(oggetto.id, null, null, listaTipi, listaPratiche)
        listaPraticheOggetto = lista.lista
        BindUtils.postNotifyChange(null, null, this, "listaPraticheOggetto")
    }

    private void creaPopup(String zul, def parametri, def onClose = {}) {
        Window w = Executions.createComponents(zul, self, parametri)
        w.onClose = onClose
        w.doModal()
    }

    @Command
    def onOpenSituazioneContribuente(@BindingParam("ni") def ni) {

        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }
}
