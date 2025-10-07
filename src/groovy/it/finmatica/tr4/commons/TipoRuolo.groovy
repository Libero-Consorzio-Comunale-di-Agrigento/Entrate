package it.finmatica.tr4.commons;

public enum TipoRuolo {

	PRINCIPALE(1, "Principale"),
	SUPPLETTIVO(2, "Supplettivo"),
	
	private final Integer id
	private final String descrizione

	public TipoRuolo(Integer tipoRuolo, String descrizione) {
		this.id = tipoRuolo
		this.descrizione = descrizione
	}

	public Integer getTipoRuolo() {
		return this.id
	}

	public String getDescrizione() {
		return this.descrizione
	}
}

