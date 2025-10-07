package it.finmatica.tr4.dto;

import it.finmatica.tr4.TipiCosto;

import java.util.Map;

public class TipiCostoDTO implements it.finmatica.dto.DTO<TipiCosto> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    String tipoCosto;


    public TipiCosto getDomainObject () {
        return TipiCosto.get(this.tipoCosto)
    }
    public TipiCosto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
