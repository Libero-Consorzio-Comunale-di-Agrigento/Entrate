package catasto

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.oggetti.OggettiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class InserimentoOggettoRenditeViewModel {

    Window self
    def springSecurityService
    OggettiService oggettiService

    def immobile
    def oggetto
    def tipoImmobile
    def cessatiDopo = new Date('01/01/1990')
    def seCessati = true

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("immobile") Long i
         , @ExecutionArgParam("oggetto") Long o
         , @ExecutionArgParam("tipoImmobile") String ti
    ) {

        self = w

        this.immobile = i
        this.oggetto = o
        this.tipoImmobile = ti
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def inserisciOggettoRendite() {

        def controlo = oggettiService.controlloRiog(immobile, oggetto, tipoImmobile)
        if (controlo == 0) {
            eseguinInserimentoOggettiRendite()
        } else if (controlo == 1) {
            String messaggio = "Esistono periodi intersecati. Sovrascrivere?"
            Messagebox.show(messaggio, "Inserimento Oggetto/Rendite",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        public void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                eseguinInserimentoOggettiRendite()
                            }
                        }
                    }
            )
        } else if (controlo == 2) {
            Events.postEvent(Events.ON_CLOSE, self, null)
            Messagebox.show("Non esistono dati da acquisire.", "Inserimento Oggetto/Rendite", Messagebox.OK, Messagebox.INFORMATION)
        } else {
            throw new RuntimeException("oggettiService.controlloRiog($immobile, $oggetto, $tipoImmobile) non supportato")
        }


    }


    private eseguinInserimentoOggettiRendite() {
        try {
            def result = oggettiService.inserimentoOggettiRendite(
                    immobile,
                    oggetto,
                    tipoImmobile,
                    cessatiDopo,
                    seCessati ? 'S' : 'N'
            )

            if (result == null) {
                Events.postEvent(Events.ON_CLOSE, self, [esito: "OK"])
                Messagebox.show("Oggetto/Rendite inseriti", "Inserimento Oggetto/Rendite", Messagebox.OK, Messagebox.INFORMATION)
            } else {
                Events.postEvent(Events.ON_CLOSE, self, [esito: "OK"])
                Clients.showNotification(result, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            }
        } catch (Exception e) {

            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            } else {
                throw e
            }
        }

    }
}
