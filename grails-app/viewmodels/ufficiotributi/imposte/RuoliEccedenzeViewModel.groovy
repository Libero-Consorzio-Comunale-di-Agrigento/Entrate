package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import it.finmatica.tr4.imposte.FiltroRicercaListeDiCaricoRuoliEccedenze
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window

import java.text.DecimalFormat
import java.math.RoundingMode

class RuoliEccedenzeViewModel {

    // Componenti
    Window self

    // Services
    CommonService commonService
    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Comuni
    def ruolo
    def codFiscale

    ContribuenteDTO contribuente
    TipoTributoDTO tipoTributo

    // Altro
    Popup popupNote

    // Elenco eccedenze ruolo
    def selectedEccedenza
    def listaEccedenzeRuolo = []

    // totali
    def totaliEccedenze = [
            contribuenti      : 0,
            importoRuolo      : 0,
            imposta           : 0,
            addProv           : 0,
            costoSvuotamento  : 0,
            costoSuperficie   : 0,
    ]

    // paginazione
    def pagingEccedenze = [
            activePage        : 0,
            pageSize          : 10,
            totalSize         : 0
    ]

    // ricerca
    FiltroRicercaListeDiCaricoRuoliEccedenze parRicercaEccedenze
    boolean filtroAttivoEccedenze = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
                         @ExecutionArgParam("ruolo") def rr,
                         @ExecutionArgParam("codFiscale") def cf) {

        this.self = w

        this.ruolo = rr
        this.codFiscale = cf

        this.contribuente = Contribuente.findByCodFiscale(this.codFiscale)?.toDTO(['soggetto'])
        if(this.contribuente == null) {
            throw new Exception("Impossibile ricavare dati Contribuente!")
        }

        Ruolo ruolo = Ruolo.get(this.ruolo)
        if(ruolo == null) {
            throw new Exception("Impossibile ricavare dati ruolo!")
        }

        tipoTributo = ruolo.tipoTributo.toDTO()

        parRicercaEccedenze = new FiltroRicercaListeDiCaricoRuoliEccedenze()
        parRicercaEccedenze.codFiscale = cf;

        verificaCampiFiltrantiEccedenze()

        onRicaricaListaEccedenze()
    }

    @Command
    def onRicaricaListaEccedenze() {

        ricalcolaTotaliEccedenze()
        caricaListaEccedenze()
    }

    @Command
    onSelezionaEccedenza() {

    }

    @Command
    void onApriPopupNote(@ContextParam(ContextType.COMPONENT) Popup popupNote) {
        this.popupNote = popupNote
    }

    @Command
    void onChiudiPopupNote() {
        this.popupNote.close()
    }

    @Command
    def onEccedenzeToXls() throws Exception {

        def listaPerExport = []

        def numeroRuolo = ruolo

        def parametriRicerca = completaParametriEccedenze()
        parametriRicerca.perExport = true
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca)
        listaPerExport = caricoEccedenze.records

        Map fields = [
                "cognomeNome"       : "Contribuente",
                "codFiscale"        : "Codice Fiscale",
                "tributo"           : "Cod.",
                "categoria"         : "Categoria",
                "dataDal"           : "Dal",
                "dataAl"            : "Al",
                "flagDomestica"     : "Domestica",
                "numeroFamiliari"   : "Num.Fam.",
                "importoRuolo"      : "Importo",
                "imposta"           : "Eccedenze",
                "addProv"           : "Add.Prov.",
                "numeroFamiliari"   : "Num.Fam.",
                "importoMinimi"     : "Imp.Minimi",
                "totaleSvuotamenti" : "Tot.Svuot.",
                "superficie"        : "Sup.",
                "costoSvuotamento"  : "Costo Svuot.",
			    "svuotamentiSuperficie" : "Svuot.Sup.",
		        "costoSuperficie"       : "Costo Sup.",
		        "eccedenzaSvuotamenti"  : "Ecc.Svuot.",
                "note"              : "Note",
                "ruolo"             : "Ruolo",
        ]

        def converters = [
                'ruolo'                       : Converters.decimalToInteger,
                'tributo'                     : Converters.decimalToInteger,
                'categoria'                   : Converters.decimalToInteger,
                'numeroFamiliari'             : Converters.decimalToInteger,
                'flagDomestica'               : { value -> (value) ? 'SI' : 'NO' },
        ]

        def bigDecimalFormats = [
                "costoUnitario"      : '#,##0.00000000'
        ]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ECCEDENZE_RUOLO,
                [tipoTributo: tipoTributo.getTipoTributoAttuale(),
                 idRuolo    : numeroRuolo])

        XlsxExporter.exportAndDownload(nomeFile, listaPerExport, fields, converters, bigDecimalFormats)
    }

    @Command
    def onAnnulla() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOpenSituazioneContribuente() {
        def ni = Contribuente.findByCodFiscale(contribuente?.codFiscale)?.soggetto?.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    def onOpenFiltriEccedenze() {
    
        Window w = Executions.createComponents("/ufficiotributi/imposte/ruoloEccedenzeRicerca.zul", self, 
            [
                parRicerca: parRicercaEccedenze
            ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicercaEccedenze = event.data.parRicerca
                    BindUtils.postNotifyChange(null, null, this, "parRicercaEccedenze")

                    onRicaricaListaEccedenze()
                }
            }

            verificaCampiFiltrantiEccedenze()

            selectedEccedenza = null
            BindUtils.postNotifyChange(null, null, this, "selectedEccedenza")
        }
        w.doModal()
    }

    private caricaListaEccedenze() {

        def parametriRicerca = completaParametriEccedenze()
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca, pagingEccedenze.pageSize, pagingEccedenze.activePage)
        listaEccedenzeRuolo = caricoEccedenze.records

        selectedEccedenza = null

        BindUtils.postNotifyChange(null, null, this, "selectedEccedenza")
        BindUtils.postNotifyChange(null, null, this, "listaEccedenzeRuolo")
    }

    private void ricalcolaTotaliEccedenze() {

        def parametriRicerca = completaParametriEccedenze()
        def caricoEccedenze = listeDiCaricoRuoliService.getEccedenzeRuolo(parametriRicerca)
        def listaPerTotali = caricoEccedenze.records

        totaliEccedenze.importoRuolo = listaPerTotali.sum { it.importoRuolo } ?: 0
        totaliEccedenze.imposta = listaPerTotali.sum { it.imposta } ?: 0
        totaliEccedenze.addProv = listaPerTotali.sum { it.addProv } ?: 0
        totaliEccedenze.costoSvuotamento = listaPerTotali.sum { it.costoSvuotamento } ?: 0
        totaliEccedenze.costoSuperficie = listaPerTotali.sum { it.costoSuperficie ?: 0 } ?: 0
        
        def contribuentiList = []
        listaPerTotali.each() { c -> (contribuentiList << c.ni) }
        def contribuentiUnique = contribuentiList.unique(false)
        totaliEccedenze.contribuenti = contribuentiUnique.size()

        BindUtils.postNotifyChange(null, null, this, "totaliEccedenze")

        pagingEccedenze.activePage = 0
        pagingEccedenze.totalSize = caricoEccedenze.totalCount

        BindUtils.postNotifyChange(null, null, this, "pagingEccedenze")
    }

    private completaParametriEccedenze() {

        def filtroRuoli = determinaFiltriRuoli()

        def parametriRicerca = [
                ruoli          : filtroRuoli.ruoli,
                tributo        : filtroRuoli.codTributo,
                cognome        : parRicercaEccedenze?.cognome,
                nome           : parRicercaEccedenze?.nome,
                codFiscale     : parRicercaEccedenze?.codFiscale
        ]

        return parametriRicerca
    }

    def determinaFiltriRuoli() {

        def ruoli = []
        def codTributo = null
        Short annoRuoli = null

        ruoli = [this.ruolo]

        Ruolo ruolo = Ruolo.get(this.ruolo)
        annoRuoli = ruolo.annoRuolo

        return [ruoli: ruoli, codTributo: codTributo, annoRuoli: annoRuoli]
    }

    private def verificaCampiFiltrantiEccedenze() {

        filtroAttivoEccedenze = parRicercaEccedenze.isDirty()
        BindUtils.postNotifyChange(null, null, this, "filtroAttivoEccedenze")
    }
}
