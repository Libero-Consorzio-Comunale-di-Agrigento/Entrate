package it.finmatica.tr4.reports.beans

import org.apache.commons.lang.StringUtils

class F24DettaglioBean {
    String sezione
    String codiceTributo
    String codiceEnte
    boolean acconto
    boolean saldo
    Integer numeroImmobili
    String rateazione
    String annoRiferimento
    BigDecimal detrazione
    BigDecimal importiDebito
    String importiDebitoDecimali
    BigDecimal importiCredito
    String ravvedimento
    String titoloF24

    Integer rataRuolo

    String getDetrazioneInt() {
        if (detrazione != null && detrazione.compareTo(BigDecimal.ZERO) > 0) {
            //println "detrazione>0 "+detrazione
            String detrazioneTxt = detrazione.toPlainString()
            //println "detrazioneTxt "+detrazioneTxt
            int radixLoc = detrazioneTxt.indexOf('.')
            //println "radixLoc "+radixLoc
            return detrazioneTxt.substring(0, (radixLoc == -1) ? detrazioneTxt.length() : radixLoc)
        }
    }

    String getDetrazioneDec() {
        if (detrazione != null && detrazione.compareTo(BigDecimal.ZERO) > 0) {
            String detrazioneTxt = detrazione.toPlainString()
            int radixLoc = detrazioneTxt.indexOf('.')
            return (radixLoc == -1) ? "00" : StringUtils.rightPad(detrazioneTxt.substring(radixLoc + 1, detrazioneTxt.length()), 2, "0")
        }
    }
}
