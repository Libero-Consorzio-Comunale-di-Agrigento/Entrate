package it.finmatica.tr4

class BeneficiariTributo {

	String tributoF24
	String codFiscale
	String intestatario
	String iban
	String tassonomia
	String tassonomiaAnniPrec
	String causaleQuota
	String desMetadata

	static mapping = {
        id				name: "tributoF24", generator: "assigned"
		tributoF24		column: "tributo_f24"
		
		table "beneficiari_tributo"
		
		version false
	}

	static constraints = {
		id					maxSize: 4
		codFiscale			maxSize: 16
		intestatario		maxSize: 100
		iban				maxSize: 34
		tassonomia			maxSize: 20
		tassonomiaAnniPrec	nullable: true, maxSize: 20
		causaleQuota		maxSize: 100
		desMetadata			maxSize: 100
	}
}
