package it.finmatica.tr4.dto;

import it.finmatica.tr4.Edificio;

import java.util.Map;

public class EdificioDTO implements it.finmatica.dto.DTO<Edificio> {
    private static final long serialVersionUID = 1L;

    Long id;
    Long amministratore;
    String descrizione;
    String note;
    Short numUi;


    public Edificio getDomainObject () {
        return Edificio.get(this.id)
    }
    public Edificio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
