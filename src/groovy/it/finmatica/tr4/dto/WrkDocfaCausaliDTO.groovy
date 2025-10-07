package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkDocfaCausali

class WrkDocfaCausaliDTO implements it.finmatica.dto.DTO<WrkDocfaCausali> {

    String causale
    String descrizione

    public WrkDocfaCausali getDomainObject() {
        return WrkDocfaCausali.findByCausale(causale)
    }

    public WrkDocfaCausali toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
