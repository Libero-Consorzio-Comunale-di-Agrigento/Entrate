package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamTipo

class SamTipoDTO implements DTO<SamTipo> {
	private static final long serialVersionUID = 1L

	String tipo
	String descrizione

	SamTipo getDomainObject() {
		return SamTipo.get(this.id)
	}

	SamTipo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
