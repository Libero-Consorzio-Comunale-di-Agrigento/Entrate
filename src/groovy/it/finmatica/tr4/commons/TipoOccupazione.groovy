package it.finmatica.tr4.commons;


 enum TipoOccupazione {

    P("P", "Permanente"),
    T("T", "Temporanea")

    private final String id
    private final String descrizione

     TipoOccupazione(String tipoOccupazione, String descrizione) {
        this.descrizione = descrizione
        this.id = tipoOccupazione
    }

     String getTipoOccupazione() {
        return this.id
    }

     String getDescrizione() {
        return this.descrizione
    }

    static def getById(String id) {
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
