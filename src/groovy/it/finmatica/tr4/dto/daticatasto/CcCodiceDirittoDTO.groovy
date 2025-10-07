package it.finmatica.tr4.dto.daticatasto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.daticatasto.CcCodiceDiritto

class CcCodiceDirittoDTO implements it.finmatica.dto.DTO<CcCodiceDiritto>{

	Long 	id
	Long	version
	String 	codice
	String 	descrizione
	
	public CcCodiceDiritto getDomainObject () {
		return CcCodiceDiritto.get(this.id)
	}
	
	public CcCodiceDiritto toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}


	/* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
	// qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	public String getDiritto(CcCodiceDirittoDTO diritto) {
		return diritto.codice + "-" + diritto.descrizione
	}
}
