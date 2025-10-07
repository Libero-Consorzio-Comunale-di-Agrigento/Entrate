package it.finmatica.tr4.reports.F24
import it.finmatica.tr4.contribuenti.F24ViolazioniService
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.beans.F24Bean

class DatiF24ViolazioneICI extends AbstractDatiF24 {
	
	F24ViolazioniService f24ViolazioniService

	@Override
	public List<F24Bean> getDatiF24(Long pratica, Boolean ridotto) {

		List<F24Bean> listaF24 = new ArrayList<F24Bean>()

		f24Bean = new F24Bean()

		PraticaTributoDTO praticaDTO = PraticaTributo.get(pratica).toDTO([
			"contribuente",
			"contribuente.soggetto.comuneNascita",
			"contribuente.soggetto.comuneNascita.ad4Comune",
			"contribuente.soggetto.comuneNascita.ad4Comune.provincia"
		])

		// Crezione identificativo operazione
		String identificativoOperazione = generaIdentificativoOperazione(praticaDTO, praticaDTO?.tipoAtto?.tipoAtto == 90 ? praticaDTO.numRata : null)
		
		gestioneTestata(praticaDTO.contribuente)
		f24Bean.identificativoOperazione = identificativoOperazione
		
		listaF24.add(f24Bean)
		
		def dettaglio = f24ViolazioniService.f24ViolazioneDettaglio(pratica, ridotto)
		DettaglioDatiF24ICI dettaglioF24ICI = new DettaglioDatiF24ICI(siglaComune, tipoPagamento, f24Bean, dettaglio)
		dettaglioF24ICI.accept(new DettaglioDatiF24ViolazioneVisitor())
		f24Bean.saldo = f24Bean.dettagli.sum {it.importiDebito}

		return listaF24

	}
}
