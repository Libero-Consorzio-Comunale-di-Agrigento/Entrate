package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class Tariffa {
	Short 				anno
	Short 				tipoTariffa
	String 				descrizione
	BigDecimal 			tariffa
	BigDecimal 			percRiduzione
	BigDecimal 			limite
	BigDecimal 			tariffaSuperiore
	BigDecimal 			limitePrec
	BigDecimal 			tariffaPrec
	BigDecimal 			tariffaSuperiorePrec

	BigDecimal 			tariffaQuotaFissa
	String				flagTariffaBase
	BigDecimal 			riduzioneQuotaFissa
	BigDecimal 			riduzioneQuotaVariabile
	
	Boolean				flagNoDepag

	static belongsTo = [categoria: Categoria]
	
	static mapping = {
		id 				column: "id_tariffa", generator: "assigned", updateable: false, insertable: false
		categoria		column: "id_categoria", updateable: false, insertable: false
		
		flagNoDepag		type: SiNoType

		table 			"web_tariffe"
		
		version false
	}
	
	static constraints = {
		descrizione 			nullable: true, maxSize: 60
		tariffa 				scale: 5
		percRiduzione 			nullable: true
		limite 					nullable: true, scale: 5
		tariffaSuperiore 		nullable: true, scale: 5
		limitePrec 				nullable: true, scale: 5
		tariffaPrec 			nullable: true, scale: 5
		tariffaSuperiorePrec	nullable: true, scale: 5
		tariffaQuotaFissa 		nullable: true, scale: 5
		flagTariffaBase			nullable: true, maxSize: 1
		riduzioneQuotaFissa		nullable: true, scale: 5
		riduzioneQuotaVariabile nullable: true, scale: 5
		flagNoDepag				nullable: true 
	}
	
	def springSecurityService
	static transients = ['springSecurityService']

	def beforeInsert() {
		this.descrizione = this.descrizione?.toUpperCase()
	}

	def beforeUpdate() {
		this.descrizione = this.descrizione?.toUpperCase()
	}
}
