package it.finmatica.tr4.pratiche

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.tr4.CodiceDiritto
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.commons.TipoEsitoNota
import it.finmatica.tr4.commons.TipoRegime
import it.finmatica.tr4.datiesterni.DocumentoCaricato

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AttributoOgco implements Serializable {
	
	Contribuente	contribuente
	OggettoPratica	oggettoPratica
	OggettoContribuente oggettoContribuente
	DocumentoCaricato documentoId
	String numeroNota
	TipoEsitoNota esitoNota
	Date dataRegAtti
	String numeroRepertorio
	Integer codAtto
	String rogante
	String codFiscaleRogante
	String sedeRogante
	CodiceDiritto codDiritto
	TipoRegime regime
	String codEsito
	Ad4Utente		utente
	Date lastUpdated
	String note
	Date dataValiditaAtto
	Ad4Comune ad4Comune
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente?.codFiscale
		builder.append oggettoPratica.id
		builder.append lastUpdated
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente?.codFiscale, other.contribuente.codFiscale
		builder.append oggettoPratica.id, other.oggettoPratica.id
		builder.append lastUpdated, other.lastUpdated
		builder.isEquals()
	}

	static mapping = {
		id composite: ["contribuente", "oggettoPratica"]
		contribuente		column: "cod_fiscale"
		oggettoPratica		column: "oggetto_pratica"
		
		
		oggettoContribuente {
			column name: "cod_fiscale"
			column name: "oggetto_pratica"
		}
		oggettoContribuente	updateable: false, insertable: false
		
		lastUpdated				column: "data_variazione", sqlType: 'Date'
		dataValiditaAtto 		sqlType: 'Date'
		dataRegAtti      		sqlType: 'Date'
		utente					column: "utente"
		documentoId				column: "documento_id"
		codDiritto				column: "cod_diritto"
		ad4Comune				column: "id_comune"
		esitoNota			  	enumType: 'ordinal'
		table "attributi_ogco"
		version false
	}

	static constraints = {
		documentoId nullable: true
		numeroNota nullable: true, maxSize: 15
		esitoNota nullable: true
		dataRegAtti nullable: true
		numeroRepertorio nullable: true, maxSize: 15
		codAtto nullable: true
		rogante nullable: true, maxSize: 60
		codFiscaleRogante nullable: true, maxSize: 16
		sedeRogante nullable: true, maxSize: 4
		codDiritto nullable: true, maxSize: 4
		regime nullable: true, maxSize: 2
		codEsito nullable: true, maxSize: 4
		utente maxSize: 8
		note nullable: true, maxSize: 2000
		dataValiditaAtto nullable: true
	}
}
