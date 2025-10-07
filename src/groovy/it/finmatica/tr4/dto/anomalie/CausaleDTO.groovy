package it.finmatica.tr4.dto.anomalie

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.anomalie.Causale
import it.finmatica.tr4.dto.TipoTributoDTO

class CausaleDTO implements it.finmatica.dto.DTO<Causale> {
    TipoTributoDTO tipoTributo;
    String causale
    String descrizione

    public Causale getDomainObject() {
        return Causale.findByCausaleAndTipoTributo(causale, tipoTributo.domainObject)
    }

    public Causale toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
