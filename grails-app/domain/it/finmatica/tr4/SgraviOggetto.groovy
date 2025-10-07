package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SgraviOggetto implements Serializable {

//	Long ruolo
//	String codFiscale
//	Short sequenza
	RuoloContribuente ruoloContribuente
	Short sequenzaSgravio
	Byte motivoSgravio
	Short numeroElenco
	Date dataElenco
	BigDecimal importo
	BigDecimal nettoSgravi
	Byte semestri
	BigDecimal addizionaleEca
	BigDecimal maggiorazioneEca
	BigDecimal addizionalePro
	BigDecimal iva
	BigDecimal maggiorazioneTares
	BigDecimal importoLordo
	BigDecimal imposta
	Byte daMeseRuco
	Byte aMeseRuco
	Byte daMeseSgra
	Byte aMeseSgra
	String tipoSgravio
	Short giorniRuolo
	Short giorniSgravio

	int hashCode() {
		def builder = new HashCodeBuilder()
//		builder.append ruolo
//		builder.append codFiscale
//		builder.append sequenza
		builder.append ruoloContribuente.ruolo
		builder.append ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza
		builder.append sequenzaSgravio
		builder.append motivoSgravio
		builder.append numeroElenco
		builder.append dataElenco
		builder.append importo
		builder.append nettoSgravi
		builder.append semestri
		builder.append addizionaleEca
		builder.append maggiorazioneEca
		builder.append addizionalePro
		builder.append iva
		builder.append maggiorazioneTares
		builder.append importoLordo
		builder.append imposta
		builder.append daMeseRuco
		builder.append aMeseRuco
		builder.append daMeseSgra
		builder.append aMeseSgra
		builder.append tipoSgravio
		builder.append giorniRuolo
		builder.append giorniSgravio
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
//		builder.append ruolo, other.ruolo
//		builder.append codFiscale, other.codFiscale
//		builder.append sequenza, other.sequenza
		builder.append ruoloContribuente.ruolo, other.ruoloContribuente.ruolo
		builder.append ruoloContribuente.contribuente.codFiscale, other.ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza, other.ruoloContribuente.sequenza
		builder.append sequenzaSgravio, other.sequenzaSgravio
		builder.append motivoSgravio, other.motivoSgravio
		builder.append numeroElenco, other.numeroElenco
		builder.append dataElenco, other.dataElenco
		builder.append importo, other.importo
		builder.append nettoSgravi, other.nettoSgravi
		builder.append semestri, other.semestri
		builder.append addizionaleEca, other.addizionaleEca
		builder.append maggiorazioneEca, other.maggiorazioneEca
		builder.append addizionalePro, other.addizionalePro
		builder.append iva, other.iva
		builder.append maggiorazioneTares, other.maggiorazioneTares
		builder.append importoLordo, other.importoLordo
		builder.append imposta, other.imposta
		builder.append daMeseRuco, other.daMeseRuco
		builder.append aMeseRuco, other.aMeseRuco
		builder.append daMeseSgra, other.daMeseSgra
		builder.append aMeseSgra, other.aMeseSgra
		builder.append tipoSgravio, other.tipoSgravio
		builder.append giorniRuolo, other.giorniRuolo
		builder.append giorniSgravio, other.giorniSgravio
		builder.isEquals()
	}

	
	static mapping = {
		id composite: ["ruoloContribuente", "sequenzaSgravio", "motivoSgravio", "numeroElenco", "dataElenco", "importo", "nettoSgravi", "semestri", "addizionaleEca", "maggiorazioneEca", "addizionalePro", "iva", "maggiorazioneTares", "importoLordo", "imposta", "daMeseRuco", "aMeseRuco", "daMeseSgra", "aMeseSgra", "tipoSgravio", "giorniRuolo", "giorniSgravio"]
		
		ruoloContribuente {
			column name: "ruolo"
			column name: "cod_fiscale"
			column name: "sequenza"
		}
		version false
		dataElenco	sqlType:'Date', column:'DATA_ELENCO'
	}

	static constraints = {
//		ruolo nullable: true
//		codFiscale nullable: true, maxSize: 16
//		sequenza nullable: true
		sequenzaSgravio nullable: true
		motivoSgravio nullable: true
		numeroElenco nullable: true
		dataElenco nullable: true
		importo nullable: true
		nettoSgravi nullable: true
		semestri nullable: true
		addizionaleEca nullable: true
		maggiorazioneEca nullable: true
		addizionalePro nullable: true
		iva nullable: true
		maggiorazioneTares nullable: true
		importoLordo nullable: true
		imposta nullable: true
		daMeseRuco nullable: true
		aMeseRuco nullable: true
		daMeseSgra nullable: true
		aMeseSgra nullable: true
		tipoSgravio nullable: true, maxSize: 1
		giorniRuolo nullable: true
		giorniSgravio nullable: true
	}
}
