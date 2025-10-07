package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ImmobiliCatastoUrbanoCc implements Serializable {

	Integer contatore
	Integer proprietario
	String indirizzo
	String numCiv
	String lotto
	String edificio
	String scala
	String interno
	String piano
	String numeratore
	String denominatore
	String codTitolo
	String desTitolo
	String tipoImmobile
	String partitaTitolarita
	String partita
	String sezione
	String foglio
	String numero
	String subalterno
	String zona
	String categoria
	String classe
	String consistenza
	String rendita
	String renditaEuro
	String descrizione
	Date dataEfficacia
	Date dataIscrizione
	String estremiCatasto
	String note
	String sezioneRic
	String foglioRic
	String numeroRic
	String subalternoRic
	String indirizzoRic
	String zonaRic
	String categoriaRic
	String partitaRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contatore
		builder.append proprietario
		builder.append indirizzo
		builder.append numCiv
		builder.append lotto
		builder.append edificio
		builder.append scala
		builder.append interno
		builder.append piano
		builder.append numeratore
		builder.append denominatore
		builder.append codTitolo
		builder.append desTitolo
		builder.append tipoImmobile
		builder.append partitaTitolarita
		builder.append partita
		builder.append sezione
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append zona
		builder.append categoria
		builder.append classe
		builder.append consistenza
		builder.append rendita
		builder.append renditaEuro
		builder.append descrizione
		builder.append dataEfficacia
		builder.append dataIscrizione
		builder.append estremiCatasto
		builder.append note
		builder.append sezioneRic
		builder.append foglioRic
		builder.append numeroRic
		builder.append subalternoRic
		builder.append indirizzoRic
		builder.append zonaRic
		builder.append categoriaRic
		builder.append partitaRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contatore, other.contatore
		builder.append proprietario, other.proprietario
		builder.append indirizzo, other.indirizzo
		builder.append numCiv, other.numCiv
		builder.append lotto, other.lotto
		builder.append edificio, other.edificio
		builder.append scala, other.scala
		builder.append interno, other.interno
		builder.append piano, other.piano
		builder.append numeratore, other.numeratore
		builder.append denominatore, other.denominatore
		builder.append codTitolo, other.codTitolo
		builder.append desTitolo, other.desTitolo
		builder.append tipoImmobile, other.tipoImmobile
		builder.append partitaTitolarita, other.partitaTitolarita
		builder.append partita, other.partita
		builder.append sezione, other.sezione
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append zona, other.zona
		builder.append categoria, other.categoria
		builder.append classe, other.classe
		builder.append consistenza, other.consistenza
		builder.append rendita, other.rendita
		builder.append renditaEuro, other.renditaEuro
		builder.append descrizione, other.descrizione
		builder.append dataEfficacia, other.dataEfficacia
		builder.append dataIscrizione, other.dataIscrizione
		builder.append estremiCatasto, other.estremiCatasto
		builder.append note, other.note
		builder.append sezioneRic, other.sezioneRic
		builder.append foglioRic, other.foglioRic
		builder.append numeroRic, other.numeroRic
		builder.append subalternoRic, other.subalternoRic
		builder.append indirizzoRic, other.indirizzoRic
		builder.append zonaRic, other.zonaRic
		builder.append categoriaRic, other.categoriaRic
		builder.append partitaRic, other.partitaRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["contatore", "proprietario", "indirizzo", "numCiv", "lotto", "edificio", "scala", "interno", "piano", "numeratore", "denominatore", "codTitolo", "desTitolo", "tipoImmobile", "partitaTitolarita", "partita", "sezione", "foglio", "numero", "subalterno", "zona", "categoria", "classe", "consistenza", "rendita", "renditaEuro", "descrizione", "dataEfficacia", "dataIscrizione", "estremiCatasto", "note", "sezioneRic", "foglioRic", "numeroRic", "subalternoRic", "indirizzoRic", "zonaRic", "categoriaRic", "partitaRic"]
		dataEfficacia           sqlType: 'Date'
		dataIscrizione          sqlType: 'Date'
		version false
	}

	static constraints = {
		contatore nullable: true
		proprietario nullable: true
		indirizzo nullable: true, maxSize: 50
		numCiv nullable: true, maxSize: 20
		lotto nullable: true, maxSize: 2
		edificio nullable: true, maxSize: 2
		scala nullable: true, maxSize: 2
		interno nullable: true, maxSize: 7
		piano nullable: true, maxSize: 19
		numeratore nullable: true, maxSize: 40
		denominatore nullable: true, maxSize: 40
		codTitolo nullable: true, maxSize: 3
		desTitolo nullable: true, maxSize: 200
		tipoImmobile nullable: true, maxSize: 1
		partitaTitolarita nullable: true, maxSize: 7
		partita nullable: true, maxSize: 7
		sezione nullable: true, maxSize: 3
		foglio nullable: true, maxSize: 4
		numero nullable: true, maxSize: 5
		subalterno nullable: true, maxSize: 4
		zona nullable: true, maxSize: 3
		categoria nullable: true, maxSize: 3
		classe nullable: true, maxSize: 3
		consistenza nullable: true, maxSize: 40
		rendita nullable: true, maxSize: 40
		renditaEuro nullable: true, maxSize: 40
		descrizione nullable: true
		dataEfficacia nullable: true
		dataIscrizione nullable: true
		estremiCatasto nullable: true, maxSize: 20
		note nullable: true, maxSize: 200
		sezioneRic nullable: true, maxSize: 3
		foglioRic nullable: true, maxSize: 4
		numeroRic nullable: true, maxSize: 5
		subalternoRic nullable: true, maxSize: 4
		indirizzoRic nullable: true, maxSize: 50
		zonaRic nullable: true, maxSize: 3
		categoriaRic nullable: true, maxSize: 3
		partitaRic nullable: true, maxSize: 7
	}
}
