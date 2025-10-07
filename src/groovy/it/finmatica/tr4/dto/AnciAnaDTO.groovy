package it.finmatica.tr4.dto;

import it.finmatica.tr4.AnciAna;

import java.util.Map;

public class AnciAnaDTO implements it.finmatica.dto.DTO<AnciAna> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short annoFiscale;
    String cognome;
    String comune;
    Short concessione;
    String ente;
    String filler;
    String nome;
    Long progrQuietanza;
    Integer progrRecord;
    String tipoRecord;


    public AnciAna getDomainObject () {
        return AnciAna.createCriteria().get {
            eq('progrRecord', this.progrRecord)
            eq('annoFiscale', this.annoFiscale)
        }
    }
    public AnciAna toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
