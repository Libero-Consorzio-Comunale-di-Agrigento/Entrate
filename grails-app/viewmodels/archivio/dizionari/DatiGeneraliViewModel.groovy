package archivio.dizionari

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DatiGeneraliViewModel {

    // componenti
    Window self

    // Services
    DatiGeneraliService datiGeneraliService

    OggettiCacheMap oggettiCacheMap

    def datiGenerali = [:]
    def datiSoggetto = [:]
    def datiBanca = [:]

    def listaAree = [
            [codice: null, descrizione: ''],
            [codice: 'NORD', descrizione: 'Nord'],
            [codice: 'CENTRO', descrizione: 'Centro'],
            [codice: 'SUD', descrizione: 'Sud'],
    ]

    def listaTipiComune = [
            [codice: null, descrizione: ''],
            [codice: 'INF', descrizione: 'Popolazione INFERIORE a 5.000 abitanti'],
            [codice: 'SUP', descrizione: 'Popolazione SUPERIORE a 5.000 abitanti'],
    ]

    def areaSelected = null
    def tipoComuneSelected = null

    Boolean modifica = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        modifica = true

        String message = ""

        try {
            datiGenerali = datiGeneraliService.extractDatiGenerali()
        } catch (Exception e) {
            message += e.message + "\n"
            e.printStackTrace()
        }

        try {
            datiSoggetto = datiGeneraliService.getDatiSoggettoCorrente()
        } catch (Exception e) {
            message += e.message + "\n"
            e.printStackTrace()
        }
        if (message.isEmpty()) {
            modifica = true
        } else {
            Messagebox.show(message, "Errore", Messagebox.OK, Messagebox.ERROR)
            modifica = false
        }

        areaSelected = listaAree.find { it.codice == datiGenerali.area }
        tipoComuneSelected = listaTipiComune.find { it.codice == datiGenerali.tipoComune }

        aggiornaDatiBanca()
    }

    @Command
    def onChangeCodAbiOppureCab() {
        aggiornaDatiBanca()
    }

    @Command
    onRadioCatastoCheck() {
        datiGenerali.catastoChanged = true
        BindUtils.postNotifyChange(null, null, this, "datiGenerali")
    }

    @Command
    onCreaSinonimiCu() {
        if (datiGenerali.flagCatastoCu == 'CC') { // Censuario
            datiGeneraliService.creaSinonimiCu()
        }
    }

    @Command
    def onSalva() {

        completaDati()

        if (!verificaDati()) return

        Messagebox.show("Salvare le modifiche?", "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            salva()
                            Clients.showNotification("Salvataggio effettuato con successo", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                        }
                    }
                }
        )
    }

    private def salva() {

        datiGeneraliService.salvaDatiGenerali(datiGenerali)
        datiGenerali.catastoChanged = false

        datiGeneraliService.salvaDatiSoggettoCorrente(datiSoggetto)

        oggettiCacheMap.refresh(OggettiCache.DATI_GENERALI)

        BindUtils.postNotifyChange(null, null, this, "datiGenerali")
    }

    private def aggiornaDatiBanca() {

        datiBanca = datiGeneraliService.getDatiBanca(datiGenerali.codAbi, datiGenerali.codCab)
        BindUtils.postNotifyChange(null, null, this, "datiBanca")
    }

    private def completaDati() {
        datiGenerali.area = areaSelected?.codice
        datiGenerali.tipoComune = tipoComuneSelected?.codice
    }

    private def verificaDati() {

        String message = ""
        boolean result = true

        def report = datiGeneraliService.verificaDatiGenerali(datiGenerali)
        if (report.result != 0) {
            message += report.message
        }
        report = datiGeneraliService.verificaDatiSoggetto(datiSoggetto)
        if (report.result != 0) {
            message += report.message
        }

        if (message.size() > 0) {

            message = "Attenzione:\n\n" + message
            Clients.showNotification("${message}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return result
    }
}
