package ufficiotributi.imposte

import it.finmatica.tr4.imposte.CompensazioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CompensazioniRicercaViewModel {

    //Services
    CompensazioniService compensazioniService

    // Componenti
    Window self

    //Comuni
    def filtri
    def listaTipiTributo
    def listaMotivi
    def listaMotiviReverse

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def f) {

        this.self = w
        this.filtri = f

        caricaDati()
    }


    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onCerca() {

        String errorMessage = ""

        //Controllo campi inseriti
        if (filtri.annoDa && filtri.annoA) {
            if (filtri.annoDa > filtri.annoA) {
                errorMessage += "Anno Da non può essere maggiore di anno A\n"
            }
        }
        if (filtri.compensazioneDa && filtri.compensazioneA) {
            if (filtri.compensazioneDa > filtri.compensazioneA) {
                errorMessage += "Compensazione Da non può essere maggiore di Compensazione A\n"
            }
        }
        if (filtri.motivoDa && filtri.motivoA) {
            if (filtri.motivoDa.id > filtri.motivoA.id) {
                errorMessage += "Motivo Da non può essere maggiore di Motivo A\n"
            }
        }

        if (errorMessage.length() > 0) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [filtriAggiornati: filtri])
    }

    @Command
    def onSvuotaFiltri() {
        filtri = [
                tipoTributo    : "TARSU",
                annoDa         : null,
                annoA          : null,
                compensazioneDa: null,
                compensazioneA : null,
                motivoDa       : listaMotivi[0],
                motivoA        : listaMotiviReverse[0]
        ]
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


    private caricaDati() {

        listaTipiTributo = compensazioniService.getTipiTributo()
        listaMotivi = compensazioniService.getMotivi()
        listaMotiviReverse = listaMotivi.reverse()
        BindUtils.postNotifyChange(null, null, this, "listaTipiTributo")
        BindUtils.postNotifyChange(null, null, this, "listaMotivi")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviReverse")
    }
}
