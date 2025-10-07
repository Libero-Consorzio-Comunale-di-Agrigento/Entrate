package sportello.contribuenti

import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.competenze.CompetenzeService;
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.zkoss.bind.annotation.BindingParam
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class StoricoProprietariViewModel {

	Window self

	def oggetto

	//Combobox
	def listaAnni
	def annoSelezionato

	def listaProprietari
	//Service
	ContribuentiService contribuentiService
	CompetenzeService competenzeService

	@Init init(@ContextParam(ContextType.COMPONENT) Window w
			, @ExecutionArgParam("oggetto") def oggettoContribuente){
		this.self 	= w
		oggetto = Oggetto.get(oggettoContribuente).toDTO(["archivioVie", "tipoOggetto", "categoriaCatasto"])

		listaAnni = contribuentiService.calcolaAnni(oggetto.id)
		listaProprietari = contribuentiService.getProprietari(oggetto.id, annoSelezionato?:"Tutti")
	}

	@NotifyChange(["listaProprietari"])
	@Command cercaPerAnno()	{
		listaProprietari = contribuentiService.getProprietari(oggetto.id, annoSelezionato?:"Tutti")
	}

	@Command onApriPraticaIMU(@BindingParam("arg") def proprietario) {
		String parametri = "sezione=PRATICA"
		parametri += "&idPratica=${proprietario.pratica}"
		parametri += "&tipoTributo=ICI"
		parametri += "&tipoRapporto=${proprietario.tipoRapporto}"

		//Verifico se l'utente ha permessi in lettura
		def praticaSelezionata = PraticaTributo.get(proprietario.pratica)
		def lettura = competenzeService.tipoAbilitazioneUtente(praticaSelezionata.tipoTributo.tipoTributo) == competenzeService.TIPO_ABILITAZIONE.LETTURA
		parametri += "&lettura=${lettura}"

		Clients.evalJavaScript("window.open('standalone.zul?$parametri','_blank');")
	}

	@Command onChiudi() {
		Events.postEvent(Events.ON_CLOSE, self, null)
	}
}
