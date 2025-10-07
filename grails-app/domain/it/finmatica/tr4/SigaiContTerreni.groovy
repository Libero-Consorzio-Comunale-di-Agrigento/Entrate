package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiContTerreni implements Serializable {

	String istatCom
	String fiscale
	String dataSit
	String flagCf
	String progMod
	String numOrdine
	String partCatast
	String cfContitolare
	String perQPoss
	String progressivo
	String invio
	String recoModificato

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append istatCom
		builder.append fiscale
		builder.append dataSit
		builder.append flagCf
		builder.append progMod
		builder.append numOrdine
		builder.append partCatast
		builder.append cfContitolare
		builder.append perQPoss
		builder.append progressivo
		builder.append invio
		builder.append recoModificato
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append istatCom, other.istatCom
		builder.append fiscale, other.fiscale
		builder.append dataSit, other.dataSit
		builder.append flagCf, other.flagCf
		builder.append progMod, other.progMod
		builder.append numOrdine, other.numOrdine
		builder.append partCatast, other.partCatast
		builder.append cfContitolare, other.cfContitolare
		builder.append perQPoss, other.perQPoss
		builder.append progressivo, other.progressivo
		builder.append invio, other.invio
		builder.append recoModificato, other.recoModificato
		builder.isEquals()
	}

	static mapping = {
		id composite: ["istatCom", "fiscale", "dataSit", "flagCf", "progMod", "numOrdine", "partCatast", "cfContitolare", "perQPoss", "progressivo", "invio", "recoModificato"]
		version false
		perQPoss column: "per_q_poss"
	}

	static constraints = {
		istatCom nullable: true, maxSize: 6
		fiscale nullable: true, maxSize: 16
		dataSit nullable: true, maxSize: 10
		flagCf nullable: true, maxSize: 1
		progMod nullable: true, maxSize: 5
		numOrdine nullable: true, maxSize: 4
		partCatast nullable: true, maxSize: 8
		cfContitolare nullable: true, maxSize: 16
		perQPoss nullable: true, maxSize: 5
		progressivo nullable: true, maxSize: 7
		invio nullable: true, maxSize: 3
		recoModificato nullable: true, maxSize: 1
	}
}
