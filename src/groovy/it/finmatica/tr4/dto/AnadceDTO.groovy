package it.finmatica.tr4.dto;

import it.finmatica.tr4.Anadce;

import java.util.Map;

public class AnadceDTO implements it.finmatica.dto.DTO<Anadce> {
    private static final long serialVersionUID = 1L;

    Long id
    String descrizione
    String tipoEvento
    String anagrafe
    
    public Anadce getDomainObject () {
        return Anadce.createCriteria().get {
            eq('id', this.id)
        }
    }
	
    public Anadce toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
	
	
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

}
