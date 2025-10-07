package pratiche.denunce

import it.finmatica.tr4.Fonte
import it.finmatica.tr4.denunce.DenunceService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.InputEvent
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DenunciaDaCatastoViewModel {

    Window self
    DenunceService denunceService

    def tributi = [IMU: 'IMU', TASI: 'TASI', Entrambi: 'Entrambi']
    def partenze = [IMU: 'IMU', CATASTO: 'CATASTO']

    def codFiscale
    def fonti
    def fonte
    def tributo = tributi.IMU
    def partenza = partenze.CATASTO
    def annoImposta = null
    def abilitaStorico = true
    def storico = true

    def logDenunce = ''

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("codFiscale") String cf) {

        self = w

        codFiscale = cf
        fonti = Fonte.findAll().sort { it.fonte }
        fonte = fonti[0]

        cambioAnno(null)
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @NotifyChange(['partenza'])
    @Command
    cambioTributo() {
        if (tributo == tributi.IMU || tributo == tributi.Entrambi) {
            partenza = partenze.CATASTO
        }
    }

    @Command
    @NotifyChange(['storico', 'abilitaStorico'])
    def cambioAnno(@ContextParam(ContextType.TRIGGER_EVENT) InputEvent event) {

        // Se l'evento è null si inizializza l'interfaccia
        if (!event) {
            abilitaStorico = false
            storico = true
        } else {

            // Per il 1992 o senza anno di imposta deve essere sempre attivo lo storico
            if (event.value in ['', '1992']) {
                abilitaStorico = false
                storico = true
            } else {
                // Se l'anno è successivo al 1992, si abilita la possibilità di scegliere lo storico
                abilitaStorico = true

                // Se il vecchio valore era null o 1992 si deseleziona la scelta di default
                if (event.previousValue in [null, 1992]) {
                    storico = false
                }
            }
        }
    }

    @Command
    def popola() {

        // TASI
        if (tributo == tributi.TASI) {
            // Da Catasto
            if (partenza == partenze.CATASTO) {
                logDenunce = denunceService.popolaDaCatastoTasi(codFiscale, fonte.fonte, '%')
            } else {
                // Da IMU
                logDenunce = denunceService.popolaDaImu(codFiscale, fonte.fonte)
                if (!logDenunce) {
                    logDenunce = 'Nessuna denuncia creata.'
                }
            }
        } else if (tributo == tributi.IMU) {
            // IMU da catasto
            logDenunce = denunceService.popolaDaCatastoImu(codFiscale, annoImposta, fonte.fonte, storico)

        } else if (tributo == tributi.Entrambi) {
            // Entrambi i tributi selezionati
            logDenunce = "IMU: \n" + denunceService.popolaDaCatastoImu(codFiscale, annoImposta, fonte.fonte, storico)
            logDenunce += "\n\nTASI: \n---------------------------------------------------------------------------------\n";
            logDenunce += denunceService.popolaDaImu(codFiscale, fonte.fonte)
        }

        if (logDenunce == 'OK') {
            Events.postEvent(Events.ON_CLOSE, self, null)
            Messagebox.show("Denunce generate", "Popolamento Denunce", Messagebox.OK, Messagebox.INFORMATION)
        } else {
            BindUtils.postNotifyChange(null, null, this, "logDenunce")
        }
    }
}
