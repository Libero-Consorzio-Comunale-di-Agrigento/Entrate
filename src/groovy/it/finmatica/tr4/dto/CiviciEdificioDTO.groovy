package it.finmatica.tr4.dto;

import it.finmatica.tr4.CiviciEdificio;

import java.util.Map;

public class CiviciEdificioDTO implements it.finmatica.dto.DTO<CiviciEdificio> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer codVia;
    Long edificio;
    Integer numCiv;
    Short sequenza;
    String suffisso;


    public CiviciEdificio getDomainObject () {
        return CiviciEdificio.createCriteria().get {
            eq('edificio', this.edificio)
            eq('sequenza', this.sequenza)
        }
    }
    public CiviciEdificio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
