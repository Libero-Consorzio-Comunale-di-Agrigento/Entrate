package it.finmatica.tr4

class SpesaNotifica implements Serializable {

    TipoTributo tipoTributo
    Short sequenza
    String descrizione
    String descrizioneBreve
    BigDecimal importo
    TipoNotifica tipoNotifica

    static mapping = {
        id composite: ["tipoTributo", "sequenza"]
        tipoTributo column: 'tipo_tributo'
        tipoNotifica column: 'tipo_notifica'
        table 'spese_notifica'
        version false
    }

    static constraints = {
        descrizione maxSize: 200
        descrizioneBreve maxSize: 40
        tipoNotifica nullable: true
    }
}
