package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiContFabbricati implements Serializable {

	String fiscale
	String dataSit
	String progMod
	String numOrd
	String istatCom
	String sezione
	String foglio
	String numero
	String subalterno
	String protocollo
	String annoDeAcc
	String fiscCont
	String flagcf
	String percPoss
	String abitPrin
	String progressivo
	String invio
	String impoDetrazAbPr
	String flagPossesso
	String recoModificato

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append fiscale
		builder.append dataSit
		builder.append progMod
		builder.append numOrd
		builder.append istatCom
		builder.append sezione
		builder.append foglio
		builder.append numero
		builder.append subalterno
		builder.append protocollo
		builder.append annoDeAcc
		builder.append fiscCont
		builder.append flagcf
		builder.append percPoss
		builder.append abitPrin
		builder.append progressivo
		builder.append invio
		builder.append impoDetrazAbPr
		builder.append flagPossesso
		builder.append recoModificato
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append fiscale, other.fiscale
		builder.append dataSit, other.dataSit
		builder.append progMod, other.progMod
		builder.append numOrd, other.numOrd
		builder.append istatCom, other.istatCom
		builder.append sezione, other.sezione
		builder.append foglio, other.foglio
		builder.append numero, other.numero
		builder.append subalterno, other.subalterno
		builder.append protocollo, other.protocollo
		builder.append annoDeAcc, other.annoDeAcc
		builder.append fiscCont, other.fiscCont
		builder.append flagcf, other.flagcf
		builder.append percPoss, other.percPoss
		builder.append abitPrin, other.abitPrin
		builder.append progressivo, other.progressivo
		builder.append invio, other.invio
		builder.append impoDetrazAbPr, other.impoDetrazAbPr
		builder.append flagPossesso, other.flagPossesso
		builder.append recoModificato, other.recoModificato
		builder.isEquals()
	}

	static mapping = {
		id composite: ["fiscale", "dataSit", "progMod", "numOrd", "istatCom", "sezione", "foglio", "numero", "subalterno", "protocollo", "annoDeAcc", "fiscCont", "flagcf", "percPoss", "abitPrin", "progressivo", "invio", "impoDetrazAbPr", "flagPossesso", "recoModificato"]
		version false
	}

	static constraints = {
		fiscale nullable: true, maxSize: 16
		dataSit nullable: true, maxSize: 10
		progMod nullable: true, maxSize: 5
		numOrd nullable: true, maxSize: 4
		istatCom nullable: true, maxSize: 6
		sezione nullable: true, maxSize: 3
		foglio nullable: true, maxSize: 5
		numero nullable: true, maxSize: 5
		subalterno nullable: true, maxSize: 4
		protocollo nullable: true, maxSize: 6
		annoDeAcc nullable: true, maxSize: 4
		fiscCont nullable: true, maxSize: 16
		flagcf nullable: true, maxSize: 1
		percPoss nullable: true, maxSize: 5
		abitPrin nullable: true, maxSize: 1
		progressivo nullable: true, maxSize: 7
		invio nullable: true, maxSize: 5
		impoDetrazAbPr nullable: true, maxSize: 8
		flagPossesso nullable: true, maxSize: 1
		recoModificato nullable: true, maxSize: 1
	}
}
