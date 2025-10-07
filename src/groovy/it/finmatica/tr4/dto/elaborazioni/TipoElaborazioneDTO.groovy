package it.finmatica.tr4.dto.elaborazioni

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.elaborazioni.TipoElaborazione

class TipoElaborazioneDTO implements DTO<TipoElaborazione> {

    String id
    String descrizione

    SortedSet<TipoAttivitaElaborazioniDTO> tipiAttivitaElaborazione

    @Override
    TipoElaborazione getDomainObject() {
        return TipoElaborazione.get(id)
    }

    TipoElaborazione toDomain(@SuppressWarnings("rawtypes") Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
