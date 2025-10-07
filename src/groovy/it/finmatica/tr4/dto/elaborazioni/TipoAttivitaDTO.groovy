package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.elaborazioni.TipoAttivita

class TipoAttivitaDTO implements DTO<TipoAttivita>{

    Long id
    String descrizione

    Set<TipoAttivitaElaborazioniDTO> tipiAttivitaElaborazione

    @Override
    TipoAttivita getDomainObject() {
        return TipoAttivita.get(id)
    }

    TipoAttivita toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
