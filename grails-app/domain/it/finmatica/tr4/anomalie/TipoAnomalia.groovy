package it.finmatica.tr4.anomalie

import it.finmatica.tr4.commons.TipoIntervento;

class TipoAnomalia {

	short tipoAnomalia
	String descrizione
	String dettagliIndipendenti
	String tipoBonifica
	TipoIntervento tipoIntervento
	String nomeMetodo
	String zul
	
	static mapping = {
		id name : "tipoAnomalia", generator: "assigned"
		dettagliIndipendenti		sqlType: "char", length: 1
		version false
		sort "tipoAnomalia"
		table 'tipi_anomalia'
	}

	static constraints = {
		descrizione maxSize: 60
		tipoBonifica nullable: true, maxSize: 1
		tipoIntervento nullable: true
	}
}
