package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.elaborazioni.StatoAttivita

class StatoAttivitaDTO implements DTO<StatoAttivita> {

    Long id
    String descrizione
    TipoAttivitaDTO tipoAttivita

    @Override
    StatoAttivita getDomainObject() {
        return StatoAttivita.get(id)
    }

    StatoAttivita toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
