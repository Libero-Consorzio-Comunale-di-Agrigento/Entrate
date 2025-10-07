package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class UtilizzoOggetto implements Serializable, Comparable<UtilizzoOggetto> {

    TipoTributo tipoTributo
    short anno
    TipoUtilizzo tipoUtilizzo
    Integer sequenza
    Soggetto soggetto
    Byte mesiAffitto
    Date dataScadenza
    String intestatario
    Ad4Utente utente
    Date lastUpdated
    String note
    Date dal
    Date al
    TipoUso tipoUso

    static belongsTo = [oggetto: Oggetto]

    //static hasMany = [tipiUso: TipoUso]

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append oggetto
        builder.append tipoTributo
        builder.append anno
        builder.append tipoUtilizzo
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append oggetto, other.oggetto
        builder.append tipoTributo, other.tipoTributo
        builder.append anno, other.anno
        builder.append tipoUtilizzo, other.tipoUtilizzo
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
        id composite: ["oggetto", "tipoTributo", "anno", "tipoUtilizzo", "sequenza"]

        oggetto column: "oggetto"
        tipoTributo column: "tipo_tributo"
        tipoUtilizzo column: "tipo_utilizzo"
        soggetto column: "ni"
        tipoUso column: "tipo_uso"
        dataScadenza sqlType: 'Date'
        dal sqlType: 'Date'
        al sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        utente column: "utente", ignoreNotFound: true
        table "utilizzi_oggetto"
        version false
    }

    static constraints = {
        sequenza nullable: true
        tipoTributo maxSize: 5
        soggetto nullable: true
        mesiAffitto nullable: true
        dataScadenza nullable: true
        intestatario nullable: true, maxSize: 60
        tipoUso nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        dal nullable: true
        al nullable: true
        lastUpdated nullable: true
    }

    def springSecurityService
    static transients = ['springSecurityService']

    def beforeValidate() {
        utente = springSecurityService.currentUser
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser
    }

    int compareTo(UtilizzoOggetto obj) {
        oggetto?.id <=> obj?.oggetto?.id ?:
                tipoTributo?.tipoTributo <=> obj?.tipoTributo.tipoTributo ?:
                        tipoUtilizzo?.id <=> obj?.tipoUtilizzo.id ?:
                                anno <=> obj?.anno ?:
                                        sequenza <=> obj?.sequenza
    }
}
