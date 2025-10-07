package it.finmatica.ad4

class Ad4Tr4DirittoAccesso implements Serializable {

    Long dirittoAccesso
    Ad4Tr4Utente tr4Utente
    Ad4Tr4Istanza tr4Istanza
    // String modulo
    // String ruolo
    // Long sequenza
    // Date ultimoAccesso
    // Integer numeroAccessi
    // String gruppo
    // String note

    static mapping = {

        id name: "dirittoAccesso", generator: "assigned"

        // ultimoAccesso column: "ULTIMO_ACCESSO"
        // numeroAccessi column: "NUMERO_ACCESSI"

        tr4Utente column: "UTENTE"
        tr4Istanza column: "ISTANZA"

        table "TR4_AD4_DIRITTO_ACCESSO"
        version false
    }

    static constraints = {

    }

    /*
    int hashCode() {

        def builder = new HashCodeBuilder()
        builder.append anno
        builder.append tipoAliquota.tipoAliquota
        builder.append tipoAliquota.tipoTributo.tipoTributo
        builder.toHashCode()

    }
    */

    /*
       boolean equals(other) {

           if (other == null) return false
           def builder = new EqualsBuilder()
           builder.append anno, other.anno
           builder.append tipoAliquota.tipoAliquota, other.tipoAliquota.tipoAliquota
           builder.append tipoAliquota.tipoTributo.tipoTributo, other.tipoAliquota.tipoTributo.tipoTributo
           builder.isEquals()

           return false
       }
   */
}
