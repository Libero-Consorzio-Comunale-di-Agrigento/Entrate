package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RiferimentoOggetto implements Serializable, Comparable<RiferimentoOggetto> {

	Date inizioValidita
	Date fineValidita
	Short daAnno
	Short aAnno
	BigDecimal rendita
	Short annoRendita
	CategoriaCatasto categoriaCatasto
	String classeCatasto
	Date dataReg
	Date dataRegAtti
	Ad4Utente	utente
	Date lastUpdated
	String note
	
	static belongsTo = [oggetto: Oggetto]
	
	static mapping = {
		id composite: ["oggetto", "inizioValidita"]
		oggetto column: "oggetto"
		categoriaCatasto column: "categoria_catasto"
		utente column: "utente", ignoreNotFound: true
		inizioValidita	sqlType:'Date', column:'inizio_validita'
		fineValidita	sqlType:'Date', column:'fine_validita'
		dataReg			sqlType:'Date', column:'data_reg'
		dataRegAtti		sqlType:'Date', column:'data_reg_atti'
		lastUpdated	sqlType:'Date', column:'data_variazione'
		
		table "riferimenti_oggetto"
		version false
	}

	static constraints = {
		annoRendita nullable: true
		categoriaCatasto nullable: true, maxSize: 3
		classeCatasto nullable: true, maxSize: 2
		dataReg nullable: true
		dataRegAtti nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggetto?.id
		builder.append inizioValidita
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggetto?.id, other.oggetto?.id
		builder.append inizioValidita, other.inizioValidita
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
	public int compareTo(RiferimentoOggetto ro) {
		oggetto?.id		<=> ro?.oggetto?.id?:
		inizioValidita	<=> ro.inizioValidita
	}
}
