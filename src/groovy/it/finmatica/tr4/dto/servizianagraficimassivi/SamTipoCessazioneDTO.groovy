package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamTipoCessazione

class SamTipoCessazioneDTO implements DTO<SamTipoCessazione> {
	private static final long serialVersionUID = 1L

	String tipoCessazione
	String descrizione

	SamTipoCessazione getDomainObject() {
		return SamTipoCessazione.get(this.id)
	}

	SamTipoCessazione toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
