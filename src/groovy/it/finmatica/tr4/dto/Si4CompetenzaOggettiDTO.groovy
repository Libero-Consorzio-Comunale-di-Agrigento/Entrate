package it.finmatica.tr4.dto;

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO;
import it.finmatica.tr4.Si4CompetenzaOggetti;

import java.util.Date;
import java.util.Map;

public class Si4CompetenzaOggettiDTO implements it.finmatica.dto.DTO<Si4CompetenzaOggetti> {
    private static final long serialVersionUID = 1L;

    Long id;
    String accesso;
    Date al;
    Date dal;
    Long idCompetenza;
    Long idTipoAbilitazione;
    Long idTipoOggetto;
    String nominativoUtente;
    String oggetto;
    Ad4UtenteDTO	utente;


    public Si4CompetenzaOggetti getDomainObject () {
        return Si4CompetenzaOggetti.createCriteria().get {
            eq('idCompetenza', this.idCompetenza)
            eq('idTipoOggetto', this.idTipoOggetto)
            eq('oggetto', this.oggetto)
            eq('utente', this.utente)
            eq('accesso', this.accesso)
            eq('nominativoUtente', this.nominativoUtente)
            eq('idTipoAbilitazione', this.idTipoAbilitazione)
            eq('dal', this.dal)
            eq('al', this.al)
        }
    }
    public Si4CompetenzaOggetti toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
