package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiAnaFis implements Serializable {

	String tdich
	String fiscale
	String presenta
	String modello
	String progMod
	String cognome
	String nome
	String sesso
	String dataNascita
	String prvNascita
	String comuneNascita
	String comuneRes
	String istatComRes
	String prvRes
	String capRes
	String indirizzoRes
	String codStaCiv
	String titStudio
	String fallimento
	String eventiEcc
	String caParDomFi
	String comDoFi
	String istatComFi
	String proDomFi
	String indirDomFi
	String capDomFi
	String presDichCong
	String fiscConiuge
	String recoModificato
	String fiscDenunc
	String free
	String denomDenunc
	String domFiscDenunc
	String capFiscDenunc
	String comFiscDenunc
	String prvFiscDenunc
	String caricaDenunc
	String telPrefDichiar
	String telDichiarante
	String progressivo

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tdich
		builder.append fiscale
		builder.append presenta
		builder.append modello
		builder.append progMod
		builder.append cognome
		builder.append nome
		builder.append sesso
		builder.append dataNascita
		builder.append prvNascita
		builder.append comuneNascita
		builder.append comuneRes
		builder.append istatComRes
		builder.append prvRes
		builder.append capRes
		builder.append indirizzoRes
		builder.append codStaCiv
		builder.append titStudio
		builder.append fallimento
		builder.append eventiEcc
		builder.append caParDomFi
		builder.append comDoFi
		builder.append istatComFi
		builder.append proDomFi
		builder.append indirDomFi
		builder.append capDomFi
		builder.append presDichCong
		builder.append fiscConiuge
		builder.append recoModificato
		builder.append fiscDenunc
		builder.append free
		builder.append denomDenunc
		builder.append domFiscDenunc
		builder.append capFiscDenunc
		builder.append comFiscDenunc
		builder.append prvFiscDenunc
		builder.append caricaDenunc
		builder.append telPrefDichiar
		builder.append telDichiarante
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tdich, other.tdich
		builder.append fiscale, other.fiscale
		builder.append presenta, other.presenta
		builder.append modello, other.modello
		builder.append progMod, other.progMod
		builder.append cognome, other.cognome
		builder.append nome, other.nome
		builder.append sesso, other.sesso
		builder.append dataNascita, other.dataNascita
		builder.append prvNascita, other.prvNascita
		builder.append comuneNascita, other.comuneNascita
		builder.append comuneRes, other.comuneRes
		builder.append istatComRes, other.istatComRes
		builder.append prvRes, other.prvRes
		builder.append capRes, other.capRes
		builder.append indirizzoRes, other.indirizzoRes
		builder.append codStaCiv, other.codStaCiv
		builder.append titStudio, other.titStudio
		builder.append fallimento, other.fallimento
		builder.append eventiEcc, other.eventiEcc
		builder.append caParDomFi, other.caParDomFi
		builder.append comDoFi, other.comDoFi
		builder.append istatComFi, other.istatComFi
		builder.append proDomFi, other.proDomFi
		builder.append indirDomFi, other.indirDomFi
		builder.append capDomFi, other.capDomFi
		builder.append presDichCong, other.presDichCong
		builder.append fiscConiuge, other.fiscConiuge
		builder.append recoModificato, other.recoModificato
		builder.append fiscDenunc, other.fiscDenunc
		builder.append free, other.free
		builder.append denomDenunc, other.denomDenunc
		builder.append domFiscDenunc, other.domFiscDenunc
		builder.append capFiscDenunc, other.capFiscDenunc
		builder.append comFiscDenunc, other.comFiscDenunc
		builder.append prvFiscDenunc, other.prvFiscDenunc
		builder.append caricaDenunc, other.caricaDenunc
		builder.append telPrefDichiar, other.telPrefDichiar
		builder.append telDichiarante, other.telDichiarante
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tdich", "fiscale", "presenta", "modello", "progMod", "cognome", "nome", "sesso", "dataNascita", "prvNascita", "comuneNascita", "comuneRes", "istatComRes", "prvRes", "capRes", "indirizzoRes", "codStaCiv", "titStudio", "fallimento", "eventiEcc", "caParDomFi", "comDoFi", "istatComFi", "proDomFi", "indirDomFi", "capDomFi", "presDichCong", "fiscConiuge", "recoModificato", "fiscDenunc", "free", "denomDenunc", "domFiscDenunc", "capFiscDenunc", "comFiscDenunc", "prvFiscDenunc", "caricaDenunc", "telPrefDichiar", "telDichiarante", "progressivo"]
		version false
	}

	static constraints = {
		tdich nullable: true, maxSize: 1
		fiscale nullable: true, maxSize: 16
		presenta nullable: true, maxSize: 10
		modello nullable: true, maxSize: 1
		progMod nullable: true, maxSize: 5
		cognome nullable: true, maxSize: 24
		nome nullable: true, maxSize: 20
		sesso nullable: true, maxSize: 1
		dataNascita nullable: true, maxSize: 10
		prvNascita nullable: true, maxSize: 2
		comuneNascita nullable: true, maxSize: 21
		comuneRes nullable: true, maxSize: 21
		istatComRes nullable: true, maxSize: 6
		prvRes nullable: true, maxSize: 2
		capRes nullable: true, maxSize: 5
		indirizzoRes nullable: true, maxSize: 35
		codStaCiv nullable: true, maxSize: 1
		titStudio nullable: true, maxSize: 1
		fallimento nullable: true, maxSize: 1
		eventiEcc nullable: true, maxSize: 1
		caParDomFi nullable: true, maxSize: 1
		comDoFi nullable: true, maxSize: 21
		istatComFi nullable: true, maxSize: 6
		proDomFi nullable: true, maxSize: 2
		indirDomFi nullable: true, maxSize: 35
		capDomFi nullable: true, maxSize: 5
		presDichCong nullable: true, maxSize: 1
		fiscConiuge nullable: true, maxSize: 16
		recoModificato nullable: true, maxSize: 1
		fiscDenunc nullable: true, maxSize: 16
		free nullable: true, maxSize: 1
		denomDenunc nullable: true, maxSize: 60
		domFiscDenunc nullable: true, maxSize: 35
		capFiscDenunc nullable: true, maxSize: 5
		comFiscDenunc nullable: true, maxSize: 25
		prvFiscDenunc nullable: true, maxSize: 2
		caricaDenunc nullable: true, maxSize: 25
		telPrefDichiar nullable: true, maxSize: 4
		telDichiarante nullable: true, maxSize: 8
		progressivo nullable: true, maxSize: 9
	}
}
