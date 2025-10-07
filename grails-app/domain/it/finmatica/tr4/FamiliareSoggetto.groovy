package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

import java.text.SimpleDateFormat

class FamiliareSoggetto implements Serializable {

    Soggetto soggetto
    Short anno
    Date dal
    Date al
    // TODO: convert lastUpdated name to dataVariazione
    Date lastUpdated
    Short numeroFamiliari
    String note

    static mapping = {
        id composite: ["soggetto", "anno", "dal"]
        soggetto column: "ni"
        table 'familiari_soggetto'
        version false
        autoTimestamp false
        dal sqlType: 'Date'
        al sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
    }

    static constraints = {
        al nullable: true
        note nullable: true, maxSize: 2000
    }

    def beforeInsert() {
        SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy")
        lastUpdated = formatter.parse(formatter.format(lastUpdated))
    }

    def beforeUpdate() {
        SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy")
        lastUpdated = formatter.parse(formatter.format(lastUpdated))
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append id
        builder.append anno
        builder.append dal
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append id, other.id
        builder.append anno, other.anno
        builder.append dal, other.dal
        builder.isEquals()
    }
}
