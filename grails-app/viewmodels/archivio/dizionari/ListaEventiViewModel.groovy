package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheEventiService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class ListaEventiViewModel {

    // Componenti
    Window self

    // Services
    CodificheEventiService codificheEventiService

    // Comuni
    def tipoEventoSelezionato
    def listaTipiEvento = []
    def eventoSelezionato
    def listaEventi = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
        this.listaTipiEvento = codificheEventiService.getListaTipiEvento()

        //Imposto come tipo evento selezionato di default il primo della lista
        if (listaTipiEvento.size() > 0)
            this.tipoEventoSelezionato = this.listaTipiEvento.get(0)

        //Filtro tutti gli eventi prendendo solo quelli del Tipo Evento selezionato
        this.listaEventi = codificheEventiService.listaEventi.findAll {
            it.tipoEvento.equals(tipoEventoSelezionato.tipoEvento)
        }.collect()

    }

    @Command
    onCambiaTipoEventoSelezionato(@BindingParam("tipoEvento") def tipoEvento) {
        //Filtro tutti gli eventi prendendo solo quelli del Tipo Evento selezionato
        this.listaEventi = codificheEventiService.listaEventi.findAll {
            it.tipoEvento.equals(tipoEvento.tipoEvento)
        }.collect()
        BindUtils.postNotifyChange(null, null, this, "listaEventi")
    }

    @Command
    onAggiungi(@BindingParam("tipo") def tipo) {

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioEventi.zul", self,
                [evento: null, tipo: tipo, tipoEvento: tipoEventoSelezionato.tipoEvento, isModifica: false])

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            if (tipo.equals("tipoevento"))
                onRefreshTipiEvento()
            else if (tipo.equals("evento"))
                onRefreshEventi()
        }
    }

    @Command
    def onModifica(@BindingParam("tipo") def tipo) {

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioEventi.zul", self,
                [evento: tipo.equals("tipoevento") ? tipoEventoSelezionato : eventoSelezionato, tipo: tipo, tipoEvento: tipoEventoSelezionato.tipoEvento, isModifica: true])

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            if (tipo.equals("tipoevento"))
                onRefreshTipiEvento()
            else if (tipo.equals("evento"))
                onRefreshEventi()
        }
    }

    @Command
    def onElimina(@BindingParam("tipo") def tipo) {

        StringBuilder sb = new StringBuilder()
        sb.append("Si è scelto di eliminare il seguente ").append(tipo.equals("tipoevento") ? "Tipo Evento" : "Evento").append(":\n")
        sb.append(tipo.equals("tipoevento") ? "Tipo Evento: " : "Sequenza: ").append(tipo.equals("tipoevento") ? tipoEventoSelezionato.tipoEvento : eventoSelezionato.sequenza).append("\n")
        sb.append("Descrizione: ").append(tipo.equals("tipoevento") ? tipoEventoSelezionato.descrizione : eventoSelezionato.descrizione).append("\n")
        if (tipo.equals("evento")) {
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            sb.append("Data: ").append(sdf.format(eventoSelezionato.dataEvento)).append("\n")
        }
        sb.append(tipo.equals("tipoevento") ? "Il tipo evento " : "L'evento ").append("verrà eliminato e non sarà recuperabile.\n")
        sb.append("Si conferma l'operazione?")


        Messagebox.show(sb.toString(), tipo.equals("tipoevento") ? "Eliminazione Tipo Evento" : "Eliminazione Evento", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {
                    def dto

                    if (tipo.equals("tipoevento")) {
                        dto = codificheEventiService.getTipoEventoDTO(tipoEventoSelezionato, true)
                        def messaggio = codificheEventiService.eliminaTipoEvento(dto)
                        visualizzaRisultatoEliminazione(messaggio)
                        onRefreshTipiEvento()
                    } else if (tipo.equals("evento")) {
                        dto = codificheEventiService.getEventoDTO(eventoSelezionato, true)
                        def messaggio = codificheEventiService.eliminaEvento(dto)
                        visualizzaRisultatoEliminazione(messaggio)
                        onRefreshEventi()
                    }
                }
            }
        })
    }

    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo!"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    @Command
    onDuplica(@BindingParam("tipo") def tipo) {

        def clone = [:]

        if (tipo.equals("tipoevento")) {

            tipoEventoSelezionato.each {
                clone << it
            }
            clone.tipoEvento = ""

        } else if (tipo.equals("evento")) {

            eventoSelezionato.each {
                clone << it
            }
            clone.sequenza = null
        }

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioEventi.zul", self,
                [evento: clone,
                 tipo  : tipo, tipoEvento: tipoEventoSelezionato.tipoEvento, isModifica: false])

        w.doModal()
        w.onClose() { event ->
            //Carico la lista di codifiche aggiornata
            if (tipo.equals("tipoevento"))
                onRefreshTipiEvento()
            else if (tipo.equals("evento"))
                onRefreshEventi()
        }


    }

    @Command
    onExportXlsTipiEvento() {

        Map fields

        if (listaTipiEvento) {

            fields = [
                    "tipoEvento" : "Tipo Evento",
                    "descrizione": "Descrizione"
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CODIFICHE_TIPI_EVENTO,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, listaTipiEvento, fields)
        }
    }

    @Command
    onExportXlsEventi() {

        Map fields

        if (listaEventi) {

            fields = [
                    "sequenza"   : "Seq.",
                    "dataEvento" : "Data",
                    "descrizione": "Descrizione",
                    "note"       : "Note"
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.CODIFICHE_EVENTI,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, listaEventi, fields)
        }
    }

    @Command
    onRefreshTipiEvento() {
        listaTipiEvento = codificheEventiService.listaTipiEvento
        BindUtils.postNotifyChange(null, null, this, "listaTipiEvento")
    }

    @Command
    onRefreshEventi() {

        //Filtro tutti gli eventi prendendo solo quelli del Tipo Evento selezionato
        this.listaEventi = codificheEventiService.listaEventi.findAll {
            it.tipoEvento.equals(tipoEventoSelezionato.tipoEvento)
        }.collect()

        BindUtils.postNotifyChange(null, null, this, "listaEventi")

    }

}
