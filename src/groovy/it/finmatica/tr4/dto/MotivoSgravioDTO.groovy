package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.MotivoSgravio

public class MotivoSgravioDTO implements DTO<MotivoSgravio> {
    private static final long serialVersionUID = 1L;

    String descrizione;
    Long id

    public MotivoSgravio getDomainObject() {
        return MotivoSgravio.get(this.id)
    }

    public MotivoSgravio toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as MotivoSgravio
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
