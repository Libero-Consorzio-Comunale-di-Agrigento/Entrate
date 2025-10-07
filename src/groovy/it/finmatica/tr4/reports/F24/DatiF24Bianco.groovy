package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.reports.beans.F24Bean
import org.hibernate.FetchMode

class DatiF24Bianco extends AbstractDatiF24 {
	
	
	@Override
	public List<F24Bean> getDatiF24(String codiceFiscale) {
		List<F24Bean> listaF24 = new ArrayList<F24Bean>()
		
		ContribuenteDTO contribuente = Contribuente.createCriteria().get {
			eq("codFiscale", codiceFiscale)
			fetchMode("soggetto", FetchMode.JOIN)
		}.toDTO(["soggetto", "soggetto.comuneNascita", "soggetto.comuneNascita.ad4Comune", "soggetto.comuneNascita.ad4Comune.provincia"])

		f24Bean = new F24Bean();
		gestioneTestata(contribuente)
		
		
		listaF24.add(f24Bean)
	
		return listaF24
	}

}
