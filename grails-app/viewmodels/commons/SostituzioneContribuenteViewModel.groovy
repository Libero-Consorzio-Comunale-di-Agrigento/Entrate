package commons

import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.annotation.Command
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

abstract class SostituzioneContribuenteViewModel {


    Window self


    // services
    DatiGeneraliService datiGeneraliService
    SoggettiService soggettiService
    CommonService commonService

    def soggettoSelezionato

    @Command
    onSostituzioneContribuente() {

        Long idOriginale = soggettoSelezionato.id
        String cfOriginale = soggettoSelezionato.contribuente.codFiscale

        def filtri = [
                contribuente     : "-",
                cognomeNome      : "",
                cognome          : "",
                nome             : "",
                indirizzo        : "",
                codFiscale       : "",
                id               : null,
                codFiscaleEscluso: null,
                idEscluso        : idOriginale
        ]

        Window w = Executions.createComponents("/sportello/contribuenti/listaContribuentiRicerca.zul", self,
                                                [
                                                    filtri: filtri,
                                                    listaVisibile: true,
                                                    ricercaSoggCont: true
                                                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Sogggetto") {
                    Long idDestinazione = event.data.idSoggetto
                    String cfDestinazione = event.data.cfSoggetto
                    sostituisciContribuenteCheck(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
                }
            }
        }
        w.doModal()
    }

    private sostituisciContribuenteCheck(Long idOriginale, String cfOriginale, Long idDestinazione, String cfDestinazione) {

        Long result
        String messaggio

        def checkResult = soggettiService.sostituisciContribuenteCheck(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
        result = checkResult.result
        messaggio = checkResult.messaggio

        String title
        String message

        switch (result) {
            default:
                title = "Risultato della Verifica Preliminare inatteso"
                message = result.toString() + " - " + messaggio
                Messagebox.show(message, title, Messagebox.OK, Messagebox.EXCLAMATION)
                break
            case 0:
                title = "Conferma operazione"
                message = "Si sta per sostituire\n\nil contribuente\n" +
                        "- ${cfOriginale}  N.I. ${idOriginale}\n\ncon in contribuente\n" +
                        "- ${cfDestinazione}  N.I. ${idDestinazione}\n\nSicuri di voler procedere ?"

                Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener<Event>() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    sostituisciContribuente(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
                                }
                            }
                        }
                )
                break
            case 1:

                if (messaggio.contains("Nuovo Contribuente non utilizzabile, sono presenti recapiti")) {

                    def soggOrigine = Soggetto.get(idOriginale)
                    def soggDestinazione = Soggetto.get(idDestinazione)

                    apriSceltaRecapito(soggOrigine, soggDestinazione)
                    break
                }

