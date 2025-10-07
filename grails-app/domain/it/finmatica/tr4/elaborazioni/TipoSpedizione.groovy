package it.finmatica.tr4.elaborazioni

class TipoSpedizione {

    String tipoSpedizione
    String descrizione

    static mapping = {
        id name: "tipoSpedizione", generator: "assigned"

        table "tipi_spedizione"
        version false
    }
}
