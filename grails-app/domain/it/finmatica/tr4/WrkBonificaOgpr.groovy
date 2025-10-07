package it.finmatica.tr4

class WrkBonificaOgpr {

	Long oggettoPraticaRif

	static mapping = {
		id column: "OGGETTO_PRATICA", generator: "assigned"
		version false
	}

	static constraints = {
		oggettoPraticaRif nullable: true
	}
}
