package it.finmatica.tr4

class ScaglioneReddito {

	short anno
	BigDecimal redditoInf
	BigDecimal redditoSup
	
	static mapping = {
		id name: "anno", generator: "assigned"
		table "scaglioni_reddito"
		version false
	}
}
