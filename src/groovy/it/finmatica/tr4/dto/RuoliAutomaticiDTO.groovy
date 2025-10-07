package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.RuoliAutomatici

class RuoliAutomaticiDTO implements DTO<RuoliAutomatici> {

    Long id
    TipoTributoDTO tipoTributo
    Date daData
    Date aData
    RuoloDTO ruolo
    String utente
    String note


    RuoliAutomatici getDomainObject() {
        return RuoliAutomatici.get(id)
    }

    RuoliAutomatici toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
