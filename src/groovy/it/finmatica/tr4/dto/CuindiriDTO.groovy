package it.finmatica.tr4.dto;

import it.finmatica.tr4.Cuindiri;

import java.util.Map;

public class CuindiriDTO implements it.finmatica.dto.DTO<Cuindiri> {
    private static final long serialVersionUID = 1L;

    Long id;
    Integer chiave;
    String civico1;
    String civico2;
    String civico3;
    String codice;
    String edificio;
    String indirizzo;
    String interno;
    String lotto;
    String piano1;
    String piano2;
    String piano3;
    String scala;
    Short toponimo;


    public Cuindiri getDomainObject () {
        return Cuindiri.createCriteria().get {
            eq('codice', this.codice)
            eq('chiave', this.chiave)
            eq('toponimo', this.toponimo)
            eq('indirizzo', this.indirizzo)
            eq('lotto', this.lotto)
            eq('edificio', this.edificio)
            eq('scala', this.scala)
            eq('interno', this.interno)
            eq('civico1', this.civico1)
            eq('civico2', this.civico2)
            eq('civico3', this.civico3)
            eq('piano1', this.piano1)
            eq('piano2', this.piano2)
            eq('piano3', this.piano3)
        }
    }
    public Cuindiri toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
