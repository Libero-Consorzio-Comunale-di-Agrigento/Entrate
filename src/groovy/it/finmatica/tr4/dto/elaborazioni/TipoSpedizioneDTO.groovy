package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.elaborazioni.TipoSpedizione

class TipoSpedizioneDTO implements DTO<TipoSpedizione> {
    String id
    String tipoSpedizione
    String descrizione

    @Override
    TipoSpedizione getDomainObject() {
        return TipoSpedizione.get(id)
    }

    TipoSpedizione toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    String descrizioneCompleta() {
        return "${tipoSpedizione} - ${descrizione}"
    }
}
