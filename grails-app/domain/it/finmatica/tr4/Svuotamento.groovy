package it.finmatica.tr4

class Svuotamento implements Serializable {

    Contribuente contribuente
    String codRfid
    Integer sequenza
    Date dataSvuotamento
    String gps
    String stato
    BigDecimal latitudine // Use BigDecimal for NUMBER(12,8)
    BigDecimal longitudine // Use BigDecimal for NUMBER(12,8)
    Integer quantita // Use Integer for NUMBER(6,0)
    Long documentoId // Use Long for NUMBER(10)
    String utente
    Date dataVariazione
    String note

    static belongsTo = [oggetto: Oggetto]

    static mapping = {
        id composite: ['contribuente', 'oggetto', 'codRfid', 'sequenza']
        oggetto column: 'oggetto'
        contribuente column: 'cod_fiscale'
        table 'SVUOTAMENTI'
        version false
    }

    static constraints = {
        oggetto nullable: false
        codRfid maxSize: 100, blank: false, nullable: false
        sequenza nullable: false
        dataSvuotamento nullable: false
        gps nullable: true
        stato nullable: true
        latitudine nullable: true
        longitudine nullable: true
        quantita nullable: true
        documentoId nullable: true
        utente nullable: true
        dataVariazione nullable: true
        note nullable: true
    }

    def springSecurityService
    static transients = ['springSecurityService']

    def beforeInsert() {
        utente = utente ?: springSecurityService?.currentUser?.id
    }

    def beforeUpdate() {
        utente = springSecurityService?.currentUser?.id
    }
}
