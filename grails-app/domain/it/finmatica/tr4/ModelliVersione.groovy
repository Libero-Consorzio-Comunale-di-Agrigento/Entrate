package it.finmatica.tr4

class ModelliVersione implements Serializable {

    Integer versione
    byte[] documento
    String utente
    String note
    Date dataVariazione

    def springSecurityService

    static transients = ['springSecurityService']

    static belongsTo = [modello: Modelli]

    static mapping = {
        id column: "versione_id"
        modello column: "modello"

        version false

        table "modelli_versione"
    }

    static constraints = {
        versione nullable: true
        documento nullable: true
        utente nullable: true
        dataVariazione nullable: true
    }

    def beforeInsert() {
        utente = springSecurityService?.currentUser?.id ?: 'TR4'
        dataVariazione = new Date()
    }
}
