package it.finmatica.tr4.dto;

import it.finmatica.tr4.ParametriImport;

import java.sql.Clob;
import java.util.Map;

public class ParametriImportDTO implements it.finmatica.dto.DTO<ParametriImport> {
    private static final long serialVersionUID = 1L;

    String nome;
    Clob parametro;


    public ParametriImport getDomainObject () {
        return ParametriImport.get(this.nome)
    }
    public ParametriImport toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
