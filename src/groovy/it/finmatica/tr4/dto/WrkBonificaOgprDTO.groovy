package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkBonificaOgpr;

import java.util.Map;

public class WrkBonificaOgprDTO implements it.finmatica.dto.DTO<WrkBonificaOgpr> {
    private static final long serialVersionUID = 1L;

    Long id;
    Long oggettoPraticaRif;


    public WrkBonificaOgpr getDomainObject () {
        return WrkBonificaOgpr.get(this.id)
    }
    public WrkBonificaOgpr toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
