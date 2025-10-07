package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SigaiAnaGiur implements Serializable {

	String uiidd
	String centroServizio
	String presenta
	String fiscale
	String modello
	String progMod
	String flagCf
	String sigla
	String ragioneSoc
	String flag
	String apprBil
	String terBil
	String dataVariaz
	String comuneSedeLeg
	String istatComSl
	String provSedeLeg
	String capSedeLeg
	String indSedeLeg
	String dataVariazDf
	String comuneDomFi
	String istatCom
	String provDomFi
	String capDomFi
	String indDomFi
	String stato
	String naturaGiu
	String situaz
	String fiSocIn
	String flagCfSIn
	String eventiEcc
	String fiscRapLeg
	String flagRapLeg
	String cognomeRapLeg
	String nomeRapLeg
	String sessoRapLeg
	String dataNasRapLe
	String comNasRapLe
	String istatNasRapLe
	String prvNasRapLe
	String denominaz
	String codiceCari
	String dataCarica
	String comuReRaLe
	String istatReRaLe
	String provReRaLe
	String indRapLeg
	String capRapLeg
	String caaf
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
		builder.append uiidd
		builder.append centroServizio
		builder.append presenta
		builder.append fiscale
		builder.append modello
		builder.append progMod
		builder.append flagCf
		builder.append sigla
		builder.append ragioneSoc
		builder.append flag
		builder.append apprBil
		builder.append terBil
		builder.append dataVariaz
		builder.append comuneSedeLeg
		builder.append istatComSl
		builder.append provSedeLeg
		builder.append capSedeLeg
		builder.append indSedeLeg
		builder.append dataVariazDf
		builder.append comuneDomFi
		builder.append istatCom
		builder.append provDomFi
		builder.append capDomFi
		builder.append indDomFi
		builder.append stato
		builder.append naturaGiu
		builder.append situaz
		builder.append fiSocIn
		builder.append flagCfSIn
		builder.append eventiEcc
		builder.append fiscRapLeg
		builder.append flagRapLeg
		builder.append cognomeRapLeg
		builder.append nomeRapLeg
		builder.append sessoRapLeg
		builder.append dataNasRapLe
		builder.append comNasRapLe
		builder.append istatNasRapLe
		builder.append prvNasRapLe
		builder.append denominaz
		builder.append codiceCari
		builder.append dataCarica
		builder.append comuReRaLe
		builder.append istatReRaLe
		builder.append provReRaLe
		builder.append indRapLeg
		builder.append capRapLeg
		builder.append caaf
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
		builder.append uiidd, other.uiidd
		builder.append centroServizio, other.centroServizio
		builder.append presenta, other.presenta
		builder.append fiscale, other.fiscale
		builder.append modello, other.modello
		builder.append progMod, other.progMod
		builder.append flagCf, other.flagCf
		builder.append sigla, other.sigla
		builder.append ragioneSoc, other.ragioneSoc
		builder.append flag, other.flag
		builder.append apprBil, other.apprBil
		builder.append terBil, other.terBil
		builder.append dataVariaz, other.dataVariaz
		builder.append comuneSedeLeg, other.comuneSedeLeg
		builder.append istatComSl, other.istatComSl
		builder.append provSedeLeg, other.provSedeLeg
		builder.append capSedeLeg, other.capSedeLeg
		builder.append indSedeLeg, other.indSedeLeg
		builder.append dataVariazDf, other.dataVariazDf
		builder.append comuneDomFi, other.comuneDomFi
		builder.append istatCom, other.istatCom
		builder.append provDomFi, other.provDomFi
		builder.append capDomFi, other.capDomFi
		builder.append indDomFi, other.indDomFi
		builder.append stato, other.stato
		builder.append naturaGiu, other.naturaGiu
		builder.append situaz, other.situaz
		builder.append fiSocIn, other.fiSocIn
		builder.append flagCfSIn, other.flagCfSIn
		builder.append eventiEcc, other.eventiEcc
		builder.append fiscRapLeg, other.fiscRapLeg
		builder.append flagRapLeg, other.flagRapLeg
		builder.append cognomeRapLeg, other.cognomeRapLeg
		builder.append nomeRapLeg, other.nomeRapLeg
		builder.append sessoRapLeg, other.sessoRapLeg
		builder.append dataNasRapLe, other.dataNasRapLe
		builder.append comNasRapLe, other.comNasRapLe
		builder.append istatNasRapLe, other.istatNasRapLe
		builder.append prvNasRapLe, other.prvNasRapLe
		builder.append denominaz, other.denominaz
		builder.append codiceCari, other.codiceCari
		builder.append dataCarica, other.dataCarica
		builder.append comuReRaLe, other.comuReRaLe
		builder.append istatReRaLe, other.istatReRaLe
		builder.append provReRaLe, other.provReRaLe
		builder.append indRapLeg, other.indRapLeg
		builder.append capRapLeg, other.capRapLeg
		builder.append caaf, other.caaf
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
		id composite: ["uiidd", "centroServizio", "presenta", "fiscale", "modello", "progMod", "flagCf", "sigla", "ragioneSoc", "flag", "apprBil", "terBil", "dataVariaz", "comuneSedeLeg", "istatComSl", "provSedeLeg", "capSedeLeg", "indSedeLeg", "dataVariazDf", "comuneDomFi", "istatCom", "provDomFi", "capDomFi", "indDomFi", "stato", "naturaGiu", "situaz", "fiSocIn", "flagCfSIn", "eventiEcc", "fiscRapLeg", "flagRapLeg", "cognomeRapLeg", "nomeRapLeg", "sessoRapLeg", "dataNasRapLe", "comNasRapLe", "istatNasRapLe", "prvNasRapLe", "denominaz", "codiceCari", "dataCarica", "comuReRaLe", "istatReRaLe", "provReRaLe", "indRapLeg", "capRapLeg", "caaf", "recoModificato", "fiscDenunc", "free", "denomDenunc", "domFiscDenunc", "capFiscDenunc", "comFiscDenunc", "prvFiscDenunc", "caricaDenunc", "telPrefDichiar", "telDichiarante", "progressivo"]
		version false
		uiidd		column: "U_IIDD" 
		flagCfSIn	column: "FLAG_CF_S_IN"
	}

	static constraints = {
		uiidd nullable: true, maxSize: 3
		centroServizio nullable: true, maxSize: 3
		presenta nullable: true, maxSize: 10
		fiscale nullable: true, maxSize: 16
		modello nullable: true, maxSize: 1
		progMod nullable: true, maxSize: 5
		flagCf nullable: true, maxSize: 1
		sigla nullable: true, maxSize: 20
		ragioneSoc nullable: true, maxSize: 180
		flag nullable: true, maxSize: 1
		apprBil nullable: true, maxSize: 10
		terBil nullable: true, maxSize: 10
		dataVariaz nullable: true, maxSize: 10
		comuneSedeLeg nullable: true, maxSize: 25
		istatComSl nullable: true, maxSize: 6
		provSedeLeg nullable: true, maxSize: 2
		capSedeLeg nullable: true, maxSize: 5
		indSedeLeg nullable: true, maxSize: 35
		dataVariazDf nullable: true, maxSize: 10
		comuneDomFi nullable: true, maxSize: 25
		istatCom nullable: true, maxSize: 6
		provDomFi nullable: true, maxSize: 2
		capDomFi nullable: true, maxSize: 5
		indDomFi nullable: true, maxSize: 35
		stato nullable: true, maxSize: 1
		naturaGiu nullable: true, maxSize: 2
		situaz nullable: true, maxSize: 1
		fiSocIn nullable: true, maxSize: 16
		flagCfSIn nullable: true, maxSize: 1
		eventiEcc nullable: true, maxSize: 1
		fiscRapLeg nullable: true, maxSize: 16
		flagRapLeg nullable: true, maxSize: 1
		cognomeRapLeg nullable: true, maxSize: 24
		nomeRapLeg nullable: true, maxSize: 20
		sessoRapLeg nullable: true, maxSize: 1
		dataNasRapLe nullable: true, maxSize: 10
		comNasRapLe nullable: true, maxSize: 25
		istatNasRapLe nullable: true, maxSize: 6
		prvNasRapLe nullable: true, maxSize: 2
		denominaz nullable: true, maxSize: 79
		codiceCari nullable: true, maxSize: 1
		dataCarica nullable: true, maxSize: 10
		comuReRaLe nullable: true, maxSize: 25
		istatReRaLe nullable: true, maxSize: 6
		provReRaLe nullable: true, maxSize: 2
		indRapLeg nullable: true, maxSize: 35
		capRapLeg nullable: true, maxSize: 5
		caaf nullable: true, maxSize: 1
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
