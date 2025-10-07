package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class MotivoDetrazione implements Serializable {
	String id
	TipoTributo tipoTributo
	int motivoDetrazione
	String descrizione

	static mapping = {
		id 			column: "id_motivo_detrazione", generator: "assigned"
		tipoTributo	column: "tipo_tributo"
		
		table "web_motivi_detrazione"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		descrizione maxSize: 60
	}
}
