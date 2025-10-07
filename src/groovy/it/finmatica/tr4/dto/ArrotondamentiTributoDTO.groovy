package it.finmatica.tr4.dto;

import it.finmatica.tr4.ArrotondamentiTributo;
import it.finmatica.tr4.CodiceTributo;

public class ArrotondamentiTributoDTO implements it.finmatica.dto.DTO<ArrotondamentiTributo> {
	
	private static final long serialVersionUID = 1L;

	CodiceTributoDTO 	codiceTributo
	Integer 			sequenza
	
	Integer 			arrConsistenza
	Double				consistenzaMinima
	Integer 			arrConsistenzaReale
	Double				consistenzaMinimaReale

	public static final Integer ARR_MODALITA_PREDEFINITO = -1
	public static final Integer ARR_MODALITA_NESSUNO = 0
	public static final Integer ARR_MODALITA_INTERO_SUCCESSIVO = 1
	public static final Integer ARR_MODALITA_MEZZO_SUCCESSIVO = 2
	
	public ArrotondamentiTributo getDomainObject () {
		return ArrotondamentiTributo.createCriteria().get {
			eq('codiceTributo', this.codiceTributo.getDomainObject())
			eq('sequenza', this.sequenza)
		}
	}
	
	public ArrotondamentiTributo toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
}
