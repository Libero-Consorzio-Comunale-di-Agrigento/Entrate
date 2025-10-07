package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ProprietariCatastoUrbanoCc implements Serializable {

	Integer idImmobile
	Integer idSoggetto
	String tipoSoggetto
	String cognomeNome
	String desComSede
	String siglaProSede
	String codTitolo
	String desDiritto
	String numeratore
	String denominatore
	String desTitolo
	Date dataValidita
	Date dataFineValidita
	Date dataNas
	String desComNas
	String siglaProNas
	String codFiscale
	String tipoImmobile
	String partita
	String cognomeNomeRic
	String codFiscaleRic
	Integer idSoggettoRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append idImmobile
		builder.append idSoggetto
		builder.append tipoSoggetto
		builder.append cognomeNome
		builder.append desComSede
		builder.append siglaProSede
		builder.append codTitolo
		builder.append desDiritto
		builder.append numeratore
		builder.append denominatore
		builder.append desTitolo
		builder.append dataValidita
		builder.append dataFineValidita
		builder.append dataNas
		builder.append desComNas
		builder.append siglaProNas
		builder.append codFiscale
		builder.append tipoImmobile
		builder.append partita
		builder.append cognomeNomeRic
		builder.append codFiscaleRic
		builder.append idSoggettoRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append idImmobile, other.idImmobile
		builder.append idSoggetto, other.idSoggetto
		builder.append tipoSoggetto, other.tipoSoggetto
		builder.append cognomeNome, other.cognomeNome
		builder.append desComSede, other.desComSede
		builder.append siglaProSede, other.siglaProSede
		builder.append codTitolo, other.codTitolo
		builder.append desDiritto, other.desDiritto
		builder.append numeratore, other.numeratore
		builder.append denominatore, other.denominatore
		builder.append desTitolo, other.desTitolo
		builder.append dataValidita, other.dataValidita
		builder.append dataFineValidita, other.dataFineValidita
		builder.append dataNas, other.dataNas
		builder.append desComNas, other.desComNas
		builder.append siglaProNas, other.siglaProNas
		builder.append codFiscale, other.codFiscale
		builder.append tipoImmobile, other.tipoImmobile
		builder.append partita, other.partita
		builder.append cognomeNomeRic, other.cognomeNomeRic
		builder.append codFiscaleRic, other.codFiscaleRic
		builder.append idSoggettoRic, other.idSoggettoRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["idImmobile", "idSoggetto", "tipoSoggetto", "cognomeNome", "desComSede", "siglaProSede", "codTitolo", "desDiritto", "numeratore", "denominatore", "desTitolo", "dataValidita", "dataFineValidita", "dataNas", "desComNas", "siglaProNas", "codFiscale", "tipoImmobile", "partita", "cognomeNomeRic", "codFiscaleRic", "idSoggettoRic"]
		version false
		dataValidita		sqlType:'Date', column:'DATA_VALIDITA'
		dataFineValidita	sqlType:'Date', column:'DATA_FINE_VALIDITA'
		dataNas				sqlType:'Date', column:'DATA_NAS'
	}

	static constraints = {
		idImmobile nullable: true
		idSoggetto nullable: true
		tipoSoggetto nullable: true, maxSize: 1
		cognomeNome nullable: true, maxSize: 150
		desComSede nullable: true, maxSize: 40
		siglaProSede nullable: true, maxSize: 2
		codTitolo nullable: true, maxSize: 3
		desDiritto nullable: true, maxSize: 100
		numeratore nullable: true, maxSize: 40
		denominatore nullable: true, maxSize: 40
		desTitolo nullable: true, maxSize: 200
		dataValidita nullable: true
		dataFineValidita nullable: true
		dataNas nullable: true
		desComNas nullable: true, maxSize: 40
		siglaProNas nullable: true, maxSize: 2
		codFiscale nullable: true, maxSize: 16
		tipoImmobile nullable: true, maxSize: 1
		partita nullable: true, maxSize: 7
		cognomeNomeRic nullable: true, maxSize: 150
		codFiscaleRic nullable: true, maxSize: 16
		idSoggettoRic nullable: true
	}
}
