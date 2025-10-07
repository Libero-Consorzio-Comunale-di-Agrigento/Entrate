package it.finmatica.tr4

class CodiceTributo {

    String descrizione
    String descrizioneRuolo
    Integer contoCorrente
    String descrizioneCc
    String flagStampaCc
    String flagRuolo
    String flagCalcoloInteressi
    String codEntrata
    String gruppoTributo

    TipoTributo tipoTributo
    TipoTributo tipoTributoPrec

    static hasMany = [categorie: Categoria]

    static mapping = {
        id column: "tributo", generator: "assigned"
        tipoTributo column: "tipo_tributo"
        tipoTributoPrec column: "tipo_tributo_prec"

        table "codici_tributo"
        version false
    }

    static constraints = {
        descrizione maxSize: 60
        descrizioneRuolo nullable: true, maxSize: 100
        tipoTributo nullable: true, maxSize: 5
        tipoTributoPrec nullable: true, maxSize: 5
        contoCorrente nullable: true
        descrizioneCc nullable: true, maxSize: 100
        flagStampaCc nullable: true, maxSize: 1
        flagRuolo nullable: true, maxSize: 1
        flagCalcoloInteressi nullable: true, maxSize: 1
        codEntrata nullable: true, maxSize: 4
        gruppoTributo nullable: true, maxSize: 10
    }
}
