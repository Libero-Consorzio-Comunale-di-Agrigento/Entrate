package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamInterrogazione

class SamInterrogazioneDTO implements DTO<SamInterrogazione> {
	private static final long serialVersionUID = 1L

	Long id
	String codFiscale
	String codFiscaleIniziale
	String identificativoEnte
	Long elaborazioneId
	Long attivitaId
	
	SamTipoDTO tipo
	
	SamInterrogazione getDomainObject() {
		return SamInterrogazione.get(this.id)
	}

	SamInterrogazione toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
