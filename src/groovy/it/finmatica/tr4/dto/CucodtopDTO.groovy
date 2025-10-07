package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cucodtop;

import java.util.Map;

public class CucodtopDTO implements it.finmatica.dto.DTO<Cucodtop> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short codice;
    String toponimo;


    public Cucodtop getDomainObject () {
        return Cucodtop.createCriteria().get {
            eq('codice', this.codice)
            eq('toponimo', this.toponimo)
        }
    }
    public Cucodtop toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
