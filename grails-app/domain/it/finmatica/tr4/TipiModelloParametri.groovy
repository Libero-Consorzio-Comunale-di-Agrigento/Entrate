package it.finmatica.tr4

class TipiModelloParametri {

	BigDecimal parametroId
	String tipoModello
	String parametro
	String descrizione
	Short lunghezzaMax
	String testoPredefinito

	static mapping = {
		id name: "parametroId", generator: "assigned"
		version false
	}

	static constraints = {
		tipoModello maxSize: 10
		parametro maxSize: 30, unique: ["tipoModello"]
		descrizione nullable: true, maxSize: 100
		testoPredefinito maxSize: 2000
	}
}
