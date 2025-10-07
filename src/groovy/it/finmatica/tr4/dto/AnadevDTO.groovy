package it.finmatica.tr4.dto;

import it.finmatica.tr4.Anadev;

import java.util.Map;

public class AnadevDTO implements it.finmatica.dto.DTO<Anadev> {
    private static final long serialVersionUID = 1L;

    Long id
    String descrizione
	Boolean segnalazione
    String flagStato
    
    public Anadev getDomainObject () {
        return Anadev.createCriteria().get {
            eq('id', this.id)
        }
    }
	
    public Anadev toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
	
	
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
