package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RuoloContribuente implements Serializable, Comparable<RuoloContribuente> {

    Ruolo ruolo
    Contribuente contribuente
    Short sequenza
    OggettoImposta oggettoImposta
    PraticaTributo pratica
    CodiceTributo codiceTributo
    BigDecimal consistenza
    BigDecimal importo
    Short semestri
    Date decorrenzaInteressi
    Short mesiRuolo
    Date dataCartella
    String numeroCartella
    Ad4Utente utente
    Date lastUpdated
    String note
    Short daMese
    Short aMese
    Short giorniRuolo

    static hasMany = [sgravi: Sgravio]

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append ruolo
        builder.append contribuente.codFiscale
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append ruolo, other.ruolo
        builder.append contribuente.codFiscale, other.contribuente.codFiscale
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
        id composite: ["ruolo", "contribuente", "sequenza"]
        contribuente column: "cod_fiscale"
        ruolo column: "ruolo"
        pratica column: "pratica"
        codiceTributo column: "tributo"
        oggettoImposta column: "oggetto_imposta"
        utente column: "utente", ignoreNotFound: true
        decorrenzaInteressi sqlType: 'Date', column: 'decorrenza_interessi'
        dataCartella sqlType: 'Date', column: 'data_cartella'
        lastUpdated sqlType: 'Date', column: 'data_variazione'

        table "ruoli_contribuente"
        version false
    }

    static constraints = {
        oggettoImposta nullable: true
        pratica nullable: true
        consistenza nullable: true
        semestri nullable: true
        decorrenzaInteressi nullable: true
        mesiRuolo nullable: true
        dataCartella nullable: true
        numeroCartella nullable: true, maxSize: 20
        utente maxSize: 8
        note nullable: true, maxSize: 2000
        daMese nullable: true
        aMese nullable: true
        giorniRuolo nullable: true
    }

    @Override
    int compareTo(RuoloContribuente rc) {
        ruolo.tipoRuolo <=> rc.ruolo.tipoRuolo ?:
                ruolo.annoRuolo <=> rc.ruolo.annoRuolo ?:
                        ruolo.annoEmissione <=> rc.ruolo.annoEmissione ?:
                                ruolo.progrEmissione <=> rc.ruolo.progrEmissione ?:
                                        ruolo.dataEmissione <=> rc.ruolo.dataEmissione ?:
                                                ruolo.invioConsorzio <=> rc.ruolo.invioConsorzio
        /*RUOLI.TIPO_RUOLO ASC,
        RUOLI.ANNO_RUOLO ASC,
        RUOLI.ANNO_EMISSIONE ASC,
        RUOLI.PROGR_EMISSIONE ASC,
        RUOLI_OGGETTO.TRIBUTO ASC,
        RUOLI.DATA_EMISSIONE ASC,
        RUOLI.INVIO_CONSORZIO ASC*/
    }
}
