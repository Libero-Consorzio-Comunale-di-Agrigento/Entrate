package it.finmatica.tr4.anomalie

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.Oggetto

class Anomalia {

	Oggetto oggetto
	String flagOk
	Date dateCreated
	Date lastUpdated
	BigDecimal			renditaMedia
	BigDecimal			renditaMassima
	BigDecimal			valoreMedio
	BigDecimal			valoreMassimo
	Ad4Utente utente

	static belongsTo = [anomaliaParametro: AnomaliaParametro]

	SortedSet<AnomaliaPratica> 		anomaliePratiche
	static hasMany = [anomaliePratiche: AnomaliaPratica]

	static mapping = {
		id 				column: "id_anomalia"
		anomaliaParametro column: "id_anomalia_parametro"
		lastUpdated		column: "data_variazione", sqlType: 'Date'
		dateCreated		column: "data_creazione", sqlType: 'Date'
		oggetto 		column: "id_oggetto"
		flagOk			sqlType: "char", length: 1
		//flagOk			type: SiNoType
		utente column: "utente", ignoreNotFound: true

		table	'anomalie'
	}

	static constraints = {
		oggetto nullable: true
		flagOk nullable: true, maxSize: 1
		renditaMedia nullable : true
		renditaMassima nullable : true
        valoreMedio nullable: true
        valoreMassimo nullable: true
	}

	def springSecurityService
	static transients = ['springSecurityService']

	def beforeValidate () {
		utente	= utente?:springSecurityService.currentUser
		anomaliePratiche*.beforeValidate()
	}

	def beforeInsert () {
		utente	= utente?:springSecurityService.currentUser
		anomaliePratiche*.beforeValidate()
	}

	def beforeUpdate () {
		if (flagOk == "S") {
			anomaliePratiche*.flagOk = flagOk
		}
	}
}
