package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RuoloEccedenza implements Serializable, Comparable<RuoloEccedenza> {

    Ruolo ruolo
    Contribuente contribuente
    CodiceTributo codiceTributo
    Short categoria
    Short sequenza

    Date dal
    Date al
    String flagDomestica
    Short numeroFamiliari
    BigDecimal imposta
    BigDecimal addizionalePro
    BigDecimal importoRuolo
    BigDecimal importoMinimi
    BigDecimal totaleSvuotamenti
    BigDecimal superficie
    BigDecimal costoUnitario
    BigDecimal costoSvuotamento
    BigDecimal svuotamentiSuperficie
    BigDecimal costoSuperficie
    BigDecimal eccedenzaSvuotamenti
    String note

    Ad4Utente utente
    Date lastUpdated

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append ruolo
        builder.append contribuente.codFiscale
        builder.append tributo
        builder.append categoria
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append ruolo, other.ruolo
        builder.append contribuente.codFiscale, other.contribuente.codFiscale
        builder.append tributo, other.tributo
        builder.append categoria, other.categoria
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
		id column: "id_eccedenza", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "RUOLI_ECCEDENZE_NR"]

        ruolo column: "ruolo"
        contribuente column: "cod_fiscale"
        codiceTributo column: "tributo"
        dal sqlType: 'Date', column: 'dal'
        al sqlType: 'Date', column: 'al'
        flagDomestica column: "flag_domestica"
        numeroFamiliari column: "numero_familiari"

        imposta column: "imposta"
        addizionalePro column: "addizionale_pro"
        importoRuolo column: "importo_ruolo"
        importoMinimi column: "importo_minimi"
        totaleSvuotamenti column: "totale_svuotamenti"
        superficie column: "superficie"
        costoUnitario column: "costo_unitario"
        costoSvuotamento column: "costo_svuotamento"
        svuotamentiSuperficie column: "svuotamenti_superficie"
        costoSuperficie column: "costo_superficie"
        eccedenzaSvuotamenti column: "eccedenza_svuotamenti"

        utente column: "utente", ignoreNotFound: true
        lastUpdated sqlType: 'Date', column: 'data_variazione'

        table "ruoli_eccedenze"
        version false
    }

    static constraints = {
        codiceTributo nullable: false
        categoria nullable: false
        sequenza nullable: false
        dal nullable: true
        al nullable: true
        flagDomestica nullable: true
        numeroFamiliari nullable: true
        imposta nullable: false
        addizionalePro nullable: true
        importoRuolo nullable: false
        importoMinimi nullable: true
        totaleSvuotamenti nullable: true
        superficie nullable: true
        costoUnitario nullable: true
        costoSvuotamento nullable: true
        svuotamentiSuperficie nullable: true
        costoSuperficie nullable: true
        eccedenzaSvuotamenti nullable: true
        note nullable: true, maxSize: 2000

        utente maxSize: 8
    }

    @Override
    int compareTo(RuoloEccedenza rc) {
        ruolo.tipoRuolo <=> rc.ruolo.tipoRuolo ?:
                ruolo.annoRuolo <=> rc.ruolo.annoRuolo ?:
                        ruolo.annoEmissione <=> rc.ruolo.annoEmissione ?:
                                ruolo.progrEmissione <=> rc.ruolo.progrEmissione ?:
                                        ruolo.dataEmissione <=> rc.ruolo.dataEmissione ?:
                                                ruolo.invioConsorzio <=> rc.ruolo.invioConsorzio
    }
}
