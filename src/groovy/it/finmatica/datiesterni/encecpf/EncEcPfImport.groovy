package it.finmatica.datiesterni.encecpf

import it.finmatica.tr4.dto.AnomalieCaricamentoDTO

@SuppressWarnings("UnnecessaryQualifiedReference")
class EncEcPfImport extends DichiarazioniImport {

    private final TIPI_RECORDS = [(DichiarazioniImport.CODICI_FORNITURA.TAS00): ['B', 'C', 'D', 'E', '9'], // ENC
                                  (DichiarazioniImport.CODICI_FORNITURA.TAT00): ['B', 'C', 'D', '9'] // ECPF
    ]

    @Override
    def convert(def dati, def documentoId, def utente, def fields) {

        def dichiarazioni = [:]
        def converters = [:]

        def params = [progressivoDichiarazione: 0,
                      documentoId             : documentoId,
                      utente                  : utente?.id,
                      codiceTracciato         : determinaCodiceFornituraEnum(dati),
                      numeroRiga              : 0]

        dati.each { k, v ->
            params.numeroRiga++
            def presenzaErroriB = false

            def tipoRecord = determinaTipoRecord(v)
            log.info("Elaborazione riga [${k}] di tipo [$tipoRecord]...")

            if (tipoRecord in TIPI_RECORDS[params.codiceTracciato]) {
                if (converters[tipoRecord] == null) {
                    converters[tipoRecord] = EncEcPfRecordConverterFactory.converter(tipoRecord, params.codiceTracciato)
                }

                switch (tipoRecord) {
                    case 'B':
                        try {
                            params.progressivoDichiarazione++
                            dichiarazioni[params.progressivoDichiarazione] = [B: converters[tipoRecord].convert(v, params, fields)]
                        } catch (Exception e) {
                            log.error(e, e)
                            gestioneErrori(dichiarazioni[params.progressivoDichiarazione], e)
                        }
                        break
                    case 'C':
                        if (presenzaErroriB) {
                            anomaliaRecord(dichiarazioni[params.progressivoDichiarazione], "C", documentoId, v[2].valore, fields.numRiga)
                            break
                        }
                        try {
                            params.codiceFiscaleDichiaranteB = codFiscaleDichiaranteB(dichiarazioni[params.progressivoDichiarazione])
                            dichiarazioni[params.progressivoDichiarazione]['C'] = dichiarazioni[params.progressivoDichiarazione]['C'] ?: []
                            dichiarazioni[params.progressivoDichiarazione]['C'] += converters[tipoRecord].convert(v, params, fields)

                        } catch (Exception e) {
                            log.error(e, e)
                            gestioneErrori(dichiarazioni[params.progressivoDichiarazione], e)
                        }
                        break
                    case 'D':
                        if (presenzaErroriB) {
                            anomaliaRecord(dichiarazioni[params.progressivoDichiarazione], "D", documentoId, v[2].valore, fields.numRiga)
                            break
                        }
                        try {
                            if (params.codiceTracciato == DichiarazioniImport.CODICI_FORNITURA.TAS00 && !(v[19]?.valore?.trim())) {
                                // In alcune forniture del tracciato TAS00 sono presenti record di tipo D, quadro B,
                                // con valori non coerenti. Si testa la corretta valorizzazione del campo 19,
                                // tipo dell'oggetto, se non è settato si esclude la riga.
                                break
                            }
                            params.codiceFiscaleDichiaranteB = codFiscaleDichiaranteB(dichiarazioni[params.progressivoDichiarazione])
                            dichiarazioni[params.progressivoDichiarazione]['D'] = dichiarazioni[params.progressivoDichiarazione]['D'] ?: []
                            dichiarazioni[params.progressivoDichiarazione]['D'] += converters[tipoRecord].convert(v, params, fields)

                        } catch (Exception e) {
                            log.error(e, e)
                            gestioneErrori(dichiarazioni[params.progressivoDichiarazione], e)
                        }
                        break
                    case 'E':
                        if (presenzaErroriB) {
                            anomaliaRecord(dichiarazioni[params.progressivoDichiarazione], "E", documentoId, v[2].valore, fields.numRiga)
                            break
                        }
                        try {
                            params.codiceFiscaleDichiaranteB = codFiscaleDichiaranteB(dichiarazioni[params.progressivoDichiarazione])
                            def valoriE = converters[tipoRecord].convert(v, params, fields)
                            // Si aggiornato i dati nella testata
                            valoriE.each {
                                dichiarazioni[params.progressivoDichiarazione].B[it.key] = it.value
                            }
                            dichiarazioni[params.progressivoDichiarazione]['E'] = valoriE
                        } catch (Exception e) {
                            log.error(e, e)
                            gestioneErrori(dichiarazioni[params.progressivoDichiarazione], e)
                        }
                        break
                    case '9':
                        // nulla da fare
                        break
                }
            }
        }


        return dichiarazioni
    }

    private void gestioneErrori(def dichiarazione, def eccezione) {
        if (dichiarazione.errori == null) {
            dichiarazione.errori = []
        }

        if (eccezione instanceof EncEcPfException) {
            dichiarazione.errori += eccezione.anomalia
        }
    }

    private void anomaliaRecord(def dichiarazione, def tipoRecord, def documentoId, def codFiscale, def numRiga) {
        if (dichiarazione.errori == null) {
            dichiarazione.errori = []
        }

        dichiarazione.errori += new AnomalieCaricamentoDTO([documentoId: documentoId,
                                                            descrizione: "Tipo record $tipoRecord ignorato a causa di anomalie su Tipo record B",
                                                            codFiscale : codFiscale,
                                                            note       : numRiga])

    }

    private def codFiscaleDichiaranteB(def dichiarazione) {
        dichiarazione.B.codFiscale
    }
}
