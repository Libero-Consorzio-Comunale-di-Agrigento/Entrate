package it.finmatica.datiesterni.encecpf


import it.finmatica.tr4.dto.WrkEncContitolariDTO

class EcPfRecordCToDtoConverter extends EncEcPfRecordConverter {

    def convert(def record,
                def params,
                def fields) {

        def contitolariMap = [
                documentoId       : params.documentoId,
                progrDichiarazione: params.progressivoDichiarazione,
                utente            : params.utente,
                dataVariazione    : new Date(),
                tipoImmobile      : 'A'
        ]

        def contitolari = []

        (0..fields.C.num - 1).each {

            log.info("Recupero contitolare [$it]...")

            def offset = fields.C.offset * it

            def datiElaborati = fields?.C?.fields?.sort { it.value }?.collect {
                k, v ->

                    def fieldIndex = v + (offset * (v in ((fields?.C?.daCampo)..((fields?.C?.daCampo + fields?.C?.offset * fields?.C?.num - 1))) ? 1 : 0))

                    [(k): leggiValore(record[fieldIndex])]
            }?.collectEntries()

            // Il secondo contitolare è opzionale, potrebbe esserne definito uno solo per record
            if (datiElaborati.numOrdine) {

                contitolariMap.progrImmobile = datiElaborati.numOrdine

                // Percentuali e valori
                normalizzaPercentuali(datiElaborati)

                contitolariMap << datiElaborati

                contitolari += new WrkEncContitolariDTO(contitolariMap)

                contitolariMap.progrContitolare = contitolariMap.progrContitolare++
            }
        }

        return contitolari

    }
}
