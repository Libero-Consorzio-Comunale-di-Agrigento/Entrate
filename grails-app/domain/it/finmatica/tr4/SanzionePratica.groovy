package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

import java.math.RoundingMode

class SanzionePratica implements Serializable {

    PraticaTributo pratica
    Sanzione sanzione
    Short sequenza
    OggettoPratica oggettoPratica
    Byte semestri
    BigDecimal percentuale
    BigDecimal importo
    BigDecimal riduzione
    Ruolo ruolo
    BigDecimal importoRuolo
    Ad4Utente utente
    Date lastUpdated
    String note
    Short giorni
    BigDecimal riduzione2
    BigDecimal abPrincipale
    BigDecimal rurali
    BigDecimal terreniComune
    BigDecimal terreniErariale
    BigDecimal areeComune
    BigDecimal areeErariale
    BigDecimal altriComune
    BigDecimal altriErariale
    BigDecimal fabbricatiDComune
    BigDecimal fabbricatiDErariale
    BigDecimal fabbricatiMerce
    Short seqSanz

    static mapping = {
        id composite: ["pratica", "sanzione", "sequenza", "seqSanz"]
        columns {
            sanzione {
                column name: "tipo_tributo"
                column name: "cod_sanzione"
                column name: "sequenza_sanz", key: "sequenza"
            }
        }
        pratica column: "pratica"
        seqSanz column: "seq_sanz"
        oggettoPratica column: "oggetto_pratica"
        ruolo column: "ruolo"
        utente column: "utente", ignoreNotFound: true
        version false
        riduzione2 column: "riduzione_2"
        fabbricatiDComune column: "fabbricati_d_comune"
        fabbricatiDErariale column: "fabbricati_d_erariale"
        lastUpdated sqlType: 'Date', column: 'data_variazione'
        table "web_sanzioni_pratica"
    }

    static constraints = {
        oggettoPratica nullable: true
        semestri nullable: true
        percentuale nullable: true
        importo nullable: true
        riduzione nullable: true
        ruolo nullable: true
        importoRuolo nullable: true
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        giorni nullable: true
        riduzione2 nullable: true
        abPrincipale nullable: true
        rurali nullable: true
        terreniComune nullable: true
        terreniErariale nullable: true
        areeComune nullable: true
        areeErariale nullable: true
        altriComune nullable: true
        altriErariale nullable: true
        fabbricatiDComune nullable: true
        fabbricatiDErariale nullable: true
        fabbricatiMerce nullable: true
    }

    static transients = ['importoLordo', 'importoTotale', 'seqSanz']


    // TODO: un'ottimizzazione completa sarà fatta nelle prossime versioni quando i campi verranno inseriti in tabella.
    BigDecimal getImportoLordo() {

        if (this.sanzione.tipoTributo.tipoTributo != 'TARSU') {
            return this.importo
        }

        BigDecimal importoLordo = 0

        List carichiTarsu = OggettiCache.CARICHI_TARSU.valore
        def cata = carichiTarsu.find { it.anno == this.pratica.anno && it.flagLordo == 'S' }

        def result = OggettoPratica.executeQuery("""
						select count(*) from OggettoPratica as ogpr
						where
                            codiceTributo.flagRuolo = 'S' and  
							(pratica.praticaTributoRif.id = ${this.pratica.id} or 
                                pratica.id = ${this.pratica.id})
							
						""")

        if (result[0] > 0 && (this.sanzione.codSanzione == 1 || this.sanzione.codSanzione == 100 || this.sanzione.codSanzione == 101 ||
                this.sanzione.flagMaggTares == null && this.sanzione.tipoCausale == 'E') && cata) {
            def addEca = this.importo.multiply(cata.addizionaleEca ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def maggEca = this.importo.multiply(cata.maggiorazioneEca ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def addPro = this.importo.multiply(cata.addizionalePro ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def aliq = this.importo.multiply(cata.aliquota ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)

            importoLordo = this.importo.add(addEca).add(maggEca).add(addPro).add(aliq)

        } else {
            importoLordo = this.importo
        }

        return importoLordo
    }

    // TODO: un'ottimizzazione completa sarà fatta nelle prossime versioni quando i campi verranno inseriti in tabella.
    BigDecimal getImportoTotale() {

        if (this.sanzione.tipoTributo.tipoTributo != 'TARSU') {
            return this.importo
        }

        BigDecimal importoTotale = 0

        List carichiTarsu = OggettiCache.CARICHI_TARSU.valore
        def cata = carichiTarsu.find { it.anno == this.pratica.anno && it.flagLordo == 'S' }

        def result = OggettoPratica.executeQuery("""
						select count(*) from OggettoPratica as ogpr
						where
                            codiceTributo.flagRuolo = 'S' and 
							(pratica.id = ${this.pratica.id} or
                                pratica.praticaTributoRif.id = ${this.pratica.id})
						""")

        if (result[0] > 0 && (this.sanzione.codSanzione == 1 || this.sanzione.codSanzione == 100 || this.sanzione.codSanzione == 101 ||
                this.sanzione.codSanzione == 111 || this.sanzione.codSanzione == 121 || this.sanzione.codSanzione == 131 ||
                this.sanzione.codSanzione == 141 || this.sanzione.flagMaggTares == null && this.sanzione.tipoCausale == 'E') && cata) {
            def addEca = this.importo.multiply(cata.addizionaleEca ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def maggEca = this.importo.multiply(cata.maggiorazioneEca ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def addPro = this.importo.multiply(cata.addizionalePro ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)
            def aliq = this.importo.multiply(cata.aliquota ?: 0).divide(100).setScale(2, RoundingMode.HALF_UP)

            importoTotale = this.importo.add(addEca).add(maggEca).add(addPro).add(aliq)

        } else {
            importoTotale = this.importo
        }

        return importoTotale
    }

    void setImportoTotale(BigDecimal importoTotale) {
        // Se non presente va in errore il metodo toDomain perché non trova il metodo per settare la property.
    }

    void setImportoLordo(BigDecimal importoLordo) {
        // Se non presente va in errore il metodo toDomain perché non trova il metodo per settare la property.
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append pratica
        builder.append sanzione.codSanzione
        builder.append sanzione.tipoTributo
        builder.append sequenza
        builder.append seqSanz
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append pratica, other.pratica
        builder.append sanzione.codSanzione, other.sanzione.codSanzione
        builder.append sanzione.tipoTributo, other.sanzione.tipoTributo
        builder.append sequenza, other.sequenza
        builder.append seqSanz, other.seqSanz
        builder.isEquals()
    }
}
