package ufficiotributi.imposte

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.SgraviService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class SgraviViewModel {

    // Componenti
    Window self

    // Services
    def springSecurityService
    SgraviService sgraviService
    CommonService commonService

    // Comuni
    def isFiltroAttivo = false
    def sgravioSelezionato
    def listaSgravi = []
    def sgraviGroupsModel
    def parametriFiltroAttuali = [:]

    // Paginazione
    def pagingSgravi = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        visualizzaFiltroRicerca()
    }


    @Command
    def visualizzaFiltroRicerca() {

        commonService.creaPopup(
                "/ufficiotributi/imposte/sgraviRicerca.zul",
                self,
                [parametriFiltroAttuali: parametriFiltroAttuali],
                { event ->
                    if (event.data) {

                        resetPaginazione()

                        this.parametriFiltroAttuali = event.data.parametri
                        this.isFiltroAttivo = event.data.isFiltroAttivo
                        caricalistaSgravi()

                        BindUtils.postNotifyChange(null, null, this, "isFiltroAttivo")
                    }
                }
        )
    }

    @Command
    def onCambioPagina() {

        sgravioSelezionato = null

        caricalistaSgravi()

        BindUtils.postNotifyChange(null, null, this, "sgravioSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaSgravi")
    }

    @Command
    def onRefresh() {
        caricalistaSgravi()
    }

    @Command
    def onExportXls() {

        Map fields
        def converters = [
                "importoLordo"  : Converters.flagNullToString,
                "ruolo"         : Converters.decimalToInteger,
                "numeroElenco"  : Converters.decimalToInteger,
                "annoRuolo"     : Converters.decimalToInteger,
                "annoEmissione" : Converters.decimalToInteger,
                "progrEmissione": Converters.decimalToInteger,
                "tipoRuolo"      : { tipoRuolo -> (tipoRuolo == 1 ? 'P' : 'S') }
        ]

        def listaSgravi = sgraviService.getListaSgraviFiltrati(parametriFiltroAttuali).records

        if (listaSgravi) {

            fields = [
                    "numeroElenco"    : "Numero Elenco",
                    "dataElenco"      : "Data Elenco",
                    "importo"         : "Importo",
                    "tipoRuolo"           : "Ruolo",
                    "importoLordo"    : "Importo Lordo",
                    "annoRuolo"       : "Anno Ruolo",
                    "annoEmissione"   : "Anno Emissione",
                    "progrEmissione"  : "Progr. Emissione",
                    "invioConsorzio"  : "Invio Consorzio",
                    "motivoSgravioCat": "Motivo Sgravio",
                    "tipoTributo"     : "Tipo Tributo",
                    "tipoSgravioDesc" : "Tipo"
            ]

            String nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.SGRAVI,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile,
                    listaSgravi, fields, converters
            )

        }
    }


    @Command
    def onDettaglioElenco() {
        commonService.creaPopup(
                "/ufficiotributi/imposte/sgraviFunzioni.zul", self, [tipoFunzione: "dettaglioElenco"]
        )
    }

    @Command
    def onNumeraElenco() {

        commonService.creaPopup("/ufficiotributi/imposte/sgraviFunzioni.zul", self, [tipoFunzione: "numeraElenco"],
                { event ->
                    onRefresh()
                }
        )
    }

    @Command
    def onAnnullaElenco() {

        commonService.creaPopup("/ufficiotributi/imposte/sgraviFunzioni.zul", self, [tipoFunzione: "annullaElenco"],
                { event ->
                    onRefresh()
                }
        )
    }

    @Command
    def onDettaglioSgravio() {
        commonService.creaPopup("/ufficiotributi/imposte/sgraviFunzioni.zul", self,
                [tipoFunzione: "dettaglioSgravio", sgravioSelezionato: sgravioSelezionato])
    }

    private def caricalistaSgravi() {
        def result =
                sgraviService.getListaSgraviFiltrati(
                        parametriFiltroAttuali,
                        pagingSgravi.pageSize,
                        pagingSgravi.activePage
                )
        listaSgravi = result.records
        pagingSgravi.totalSize = result.totalCount

        sgraviGroupsModel =
                new SgraviGroupsModel(
                        listaSgravi as Object[],
                        { a, b -> a.numeroElenco <=> b.numeroElenco ?: a.dataElenco <=> b.dataElenco }
                )

        sgravioSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "sgravioSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pagingSgravi")
        BindUtils.postNotifyChange(null, null, this, "listaSgravi")
        BindUtils.postNotifyChange(null, null, this, "sgraviGroupsModel")
    }

    private resetPaginazione() {
        pagingSgravi.activePage = 0
        pagingSgravi.totalSize = 0

        BindUtils.postNotifyChange(null, null, this, "pagingSgravi")
        BindUtils.postNotifyChange(null, null, this, "listaSgravi")
    }
}
