package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.Contenitore

class ContenitoreDTO implements DTO<Contenitore> {

    Long id
    String descrizione
    String unitaDiMisura
    BigDecimal capienza

    Contenitore getDomainObject() {
        return Contenitore.get(id)
    }

    Contenitore toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as Contenitore
    }

}
