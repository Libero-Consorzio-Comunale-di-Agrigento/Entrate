package it.finmatica.tr4.dto.servizianagraficimassivi

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaDitta

class SamRispostaDittaDTO implements DTO<SamRispostaDitta> {
	private static final long serialVersionUID = 1L

	Long id

	String codFiscaleDitta
	Date dataDecorrenza
	Date dataFineCarica

	SamRispostaDTO risposta
	
	SamCodiceRitornoDTO codiceRitorno
	SamCodiceCaricaDTO codiceCarica
	
	SamRispostaDitta getDomainObject() {
		return SamRispostaDitta.get(this.id)
	}

	SamRispostaDitta toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
