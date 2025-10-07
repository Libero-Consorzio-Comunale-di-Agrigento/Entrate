package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoContribuente;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AliquotaOgco implements Serializable {

	OggettoContribuente oggettoContribuente
	Date dal
	Date al
	TipoAliquota tipoAliquota
	String note
	
	static belongsTo = [oggettoContribuente: OggettoContribuente]
	
	static mapping = {
		id composite: ["oggettoContribuente", "dal"]
		
		columns {
			tipoAliquota {
				column name: "tipo_tributo"
				column name: "tipo_aliquota"
			}
			oggettoContribuente {
				column name: "cod_fiscale"
				column name: "oggetto_pratica"
			}
		}
		dal	sqlType: 'Date'
		al	sqlType: 'Date'
		
		table "aliquote_ogco"
		
		version false
	}

	static constraints = {
		//codFiscale maxSize: 16
		//tipoTributo maxSize: 5
		note nullable: true, maxSize: 2000
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggettoContribuente?.contribuente?.codFiscale
		builder.append oggettoContribuente?.oggettoPratica
		builder.append dal
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		if (!(other instanceof AliquotaOgco)) { 
			return false 
		}
		
		other.oggettoContribuente.contribuente.codFiscale == oggettoContribuente.contribuente.codFiscale &&
		other.oggettoContribuente.oggettoPratica == oggettoContribuente.oggettoPratica && 
		other.dal == dal
	}
}
