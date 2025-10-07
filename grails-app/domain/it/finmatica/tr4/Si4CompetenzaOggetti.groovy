package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Si4CompetenzaOggetti implements Serializable {

	Long idCompetenza
	Long idTipoOggetto
	String oggetto
	Ad4Utente	utente
	String accesso
	String nominativoUtente
	Long idTipoAbilitazione
	Date dal
	Date al

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append idCompetenza
		builder.append idTipoOggetto
		builder.append oggetto
		builder.append utente
		builder.append accesso
		builder.append nominativoUtente
		builder.append idTipoAbilitazione
		builder.append dal
		builder.append al
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append idCompetenza, other.idCompetenza
		builder.append idTipoOggetto, other.idTipoOggetto
		builder.append oggetto, other.oggetto
		builder.append utente, other.utente
		builder.append accesso, other.accesso
		builder.append nominativoUtente, other.nominativoUtente
		builder.append idTipoAbilitazione, other.idTipoAbilitazione
		builder.append dal, other.dal
		builder.append al, other.al
		builder.isEquals()
	}

	static mapping = {
		id composite: ["idCompetenza", "idTipoOggetto", "oggetto", "utente", "accesso", "nominativoUtente", "idTipoAbilitazione", "dal", "al"]
		utente	column: "utente"
		version false
		dal	sqlType:'Date', column:'dal'
		al	sqlType:'Date', column:'al'
		table "si4_competenza_oggetti"
	}

	static constraints = {
		idTipoOggetto nullable: true
		oggetto maxSize: 250
		utente maxSize: 8
		accesso maxSize: 1
		nominativoUtente maxSize: 40
		idTipoAbilitazione nullable: true
		dal nullable: true
		al nullable: true
	}
}
