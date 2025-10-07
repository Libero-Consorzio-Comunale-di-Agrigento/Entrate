package it.finmatica.as4.dto;

import it.finmatica.as4.As4TipoSoggetto
import it.finmatica.dto.DtoToEntityUtils

public class As4TipoSoggettoDTO implements it.finmatica.dto.DTO<As4TipoSoggetto> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    String tipoSoggetto;


    public As4TipoSoggetto getDomainObject () {
        return As4TipoSoggetto.get(this.tipoSoggetto)
    }
    public As4TipoSoggetto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.



}
