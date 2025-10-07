package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class TipoNotifica {

    Long tipoNotifica
    String descrizione
    Boolean flagModificabile

    static mapping = {
        id name: 'tipoNotifica', generator: "assigned"

        descrizione column: "descrizione"
        flagModificabile column: "flag_modificabile", type: SiNoType

        table "tipi_notifica"
        version false
    }

    static constraints = {
        descrizione nullable: true, maxSize: 100
        flagModificabile nullable: true
    }
}
