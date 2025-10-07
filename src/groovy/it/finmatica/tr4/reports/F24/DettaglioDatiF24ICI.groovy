package it.finmatica.tr4.reports.F24


import it.finmatica.tr4.reports.beans.F24Bean

class DettaglioDatiF24ICI extends DettaglioDatiF24 {


    //salva la detrazione che poi verra' messa
    //nella riga dell'abitazione principale
    //dall'oggetto chiamante
    BigDecimal detrazione = BigDecimal.ZERO

    static final Map codiciTributo = [
            'TERRENO'                : ['COMUNE': "3914", 'STATO': "3915"]
            , 'AREA'                 : ['COMUNE': "3916", 'STATO': "3917"]
            , 'ABITAZIONE_PRINCIPALE': "3912"
            , 'ALTRO_FABBRICATO'     : ['COMUNE': "3918", 'STATO': "3919"]
            , 'RURALE'               : "3913"
            , 'FABBRICATO_D'         : ['COMUNE': "3930", 'STATO': "3925"]
            , 'INTERESSI'            : "3923"
            , 'SANZIONI'             : "3924"
            , 'FABBRICATO_MERCE'     : "3939"
    ]


    public DettaglioDatiF24ICI(String siglaComune, int tipoPagamento,
                               F24Bean f24Bean, def dettagli) {
        super(siglaComune, tipoPagamento, f24Bean, dettagli)

    }

}
