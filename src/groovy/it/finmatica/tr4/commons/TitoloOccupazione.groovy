package it.finmatica.tr4.commons;



enum TitoloOccupazione {
	NESSUNO (0, "Vuoto"),
	PROPRIETA (1, "Proprietà"),
	USUFRUTTO (2, "Usufrutto"), 
    LOCATARIO (3, "Locatario"),
    ALTRO (4, "Altro diritto reale")
	
	
	private final int id
	private final String descrizione

	TitoloOccupazione(int titoloOccupazione, String descrizione) {
		this.descrizione	= descrizione
		this.id = titoloOccupazione
	}

	int getId() {
		return this.id
	}

	String getDescrizione() {
		return this.descrizione
	}

	static def getById(int id) {
		def element = null

		for (e in values()) {
			if (e.id == id) {
				element = e
				break
			}
		}

		return element
	}

}
