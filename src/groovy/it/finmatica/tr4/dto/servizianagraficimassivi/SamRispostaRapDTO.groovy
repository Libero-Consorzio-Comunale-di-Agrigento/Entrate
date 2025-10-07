package it.finmatica.tr4.dto.servizianagraficimassivi

import java.util.Date;

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.servizianagraficimassivi.SamRispostaRap

class SamRispostaRapDTO implements DTO<SamRispostaRap> {
	private static final long serialVersionUID = 1L

	Long id
	
	String codFiscaleRap
	Date dataDecorrenza
	Date dataFineCarica
	
	SamRispostaDTO risposta
	
	SamCodiceRitornoDTO codiceRitorno
	SamCodiceCaricaDTO codiceCarica

	SamRispostaRap getDomainObject() {
		return SamRispostaRap.get(this.id)
	}

	SamRispostaRap toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
