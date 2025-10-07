package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamFonteDomSede

class SamFonteDomSedeDTO implements DTO<SamFonteDomSede> {
	private static final long serialVersionUID = 1L

	String fonte
	String descrizione

	SamFonteDomSede getDomainObject() {
		return SamFonteDomSede.get(this.id)
	}

	SamFonteDomSede toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
