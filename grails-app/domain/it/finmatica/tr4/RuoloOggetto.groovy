package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RuoloOggetto implements Serializable {

	Ruolo ruolo
	RuoloContribuente ruoloContribuente
	PraticaTributo pratica
	Short annoRuolo
	TipoTributo tipoTributo
	CodiceTributo codiceTributo
	BigDecimal consistenza
	BigDecimal importo
	Short semestri
	Date decorrenzaInteressi
	Short mesiRuolo
	Date dataCartella
	String numeroCartella
	Ad4Utente	utente
	Date lastUpdated
	String note
	Oggetto oggetto
	OggettoPratica oggettoPratica
	Short categoria
	Short tipoTariffa
	OggettoImposta oggettoImposta
	BigDecimal imposta
	BigDecimal addizionaleEca
	BigDecimal maggiorazioneEca
	BigDecimal addizionalePro
	BigDecimal iva
	BigDecimal maggiorazioneTares
	boolean importoLordo
	Short daMese
	Short aMese
	Short giorniRuolo
	String codFiscale
	
	static mapping = {
		id composite: ["ruoloContribuente"]
		
		ruoloContribuente {
			column name: "ruolo_contribuente"
			column name: "cod_fiscale"
			column name: "sequenza"
		}
		ruolo			column: "ruolo"
		pratica			column: "pratica"
		tipoTributo		column: "tipo_tributo"
		codiceTributo	column: "tributo"
		oggettoPratica	column: "oggetto_pratica"
		oggettoImposta	column: "oggetto_imposta"
		oggetto			column: "oggetto"
		decorrenzaInteressi	sqlType:'Date'
		dataCartella		sqlType:'Date'
		lastUpdated			column: "data_variazione", sqlType:'Date'
		importoLordo		type: SiNoType
		utente column: "utente", ignoreNotFound: true
		table "web_ruoli_oggetto"
		version false
		codFiscale updateable: false, insertable: false
	}
	
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append ruoloContribuente.ruolo.id
		builder.append ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append ruoloContribuente.ruolo.id, other.ruoloContribuente.ruolo.id
		builder.append ruoloContribuente.contribuente.codFiscale, other.ruoloContribuente.contribuente.codFiscale
		builder.append ruoloContribuente.sequenza, other.ruoloContribuente.sequenza
		
		builder.isEquals()
	}

	

	static constraints = {
		pratica nullable: true
		annoRuolo nullable: true
		tipoTributo nullable: true, maxSize: 5
		codiceTributo nullable: true
		consistenza nullable: true
		importo nullable: true
		semestri nullable: true
		decorrenzaInteressi nullable: true
		mesiRuolo nullable: true
		dataCartella nullable: true
		numeroCartella nullable: true, maxSize: 20
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		oggetto nullable: true
		oggettoPratica nullable: true
		categoria nullable: true
		tipoTariffa nullable: true
		oggettoImposta nullable: true
		imposta nullable: true
		addizionaleEca nullable: true
		maggiorazioneEca nullable: true
		addizionalePro nullable: true
		iva nullable: true
		maggiorazioneTares nullable: true
		importoLordo nullable: true, maxSize: 1
		daMese nullable: true
		aMese nullable: true
		giorniRuolo nullable: true
	}
}
