package pratiche.insolventi

import commons.OrdinamentoMutiColonnaViewModel
import document.FileNameGenerator
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.InsolventiService
import it.finmatica.tr4.insolventi.FiltroRicercaInsolventi
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Listbox
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class ElencoInsolventiViewModel extends OrdinamentoMutiColonnaViewModel {

    Window self
    ServletContext servletContext

    @Wire("#listBoxInsolventi")
    Listbox listBoxInsolventi

    // services
    TributiSession tributiSession
    CommonService commonService
    CompetenzeService competenzeService
    InsolventiService insolventiService

    String tipoTributo
    TipoTributoDTO tipoTributoDTO
    Boolean lettura = true

    // Paginazione
    def pagingInsolventi = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    // Filtri
    FiltroRicercaInsolventi filtriInsolventi
    boolean filtroAttivo = false

    // Insolventi
    def listaInsolventi = []
    def insolventeSelezionato = null
    def totaliInsolventi = [:]

    @Init(superclass = true)
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tt,
         @ExecutionArgParam("tipoPratica") String tp) {

        this.self = w

        tipoTributo = tt
        tipoTributoDTO = TipoTributo.get(tipoTributo).toDTO()

        String abilitazione = competenzeService.tipoAbilitazioneUtente(tipoTributo)
        lettura = (abilitazione != "A")

        campiOrdinamento = [
                'contribuente': [verso: VERSO_ASC, posizione: 0],
                'cod_fiscale' : [verso: VERSO_ASC, posizione: 1],
                'anno'        : [verso: VERSO_ASC, posizione: 2],
        ]

        campiCssOrdinamento = [
                'contribuente': CSS_ASC,
                'cod_fiscale' : CSS_ASC,
                'anno'        : CSS_ASC,
        ]

        filtriInsolventi = tributiSession.filtroRicercaInsolventi

        if (filtriInsolventi && filtriInsolventi.filtroAttivo(true)) {

            filtriInsolventi.tipoTributo = tipoTributoDTO.tipoTributo

            filtroAttivo = filtriInsolventi.filtroAttivo(true)
            caricaInsolventi(false, true)
        } else {
            filtriInsolventi = new FiltroRicercaInsolventi()
            filtriInsolventi.tipoTributo = tipoTributoDTO.tipoTributo
            onOpenFiltri()
        }
    }

    @Override
    void caricaLista() {

        caricaInsolventi()
    }

    // Eventi

    @Command
    def onPaging() {

        caricaInsolventi(false)
    }

    @Command
    def onRefresh() {

        caricaInsolventi(true)
    }

    @Command
    def onCheckTipologia() {
        caricaInsolventi(true, false)
    }

    @Command
    def onCheckIngiunzione() {

        caricaInsolventi(true)
    }

    @Command
    def onCheckVersamenti() {

        caricaInsolventi(true)
    }

    @Command
    def onCheckTardivi() {

        caricaInsolventi(true)
    }

    @Command
    def onExportXls() {

        String tipoTributoDescr = tipoTributoDTO.getTipoTributoAttuale()

        def pagingToXls = [
                activePage: 0,
                pageSize  : Integer.MAX_VALUE,
                totalSize : 0
        ]

        def insolventi = insolventiService.getInsolventiGenerale(filtriInsolventi, pagingToXls, campiOrdinamento, true)
        def elencoInsolventi = insolventi.records

        def fields = [
                "contribuente"  : "Contribuente",
                "codFiscale"    : "Cod.Fiscale",
                "anno"          : "Anno",
                "tipoPratica"   : "T.Prat.",
                "dovuto"        : "Imp. Dovuto",
                "versato"       : "Imp. Versato",
                "tardivo"       : "Tardivo",
                "insolvenza"    : "Insolvenza",
                "ingiunzione"   : "Ingiunzione",
                "dataPagamento" : "Data versam.",
                "importoTributo": "Imp. Tributo",
                "ruolo"         : "Ruolo",
                "numeroPratica" : "Numero",
                "dataNotifica"  : "Data Notifica",
                "indirizzoDich" : "Indirizzo",
                "residenzaDich" : "Comune",
                "dataNascita"   : "Data Nascita",
                "luogoNascita"  : "Comune di Nascita",
                "rappresentante": "Rappresentante Legale",
                "codFiscaleRap" : "Codifce Fiscale Rapp. Leg.",
                "indirizzoRap"  : "Indirizzo Rapp. Leg.",
                "comuneRap"     : "Comune Rapp. Leg.",
                "primoErede"    : "Primo Erede",
        ]

        def formatters = [
                "tardivo"      : { t -> (t ?: 0) > 0.0 ? 'S' : 'N' },
                "ingiunzione"  : { i -> (i ?: 0) > 0.0 ? 'S' : 'N' },
                "anno"         : Converters.decimalToInteger,
                "ruolo"        : Converters.decimalToInteger,
                "numeroPratica": Converters.decimalToInteger,
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.INSOLVENTI,
                [tipoTributo: tipoTributoDescr])

        XlsxExporter.exportAndDownload(nomeFile, elencoInsolventi, fields, formatters)
    }

    @Command
    def onOpenFiltri() {

        commonService.creaPopup("/ufficiotributi/imposte/insolventiRicerca.zul", self,
                [
                        tipoTributo        : tipoTributoDTO,
                        filtri             : filtriInsolventi,
                        anno               : null,
                        gruppoTributoAttivo: null,
                        codiceTributo      : null,
                        insolventiGenerale : true
                ],
                { e ->
                    if (e.data?.filtriAggiornati) {
                        filtriInsolventi = e.data.filtriAggiornati
                        tributiSession.filtroRicercaInsolventi = filtriInsolventi

                        aggiornaFiltroAttivo()

                        if (e.data?.isChangedTipo != null) {
                            caricaInsolventi(true, e.data.isChangedTipo)
                        }

                    }
                }
        )
    }

    @Command
    def onResizeColumn() {
        listBoxInsolventi?.invalidate()
    }


    // Funzioni interne

    def caricaInsolventi(Boolean resetPaginazione = false, Boolean filtriAttoModificati = false) {

        if (resetPaginazione) {
            pagingInsolventi.activePage = 0
        }

        controllaFiltroTipiAtti(filtriAttoModificati)

        def insolventi = insolventiService.getInsolventiGenerale(filtriInsolventi, pagingInsolventi, campiOrdinamento)

        listaInsolventi = insolventi.records
        pagingInsolventi.totalSize = insolventi.totalCount
        totaliInsolventi = insolventi.totali

        insolventeSelezionato = null

        svuotaDatiRidondanti(listaInsolventi)

        BindUtils.postNotifyChange(null, null, this, "pagingInsolventi")
        BindUtils.postNotifyChange(null, null, this, "insolventeSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaInsolventi")
        BindUtils.postNotifyChange(null, null, this, "totaliInsolventi")
        BindUtils.postNotifyChange(null, null, this, "filtriInsolventi")

    }

    private def controllaFiltroTipiAtti(Boolean filtriAttoModificati = false) {

        if (filtriInsolventi.tipo != "Tutti") {
            filtriInsolventi.filtroTipiAtto.each { it.value = false }

            if (filtriInsolventi.tipo == "Imposta") {
                filtriInsolventi.filtroTipiAtto.imp = true
            } else if (filtriInsolventi.tipo == "Liquidazione") {
                filtriInsolventi.filtroTipiAtto.liq = true
            } else if (filtriInsolventi.tipo == "Accertamento") {
                filtriInsolventi.filtroTipiAtto.acc = true
            }
        } else {
            if (filtriAttoModificati) {
                filtriInsolventi.filtroTipiAtto.each { it.value = true }
            }
        }

        BindUtils.postNotifyChange(null, null, this, "filtriInsolventi")
    }

    private void svuotaDatiRidondanti(def listaInsolventi) {

        def numInsolventi = listaInsolventi.size() - 1

        for (def outer = 0; outer < numInsolventi; outer++) {

            def outerItem = listaInsolventi.get(outer)

            for (def inner = outer + 1; inner <= numInsolventi; inner++) {

                def innerItem = listaInsolventi.get(inner)

                if ((innerItem.contribuente == outerItem.contribuente) &&
                        (innerItem.codFiscale == outerItem.codFiscale)) {
                    innerItem.contribuente = ""
                    innerItem.indirizzoDich = ""
                    innerItem.residenzaDich = ""
                } else {
                    break
                }
            }
        }
    }

    // Verifica impostazioni filtro
    def aggiornaFiltroAttivo() {

        filtroAttivo = filtriInsolventi.filtroAttivo(true)
        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

}
