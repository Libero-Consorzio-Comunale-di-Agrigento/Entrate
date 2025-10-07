package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiVersamenti implements Serializable {

	String concessione
	String fiscale
	String dataVersame
	String comuneImmob
	String istatCom
	String capImmobile
	String numFabbricati
	String annoFiscaleImm
	String flagAcconto
	String flagSaldo
	String impTerrAgr
	String areeFabbrica
	String abitPrincip
	String altriFabbric
	String impDetAbPr
	String totaleImp
	String progressivo
	String invio
	String exRurale
	String recoModificato

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append concessione
		builder.append fiscale
		builder.append dataVersame
		builder.append comuneImmob
		builder.append istatCom
		builder.append capImmobile
		builder.append numFabbricati
		builder.append annoFiscaleImm
		builder.append flagAcconto
		builder.append flagSaldo
		builder.append impTerrAgr
		builder.append areeFabbrica
		builder.append abitPrincip
		builder.append altriFabbric
		builder.append impDetAbPr
		builder.append totaleImp
		builder.append progressivo
		builder.append invio
		builder.append exRurale
		builder.append recoModificato
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append concessione, other.concessione
		builder.append fiscale, other.fiscale
		builder.append dataVersame, other.dataVersame
		builder.append comuneImmob, other.comuneImmob
		builder.append istatCom, other.istatCom
		builder.append capImmobile, other.capImmobile
		builder.append numFabbricati, other.numFabbricati
		builder.append annoFiscaleImm, other.annoFiscaleImm
		builder.append flagAcconto, other.flagAcconto
		builder.append flagSaldo, other.flagSaldo
		builder.append impTerrAgr, other.impTerrAgr
		builder.append areeFabbrica, other.areeFabbrica
		builder.append abitPrincip, other.abitPrincip
		builder.append altriFabbric, other.altriFabbric
		builder.append impDetAbPr, other.impDetAbPr
		builder.append totaleImp, other.totaleImp
		builder.append progressivo, other.progressivo
		builder.append invio, other.invio
		builder.append exRurale, other.exRurale
		builder.append recoModificato, other.recoModificato
		builder.isEquals()
	}

	static mapping = {
		id composite: ["concessione", "fiscale", "dataVersame", "comuneImmob", "istatCom", "capImmobile", "numFabbricati", "annoFiscaleImm", "flagAcconto", "flagSaldo", "impTerrAgr", "areeFabbrica", "abitPrincip", "altriFabbric", "impDetAbPr", "totaleImp", "progressivo", "invio", "exRurale", "recoModificato"]
		version false
	}

	static constraints = {
		concessione nullable: true, maxSize: 4
		fiscale nullable: true, maxSize: 16
		dataVersame nullable: true, maxSize: 10
		comuneImmob nullable: true, maxSize: 25
		istatCom nullable: true, maxSize: 6
		capImmobile nullable: true, maxSize: 5
		numFabbricati nullable: true, maxSize: 4
		annoFiscaleImm nullable: true, maxSize: 4
		flagAcconto nullable: true, maxSize: 1
		flagSaldo nullable: true, maxSize: 1
		impTerrAgr nullable: true, maxSize: 10
		areeFabbrica nullable: true, maxSize: 10
		abitPrincip nullable: true, maxSize: 10
		altriFabbric nullable: true, maxSize: 10
		impDetAbPr nullable: true, maxSize: 8
		totaleImp nullable: true, maxSize: 11
		progressivo nullable: true, maxSize: 7
		invio nullable: true, maxSize: 3
		exRurale nullable: true, maxSize: 1
		recoModificato nullable: true, maxSize: 1
	}
}
