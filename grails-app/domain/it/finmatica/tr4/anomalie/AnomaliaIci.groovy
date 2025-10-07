package it.finmatica.tr4.anomalie

import it.finmatica.tr4.Oggetto

class AnomaliaIci {

    Short anno
    TipoAnomalia tipoAnomalia
    String codFiscale
    Oggetto oggetto
    String flagOk
    Date dataVariazione
    String note

    static mapping = {
        id column: "anomalia"
        oggetto column: "oggetto"
        tipoAnomalia column: "tipo_anomalia"
        version false

        table 'anomalie_ici'
    }

    static constraints = {
        codFiscale nullable: true
        oggetto nullable: true
        flagOk nullable: true, maxSize: 1
        dataVariazione nullable: true
        note nullable: true
    }
}
