package archivio.dizionari

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.RuoliAutomaticiDTO
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Bandbox
import org.zkoss.zul.Window

class DettaglioRuoloAutomaticoViewModel {

    // Componenti
    Window self
    def bdRuoli

    // Service
    ListeDiCaricoRuoliService listeDiCaricoRuoliService
    CommonService commonService
    CompetenzeService competenzeService

    RuoliAutomaticiDTO ruoloAutomatico
    def listaRuoli

    def tipoEmissione = [
            A: "Acconto",
            S: "Saldo",
            T: "Totale",
            X: ''
    ]

    def tipoRuolo = [
            1: 'P - Principale',
            2: 'S - Suppletivo'
    ]

    def selectedTipoRuolo = 1

    Boolean lettura = true
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("ruoloAutomatico") RuoliAutomaticiDTO ruoloAutomatico) {

        this.self = w

        this.ruoloAutomatico = ruoloAutomatico

        aggiornaCompetenze()

        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    def onSalva() {

        if (areRequiredFieldsEmptyAndNotify()) {
            return
        }

        if (isOverlappingAndNotify()) {
            return
        }
        
        listeDiCaricoRuoliService.salvaRuoloAutomatico(ruoloAutomatico)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
        
        Events.postEvent(Events.ON_CLOSE, self, [salvato: true])
    }

    private def areRequiredFieldsEmptyAndNotify() {
        def errors = []
        if (!ruoloAutomatico.daData) {
            errors << 'Dal obbligatorio'
        }
        if (!ruoloAutomatico.aData) {
            errors << 'Al obbligatorio'
        }
        if (!ruoloAutomatico.ruolo) {
            errors << 'Ruolo obbligatorio'
        }
        if (ruoloAutomatico.aData && ruoloAutomatico.daData && ruoloAutomatico.aData < ruoloAutomatico.daData) {
            errors << 'Dal deve essere minore o uguale ad Al'
        }
        if (!errors.empty) {
            Clients.showNotification(errors.join('\n'),
                    Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 2000, true)
            return true
        }
        return false
    }

    def isOverlappingAndNotify() {
        if (listeDiCaricoRuoliService.existsOverlappingRuoloAutomatico(ruoloAutomatico)) {
            Clients.showNotification("Esistono periodi intersecanti",
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return true
        }
        return false
    }

    @Command
    def onNuovaListaDiCarico() {
        commonService.creaPopup("/ufficiotributi/imposte/dettaglioListaDiCarico.zul",
                self,
                [
                        ruolo      : null,
                        tipoTributo: ruoloAutomatico.tipoTributo.tipoTributo,
                        modifica   : true
                ],
                { e ->
                    if (e.data?.ruolo) {
                        ruoloAutomatico.ruolo = e.data?.ruolo
                        BindUtils.postNotifyChange(null, null, this, "ruoloAutomatico")
                    }
                })
    }

    @Command
    def onNuovoRuoloCoattivo() {
        commonService.creaPopup("/ufficiotributi/imposte/dettaglioRuoloCoattivo.zul",
                self,
                [
                        ruolo      : null,
                        tipoTributo: ruoloAutomatico.tipoTributo.tipoTributo,
                        modifica   : true
                ],
                { e ->
                    if (e.data?.ruolo) {
                        ruoloAutomatico.ruolo = e.data?.ruolo
                        BindUtils.postNotifyChange(null, null, this, "ruoloAutomatico")
                    }
                })
    }

    @Command
    def onSelezionaRuolo() {
        bdRuoli?.close()
    }

    @Command
    def onApriRuolo(@BindingParam("bd") Bandbox bd) {
        caricaRuoli()
        bdRuoli = bd
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private caricaRuoli() {

        listaRuoli = Ruolo.createCriteria().list {
            eq('tipoTributo', ruoloAutomatico.tipoTributo.toDomain())

            and {
                isNull('invioConsorzio')
                eq('tipoRuolo', selectedTipoRuolo)

                gte("dataEmissione", ruoloAutomatico.aData ?: ruoloAutomatico.daData)

            }

            order("tipoRuolo")
            order("annoRuolo")
            order("annoEmissione")
            order("progrEmissione")
            order("dataEmissione")
            order("invioConsorzio")

        }.toDTO()

        BindUtils.postNotifyChange(null, null, this, "listaRuoli")
    }

    private def aggiornaCompetenze() {

        String tipoTributo = ruoloAutomatico?.tipoTributo?.tipoTributo ?: '-'
        lettura = (competenzeService.tipoAbilitazioneUtente(tipoTributo) != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        BindUtils.postNotifyChange(null, null, this, "lettura")
    }
}
