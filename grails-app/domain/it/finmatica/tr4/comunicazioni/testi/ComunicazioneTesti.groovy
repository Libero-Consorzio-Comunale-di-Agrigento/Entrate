package it.finmatica.tr4.comunicazioni.testi


import it.finmatica.tr4.comunicazioni.TipiCanale

class ComunicazioneTesti {

    String tipoTributo
    String tipoComunicazione
    TipiCanale tipoCanale
    String descrizione
    String oggetto
    String testo
    String utente
    Date dataVariazione
    String note

    static hasMany = [allegatiTesto: AllegatoTesto]

    def springSecurityService
    static transients = [
            'springSecurityService',
    ]

    static mapping = {
        id column: "comunicazione_testo", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "COMUNICAZIONE_TESTI_NR"]
        tipoCanale column: "tipo_canale"

        table "comunicazione_testi"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        tipoComunicazione maxSize: 3
        descrizione nullable: true, maxSize: 200
        oggetto nullable: true, maxSize: 200
        utente nullable: true, maxSize: 8
        dataVariazione nullable: true
        note nullable: true, maxSize: 2000
    }

    // Gorm eventListener
    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
        this.descrizione = this.descrizione?.toUpperCase()
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser?.id
        this.descrizione = this.descrizione?.toUpperCase()
    }

}
