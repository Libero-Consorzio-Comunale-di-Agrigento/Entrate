package it.finmatica.tr4

class TipiExport implements Serializable {

	String descrizione
	String nomeProcedura
	String flagStandard
	String tabellaTemporanea
	String nomeFile
	BigDecimal annoTrasAnci
	Integer ordinamento
	String windowStampa
	String tipoTributo
	String windowControllo
	String prefissoNomeFile
	String suffissoNomeFile
	String estensioneNomeFile
	String flagClob
	SortedSet<ParametriExport> parametriExport

	static hasMany = [parametriExport: ParametriExport]

	static mapping = {
		id column: "TIPO_EXPORT", generator: "assigned"
		version false
	}

	static constraints = {
		descrizione maxSize: 100
		nomeProcedura maxSize: 100
		flagStandard nullable: true, maxSize: 1
		tabellaTemporanea nullable: true, maxSize: 100
		nomeFile nullable: true, maxSize: 100
		annoTrasAnci nullable: true
		ordinamento nullable: true
		windowStampa nullable: true, maxSize: 100
		tipoTributo nullable: true, maxSize: 5
		windowControllo nullable: true, maxSize: 100
		prefissoNomeFile nullable: true, maxSize: 20
		suffissoNomeFile nullable: true, maxSize: 20
		estensioneNomeFile nullable: true, maxSize: 100
	}
}
