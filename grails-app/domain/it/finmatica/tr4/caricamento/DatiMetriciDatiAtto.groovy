package it.finmatica.tr4.caricamento

class DatiMetriciDatiAtto implements Serializable {

    String sedeRogante
    Date data
    Integer numeroRepertorio
    Integer raccoltaRepertorio

    static belongsTo = [soggetto: DatiMetriciSoggetto]

    static mapping = {
        id column: "dati_atto_id"
        soggetto column: "soggetti_id"

        version false

        table "dati_metrici_dati_atto"
    }

    static constraints = {
        sedeRogante nullable: true
        data nullable: true
        numeroRepertorio nullable: true
        raccoltaRepertorio nullable: true
    }
}
