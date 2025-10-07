package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoContatto;

import java.util.Map;

public class TipoContattoDTO implements it.finmatica.dto.DTO<TipoContatto> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Integer tipoContatto;


    public TipoContatto getDomainObject () {
        return TipoContatto.get(this.tipoContatto)
    }
    public TipoContatto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
