package it.finmatica.tr4

class TipoAtto implements Comparable {

	Long tipoAtto
	String descrizione

	static mapping = {
		id name: "tipoAtto", generator: "assigned"
		table 'tipi_atto'
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 60
	}

	@Override
	int compareTo(Object o) {
		return 0
	}
}
