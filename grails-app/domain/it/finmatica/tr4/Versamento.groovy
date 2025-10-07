package it.finmatica.tr4

import java.math.BigDecimal;

import it.finmatica.tr4.pratiche.PraticaTributo

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Versamento implements Serializable, Comparable<Versamento> {

    Short anno

    Short sequenza

    Short rata
    String tipoVersamento
    String descrizione
    Integer provvedimento
    String ufficioPt
    Long numBollettino
    Date dataPagamento
    BigDecimal importoVersato
    Short fabbricati
    BigDecimal terreniAgricoli
    BigDecimal areeFabbricabili
    BigDecimal abPrincipale
    BigDecimal altriFabbricati
    BigDecimal fabbricatiMerce
    BigDecimal detrazione
    Long progrAnci
    String causale

    String utente
    Date lastUpdated
    String note
    String estremiProvvedimento
    Date dataProvvedimento
    String estremiSentenza
    Date dataSentenza
    Date dataReg
    Long ogprOgim
    Long imposta
    Long interessi

    Long fattura
    BigDecimal speseSpedizione
    BigDecimal speseMora
    BigDecimal rurali
    BigDecimal terreniErariale
    BigDecimal areeErariale
    BigDecimal altriErariale
    Short numFabbricatiAb
    Short numFabbricatiRurali
    Short numFabbricatiAltri
    Short numFabbricatiMerce
    BigDecimal terreniComune
    BigDecimal areeComune
    BigDecimal altriComune
    Short numFabbricatiTerreni
    Short numFabbricatiAree
    BigDecimal fabbricatiD
    BigDecimal fabbricatiDErariale
    BigDecimal fabbricatiDComune
    Short numFabbricatiD
    BigDecimal sanzioni1
    BigDecimal sanzioni2
    BigDecimal ruraliErariale
    BigDecimal ruraliComune
    BigDecimal maggiorazioneTares

    Ruolo ruolo
    PraticaTributo pratica
    Contribuente contribuente
    TipoTributo tipoTributo
    OggettoImposta oggettoImposta
    Fonte fonte
    RataImposta rataImposta
    Long idCompensazione
    Long documentoId

    String servizio
	String idback
	
    BigDecimal addizionalePro
	BigDecimal sanzioniAddPro
	BigDecimal interessiAddPro

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append contribuente.codFiscale
        builder.append anno
        builder.append tipoTributo.tipoTributo
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append contribuente.codFiscale, other.contribuente.codFiscale
        builder.append anno, other.anno
        builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
        id composite: ["contribuente", "anno", "tipoTributo", "sequenza"]

        ruolo column: "ruolo"
        pratica column: "pratica"
        contribuente column: "cod_fiscale"
        tipoTributo column: "tipo_tributo"
        oggettoImposta column: "oggetto_imposta"
        fonte column: "fonte"
        rataImposta column: "rata_imposta"
        fabbricatiD column: "fabbricati_d"
        fabbricatiDErariale column: "fabbricati_d_erariale"
        fabbricatiDComune column: "fabbricati_d_comune"
        numFabbricatiD column: "num_fabbricati_d"
        sanzioni1 column: "sanzioni_1"
        sanzioni2 column: "sanzioni_2"
        utente column: "utente"
        dataPagamento sqlType: 'Date'
        lastUpdated column: "data_variazione", sqlType: 'Date'
        dataSentenza sqlType: 'Date'
        dataReg sqlType: 'Date'
        dataProvvedimento sqlType: 'Date'

        table 'versamenti'
        version false

    }

    static constraints = {
        tipoTributo maxSize: 5
        oggettoImposta nullable: true
        rataImposta nullable: true
        pratica nullable: true
        rata nullable: true
        tipoVersamento nullable: true, inList: ['A', 'S', 'U']
        descrizione nullable: true, maxSize: 60
        provvedimento nullable: true
        ufficioPt nullable: true, maxSize: 30
        numBollettino nullable: true
        dataPagamento nullable: true
        importoVersato nullable: true
        fabbricati nullable: true
        terreniAgricoli nullable: true
        areeFabbricabili nullable: true
        abPrincipale nullable: true
        altriFabbricati nullable: true
        detrazione nullable: true
        progrAnci nullable: true
        causale nullable: true, maxSize: 200
        fonte nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        estremiProvvedimento nullable: true, maxSize: 16
        dataProvvedimento nullable: true
        estremiSentenza nullable: true, maxSize: 16
        dataSentenza nullable: true
        dataReg nullable: true
        ogprOgim nullable: true
        imposta nullable: true
        sanzioni1 nullable: true
        sanzioni2 nullable: true
        interessi nullable: true
        ruolo nullable: true
        fattura nullable: true
        speseSpedizione nullable: true
        speseMora nullable: true
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
        idCompensazione nullable: true
        sequenza nullable: true
        fabbricatiMerce nullable: true
        numFabbricatiMerce nullable: true
        documentoId nullable: true
        addizionalePro nullable: true
		sanzioniAddPro nullable: true
		interessiAddPro nullable: true
		servizio nullable: true, maxSize: 64
		idback nullable: true, maxSize: 4000
    }

    def springSecurityService

    def beforeValidate() {
        utente = utente ?: springSecurityService.currentUser?.id
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser?.id
    }


    /* la query del folder versamenti fa una finta left join con
     * la tabella scadenze per prendere la data, ma il dato non
     * viene utilizzato in maschera... è inutile?
     */

    def getScadenza() {
        Scadenza.createCriteria().get {
            eq("tipoScadenza", "V")
            eq("tipoTributo.tipoTributo", tipoTributo.tipoTributo)
            eq("anno", anno)
            eq("tipoVersamento", tipoVersamento)
        }
    }

    @Override
    public int compareTo(Versamento vers) {
        contribuente.codFiscale <=> vers.contribuente.codFiscale ?:
                tipoTributo.tipoTributo <=> vers.tipoTributo.tipoTributo ?:
                        vers.anno <=> anno ?:
                                vers.dataPagamento <=> dataPagamento ?:
                                        vers.tipoVersamento <=> tipoVersamento ?:
                                                vers.pratica?.id <=> pratica?.id ?:
                                                        rata <=> vers.rata ?:
                                                                sequenza <=> vers.sequenza
    }

}
