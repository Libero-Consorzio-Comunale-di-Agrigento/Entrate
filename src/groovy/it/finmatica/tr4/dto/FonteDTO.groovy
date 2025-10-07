package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.Fonte;

import java.util.Map;

public class FonteDTO implements it.finmatica.dto.DTO<Fonte> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    long fonte;


    public Fonte getDomainObject () {
        return Fonte.get(this.fonte)
    }
    public Fonte toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
