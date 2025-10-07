package it.finmatica.tr4.commons

public enum TipoIntervento {
	OGGETTO ("OGGETTO", "Oggetto"),
	PRATICA ("PRATICA", "Pratica")
	
	private final String id
	private final String descrizione
	
	public TipoIntervento(String tipoIntervento, String descrizione) {
		this.id = tipoIntervento
		this.descrizione	= descrizione
	}
	
	public String getTipoIntervento() {
		return this.id
	}
	
}
