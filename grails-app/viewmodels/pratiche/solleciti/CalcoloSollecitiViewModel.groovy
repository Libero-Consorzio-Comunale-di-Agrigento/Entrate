package pratiche.solleciti

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.jobs.CalcoloSollecitiJob
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CalcoloSollecitiViewModel {

    // Services
    def springSecurityService
    ImposteService imposteService

    // Componenti
    Window self

    // Comuni
    def tipoTributo
    def listaTipiTributo
    def elaborazioneEseguita = false
    def isSoloAnno = false
    def visualizzaMsg = false
    def parametriCalcolo = [speseNotifica: true]

    // --
    boolean asynch

    /**
     * D: Disabled
     * H: Hidden
     * N: Normal (Default)
     */
    def modalitaCognomeNomeCodFiscale = 'N'
    def modalitaAnno = 'N'

    /**
     * H: Hidden (Default)
     * V: Visible
     */
    def modalitaTipoTributo = 'H'

    // Per l'esecuzione del job dalle Imposte > Tab Da Pagare
    def listaContribuenti
    def contribuentiProps

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("anno") def an,
         @ExecutionArgParam("cognomeNome") def cogNome,
         @ExecutionArgParam("codFiscale") def cf,
         @ExecutionArgParam("modalitaCognomeNomeCodFiscale") @Default("N") String modalitaCognomeNomeCodFiscale,
         @ExecutionArgParam("modalitaTipoTributo") @Default("H") String modalitaTipoTributo,
         @ExecutionArgParam("modalitaAnno") @Default("N") String modalitaAnno,
         @ExecutionArgParam("listaContribuenti") def lc,
         @ExecutionArgParam("contribuentiProps") @Default("") def cp,
         @ExecutionArgParam("asynch") @Default("false") boolean asynch) {

        self = w

        this.asynch = asynch || lc
        this.listaTipiTributo = TipoTributo.list()
                .sort { it.tipoTributo }
                .findAll { it.tipoTributo == 'TARSU' || it.tipoTributo == 'CUNI' }

        // Nel caso il tipo tributo passato sia nullo, viene impostato il primo della lista (situazione con combo visibile nella SC)
        this.tipoTributo = tt ?: listaTipiTributo[0].tipoTributo

        this.listaContribuenti = lc
        this.contribuentiProps = cp
        this.modalitaCognomeNomeCodFiscale = modalitaCognomeNomeCodFiscale
        this.modalitaAnno = modalitaAnno
        this.modalitaTipoTributo = modalitaTipoTributo

        parametriCalcolo.anno = an ?: Calendar.getInstance().get(Calendar.YEAR)
        parametriCalcolo.limiteInferiore = 0.01
        parametriCalcolo.limiteSuperiore = 99999999.00
        parametriCalcolo.tipoTributo = this.tipoTributo

        if (cogNome) {
            parametriCalcolo.cognomeNome = cogNome
        }
        if (cf) {
            parametriCalcolo.codFiscale = cf
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, visualizzaMsg ? [elaborazioneEseguita: elaborazioneEseguita, isSoloAnno: isSoloAnno] : null)
    }

    @Command
    def onCalcolaSolleciti() {

        def errors = controllaParametri()

        if (errors.size() > 0) {
            Clients.showNotification(errors.join(), Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
            return
        }

        String messaggio = "Verranno eliminate le pratiche non numerate e non notificate.\n" +
                "Si vuole confermare l'esecuzione del calcolo?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            calcolaSolleciti()
                        }
                    }
                }
        )

    }

    private def calcolaSolleciti() {
        try {
            if (!asynch) {
                calcoloSollecitiSynch()
            } else {
                calcolaSollecitiAsynch()
            }
        } catch (Exception ex) {
            manageException(ex)
        }
    }

    private def manageException(Exception ex) {
        if (ex instanceof Application20999Error) {
            Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        } else {
            throw ex
        }
    }

    private def calcoloSollecitiSynch() {
        def idPratica = imposteService.calcoloSolleciti(parametriCalcolo)

        if (idPratica != null) {
            elaborazioneEseguita = true
        } else if (idPratica == null && parametriCalcolo.codFiscale == null) {
            // Nel caso si avvia un calcolo singolo senza specificare CF, la procedure ritorna null
            // e non si può sapere se ha calcolato o meno delle pratiche per quell'anno
            isSoloAnno = true
        }
        visualizzaMsg = true
        onChiudi()
    }

    private def calcolaSollecitiAsynch() {
        try {
            CalcoloSollecitiJob.triggerNow(
                    [
                            codiceUtenteBatch: springSecurityService.currentUser.id,
                            codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                            listaContribuenti: listaContribuenti,
                            parametriCalcolo : parametriCalcolo,
                            contribuentiProps: contribuentiProps != null && contribuentiProps != "" ? contribuentiProps : null
                    ]
            )
            elaborazioneEseguita = true
            visualizzaMsg = true
            onChiudi()
        } catch (Exception ex) {
            if (!(ex instanceof Application20999Error)) {
                throw ex
            }
            Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        }
    }


    @Command
    def onChangeTipoTributo() {
        this.tipoTributo = parametriCalcolo.tipoTributo
        BindUtils.postNotifyChange(null, null, this, "tipoTributo")
    }

    def tipoTributo() {
        return TipoTributo.get(tipoTributo).getTipoTributoAttuale()
    }

    private def controllaParametri() {

        def errors = []

        if (!parametriCalcolo?.cognomeNome && !parametriCalcolo?.codFiscale) {
            errors << "Obbligatorio specificare 'Cognome e Nome' o 'Codice Fiscale'\n"
        }

        if (parametriCalcolo?.anno == null) {
            errors << "L'anno è obbligatorio\n"
        }

        if (parametriCalcolo?.dataScadenza == null) {
            errors << "La data scadenza è obbligatoria\n"
        }

        if (parametriCalcolo?.limiteInferiore == null || parametriCalcolo?.limiteSuperiore == null) {
            errors << "Il Limite Inferiore e il Limiti Superiore sono obbligatori\n"
        } else if (parametriCalcolo.limiteInferiore > parametriCalcolo.limiteSuperiore) {
            errors << "Il Limite Inferiore deve essere minore del Limite Superiore\n"
        }

        return errors
    }

}
