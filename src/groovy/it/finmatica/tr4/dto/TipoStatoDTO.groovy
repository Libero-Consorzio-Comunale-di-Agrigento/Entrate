package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.pratiche.IterPratica

class TipoStatoDTO implements DTO<TipoStato> {
    private static final long serialVersionUID = 1L

    String descrizione
    String tipoStato
	Integer numOrdine
	
    Set<IterPratica> iter

    TipoStato getDomainObject () {
        return TipoStato.get(this.tipoStato)
    }

    TipoStato toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    String toString() {
        return "$tipoStato - $descrizione"
    }

}
