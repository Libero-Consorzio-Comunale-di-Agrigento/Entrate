package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.elaborazioni.TipoAttivitaElaborazioni

class TipoAttivitaElaborazioniDTO implements DTO<TipoAttivitaElaborazioni>, Comparable<TipoAttivitaElaborazioniDTO> {

    TipoAttivitaDTO tipoAttivita
    TipoElaborazioneDTO tipoElaborazione
    Integer numOrdine

    @Override
    TipoAttivitaElaborazioni getDomainObject() {
        return TipoAttivitaElaborazioni.findByTipoAttivitaAndTipoElaborazione(tipoAttivita.toDomain(), tipoElaborazione.toDomain())
    }

    TipoAttivitaElaborazioni toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    @Override
    int compareTo(TipoAttivitaElaborazioniDTO obj) {
        numOrdine <=> obj.numOrdine
    }
}
