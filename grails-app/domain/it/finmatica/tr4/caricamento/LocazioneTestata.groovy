package it.finmatica.tr4.caricamento

class LocazioneTestata implements Serializable {

    Integer documentoId

    String intestazione
    Date dataFile
    Short anno

    static hasMany = [
            locazioniContratti: LocazioneContratto
    ]

    static mapping = {
        id column: "testate_id"

        version false

        table "locazioni_testate"
    }

    static constraints = {
        intestazione nullable: true
        dataFile nullable: true
        anno nullable: true
    }
}
