package it.finmatica.tr4.commons


enum TipoEventoDenuncia {

    A("A", "Automatico"),
    R("R", "Rendita"),
    T("T", "Totale"),
    I("I", "Iscrizione"),
    V("V", "Variazione"),
    C("C", "Cessazione"),
    U("U", "Unico"),
    S("S", "Saldo"),
    R0("0", "Rata Unica"),
    R1("1", "Rata 1"),
    R2("2", "Rata 2"),
    R3("3", "Rata 3"),
    R4("4", "Rata 4")


    private final String id
    private final String descrizione

    TipoEventoDenuncia(String tipoEventoDenuncia, String descrizione) {
        this.descrizione = descrizione
        this.id = tipoEventoDenuncia
    }

    String getTipoEventoDenuncia() {
        return this.id
    }

    String getDescrizione() {
        return this.descrizione
    }

    String getId() {
        return this.id
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

