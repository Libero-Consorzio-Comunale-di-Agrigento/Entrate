package it.finmatica.tr4.commons;



 enum DestinazioneUso {
	NESSUNO 		(0, "Vuoto"),
	ABITATIVO 		(1, "Per uso abitativo"),                
	DISPOSIZIONE	(2, "Per immobile tenuto a disposizione"), 
    COMMERCIALE 	(3, "Per uso commerciale"),                
    BOX		 		(4, "Per locali adibiti a box"),           
	ALTRO           (5, "Per altri usi")                     
	
	private final int id
	private final String descrizione
	
	 DestinazioneUso(int destinazioneUso, String descrizione) {
		this.descrizione	= descrizione
		this.id = destinazioneUso
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
