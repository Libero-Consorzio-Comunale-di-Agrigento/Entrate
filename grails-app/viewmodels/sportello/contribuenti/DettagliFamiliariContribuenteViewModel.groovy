package sportello.contribuenti

import it.finmatica.tr4.FamiliareSoggetto
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.FamiliareSoggettoDTO
import it.finmatica.tr4.familiari.FamiliariService
import org.codehaus.groovy.runtime.InvokerHelper
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class DettagliFamiliariContribuenteViewModel {

    Window self

    //Services
    ContribuentiService contribuentiService
    FamiliariService familiariService

    //Comuni
    def tipoOperazione
    def familiare
    def familiareOld
    def listaFamiliari
    def listaFamiliariEsistenti = [:]

    def abilitaModificaAnno = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("familiare") def familiare,
         @ExecutionArgParam("tipoOperazione") def tipoOperazione,
         @ExecutionArgParam("listaFamiliari") def listaFamiliari) {

        this.self = w

        this.tipoOperazione = tipoOperazione
        this.abilitaModificaAnno = tipoOperazione in [
                FamiliariService.TipoOperazione.INSERIMENTO,
                FamiliariService.TipoOperazione.CLONAZIONE
        ]

        this.listaFamiliari = listaFamiliari
        this.listaFamiliariEsistenti = listaFamiliari.collectEntries { [(it.uuid): true] }

        initFamiliare(familiare)

    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onSalva() {

        def listaFamiliariControllo = (tipoOperazione != FamiliariService.TipoOperazione.MODIFICA) ?
                listaFamiliari : listaFamiliari.findAll { it.uuid != familiareOld.uuid }

        // Nel caso di periodi aperti si porpone la chiusura automatica
        if (familiariService.getNumPeriodiAperti(listaFamiliariControllo) > 1) {
            apriPopupChiusuraPeriodiAperti(listaFamiliari)
            return
        }

        def errorMessage = familiariService.verificaFamiliare(
                familiare, listaFamiliariControllo, tipoOperazione
        )

        if (errorMessage.length() != 0) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_WARNING, null,
                    "middle_center", 5000, true)
            return
        }

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")

        //Popup aggiornamento data variazione
        if (familiare.lastUpdated == null || sdf.format(familiare.lastUpdated) != sdf.format(new Date())) {
            def msg = "Si desidera aggiornare la Data di Variazione con la Data odierna?"
            Messagebox.show(msg, "Data Variazione", Messagebox.OK | Messagebox.NO, Messagebox.QUESTION, new EventListener() {
                void onEvent(Event evt) throws InterruptedException {

                    //Aggiorno data variazione nel caso di ok e salvo
                    if (evt.getName() == "onOK") {
                        familiare.lastUpdated = new Date()
                        salvaFamiliare()
                    } else if (evt.getName() == "onNo") {
                        salvaFamiliare()
                    }

                    Events.postEvent(Events.ON_CLOSE, self, null)
                }
            })
        } else {
            salvaFamiliare()
            Events.postEvent(Events.ON_CLOSE, self, null)
        }

    }

    private def salvaFamiliare() {

        def sogg = Soggetto.get(this.familiare.soggetto.id)
        FamiliareSoggetto familiare =
                FamiliareSoggetto.findBySoggettoAndAnnoAndDal(sogg, this.familiare.anno, this.familiare.dal) ?:
                new FamiliareSoggetto()

        familiare.anno = this.familiare.anno
        familiare.dal = this.familiare.dal
        familiare.al = this.familiare.al
        familiare.note = this.familiare.note
        familiare.lastUpdated = this.familiare.lastUpdated
        familiare.numeroFamiliari = this.familiare.numeroFamiliari
        familiare.soggetto = sogg

        contribuentiService.salvaFamiliareContribuente(familiare)

        /*
            Con Hibernate non è possibile modificare la chiave primaria o un campo parte di essa, si deve effettuare
            il salvataggio che porta alla creazione di una nuova entity ed eliminare la precedente.
            NI non è modificabile come non lo è anno rimane dal.
         */
        if (tipoOperazione == FamiliariService.TipoOperazione.MODIFICA && familiare.dal != familiare.dal) {
            contribuentiService.eliminaFamiliareContribuente(familiare.toDomain())
        }
    }

    private def initFamiliare(def familiare) {

        familiareOld = new FamiliareSoggettoDTO()
        InvokerHelper.setProperties(familiareOld, familiare.properties)

        this.familiare = new FamiliareSoggettoDTO()

        InvokerHelper.setProperties(this.familiare, familiare.properties)

        if (tipoOperazione == FamiliariService.TipoOperazione.CLONAZIONE) {
            familiare.lastUpdated = null
        }
    }

    private def apriPopupChiusuraPeriodiAperti(def listaFamiliari) {

        String msg = "Solo un periodo per contribuente può essere aperto.\n" +
                "Si desidera chiudere automaticamente i periodi aperti?"

        Messagebox.show(msg, "Attenzione.", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName() == "onOK") {
                    familiariService.chiudiPeriodiAperti(listaFamiliari, true)
                    onSalva()
                    Clients.showNotification("Chiusura periodi avvenuta con successo!",
                            Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
            }
        })
    }
}
