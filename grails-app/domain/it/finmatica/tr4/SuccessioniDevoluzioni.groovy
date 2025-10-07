package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SuccessioniDevoluzioni implements Serializable {

	Long successione
	Integer progressivo
	Short progrImmobile
	Short progrErede
	Integer numeratoreQuota
	Integer denominatoreQuota
	Boolean agevolazionePrimaCasa

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append successione
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append successione, other.successione
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["successione", "progressivo"]
		version false
	}

	static constraints = {
		numeratoreQuota nullable: true
		denominatoreQuota nullable: true
		agevolazionePrimaCasa nullable: true
	}
}
