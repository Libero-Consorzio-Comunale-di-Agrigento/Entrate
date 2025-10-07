package it.finmatica.tr4.dto;

import it.finmatica.tr4.ScaglioneReddito;

import java.util.Map;

public class ScaglioneRedditoDTO implements it.finmatica.dto.DTO<ScaglioneReddito> {
    private static final long serialVersionUID = 1L;

    short anno;
    BigDecimal redditoInf;
    BigDecimal redditoSup;


    public ScaglioneReddito getDomainObject () {
        return ScaglioneReddito.get(this.anno)
    }
    public ScaglioneReddito toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
