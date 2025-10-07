package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamCodiceCarica

class SamCodiceCaricaDTO implements DTO<SamCodiceCarica> {
    private static final long serialVersionUID = 1L

	String codCarica
	String descrizione

    SamCodiceCarica getDomainObject() {
        return SamCodiceCarica.get(this.id)
    }

    SamCodiceCarica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
