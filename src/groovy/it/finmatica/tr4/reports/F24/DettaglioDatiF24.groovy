package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24Bean

class DettaglioDatiF24 implements DettaglioDatiF24Interface {

    String siglaComune
    int tipoPagamento
    F24Bean f24Bean
    def dettagli

    DettaglioDatiF24(String siglaComune, int tipoPagamento,
                     F24Bean f24Bean, def dettagli) {
        super();
        this.siglaComune = siglaComune
        this.tipoPagamento = tipoPagamento
        this.f24Bean = f24Bean
        this.dettagli = dettagli
    }

    @Override
    void accept(DettaglioDatiF24VisitorAbstract dettaglioF24Visitor) {
        dettaglioF24Visitor.visit(this)
    }
}
