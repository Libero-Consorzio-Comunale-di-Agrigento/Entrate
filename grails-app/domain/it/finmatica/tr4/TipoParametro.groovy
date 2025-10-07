package it.finmatica.tr4

class TipoParametro {

    String id
    String descrizione
    String applicativo

    static hasMany = [
            parametriUtente: ParametroUtente
    ]

    static mapping = {
        id column: "tipo_parametro", generator: "assigned"

        version false
        table "tipi_parametro"
    }

    def beforeValidate() {
        applicativo = applicativo ?: 'WEB'
    }
}
