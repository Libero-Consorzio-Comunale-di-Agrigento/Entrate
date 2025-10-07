package it.finmatica.tr4

class WrkDocfaCausali {

    String causale
    String descrizione

    static mapping = {
        id name: "causale", generator: "assigned"
        table "wrk_docfa_causali"
        version false
    }
}
