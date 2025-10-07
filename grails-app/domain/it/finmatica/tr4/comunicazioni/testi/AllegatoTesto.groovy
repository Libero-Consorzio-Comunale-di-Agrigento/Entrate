package it.finmatica.tr4.comunicazioni.testi

import it.finmatica.ad4.autenticazione.Ad4Utente

class AllegatoTesto implements Serializable {

    ComunicazioneTesti comunicazioneTesti
    Short sequenza
    String descrizione
    String nomeFile
    byte[] documento
    Ad4Utente utente
    Date dataVariazione
    String note

    def springSecurityService
    static transients = [
            'springSecurityService',
    ]

    static mapping = {
        id composite: ['comunicazioneTesti', 'sequenza']
        comunicazioneTesti column: "comunicazione_testo"
        utente column: "utente"

        table "allegati_testo"
        version false
    }

    static constraints = {
        descrizione nullable: true, maxSize: 100
        nomeFile maxSize: 255
        documento nullable: false
        utente nullable: true, maxSize: 8
        dataVariazione nullable: true
        note nullable: true, maxSize: 2000
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser
        dataVariazione = new Date()
        this.descrizione = this.descrizione?.toUpperCase()
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser
        dataVariazione = new Date()
        this.descrizione = this.descrizione?.toUpperCase()
    }

}
