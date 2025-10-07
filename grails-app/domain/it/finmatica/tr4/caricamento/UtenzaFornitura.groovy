package it.finmatica.tr4.caricamento

class UtenzaFornitura implements Serializable {

    Integer documentoId

    String identificativo
    Short progressivo
    Date data

    static hasMany = [
            utenzeDati: UtenzaDatiFornitura
    ]

    static mapping = {
        id column: "forniture_id"

        version false

        table "utenze_forniture"
    }

    static constraints = {
        data nullable: true
    }
}