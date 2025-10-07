package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.tipi.SiNoType

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettoValidita implements Serializable {
	
	Contribuente 	contribuente
	OggettoPratica 	oggettoPratica
	Oggetto 		oggetto
	PraticaTributo 	pratica
	TipoStato		tipoStato
	OggettoPratica 	oggettoPraticaRif
	TipoTributo 	tipoTributo
	
	String 		numero
	Date 		data
	Short 		anno
	boolean		flagAbPrincipale
	boolean 	flagDenuncia
	Date		dal
	Date		al
	String		tipoPratica
	String		tipoEvento
	String		tipoOccupazione
	
	BigDecimal 	percPossesso
	Short 		mesiPossesso
	Short 		mesiEsclusione
	Short 		mesiRiduzione
	boolean 	flagPossesso
	boolean 	flagEsclusione
	boolean 	flagRiduzione
	BigDecimal 	valore
	boolean		flagProvvisorio
	TipoOggetto	tipoOggetto
	BigDecimal 		detrazione
	OggettoPratica 	oggettoPraticaRifAp
	

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente.codFiscale
		builder.append oggettoPratica.id
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.append oggettoPratica.id, other.oggettoPratica.id
		builder.isEquals()
	}

	static mapping = {
		id 	composite: ["contribuente", "oggettoPratica"]
		
		tipoTributo			column: "tipo_tributo"
		contribuente		column: "cod_fiscale"
		oggettoPraticaRif	column: "oggetto_pratica_rif"
		oggettoPraticaRifAp	column: "oggetto_pratica_rif_ap"
		contribuente		column: "cod_fiscale"
		oggettoPratica		column: "oggetto_pratica"
		tipoStato			column: "stato_accertamento"
		oggetto				column: "oggetto"
		pratica				column: "pratica"
		
		dal		sqlType: 'Date', column: 'dal'
		al		sqlType: 'Date', column: 'al'
		data	sqlType: 'Date', column: 'data'
		
		flagDenuncia		type: SiNoType
		flagAbPrincipale	type: SiNoType
		flagPossesso		type: SiNoType
		flagEsclusione		type: SiNoType
		flagRiduzione		type: SiNoType
		flagProvvisorio		type: SiNoType
		
		tipoOggetto			column: "tipo_oggetto"
		
		table "web_oggetti_validita"
		version false
		
	}

	static constraints = {
		contribuente maxSize: 16
		flagAbPrincipale nullable: true, maxSize: 1
		oggettoPraticaRif nullable: true
		dal nullable: true
		al nullable: true
		numero nullable: true, maxSize: 15
		data nullable: true
		tipoTributo maxSize: 5
		tipoPratica maxSize: 1
		tipoEvento maxSize: 1
		tipoOccupazione nullable: true, maxSize: 1
		tipoStato nullable: true, maxSize: 2
		flagDenuncia nullable: true, maxSize: 1
	}
}
