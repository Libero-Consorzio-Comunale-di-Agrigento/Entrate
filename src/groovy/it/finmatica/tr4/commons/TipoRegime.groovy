package it.finmatica.tr4.commons;



public enum TipoRegime {
	
	C ("C", "bene in comunione legale"),
	P ("P", "bene Personale"),
	S ("S", "bene in regime di Separazione"),
	D ("D", "bene in comunione De Residuo")
	
	private final String id
	private final String descrizione
	
	public TipoRegime(String tipoRegime, String descrizione) {
		this.descrizione	= descrizione
		this.id = tipoRegime
	}
	
	public String getTipoRegime() {
		return this.id
	}
	
	public String getDescrizione() {
		return this.descrizione
	}
}