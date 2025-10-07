package it.finmatica.datiesterni.beans

interface TracciatiUtenze {

    def static final UTE_RECORD_0 = [
            tipoRecord             : 1,
            identificativoFornitura: 9,
            progressivoFornitura   : 4,
            dataFornitura          : 8
    ]

    def static final UTE_ELE_RECORD_2011 = [
            // Dati fornitura
            tipoRecord        : 1,
            tipoFornitura     : 1,
            annoRifDati       : 4,
            // Codice catastale del comune
            codCatComune      : 4,
            // Codice fiscale dell'ente erogante
            codFisSoggErog    : 16,
            // Codice fiscale del titolare dell'utenza
            codFisTitUte      : 16,
            // Tipo soggetto
            tipoSogg          : 1,
            // Dati anagrafici del titolare dell'utenza
            datiAnagrafici    : 80,
            // Dati dell'utenza
            codIden           : 14,
            filler            : 3,
            tipoUte           : 1,
            indirizzoUte      : 35,
            capUte            : 5,
            // Dati dei consumi
            spesaConsumo      : 14,
            kwh               : 10,
            mesiFatturazione  : 2,
            // Area a disposizione
            spazioDisposizione: 92,
            fineRiga          : 1

    ]

    def static final UTE_GAS_RECORD_2011 = [
            // Dati fornitura
            tipoRecord        : 1,
            tipoFornitura     : 1,
            annoRifDati       : 4,
            // Codice catastale del comune
            codCatComune      : 4,
            // Codice fiscale dell'ente erogante
            codFisSoggErog    : 16,
            // Codice fiscale del titolare dell'utenza
            codFisTitUte      : 16,
            // Tipo soggetto
            tipoSogg          : 1,
            // Dati anagrafici del titolare dell'utenza
            datiAnagrafici    : 80,
            // Dati dell'utenza
            codIden           : 30,
            filler01          : 3,
            tipoUte           : 1,
            indirizzoUte      : 35,
            filler02          : 5,
            // Dati dei consumi
            fatturato         : 10,
            filler03          : 4,
            consumo           : 10,
            mesiFatturazione  : 2,
            // Area a disposizione
            spazioDisposizione: 76,
            fineRiga          : 1

    ]
}