package it.finmatica.tr4.anomalie

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.TipoTributo

class AnomaliaParametro {

    Short anno
    TipoAnomalia tipoAnomalia
    BigDecimal scarto
    BigDecimal renditaDa
    BigDecimal renditaA
    String flagImposta
    TipoTributo tipoTributo
    String categorie
    Date dateCreated
    Date lastUpdated
    Ad4Utente utente
    BigDecimal renditaMedia
    BigDecimal renditaMassima
    BigDecimal			valoreMedio
    BigDecimal			valoreMassimo
    boolean locked

    static hasMany = [anomalie: Anomalia]

    static mapping = {
        id column: "id_anomalia_parametro"
        lastUpdated column: "data_variazione", sqlType: 'Date'
        dateCreated column: "data_creazione", sqlType: 'Date'
        flagImposta sqlType: "char", length: 1
        tipoAnomalia column: "id_tipo_anomalia"
        tipoTributo column: "tipo_tributo"
        utente column: "utente", ignoreNotFound: true
        renditaDa column: "rendita_da"
        renditaA column: "rendita_a"

        table 'anomalie_parametri'
    }

    static constraints = {
        scarto nullable: true
        renditaDa nullable: true
        renditaA nullable: true
        categorie nullable: true
        flagImposta nullable: true, maxSize: 1
        renditaMedia nullable: true
        renditaMassima nullable: true
        valoreMedio nullable: true
        valoreMassimo nullable: true
        tipoAnomalia unique: [
                'anno',
                'tipoTributo',
                'flagImposta'
        ]
    }

    def springSecurityService
    static transients = ['springSecurityService']

    def beforeValidate() {
        utente = utente ?: springSecurityService.currentUser
    }

    def beforeInsert() {
        utente = utente ?: springSecurityService.currentUser
    }
}
