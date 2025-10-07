package ufficiotributi.imposte

import it.finmatica.tr4.Compensazione
import it.finmatica.tr4.MotivoCompensazione
import it.finmatica.tr4.imposte.CompensazioniService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioCompensazioneViewModel {

    //Services
    CompensazioniService compensazioniService
    def springSecurityService

    // Componenti
    Window self

    //Comuni
    def listaTipiTributo
    def listaMotivi
    def parametri
    def isModifica
    def isClonazione
    def codFiscale
    def compensazioneSelezionata


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("isModifica") def im,
         @ExecutionArgParam("isClonazione") def ic,
         @ExecutionArgParam("codFiscale") def cf,
         @ExecutionArgParam("compensazioneSelezionata") def cs) {

        this.self = w
        this.isModifica = im
        this.isClonazione = ic
        this.codFiscale = cf
        this.compensazioneSelezionata = cs

        this.listaTipiTributo = compensazioniService.getTipiTributo()
        this.listaMotivi = compensazioniService.getMotivi()

        initParametri()

    }


    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOk() {

        if (!isModifica) {//aggiunta

            def messaggio = compensazioniService.controlloParametriSalvataggio(parametri)

            if (messaggio.length() > 0) {
                Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
                return
            }

            aggiungiCompensazione()

        } else {//modifica - clonazione

            def messaggio = compensazioniService.controlloParametriModifica(parametri)

            if (messaggio.length() > 0) {
                Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, self, "top_center", 5000, true)
                return
            }

            modificaCompensazione()
        }

        Events.postEvent(Events.ON_CLOSE, self, null)
    }


    private def initParametri() {

        if (!isModifica) {
            parametri = [
                    tipoTributo  : "TARSU",
                    desTitr      : "TARI",
                    anno         : null,
                    motivo       : null,
                    compensazione: null,
                    versamento   : null,
                    auto         : null,
                    codFiscale   : codFiscale,
                    note         : null,
                    utente       : null,
                    versPresente : false,
            ]
        } else {

            def compensazione = compensazioniService.getCompensazione(compensazioneSelezionata.idCompensazione)

            parametri = [
                    tipoTributo  : compensazioneSelezionata.tipoTributo,
                    desTitr      : compensazioneSelezionata.desTitr,
                    anno         : compensazioneSelezionata.anno,
                    motivo       : listaMotivi.find {
                        it.motivoCompensazione == compensazioneSelezionata.motivoCompensazione
                    },
                    compensazione: compensazioneSelezionata.compensazione,
                    versamento   : compensazione.versamento,
                    versPresente : compensazione.versPresente,
                    auto         : compensazioneSelezionata.flagAutomatico,
                    codFiscale   : compensazioneSelezionata.codFiscale,
                    note         : compensazioneSelezionata.note,
                    utente       : compensazioneSelezionata.utente
            ]
        }
    }

    private def aggiungiCompensazione() {

        Compensazione compensazione = new Compensazione()

        MotivoCompensazione motivo = new MotivoCompensazione()

        motivo.id = parametri.motivo.motivoCompensazione
        motivo.descrizione = parametri.motivo.descrizione

        compensazione.anno = parametri.anno
        compensazione.tipoTributo = parametri.tipoTributo
        compensazione.motivoCompensazione = motivo
        compensazione.utente = springSecurityService.currentUser.id
        compensazione.flagAutomatico = parametri.auto
        compensazione.compensazione = parametri.compensazione
        compensazione.codFiscale = codFiscale
        compensazione.lastUpdated = new Date()
        compensazione.note = parametri.note

        compensazioniService.salvaCompensazione(compensazione)

    }

    private def modificaCompensazione() {

        Compensazione compensazione = new Compensazione()
        MotivoCompensazione motivo = new MotivoCompensazione()

        compensazione.id = isClonazione ? null : compensazioneSelezionata.idCompensazione

        motivo.id = parametri.motivo.motivoCompensazione
        motivo.descrizione = parametri.motivo.descrizione
        compensazione.anno = parametri.anno
        compensazione.tipoTributo = compensazioneSelezionata.tipoTributo
        compensazione.motivoCompensazione = motivo
        compensazione.utente = compensazioneSelezionata.utente
        compensazione.flagAutomatico = compensazioneSelezionata.flagAutomatico
        compensazione.compensazione = parametri.compensazione
        compensazione.codFiscale = compensazioneSelezionata.codFiscale
        compensazione.lastUpdated = new Date()
        compensazione.note = parametri.note

        compensazioniService.salvaCompensazione(compensazione)
    }

}
