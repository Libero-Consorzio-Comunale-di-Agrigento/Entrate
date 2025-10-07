package it.finmatica.tr4.reports.F24


import it.finmatica.tr4.reports.beans.F24Bean

class DettaglioDatiF24TARSU extends DettaglioDatiF24 {

    DettaglioDatiF24TARSU(String siglaComune, int tipoPagamento,
                          F24Bean f24Bean, def dettagli) {
        super(siglaComune, tipoPagamento, f24Bean, dettagli)
    }

}
