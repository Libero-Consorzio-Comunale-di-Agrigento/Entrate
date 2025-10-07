package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder

class Sanzione implements Serializable {

    def springSecurityService

    TipoTributo tipoTributo
    Short codSanzione
    String descrizione
    BigDecimal percentuale
    BigDecimal sanzione
    BigDecimal sanzioneMinima
    BigDecimal riduzione
    String flagImposta
    String flagInteressi
    String flagPenaPecuniaria
    GruppiSanzione gruppoSanzione
    Short tributo
    String flagCalcoloInteressi
    BigDecimal riduzione2
    String codTributoF24
    String flagMaggTares
    Short rata
    Short tipologiaRuolo
    String tipoCausale
    String tipoVersamento
    Short sequenza
    Date dataInizio
    Date dataFine
    String utente
    String note
    Date dataVariazione

    static mapping = {
        id composite: ["tipoTributo", "codSanzione", "sequenza"]

        tipoTributo column: "tipo_tributo"
        codTributoF24 column: "cod_tributo_F24"
        gruppoSanzione column: "gruppo_sanzione"
        version false
        riduzione2 column: "RIDUZIONE_2"
        table "sanzioni"
    }

    static constraints = {
        tipoTributo maxSize: 5
        descrizione maxSize: 60
        percentuale nullable: true
        sanzione nullable: true
        sanzioneMinima nullable: true
        riduzione nullable: true
        flagImposta nullable: true, maxSize: 1
        flagInteressi nullable: true, maxSize: 1
        flagPenaPecuniaria nullable: true, maxSize: 1
        gruppoSanzione nullable: true
        tributo nullable: true
        flagCalcoloInteressi nullable: true, maxSize: 1
        riduzione2 nullable: true
        tipoVersamento nullable: true
        codTributoF24 nullable: true
        flagMaggTares nullable: true, maxSize: 1
        rata nullable: true
        tipoCausale nullable: true
        tipologiaRuolo nullable: true
    }

    def beforeValidate() {
        utente = springSecurityService.currentUser?.id
        note = note ?: ''
        dataVariazione = new Date()
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
        note = note ?: ''
        dataVariazione = new Date()
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser?.id
        note = note ?: ''
        dataVariazione = new Date()
    }
}
