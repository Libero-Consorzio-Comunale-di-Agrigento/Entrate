package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheTipoTributoService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Executions
import org.zkoss.zul.Window

class ListaTipiTributoViewModel {

    // Componenti
    Window self

    // Services
    CodificheTipoTributoService codificheTipoTributoService

    // Comuni
    def tipoTributoSelezionato
    def listaTipiTributo = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
        this.listaTipiTributo = codificheTipoTributoService.getListaTipiTributo()

    }

    @Command
    def onModificaTipoTributo() {

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioTipiTributo.zul", self,
                [tipoTributo: tipoTributoSelezionato])

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            onRefresh()
        }
    }


    @Command
    def onExportXls() {

        Map fields

        fields = [
                "tipoTributo"     : "Tipo Tributo",
                "descrizione"     : "Descrizione",
                "contoCorrente"   : "Conto Corrente",
                "descrizioneCc"   : "Descrizione CC",
                "flagCanone"      : "Canone",
                "flagTariffa"     : "Tariffa",
                "flagLiqRiog"     : "Liquidazione RIOG",
                "codEnte"         : "Cod. Ente",
                "indirizzoUfficio": "Indirizzo Ufficio",
                "tipoUfficio"     : "Tipo Ufficio",
                "codUfficio"      : "Codice Ufficio",
                "ufficio"         : "Descrizione Ufficio",
                "testoBollettino" : "Testo per bollettino a 3 Parti"
        ]

        def converters = [
                flagCanone : Converters.flagString,
                flagTariffa: Converters.flagString,
                flagLiqRiog: Converters.flagString,
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CODIFICHE_TIPI_TRIBUTO,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaTipiTributo, fields, converters)
    }

    @Command
    onRefresh() {
        listaTipiTributo = codificheTipoTributoService.getListaTipiTributo()
        BindUtils.postNotifyChange(null, null, this, "listaTipiTributo")
    }


}
