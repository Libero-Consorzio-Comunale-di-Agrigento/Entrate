package it.finmatica.tr4.dto;

import it.finmatica.tr4.Parametri;

import java.util.Date;
import java.util.Map;

public class ParametriDTO implements it.finmatica.dto.DTO<Parametri> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date data;
    String nomeParametro;
    BigDecimal progressivo;
    BigDecimal sessione;
    String valore;


    public Parametri getDomainObject () {
        return Parametri.createCriteria().get {
            eq('sessione', this.sessione)
            eq('nomeParametro', this.nomeParametro)
            eq('progressivo', this.progressivo)
        }
    }
    public Parametri toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
