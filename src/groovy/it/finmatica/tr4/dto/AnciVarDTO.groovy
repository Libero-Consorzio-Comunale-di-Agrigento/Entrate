package it.finmatica.tr4.dto;

import it.finmatica.tr4.AnciVar;

import java.util.Map;

public class AnciVarDTO implements it.finmatica.dto.DTO<AnciVar> {
    private static final long serialVersionUID = 1L;

    Long id;
    String dati;
    String dati1;
    String dati2;
    String dati3;
    Integer numeroPacco;
    Integer progressivoRecord;
    String tipoRecord;


    public AnciVar getDomainObject () {
        return AnciVar.get(this.id)
    }
    public AnciVar toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
