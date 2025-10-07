package it.finmatica.ad4.dto.autenticazione

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils

class Ad4UtenteDTO implements DTO<Ad4Utente> {
    private static final long serialVersionUID = 1L

    String id
    boolean accountExpired
    boolean accountLocked
    boolean enabled
    boolean esisteSoggetto
    String nominativo
    String nominativoSoggetto
    String password
    boolean passwordExpired
    String tipoUtente


    Ad4Utente getDomainObject() {
        return Ad4Utente.get(this.id)
    }

    Ad4Utente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
