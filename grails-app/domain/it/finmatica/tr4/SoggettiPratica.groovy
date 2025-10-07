package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SoggettiPratica implements Serializable {

	String comuneEnte
	String siglaEnte
	String provinciaEnte
	String cognomeNome
	Long ni
	String codSesso
	String sesso
	Integer codContribuente
	Byte codControllo
	String codFiscale
	String presso
	String indirizzo
	String comune
	String telefono
	Date dataNascita
	String comuneNascita
	String rappresentante
	String codFiscaleRap
	String indirizzoRap
	String comuneRap
	Long pratica
	String tipoTributo
	String tipoPratica
	String tipoEvento
	Short anno
	String numero
	String tipoRapporto
	String dataPratica
	String dataNotifica
	String dataOdierna
	String cognomeNomeErede
	String codFiscaleErede
	String indirizzoErede
	String comuneErede
	String notePratica
	String motivoPratica
	Character datiDb1
	Character datiDb2

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append comuneEnte
		builder.append siglaEnte
		builder.append provinciaEnte
		builder.append cognomeNome
		builder.append ni
		builder.append codSesso
		builder.append sesso
		builder.append codContribuente
		builder.append codControllo
		builder.append codFiscale
		builder.append presso
		builder.append indirizzo
		builder.append comune
		builder.append telefono
		builder.append dataNascita
		builder.append comuneNascita
		builder.append rappresentante
		builder.append codFiscaleRap
		builder.append indirizzoRap
		builder.append comuneRap
		builder.append pratica
		builder.append tipoTributo
		builder.append tipoPratica
		builder.append tipoEvento
		builder.append anno
		builder.append numero
		builder.append tipoRapporto
		builder.append dataPratica
		builder.append dataNotifica
		builder.append dataOdierna
		builder.append cognomeNomeErede
		builder.append codFiscaleErede
		builder.append indirizzoErede
		builder.append comuneErede
		builder.append notePratica
		builder.append motivoPratica
		builder.append datiDb1
		builder.append datiDb2
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append comuneEnte, other.comuneEnte
		builder.append siglaEnte, other.siglaEnte
		builder.append provinciaEnte, other.provinciaEnte
		builder.append cognomeNome, other.cognomeNome
		builder.append ni, other.ni
		builder.append codSesso, other.codSesso
		builder.append sesso, other.sesso
		builder.append codContribuente, other.codContribuente
		builder.append codControllo, other.codControllo
		builder.append codFiscale, other.codFiscale
		builder.append presso, other.presso
		builder.append indirizzo, other.indirizzo
		builder.append comune, other.comune
		builder.append telefono, other.telefono
		builder.append dataNascita, other.dataNascita
		builder.append comuneNascita, other.comuneNascita
		builder.append rappresentante, other.rappresentante
		builder.append codFiscaleRap, other.codFiscaleRap
		builder.append indirizzoRap, other.indirizzoRap
		builder.append comuneRap, other.comuneRap
		builder.append pratica, other.pratica
		builder.append tipoTributo, other.tipoTributo
		builder.append tipoPratica, other.tipoPratica
		builder.append tipoEvento, other.tipoEvento
		builder.append anno, other.anno
		builder.append numero, other.numero
		builder.append tipoRapporto, other.tipoRapporto
		builder.append dataPratica, other.dataPratica
		builder.append dataNotifica, other.dataNotifica
		builder.append dataOdierna, other.dataOdierna
		builder.append cognomeNomeErede, other.cognomeNomeErede
		builder.append codFiscaleErede, other.codFiscaleErede
		builder.append indirizzoErede, other.indirizzoErede
		builder.append comuneErede, other.comuneErede
		builder.append notePratica, other.notePratica
		builder.append motivoPratica, other.motivoPratica
		builder.append datiDb1, other.datiDb1
		builder.append datiDb2, other.datiDb2
		builder.isEquals()
	}

	static mapping = {
		id composite: ["comuneEnte", "siglaEnte", "provinciaEnte", "cognomeNome", "ni", "codSesso", "sesso", "codContribuente", "codControllo", "codFiscale", "presso", "indirizzo", "comune", "telefono", "dataNascita", "comuneNascita", "rappresentante", "codFiscaleRap", "indirizzoRap", "comuneRap", "pratica", "tipoTributo", "tipoPratica", "tipoEvento", "anno", "numero", "tipoRapporto", "dataPratica", "dataNotifica", "dataOdierna", "cognomeNomeErede", "codFiscaleErede", "indirizzoErede", "comuneErede", "notePratica", "motivoPratica", "datiDb1", "datiDb2"]
		version false
		dataNascita	sqlType:'Date', column:'DATA_NASCITA'
	}

	static constraints = {
		comuneEnte nullable: true, maxSize: 40
		siglaEnte nullable: true, maxSize: 5
		provinciaEnte nullable: true, maxSize: 40
		cognomeNome nullable: true, maxSize: 100
		codSesso nullable: true, maxSize: 1
		sesso nullable: true, maxSize: 7
		codContribuente nullable: true
		codControllo nullable: true
		codFiscale maxSize: 16
		presso nullable: true, maxSize: 108
		indirizzo nullable: true, maxSize: 175
		comune nullable: true, maxSize: 94
		telefono nullable: true, maxSize: 47
		dataNascita nullable: true
		comuneNascita nullable: true, maxSize: 51
		rappresentante nullable: true, maxSize: 40
		codFiscaleRap nullable: true, maxSize: 16
		indirizzoRap nullable: true, maxSize: 50
		comuneRap nullable: true, maxSize: 51
		tipoTributo maxSize: 5
		tipoPratica maxSize: 1
		tipoEvento maxSize: 1
		numero nullable: true, maxSize: 15
		tipoRapporto nullable: true, maxSize: 1
		dataPratica nullable: true, maxSize: 10
		dataNotifica nullable: true, maxSize: 10
		dataOdierna nullable: true, maxSize: 10
		cognomeNomeErede nullable: true, maxSize: 100
		codFiscaleErede nullable: true, maxSize: 16
		indirizzoErede nullable: true, maxSize: 113
		comuneErede nullable: true, maxSize: 51
		notePratica nullable: true, maxSize: 2000
		motivoPratica nullable: true, maxSize: 2000
		datiDb1 nullable: true
		datiDb2 nullable: true
	}
}
