package it.finmatica.tr4.caricamento

class DatiMetriciIdentificativi implements Serializable {

    String sezione
    String foglio
    String numero
    String denominatore
    String subalterno
    String edificialita

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "identificativi_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_identificativi"
    }

    static constraints = {
        sezione nullable: true
        foglio nullable: true
        numero nullable: true
        denominatore nullable: true
        subalterno nullable: true
        edificialita nullable: true
    }
}
