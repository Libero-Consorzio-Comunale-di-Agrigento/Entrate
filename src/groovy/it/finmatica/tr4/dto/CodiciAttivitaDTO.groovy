package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.CodiciAttivita;

import java.util.Map;

public class CodiciAttivitaDTO implements it.finmatica.dto.DTO<CodiciAttivita> {
    private static final long serialVersionUID = 1L;

    String codAttivita;
    String descrizione;
    String flagReale;


    public CodiciAttivita getDomainObject () {
        return CodiciAttivita.get(this.codAttivita)
    }
    public CodiciAttivita toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
