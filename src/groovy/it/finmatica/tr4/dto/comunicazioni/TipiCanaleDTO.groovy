package it.finmatica.tr4.dto.comunicazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.comunicazioni.TipiCanale

public class TipiCanaleDTO implements DTO<TipiCanale> {
    private static final long serialVersionUID = 1L;

    static APPIO = 1L
    static EMAIL = 2L
    static PEC = 3L
    static PND = 4L

    String descrizione
    Long id

    public TipiCanale getDomainObject() {
        return TipiCanale.get(this.id)
    }

    public TipiCanale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as TipiCanale
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
