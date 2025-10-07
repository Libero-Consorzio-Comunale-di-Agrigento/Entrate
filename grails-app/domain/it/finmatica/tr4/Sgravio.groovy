package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Sgravio implements Serializable {
	RuoloContribuente ruoloContribuente
	Short sequenzaSgravio
	MotivoSgravio motivoSgravio
	Short numeroElenco
	Date dataElenco
	BigDecimal importo
	Short semestri
	BigDecimal addizionaleEca
	BigDecimal maggiorazioneEca
	BigDecimal addizionalePro
	BigDecimal iva
	Short codConcessione
	Integer numRuolo
	BigDecimal fattura
	Short mesiSgravio
	boolean flagAutomatico
	Short daMese
	Short aMese
	String tipoSgravio
	Short giorniSgravio
	BigDecimal maggiorazioneTares
	String note
	OggettoPratica oggettoPratica
	Short progrSgravio

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append ruoloContribuente.ruolo
		builder.append ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza
		builder.append sequenzaSgravio
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append ruoloContribuente.ruolo, other.ruoloContribuente.ruolo
		builder.append ruoloContribuente.contribuente.codFiscale, other.ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza, other.ruoloContribuente.sequenza
		builder.append sequenzaSgravio, other.sequenzaSgravio
		builder.isEquals()
	}

	static mapping = {
		id composite: ["ruoloContribuente", "sequenzaSgravio"]
		
		ruoloContribuente {
			column name: "ruolo"
			column name: "cod_fiscale"
			column name: "sequenza"
		}
		
		motivoSgravio	column: "motivo_sgravio"
		oggettoPratica column: "ogpr_sgravio"
		flagAutomatico	type: SiNoType
		dataElenco	sqlType:'Date', column:'DATA_ELENCO'
		
		table "sgravi"
		version false
	}

	static constraints = {
		motivoSgravio nullable: true
		numeroElenco nullable: true
		dataElenco nullable: true
		importo nullable: true
		semestri nullable: true
		addizionaleEca nullable: true
		maggiorazioneEca nullable: true
		addizionalePro nullable: true
		iva nullable: true
		codConcessione nullable: true
		numRuolo nullable: true
		fattura nullable: true
		mesiSgravio nullable: true
		flagAutomatico nullable: true, maxSize: 1
		daMese nullable: true
		aMese nullable: true
        tipoSgravio nullable: true
		giorniSgravio nullable: true
		maggiorazioneTares nullable: true
		note nullable: true
		oggettoPratica nullable: true
		progrSgravio nullable: true
	}
	
}
