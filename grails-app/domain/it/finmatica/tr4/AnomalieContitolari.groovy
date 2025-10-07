package it.finmatica.tr4

class AnomalieContitolari {

	Short anno
	String codFiscale
	Long pratica
	String numOrdine
	String indirizzo
	String comune
	String siglaProvincia
	BigDecimal percPossesso
	Byte mesiPossesso
	BigDecimal detrazione
	Byte mesiAliquotaRidotta
	String flagPossesso
	String flagEsclusione
	String flagRiduzione
	String flagAbPrincipale
	String flagAlRidotta

	static mapping = {
		id column: "PROGRESSIVO", generator: "assigned"
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		numOrdine nullable: true, maxSize: 5
		indirizzo nullable: true, maxSize: 40
		comune nullable: true, maxSize: 60
		siglaProvincia nullable: true, maxSize: 2
		percPossesso nullable: true
		mesiPossesso nullable: true
		detrazione nullable: true
		mesiAliquotaRidotta nullable: true
		flagPossesso nullable: true, maxSize: 1
		flagEsclusione nullable: true, maxSize: 1
		flagRiduzione nullable: true, maxSize: 1
		flagAbPrincipale nullable: true, maxSize: 1
		flagAlRidotta nullable: true, maxSize: 1
	}
}
