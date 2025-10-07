package it.finmatica.tr4

import it.finmatica.tr4.anomalie.Causale

class WrkVersamenti {

    Contribuente contribuente
    Long progressivo
    TipoTributo tipoTributo
    String tipoIncasso
    Short anno
    Long ruolo
    String codFiscale
    String cognomeNome
    Byte rata
    BigDecimal importoVersato
    Date dataScadenza
    Causale causale
    BigDecimal disposizione
    Date lastUpdated
    String note
    String tipoVersamento
    String ufficioPt
    Date dataPagamento
    BigDecimal abPrincipale
    BigDecimal terreniAgricoli
    BigDecimal areeFabbricabili
    BigDecimal altriFabbricati
    Date dataReg
    BigDecimal detrazione
    Short fabbricati
    String flagContribuente
    String sanzioneRavvedimento
    BigDecimal rurali
    BigDecimal terreniErariale
    BigDecimal areeErariale
    BigDecimal altriErariale
    Short numFabbricatiAb
    Short numFabbricatiRurali
    Short numFabbricatiAltri
    BigDecimal terreniComune
    BigDecimal areeComune
    BigDecimal altriComune
    Short numFabbricatiTerreni
    Short numFabbricatiAree
    BigDecimal fabbricatiD
    BigDecimal fabbricatiDErariale
    BigDecimal fabbricatiDComune
    Short numFabbricatiD
    BigDecimal ruraliErariale
    BigDecimal ruraliComune
    BigDecimal maggiorazioneTares
    Long documentoId
    String identificativoOperazione
    String flagOk
    String noteVersamento

    static mapping = {
        id name: "progressivo", generator: "assigned"
        version false
        fabbricatiD column: "fabbricati_d"
        fabbricatiDErariale column: "fabbricati_d_erariale"
        fabbricatiDComune column: "fabbricati_d_comune"
        numFabbricatiD column: "num_fabbricati_d"
        tipoTributo column: "tipo_tributo", updateable: false, insertable: false
        contribuente column: "cod_fiscale", updateable: false, insertable: false, ignoreNotFound: true

        columns {
            causale {
                column name: "tipo_tributo"
                column name: "causale"
            }
        }

        dataScadenza sqlType: 'Date', column: 'DATA_SCADENZA'
        dataReg sqlType: 'Date', column: 'DATA_REG'
        dataPagamento sqlType: 'Date', column: 'DATA_PAGAMENTO'
        lastUpdated sqlType: 'Date', column: 'DATA_VARIAZIONE'
    }

    static constraints = {
        tipoIncasso maxSize: 10
        anno nullable: true
        ruolo nullable: true
        codFiscale nullable: true, maxSize: 16
        cognomeNome nullable: true, maxSize: 60
        rata nullable: true
        importoVersato nullable: true
        dataScadenza nullable: true
        causale nullable: true
        disposizione nullable: true
        lastUpdated nullable: true
        note nullable: true, maxSize: 2000
        tipoVersamento nullable: true, maxSize: 1
        ufficioPt nullable: true, maxSize: 30
        dataPagamento nullable: true
        abPrincipale nullable: true
        terreniAgricoli nullable: true
        areeFabbricabili nullable: true
        altriFabbricati nullable: true
        dataReg nullable: true
        detrazione nullable: true
        fabbricati nullable: true
        flagContribuente nullable: true, maxSize: 1
        sanzioneRavvedimento nullable: true, maxSize: 1
        rurali nullable: true
        terreniErariale nullable: true
        areeErariale nullable: true
        altriErariale nullable: true
        numFabbricatiAb nullable: true
        numFabbricatiRurali nullable: true
        numFabbricatiAltri nullable: true
        terreniComune nullable: true
        areeComune nullable: true
        altriComune nullable: true
        numFabbricatiTerreni nullable: true
        numFabbricatiAree nullable: true
        fabbricatiD nullable: true
        fabbricatiDErariale nullable: true
        fabbricatiDComune nullable: true
        numFabbricatiD nullable: true
        ruraliErariale nullable: true
        ruraliComune nullable: true
        maggiorazioneTares nullable: true
        documentoId nullable: true
        identificativoOperazione nullable: true
        flagOk nullable: true
        noteVersamento nullable: true
        contribuente nullable: true
    }
}
