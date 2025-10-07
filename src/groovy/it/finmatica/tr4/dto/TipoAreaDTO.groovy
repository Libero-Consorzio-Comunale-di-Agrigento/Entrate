package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoArea;

import java.util.Map;

public class TipoAreaDTO implements it.finmatica.dto.DTO<TipoArea> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id

    public TipoArea getDomainObject () {
        return TipoArea.get(this.id)
    }
    public TipoArea toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
