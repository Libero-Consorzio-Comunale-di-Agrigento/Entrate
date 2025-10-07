package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cuarcuiu implements Serializable {

	String codice
	String partita
	String sezione
	String foglio
	String numero
	String subalterno
	String zona
	String categoria1
	Byte categoria2
	String classe
	BigDecimal consistenza
	Long rendita
	String descrizione
	Integer contatore
	String flag
	String dataEfficacia
	String dataIscrizione
	String categoriaRic
	String sezioneRic
	String foglioRic
	String numeroRic
	String subalternoRic
	String zonaRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append partita
		builder.append sezione
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append zona
		builder.append categoria1
		builder.append categoria2
		builder.append classe
		builder.append consistenza
		builder.append rendita
		builder.append descrizione
		builder.append contatore
		builder.append flag
		builder.append dataEfficacia
		builder.append dataIscrizione
		builder.append categoriaRic
		builder.append sezioneRic
		builder.append foglioRic
		builder.append numeroRic
		builder.append subalternoRic
		builder.append zonaRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append partita, other.partita
		builder.append sezione, other.sezione
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append zona, other.zona
		builder.append categoria1, other.categoria1
		builder.append categoria2, other.categoria2
		builder.append classe, other.classe
		builder.append consistenza, other.consistenza
		builder.append rendita, other.rendita
		builder.append descrizione, other.descrizione
		builder.append contatore, other.contatore
		builder.append flag, other.flag
		builder.append dataEfficacia, other.dataEfficacia
		builder.append dataIscrizione, other.dataIscrizione
		builder.append categoriaRic, other.categoriaRic
		builder.append sezioneRic, other.sezioneRic
		builder.append foglioRic, other.foglioRic
		builder.append numeroRic, other.numeroRic
		builder.append subalternoRic, other.subalternoRic
		builder.append zonaRic, other.zonaRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "partita", "sezione", "foglio", "numero", "subalterno", "zona", "categoria1", "categoria2", "classe", "consistenza", "rendita", "descrizione", "contatore", "flag", "dataEfficacia", "dataIscrizione", "categoriaRic", "sezioneRic", "foglioRic", "numeroRic", "subalternoRic", "zonaRic"]
		version false
	}

	static constraints = {
		codice nullable: true, maxSize: 5
		partita nullable: true, maxSize: 7
		sezione nullable: true, maxSize: 3
		foglio nullable: true, maxSize: 4
		numero nullable: true, maxSize: 11
		subalterno nullable: true, maxSize: 4
		zona nullable: true, maxSize: 3
		categoria1 nullable: true, maxSize: 1
		categoria2 nullable: true
		classe nullable: true, maxSize: 2
		consistenza nullable: true, scale: 1
		rendita nullable: true
		descrizione nullable: true, maxSize: 100
		contatore nullable: true
		flag nullable: true, maxSize: 1
		dataEfficacia nullable: true, maxSize: 10
		dataIscrizione nullable: true, maxSize: 10
		categoriaRic nullable: true, maxSize: 3
		sezioneRic nullable: true, maxSize: 3
		foglioRic nullable: true, maxSize: 4
		numeroRic nullable: true, maxSize: 11
		subalternoRic nullable: true, maxSize: 4
		zonaRic nullable: true, maxSize: 3
	}
}
