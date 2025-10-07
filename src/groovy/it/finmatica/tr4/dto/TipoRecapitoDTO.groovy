package it.finmatica.tr4.dto;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoRecapito

public class TipoRecapitoDTO implements it.finmatica.dto.DTO<TipoRecapito> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id

	
    public TipoRecapito getDomainObject () {
        return TipoRecapito.get(this.id)
    }
    public TipoRecapito toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
	
	String toString() {
		"$id - $descrizione"
	}	
}
