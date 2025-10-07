package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.TipoEvento;

public class TipoEventoDTO implements it.finmatica.dto.DTO<TipoEvento> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    String tipoEvento;


    public TipoEvento getDomainObject () {
        return TipoEvento.get(this.tipoEvento)
    }
    public TipoEvento toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
