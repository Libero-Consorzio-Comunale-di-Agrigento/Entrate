package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DettagliImu implements Serializable {

	String codFiscale
	String cognomeNome
	Short anno
	BigDecimal abComu
	BigDecimal abComuAcc
	BigDecimal nFabAb
	BigDecimal detrComu
	BigDecimal detrComuAcc
	BigDecimal ruraliComu
	BigDecimal ruraliComuAcc
	BigDecimal nFabRurali
	BigDecimal terreniComu
	BigDecimal terreniComuAcc
	BigDecimal terreniErar
	BigDecimal terreniErarAcc
	BigDecimal areeComu
	BigDecimal areeComuAcc
	BigDecimal areeErar
	BigDecimal areeErarAcc
	BigDecimal fabbDComu
	BigDecimal fabbDComuAcc
	BigDecimal fabbDErar
	BigDecimal fabbDErarAcc
	BigDecimal nFabFabbD
	BigDecimal altriComu
	BigDecimal altriComuAcc
	BigDecimal altriErar
	BigDecimal altriErarAcc
	BigDecimal nFabAltri
	BigDecimal versAbPrinc
	BigDecimal versAbPrincAcc
	BigDecimal versRurali
	BigDecimal versRuraliAcc
	BigDecimal versAltriComu
	BigDecimal versAltriComuAcc
	BigDecimal versAltriErar
	BigDecimal versAltriErarAcc
	BigDecimal versTerreniComu
	BigDecimal versTerreniComuAcc
	BigDecimal versTerreniErar
	BigDecimal versTerreniErarAcc
	BigDecimal versAreeComu
	BigDecimal versAreeComuAcc
	BigDecimal versAreeErar
	BigDecimal versAreeErarAcc
	BigDecimal versFabDComu
	BigDecimal versFabDComuAcc
	BigDecimal versFabDErar
	BigDecimal versFabDErarAcc
	BigDecimal impostaComu
	BigDecimal impostaComuAcc
	BigDecimal impostaErar
	BigDecimal impostaErarAcc
	BigDecimal versamentiComu
	BigDecimal versamentiComuAcc
	BigDecimal versamentiErar
	BigDecimal versamentiErarAcc

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append cognomeNome
		builder.append anno
		builder.append abComu
		builder.append abComuAcc
		builder.append nFabAb
		builder.append detrComu
		builder.append detrComuAcc
		builder.append ruraliComu
		builder.append ruraliComuAcc
		builder.append nFabRurali
		builder.append terreniComu
		builder.append terreniComuAcc
		builder.append terreniErar
		builder.append terreniErarAcc
		builder.append areeComu
		builder.append areeComuAcc
		builder.append areeErar
		builder.append areeErarAcc
		builder.append fabbDComu
		builder.append fabbDComuAcc
		builder.append fabbDErar
		builder.append fabbDErarAcc
		builder.append nFabFabbD
		builder.append altriComu
		builder.append altriComuAcc
		builder.append altriErar
		builder.append altriErarAcc
		builder.append nFabAltri
		builder.append versAbPrinc
		builder.append versAbPrincAcc
		builder.append versRurali
		builder.append versRuraliAcc
		builder.append versAltriComu
		builder.append versAltriComuAcc
		builder.append versAltriErar
		builder.append versAltriErarAcc
		builder.append versTerreniComu
		builder.append versTerreniComuAcc
		builder.append versTerreniErar
		builder.append versTerreniErarAcc
		builder.append versAreeComu
		builder.append versAreeComuAcc
		builder.append versAreeErar
		builder.append versAreeErarAcc
		builder.append versFabDComu
		builder.append versFabDComuAcc
		builder.append versFabDErar
		builder.append versFabDErarAcc
		builder.append impostaComu
		builder.append impostaComuAcc
		builder.append impostaErar
		builder.append impostaErarAcc
		builder.append versamentiComu
		builder.append versamentiComuAcc
		builder.append versamentiErar
		builder.append versamentiErarAcc
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append cognomeNome, other.cognomeNome
		builder.append anno, other.anno
		builder.append abComu, other.abComu
		builder.append abComuAcc, other.abComuAcc
		builder.append nFabAb, other.nFabAb
		builder.append detrComu, other.detrComu
		builder.append detrComuAcc, other.detrComuAcc
		builder.append ruraliComu, other.ruraliComu
		builder.append ruraliComuAcc, other.ruraliComuAcc
		builder.append nFabRurali, other.nFabRurali
		builder.append terreniComu, other.terreniComu
		builder.append terreniComuAcc, other.terreniComuAcc
		builder.append terreniErar, other.terreniErar
		builder.append terreniErarAcc, other.terreniErarAcc
		builder.append areeComu, other.areeComu
		builder.append areeComuAcc, other.areeComuAcc
		builder.append areeErar, other.areeErar
		builder.append areeErarAcc, other.areeErarAcc
		builder.append fabbDComu, other.fabbDComu
		builder.append fabbDComuAcc, other.fabbDComuAcc
		builder.append fabbDErar, other.fabbDErar
		builder.append fabbDErarAcc, other.fabbDErarAcc
		builder.append nFabFabbD, other.nFabFabbD
		builder.append altriComu, other.altriComu
		builder.append altriComuAcc, other.altriComuAcc
		builder.append altriErar, other.altriErar
		builder.append altriErarAcc, other.altriErarAcc
		builder.append nFabAltri, other.nFabAltri
		builder.append versAbPrinc, other.versAbPrinc
		builder.append versAbPrincAcc, other.versAbPrincAcc
		builder.append versRurali, other.versRurali
		builder.append versRuraliAcc, other.versRuraliAcc
		builder.append versAltriComu, other.versAltriComu
		builder.append versAltriComuAcc, other.versAltriComuAcc
		builder.append versAltriErar, other.versAltriErar
		builder.append versAltriErarAcc, other.versAltriErarAcc
		builder.append versTerreniComu, other.versTerreniComu
		builder.append versTerreniComuAcc, other.versTerreniComuAcc
		builder.append versTerreniErar, other.versTerreniErar
		builder.append versTerreniErarAcc, other.versTerreniErarAcc
		builder.append versAreeComu, other.versAreeComu
		builder.append versAreeComuAcc, other.versAreeComuAcc
		builder.append versAreeErar, other.versAreeErar
		builder.append versAreeErarAcc, other.versAreeErarAcc
		builder.append versFabDComu, other.versFabDComu
		builder.append versFabDComuAcc, other.versFabDComuAcc
		builder.append versFabDErar, other.versFabDErar
		builder.append versFabDErarAcc, other.versFabDErarAcc
		builder.append impostaComu, other.impostaComu
		builder.append impostaComuAcc, other.impostaComuAcc
		builder.append impostaErar, other.impostaErar
		builder.append impostaErarAcc, other.impostaErarAcc
		builder.append versamentiComu, other.versamentiComu
		builder.append versamentiComuAcc, other.versamentiComuAcc
		builder.append versamentiErar, other.versamentiErar
		builder.append versamentiErarAcc, other.versamentiErarAcc
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "cognomeNome", "anno", "abComu", "abComuAcc", "nFabAb", "detrComu", "detrComuAcc", "ruraliComu", "ruraliComuAcc", "nFabRurali", "terreniComu", "terreniComuAcc", "terreniErar", "terreniErarAcc", "areeComu", "areeComuAcc", "areeErar", "areeErarAcc", "fabbDComu", "fabbDComuAcc", "fabbDErar", "fabbDErarAcc", "nFabFabbD", "altriComu", "altriComuAcc", "altriErar", "altriErarAcc", "nFabAltri", "versAbPrinc", "versAbPrincAcc", "versRurali", "versRuraliAcc", "versAltriComu", "versAltriComuAcc", "versAltriErar", "versAltriErarAcc", "versTerreniComu", "versTerreniComuAcc", "versTerreniErar", "versTerreniErarAcc", "versAreeComu", "versAreeComuAcc", "versAreeErar", "versAreeErarAcc", "versFabDComu", "versFabDComuAcc", "versFabDErar", "versFabDErarAcc", "impostaComu", "impostaComuAcc", "impostaErar", "impostaErarAcc", "versamentiComu", "versamentiComuAcc", "versamentiErar", "versamentiErarAcc"]
		version false
		fabbDComu		column: "FABB_D_COMU"
		fabbDComuAcc	column: "FABB_D_COMU_ACC"
		fabbDErar		column: "FABB_D_ERAR"
		fabbDErarAcc	column: "FABB_D_ERAR_ACC"
		versFabDComu		column: "VERS_FAB_D_COMU"
		versFabDComuAcc	column: "VERS_FAB_D_COMU_ACC"
		versFabDErar		column: "VERS_FAB_D_ERAR"
		versFabDErarAcc	column: "VERS_FAB_D_ERAR_ACC"
		nFabFabbD		column: "N_FAB_FABB_D"
	}

	static constraints = {
		codFiscale nullable: true, maxSize: 16
		cognomeNome nullable: true, maxSize: 100
		anno nullable: true
		abComu nullable: true
		abComuAcc nullable: true
		nFabAb nullable: true
		detrComu nullable: true
		detrComuAcc nullable: true
		ruraliComu nullable: true
		ruraliComuAcc nullable: true
		nFabRurali nullable: true
		terreniComu nullable: true
		terreniComuAcc nullable: true
		terreniErar nullable: true
		terreniErarAcc nullable: true
		areeComu nullable: true
		areeComuAcc nullable: true
		areeErar nullable: true
		areeErarAcc nullable: true
		fabbDComu nullable: true
		fabbDComuAcc nullable: true
		fabbDErar nullable: true
		fabbDErarAcc nullable: true
		nFabFabbD nullable: true
		altriComu nullable: true
		altriComuAcc nullable: true
		altriErar nullable: true
		altriErarAcc nullable: true
		nFabAltri nullable: true
		versAbPrinc nullable: true
		versAbPrincAcc nullable: true
		versRurali nullable: true
		versRuraliAcc nullable: true
		versAltriComu nullable: true
		versAltriComuAcc nullable: true
		versAltriErar nullable: true
		versAltriErarAcc nullable: true
		versTerreniComu nullable: true
		versTerreniComuAcc nullable: true
		versTerreniErar nullable: true
		versTerreniErarAcc nullable: true
		versAreeComu nullable: true
		versAreeComuAcc nullable: true
		versAreeErar nullable: true
		versAreeErarAcc nullable: true
		versFabDComu nullable: true
		versFabDComuAcc nullable: true
		versFabDErar nullable: true
		versFabDErarAcc nullable: true
		impostaComu nullable: true
		impostaComuAcc nullable: true
		impostaErar nullable: true
		impostaErarAcc nullable: true
		versamentiComu nullable: true
		versamentiComuAcc nullable: true
		versamentiErar nullable: true
		versamentiErarAcc nullable: true
	}
}
