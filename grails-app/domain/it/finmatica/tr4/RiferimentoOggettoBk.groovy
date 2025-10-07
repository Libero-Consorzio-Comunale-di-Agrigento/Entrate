package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RiferimentoOggettoBk implements Serializable, Comparable<RiferimentoOggettoBk> {

	Date inizioValidita
	Short sequenza
	Date fineValidita
	Short daAnno
	Short aAnno
	BigDecimal rendita
	Short annoRendita
	CategoriaCatasto categoriaCatasto
	String classeCatasto
	Date dataReg
	Date dataRegAtti
	Ad4Utente utenteRiog
	Date dataVariazioneRiog
	String note
	Ad4Utente utente
	Date dataOraVariazione
	
	static belongsTo = [oggetto: Oggetto]
	
	static mapping = {
		id 					composite: ["oggetto", "inizioValidita", "sequenza"]
		oggetto 			column: "oggetto"
		categoriaCatasto 	column: "categoria_catasto"
		utente      		column: "utente", ignoreNotFound: true
		utenteRiog     		column: "utente_riog", ignoreNotFound: true
		inizioValidita		sqlType:'Date', column:'inizio_validita'
		fineValidita		sqlType:'Date', column:'fine_validita'
		dataReg				sqlType:'Date', column:'data_reg'
		dataRegAtti			sqlType:'Date', column:'data_reg_atti'
		dataVariazioneRiog  sqlType:'Date', column:'data_variazione_riog'
		dataOraVariazione  	sqlType:'Date', column:'data_ora_variazione'
		note 				column: "note_riog"
		
		table "riferimenti_oggetto_bk"
		version false
	}

	static constraints = {
		annoRendita nullable: true
		categoriaCatasto nullable: true, maxSize: 3
		classeCatasto nullable: true, maxSize: 2
		dataReg nullable: true
		dataRegAtti nullable: true
		utenteRiog nullable: true, maxSize: 8
		dataVariazioneRiog nullable: true
		note nullable: true, maxSize: 2000
		utente nullable: true, maxSize: 8
		dataOraVariazione nullable: true
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggetto?.id
		builder.append inizioValidita
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggetto?.id, other.oggetto?.id
		builder.append inizioValidita, other.inizioValidita
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente	= springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente	= springSecurityService.currentUser
	}

	@Override
	public int compareTo(RiferimentoOggettoBk ro) {
		oggetto?.id		<=> ro?.oggetto?.id?:
		inizioValidita	<=> ro.inizioValidita
		sequenza		<=> ro.sequenza
	}
}
