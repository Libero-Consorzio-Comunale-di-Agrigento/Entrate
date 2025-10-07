package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.OggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ContribuentiOggettoViewModel {

    Window self
    CompetenzeService competenzeService
    OggettiService oggettiService
    CommonService commonService


    OggettoDTO oggetto
    Long idPratica
    def listaContribuenti = []
    def contribuenteSelezionato
    def anno
    def listaAnni
    def lista

    def cbTributiAbilitati = [:]
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
            , V: true]    // versamenti V


    ContribuentiService contribuentiService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("oggetto") def idOggettoContribuente
         , @ExecutionArgParam("pratica") def idPratica
         , @ExecutionArgParam("anno") @Default("-1") String anno
         , @ExecutionArgParam("listaAnni") List listaAnni) {
        this.self = w
        oggetto = Oggetto.get(idOggettoContribuente).toDTO(["archivioVie", "tipoOggetto", "categoriaCatasto"])
        this.idPratica = idPratica

        this.anno = anno

        this.listaAnni = listaAnni ?: oggettiService.anniContribuentiSuOggetto(idOggettoContribuente)

        caricaOggetti()
        refreshCheckBox()

        verificaCompetenze()
    }

    @Command
    onChangeTipoTributo() {
        caricaOggetti()
    }

    @Command
    onChangeTipoPratica() {
        caricaOggetti()
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(contribuenteSelezionato?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onSelezioneAnno() {
        cbTributi.entrySet().each { it.value = true }
        cbTipiPratica.entrySet().each { it.value = true }
        caricaOggetti()

        refreshCheckBox()
    }

    @Command
    contribuentiToXls() {

        Map fields = [
                'ni'             : 'NI',
                'contribuente'   : 'Contribuente',
                'codFiscale'     : 'Codice fiscale',
                'dataNascita'    : 'Data di nascita',
                'codContribuente': 'Codice contribuente',
                'partitaIVA'     : 'Partiva IVA',
                'indirizzo'      : 'Indirizzo',
                'percPossesso'   : '%Poss.'
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_CONTRIBUENTI,
                [idOggetto: oggetto.id])

        def lista = listaContribuenti.collect { row ->
            ['ni'             : row["ni"],
             'contribuente'   : row["cognome"] + " " + row["nome"],
             'codFiscale'     : (row["codFiscale"]) ? row["codFiscale"] : "",
             'dataNascita'    : row["dataNascita"]?.format("dd/MM/yyyy"),
             'codContribuente': (row["codContribuente"]) ? row["codContribuente"] : "",
             'partitaIVA'     : (row["partitaIVA"]) ? row["partitaIVA"] : "",
             'indirizzo'      : (row["indirizzo"]) ? row["indirizzo"] : "",
             'percPossesso'   : (row["percPossesso"]) ? row["percPossesso"] : ""
            ]
        }

        XlsxExporter.exportAndDownload(nomeFile, lista, fields)
    }

    private caricaOggetti() {
        lista = contribuentiService.getContribuentiOggetto(
                oggetto.id, idPratica,
                cbTributi, cbTipiPratica,
                !(anno in ['Tutti', '-1']) ? anno : null
        )

        listaContribuenti = lista.lista

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
    }

    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
        }

        cbTributi.each { k, v ->
            if (competenzeService.tipiTributoUtenza().find { it.tipoTributo == k } == null) {
                cbTributi[k] = false
            }
        }
    }

    private refreshCheckBox() {
        this.cbTributi.TASI = lista.tributiPratiche.TASI
        this.cbTributi.ICI = lista.tributiPratiche.ICI
        this.cbTributi.TARSU = lista.tributiPratiche.TARSU
        this.cbTributi.ICP = lista.tributiPratiche.ICP
        this.cbTributi.TOSAP = lista.tributiPratiche.TOSAP
        this.cbTributi.CUNI = lista.tributiPratiche.CUNI

        cbTipiPratica.D = lista.tributiPratiche.D
        cbTipiPratica.A = lista.tributiPratiche.A
        cbTipiPratica.L = lista.tributiPratiche.L

        BindUtils.postNotifyChange(null, null, this, "cbTributi")
        BindUtils.postNotifyChange(null, null, this, "cbTipiPratica")
    }
}
