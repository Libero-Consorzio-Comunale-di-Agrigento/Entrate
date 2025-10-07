package it.finmatica.tr4

class Modelli {

    Long modello
    String tipoTributo
    String descrizione
    String path
    String nomeDw
    String flagSottomodello
    String codiceSottomodello
    String flagEditabile
    String flagStandard
    String dbFunction
    String flagF24
    String flagAvvisoAgid
    String flagWeb
    String flagEredi

    static hasOne = [tipoModello: TipiModello]
    static hasMany = [versioni: ModelliVersione]

    static mapping = {
        id name: "modello", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "MODELLI_NR"]
        tipoModello column: "descrizione_ord", ignoreNotFound: true
        flagF24 column: "FLAG_F24"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        descrizione maxSize: 60
        path nullable: true, maxSize: 200
        flagSottomodello nullable: true
        flagStandard nullable: true
        flagEditabile nullable: true
        codiceSottomodello nullable: true
        nomeDw nullable: true, maxSize: 60
        dbFunction nullable: true
        flagF24 nullable: true
        flagAvvisoAgid nullable: true
        flagWeb nullable: true
        flagEredi nullable: true
    }
}
