package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Uteele implements Serializable {

	String utenza
	Integer ente
	String tipoUtente
	String nominativo
	String codFiscale
	String tipoVia
	String nomeVia
	String localita
	String cap
	String tipoUtenza
	String statoUtenza
	String codAttivita
	BigDecimal potenza
	String consumo
	String dataAllacciamento
	String dataContratto
	String codContratto
	String nominativoRecapito
	String indirizzoRecapito
	String localitaRecapito
	String capRecapito
	String semestre

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append utenza
		builder.append ente
		builder.append tipoUtente
		builder.append nominativo
		builder.append codFiscale
		builder.append tipoVia
		builder.append nomeVia
		builder.append localita
		builder.append cap
		builder.append tipoUtenza
		builder.append statoUtenza
		builder.append codAttivita
		builder.append potenza
		builder.append consumo
		builder.append dataAllacciamento
		builder.append dataContratto
		builder.append codContratto
		builder.append nominativoRecapito
		builder.append indirizzoRecapito
		builder.append localitaRecapito
		builder.append capRecapito
		builder.append semestre
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append utenza, other.utenza
		builder.append ente, other.ente
		builder.append tipoUtente, other.tipoUtente
		builder.append nominativo, other.nominativo
		builder.append codFiscale, other.codFiscale
		builder.append tipoVia, other.tipoVia
		builder.append nomeVia, other.nomeVia
		builder.append localita, other.localita
		builder.append cap, other.cap
		builder.append tipoUtenza, other.tipoUtenza
		builder.append statoUtenza, other.statoUtenza
		builder.append codAttivita, other.codAttivita
		builder.append potenza, other.potenza
		builder.append consumo, other.consumo
		builder.append dataAllacciamento, other.dataAllacciamento
		builder.append dataContratto, other.dataContratto
		builder.append codContratto, other.codContratto
		builder.append nominativoRecapito, other.nominativoRecapito
		builder.append indirizzoRecapito, other.indirizzoRecapito
		builder.append localitaRecapito, other.localitaRecapito
		builder.append capRecapito, other.capRecapito
		builder.append semestre, other.semestre
		builder.isEquals()
	}

	static mapping = {
		id composite: ["utenza", "ente", "tipoUtente", "nominativo", "codFiscale", "tipoVia", "nomeVia", "localita", "cap", "tipoUtenza", "statoUtenza", "codAttivita", "potenza", "consumo", "dataAllacciamento", "dataContratto", "codContratto", "nominativoRecapito", "indirizzoRecapito", "localitaRecapito", "capRecapito", "semestre"]
		version false
	}

	static constraints = {
		utenza nullable: true, maxSize: 16
		ente nullable: true
		tipoUtente nullable: true, maxSize: 1
		nominativo nullable: true, maxSize: 35
		codFiscale nullable: true, maxSize: 16
		tipoVia nullable: true, maxSize: 3
		nomeVia nullable: true, maxSize: 27
		localita nullable: true, maxSize: 18
		cap nullable: true, maxSize: 5
		tipoUtenza nullable: true, maxSize: 1
		statoUtenza nullable: true, maxSize: 1
		codAttivita nullable: true, maxSize: 3
		potenza nullable: true, scale: 1
		consumo nullable: true, maxSize: 9
		dataAllacciamento nullable: true, maxSize: 8
		dataContratto nullable: true, maxSize: 8
		codContratto nullable: true, maxSize: 1
		nominativoRecapito nullable: true, maxSize: 20
		indirizzoRecapito nullable: true, maxSize: 24
		localitaRecapito nullable: true, maxSize: 18
		capRecapito nullable: true, maxSize: 5
		semestre nullable: true, maxSize: 8
	}
}
