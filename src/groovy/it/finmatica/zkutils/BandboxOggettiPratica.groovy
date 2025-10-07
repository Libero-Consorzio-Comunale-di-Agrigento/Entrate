package it.finmatica.zkutils

import grails.util.Holders

import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.select.Selectors
import org.zkoss.zk.ui.select.annotation.Listen
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Combobox
import org.zkoss.zul.ListModelList

class BandboxOggettiPratica extends CustomBandbox {	
	
	private String nomeMetodo
	
	@Wire("combobox")
	protected Combobox comboAnno
	
	private Long oggettoPraticaRifAp
	
	public BandboxOggettiPratica () {
		super()
		Executions.createComponents("/commons/bandboxOggettiPratica.zul", this, null)
		
		Selectors.wireVariables(this, this, null)
		Selectors.wireComponents(this, this, false)
		Selectors.wireEventListeners(this, this)
		
	}
	
	protected void loadData() {		
		def elencoOggettiPratica = Holders.grailsApplication.mainContext.getBean("denunceService")."${nomeMetodo}"(getOggetto(), paging.getPageSize(), paging.getActivePage(), listaFetch)
		lista.setModel(new ListModelList(elencoOggettiPratica.lista))
		paging.setTotalSize(elencoOggettiPratica.totale)
		def anni = Holders.grailsApplication.mainContext.getBean("denunceService").anniOgco(getOggetto())
		comboAnno.setModel(new ListModelList(anni))
		comboAnno.setValue(String.valueOf(getOggetto()["anno"]))
		
	}
	
	public String getNomeMetodo(){
		return this.nomeMetodo
	}
	
	public void setNomeMetodo(String nomeMetodo){
		this.nomeMetodo = nomeMetodo
	}
	
	/*Vado in override per leggere oggetto.id (che non ha lo stesso nome della proprieta in cui verra' scritto
	 * e per leggere oggettoPratica.id che andra' nell'oggettoPraticaRifAp del oggettoPratica che modifichero'*/
	@Listen("onSelect = listbox")
	public void selectData() {
		if (lista.getSelectedItem()){
			getOggetto()[getProprieta()] = lista.getSelectedItem().getValue()["oggettoPratica"].oggetto?.id
			setValue(String.valueOf(getOggetto()[getProprieta()]))
			setOggettoPraticaRifAp(lista.getSelectedItem().getValue()["oggettoPratica"]?.id)			
			//rilancia onSelect del viewModel
			Events.postEvent(Events.ON_SELECT, this, lista.getSelectedItem().getValue())
			close()
		}
	}
	
	@Listen("onSelect = combobox")
	public void selectAnno() {
		if (comboAnno.getSelectedItem()){
			getOggetto()["anno"] = comboAnno.getSelectedItem().getValue()
			loadData()
		}
	}
	
	public Long getOggettoPraticaRifAp(){
		return this.oggettoPraticaRifAp
	}
	
	public void setOggettoPraticaRifAp(Long oggettoPraticaRifAp){
		this.oggettoPraticaRifAp = oggettoPraticaRifAp
	}

	@Override
	protected void controllaSingoloElemento() {}

}
