package it.finmatica.tr4

class Anadce {

    String descrizione
    String tipoEvento
    String anagrafe

    static mapping = {
        id column: "cod_ev", generator: "assigned"
        tipoEvento column: "tipo_evento"

        table "web_anadce"

        version false
    }

    static constraints = {
        descrizione nullable: true
        tipoEvento nullable: true
        anagrafe nullable: true
    }
}
