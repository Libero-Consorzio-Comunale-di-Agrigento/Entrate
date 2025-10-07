package it.finmatica.tr4.imposte.datiesterni

import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAEG1
import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAEG5

class FiltroRicercaFornitureAE {
	
	private FiltroRicercaFornitureAEG1	filtroG1;
	private FiltroRicercaFornitureAEG5	filtroG5;
	
	Long progrDocG1 = null
	String porzioneDocG1 = null
	
	def getFiltroG1() {
		if(filtroG1 == null) {
			filtroG1 = new FiltroRicercaFornitureAEG1();
		}
		
		return filtroG1;
	}
	
	def setFiltroG1(FiltroRicercaFornitureAEG1 newFiltro) {
		
		filtroG1 = newFiltro;
	}
	
	def getFiltroG5() {
		
		if(filtroG5 == null) {
			filtroG5 = new FiltroRicercaFornitureAEG5();
		}
		
		return filtroG5;
	}

	def setFiltroG5(FiltroRicercaFornitureAEG5 newFiltro) {
		
		filtroG5 = newFiltro;
	}
}
