package depag

import document.FileNameGenerator
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class EsitoDePagViewModel {

    // Services

    // Componenti
    Window self

    // Comuni
    String title
    List listaEsiti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("listaEsiti") def listaEsiti) {
        this.self = w
        this.title = "Invio a ${IntegrazioneDePagService.TITOLO_DEPAG}"

        this.listaEsiti = listaEsiti.collect {
            [pratica      : it.pratica,
             response     : it.response,
             denominazione: "${it.pratica.contribuente.soggetto.cognome} ${it.pratica.contribuente.soggetto.nome}"
            ]
        }

        if (listaEsiti.size() == 1) {
            def esito = listaEsiti.first()
            def messaggio = esito.response.messaggio.trim()
            def inviato = esito.response.inviato
            def notificationType = inviato ? Clients.NOTIFICATION_TYPE_INFO : Clients.NOTIFICATION_TYPE_WARNING
            def notificationMessage = "Documento ${inviato ? '' : 'non '}inviato a ${IntegrazioneDePagService.TITOLO_DEPAG}"
            if (messaggio) {
                notificationMessage += stringToMultiline(messaggio)
            }
            onChiudi()
            Clients.showNotification(notificationMessage, notificationType, self, "top_center", 60000, true)
            return
        }

        def nInviati = this.listaEsiti.count { it.response.inviato }
        def anyFailure = nInviati != listaEsiti.size()

        if (!anyFailure) {
            def notificationMessage = "$nInviati documenti inviati a ${IntegrazioneDePagService.TITOLO_DEPAG}"
            onChiudi()
            Clients.showNotification(notificationMessage, Clients.NOTIFICATION_TYPE_INFO, self, "top_center", 60000, true)
        }
    }

    @Command
    def onExportXls() {
        Map fields = [
                "denominazione"     : "Denominazione",
                "pratica.id"        : "Pratica",
                "pratica.anno"      : "Anno",
                "pratica.numero"    : "Numero",
                "response.inviato"    : "Stato",
                "response.messaggio": "Messaggio"
        ]

        def formatters = [
                "denomiazione"  : { esito -> "${esito.pratica.contribuente.soggetto.cognome} ${esito.pratica.contribuente.soggetto.nome}" },
                "response.inviato": Converters.flagBooleanToString
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.INVIO_DEPAG,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaEsiti, fields, formatters)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onClickErrore(@BindingParam("errore") String errore) {
        Messagebox.show(errore, "Errore", Messagebox.OK, Messagebox.EXCLAMATION)
    }

    private String stringToMultiline(String stringToSplit,
                                     String character = ' ',
                                     int maxRowLength = 100,
                                     int offset = 10) {
        def result = ""
        if (stringToSplit) {
            while (stringToSplit.size() > maxRowLength) {
                int indexWhereSplit = stringToSplit.indexOf(character, maxRowLength - offset) ?: maxRowLength
                def row = stringToSplit.substring(0, indexWhereSplit)
                result += "\n$row"
                stringToSplit = stringToSplit.substring(indexWhereSplit + 1)
            }
            result += "\n$stringToSplit"
        }
        return result
    }

}
