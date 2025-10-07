package it.finmatica.tr4.dto.pratiche;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.pratiche.DenunciaTarsu

public class DenunciaTarsuDTO implements it.finmatica.dto.DTO<DenunciaTarsu> {
    private static final long serialVersionUID = 1L;

    Long id;
    Date lastUpdated;
    String note;
    PraticaTributoDTO pratica;
    Ad4UtenteDTO	utente;


    public DenunciaTarsu getDomainObject () {
        return DenunciaTarsu.get(this.id)
    }
    public DenunciaTarsu toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
