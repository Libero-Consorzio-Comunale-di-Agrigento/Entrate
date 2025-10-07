package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24DettaglioBean

import java.text.DecimalFormat

class DettaglioDatiF24RateVisitor extends DettaglioDatiF24VisitorAbstract {

    @Override
    void visit(DettaglioDatiF24 dettaglioF24) {
        if (dettaglioF24.dettagli == null) {
            return
        }

        if (dettaglioF24.dettagli.IMPORTO_RIGA_1 != 0) {
            F24DettaglioBean f24DettaglioBeanRata = new F24DettaglioBean()
            f24DettaglioBeanRata.sezione = "EL"
            f24DettaglioBeanRata.codiceEnte = dettaglioF24.siglaComune
            f24DettaglioBeanRata.codiceTributo = dettaglioF24.dettagli.COTR_RIGA_1
            f24DettaglioBeanRata.importiDebito = dettaglioF24.dettagli.IMPORTO_RIGA_1
            f24DettaglioBeanRata.importiDebitoDecimali = new DecimalFormat("#,##0.00").format(dettaglioF24.dettagli.IMPORTO_RIGA_1)[-2..-1]
            f24DettaglioBeanRata.rateazione = dettaglioF24.dettagli.RATEAZIONE_RIGA_1 ?: ''
            f24DettaglioBeanRata.annoRiferimento = dettaglioF24.dettagli.ANNO
            f24DettaglioBeanRata.acconto = true
            f24DettaglioBeanRata.saldo = true

            dettaglioF24.f24Bean.dettagli << f24DettaglioBeanRata
        }


        if (dettaglioF24.dettagli.IMPORTO_RIGA_2 != 0) {
            F24DettaglioBean f24DettaglioBeanInteressi = new F24DettaglioBean()
            f24DettaglioBeanInteressi.sezione = "EL"
            f24DettaglioBeanInteressi.codiceEnte = dettaglioF24.siglaComune
            f24DettaglioBeanInteressi.codiceTributo = dettaglioF24.dettagli.COTR_RIGA_2
            f24DettaglioBeanInteressi.importiDebito = dettaglioF24.dettagli.IMPORTO_RIGA_2
            f24DettaglioBeanInteressi.importiDebitoDecimali = new DecimalFormat("#,##0.00").format(dettaglioF24.dettagli.IMPORTO_RIGA_2)[-2..-1]
            f24DettaglioBeanInteressi.rateazione = dettaglioF24.dettagli.RATEAZIONE_RIGA_2 ?: ''
            f24DettaglioBeanInteressi.annoRiferimento = dettaglioF24.dettagli.ANNO
            f24DettaglioBeanInteressi.acconto = true
            f24DettaglioBeanInteressi.saldo = true

            dettaglioF24.f24Bean.dettagli << f24DettaglioBeanInteressi
        }

        if (dettaglioF24.dettagli.IMPORTO_RIGA_3 != 0) {
            F24DettaglioBean f24DettaglioBeanTributo = new F24DettaglioBean()
            f24DettaglioBeanTributo.sezione = "EL"
            f24DettaglioBeanTributo.codiceEnte = dettaglioF24.siglaComune
            f24DettaglioBeanTributo.codiceTributo = dettaglioF24.dettagli.COTR_RIGA_3
            f24DettaglioBeanTributo.importiDebito = dettaglioF24.dettagli.IMPORTO_RIGA_3
            f24DettaglioBeanTributo.importiDebitoDecimali = new DecimalFormat("#,##0.00").format(dettaglioF24.dettagli.IMPORTO_RIGA_3)[-2..-1]
            f24DettaglioBeanTributo.rateazione = dettaglioF24.dettagli.RATEAZIONE_RIGA_3 ?: ''
            f24DettaglioBeanTributo.annoRiferimento = dettaglioF24.dettagli.ANNO
            f24DettaglioBeanTributo.acconto = true
            f24DettaglioBeanTributo.saldo = true

            dettaglioF24.f24Bean.dettagli << f24DettaglioBeanTributo
        }

        if (dettaglioF24.dettagli.IMPORTO_RIGA_4 != 0) {
            F24DettaglioBean f24DettaglioBeanTefa = new F24DettaglioBean()
            f24DettaglioBeanTefa.sezione = "EL"
            f24DettaglioBeanTefa.codiceEnte = dettaglioF24.siglaComune
            f24DettaglioBeanTefa.codiceTributo = dettaglioF24.dettagli.COTR_RIGA_4
            f24DettaglioBeanTefa.importiDebito = dettaglioF24.dettagli.IMPORTO_RIGA_4
            f24DettaglioBeanTefa.importiDebitoDecimali = new DecimalFormat("#,##0.00").format(dettaglioF24.dettagli.IMPORTO_RIGA_4)[-2..-1]
            f24DettaglioBeanTefa.rateazione = dettaglioF24.dettagli.RATEAZIONE_RIGA_4 ?: ''
            f24DettaglioBeanTefa.annoRiferimento = dettaglioF24.dettagli.ANNO
            f24DettaglioBeanTefa.acconto = true
            f24DettaglioBeanTefa.saldo = true

            dettaglioF24.f24Bean.dettagli << f24DettaglioBeanTefa
        }
    }
}
