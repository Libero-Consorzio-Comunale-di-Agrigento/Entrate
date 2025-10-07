package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

import java.sql.Clob

class Trasmissione implements Serializable {

    long idDocumento
    String nomeFile
    Clob clobFile
    String utente
    Date dataVariazione
    String direzione
    String hash

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append idDocumento
        builder.append hash
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append idDocumento, other.idDocumento
        builder.append hash, other.hash
        builder.isEquals()
    }

    static mapping = {
        id name: "idDocumento", generator: "assigned"
        nomeFile column: "nome_file"
        clobFile column: "clob_file", sqlType: 'Clob'
        utente column: "utente"
        dataVariazione column: "data_variazione", sqlType: 'Date'
        direzione column: "direzione"
        hash column: "hash"

        table name: "ftp_trasmissioni"
        version false
    }

    static constraints = {
		nomeFile maxSize: 100
        utente maxSize: 8
        direzione maxSize: 1
        hash maxSize: 256
    }
}
