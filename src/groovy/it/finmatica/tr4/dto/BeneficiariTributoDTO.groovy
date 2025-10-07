package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.BeneficiariTributo

public class BeneficiariTributoDTO implements DTO<BeneficiariTributo> {

	private static final long serialVersionUID = 1L
	
	String id

	String tributoF24
	String codFiscale
	String intestatario
	String iban
	String tassonomia
	String tassonomiaAnniPrec
	String causaleQuota
	String desMetadata

	public BeneficiariTributo getDomainObject () {
		return BeneficiariTributo.createCriteria().get {
			eq('tributoF24', this?.tributoF24)
		}
	}
	public BeneficiariTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
