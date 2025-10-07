package archivio

import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window
import org.zkoss.zhtml.Messagebox;
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events

import it.finmatica.tr4.jobs.GisJob

class OggettiWebGisViewModel {

    def self

    def springSecurityService

    def integrazioneWEBGISService

	boolean integrazioneAbilitata = false
	boolean sincronizzazioneAbilitata = false
	
    def oggettiSelezionati
    def listaOggetti

    def zul

    def oggettoSelezionato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("oggetti") def oggetti,
         @ExecutionArgParam("zul") def zul) {

        this.self = w
		
		this.integrazioneAbilitata = integrazioneWEBGISService.integrazioneAbilitata();
		this.sincronizzazioneAbilitata = integrazioneWEBGISService.sincronizzazioneAbilitata();
		
        listaOggetti = oggetti
        this.zul = zul
    }

	@Command
	def onSincronizzaMappa() {
		
		Messagebox.show("L'operazione potrebbe richiedere molto tempo !\n\nSicuri di voler procedere ?", "Sincronizzazione",
			Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
			new org.zkoss.zk.ui.event.EventListener() {
				public void onEvent(Event e) {
					if (Messagebox.ON_YES.equals(e.getName())) {
						
						sincronizzaMappa();
					}
				}
			}
		)
	}
	
	private sincronizzaMappa() {
		
		GisJob.triggerNow([ codiceUtenteBatch: springSecurityService.currentUser.id,
							codiciEntiBatch  : springSecurityService.principal.amministrazione.codice])
		
		String title = "Sincronizzazione";
		String message = "Job avviato";
		Messagebox.show(message,title, Messagebox.OK, Messagebox.INFORMATION);
	}
	
    @Command
    def onVisualizzaMappa() {
		
		if((oggettiSelezionati == null) || (oggettiSelezionati.size() == 0)) {
			
			String title = "Problema di selezione";
			String message = "Attenzione :\n\nNessun oggetto selezionato";
			Messagebox.show(message,title, Messagebox.OK, Messagebox.EXCLAMATION);
			return;
		}

		def oggettiDaVisualizzare = []
        oggettiSelezionati.each {

            if (zul.indexOf("Cruscotto") * zul.indexOf("Archivio") < 0) {
                oggettiDaVisualizzare << [tipoOggetto : it.tipoOggetto, sezione: it.sezione, foglio: it.foglio, numero: it.numero]
            } else {
                oggettiDaVisualizzare << [tipoOggetto : it.tipoOggetto, sezione: it.SEZIONE, foglio: it.FOGLIO, numero: it.NUMERO]
            }
        }
		
		integrazioneWEBGISService.openWebGis(oggettiDaVisualizzare)
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onSelezionaRiga() {}

}
