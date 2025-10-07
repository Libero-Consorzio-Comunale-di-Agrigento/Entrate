package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettiStorici implements Serializable {

	String codFiscale
	Short anno
	Long oggettoPratica
	Short tributo
	Short categoria
	Byte tipoTariffa
	Date dataDecorrenza
	Date dataCessazione
	BigDecimal valore
	BigDecimal consistenza
	Long oggetto
	Long pratica
	String tipoTributo
	String tipoPratica
	Date data

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append oggettoPratica
		builder.append tributo
		builder.append categoria
		builder.append tipoTariffa
		builder.append dataDecorrenza
		builder.append dataCessazione
		builder.append valore
		builder.append consistenza
		builder.append oggetto
		builder.append pratica
		builder.append tipoTributo
		builder.append tipoPratica
		builder.append data
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append oggettoPratica, other.oggettoPratica
		builder.append tributo, other.tributo
		builder.append categoria, other.categoria
		builder.append tipoTariffa, other.tipoTariffa
		builder.append dataDecorrenza, other.dataDecorrenza
		builder.append dataCessazione, other.dataCessazione
		builder.append valore, other.valore
		builder.append consistenza, other.consistenza
		builder.append oggetto, other.oggetto
		builder.append pratica, other.pratica
		builder.append tipoTributo, other.tipoTributo
		builder.append tipoPratica, other.tipoPratica
		builder.append data, other.data
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "oggettoPratica", "tributo", "categoria", "tipoTariffa", "dataDecorrenza", "dataCessazione", "valore", "consistenza", "oggetto", "pratica", "tipoTributo", "tipoPratica", "data"]
		version false
		dataDecorrenza	sqlType:'Date', column:'DATA_DECORRENZA'
		dataCessazione	sqlType:'Date', column:'DATA_CESSAZIONE'
		data			sqlType:'Date', column:'DATA'
	}

	static constraints = {
		codFiscale maxSize: 16
		tributo nullable: true
		categoria nullable: true
		tipoTariffa nullable: true
		dataDecorrenza nullable: true
		dataCessazione nullable: true
		valore nullable: true
		consistenza nullable: true
		tipoTributo maxSize: 5
		tipoPratica maxSize: 1
		data nullable: true
	}
}
