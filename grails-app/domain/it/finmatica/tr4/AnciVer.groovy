package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AnciVer implements Serializable {

    Contribuente contribuente
    Integer progrRecord
    Short annoFiscale
    Short concessione
    String ente
    Long progrQuietanza
    String tipoRecord
    Date dataVersamento
    String codFiscale
    String quietanza
    Long importoVersato
    Long terreniAgricoli
    Long areeFabbricabili
    Long abPrincipale
    Long altriFabbricati
    Integer detrazione
    String flagQuadratura
    String flagSquadratura
    Integer detrazioneEffettiva
    Long impostaCalcolata
    Integer tipoVersamento
    Integer dataReg
    String flagCompetenzaVer
    String comune
    String codCatasto
    Integer cap
    Short fabbricati
    String accontoSaldo
    String flagExRurali
    String flagZero
    Boolean flagIdentificazione
    Byte tipoAnomalia
    Long imposta
    Long sanzioni1
    Long sanzioni2
    Long interessi
    Short annoImposta
    Integer numProvvedimento
    Date dataProvvedimento
    Boolean flagRavvedimento
    String flagContribuente
    String sanzioneRavvedimento
    Byte fonte
    String flagOk

    Short annoFiscaleModificato

    static transients = ['annoFiscaleModificato']

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append progrRecord
        builder.append annoFiscale
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append progrRecord, other.progrRecord
        builder.append annoFiscale, other.annoFiscale
        builder.isEquals()
    }

    static mapping = {
        id composite: ["progrRecord", "annoFiscale"]

        dataVersamento sqlType: 'Date'
        dataProvvedimento sqlType: 'Date'
        contribuente column: "cod_fiscale", updateable: false, insertable: false

        version false
        sanzioni1 column: "SANZIONI_1"
        sanzioni2 column: "SANZIONI_2"
    }

    static constraints = {
        concessione nullable: true
        ente nullable: true, maxSize: 4
        progrQuietanza nullable: true
        tipoRecord maxSize: 1
        dataVersamento nullable: true
        codFiscale nullable: true, maxSize: 16
        quietanza nullable: true, maxSize: 11
        importoVersato nullable: true
        terreniAgricoli nullable: true
        areeFabbricabili nullable: true
        abPrincipale nullable: true
        altriFabbricati nullable: true
        detrazione nullable: true
        flagQuadratura nullable: true, maxSize: 1
        flagSquadratura nullable: true, maxSize: 1
        detrazioneEffettiva nullable: true
        impostaCalcolata nullable: true
        tipoVersamento nullable: true
        dataReg nullable: true
        flagCompetenzaVer nullable: true, maxSize: 1
        comune nullable: true, maxSize: 25
        codCatasto nullable: true, maxSize: 4
        cap nullable: true
        fabbricati nullable: true
        accontoSaldo nullable: true, maxSize: 1
        flagExRurali nullable: true, maxSize: 1
        flagZero nullable: true, maxSize: 35
        flagIdentificazione nullable: true
        tipoAnomalia nullable: true
        imposta nullable: true
        sanzioni1 nullable: true
        sanzioni2 nullable: true
        interessi nullable: true
        annoImposta nullable: true
        numProvvedimento nullable: true
        dataProvvedimento nullable: true
        flagRavvedimento nullable: true
        flagContribuente nullable: true, maxSize: 1
        sanzioneRavvedimento nullable: true, maxSize: 1
        fonte nullable: true
        flagOk nullable: true
    }
}
