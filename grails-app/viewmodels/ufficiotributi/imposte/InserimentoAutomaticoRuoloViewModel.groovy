package ufficiotributi.imposte

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.dto.RuoloDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class InserimentoAutomaticoRuoloViewModel {

    // Services
    def springSecurityService

    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // Componenti
    Window self

    // Generali
    boolean aggiornaStato = false

    TributiSession tributiSession

    TipoTributoDTO tipoTributo
    String tipoTributoDescr

    // Dati
    RuoloDTO ruolo

    def mapParametri = [
            tipoPratica      : 'T',
            tipoEvento       : 'T',
            notificaDal      : null,
            notificaAl       : null,
            diffDovutoVersato: null
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") Long rr) {

        this.self = w

        ruolo = Ruolo.get(rr).toDTO()

        tipoTributo = ruolo.tipoTributo
        tipoTributoDescr = tipoTributo.getTipoTributoAttuale()
    }

    // Eventi interfaccia

    @Command
    def onCheckTipoPratica() {

    }

    @Command
    def onCheckTipoEvento() {

    }

    @Command
    def onApplica() {

        try {
            if (listeDiCaricoRuoliService
                    .proceduraInserimentoRuoloCoattivo(ruolo.id,
                            mapParametri.tipoPratica,
                            mapParametri.tipoEvento,
                            mapParametri.notificaDal, mapParametri.notificaAl,
                            mapParametri.diffDovutoVersato) == 'OK') {

                Clients.showNotification("Inserimento Ruolo Coattivo eseguito con successo!",
                        Clients.NOTIFICATION_TYPE_INFO, self,
                        "before_center", 5000, true)
                aggiornaStato = true
            }
        }
        catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                throw e
            }
        }
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [aggiornaStato: aggiornaStato])
    }
}
