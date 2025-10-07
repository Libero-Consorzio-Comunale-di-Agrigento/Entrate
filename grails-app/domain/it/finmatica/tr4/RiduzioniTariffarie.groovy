package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RiduzioniTariffarie implements Serializable {

	String tipoTributo
	Short tributo
	String descTributo
	Short categoria
	String descCategoria
	Byte tipoTariffa
	String descTariffa
	Short anno
	BigDecimal tariffa
	BigDecimal tariffaBase
	String riduzione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append tributo
		builder.append descTributo
		builder.append categoria
		builder.append descCategoria
		builder.append tipoTariffa
		builder.append descTariffa
		builder.append anno
		builder.append tariffa
		builder.append tariffaBase
		builder.append riduzione
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append tributo, other.tributo
		builder.append descTributo, other.descTributo
		builder.append categoria, other.categoria
		builder.append descCategoria, other.descCategoria
		builder.append tipoTariffa, other.tipoTariffa
		builder.append descTariffa, other.descTariffa
		builder.append anno, other.anno
		builder.append tariffa, other.tariffa
		builder.append tariffaBase, other.tariffaBase
		builder.append riduzione, other.riduzione
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "tributo", "descTributo", "categoria", "descCategoria", "tipoTariffa", "descTariffa", "anno", "tariffa", "tariffaBase", "riduzione"]
		version false
	}

	static constraints = {
		tipoTributo nullable: true, maxSize: 5
		descTributo maxSize: 60
		descCategoria maxSize: 100
		descTariffa nullable: true, maxSize: 60
		tariffa scale: 5
		tariffaBase scale: 5
		riduzione nullable: true, maxSize: 40
	}
}
