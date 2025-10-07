package it.finmatica.tr4

class OggettiIci93 {

	Boolean tipoRendita93
	Boolean tipoBene93
	Boolean esenzione93
	Boolean riduzione93
	Boolean percentuale93
	Boolean conduzione93
	Boolean areaFabbr93

	static mapping = {
		table "OGGETTI_ICI_93"
		id column: "OGGETTO_PRATICA", generator: "assigned"
		version false
		tipoRendita93	column: "TIPO_RENDITA_93"
		tipoBene93      column: "TIPO_BENE_93"
		esenzione93     column: "ESENZIONE_93"
		riduzione93     column: "RIDUZIONE_93"
		percentuale93   column: "PERCENTUALE_93"
		conduzione93    column: "CONDUZIONE_93"
		areaFabbr93     column: "AREA_FABBR_93"
	}                  

	static constraints = {
		tipoRendita93 nullable: true
		tipoBene93 nullable: true
		esenzione93 nullable: true
		riduzione93 nullable: true
		percentuale93 nullable: true
		conduzione93 nullable: true
		areaFabbr93 nullable: true
	}
}
