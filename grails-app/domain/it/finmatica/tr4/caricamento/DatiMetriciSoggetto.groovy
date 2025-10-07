package it.finmatica.tr4.caricamento


import it.finmatica.tr4.caricamento.DatiMetriciUiu

class DatiMetriciSoggetto implements Serializable {

    Integer idSoggetto
    String tipo
    String cognome
    String nome
    String sesso
    Date dataNascita
    String comune
    String codFiscale
    String denominazione
    String sede

    static belongsTo = [uiu: DatiMetriciUiu]
    static hasMany = [datiAtto: DatiMetriciDatiAtto]

    static mapping = {
        id column: "soggetti_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_soggetti"
    }

    static constraints = {
        tipo nullable: true
        cognome nullable: true
        nome nullable: true
        sesso nullable: true
        dataNascita nullable: true
        comune nullable: true
        codFiscale nullable: true
        denominazione nullable: true
        sede nullable: true
    }
}
