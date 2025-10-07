package it.finmatica.zkutils

import grails.util.Holders
import it.finmatica.tr4.dto.ArchivioVieDTO

import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zul.ListModelList

class BandboxVie extends CustomBandbox {
	
	public BandboxVie() {
		super()
		
		Executions.createComponents("/commons/bandboxVie.zul", this, null)
		
		Selectors.wireVariables(this, this, null)
		Selectors.wireComponents(this, this, false)
		Selectors.wireEventListeners(this, this)
	}

	protected void loadData () {
		def elencoVie =  Holders.grailsApplication.mainContext.getBean("archivioVieService").listaVie(getOggetto()[getProprieta()], paging.getPageSize(), paging.getActivePage())

		if (elencoVie.lista.isEmpty()) {
			Events.postEvent(Events.ON_ERROR, this, "dato_non_valido")
		}
		lista.setModel(new ListModelList<ArchivioVieDTO>(elencoVie.lista))
		paging.setTotalSize(elencoVie.totale)
	}

	@Override
	protected void controllaSingoloElemento() {}
	
}
