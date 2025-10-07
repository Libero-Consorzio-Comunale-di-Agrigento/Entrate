package it.finmatica.ad4.dto

import it.finmatica.ad4.Ad4Tr4Utente
import it.finmatica.dto.DtoToEntityUtils


class Ad4Tr4UtenteDTO implements it.finmatica.dto.DTO<Ad4Tr4Utente> {


    String id
    String nominativo
    /*String 		password
    boolean 	enabled
    boolean 	accountExpired
    boolean 	accountLocked
    boolean 	passwordExpired*/
    String tipoUtente
    Set dirittiAccesso



    /*String 		nominativoSoggetto
    boolean     esisteSoggetto*/
    // serve per discriminare gli utenti che corrispondono a soggetti chiusi da quelli che non corrispondono a soggetti di as4


    String getUtente() {
        return id
    }

    void setUtente(String utente) {
        id = utente
    }


    Ad4Tr4Utente getDomainObject() {
        return Ad4Tr4Utente.get(this.id)
    }


    Ad4Tr4Utente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
