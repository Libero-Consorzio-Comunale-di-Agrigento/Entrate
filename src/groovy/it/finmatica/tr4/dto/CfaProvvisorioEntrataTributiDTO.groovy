package it.finmatica.tr4.dto;

import java.math.BigDecimal;
import java.util.Date;
import java.text.SimpleDateFormat

import it.finmatica.tr4.CfaProvvisorioEntrataTributi;

public class CfaProvvisorioEntrataTributiDTO implements it.finmatica.dto.DTO<CfaProvvisorioEntrataTributi> {
	
	private static final long serialVersionUID = 1L;

	Short		esercizio
	String		numeroProvvisorio
	Date		dataProvvisorio
	
	String		descrizione
	BigDecimal	importo
	String		desBen
	String		idFlussoTesoreria
	String		note

	public CfaProvvisorioEntrataTributi getDomainObject () {
		return CfaProvvisorioEntrataTributi.createCriteria().get {
			eq('esercizio', this.esercizio)
			eq('numeroProvvisorio', this.numeroProvvisorio)
			eq('dataProvvisorio', this.dataProvvisorio)
		}
	}
	
	public CfaProvvisorioEntrataTributi toDomain(Map overrides = [:]) {
		return DtoToEntityUtils.toEntity(this, overrides)
	}
	
	String getIdentificativo() {
		SimpleDateFormat dateFmt = new SimpleDateFormat("yyyyMMdd")
		return String.format( "%05d", (this.esercizio ?: 0) ) + this.numeroProvvisorio + ((dataProvvisorio) ? dateFmt.format(this.dataProvvisorio) : "-")
	}
}
