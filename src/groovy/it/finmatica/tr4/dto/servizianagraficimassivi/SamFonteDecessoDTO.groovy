package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamFonteDecesso

class SamFonteDecessoDTO implements DTO<SamFonteDecesso> {
	private static final long serialVersionUID = 1L

	String fonteDecesso
	String descrizione

	SamFonteDecesso getDomainObject() {
		return SamFonteDecesso.get(this.id)
	}

	SamFonteDecesso toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
