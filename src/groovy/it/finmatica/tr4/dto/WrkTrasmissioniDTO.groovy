package it.finmatica.tr4.dto;

import it.finmatica.tr4.WrkTrasmissioni;

import java.util.Map;

public class WrkTrasmissioniDTO implements it.finmatica.dto.DTO<WrkTrasmissioni> {
    private static final long serialVersionUID = 1L;

    Long id;
    String dati;
    String numero;


    public WrkTrasmissioni getDomainObject () {
        return WrkTrasmissioni.createCriteria().get {
            eq('numero', this.numero)
            eq('dati', this.dati)
        }
    }
    public WrkTrasmissioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
