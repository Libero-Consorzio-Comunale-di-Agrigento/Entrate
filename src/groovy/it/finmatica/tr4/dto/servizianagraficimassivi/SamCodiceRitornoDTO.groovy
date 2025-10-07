package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamCodiceRitorno

class SamCodiceRitornoDTO implements DTO<SamCodiceRitorno> {
	private static final long serialVersionUID = 1L

	String codRitorno
	String descrizione
	String riscontro
	String esito

	SamCodiceRitorno getDomainObject() {
		return SamCodiceRitorno.get(this.id)
	}

	SamCodiceRitorno toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
