package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoRichiedente;

import java.util.Map;

public class TipoRichiedenteDTO implements it.finmatica.dto.DTO<TipoRichiedente> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Integer tipoRichiedente;


    public TipoRichiedente getDomainObject () {
        return TipoRichiedente.get(this.tipoRichiedente)
    }
    public TipoRichiedente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
