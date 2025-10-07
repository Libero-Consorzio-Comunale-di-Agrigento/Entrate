package sportello.contribuenti

import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.SoggettoDTO
import it.finmatica.tr4.depag.IntegrazioneDePagService
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DettagliContribuenteViewModel {

    private Logger log = LoggerFactory.getLogger(DettagliContribuenteViewModel.class)

    // componenti
    Window self

    // services
    ContribuentiService contribuentiService
    IntegrazioneDePagService integrazioneDePagService

    SoggettoDTO soggetto
    def contribuente
    List codiciAttivita
    def attivitaSelezionata
    Integer codiceControlloAttuale
    HashMap<String, String> flagsTP

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("soggetto") SoggettoDTO soggetto) {

        this.self = w
        this.soggetto = soggetto

        codiciAttivita = contribuentiService.getCodiciAttivita()

        caricaContribuente()
    }

    private void caricaContribuente() {

        contribuente = contribuentiService.getSoggettoContribuente(soggetto)
        contribuente.codFiscaleNuovo = contribuente.codFiscale

        codiceControlloAttuale = contribuente.codContribuente

        flagsTP = contribuentiService.getFlagsTributiPratiche(contribuente.codFiscale)

        if (contribuente.codAttivita) {
            attivitaSelezionata = codiciAttivita.find {
                it.codAttivita == contribuente.codAttivita
            }
        }
    }

    private void salva() {

        String message = ""
        Long result = 0

        if (attivitaSelezionata) {
            contribuente.codAttivita = attivitaSelezionata.codAttivita
        }

        contribuentiService.aggiornaContribuente(contribuente)

        if (contribuente.codFiscale != contribuente.codFiscaleNuovo) {
            if(integrazioneDePagService.dePagAbilitato()) {

                def report = integrazioneDePagService.eliminaDovutiAnnullatiSoggetto(contribuente.codFiscale,null,
                                                                                            contribuente.codFiscaleNuovo)
                if (report.result > 0) {
                    message += report.message
                    result = report.result
                }
                report = integrazioneDePagService.aggiornaDovutiSoggetto(contribuente.codFiscaleNuovo)
                if (report.result > 0) {
                    if(!message.isEmpty()) {
                        message += "\n"
                    }
                    message += report.message
                    result = report.result
                }

                if (result > 0) {
                    message = "DEPAG – Aggiornamento Contribuente:\n"+ message
                    Messagebox.show(message, "Errore", Messagebox.OK, Messagebox.ERROR, new org.zkoss.zk.ui.event.EventListener() {

                        void onEvent(Event event) throws Exception {

                            Events.postEvent(Events.ON_CLOSE, self, [status: "Salva"])
                        }
                    })
                }
            }
        }

        if(result == 0) {
            Events.postEvent(Events.ON_CLOSE, self, [status: "Salva"])
        }
    }

    private void salvaConNuovoCF() {

        String errorMessage
        String pivaPattern = /^[0-9]{11}$/
        String cfPattern = /^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[A-Z][0-9]{3}[A-Z]$/
        if (!(contribuente.codFiscaleNuovo?.length() in [11, 16])) {
            errorMessage = "La lunghezza del Cod.Fiscale o P.Iva e' 16 o 11"
        } else {
            boolean matcher
            if (contribuente.codFiscaleNuovo?.length() == 16) {
                matcher = contribuente.codFiscaleNuovo ==~ cfPattern
            } else {
                matcher = contribuente.codFiscaleNuovo ==~ pivaPattern
            }

            if (matcher) {
                def contribHash = contribuentiService.getContribuente([codFiscale: contribuente.codFiscaleNuovo])
                if (!contribHash || contribHash.codFiscale == contribuente.codFiscale) {
                    salva()
                } else {
                    errorMessage = "Il Cod.Fiscale o P.Iva inserito e' gia' esistente"
                }
            } else {
                errorMessage = "Il Cod.Fiscale o P.Iva inserito non e' formalmente corretto"
            }

        }

        if (errorMessage) {
            Clients.showNotification(errorMessage, Clients.NOTIFICATION_TYPE_ERROR, self,
                    "before_center", 5000, true)
        }
    }

    @Command
    onSalva() {
            
        if (contribuente.codContribuente || contribuente.codControllo) {
            
            // Se esiste già un contribuente con la stessa coppia codContribuente, codControllo si da errore.
            if ((contribuentiService.getContribuenteByCodContribuenteCodControllo(
                    contribuente.codContribuente, contribuente.codControllo
            )?.codFiscale ?: contribuente.codFiscale) != contribuente.codFiscale) {
                Clients.showNotification("Esiste già un contribuente con la stessa coppia Codice Contribuente e codice Controllo", Clients.NOTIFICATION_TYPE_ERROR, self,
                        "before_center", 5000, true)
                return
            }
        }

        contribuente.codFiscaleNuovo = contribuente.codFiscaleNuovo?.toUpperCase()
        contribuente.soggCodFiscale = contribuente.soggCodFiscale?.toUpperCase()

        if (contribuente.codFiscaleNuovo == contribuente.soggCodFiscale) {
            salva()
        } else {
            String messaggio = "Codice Fiscale diverso da quello in Anagrafe, si vuole continuare ?"
            String title = "Aggiornamento Contribuente : " + contribuente.cognomeNome
            String errorMessage

            Messagebox.show(messaggio, title,
                    Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES == e.getName()) {
                                salvaConNuovoCF()
                            }
                        }
                    }
            )
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
