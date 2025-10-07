package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class LiquidazioneOgprAcc implements Serializable {

	Long oggettoPraticaLiq
	BigDecimal valoreLiq
	String categoriaCatastoLiq
	String classeCatastoLiq
	Byte tipoOggettoLiq
	BigDecimal percPossessoLiq
	Byte mesiPossessoLiq
	Byte mesiEsclusioneLiq
	String flagRiduzioneLiq
	Byte mesiRiduzioneLiq
	BigDecimal detrazioneLiq
	Byte tipoAliquotaLiq
	Long oggettoPraticaDic
	String codFiscale
	Long praticaAcc
	Date dataLiq

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggettoPraticaLiq
		builder.append valoreLiq
		builder.append categoriaCatastoLiq
		builder.append classeCatastoLiq
		builder.append tipoOggettoLiq
		builder.append percPossessoLiq
		builder.append mesiPossessoLiq
		builder.append mesiEsclusioneLiq
		builder.append flagRiduzioneLiq
		builder.append mesiRiduzioneLiq
		builder.append detrazioneLiq
		builder.append tipoAliquotaLiq
		builder.append oggettoPraticaDic
		builder.append codFiscale
		builder.append praticaAcc
		builder.append dataLiq
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggettoPraticaLiq, other.oggettoPraticaLiq
		builder.append valoreLiq, other.valoreLiq
		builder.append categoriaCatastoLiq, other.categoriaCatastoLiq
		builder.append classeCatastoLiq, other.classeCatastoLiq
		builder.append tipoOggettoLiq, other.tipoOggettoLiq
		builder.append percPossessoLiq, other.percPossessoLiq
		builder.append mesiPossessoLiq, other.mesiPossessoLiq
		builder.append mesiEsclusioneLiq, other.mesiEsclusioneLiq
		builder.append flagRiduzioneLiq, other.flagRiduzioneLiq
		builder.append mesiRiduzioneLiq, other.mesiRiduzioneLiq
		builder.append detrazioneLiq, other.detrazioneLiq
		builder.append tipoAliquotaLiq, other.tipoAliquotaLiq
		builder.append oggettoPraticaDic, other.oggettoPraticaDic
		builder.append codFiscale, other.codFiscale
		builder.append praticaAcc, other.praticaAcc
		builder.append dataLiq, other.dataLiq
		builder.isEquals()
	}

	static mapping = {
		id composite: ["oggettoPraticaLiq", "valoreLiq", "categoriaCatastoLiq", "classeCatastoLiq", "tipoOggettoLiq", "percPossessoLiq", "mesiPossessoLiq", "mesiEsclusioneLiq", "flagRiduzioneLiq", "mesiRiduzioneLiq", "detrazioneLiq", "tipoAliquotaLiq", "oggettoPraticaDic", "codFiscale", "praticaAcc", "dataLiq"]
		dataLiq	sqlType: 'Date'
		version false
	}

	static constraints = {
		valoreLiq nullable: true
		categoriaCatastoLiq nullable: true, maxSize: 3
		classeCatastoLiq nullable: true, maxSize: 2
		tipoOggettoLiq nullable: true
		percPossessoLiq nullable: true
		mesiPossessoLiq nullable: true
		mesiEsclusioneLiq nullable: true
		flagRiduzioneLiq nullable: true, maxSize: 1
		mesiRiduzioneLiq nullable: true
		detrazioneLiq nullable: true
		tipoAliquotaLiq nullable: true
		oggettoPraticaDic nullable: true
		codFiscale maxSize: 16
		dataLiq nullable: true
	}
}
