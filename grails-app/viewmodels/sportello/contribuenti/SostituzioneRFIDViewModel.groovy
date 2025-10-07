package sportello.contribuenti

import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.Application20999Error
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.Component
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zk.ui.ext.Disable
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window
import org.zkoss.zul.Popup

 import it.finmatica.tr4.CodiceRfid

class SostituzioneRFIDViewModel {

	Window self

    CommonService commonService
    ContribuentiService contribuentiService
	OggettiService oggettiService
	DenunceService denunceService

	def oggettoOriginale
	String codFiscale
	def tipiTributo
	def tipiPratica

	def listaOriginali
	def originaleSelezionato

    def listaOggetti
	def oggettoSelezionato

    def svuotamentiTooltipText = [:]

	boolean salvato = false

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w
			, @ExecutionArgParam("oggetto") def o
			, @ExecutionArgParam("codFiscale") def cf
			, @ExecutionArgParam("tipiTributo") def tt
			, @ExecutionArgParam("tipiPratica") def tp) {

		this.self = w

		oggettoOriginale = o

		codFiscale = cf
        tipiTributo = tt
        tipiPratica = tp

		listaOriginali = []
		listaOriginali << oggettoOriginale
		originaleSelezionato = oggettoOriginale

		listaOggetti = contribuentiService.oggettiContribuenteStoria(codFiscale,tipiTributo,tipiPratica,null)
		listaOggetti = listaOggetti.findAll { it.oggetto != oggettoOriginale.oggetto }
		oggettoSelezionato = null
	}
	
	@Command
	def onSelezionaOriginale(@BindingParam("popup") Component popup) {

	}

	@Command
	def onSelezionaOggetto(@BindingParam("popup") Component popup) {

	}

    @Command
    def onTooltipInfoOggetti(@BindingParam("sorgente") String sorgente, @BindingParam("uuid") String uuid) {

        def ogg = listaOggetti.find { it.uuid == uuid }
		if(ogg == null) {
			ogg = listaOriginali.find { it.uuid == uuid }
		}

        switch (sorgente) {
            case 'sost-rfid-svuot':
                svuotamentiTooltipText[uuid] = svuotamentiTooltipText[uuid] ?: oggettiService.tooltipSvuotamenti(codFiscale, ogg.oggetto)
                BindUtils.postNotifyChange(null, null, this, "svuotamentiTooltipText")
                break
        }
    }

	@Command
	def onGeolocalizzaOriginale() {

		geolocalizzaOggetto(originaleSelezionato)
	}

	@Command
	def onGeolocalizzaOggetto() {

		geolocalizzaOggetto(oggettoSelezionato)
	}

	@Command
	def onSostituisciRFID() {

		def oggetto = oggettoSelezionato.oggetto as Long

        String messaggio = "Confermando la sostituzione saranno trasferiti sul nuovo oggetto tutti gli svuotamenti " + 
						   "già caricati per il contribuente/RFID.\n" + 
						   "Se non si vogliono trasferire gli svuotamenti, chiudere il precedente RFID sull'Attuale " + 
						   "Oggetto e inserire lo stesso RFID sul Nuovo Oggetto.\n\n" + 
						   "Si desidera continuare?"

        Messagebox.show(messaggio, "Attenzione",
            Messagebox.YES | Messagebox.NO | Messagebox.CANCEL, Messagebox.QUESTION, 
			{ e ->
                if (Messagebox.ON_YES.equals(e.getName())) {
                    applicaRFID(oggetto)
                    if (salvato)
                        chiudi()
                }
				else if (Messagebox.ON_NO.equals(e.getName())) {
                    chiudi()
                }
				else if (Messagebox.ON_CANCEL.equals(e.getName())) {
                    // Nulla da fare
                }
            }
		)
	}

	@Command
	def onAnnulla() {
		chiudi()
	}

	def geolocalizzaOggetto(def oggetto) {

        String url = oggettiService.getGoogleMapshUrl(null, oggetto.latitudine, oggetto.longitudine)
        Clients.evalJavaScript("window.open('${url}','_blank');")
	}

	def applicaRFID(Long oggetto) {

        try {
			denunceService.sostituzioneRfid(codFiscale, oggettoOriginale.oggetto as Long, oggetto)

			salvato = true
        }
        catch (Exception e) {

			if(e.getCause() == null) {
				throw e
			}
			else {
				def message = e.getCause().message
				throw new Exception(message)
			}
        }
	}

	def chiudi() {

		if(salvato) {
			Events.postEvent(Events.ON_CLOSE, self, [ salvato : salvato ])
		}
		else {
			Events.postEvent(Events.ON_CLOSE, self, null)
		}
	}
}
