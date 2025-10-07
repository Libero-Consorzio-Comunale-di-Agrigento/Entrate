package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.EventiContribuente;

import java.util.Date;
import java.util.Map;

public class EventiContribuenteDTO implements it.finmatica.dto.DTO<EventiContribuente> {
    private static final long serialVersionUID = 1L;

    Long id;
    String codFiscale;
    Date lastUpdated;
    String flagAutomatico;
    String note;
    Short sequenza;
    String tipoEvento;
    Ad4UtenteDTO	utente;


    public EventiContribuente getDomainObject () {
        return EventiContribuente.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('tipoEvento', this.tipoEvento)
            eq('sequenza', this.sequenza)
        }
    }
    public EventiContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
