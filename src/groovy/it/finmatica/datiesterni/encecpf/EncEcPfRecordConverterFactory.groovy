package it.finmatica.datiesterni.encecpf

class EncEcPfRecordConverterFactory {

    private static converters = [
            // ENC
            (DichiarazioniImport.CODICI_FORNITURA.TAS00): [
                    'B': new EncEcPfRecordBToDtoConverter(),
                    'C': new EncRecordCToDtoConverter(),
                    'D': new EncRecordDToDtoConverter(),
                    'E': new EncEcPfRecordEToDtoConverter(),
            ],
            // ECPF
            (DichiarazioniImport.CODICI_FORNITURA.TAT00): [
                    'B': new EncEcPfRecordBToDtoConverter(),
                    'C': new EcPfRecordCToDtoConverter(),
                    'D': new EcPfRecordDToDtoConverter()
            ]
    ]


    static EncEcPfRecordConverter converter(def tipoRecord, DichiarazioniImport.CODICI_FORNITURA codiceFornitura) {
        def converter = converters[codiceFornitura][tipoRecord]

        if (!converter) {
            // throw new Exception("Convertitore non definito per tipo record [$tipoRecord] e fornitore [$codiceFornitura]")
        }

        return converters[codiceFornitura][tipoRecord]
    }
}
