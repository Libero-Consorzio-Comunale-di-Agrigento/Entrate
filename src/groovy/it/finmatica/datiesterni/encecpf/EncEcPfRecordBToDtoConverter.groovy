package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO
import it.finmatica.tr4.dto.WrkEncTestataDTO

class EncEcPfRecordBToDtoConverter extends EncEcPfRecordConverter {
    def convert(def record,
                def params,
                def fields) {

        def testataMap = [
                documentoId       : params.documentoId,
                progrDichiarazione: params.progressivoDichiarazione,
                utente            : params.utente,
                dataVariazione    : new Date(),
                codiceTracciato   : params.codiceTracciato,
        ]

        def datiElaborati = fields?.B?.fields?.sort { it.value }?.collect { k, v -> [(k): leggiValore(record[v])] }?.collectEntries()

        // Validazione
        if (record[2].valore?.trim() != (params.codiceTracciato.toString() == 'TAS00' ? record[11] : record[10])?.valore?.trim()) {
            def anomalia = new AnomalieCaricamentoDTO(
                    [
                            documentoId: params.documentoId,
                            descrizione: "Tracciato ${params.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'} non conforme - Tipo record B",
                            codFiscale : record[2].valore,
                            note       : "Il CF contribuente deve essere obbligatoriamente uguale al CF soggetto dichiarante riga [${params.numeroRiga}]."
                    ]
            )
            throw new EncEcPfException(anomalia)
        }

        // Si crea il valore per telefono
        concat(datiElaborati, ['telefonoPrefisso', 'telefonoNumero'], 'telefono')

        testataMap << datiElaborati

        testataMap.codiceTracciato = testataMap.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'

        def testata = new WrkEncTestataDTO(testataMap)

        return testata

    }
}
