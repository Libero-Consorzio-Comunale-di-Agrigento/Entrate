package it.finmatica.datiesterni.encecpf


import it.finmatica.tr4.dto.AnomalieCaricamentoDTO
import it.finmatica.tr4.dto.WrkEncImmobiliDTO

class EcPfRecordDToDtoConverter extends EncEcPfRecordConverter {

    def convert(def record,
                def params,
                def fields) {

        def immobileMap = [documentoId       : params.documentoId,
                           progrDichiarazione: params.progressivoDichiarazione,
                           utente            : params.utente,
                           dataVariazione    : new Date(),
                           tipoImmobile      : 'A'
        ]

        def immobili = []

        (0..fields.D.num - 1).each {

            // Validazione
            if (record[2].valore?.trim() != params.codiceFiscaleDichiaranteB) {
                def anomalia = new AnomalieCaricamentoDTO([documentoId: params.documentoId,
                                                           descrizione: "Tracciato ${params.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'} non conforme - Tipo record D",
                                                           codFiscale : record[2].valore,
                                                           note       : "Tipo record D, riga [${params.numeroRiga}], sequenza righe errata: Dati non relativi al dichiarante [${params.codiceFiscaleDichiaranteB}] indicato nel frontespizio."])
                throw new EncEcPfException(anomalia)
            }

            def offset = fields.D.offset * it

            def datiElaborati = fields?.D?.fields?.sort { it.value }?.collect { k, v ->

                def fieldIndex = v + (offset * (v in ((fields?.D?.daCampo)..((fields?.D?.daCampo + fields?.D?.offset * fields?.D?.num - 1))) ? 1 : 0))

                [(k): leggiValore(record[fieldIndex])]
            }?.collectEntries()

            // Il secondo immobile è opzionale, potrebbe esserne definito uno solo per record
            if (datiElaborati.numOrdine) {

                // Imobile storico
                immobileStorico(datiElaborati)

                // Esenzione
                esenzione(datiElaborati)

                // Percentuali/valori
                normalizzaPercentuali(datiElaborati)

                immobileMap.progrImmobile = datiElaborati.progrImmobileDich

                immobileMap << datiElaborati

                immobili += new WrkEncImmobiliDTO(immobileMap)

            }

        }

        params.progressivoImmobileB = immobileMap.progrImmobile

        return immobili

    }

}
