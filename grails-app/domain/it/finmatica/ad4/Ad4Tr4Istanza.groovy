package it.finmatica.ad4

class Ad4Tr4Istanza implements Serializable {

    String id
    // String progetto
    // String ente
    // String descrizione
    String userOracle
    // String passwordOracle
    // String dislocazione
    // String dislocazioneTemporanea
    // String installazione
    // String versione
    // String dislocazioneDimensionamenti
    // String note
    // String lingua
    // String linkOracle
    // String servizio
    // String databaseLink
    // String databaseDriver
    // String istanzaAmministratore

    static hasMany = [dirittiAccesso: Ad4Tr4DirittoAccesso]


    static mapping = {
        id column: 'istanza', generator: 'assigned'

        // dislocazioneTemporanea column: "DISLOCAZIONE_TEMPORANEA"
        // dislocazioneDimensionamenti column: "DISLOCAZIONE_DIMENSIONAMENTI"

        table "AD4_ISTANZE"
        version false
    }

    static constraints = {


        // istanza nullable: false
        /*progetto nullable: false
        ente nullable: false
        descrizione nullable: false
        userOracle nullable: false
        passwordOracle nullable: false
        dislocazione nullable: false*/

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
