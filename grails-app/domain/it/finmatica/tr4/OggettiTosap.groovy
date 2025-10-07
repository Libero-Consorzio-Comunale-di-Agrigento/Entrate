package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettiTosap implements Serializable {

	String codFiscale
	Short anno
	Long oggettoPratica
	Long oggettoPraticaRif
	Date dataDecorrenza
	Date dataCessazione
	Short tributo
	Short categoria
	Byte tipoTariffa
	BigDecimal consistenza
	Integer numConcessione
	Date dataConcessione
	Date inizioConcessione
	Date fineConcessione
	BigDecimal larghezza
	BigDecimal profondita
	Short codProOcc
	Short codComOcc
	String indirizzoOcc
	BigDecimal daChilometro
	BigDecimal aChilometro
	String lato
	Long pratica
	String tipoPratica
	Date data
	Long oggetto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append oggettoPratica
		builder.append oggettoPraticaRif
		builder.append dataDecorrenza
		builder.append dataCessazione
		builder.append tributo
		builder.append categoria
		builder.append tipoTariffa
		builder.append consistenza
		builder.append numConcessione
		builder.append dataConcessione
		builder.append inizioConcessione
		builder.append fineConcessione
		builder.append larghezza
		builder.append profondita
		builder.append codProOcc
		builder.append codComOcc
		builder.append indirizzoOcc
		builder.append daChilometro
		builder.append aChilometro
		builder.append lato
		builder.append pratica
		builder.append tipoPratica
		builder.append data
		builder.append oggetto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append oggettoPratica, other.oggettoPratica
		builder.append oggettoPraticaRif, other.oggettoPraticaRif
		builder.append dataDecorrenza, other.dataDecorrenza
		builder.append dataCessazione, other.dataCessazione
		builder.append tributo, other.tributo
		builder.append categoria, other.categoria
		builder.append tipoTariffa, other.tipoTariffa
		builder.append consistenza, other.consistenza
		builder.append numConcessione, other.numConcessione
		builder.append dataConcessione, other.dataConcessione
		builder.append inizioConcessione, other.inizioConcessione
		builder.append fineConcessione, other.fineConcessione
		builder.append larghezza, other.larghezza
		builder.append profondita, other.profondita
		builder.append codProOcc, other.codProOcc
		builder.append codComOcc, other.codComOcc
		builder.append indirizzoOcc, other.indirizzoOcc
		builder.append daChilometro, other.daChilometro
		builder.append aChilometro, other.aChilometro
		builder.append lato, other.lato
		builder.append pratica, other.pratica
		builder.append tipoPratica, other.tipoPratica
		builder.append data, other.data
		builder.append oggetto, other.oggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "oggettoPratica", "oggettoPraticaRif", "dataDecorrenza", "dataCessazione", "tributo", "categoria", "tipoTariffa", "consistenza", "numConcessione", "dataConcessione", "inizioConcessione", "fineConcessione", "larghezza", "profondita", "codProOcc", "codComOcc", "indirizzoOcc", "daChilometro", "aChilometro", "lato", "pratica", "tipoPratica", "data", "oggetto"]
		version false
		dataConcessione		sqlType:'Date', column:'DATA_CONCESSIONE'
		inizioConcessione	sqlType:'Date', column:'INIZIO_CONCESSIONE'
		fineConcessione		sqlType:'Date', column:'FINE_CONCESSIONE'
		dataDecorrenza		sqlType:'Date', column:'DATA_DECORRENZA'
		dataCessazione		sqlType:'Date', column:'DATA_CESSAZIONE'
		data				sqlType:'Date', column:'DATA'
	}

	static constraints = {
		codFiscale maxSize: 16
		oggettoPraticaRif nullable: true
		dataDecorrenza nullable: true
		dataCessazione nullable: true
		tributo nullable: true
		categoria nullable: true
		tipoTariffa nullable: true
		consistenza nullable: true
		numConcessione nullable: true
		dataConcessione nullable: true
		inizioConcessione nullable: true
		fineConcessione nullable: true
		larghezza nullable: true
		profondita nullable: true
		codProOcc nullable: true
		codComOcc nullable: true
		indirizzoOcc nullable: true, maxSize: 50
		daChilometro nullable: true, scale: 4
		aChilometro nullable: true, scale: 4
		lato nullable: true, maxSize: 1
		tipoPratica maxSize: 1
		data nullable: true
	}
}
