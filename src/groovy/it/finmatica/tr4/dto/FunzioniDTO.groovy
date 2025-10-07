package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.tr4.Funzioni

class FunzioniDTO implements DTO<Funzioni> {
    private static final long serialVersionUID = 1L

    String descrizione
    String funzione

    boolean flagVisibile

    Funzioni getDomainObject() {
        return Funzioni.get(this.funzione)
    }

    Funzioni toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.
}
