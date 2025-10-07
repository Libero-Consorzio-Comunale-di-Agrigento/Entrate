package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO
import it.finmatica.tr4.dto.WrkEncImmobiliDTO

class EncRecordDToDtoConverter extends EncEcPfRecordConverter {

    def convert(def record,
                def params,
                def fields) {

        def immobileMap = [
                documentoId       : params.documentoId,
                progrDichiarazione: params.progressivoDichiarazione,
                utente            : params.utente,
                dataVariazione    : new Date(),
                tipoImmobile      : 'B'
        ]

        // Validazione
        if (record[2].valore?.trim() != params.codiceFiscaleDichiaranteB) {
            def anomalia = new AnomalieCaricamentoDTO(
                    [
                            documentoId: params.documentoId,
                            descrizione: "Tracciato ${params.codiceTracciato.toString() == 'TAS00' ? 'ENC' : 'ECPF'} non conforme - Tipo record D",
                            codFiscale : record[2].valore,
                            note       : "Tipo record D, riga [${params.numeroRiga}], sequenza righe errata: Dati non relativi al dichiarante [${params.codiceFiscaleDichiaranteB}] indicato nel frontespizio."
                    ]
            )
            throw new EncEcPfException(anomalia)
        }

        def datiElaborati = fields?.D?.fields?.sort { it.value }?.collect {
            k, v ->
                [(k): leggiValore(record[v])]
        }?.collectEntries()

        // Tipo attività
        def rangeTipiAttivita = (9..18)
        def campiTipiAttivita = fields?.D?.fields?.sort { it.value }?.findAll { it.value in rangeTipiAttivita }
        decodificaTipo(datiElaborati, campiTipiAttivita, 'tipoAttivita')

        // Imobile storico
        immobileStorico(datiElaborati)

        // Esenzione
        esenzione(datiElaborati)

        // Percentuali/valori
        normalizzaPercentuali(datiElaborati)

        immobileMap.progrImmobile = datiElaborati.progrImmobileDich

        immobileMap << datiElaborati

        def immobile = new WrkEncImmobiliDTO(immobileMap)

        return immobile

    }

    void decodificaTipo(Map valori, Map fields, String campoDestinazione) {
        def tipoAttivita = fields.find { valori[it.key] == 1 }?.value
        if (!tipoAttivita) {
            throw new RuntimeException("Tipo attivita non riconosciuto")
        }

        valori[campoDestinazione] = tipoAttivita - 8
        fields.each { valori.remove(it.key) }
    }
}
