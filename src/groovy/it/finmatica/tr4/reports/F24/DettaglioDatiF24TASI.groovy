package it.finmatica.tr4.reports.F24


import it.finmatica.tr4.reports.beans.F24Bean

class DettaglioDatiF24TASI extends DettaglioDatiF24 {

    //salva la detrazione che poi verra' messa
    //nella riga dell'abitazione principale
    //dall'oggetto chiamante
    BigDecimal detrazione = BigDecimal.ZERO


    private static final Map codiciTributo = [
            'AREA'                   : "3960"
            , 'ABITAZIONE_PRINCIPALE': "3958"
            , 'ALTRO_FABBRICATO'     : "3961"
            , 'RURALE'               : "3959"
            , 'INTERESSI'            : "3962"
            , 'SANZIONI'             : "3963"
    ]

    public DettaglioDatiF24TASI(String siglaComune, int tipoPagamento,
                                F24Bean f24Bean, def dettagli) {
        super(siglaComune, tipoPagamento, f24Bean, dettagli)
    }

}
