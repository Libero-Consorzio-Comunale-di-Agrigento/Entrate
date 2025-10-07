package it.finmatica.tr4.commons;


enum NaturaOccupazione {
    NESSUNO(0, "Vuoto"),
    SINGOLO(1, "Per singolo"),
    NUCLEO(2, "Per nucleo familiare"),
    COMMERCIALE(3, "Presenza di attività commerciali"),
    ALTRO(4, "Altra tipologia di occupazione")


    private final int id
    private final String descrizione

    NaturaOccupazione(int naturaOccupazione, String descrizione) {
        this.descrizione = descrizione
        this.id = naturaOccupazione
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
