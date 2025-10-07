package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoContribuente;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DetrazioneOgco implements Serializable {
	OggettoContribuente oggettoContribuente
	Integer motDetrazione
	TipoTributo				tipoTributo
	Short anno
	BigDecimal detrazione
	String note
	BigDecimal detrazioneAcconto
	MotivoDetrazione motivoDetrazione
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggettoContribuente?.contribuente?.codFiscale
		builder.append oggettoContribuente?.oggettoPratica
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		if (!(other instanceof DetrazioneOgco)) { 
			return false 
		}
		
		other.oggettoContribuente.contribuente.codFiscale == oggettoContribuente.contribuente.codFiscale &&
		other.oggettoContribuente.oggettoPratica == oggettoContribuente.oggettoPratica && 
		other.anno == anno
		
	}
	
	static belongsTo = [oggettoContribuente: OggettoContribuente]
	
	static mapping = {
		id composite: ["oggettoContribuente", "anno"]
		motivoDetrazione column: "id_motivo_detrazione", insertable: false, updateable: false
		tipoTributo		column: "tipo_tributo"
		columns {
			oggettoContribuente {
				column name: "cod_fiscale"
				column name: "oggetto_pratica"
			}
		}
		
		table "web_detrazioni_ogco"
		version false
	}

	static constraints = {
		//codFiscale maxSize: 16
		//tipoTributo nullable: true, maxSize: 5
		motDetrazione	nullable: true
		motivoDetrazione nullable: true
		detrazione nullable: true
		note nullable: true, maxSize: 2000
		detrazioneAcconto nullable: true
	}
	
	def beforeValidate () {
		this.motDetrazione = motivoDetrazione.motivoDetrazione
		this.tipoTributo = motivoDetrazione.tipoTributo
	}
	
	def beforeInsert () {
		this.motDetrazione = motivoDetrazione.motivoDetrazione
		this.tipoTributo = motivoDetrazione.tipoTributo
	}
	
}
