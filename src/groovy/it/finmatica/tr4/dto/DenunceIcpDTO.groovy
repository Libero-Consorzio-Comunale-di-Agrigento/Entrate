package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.DenunceIcp;

import java.util.Date;
import java.util.Map;

public class DenunceIcpDTO implements it.finmatica.dto.DTO<DenunceIcp> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date lastUpdated;
    String note;
    Long pratica;
    Ad4UtenteDTO	utente;


    public DenunceIcp getDomainObject () {
        return DenunceIcp.createCriteria().get {
            eq('pratica', this.pratica)
            eq('utente', this.utente)
            eq('lastUpdated', this.lastUpdated)
            eq('note', this.note)
        }
    }
    public DenunceIcp toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
