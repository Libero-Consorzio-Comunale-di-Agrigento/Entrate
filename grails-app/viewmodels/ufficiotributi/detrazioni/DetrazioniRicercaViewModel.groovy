package ufficiotributi.detrazioni

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.imposte.DetrazioniService
import it.finmatica.tr4.imposte.FiltroRicercaImposteDetrazioni
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DetrazioniRicercaViewModel {

    //Services
    DetrazioniService detrazioniService
    CompetenzeService competenzeService

    // Componenti
    Window self

    //Comuni
    FiltroRicercaImposteDetrazioni filtri
    def listaTipiTributo
    def listaMotivi, listaMotiviReverse
    def listaTipiAliquota, listaTipiAliquotaReverse
    def tabSelezionato
    def competenzeTipiTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def f,
         @ExecutionArgParam("tabSelezionato") def ts,
         @ExecutionArgParam("tipiTributo") def tt) {

        this.self = w
        this.filtri = f
        this.tabSelezionato = ts
        this.competenzeTipiTributo = tt

        caricaDati()

        filtri.motivoDa = filtri.motivoDa != null ? filtri.motivoDa : listaMotivi[0]
        filtri.motivoA = filtri.motivoA != null ? filtri.motivoA : listaMotiviReverse[0]
        filtri.tipoAliquotaDa = filtri.tipoAliquotaDa != null ? filtri.tipoAliquotaDa : listaTipiAliquota[0]
        filtri.tipoAliquotaA = filtri.tipoAliquotaA != null ? filtri.tipoAliquotaA : listaTipiAliquotaReverse[0]
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
        if (filtri.motivoDa && filtri.motivoA) {
            if (filtri.motivoDa.motivoDetrazione > filtri.motivoA.motivoDetrazione) {
                errorMessage += "Motivo Da non può essere maggiore di Motivo A\n"
            }
        }
        if (filtri.tipoAliquotaDa && filtri.tipoAliquotaA) {
            if (filtri.tipoAliquotaDa.tipoAliquota > filtri.tipoAliquotaA.tipoAliquota) {
                errorMessage += "Tipo Aliquota Da non può essere maggiore di Tipo Aliquota A\n"
            }
        }
        if (filtri.detrazioneDa != null && filtri.detrazioneA != null) {
            if (filtri.detrazioneDa > filtri.detrazioneA) {
                errorMessage += "Detrazione Da non può essere maggiore di Detrazione A\n"
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
        pulisciFiltro()
    }


    private caricaDati(def cambioTributo = false) {

        listaMotivi = detrazioniService.getMotiviDetrazione(filtri.tipoTributo)
        listaMotiviReverse = listaMotivi.reverse()
        listaTipiAliquota = OggettiCache.TIPI_ALIQUOTA.valore.findAll { it.tipoTributo.tipoTributo == filtri.tipoTributo.tipoTributo }
        listaTipiAliquotaReverse = listaTipiAliquota.reverse()

        if (cambioTributo) {
            filtri.motivoDa = listaMotivi[0]
            filtri.motivoA = listaMotiviReverse[0]
            filtri.tipoAliquotaDa = listaTipiAliquota[0]
            filtri.tipoAliquotaA = listaTipiAliquotaReverse[0]
        }

        BindUtils.postNotifyChange(null, null, this, "listaTipiTributo")
        BindUtils.postNotifyChange(null, null, this, "listaMotivi")
        BindUtils.postNotifyChange(null, null, this, "listaMotiviReverse")
        BindUtils.postNotifyChange(null, null, this, "listaTipiAliquota")
        BindUtils.postNotifyChange(null, null, this, "listaTipiAliquotaReverse")
    }

    private def pulisciFiltro() {

        filtri.annoDa = null
        filtri.annoA = null

        if (tabSelezionato == "detrazioni") {
            filtri.detrazioneDa = null
            filtri.detrazioneA = null
            filtri.motivoDa = listaMotivi[0]
            filtri.motivoA = listaMotiviReverse[0]
        } else if (tabSelezionato == "aliquote") {
            filtri.tipoAliquotaDa = listaTipiAliquota[0]
            filtri.tipoAliquotaA = listaTipiAliquotaReverse[0]
        }

        BindUtils.postNotifyChange(null, null, this, "filtri")
    }


}
