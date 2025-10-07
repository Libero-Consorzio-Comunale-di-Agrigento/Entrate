package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoUso;

import java.util.Map;

public class TipoUsoDTO implements it.finmatica.dto.DTO<TipoUso> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id;


    public TipoUso getDomainObject () {
        return TipoUso.get(this.id)
    }
    public TipoUso toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
