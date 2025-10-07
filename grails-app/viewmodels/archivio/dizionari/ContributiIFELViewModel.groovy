package archivio.dizionari

import it.finmatica.tr4.codifiche.CodificheService
import it.finmatica.tr4.dto.ContributiIfelDTO
import org.apache.commons.lang.StringUtils
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Default
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ContributiIFELViewModel {

	// Componenti
	Window self

	//Servizi
	CodificheService codificheService

	//Modello
	ContributiIfelDTO contributo

	boolean inModifica
	boolean inDuplica
	List<ContributiIfelDTO> listaContributiIFEL

	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			 , @ExecutionArgParam("contributo") ContributiIfelDTO contr
			 , @ExecutionArgParam("modifica") boolean modifica
			 , @ExecutionArgParam("duplica")  @Default("false") boolean duplicaDato) {

		this.self 	= w
		inModifica = modifica
		inDuplica = duplicaDato
		listaContributiIFEL = codificheService.getContributi()
		Short anno = Calendar.getInstance().get(Calendar.YEAR)

		if(!contr){
			contributo = new ContributiIfelDTO()
			contributo.anno = anno
		} else {

			contributo = codificheService.getContributo(contr.anno)

			if(duplicaDato){
				contributo = new ContributiIfelDTO()
				contributo.anno = contr.anno
				contributo.aliquota = contr.aliquota
			}
		}

		BindUtils.postNotifyChange(null, null, this, "contributo")
		BindUtils.postNotifyChange(null, null, this, "inDuplica")
		BindUtils.postNotifyChange(null, null, this, "inModifica")
	}
	
    @NotifyChange("contributo")
	@Command onSalva() {
		if (validaMaschera()) {
			contributo = codificheService.salvaContributo(contributo, inModifica)
			Clients.showNotification("Dato salvato", Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
			onChiudi()
		}
	}
	
	@Command onChiudi () {
		Events.postEvent(Events.ON_CLOSE, self, [chiudi: true])
	}

	@Command onElimina () {
		if(contributo){
			Messagebox.show("Il contributo verra' eliminato. Proseguire?", "Eliminazione Contributo",
					Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
					new org.zkoss.zk.ui.event.EventListener() {
						public void onEvent(Event e) {
							if (Messagebox.ON_YES.equals(e.getName())) {
								def elemento = codificheService.cancellaContributo(contributo)
								Clients.showNotification("Contributo eliminato con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
								onChiudi()
							}
						}
					}
			)
		}
	}

	private boolean validaMaschera() {
		def messaggi = [];

		if (contributo.anno == null) {
			messaggi << ("Indicare l'anno'")
		}
		else {
			if(!inModifica){
				//Controllo esistenza per anno
				def contr = codificheService.getContributo(contributo.anno)
				if (contr){
					messaggi.add(0, "Impossibile salvare il contributo:")
					Clients.showNotification("Il contributo per l'anno "+contributo.anno+" esiste gia'!", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
					return false
				}
			}
		}

		if (messaggi.size() > 0) {
			messaggi.add(0, "Impossibile salvare il contributo:")
			Clients.showNotification(StringUtils.join(messaggi, "\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
			return false
		}

		return true
	}
}
