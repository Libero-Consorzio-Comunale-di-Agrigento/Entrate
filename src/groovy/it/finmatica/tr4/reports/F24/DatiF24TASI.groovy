package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.WebCalcoloIndividuale
import it.finmatica.tr4.dto.WebCalcoloIndividualeDTO
import it.finmatica.tr4.reports.beans.F24Bean

import org.hibernate.FetchMode

class DatiF24TASI extends AbstractDatiF24 {
	
	
	@Override
	public List<F24Bean> getDatiF24(String codiceFiscale, short anno) {
		List<F24Bean> listaF24 = new ArrayList<F24Bean>()
		
		WebCalcoloIndividualeDTO webCalcoloIndividuale = WebCalcoloIndividuale.createCriteria().get{
			eq("contribuente.codFiscale", codiceFiscale)
			eq("tipoTributo.tipoTributo", "TASI")
			eq("anno", anno)
			fetchMode("contribuente", FetchMode.JOIN)
			fetchMode("contribuente.soggetto", FetchMode.JOIN)
			fetchMode("contribuente.soggetto.comuneNascita", FetchMode.JOIN)
			fetchMode("contribuente.soggetto.comuneNascita.ad4Comune", FetchMode.JOIN)
			fetchMode("contribuente.soggetto.comuneNascita.ad4Comune.provincia", FetchMode.JOIN)
			fetchMode("webCalcoloDettagli", FetchMode.JOIN)
		}.toDTO(["webCalcoloDettagli", "contribuente", "contribuente.soggetto.comuneNascita", "contribuente.soggetto.comuneNascita.ad4Comune", "contribuente.soggetto.comuneNascita.ad4Comune.provincia"])

		f24Bean = new F24Bean()
		gestioneTestata(webCalcoloIndividuale.contribuente)
		DettaglioDatiF24TASI dettaglioF24TASI = new DettaglioDatiF24TASI(siglaComune, tipoPagamento, f24Bean, webCalcoloIndividuale.webCalcoloDettagli)
		dettaglioF24TASI.accept(new DettaglioDatiF24Visitor())
		f24Bean.dettagli.sort{ it.codiceTributo }
		f24Bean.dettagli.find {it.codiceTributo == DettaglioDatiF24TASI.codiciTributo["ABITAZIONE_PRINCIPALE"]}?.detrazione = dettaglioF24TASI.detrazione
		f24Bean.saldo = f24Bean.dettagli.sum {it.importiDebito}
		listaF24.add(f24Bean)
	
		return listaF24
	}
	
}
