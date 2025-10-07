package pratiche.violazioni

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

import java.text.DecimalFormat

class RicalcoliLiquidazioneViewModel {
    static def DEFAULT_SPESA_NOTIFICA = [:]
    static String DEFAULT_SPESA_NOTIFICA_LABEL = 'MANTIENI ATTUALE'

    LiquidazioniAccertamentiService liquidazioniAccertamentiService

    Window self
    def tipoTributo
    def defaultSpesaNotificaLabel = DEFAULT_SPESA_NOTIFICA_LABEL

    boolean interessiEnabled
    boolean speseNotificaEnabled
    boolean creaEnabled = true

    boolean interessiChecked = false
    boolean speseNotificaChecked = false
    boolean creaChecked = false

    def listaSpeseNotifica
    def speseNotificaSelected
    def listaImporti
    def importoSelected

    def sanzioniLabels = [:]

    @Init
    void init(@ContextParam(ContextType.COMPONENT) Window w,
              @ExecutionArgParam('tipoTributo') String tipoTributo,
              @ExecutionArgParam("interessiEnabled") boolean interessiEnabled,
              @ExecutionArgParam("speseNotificaEnabled") boolean speseNotificaEnabled) {
        self = w
        this.interessiEnabled = interessiEnabled
        this.speseNotificaEnabled = speseNotificaEnabled

        this.tipoTributo = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributo }

        fetchSpeseNotifica()
        fetchImporti()
        fetchCrea()
    }

    private fetchSpeseNotifica() {
        if (speseNotificaChecked) {
            listaSpeseNotifica = [
                    DEFAULT_SPESA_NOTIFICA,
                    *liquidazioniAccertamentiService.getSanzioniSpeseNotificaRicalcolabili(tipoTributo)
            ]
            speseNotificaSelected = listaSpeseNotifica.first()
            listaSpeseNotifica.each {
                def currencyFormatter = new DecimalFormat("€ #,##0.00")
                sanzioniLabels[it] = it?.codSanzione ? "${it.codSanzione} - ${it.descrizione} (${currencyFormatter.format(it.sanzione)}) ${' ' * it.sequenza}" : defaultSpesaNotificaLabel
            }
        } else {
            listaSpeseNotifica = null
            speseNotificaSelected = null
        }
        BindUtils.postNotifyChange(null, null, this, 'listaSpeseNotifica')
        BindUtils.postNotifyChange(null, null, this, 'speseNotificaSelected')
    }

    private fetchImporti() {
        if (speseNotificaChecked) {
            listaImporti = [
                    null,
                    *liquidazioniAccertamentiService.getSpeseNotifica(tipoTributo)
            ]
            importoSelected = listaImporti.first()
        } else {
            listaImporti = null
            importoSelected = null
        }
        BindUtils.postNotifyChange(null, null, this, 'listaImporti')
        BindUtils.postNotifyChange(null, null, this, 'importoSelected')
    }

    private fetchCrea() {
        if (!speseNotificaChecked) {
            creaChecked = false
            creaEnabled = false
            BindUtils.postNotifyChange(null, null, this, 'creaChecked')
            BindUtils.postNotifyChange(null, null, this, 'creaEnabled')
            return
        }

        if (speseNotificaSelected == DEFAULT_SPESA_NOTIFICA) {
            creaChecked = false
            creaEnabled = false
            BindUtils.postNotifyChange(null, null, this, 'creaChecked')
            BindUtils.postNotifyChange(null, null, this, 'creaEnabled')
            return
        }

        creaEnabled = true
        BindUtils.postNotifyChange(null, null, this, 'creaEnabled')
    }

    @Command
    onCheckSpeseNotifica() {
        fetchSpeseNotifica()
        fetchImporti()
        fetchCrea()
    }

    @Command
    onSelectSpeseNotifica() {
        fetchCrea()
    }

    @Command
    onCalcola() {

        if (noneIsSelected()) {
            showNoneSelectedError()
            return
        }
        def result = [
                ricalcoloInteressi          : interessiChecked,
                ricalcoloSpeseNotifica      : speseNotificaChecked,
                ricalcoloSpeseNotificaParams: [
                        sanzione         : speseNotificaSelected == DEFAULT_SPESA_NOTIFICA ? null : speseNotificaSelected,
                        importo          : importoSelected,
                        creaSeNonPresenti: creaChecked
                ]
        ]
        Events.postEvent(Events.ON_CLOSE, self, result)
    }

    private noneIsSelected() {
        !interessiChecked && !speseNotificaChecked
    }

    private showNoneSelectedError() {
        Clients.showNotification("Selezionare almeno un tipo di ricalcolo",
                Clients.NOTIFICATION_TYPE_ERROR,
                null,
                "before_center",
                5000,
                true)
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
