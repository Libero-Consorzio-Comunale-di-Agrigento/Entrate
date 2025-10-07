package it.finmatica.tr4.anomalie

import it.finmatica.tr4.TipoTributo

class Causale implements Serializable {

    TipoTributo tipoTributo
    String causale
    String descrizione

    static mapping = {
        id composite: ["tipoTributo", "causale"]

        tipoTributo column: "tipo_tributo"
        causale column: "causale"

        table "causali"
        version false
    }
}
