package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO
import it.finmatica.tr4.dto.WrkEncImmobiliDTO

class EncRecordCToDtoConverter extends EncEcPfRecordConverter {

    def convert(def record,
                def params,
                def fields) {

        def immobileMap = [
                documentoId       : params.documentoId,
                progrDichiarazione: params.progressivoDichiarazione,
                utente            : params.utente,
                dataVariazione    : new Date(),
                tipoImmobile: 'A'
        ]

        def immobili = []

        (0..fields.C.num - 1).each {
            log.info("Recupero immobile [$it]...")

            // Validazione
            if (record[2].valore?.trim() != params.codiceFiscaleDichiaranteB) {
                def anomalia = new AnomalieCaricamentoDTO(
                        [
                                documentoId: params.documentoId,
                                descrizione: "Tracciato ${params.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'} non conforme - Tipo record C",
                                codFiscale : record[2].valore,
                                note       : "Tipo record C, riga [${params.numeroRiga}], sequenza righe errata: Dati non relativi al dichiarante [${params.codiceFiscaleDichiaranteB}] indicato nel frontespizio."
                        ]
                )
                throw new EncEcPfException(anomalia)
            }

            def offset = fields.C.offset * it

            def datiElaborati = fields?.C?.fields?.sort { it.value }?.collect {
                k, v ->

                    def fieldIndex = v + (offset * ((v >= fields.C.daCampo && (v < fields.C.daCampo + fields.C.offset * 2)) ? 1 : 0))

                    [(k): leggiValore(record[fieldIndex])]
            }?.collectEntries()

            // Il secondo immobile è opzionale, potrebbe esserne definito uno solo per record
            if (datiElaborati.numOrdine) {

                // Imobile storico
                immobileStorico(datiElaborati)

                // Esenzione
                esenzione(datiElaborati)

                // Percentuali e valori
                normalizzaPercentuali(datiElaborati)

                immobileMap.progrImmobile = datiElaborati.progrImmobileDich

                immobileMap << datiElaborati

                immobili += new WrkEncImmobiliDTO(immobileMap)
            }
        }

        return immobili

    }
}
