package it.finmatica.tr4

import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ContattoContribuente implements Serializable {

	Short 			sequenza
	TipoContatto 	tipoContatto
	TipoRichiedente tipoRichiedente
	
	Date data
	Integer numero
	Short anno
	
	String testo
	TipoTributo tipoTributo
	PraticaTributo	pratica
	
	static belongsTo = [contribuente: Contribuente]
	
	static mapping = {
		id 				composite: ["contribuente", "sequenza"]
		contribuente	column: "cod_fiscale"
		tipoContatto	column: "tipo_contatto"
		tipoRichiedente	column: "tipo_richiedente"
		tipoTributo		column: "tipo_tributo"
		pratica column: "pratica_k", ignoreNotFound: true
		
		data sqlType: 'Date'
		table 'contatti_contribuente'
		version false
	}

	static constraints = {
		contribuente	 maxSize: 16
		sequenza		nullable: true
		numero 			nullable: true
		anno 			nullable: true
		tipoContatto	nullable: true
		tipoRichiedente nullable: true
		testo 			nullable: true, maxSize: 2000
		tipoTributo 	nullable: true, maxSize: 5
		pratica 		nullable: true
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente, other.contribuente
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}
	
}
