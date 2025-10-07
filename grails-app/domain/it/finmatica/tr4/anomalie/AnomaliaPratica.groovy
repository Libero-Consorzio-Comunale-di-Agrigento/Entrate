package it.finmatica.tr4.anomalie

import java.util.Date;

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.tipi.SiNoType

import org.apache.commons.lang.builder.EqualsBuilder

class AnomaliaPratica implements Comparable<AnomaliaPratica>  {

	OggettoContribuente oggettoContribuente
	String flagOk
	Date dateCreated
	Date lastUpdated
	Ad4Utente			utente
	AnomaliaPratica		anomaliaPraticaRif
	BigDecimal			rendita
	BigDecimal			valore
	//	boolean				hasRif

	static belongsTo = [anomalia: Anomalia]

	static mapping = {
		id 				column: "id_anomalia_pratica"
		lastUpdated		column: "data_variazione", sqlType: 'Date'
		dateCreated		column: "data_reg", sqlType: 'Date'
		utente			column: "utente"
		flagOk			sqlType: "char", length: 1
		anomalia			column: "id_anomalia"
		anomaliaPraticaRif	column: "anomalia_pratica_rif"
		columns {
			oggettoContribuente {
				column name: "cod_fiscale"
				column name: "oggetto_pratica"
			}
		}

		table 'anomalie_pratiche'
	}

	static constraints = {
		anomaliaPraticaRif	nullable: true
		rendita nullable : true
        valore nullable: true
	}

	// ritorna sempre 1 per evitare query inutili in fase di inserimento e cancellazione
	int compareTo(AnomaliaPratica obj) {
		1
	}

	def springSecurityService
	static transients = ['springSecurityService']

	def beforeValidate () {
		utente	= utente?:springSecurityService.currentUser
	}

	def beforeInsert () {
		utente	= utente?:springSecurityService.currentUser
	}
}
