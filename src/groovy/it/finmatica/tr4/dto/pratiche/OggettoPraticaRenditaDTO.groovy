package it.finmatica.tr4.dto.pratiche;

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.pratiche.OggettoPraticaRendita

public class OggettoPraticaRenditaDTO implements it.finmatica.dto.DTO<OggettoPraticaRendita> {
    private static final long serialVersionUID = 1L;

    Long id;
	BigDecimal rendita;
	
	public OggettoPraticaRendita getDomainObject () {
		return OggettoPraticaRendita.get(this.id)
	}
	public OggettoPraticaRendita toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
