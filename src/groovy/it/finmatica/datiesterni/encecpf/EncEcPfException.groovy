package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO

class EncEcPfException extends Exception {
    AnomalieCaricamentoDTO anomalia

    EncEcPfException(Throwable cause, AnomalieCaricamentoDTO anomalia) {
        super(cause)
        this.anomalia = anomalia
    }

    EncEcPfException(AnomalieCaricamentoDTO anomalia) {
        this.anomalia = anomalia
    }

}
