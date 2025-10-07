package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipiModello

public class TipiModelloDTO implements DTO<TipiModello> {

    String descrizione
    String tipoModello
    String tipoPratica
    def modelli


    public TipiModello getDomainObject() {
        return TipiModello.get(this.tipoModello)
    }

    public TipiModello toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
