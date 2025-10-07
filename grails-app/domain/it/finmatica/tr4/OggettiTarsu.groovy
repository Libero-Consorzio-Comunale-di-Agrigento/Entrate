package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettiTarsu implements Serializable {

	String codFiscale
	Short anno
	Long oggettoPratica
	String categoriaCatasto
	String classeCatasto
	Long oggettoPraticaRif
	Date inizioOccupazione
	Date fineOccupazione
	Date dataDecorrenza
	Date dataCessazione
	Short tributo
	Short categoria
	Byte tipoTariffa
	BigDecimal consistenza
	Long pratica
	String tipoPratica
	Date data
	Long oggetto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append oggettoPratica
		builder.append categoriaCatasto
		builder.append classeCatasto
		builder.append oggettoPraticaRif
		builder.append inizioOccupazione
		builder.append fineOccupazione
		builder.append dataDecorrenza
		builder.append dataCessazione
		builder.append tributo
		builder.append categoria
		builder.append tipoTariffa
		builder.append consistenza
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
		builder.append categoriaCatasto, other.categoriaCatasto
		builder.append classeCatasto, other.classeCatasto
		builder.append oggettoPraticaRif, other.oggettoPraticaRif
		builder.append inizioOccupazione, other.inizioOccupazione
		builder.append fineOccupazione, other.fineOccupazione
		builder.append dataDecorrenza, other.dataDecorrenza
		builder.append dataCessazione, other.dataCessazione
		builder.append tributo, other.tributo
		builder.append categoria, other.categoria
		builder.append tipoTariffa, other.tipoTariffa
		builder.append consistenza, other.consistenza
		builder.append pratica, other.pratica
		builder.append tipoPratica, other.tipoPratica
		builder.append data, other.data
		builder.append oggetto, other.oggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "oggettoPratica", "categoriaCatasto", "classeCatasto", "oggettoPraticaRif", "inizioOccupazione", "fineOccupazione", "dataDecorrenza", "dataCessazione", "tributo", "categoria", "tipoTariffa", "consistenza", "pratica", "tipoPratica", "data", "oggetto"]
		version false
		inizioOccupazione	sqlType:'Date', column:'INIZIO_OCCUPAZIONE'
		fineOccupazione		sqlType:'Date', column:'FINE_OCCUPAZIONE'
		dataDecorrenza		sqlType:'Date', column:'DATA_DECORRENZA'
		dataCessazione		sqlType:'Date', column:'DATA_CESSAZIONE'
		data				sqlType:'Date', column:'DATA'
	}

	static constraints = {
		codFiscale maxSize: 16
		categoriaCatasto nullable: true, maxSize: 3
		classeCatasto nullable: true, maxSize: 2
		oggettoPraticaRif nullable: true
		inizioOccupazione nullable: true
		fineOccupazione nullable: true
		dataDecorrenza nullable: true
		dataCessazione nullable: true
		tributo nullable: true
		categoria nullable: true
		tipoTariffa nullable: true
		consistenza nullable: true
		tipoPratica maxSize: 1
		data nullable: true
	}
}
