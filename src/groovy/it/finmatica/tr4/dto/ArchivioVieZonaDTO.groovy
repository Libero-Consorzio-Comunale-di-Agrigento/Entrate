package it.finmatica.tr4.dto;

import it.finmatica.tr4.ArchivioVieZona;
import it.finmatica.tr4.ArchivioVie;

import java.util.Date;
import java.util.Map;

public class ArchivioVieZonaDTO implements it.finmatica.dto.DTO<ArchivioVieZona> {

    Long id;
	
	ArchivioVieDTO archivioVie
	Short sequenza
	
	Integer daNumCiv
	Integer aNumCiv
	
	boolean flagPari
	boolean flagDispari
	
	Double daChilometro
	Double aChilometro
	String lato
	
	Short daAnno
	Short aAnno
	
	Short codZona
	Short sequenzaZona
	
	public ArchivioVieZona getDomainObject () {
		return ArchivioVieZona.createCriteria().get {
			eq('archivioVie', this.archivioVie.getDomainObject())
			eq('sequenza', this.sequenza)
		}
	}
	
	public ArchivioVieZona toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
}
