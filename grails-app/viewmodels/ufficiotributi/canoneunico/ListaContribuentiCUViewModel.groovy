package ufficiotributi.canoneunico

import it.finmatica.tr4.tributiminori.CanoneUnicoService

import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.dto.SoggettoDTO

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.bind.annotation.NotifyChange
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event;
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ListaContribuentiCUViewModel {
	
	Window self
	
	// services
	CanoneUnicoService canoneUnicoService

	boolean	creaContribuenteVisible = false
	
	def 	listaContribuenti
	def 	contribuenteSelezionato
	Long	idSoggetto
	
    def pagingLista = [
        activePage: 0,
        pageSize  : 30,
        totalSize : 0
    ]

	// dati
	boolean stampaVisibile = false
	boolean	filtroAttivo = false

	def filtriContribuente = [  
		cognomeNome:	"",
		cognome:		"",
		nome:			"",
		codFiscale:		"",
		indirizzo:		"",
		contribuenteCU:	1,
		id:				null
	]
	
	@NotifyChange(["pagingLista"])
	@Init init(@ContextParam(ContextType.COMPONENT) Window w) {
		
		this.self = w
		
		this.creaContribuenteVisible = true;
		
		apriMascheraRicerca()		
	}
	
	@Command
	openCloseFiltri() {
		
		apriMascheraRicerca()
	}
	
	@Command
	onCerca() {
		
		caricaLista()
	}
	
	@Command
	onModifica() {
		
		apriMascheraContribuente(contribuenteSelezionato.id);
	}
	
	@Command
	onNuovo() {
		
		String codFiscale = filtriContribuente?.codFiscale ?: ""
		
		def filtri = [ 
			personaFisica: 		true,
			personaGiuridica: 	true,
			personaParticolare:	true,
			residente:			true,
			contribuente:		"n",			/// Non vogliamo i contribuenti
			gsd:				true,
			cognomeNome:		"",
			codFiscale:			codFiscale,
			fonte:				-1,
			indirizzo:			"",
			id:					null,
			cognome:			"",
			nome:				""
		]
		
		Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul",
			self,
			[ filtri: filtri, listaVisibile: true ]
		)
		w.onClose { event ->
			if (event.data) {
				if (event.data.status == "Soggetto") {
					aggiungiContribuente(event.data.Soggetto)
				}
			}
		}
		w.doModal()
	}
		
	@Command
	onRefresh(){
		
		caricaLista()
	}
	
	private apriMascheraContribuente(def idSogg) {
		
		Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${idSogg}','_blank');")
	}
	
	private aggiungiContribuente(SoggettoDTO selectedSoggetto) {
		
		if (selectedSoggetto) {
			
			Contribuente contribuente = canoneUnicoService.creaContribuente(selectedSoggetto);
			
			caricaLista();
			
			apriMascheraContribuente(contribuente.soggetto.id)
		}
		
	}
	
	private caricaLista() {
		
		def elenco = canoneUnicoService.getContribuenti(filtriContribuente, pagingLista.pageSize, pagingLista.activePage)
		listaContribuenti = elenco.records
		pagingLista.totalSize = elenco.totalCount
		
		BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
		BindUtils.postNotifyChange(null, null, this, "pagingLista")
	}
	
	private apriMascheraRicerca() {
		
		Window w = Executions.createComponents("/ufficiotributi/canoneunico/listaContribuentiCURicerca.zul", self, [filtri: filtriContribuente])
		w.onClose { event ->
			if (event.data) {
				if(event.data.status == "Cerca") {
					filtriContribuente = event.data.filtri
					filtroAttivo = isFiltroAttivo();
					pagingLista.activePage = 0
					caricaLista()
					if (listaContribuenti.size() == 1) {
						contribuenteSelezionato = listaContribuenti[0]
						onModifica()
					}
				}
			}
			BindUtils.postNotifyChange(null, null, this, "filtriContribuente")
			BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
			BindUtils.postNotifyChange(null, null, this, "contribuenteSelezionato")
		}
		w.doModal()
	}
	
	///
	/// *** Verifica se filtro attivo
	///
	public boolean isFiltroAttivo() {
		
		return ( filtriContribuente.cognomeNome != ""
				|| filtriContribuente.cognome != ""
				|| filtriContribuente.nome != ""
				|| filtriContribuente.codFiscale != ""
				|| filtriContribuente.indirizzo != ""
				|| filtriContribuente.id != null
				|| filtriContribuente.contribuenteCU != 1)
	}
}
