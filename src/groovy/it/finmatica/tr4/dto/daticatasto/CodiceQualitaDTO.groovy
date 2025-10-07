package it.finmatica.tr4.dto.daticatasto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.daticatasto.CodiceQualita

class CodiceQualitaDTO implements it.finmatica.dto.DTO<CodiceQualita>{

	Long 	id
	Long	version
	String 	descrizione
	
	public CodiceQualita getDomainObject () {
		return CodiceQualita.get(this.id)
	}
	
	public CodiceQualita toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
}
