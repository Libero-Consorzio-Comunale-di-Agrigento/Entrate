package ufficiotributi.bonificaDati

import java.util.List;

import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.anomalie.AnomaliaPratica
import it.finmatica.tr4.bonificaDati.BonificaDatiService
import it.finmatica.tr4.dto.anomalie.AnomaliaPraticaDTO

import org.zkoss.bind.annotation.Default
import org.zkoss.bind.annotation.AfterCompose
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.HtmlBasedComponent
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class DatiUgualiPopupViewModel {

    Window self

    String opzioniHelp = "e" //1 elimina duplicati, 2 annulla flag possesso doppi
    AnomaliaPraticaDTO praticaSelezionata
    def anomaliaSelezionata
    String msgHelp
    List<AnomaliaPraticaDTO> oggettiDuplicati

    BonificaDatiService bonificaDatiService

	Boolean lettura = true

	@Wire("textbox, combobox, decimalbox, intbox, datebox, checkbox")
	List<HtmlBasedComponent> componenti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("anomaliaSelezionata") def anomaliaSelezionata
         , @ExecutionArgParam("praticaSelezionata") AnomaliaPraticaDTO praticaSelezionata
		 , @ExecutionArgParam("lettura") @Default("true") Boolean lettura) {
		 
        this.self = w

		this.lettura = lettura

        def ogg = Oggetto.get(praticaSelezionata.oggettoContribuente.oggettoPratica.oggetto.id).toDTO(["archivioVie"])
        def indirizzo = (ogg.archivioVie ? ogg.archivioVie.denomUff : ogg.indirizzoLocalita) ?: ''

        this.anomaliaSelezionata = anomaliaSelezionata
        this.praticaSelezionata = praticaSelezionata
        this.msgHelp = """L'oggetto $praticaSelezionata.oggettoContribuente.oggettoPratica.oggetto.id sito in $indirizzo
                è denunciato più volte per il contribuente ${
            praticaSelezionata.oggettoContribuente.contribuente.soggetto.cognomeNome
        }."""

        oggettiDuplicati = AnomaliaPratica.findAllByAnomaliaPraticaRif(praticaSelezionata.getDomainObject()).toDTO([
                "oggettoContribuente",
                "oggettoContribuente.contribuente",
                "oggettoContribuente.contribuente.soggetto",
                "oggettoContribuente.oggettoPratica",
                "oggettoContribuente.oggettoPratica.pratica",
                "oggettoContribuente.oggettoPratica.oggetto"
        ])

        if (oggettiDuplicati.empty && praticaSelezionata.anomaliaPraticaRif) {
            oggettiDuplicati = AnomaliaPratica.findAllByAnomaliaPraticaRif(praticaSelezionata.anomaliaPraticaRif.getDomainObject()).toDTO([
                    "oggettoContribuente",
                    "oggettoContribuente.contribuente",
                    "oggettoContribuente.contribuente.soggetto",
                    "oggettoContribuente.oggettoPratica",
                    "oggettoContribuente.oggettoPratica.pratica",
                    "oggettoContribuente.oggettoPratica.oggetto"
            ])

            // Si rimuove l'anomalia selezionata
            oggettiDuplicati = oggettiDuplicati.findAll { it -> it.id != praticaSelezionata.id }

            // Si aggiunge l'anomalia di riferimento
            oggettiDuplicati << praticaSelezionata.anomaliaPraticaRif.getDomainObject().toDTO([
                    "oggettoContribuente",
                    "oggettoContribuente.contribuente",
                    "oggettoContribuente.contribuente.soggetto",
                    "oggettoContribuente.oggettoPratica",
                    "oggettoContribuente.oggettoPratica.pratica",
                    "oggettoContribuente.oggettoPratica.oggetto"
            ])

        }
    }

    @Command
    onCloseHelp() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onEseguiHelp(@BindingParam("scelta") String scelta) {

        // Le funzionalità erano state implementate per lavorare sull'anomalia di riferimento.
        // Si forza la pratica selezionata ad essere quella di riferimento.
        def anomPrtrRif = praticaSelezionata.getDomainObject()
        anomPrtrRif.anomaliaPraticaRif = null
        def anomPrtrDup = oggettiDuplicati*.getDomainObject()
        anomPrtrDup*.anomaliaPraticaRif = anomPrtrRif

        def anomPrtrDaSalvate = anomPrtrDup + anomPrtrRif

        bonificaDatiService.salvaAnomaliePratiche(anomPrtrDaSalvate)


        if (scelta == "e") {
            String message = bonificaDatiService.eliminaOgcoDuplicati(praticaSelezionata)
            if (message) {
                Map params = new HashMap()
                params.put("width", "600")
                Messagebox.Button[] buttons = [Messagebox.Button.OK];
                Messagebox.show(message, "Attenzione", buttons, null, Messagebox.EXCLAMATION, null, null, params)
            } else {
                Events.postEvent(Events.ON_CLOSE, self, null)
            }
        } else if (scelta == "a") {
            int moltiplicatore = oggettiDuplicati.size() + 1
            if (praticaSelezionata.oggettoContribuente.mesiPossesso ?: 0 * moltiplicatore > 12) {
                Messagebox.show("Attenzione! La somma dei mesi di possesso resterà maggiore di 12. Si desidera proseguire?", "Disabilita possesso",
                        Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                        new org.zkoss.zk.ui.event.EventListener() {
                            public void onEvent(Event e) {
                                if (Messagebox.ON_YES.equals(e.getName())) {
                                    String message = bonificaDatiService.annullaFlagPossesso(praticaSelezionata)
                                    if (message) {
                                        Map params = new HashMap()
                                        params.put("width", "600")
                                        Messagebox.Button[] buttons = [Messagebox.Button.OK];
                                        Messagebox.show(message, "Attenzione", buttons, null, Messagebox.EXCLAMATION, null, null, params)
                                    } else {
                                        Events.postEvent(Events.ON_CLOSE, self, null)
                                    }
                                }

                            }
                        }
                )
            } else {
                String message = bonificaDatiService.annullaFlagPossesso(praticaSelezionata)
                if (message) {
                    Map params = new HashMap()
                    params.put("width", "600")
                    Messagebox.Button[] buttons = [Messagebox.Button.OK];
                    Messagebox.show(message, "Attenzione", buttons, null, Messagebox.EXCLAMATION, null, null, params)
                } else {
                    Events.postEvent(Events.ON_CLOSE, self, null)
                }
            }
        }
    }

	@AfterCompose
	void afterCompose(@ContextParam(ContextType.VIEW) Component view) {

		if(this.lettura) {
			componenti.each {
			    it.disabled = true
			}
		}
	}
}
