package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettiTasi implements Serializable {

	String codFiscale
	Short anno
	Long oggettoPratica
	BigDecimal percPossesso
	Byte mesiPossesso
	Byte mesiEsclusione
	Byte mesiRiduzione
	BigDecimal detrazione
	Byte mesiAliquotaRidotta
	String flagPossesso
	String flagEsclusione
	String flagRiduzione
	String flagAbPrincipale
	String flagAlRidotta
	String numOrdine
	String immStorico
	String categoriaCatasto
	String classeCatasto
	BigDecimal valore
	String titolo
	String estremiTitolo
	String flagFirma
	Short modello
	Byte fonte
	Long oggettoPraticaRif
	Long pratica
	String tipoPratica
	Date data
	Long oggetto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append oggettoPratica
		builder.append percPossesso
		builder.append mesiPossesso
		builder.append mesiEsclusione
		builder.append mesiRiduzione
		builder.append detrazione
		builder.append mesiAliquotaRidotta
		builder.append flagPossesso
		builder.append flagEsclusione
		builder.append flagRiduzione
		builder.append flagAbPrincipale
		builder.append flagAlRidotta
		builder.append numOrdine
		builder.append immStorico
		builder.append categoriaCatasto
		builder.append classeCatasto
		builder.append valore
		builder.append titolo
		builder.append estremiTitolo
		builder.append flagFirma
		builder.append modello
		builder.append fonte
		builder.append oggettoPraticaRif
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
		builder.append percPossesso, other.percPossesso
		builder.append mesiPossesso, other.mesiPossesso
		builder.append mesiEsclusione, other.mesiEsclusione
		builder.append mesiRiduzione, other.mesiRiduzione
		builder.append detrazione, other.detrazione
		builder.append mesiAliquotaRidotta, other.mesiAliquotaRidotta
		builder.append flagPossesso, other.flagPossesso
		builder.append flagEsclusione, other.flagEsclusione
		builder.append flagRiduzione, other.flagRiduzione
		builder.append flagAbPrincipale, other.flagAbPrincipale
		builder.append flagAlRidotta, other.flagAlRidotta
		builder.append numOrdine, other.numOrdine
		builder.append immStorico, other.immStorico
		builder.append categoriaCatasto, other.categoriaCatasto
		builder.append classeCatasto, other.classeCatasto
		builder.append valore, other.valore
		builder.append titolo, other.titolo
		builder.append estremiTitolo, other.estremiTitolo
		builder.append flagFirma, other.flagFirma
		builder.append modello, other.modello
		builder.append fonte, other.fonte
		builder.append oggettoPraticaRif, other.oggettoPraticaRif
		builder.append pratica, other.pratica
		builder.append tipoPratica, other.tipoPratica
		builder.append data, other.data
		builder.append oggetto, other.oggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "oggettoPratica", "percPossesso", "mesiPossesso", "mesiEsclusione", "mesiRiduzione", "detrazione", "mesiAliquotaRidotta", "flagPossesso", "flagEsclusione", "flagRiduzione", "flagAbPrincipale", "flagAlRidotta", "numOrdine", "immStorico", "categoriaCatasto", "classeCatasto", "valore", "titolo", "estremiTitolo", "flagFirma", "modello", "fonte", "oggettoPraticaRif", "pratica", "tipoPratica", "data", "oggetto"]
		version false
		data		sqlType:'Date', column:'DATA'
	}

	static constraints = {
		codFiscale maxSize: 16
		percPossesso nullable: true
		mesiPossesso nullable: true
		mesiEsclusione nullable: true
		mesiRiduzione nullable: true
		detrazione nullable: true
		mesiAliquotaRidotta nullable: true
		flagPossesso nullable: true, maxSize: 1
		flagEsclusione nullable: true, maxSize: 1
		flagRiduzione nullable: true, maxSize: 1
		flagAbPrincipale nullable: true, maxSize: 1
		flagAlRidotta nullable: true, maxSize: 1
		numOrdine nullable: true, maxSize: 5
		immStorico nullable: true, maxSize: 1
		categoriaCatasto nullable: true, maxSize: 3
		classeCatasto nullable: true, maxSize: 2
		valore nullable: true
		titolo nullable: true, maxSize: 1
		estremiTitolo nullable: true, maxSize: 60
		flagFirma nullable: true, maxSize: 1
		modello nullable: true
		fonte nullable: true
		oggettoPraticaRif nullable: true
		tipoPratica maxSize: 1
		data nullable: true
	}
}
