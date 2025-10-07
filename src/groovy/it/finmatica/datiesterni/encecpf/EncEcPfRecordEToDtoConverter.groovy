package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO

class EncEcPfRecordEToDtoConverter extends EncEcPfRecordConverter {
    def convert(def record,
                def params,
                def fields) {

        // Validazione
        if (record[2].valore?.trim() != params.codiceFiscaleDichiaranteB) {
            def anomalia = new AnomalieCaricamentoDTO(
                    [
                            documentoId: params.documentoId,
                            descrizione: "Tracciato ${params.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'} non conforme - Tipo record E",
                            codFiscale : record[2].valore,
                            note       : "Tipo record E, riga [${params.numeroRiga}], sequenza righe errata: Dati non relativi al dichiarante [${params.codiceFiscaleDichiaranteB}] indicato nel frontespizio."
                    ]
            )
            throw new EncEcPfException(anomalia)
        }

        def datiElaborati = fields?.E?.fields?.sort { it.value }?.collect { k, v -> [(k): leggiValore(record[v])] }?.collectEntries()

        return datiElaborati

    }
}
