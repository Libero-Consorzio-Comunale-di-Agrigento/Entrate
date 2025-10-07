package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24Bean;


class DettaglioDatiF24Ruolo extends DettaglioDatiF24 {

    public DettaglioDatiF24Ruolo(String siglaComune, int tipoPagamento, F24Bean f24Bean, def dettagli) {
        super(siglaComune, tipoPagamento, f24Bean, dettagli)
    }
}
