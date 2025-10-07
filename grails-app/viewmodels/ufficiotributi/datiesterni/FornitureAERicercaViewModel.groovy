package ufficiotributi.datiesterni

import it.finmatica.tr4.imposte.datiesterni.*
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.datiesterni.FornitureAEService
import org.junit.After;
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class FornitureAERicercaViewModel {

	// Services
	def springSecurityService
	FornitureAEService fornitureAEService

	def filtroAccertamento = [
		[ codice: null, descrizione : 'Tutti'],
		[ codice: 1, descrizione : 'Solo assegnati'],
		[ codice: 2, descrizione : 'Solo non asseganti'],
	]
	def filtroAccertatoSelected
		
	def filtroProvvisorio = [
		[ codice: null, descrizione : 'Tutti'],
		[ codice: 1, descrizione : 'Solo assegnati'],
		[ codice: 2, descrizione : 'Solo non asseganti'],
	]
	def filtroProvvisorioSelected

	def enteComunale  = [
		codPro : null,
		codCom : null,
		///
		denominazione : "",
		provincia : "",
		siglaProv : "",
		siglaCFis : ""
	]

	// Componenti
	Window self

	Boolean flagProvincia = false
	Long progrDoc = null
	FiltroRicercaFornitureAEG1 filtri
	
    def codiceEnteSelezionato = null

	@Init
	init(@ContextParam(ContextType.COMPONENT) Window w,
						 @ExecutionArgParam("filtri") def ff,
						 @ExecutionArgParam("flagProvincia") Boolean fp,
						 @ExecutionArgParam("progrDoc") Long pd) {

        this.self = w

        this.flagProvincia = fp
		this.progrDoc = pd ?: 0
		
		filtri = ff ?: new FiltroRicercaFornitureAEG1();
		
		filtroAccertatoSelected = filtroAccertamento.find { it.codice == filtri.filtroAccertato };
		filtroProvvisorioSelected = filtroProvvisorio.find { it.codice == filtri.filtroProvvisorio };

		inizializzaDettagliEnte(filtri.codEnteComunale)
	}
						 
	/// Eventi interfaccia ######################################################################################################
	
	@Command
	onSvuotaFiltri() {
		
		filtri = new FiltroRicercaFornitureAEG1();
		
		filtroAccertatoSelected = null
		filtroProvvisorioSelected = null

		inizializzaDettagliEnte(null)
	
		BindUtils.postNotifyChange(null, null, this, "filtri")
		BindUtils.postNotifyChange(null, null, this, "filtroAccertatoSelected")
		BindUtils.postNotifyChange(null, null, this, "filtroProvvisorioSelected")
	}
	
	@Command
	onCerca() {

		filtri.codEnteComunale = enteComunale.siglaCFis
		filtri.filtroAccertato = filtroAccertatoSelected?.codice
		filtri.filtroProvvisorio = filtroProvvisorioSelected?.codice

		Events.postEvent(Events.ON_CLOSE, self,	[ status: "cerca", filtri: filtri ])
	}

    @Command
    onSelectEnte(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

		def selectedComune = event?.data
		
		if ((selectedComune != null) && ((selectedComune.denominazione ?: '').size() > 1)) {
			enteComunale.codPro = (selectedComune.provincia != null) ? selectedComune.provincia.id : selectedComune.stato.id
			enteComunale.codCom = selectedComune.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}

		aggiornaDettagliEnte()
    }
	
	@Command
	onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}

	/// Metodi interni ######################################################################################################
	
	def inizializzaDettagliEnte(String siglaCFis) {

		if((siglaCFis != null) && (!siglaCFis.isEmpty())) {
			def comune = fornitureAEService.getComuneDaSiglaCFis(siglaCFis)

			enteComunale.codPro = comune?.provincia?.id ?: comune?.stato?.id
			enteComunale.codCom = comune?.comune
		}
		else {
			enteComunale.codPro = null
			enteComunale.codCom = null
		}
		aggiornaDettagliEnte()
	}

	def aggiornaDettagliEnte() {

		Ad4ComuneTr4 comune = null
		
		Long codPro = enteComunale.codPro as Long
		Integer codCom = enteComunale.codCom as Integer
		
		if (codCom != null && codPro != null) {
			comune = Ad4ComuneTr4.createCriteria().get {
				eq('provinciaStato', codPro)
				eq('comune', codCom)
			}
		}
		
		if(comune) {
			Ad4Comune ad4Comune = comune.ad4Comune
			
			enteComunale.denominazione = ad4Comune?.denominazione
			enteComunale.provincia = ad4Comune?.provincia?.denominazione
			enteComunale.siglaProv = ad4Comune?.provincia?.sigla
			enteComunale.siglaCFis = ad4Comune?.siglaCodiceFiscale
		}
		else {
			enteComunale.denominazione = ""
			enteComunale.provincia = ""
			enteComunale.siglaProv = ""
			enteComunale.siglaCFis = ""
		}
		
        BindUtils.postNotifyChange(null, null, this, "enteComunale")
	}
}
