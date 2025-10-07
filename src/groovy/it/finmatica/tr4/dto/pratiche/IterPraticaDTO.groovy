package it.finmatica.tr4.dto.pratiche

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.dto.TipoAttoDTO
import it.finmatica.tr4.dto.TipoStatoDTO
import it.finmatica.tr4.pratiche.IterPratica

class IterPraticaDTO implements DTO<IterPratica> {

    Long id
    Date data
    String motivo
    String note
    PraticaTributoDTO pratica
    TipoStatoDTO stato
    TipoAttoDTO tipoAtto
    boolean flagAnnullamento

    String utente
    Date dataVariazione

    public IterPratica getDomainObject() {
        return IterPratica.get(this.id)
    }

    public IterPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
