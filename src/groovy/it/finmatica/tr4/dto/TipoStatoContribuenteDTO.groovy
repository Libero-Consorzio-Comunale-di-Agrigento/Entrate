package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.TipoStatoContribuente

class TipoStatoContribuenteDTO implements DTO<TipoStatoContribuente> {
    Long id
    String descrizione
    String descrizioneBreve

    TipoStatoContribuente getDomainObject() {
        return TipoStatoContribuente.get(this.id)
    }

    TipoStatoContribuente toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as TipoStatoContribuente
    }

    @Override
    boolean equals(Object obj) {
        if (this.is(obj)) {
            return true
        }

        if (obj == null || getClass() != obj.getClass()) {
            return false
        }

        TipoStatoContribuenteDTO other = (TipoStatoContribuenteDTO) obj;
        return id != null &&
                id == other.id &&
                descrizione == other.descrizione
    }
}
