package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettiIciap implements Serializable {

	String codFiscale
	Short anno
	Long oggettoPratica
	Long oggettoPraticaRif
	BigDecimal consistenza
	Byte settore
	Integer classeSup
	BigDecimal impostaBase
	BigDecimal impostaDovuta
	Long pratica
	String tipoPratica
	Date data
	Long oggetto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append oggettoPratica
		builder.append oggettoPraticaRif
		builder.append consistenza
		builder.append settore
		builder.append classeSup
		builder.append impostaBase
		builder.append impostaDovuta
		builder.append pratica
		builder.append tipoPratica
		builder.append data
		builder.append oggetto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append oggettoPratica, other.oggettoPratica
		builder.append oggettoPraticaRif, other.oggettoPraticaRif
		builder.append consistenza, other.consistenza
		builder.append settore, other.settore
		builder.append classeSup, other.classeSup
		builder.append impostaBase, other.impostaBase
		builder.append impostaDovuta, other.impostaDovuta
		builder.append pratica, other.pratica
		builder.append tipoPratica, other.tipoPratica
		builder.append data, other.data
		builder.append oggetto, other.oggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "oggettoPratica", "oggettoPraticaRif", "consistenza", "settore", "classeSup", "impostaBase", "impostaDovuta", "pratica", "tipoPratica", "data", "oggetto"]
		version false
		data	sqlType:'Date', column:'DATA'
	}

	static constraints = {
		codFiscale maxSize: 16
		oggettoPraticaRif nullable: true
		consistenza nullable: true
		settore nullable: true
		classeSup nullable: true
		impostaBase nullable: true
		impostaDovuta nullable: true
		tipoPratica maxSize: 1
		data nullable: true
	}
}
