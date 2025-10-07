package it.finmatica.tr4.commons;


enum AssenzaEstremiCatasto {
    NESSUNO(0, "Vuoto"),
    NON_ACCATASTATO(1, "Immobile non accatastato"),
    NON_ACCATASTABILE(2, "Immobile non accatastabile"),
    ALTRO(3, "Dati non disponibili per la comunicazione corrente")


    private final int id
    private final String descrizione

    AssenzaEstremiCatasto(int assenzaEstremiCatasto, String descrizione) {
        this.descrizione = descrizione
        this.id = assenzaEstremiCatasto
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
