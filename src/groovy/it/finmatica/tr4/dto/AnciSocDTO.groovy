package it.finmatica.tr4.dto;

import it.finmatica.tr4.AnciSoc;

import java.util.Map;

public class AnciSocDTO implements it.finmatica.dto.DTO<AnciSoc> {
    private static final long serialVersionUID = 1L;

    Long id;
    Short annoFiscale;
    String comune;
    Short concessione;
    String ente;
    String filler;
    Long progrQuietanza;
    Integer progrRecord;
    String ragioneSociale;
    String tipoRecord;


    public AnciSoc getDomainObject () {
        return AnciSoc.createCriteria().get {
            eq('progrRecord', this.progrRecord)
            eq('annoFiscale', this.annoFiscale)
        }
    }
    public AnciSoc toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
