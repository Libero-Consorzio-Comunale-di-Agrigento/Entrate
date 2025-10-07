package sportello.contribuenti

import document.FileNameGenerator
import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.jobs.CalcoloLiquidazioniJob
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CalcoloLiquidazioniICIViewModel {

    // componenti
    Window self

    // Service
    SpringSecurityService springSecurityService
    ImposteService imposteService

    // --
    boolean asynch

    // Modello
    def parametriCalcolo = [:]
    def tabSelezionato
    String tributo = ''
    def elaborazioneEseguita = false
    def contribuentiNonLiquidati = []
    def modificaCognomeNomeCodFiscale = false

    @NotifyChange(["cognomeNome", "codiceFiscale", "parametriCalcolo"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("tributo") String tt
         , @ExecutionArgParam("cognomeNome") @Default("") String cn
         , @ExecutionArgParam("codFiscale") @Default("") String cf
         , @ExecutionArgParam("modificaCognomeNomeCodFiscale") @Default("false") boolean modificaCognomeNomeCodFiscale
         , @ExecutionArgParam("asynch") @Default("false") boolean asynch
    ) {

        this.self = w
        this.tributo = tt
        this.asynch = asynch

        tabSelezionato = 0
        this.modificaCognomeNomeCodFiscale = modificaCognomeNomeCodFiscale

        parametriCalcolo.tributo = tt
        parametriCalcolo.daAnno = (tributo == 'ICI') ?
                Calendar.getInstance().get(Calendar.YEAR) : Calendar.getInstance().get(Calendar.YEAR) - 1
        parametriCalcolo.adAnno = (tributo == 'ICI') ?
                Calendar.getInstance().get(Calendar.YEAR) : Calendar.getInstance().get(Calendar.YEAR) - 1
        parametriCalcolo.parametriCalcolo = null
        parametriCalcolo.flagRimborso = false
        parametriCalcolo.limiteInf = null
        parametriCalcolo.limiteSup = null
        parametriCalcolo.flagRicalcoloDovuto = true
        parametriCalcolo.flagRicalcolo = null
        parametriCalcolo.flagRavvedimento = null
        parametriCalcolo.cognomeNome = cn
        parametriCalcolo.codFiscale = cf
        parametriCalcolo.dataLiquidazione = new Date()
        parametriCalcolo.dataRifInteressi = new Date()
        parametriCalcolo.flagRiOg = false
        parametriCalcolo.aDataRiOg = new Date()
        parametriCalcolo.daDataRiOg = null
        parametriCalcolo.daPercDiff = -99999.99
        parametriCalcolo.aPercDiff = 99999.99

        contribuentiNonLiquidati = imposteService.contribuentiNonLiquidati(tributo)
        BindUtils.postNotifyChange(null, null, this, "contribuentiNonLiquidati")
        BindUtils.postNotifyChange(null, null, this, "modificaCognomeNomeCodFiscale")
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, {
            elaborazioneEseguita:
            elaborazioneEseguita
        })
    }

    @Command
    selezionaTab(@BindingParam("id") def id) {
        tabSelezionato = id
        BindUtils.postNotifyChange(null, null, this, "tabSelezionato")
    }

    @NotifyChange(["parametriCalcolo"])
    @Command
    def onCheckRiOg() {
        if (parametriCalcolo.flagVersamenti && !parametriCalcolo.annoRiferimento) {
            parametriCalcolo.flagVersamenti = false
        }
    }

    @Command
    onCalcolaLiquidazioni() {

        if (!valida()) {
            return
        }

        String messaggio = "Verranno eliminate le pratiche non numerate e non notificate.\n" +
                "Si vuole confermare l'esecuzione del calcolo?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {

                            if (asynch)
                                calcolaLiquidazioniAsynch()
                            else
                                calcolaLiquidazioni()
                        }
                    }
                }
        )
    }

    @Command
    contribuentiNonLiquidatiToXls() {

        Map fields = [
                'COD_FIS'     : 'Codice Fiscale',
                'NOME'        : 'Nome',
                'ANNO'        : 'Anno',
                'DATA'        : 'Data',
                'NOTE_CALCOLO': 'Note'
        ]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.CONTRIBUENTI_NON_LIQUIDATI,
                [tipoTributo: tributo])

        XlsxExporter.exportAndDownload(nomeFile, contribuentiNonLiquidati, fields)

    }

    def calcolaLiquidazioni() {

        def contatore = imposteService.calcoloLiquidazioni(parametriCalcolo)

        elaborazioneEseguita = true

        def notificationMsg = "Elaborazione conclusa."
        if (contatore > 0) {
            notificationMsg += "\nAttenzione non è stato possibile effettuare la liquidazione per ${contatore} Contribuente/i."
        }

        def notificationType = contatore == 0 ? Clients.NOTIFICATION_TYPE_INFO : Clients.NOTIFICATION_TYPE_WARNING

        Clients.showNotification(notificationMsg, notificationType, self, "before_center", 5000, true)

        if (contatore > 0) {
            contribuentiNonLiquidati = imposteService.contribuentiNonLiquidati(tributo)
        }

        // println "Liq : ${contribuentiNonLiquidati}"

        BindUtils.postNotifyChange(null, null, this, "contribuentiNonLiquidati")
    }

    def calcolaLiquidazioniAsynch() {
        try {
            CalcoloLiquidazioniJob.triggerNow(
                    [
                            codiceUtenteBatch: springSecurityService.currentUser.id,
                            codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                            parametriCalcolo : parametriCalcolo
                    ]
            )
            elaborazioneEseguita = true

            onChiudi()

            Clients.showNotification("Elaborazione calcolo liquidazioni lanciata con successo", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
        } catch (Exception ex) {
            Clients.showNotification("Errore durante il lancio dell'elaborazione calcolo liquidazioni", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)

            if (ex instanceof Application20999Error) {
                Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                throw ex
            }

        }
    }

    def valida() {

        def errori = []

        if (!parametriCalcolo?.cognomeNome && !parametriCalcolo?.codFiscale) {
            errori << "Obbligatorio specificare 'Cognome e Nome' o 'Codice Fiscale'"
        }

        if (!parametriCalcolo.daAnno) {
            errori << "Specicare un valore per 'Da anno'"
        }

        if (parametriCalcolo.adAnno && parametriCalcolo.daAnno > parametriCalcolo.adAnno) {
            errori << "I campi 'Da Anno' e 'Ad Anno' sono incoerenti."
        }

        if (parametriCalcolo.annoRiferimento && parametriCalcolo.annoRiferimento > parametriCalcolo.daAnno) {
            errori << "L'anno su cui si vuole effettuare il calcolo è minore dell'anno di riferimento."
        }

        if (parametriCalcolo.limiteSup && parametriCalcolo.limiteInf > parametriCalcolo.limiteSup) {
            errori << "Il limite superiore è minore del limite inferiore."
        }

        if (parametriCalcolo.flagRiOg) {
            if (!parametriCalcolo.daDataRiOg) {
                errori << "Il campo: 'Da Data' non può essere NULLO."
            }

            if (!parametriCalcolo.aDataRiOg) {
                errori << "Il campo: 'A Data' non può essere NULLO."
            }

            if (parametriCalcolo.daDataRiOg && parametriCalcolo.aDataRiOg && parametriCalcolo.daDataRiOg > parametriCalcolo.aDataRiOg) {
                errori << "I campi 'Da Data' e 'A Data' sono incoerenti."
            }

            if (parametriCalcolo.flagVersamenti) {
                if (!parametriCalcolo.daPercDiff || !parametriCalcolo.aPercDiff) {
                    errori << "I campi: 'Perc. di Scostamento da / A' non possono essere NULLI."
                }


                if (parametriCalcolo.daPercDiff && parametriCalcolo.aPercDiff && parametriCalcolo.daPercDiff > parametriCalcolo.aPercDiff) {
                    errori << "I campi: 'Perc. di Scostamento da / A' sono incoerenti."
                }
            }
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }
}
