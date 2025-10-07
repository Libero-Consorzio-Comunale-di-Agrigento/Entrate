package archivio

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.oggetti.OggettiService
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Popup
import org.zkoss.zul.Window


class ListaRiferimentiOggettoRicercaViewModel {
	Window self

	// paginazione bandbox
	int activePage  = 0
	int pageSize 	= 10
	int totalSize

	// services
	OggettiService oggettiService

	Popup popupNote

	// dati
	def oggetto
	def listaRiferimenti
	def listaDate
	def dataSelezionata

	@NotifyChange([
		"listaRiferimenti",
		"listaDate",
	    "dataSelezionata",
	])
	@Init init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("oggetto") def oggettoSelezionato) {

		this.self 	= w
		this.oggetto = oggettoSelezionato
		listaDate = oggettiService.listaDateRiferimentiOggettBk(oggetto.id).dataOraVariazione
		dataSelezionata = listaDate.get(0)
		if(dataSelezionata)
		  listaRiferimenti = oggettiService.listaRiferimentiOggettBk(oggetto.id,dataSelezionata)
	}

	@NotifyChange([
		"listaRiferimenti",
		"listaDate",
		"activePage",
		"totalSize"
	])
	@Command onSvuotaFiltri() {
		listaRiferimenti = []
		activePage = 0
		totalSize = 0
	}

	@NotifyChange([
			"listaRiferimenti",
			"listaDate",
			"dataSelezionata",
			"activePage",
			"totalSize"
	])
	@Command
	onSelectData() {
		listaRiferimenti = oggettiService.listaRiferimentiOggettBk(oggetto.id,dataSelezionata)
	}

	@Command onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	@Command onScegliRiferimento() {
		String msg = "Si è scelto di recuperare i riferimenti del "+dataSelezionata+".\n"+
		              "I riferimenti attualmente presenti verranno cancellati e non saranno recuperabili.\n" +
				      "Si conferma l'operazione?"

		Messagebox.show(msg, "Ripristino Rendite",  Messagebox.OK | Messagebox.CANCEL,
				Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
			public void onEvent(Event evt) throws InterruptedException {
				if (evt.getName().equals("onOK")) {
					ripristinoRendite()
				}
			}
		}
		)
	}

	@Command
	onApriNote(@BindingParam("arg") def nota) {
		Messagebox.show(nota, "Note", Messagebox.OK, Messagebox.INFORMATION)
	}

	private def ripristinoRendite() {
		def esito
		try {
			esito = oggettiService.ripristinoRendite(oggetto.id,dataSelezionata)
			if(esito.isEmpty()){
				Clients.showNotification("Operazione eseguita!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true);
				Events.postEvent(Events.ON_CLOSE, self, [status: "eseguito"])
			}
			else {
				Clients.showNotification(esito, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
			}
		} catch (Exception e) {
			if (e instanceof Application20999Error) {
				Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
			} else {
				throw e
			}
		}
	}

}
