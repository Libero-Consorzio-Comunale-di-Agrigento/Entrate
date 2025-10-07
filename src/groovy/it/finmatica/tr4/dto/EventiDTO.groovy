package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils;
import it.finmatica.tr4.Eventi;

import java.util.Date;
import java.util.Map;

public class EventiDTO implements it.finmatica.dto.DTO<Eventi> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date dataEvento;
    String descrizione;
    String note;
    Short sequenza;
    String tipoEvento;


    public Eventi getDomainObject () {
        return Eventi.createCriteria().get {
            eq('tipoEvento', this.tipoEvento)
            eq('sequenza', this.sequenza)
        }
    }
    public Eventi toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
