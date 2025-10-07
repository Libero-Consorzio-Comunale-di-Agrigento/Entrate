package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoContatto
import it.finmatica.tr4.TipoNotifica

public class TipoNotificaDTO implements DTO<TipoNotifica> {
    private static final long serialVersionUID = 1L;

    Long tipoNotifica
    String descrizione
    Boolean flagModificabile


    public TipoNotifica getDomainObject() {
        return TipoNotifica.get(this.tipoNotifica)
    }

    public TipoNotifica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
