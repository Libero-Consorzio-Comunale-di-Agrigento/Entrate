package it.finmatica.tr4.commons;

public enum SpecieRuolo {

	ORDINARIO(false, "Ordinario"),
	COATTIVO(true, "Coattivo"),
	
	private final Boolean id
	private final String descrizione

	public SpecieRuolo(Boolean specieRuolo, String descrizione) {
		this.id = specieRuolo
		this.descrizione = descrizione
	}

	public Boolean getSpecieRuolo() {
		return this.id
	}

	public String getDescrizione() {
		return this.descrizione
	}
}

