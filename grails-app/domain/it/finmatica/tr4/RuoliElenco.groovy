package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RuoliElenco implements Serializable {

	Boolean tipoRuolo
	Short annoRuolo
	Short annoEmissione
	Byte progrEmissione
	Date dataEmissione
	Short tributo
	BigDecimal importo
	BigDecimal imposta
	BigDecimal addMaggEca
	BigDecimal addPro
	BigDecimal iva
	BigDecimal maggiorazioneTares
	Date invioConsorzio
	Long ruolo
	String tipoTributo
	BigDecimal sgravio
	String rutrDesc
	Date scadenzaPrimaRata
	Boolean specieRuolo
	String importoLordo
	Long ruoloMaster
	String isRuoloMaster
	String tipoCalcolo
	String tipoEmissione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoRuolo
		builder.append annoRuolo
		builder.append annoEmissione
		builder.append progrEmissione
		builder.append dataEmissione
		builder.append tributo
		builder.append importo
		builder.append imposta
		builder.append addMaggEca
		builder.append addPro
		builder.append iva
		builder.append maggiorazioneTares
		builder.append invioConsorzio
		builder.append ruolo
		builder.append tipoTributo
		builder.append sgravio
		builder.append rutrDesc
		builder.append scadenzaPrimaRata
		builder.append specieRuolo
		builder.append importoLordo
		builder.append ruoloMaster
		builder.append isRuoloMaster
		builder.append tipoCalcolo
		builder.append tipoEmissione
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoRuolo, other.tipoRuolo
		builder.append annoRuolo, other.annoRuolo
		builder.append annoEmissione, other.annoEmissione
		builder.append progrEmissione, other.progrEmissione
		builder.append dataEmissione, other.dataEmissione
		builder.append tributo, other.tributo
		builder.append importo, other.importo
		builder.append imposta, other.imposta
		builder.append addMaggEca, other.addMaggEca
		builder.append addPro, other.addPro
		builder.append iva, other.iva
		builder.append maggiorazioneTares, other.maggiorazioneTares
		builder.append invioConsorzio, other.invioConsorzio
		builder.append ruolo, other.ruolo
		builder.append tipoTributo, other.tipoTributo
		builder.append sgravio, other.sgravio
		builder.append rutrDesc, other.rutrDesc
		builder.append scadenzaPrimaRata, other.scadenzaPrimaRata
		builder.append specieRuolo, other.specieRuolo
		builder.append importoLordo, other.importoLordo
		builder.append ruoloMaster, other.ruoloMaster
		builder.append isRuoloMaster, other.isRuoloMaster
		builder.append tipoCalcolo, other.tipoCalcolo
		builder.append tipoEmissione, other.tipoEmissione
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoRuolo", "annoRuolo", "annoEmissione", "progrEmissione", "dataEmissione", "tributo", "importo", "imposta", "addMaggEca", "addPro", "iva", "maggiorazioneTares", "invioConsorzio", "ruolo", "tipoTributo", "sgravio", "rutrDesc", "scadenzaPrimaRata", "specieRuolo", "importoLordo", "ruoloMaster", "isRuoloMaster", "tipoCalcolo", "tipoEmissione"]
		version false
		dataEmissione		sqlType:'Date', column:'DATA_EMISSIONE'
		invioConsorzio		sqlType:'Date', column:'INVIO_CONSORZIO'
		scadenzaPrimaRata	sqlType:'Date', column:'SCADENZA_PRIMA_RATA'
	}

	static constraints = {
		dataEmissione nullable: true
		tributo nullable: true
		importo nullable: true
		imposta nullable: true
		addMaggEca nullable: true
		addPro nullable: true
		iva nullable: true
		maggiorazioneTares nullable: true
		invioConsorzio nullable: true
		tipoTributo maxSize: 5
		sgravio nullable: true
		rutrDesc nullable: true, maxSize: 108
		scadenzaPrimaRata nullable: true
		specieRuolo nullable: true
		importoLordo nullable: true, maxSize: 1
		ruoloMaster nullable: true
		isRuoloMaster nullable: true, maxSize: 4000
		tipoCalcolo nullable: true, maxSize: 1
		tipoEmissione nullable: true, maxSize: 1
	}
}
