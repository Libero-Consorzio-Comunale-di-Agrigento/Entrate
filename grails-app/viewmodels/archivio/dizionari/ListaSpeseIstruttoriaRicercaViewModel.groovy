package archivio.dizionari

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ListaSpeseIstruttoriaRicercaViewModel {

    // Services

    // Componenti
    Window self

    // Comuni
    def filtri


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def pr) {

        this.self = w

        this.filtri = pr ?: [:]
    }

    @Command
    onCerca() {

        def errori = controllaFiltri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }
        Events.postEvent(Events.ON_CLOSE, self, [filtri: filtri])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onCancellaFiltri() {

        this.filtri = [
                annoDa          : null,
                annoA           : null,
                daImportoDa     : null,
                daImportoA      : null,
                aImportoDa      : null,
                aImportoA       : null,
                daSpese         : null,
                aSpese          : null,
                daPercInsolvenza: null,
                aPercInsolvenza : null
        ]

        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


    def controllaFiltri() {

        def errori = []

        if (filtri.annoDa != null && filtri.annoA != null && filtri.annoDa > filtri.annoA) {
            errori << "Anno Da deve essere minore di Anno A"
        }

        if (filtri.daImportoDa != null && filtri.daImportoA != null && filtri.daImportoDa > filtri.daImportoA) {
            errori << "Gli Importi Da devono essere minori degli Importi A"
        }

        if (filtri.aImportoDa != null && filtri.aImportoA != null && filtri.aImportoDa > filtri.aImportoA) {
            errori << "Gli Importi Da devono essere minori degli Importi A"
        }

        if (filtri.daSpese != null && filtri.aSpese != null && filtri.daSpese > filtri.aSpese) {
            errori << "Spese Da deve essere minore di Spese A"
        }

        if (filtri.daPercInsolvenza != null && filtri.aPercInsolvenza != null && filtri.daPercInsolvenza > filtri.aPercInsolvenza) {
            errori << "% Insolvenza Da deve essere minore di % Insolvenza"
        }

        return errori
    }


}
