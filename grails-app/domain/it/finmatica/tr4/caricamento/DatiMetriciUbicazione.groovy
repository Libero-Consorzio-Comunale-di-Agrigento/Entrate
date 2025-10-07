package it.finmatica.tr4.caricamento

class DatiMetriciUbicazione implements Serializable {
    String lotto
    String edificio
    String scala
    String interno1
    String interno2
    String piano1
    String piano2
    String piano3
    String piano4

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "ubicazioni_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_ubicazioni"
    }

    static constraints = {
        lotto nullable: true
        edificio nullable: true
        scala nullable: true
        interno1 nullable: true
        interno2 nullable: true
        piano1 nullable: true
        piano2 nullable: true
        piano3 nullable: true
        piano4 nullable: true
    }
}
