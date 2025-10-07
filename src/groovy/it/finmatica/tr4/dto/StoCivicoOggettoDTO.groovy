package it.finmatica.tr4.dto;

import it.finmatica.tr4.StoCivicoOggetto;

import java.util.Map;

public class StoCivicoOggettoDTO implements it.finmatica.dto.DTO<StoCivicoOggetto>, Comparable<StoCivicoOggettoDTO> {

	private static final long serialVersionUID = 1L;

	ArchivioVieDTO archivioVie;
	String indirizzoLocalita;
	Integer numCiv;
	StoOggettoDTO oggetto;
	Integer sequenza;
	String suffisso;

	public StoCivicoOggetto getDomainObject () {
		return StoCivicoOggetto.createCriteria().get {
			eq('oggetto.id', this.oggetto.id)
			eq('sequenza', this.sequenza)
		}
	}
	public StoCivicoOggetto toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	// proprietè per gestire la riga che fa riferimento all'indirizzo dell'oggetto
	boolean riferimentoIndirizzo = false

	int compareTo(StoCivicoOggettoDTO obj) {
		oggetto?.id <=> obj?.oggetto?.id?:
		sequenza <=> obj?.sequenza
	}
}

