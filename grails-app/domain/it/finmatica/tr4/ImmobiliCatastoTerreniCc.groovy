package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ImmobiliCatastoTerreniCc implements Serializable {

	Integer idImmobile
	Integer idSoggetto
	String indirizzo
	String numCiv
	String partita
	String foglio
	String numero
	String subalterno
	String edificialita
	String qualita
	String classe
	String ettari
	String are
	String centiare
	String numeratore
	String denominatore
	String flagReddito
	String flagPorzione
	String flagDeduzioni
	String redditoDominicaleLire
	String redditoAgrarioLire
	String redditoDominicaleEuro
	String redditoAgrarioEuro
	Date dataEfficacia
	Date dataIscrizione
	Date dataEfficacia1
	Date dataIscrizione1
	String tipoNota
	String numeroNota
	String progressivoNota
	String annoNota
	
	String 	tipoNota1
	String 	numeroNota1
	String 	progressivoNota1
	String 	annoNota1
	String partitaTerreno
	String annotazione
	String foglioRic
	String numeroRic
	String subalternoRic
	String indirizzoRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append idImmobile
		builder.append idSoggetto
		builder.append indirizzo
		builder.append numCiv
		builder.append partita
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append edificialita
		builder.append qualita
		builder.append classe
		builder.append ettari
		builder.append are
		builder.append centiare
		builder.append numeratore
		builder.append denominatore
		builder.append flagReddito
		builder.append flagPorzione
		builder.append flagDeduzioni
		builder.append redditoDominicaleLire
		builder.append redditoAgrarioLire
		builder.append redditoDominicaleEuro
		builder.append redditoAgrarioEuro
		builder.append dataEfficacia
		builder.append dataIscrizione
		builder.append tipoNota
		builder.append numeroNota
		builder.append progressivoNota
		builder.append annoNota
		builder.append dataEfficacia1
		builder.append dataIscrizione1
		builder.append tipoNota1
		builder.append numeroNota1
		builder.append progressivoNota1
		builder.append annoNota1
		builder.append partitaTerreno
		builder.append annotazione
		builder.append foglioRic
		builder.append numeroRic
		builder.append subalternoRic
		builder.append indirizzoRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append idImmobile, other.idImmobile
		builder.append idSoggetto, other.idSoggetto
		builder.append indirizzo, other.indirizzo
		builder.append numCiv, other.numCiv
		builder.append partita, other.partita
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append edificialita, other.edificialita
		builder.append qualita, other.qualita
		builder.append classe, other.classe
		builder.append ettari, other.ettari
		builder.append are, other.are
		builder.append centiare, other.centiare
		builder.append numeratore, other.numeratore
		builder.append denominatore, other.denominatore
		builder.append flagReddito, other.flagReddito
		builder.append flagPorzione, other.flagPorzione
		builder.append flagDeduzioni, other.flagDeduzioni
		builder.append redditoDominicaleLire, other.redditoDominicaleLire
		builder.append redditoAgrarioLire, other.redditoAgrarioLire
		builder.append redditoDominicaleEuro, other.redditoDominicaleEuro
		builder.append redditoAgrarioEuro, other.redditoAgrarioEuro
		builder.append dataEfficacia, other.dataEfficacia
		builder.append dataIscrizione, other.dataIscrizione
		builder.append tipoNota, other.tipoNota
		builder.append numeroNota, other.numeroNota
		builder.append progressivoNota, other.progressivoNota
		builder.append annoNota, other.annoNota
		builder.append dataEfficacia1, other.dataEfficacia1
		builder.append dataIscrizione1, other.dataIscrizione1
		builder.append tipoNota1, other.tipoNota1
		builder.append numeroNota1, other.numeroNota1
		builder.append progressivoNota1, other.progressivoNota1
		builder.append annoNota1, other.annoNota1
		builder.append partitaTerreno, other.partitaTerreno
		builder.append annotazione, other.annotazione
		builder.append foglioRic, other.foglioRic
		builder.append numeroRic, other.numeroRic
		builder.append subalternoRic, other.subalternoRic
		builder.append indirizzoRic, other.indirizzoRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["idImmobile", "idSoggetto", "indirizzo", "numCiv", "partita", "foglio", "numero", "subalterno", "edificialita", "qualita", "classe", "ettari", "are", "centiare", "numeratore", "denominatore", "flagReddito", "flagPorzione", "flagDeduzioni", "redditoDominicaleLire", "redditoAgrarioLire", "redditoDominicaleEuro", "redditoAgrarioEuro", "dataEfficacia", "dataIscrizione", "tipoNota", "numeroNota", "progressivoNota", "annoNota", "dataEfficacia1", "dataIscrizione1", "tipoNota1", "numeroNota1", "progressivoNota1", "annoNota1", "partitaTerreno", "annotazione", "foglioRic", "numeroRic", "subalternoRic", "indirizzoRic"]
		version false
		dataEfficacia1			column: "DATA_EFFICACIA_1"
		dataIscrizione1			column: "DATA_ISCRIZIONE_1"
		tipoNota1				column: "TIPO_NOTA_1"
		numeroNota1             column: "NUMERO_NOTA_1"
		progressivoNota1        column: "PROGRESSIVO_NOTA_1"
		annoNota1               column: "ANNO_NOTA_1"
		dataEfficacia           sqlType: 'Date'
		dataIscrizione          sqlType: 'Date'
		dataEfficacia1          sqlType: 'Date'
		dataIscrizione1         sqlType: 'Date'
	}

	static constraints = {
		idImmobile nullable: true
		idSoggetto nullable: true
		indirizzo nullable: true, maxSize: 50
		numCiv nullable: true, maxSize: 20
		partita nullable: true, maxSize: 7
		foglio nullable: true, maxSize: 5
		numero nullable: true, maxSize: 4
		subalterno nullable: true, maxSize: 4
		edificialita nullable: true, maxSize: 1
		qualita nullable: true, maxSize: 3
		classe nullable: true, maxSize: 2
		ettari nullable: true, maxSize: 5
		are nullable: true, maxSize: 2
		centiare nullable: true, maxSize: 2
		numeratore nullable: true, maxSize: 40
		denominatore nullable: true, maxSize: 40
		flagReddito nullable: true, maxSize: 1
		flagPorzione nullable: true, maxSize: 1
		flagDeduzioni nullable: true, maxSize: 1
		redditoDominicaleLire nullable: true, maxSize: 12
		redditoAgrarioLire nullable: true, maxSize: 11
		redditoDominicaleEuro nullable: true, maxSize: 9
		redditoAgrarioEuro nullable: true, maxSize: 8
		dataEfficacia nullable: true
		dataIscrizione nullable: true
		tipoNota nullable: true, maxSize: 1
		numeroNota nullable: true, maxSize: 6
		progressivoNota nullable: true, maxSize: 3
		annoNota nullable: true, maxSize: 4
		dataEfficacia1 nullable: true
		dataIscrizione1 nullable: true
		tipoNota1 nullable: true, maxSize: 1
		numeroNota1 nullable: true, maxSize: 6
		progressivoNota1 nullable: true, maxSize: 3
		annoNota1 nullable: true, maxSize: 4
		partitaTerreno nullable: true, maxSize: 7
		annotazione nullable: true, maxSize: 200
		foglioRic nullable: true, maxSize: 4
		numeroRic nullable: true, maxSize: 5
		subalternoRic nullable: true, maxSize: 4
		indirizzoRic nullable: true, maxSize: 50
	}
}
