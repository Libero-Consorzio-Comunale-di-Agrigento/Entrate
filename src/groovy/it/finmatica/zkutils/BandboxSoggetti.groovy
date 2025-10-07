package it.finmatica.zkutils

import grails.util.Holders
import it.finmatica.tr4.dto.SoggettoDTO

import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Listen
import org.zkoss.zul.ListModelList

class BandboxSoggetti extends CustomBandbox {

	//parametro di ricerca codice fiscale in caso di oggetto nullo
	def codice

	public BandboxSoggetti () {
		super()
		
		Executions.createComponents("/commons/bandboxSoggetti.zul", this, null)
		
		Selectors.wireVariables(this, this, null)
		Selectors.wireComponents(this, this, false)
		Selectors.wireEventListeners(this, this)
	}

	protected void loadData () {
		if (getOggetto()!=null) {
			if ( getOggetto()[getProprieta()] == "") {
				getOggetto().codFiscale = ""
				getOggetto().cognomeNome = ""
			}
		}
		else {
			def soggetto = new SoggettoDTO()
			soggetto.codFiscale = codice?:""
			soggetto.cognomeNome =""
			setOggetto(soggetto)
		}

		def elencoSoggetti = Holders.grailsApplication.mainContext.getBean("soggettiService").listaSoggettiBandbox(getOggetto(), paging.getPageSize(), paging.getActivePage(), listaFetch)
		lista.setModel(new ListModelList<SoggettoDTO>(elencoSoggetti.lista))
		paging.setTotalSize(elencoSoggetti.totale)
	}
	
	@Override
	@Listen("onSelect = listbox")
	public void selectData() {
		if (lista.getSelectedItem()){



			getOggetto()[getProprieta()] = (lista.getSelectedItem().getValue().hasProperty(getProprieta())?(lista.getSelectedItem().getValue()[getProprieta()]?:""):"")
			getOggetto()["id"] = (lista.getSelectedItem().getValue().hasProperty("id")?(lista.getSelectedItem().getValue()["id"]?:""):"")
			setValue(getOggetto()[getProprieta()])
			Events.postEvent(Events.ON_SELECT, this, lista.getSelectedItem().getValue())
			close()
		}
	}

	@Override
	protected void controllaSingoloElemento() {}

}
