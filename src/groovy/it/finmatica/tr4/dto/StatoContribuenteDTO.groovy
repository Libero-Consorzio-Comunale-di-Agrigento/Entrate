package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.StatoContribuente

class StatoContribuenteDTO implements DTO<StatoContribuente> {
    Long id
    ContribuenteDTO contribuente
    TipoTributoDTO tipoTributo
    TipoStatoContribuenteDTO stato
    Date dataStato
    Short anno
    String utente
    Date lastUpdated
    String note

    StatoContribuente getDomainObject() {
        return StatoContribuente.get(this.id)
    }

    StatoContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as StatoContribuente
    }
}
