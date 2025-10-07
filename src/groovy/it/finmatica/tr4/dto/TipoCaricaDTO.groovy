package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoCarica;

import java.util.Map;

public class TipoCaricaDTO implements it.finmatica.dto.DTO<TipoCarica> {
    private static final long serialVersionUID = 1L;

    String descrizione
    String codSoggetto
    String flagOnline
    Long id


    public TipoCarica getDomainObject () {
        return TipoCarica.get(this.id)
    }
    public TipoCarica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
