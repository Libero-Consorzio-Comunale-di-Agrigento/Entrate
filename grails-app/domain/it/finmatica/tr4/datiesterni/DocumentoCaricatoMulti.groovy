package it.finmatica.tr4.datiesterni

import it.finmatica.ad4.autenticazione.Ad4Utente

class DocumentoCaricatoMulti {

    String nomeDocumento
    byte[] contenuto
    String nomeDocumento2
    byte[] contenuto2
    Ad4Utente utente
    Date lastUpdated
    String note

    static belongsTo = [documentoCaricato: DocumentoCaricato]

    static mapping = {
        id column: 'documento_multi_id'
        version false
        utente column: "utente"
        nomeDocumento2 column: "nome_documento_2"
        contenuto2 column: "contenuto_2", sqlType: 'Blob'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        documentoCaricato column: "documento_id"
        contenuto sqlType: 'Blob'

        table 'documenti_caricati_multi'
    }

    static constraints = {
        nomeDocumento nullable: true
        contenuto nullable: true
        nomeDocumento2 nullable: true
        contenuto2 nullable: true
        utente nullable: true, maxSize: 8
        lastUpdated nullable: true
        note nullable: true, maxSize: 2000
    }

    def springSecurityService
    static transients = ['springSecurityService']

    def beforeValidate() {
        utente = springSecurityService.currentUser
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser
    }
}
