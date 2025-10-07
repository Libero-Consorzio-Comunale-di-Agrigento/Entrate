package pratiche.violazioni

import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.pratiche.PraticaTributo

import org.zkoss.bind.BindContext
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CalcoloAccertamentoManualeViewModel {

    // Services
    def springSecurityService

    // Componenti
    Window self

    TributiSession tributiSession

    Boolean nascondiCalcolo = false

    // Dati
    def impostazioni = [
            anno               : null,
            calcoloNormalizzato: true,
            interessiDal       : null,
            interessiAl        : null,
            soloCalcoloSanzioni: false,
            praticaId           : null
    ]

    def dataPratica = null

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("impostazioni") def imp) {

        this.self = w

        if (imp) {
            impostazioni = imp
        }

        /// Se specificata la pratica cerca data di riferimento per validare le date degli interessi

        if(impostazioni.praticaId) {
            PraticaTributo pratica = PraticaTributo.get(impostazioni.praticaId)
            dataPratica = pratica.data
        }
    }

    // Eventi interfaccia

    @Command
    def onChangeInteressiDal() {

    }

    @Command
    def onChangeInteressiAl() {

    }

    @Command
    def onOK() {

        if (verificaImpostazioni() == false) {
			return
		}

        Events.postEvent(Events.ON_CLOSE, self, [impostazioniCalcolo: impostazioni])
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [impostazioniCalcolo: null])
    }

    // Metodi privati

    private def verificaImpostazioni() {

        String message = ""
        Boolean valid = true

        if (impostazioni.interessiAl) {
            if (impostazioni.interessiDal) {
                if (impostazioni.interessiDal > impostazioni.interessiAl) {
                    message += "- Interessi Sanzioni -> Data Inizio deve essere precedente o uguale a Data Fine\n"
                }
            }
            else {
                message += "- Interessi Sanzioni -> Data Inizio non specificata\n"
            }
            if(dataPratica) {
                if(impostazioni.interessiAl > dataPratica) {
                    message += "- Interessi Sanzioni -> Data Fine posteriore a Data Emissione!\n"
                }
            }
        }
        else {
            message += "- Interessi Sanzioni -> Data Fine non specificata\n"
        }

        if (!message.empty) {

            message = "Attenzione:\n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
            valid = false
        }

        return valid
    }
}
