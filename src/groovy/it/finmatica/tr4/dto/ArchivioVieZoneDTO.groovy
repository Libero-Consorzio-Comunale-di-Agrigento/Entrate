package it.finmatica.tr4.dto;

import it.finmatica.tr4.ArchivioVieZone;

import java.util.Map;

public class ArchivioVieZoneDTO implements it.finmatica.dto.DTO<ArchivioVieZone> {

    Long id;
	
	Short codZona
	Short sequenza
	String denominazione
	Short daAnno
	Short aAnno
	
	public ArchivioVieZone getDomainObject () {
		return ArchivioVieZone.createCriteria().get {
			eq('codZona', this.codZona)
			eq('sequenza', this.sequenza)
		}
	}
	
	public ArchivioVieZone toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}

	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
}
