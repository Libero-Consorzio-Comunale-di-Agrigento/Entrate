package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AliquotaCategoria implements Serializable {

	short anno
	TipoAliquota tipoAliquota
	CategoriaCatasto categoriaCatasto
	BigDecimal aliquota
	BigDecimal aliquotaBase
	String note
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append tipoAliquota
		builder.append categoriaCatasto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append tipoAliquota, other.tipoAliquota
		builder.append categoriaCatasto, other.categoriaCatasto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "tipoAliquota", "categoriaCatasto"]
		categoriaCatasto		column: "categoria_catasto"
		columns {
			tipoAliquota {
				column name: "tipo_tributo"
				column name: "tipo_aliquota"
			}
		}
		
		table "aliquote_categoria"
		version false
	}

	static constraints = {
		note nullable: true, maxSize: 2000
		aliquotaBase nullable: true
	}
}
