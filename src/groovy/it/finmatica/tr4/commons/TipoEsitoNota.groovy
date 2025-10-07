package it.finmatica.tr4.commons;



public enum TipoEsitoNota {
	
	REGISTRATA (1, "nota registrata in atti"),
	PARZIALE (2, "nota registrata parzialmente"),
	NON_REGISTRATA (3, "nota non registrata")
	
	private final int id
	private final String descrizione
	
	public TipoEsitoNota(int tipoEsitoNota, String descrizione) {
		this.descrizione	= descrizione
		this.id = tipoEsitoNota
	}
	
	public String getTipoEsitoNota() {
		return this.id
	}
	
	public String getDescrizione() {
		return this.descrizione
	}
}