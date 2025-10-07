package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoAtto

public class TipoAttoDTO implements DTO<TipoAtto> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long tipoAtto;


    public TipoAtto getDomainObject() {
        return TipoAtto.get(this.tipoAtto)
    }

    public TipoAtto toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
