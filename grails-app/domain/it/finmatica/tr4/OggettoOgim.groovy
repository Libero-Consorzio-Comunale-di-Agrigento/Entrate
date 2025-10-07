package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoPratica

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettoOgim implements Serializable {

	Contribuente	contribuente
	short anno
	OggettoPratica oggettoPratica
	Short sequenza
	TipoAliquota tipoAliquota
	BigDecimal aliquota
	BigDecimal aliquotaErariale
	Byte mesiPossesso
	Boolean mesiPossesso1sem
	BigDecimal aliquotaStd

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente.codFiscale
		builder.append anno
		builder.append oggettoPratica.id
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.append anno, other.anno
		builder.append oggettoPratica.id, other.oggettoPratica.id
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static belongsTo	= [oggettoPratica: OggettoPratica]	
	static mapping = {
		id composite: ["contribuente", "anno", "oggettoPratica", "sequenza"]
		version false
		mesiPossesso1sem	column: "MESI_POSSESSO_1SEM"
		contribuente		column: "cod_fiscale"
		oggettoPratica		column: "oggetto_pratica"
		columns {
			tipoAliquota {
				column	name: "tipo_tributo"
				column	name: "tipo_aliquota"				
			}
		}
		table	'oggetti_ogim'
	}

	static constraints = {
		tipoAliquota nullable: true
		aliquota nullable: true
		aliquotaErariale nullable: true
		mesiPossesso nullable: true
		mesiPossesso1sem nullable: true
		aliquotaStd nullable: true
	}
}
