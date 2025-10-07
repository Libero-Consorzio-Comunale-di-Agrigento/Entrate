package ufficiotributi.imposte

import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.imposte.SgraviService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class RuoliOggettiSgraviCalcoloViewModel {

    // Componenti
    Window self

    // Services
    SgraviService sgraviService


    // Comuni
    def listaMotivi
    def listaTipi
    def ruolo
    def codFiscale
    def sequenza
    def oggPratica
    //Selezioni
    def tipoSelezionato
    def motivoSelezionato
    def isCalcoloNormalizzato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruolo") def r) {

        this.self = w
        this.listaMotivi = sgraviService.getMotiviSgravio()
        this.ruolo = r

        this.listaTipi = [null: null, D: "Discarico", S: "Sgravio", R: "Rimborso"]

        isCalcoloNormalizzato = true
        motivoSelezionato = listaMotivi[0]
        tipoSelezionato = "D"

    }

    @Command
    def onAnnulla() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOk() {
        if (motivoSelezionato == null) {
            Messagebox.show("Il campo Motivo Sgravio è obbligatorio!", "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
            return
        }

        RuoloContribuente ruoloContribuente = sgraviService.getRuoloContribuente(ruolo.ruolo, ruolo.codFiscale, ruolo.sequenza)

        def result = sgraviService.calcolaSgravio([
                codFiscale         : ruolo.codFiscale,
                ruolo              : ruolo.ruolo,
                sequenza           : ruolo.sequenza,
                motivo             : motivoSelezionato,
                tipo               : tipoSelezionato,
                oggPratica         : ruoloContribuente.oggettoImposta.oggettoContribuente.oggettoPratica.id,
                calcoloNormalizzato: this.isCalcoloNormalizzato ? 'S' : 'N'
        ])

        Events.postEvent(Events.ON_CLOSE, self, [result: result])

    }
}
