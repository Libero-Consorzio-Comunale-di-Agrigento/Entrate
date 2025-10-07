package pratiche.utenze

import document.FileNameGenerator
import it.finmatica.tr4.contribuenti.UtenzeService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ElencoUtenzeDaControllareViewModel {

    Window self

    //Servizi
    UtenzeService utenzeService

    def listaUtenti

    String titolo
    String anno
    String codiceFiscale
    def resultFromDb

    /// Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 20,
            totalSize : 0
    ]


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") String anno,
         @ExecutionArgParam("codiceFiscale") String codiceFiscale
    ) {


        this.self = w
        this.anno = anno
        this.codiceFiscale = codiceFiscale

        resultFromDb = utenzeService.controlloUtenze(codiceFiscale, anno, pagingList.pageSize, pagingList.activePage)

        listaUtenti = resultFromDb.lista
        int numeroTotaleUtenze = resultFromDb.totaleUtenze

        if (numeroTotaleUtenze == 0) {
            noUser()
            return
        }

        pagingList.totalSize = numeroTotaleUtenze
        this.titolo = "Contribuenti con utenze domestiche incoerenti per l'anno $anno"
    }

    private void noUser() {

        String message
        if (codiceFiscale == UtenzeService.ALL_FISCAL_CODE) {
            message = "Le utenze dei contribuenti per l'anno : ${anno} sono corrette"
        } else {
            message = "Le utenze del contribuente sono corrette"
        }

        Events.postEvent(Events.ON_CLOSE, self, [status: utenzeService.NO_USERS_FOUND, message: message])

    }

    @Command
    onCambioPagina() {

        resultFromDb = utenzeService.controlloUtenze(codiceFiscale, anno, pagingList.pageSize, pagingList.activePage)

        listaUtenti = resultFromDb.lista
        int numeroTotaleUtenze = resultFromDb.totaleUtenze.intValue()

        pagingList.totalSize = numeroTotaleUtenze

    }


    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Close"])
    }

    @Command
    onUtentiToXls() {

        Map fields

        List listaUtenze = (utenzeService.controlloUtenze(codiceFiscale, anno,Integer.MAX_VALUE,0) as HashMap).lista

        fields = [
                "ni"         : "N.Ind.",
                "cognomeNome": "Contribuente",
                "codFiscale" : "Codice Fiscale",
                "tributo"    : "C.Trib.",
                "categoria"  : "Cat.",
                "messaggio"  : "Messaggio"
        ]


        def formatters =
                ["ni"       : Converters.decimalToInteger,
                 "tributo"  : Converters.decimalToInteger,
                 "categoria": Converters.decimalToInteger
                ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.LISTA_UTENTI,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaUtenze, fields, formatters)

    }
}