                title = "Errore"
                message = messaggio + "\n\nImpossibile procedere"
                Messagebox.show(message, title, Messagebox.OK, Messagebox.ERROR)
                break
            case 2:
                title = "Attenzione"
                message = messaggio + "\n\nProcedere comunque?"

                Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener<Event>() {
                            void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    sostituisciContribuente(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
                                }
                            }
                        }
                )
                break
        }
    }

    private sostituisciContribuente(Long idOriginale, String cfOriginale, Long idDestinazione, String cfDestinazione) {

        Long result
        String messaggio

        def applyResult = soggettiService.sostituisciContribuente(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
        result = applyResult.result
        messaggio = applyResult.messaggio

        String title = ""
        String message
        def icon

        def verificaSoggetto = verificaSoggettoEliminabile(idOriginale)

        switch (result) {
            case 0:
                if (verificaSoggetto) {
                    eliminaSoggettoSostituito(idOriginale, idDestinazione)
                } else {
                    title = "Informazione"
                    message = "Contribuente sostituito con successo"
                    icon = Messagebox.INFORMATION
                }
                break
            case 1:
            case 2:
            default:
                title = "Attenzione"
                message = messaggio
                icon = Messagebox.EXCLAMATION
                break
            case 3:
                title = "Errore"
                message = messaggio
                icon = Messagebox.ERROR
                break
        }


        if (!title.isEmpty()) {

            Messagebox.show(message, title, Messagebox.OK, icon,
                    new org.zkoss.zk.ui.event.EventListener<Event>() {
                        void onEvent(Event e) {
                            // Nel caso il soggetto sia stato sostituito, la verifica non va bene (es. soggetto GSD) e siamo nella SC
                            if (result == 0 && !verificaSoggetto) {
                                closeAndOpenContribuente(idDestinazione)
                            }
                        }
                    })

            onRefresh()
        }

    }

    // Verifica se soggetto eliminabile : true se eliminabile
    private boolean verificaSoggettoEliminabile(Long id) {

        boolean result = false

        boolean integrazioneGSD = datiGeneraliService.integrazioneGSDAbilitata()
        if (integrazioneGSD) {
            Soggetto soggetto = Soggetto.get(id)
            if (soggetto == null) {
                throw new Exception("Soggetto ${id} non trovato")
            }
            if (soggetto.tipoResidente) {
                result = true
            }
        } else {
            result = true
        }

        return result
    }

    // Verifica se soggetto eliminabile : true se eliminabile
    private void eliminaSoggettoSostituito(Long id, def idDestinazione) {

        Soggetto soggetto = Soggetto.get(id)
        if (soggetto == null) {
            throw new Exception("Soggetto ${id} non trovato")
        }

        eliminaSoggetto(soggetto.toDTO(), idDestinazione, true)
    }

    // Elimina il soggetto dopo aver chiesto conferma
    def eliminaSoggetto(def soggetto, def idDestinazione, boolean dopoSostituzione = false) {

        // idDestinazione serve per ricaricare la SC del contribuente sostituito

        Boolean forzaRefresh = false
        String msg = ""

        if (dopoSostituzione) {
            msg = "Contribuente sostituito con successo\n\n"
            msg += "Eliminare il soggetto sostituito ${soggetto.cognome} ${soggetto.nome} (N.Ind. ${soggetto.id}) ?\n\n"
            forzaRefresh = true
        } else {
            msg = "Si è scelto di eliminare il soggetto ${soggetto.cognome} ${soggetto.nome} (N.Ind. ${soggetto.id}).\n\n"
            msg += "Si conferma l'operazione?"
        }

        Messagebox.show(msg, "Eliminazione Soggetto", Messagebox.YES | Messagebox.NO,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event e) {
                if (Messagebox.ON_YES.equals(e.getName())) {
                    def messaggio = soggettiService.eliminaSoggetto(soggetto)
                    visualizzaRisultatoEliminazione(messaggio, forzaRefresh)
                } else {
                    if (forzaRefresh) {
                        onRefresh()
                    }
                }

                closeAndOpenContribuente(idDestinazione)
            }
        })
    }

    private def visualizzaRisultatoEliminazione(def messaggio, Boolean forzaRefresh) {

        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            forzaRefresh = true
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        if (forzaRefresh) {
            onRefresh()
        }
    }

    private def apriSceltaRecapito(def soggOrigine, def soggDestinazione) {


        commonService.creaPopup("/sportello/contribuenti/sostituzioneContribuenteRecapito.zul",
                self,
                [
                        soggOrigine     : soggOrigine,
                        soggDestinazione: soggDestinazione
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.completato == true) {
                            if (verificaSoggettoEliminabile(soggOrigine.id)) {
                                eliminaSoggettoSostituito(soggOrigine.id, soggDestinazione.id)
                            } else {
                                // Chiude la situazione del contribuente e riapre quella del contribuente sostituito
                                // All'interno del metodo eliminaSoggettoSostituito() è già presente il controllo a fine elaborazione
                                // Qua serve per gestire il caso di soggetti GSD e quindi non cancellabili
                                closeAndOpenContribuente(soggDestinazione.id)
                            }
                            onRefresh()
                        }

                    }
                }
        )
    }

    abstract void closeAndOpenContribuente(def idSoggetto)

    abstract def onRefresh()
}
