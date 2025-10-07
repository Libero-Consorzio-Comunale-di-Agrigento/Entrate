package versamenti

import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.contribuenti.ContribuentiService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class VersamentoSelezionaPraticaViewModel {

    // componenti
    Window self

    ContribuentiService contribuentiService

    def listaTipiAtto

    def tipiPraticaValidi

    def listaPratiche = []
    def praticaSelezionata

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("codFiscale") String codFiscale,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("anno") Short anno) {

        self = w

        listaTipiAtto = [null] + TipoAtto.list().sort { it.tipoAtto }.toDTO()
		
		if(tipoTributo in(['CUNI', 'ICP', 'TOSAP'])) {
			tipiPraticaValidi = ['A', 'G', 'I', 'L', 'V', 'D']
		}
		else {
			tipiPraticaValidi = ['A', 'G', 'I', 'L', 'V']
		}

		listaPratiche =
				contribuentiService.praticheContribuente(codFiscale, "list", [tipoTributo], tipiPraticaValidi)
						.findAll {
							it.anno == anno &&
									(
										// Pratiche non (a, i, l) o se (a, i, l) devono essere notificate
										!((it.tipoPratica as String) in ['A', 'I', 'L']) ||
												((it.tipoPratica as String) in ['A', 'I', 'L'] && it.dataNotifica != null)
									)
						}
    }

    @Command
    onSelezionaPratica() {

    }

    @Command
    onDoppioClickPratica() {

    }

    @Command
    onSeleziona() {
        Events.postEvent(Events.ON_CLOSE, self, [status: "Pratica", pratica: praticaSelezionata.id])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }
}
