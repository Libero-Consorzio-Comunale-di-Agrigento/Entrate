package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.SpesaNotifica

class SpesaNotificaDTO implements DTO<SpesaNotifica> {
    private static final long serialVersionUID = 1L;

    TipoTributoDTO tipoTributo
    Short sequenza
    String descrizione
    String descrizioneBreve
    BigDecimal importo
    TipoNotificaDTO tipoNotifica

    SpesaNotifica getDomainObject() {
        return SpesaNotifica.findByTipoTributoAndSequenza(tipoTributo.getDomainObject(), sequenza)
    }

    SpesaNotifica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as SpesaNotifica
    }


    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
