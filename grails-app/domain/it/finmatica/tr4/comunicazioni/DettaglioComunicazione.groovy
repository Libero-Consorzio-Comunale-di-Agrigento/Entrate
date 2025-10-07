package it.finmatica.tr4.comunicazioni

import it.finmatica.tr4.TipoTributo

class DettaglioComunicazione implements Serializable {

    TipoTributo tipoTributo
    String tipoComunicazione
    Short sequenza
    String descrizione
    String tipoComunicazionePnd
    String tag
    TipiCanale tipoCanale

    static mapping = {
        id composite: ['tipoTributo', 'tipoComunicazione', 'sequenza']
        tipoTributo column: "tipo_tributo"
        tipoCanale column: "tipo_canale"

        table "dettagli_comunicazione"
        version false
    }

    static constraints = {
        sequenza nullable: true
        descrizione nullable: true, maxSize: 100
        tipoComunicazionePnd nullable: true, maxSize: 30
        tag nullable: true, maxSize: 100
        tipoCanale nullable: true, maxSize: 1
    }

    def beforeInsert() {
        this.descrizione = this.descrizione?.toUpperCase()
    }

    def beforeUpdate() {
        this.descrizione = this.descrizione?.toUpperCase()
    }



}
