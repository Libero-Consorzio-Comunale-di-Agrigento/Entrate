package it.finmatica.tr4.dto;

import it.finmatica.tr4.TipiModelloParametri;

import java.util.Map;

public class TipiModelloParametriDTO implements it.finmatica.dto.DTO<TipiModelloParametri> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Short lunghezzaMax;
    String parametro;
    BigDecimal parametroId;
    String testoPredefinito;
    String tipoModello;


    public TipiModelloParametri getDomainObject () {
        return TipiModelloParametri.get(this.parametroId)
    }
    public TipiModelloParametri toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
