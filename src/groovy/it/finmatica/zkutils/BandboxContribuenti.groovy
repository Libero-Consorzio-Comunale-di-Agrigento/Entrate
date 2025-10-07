package it.finmatica.zkutils

import grails.util.Holders
import it.finmatica.tr4.dto.SoggettoDTO
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zul.ListModelList

class BandboxContribuenti extends CustomBandbox {
	
	BandboxContribuenti() {
		super()

		Executions.createComponents("/commons/bandboxContribuenti.zul", this, null)

		Selectors.wireVariables(this, this, null)
		Selectors.wireComponents(this, this, false)
		Selectors.wireEventListeners(this, this)
	}

	protected void loadData () {
		if (getOggetto()[getProprieta()] == "") {
			getOggetto().codFiscale = ""
			getOggetto().soggetto.cognomeNome = ""
		}
		def elencoContribuenti = Holders.grailsApplication.mainContext.getBean("contribuentiService").listaContribuentiBandbox(getOggetto(), paging.getPageSize(), paging.getActivePage())
		
		lista.setModel(new ListModelList<SoggettoDTO>(elencoContribuenti.lista))
		paging.setTotalSize(elencoContribuenti.totale)
	}

	@Override
	protected void controllaSingoloElemento() {}
	
}
