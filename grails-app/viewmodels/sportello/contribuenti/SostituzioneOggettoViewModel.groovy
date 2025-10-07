package sportello.contribuenti

import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.OggettoDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class SostituzioneOggettoViewModel {

	Window self

	String tipoTributo
	String cfContr
	OggettoDTO newOggetto
	OggettoDTO oldOggetto
	Map dettaglioOggetto = [tipoTributo: null, cfContr: null, idOldOggetto: null, idNewOggetto: null]
	String status

	List praticheOggetto
	List praticheSelezionate
	boolean praticheCompletate
	boolean terminaSostituzione
	boolean praticaAnomala

	boolean visualizzaPratiche

	List anomalieSostituzione = []
	List tipiTributo
	def tipoTributoSelezionato = [:]

	ContribuentiService contribuentiService

	@NotifyChange("praticheOggetto")
	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			, @ExecutionArgParam("dettaglioOggetto") Map d
			, @ExecutionArgParam("sostituisciDaAnomalie") boolean s) {
		this.self 	= w
		dettaglioOggetto = d
		visualizzaPratiche = s
		praticheCompletate = false
		terminaSostituzione = false

		newOggetto = Oggetto.get(dettaglioOggetto.idNewOggetto).toDTO(["tipoOggetto", "categoriaCatasto", "archivioVie", "fonte", "riferimentiOggetto"])
		oldOggetto = Oggetto.get(dettaglioOggetto.idOldOggetto).toDTO(["tipoOggetto", "categoriaCatasto", "archivioVie", "fonte", "riferimentiOggetto"])
		
		//		listaTipiTributo  = TipoTributo.list().toDTO()
		praticheOggetto = contribuentiService.getPraticheOggetto(oldOggetto.id, dettaglioOggetto.cfContr)
		for (Map pratica : praticheOggetto) {
			controllaAnomalie(pratica)
		}
		
		if (!s) {
			tipiTributo = contribuentiService.tributiSostituzioneOggetto(dettaglioOggetto.cfContr, dettaglioOggetto.idOldOggetto as Long, oldOggetto.tipoOggetto.tipoOggetto as Long)
			tipoTributoSelezionato = tipiTributo[0]
		}
	}

	@NotifyChange("praticheSelezionate")
	@Command onSostituisciOggetto(){
		if ((praticheSelezionate == null || praticheSelezionate.isEmpty()) && visualizzaPratiche) {
			Clients.showNotification("Attenzione! Selezionare almeno una pratica", Clients.NOTIFICATION_TYPE_WARNING, self, "middle_center", 3000, true);
		} else {
			//anomalieSostituzione = []praticaAnomala = praticheSelezionate.find { it.anomalia != null}

			if(praticheSelezionate.find { it.anomalia != null}){
				Messagebox.show("Attenzione! Verranno sostituite delle pratiche con anomalie. \n Vuoi proseguire?", "Sostituzione oggetto", Messagebox.YES | Messagebox.NO, Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {
							public void onEvent(Event e){
								if (Messagebox.ON_YES.equals(e.getName())) {
									controllaAnomalieSostituzione()
								} else if(Messagebox.ON_CANCEL.equals(e.getName())){
									//Cancel is clicked
								}
							}
						})
			} else {
				controllaAnomalieSostituzione()
			}
		}
	}

	private void controllaAnomalie(Map pratica) {
		def checkAcc = contribuentiService.verificaOggettoAcc(pratica.tipoTributoOrig, pratica.codFiscale, oldOggetto.id)
		def checkLiq = contribuentiService.verificaOggettoLiq(pratica.tipoTributoOrig, pratica.codFiscale, oldOggetto.id)
		String message = ""
		if (checkAcc.size() > 0 || checkLiq.size() > 0) {
			message = contribuentiService.getAccLiqOggetto(pratica.tipoTributoOrig, pratica.codFiscale, oldOggetto.id)
		} else {
			message = contribuentiService.checkSostituzioneOggetto(pratica.tipoTributoOrig, oldOggetto.id, newOggetto.id, "S")
		}
		pratica.anomalia = message
	}

	private void controllaAnomalieSostituzione() {
		anomalieSostituzione = []
		if(visualizzaPratiche){
			for (Map p : praticheSelezionate) {
				String messageAnomalie = contribuentiService.sostituzioneOggetto(p.codFiscale, p.tipoTributoOrig, oldOggetto.id, newOggetto.id)
				if (messageAnomalie) {
					p.anomalia = messageAnomalie
				} else {
					p.anomalia = "Sostituzione avvenuta con successo"
				}
				anomalieSostituzione << p
			}

			Window w = Executions.createComponents("/ufficiotributi/bonificaDati/riepilogoSostituzioni.zul", self, [anomalieSostituzione: anomalieSostituzione])
			w.doModal()
			w.onClose(){
				terminaSostituzione = true
				praticheOggetto = contribuentiService.getPraticheOggetto(oldOggetto.id, dettaglioOggetto.cfContr)
				if(praticheOggetto.size() > 0)
				{
					for (Map pratica : praticheOggetto) {
						controllaAnomalie(pratica)
					}
				}
				BindUtils.postNotifyChange(null, null, this, "praticheOggetto")
				BindUtils.postNotifyChange(null, null, this, "terminaSostituzione")
			}
			praticheSelezionate = null
		} else{
			String messageAnomalie = contribuentiService.sostituzioneOggetto(dettaglioOggetto.cfContr, tipoTributoSelezionato.tipoTributo, oldOggetto.id, newOggetto.id)
			if (messageAnomalie) {
				Messagebox.show(messageAnomalie, "Attenzione", Messagebox.OK, Messagebox.EXCLAMATION)
			} else {
				Messagebox.show("Sostituzione avvenuta con successo", null, Messagebox.OK, Messagebox.EXCLAMATION)
			}
			terminaSostituzione = true
			BindUtils.postNotifyChange(null, null, this, "terminaSostituzione")
		}
	}

	@Command onAnnulla(){
		Events.postEvent(Events.ON_CLOSE, self, [annulla: true])
	}
	@Command onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, [status: status, praticheCompletate: praticheCompletate])
	}
}
