package it.finmatica.tr4

class GruppoTributo implements Serializable {

	String gruppoTributo
	String descrizione
	
	TipoTributo tipoTributo;
	
	static mapping = {
		id composite: ["tipoTributo", "gruppoTributo"]
		
		tipoTributo column: "tipo_tributo"
		gruppoTributo column: "gruppo_tributo"
		
		table "gruppi_tributo"
		
		version false
	}

	static constraints = {
		tipoTributo nullable: false, maxSize: 5
		gruppoTributo nullable: false, maxSize: 10
		descrizione nullable: true, maxSize: 100
	}
}
