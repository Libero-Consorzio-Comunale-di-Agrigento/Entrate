package it.finmatica.tr4.dto;

import it.finmatica.tr4.CivicoOggetto;

import java.util.Map;

public class CivicoOggettoDTO implements it.finmatica.dto.DTO<CivicoOggetto>, Comparable<CivicoOggettoDTO> {
    private static final long serialVersionUID = 1L;

    ArchivioVieDTO archivioVie;
    String indirizzoLocalita;
    Integer numCiv;
    OggettoDTO oggetto;
    Integer sequenza;
    String suffisso;


    public CivicoOggetto getDomainObject () {
        return CivicoOggetto.createCriteria().get {
            eq('oggetto.id', this.oggetto.id)
            eq('sequenza', this.sequenza)
        }
    }
    public CivicoOggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

	// proprietà per gestire la riga che fa riferimento all'indirizzo dell'oggetto
	boolean riferimentoIndirizzo = false

	int compareTo(CivicoOggettoDTO obj) {
		oggetto?.id <=> obj?.oggetto?.id?:
		sequenza <=> obj?.sequenza
	}
}
