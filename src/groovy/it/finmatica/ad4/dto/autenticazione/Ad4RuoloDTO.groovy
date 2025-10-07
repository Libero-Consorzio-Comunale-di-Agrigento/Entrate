package it.finmatica.ad4.dto.autenticazione;

import it.finmatica.ad4.autenticazione.Ad4Ruolo;
import it.finmatica.ad4.dto.dizionari.Ad4ModuloDTO;
import it.finmatica.ad4.dto.dizionari.Ad4ProgettoDTO;
import it.finmatica.dto.DtoToEntityUtils;

public class Ad4RuoloDTO implements it.finmatica.dto.DTO<Ad4Ruolo> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Ad4ModuloDTO modulo;
    Ad4ProgettoDTO progetto;
    String ruolo;
    boolean ruoloApplicativo;


    public Ad4Ruolo getDomainObject () {
        return Ad4Ruolo.get(this.ruolo)
    }
    public Ad4Ruolo toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
