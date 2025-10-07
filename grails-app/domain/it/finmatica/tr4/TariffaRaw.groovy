package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class TariffaRaw implements Serializable {
	int					tributo
	int					categoria
	Short 				anno
	Short tipoTariffa
	
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

	static mapping = {
		id 				composite: ["anno", "tributo", "categoria", "tipoTariffa"]
		
		anno			column: "anno", updateable: false
		categoria		column: "categoria", updateable: false
		tributo			column: "tributo", updateable: false
		categoria		column: "categoria", updateable: false

		flagNoDepag		type: SiNoType

		table 			"tariffe"
		
		version false
	}
	
	static constraints = {
		anno 					nullable: false
		tributo 				nullable: false
		categoria 				nullable: false
		tipoTariffa 			nullable: false
		
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
}
