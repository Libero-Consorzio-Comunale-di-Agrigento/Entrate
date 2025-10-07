package it.finmatica.tr4.pratiche

import it.finmatica.tr4.tipi.SiNoType

class RataPratica implements Serializable {

    // Pratica
    Byte rata
    Date dataScadenza
    Integer anno
    String tributoCapitaleF24
    BigDecimal importoCapitale
    String tributoInteressiF24
    BigDecimal importoInteressi
    BigDecimal residuoCapitale
    BigDecimal residuoInteressi
    String note
    String utente
    Date dataVariazione
	
	Short giorniAggio
	Double aliquotaAggio
	BigDecimal aggio
	BigDecimal aggioRimodulato
	Short giorniDilazione
	Double aliquotaDilazione
	BigDecimal dilazione
	BigDecimal dilazioneRimodulata
	
	BigDecimal oneri
	BigDecimal importo
	BigDecimal importoArr

    BigDecimal quotaTassa
    BigDecimal quotaTefa

    Boolean flagSospFerie
	
    static hasOne = [pratica: PraticaTributo]

    static mapping = {
        id column: "rata_pratica"
        pratica column: "pratica"
        tributoCapitaleF24 column: "tributo_capitale_f24"
        tributoInteressiF24 column: "tributo_interessi_f24"
        flagSospFerie type: SiNoType

        version false

        table "rate_pratica"
    }

    static constraints = {
        tributoCapitaleF24 maxSize: 4, nullable: true
        tributoInteressiF24 maxSize: 4, nullable: true
        residuoCapitale nullable: true
        residuoInteressi nullable: true
        note nullable: true
        giorniAggio nullable: true, maxSize: 4
        aliquotaAggio nullable: true
        aggio nullable: true
        aggioRimodulato nullable: true
        giorniDilazione nullable: true, maxSize: 4
        aliquotaDilazione nullable: true
        dilazione nullable: true
		dilazioneRimodulata nullable : true
		oneri nullable : true
		importo nullable : true
		importoArr nullable : true
        quotaTassa nullable : true
        quotaTefa nullable : true
	}
}
