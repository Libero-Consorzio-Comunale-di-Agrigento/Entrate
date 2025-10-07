package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.reports.beans.F24DettaglioBean

import java.math.RoundingMode

class DettaglioDatiF24ViolazioneVisitor extends DettaglioDatiF24VisitorAbstract {

    private final Map queryKeys = [
            // ICI
            "ABITAZIONEPRINCIPALE": ["key": "ABITAZIONEPRINCIPALE", "num": "NUMFABBABIPRI"],
            "TERRENI"             : ["key": "TERRENI", "num": ""],
            "AREE"                : ["key": "AREE", "num": ""],
            "ALTRI"               : ["key": "ALTRI", "num": "NUMFABALTRI"],
            "SANZIONI_ICI"        : ["key": "SANZIONI", "num": ""],
            "INTERESSI_ICI"       : ["key": "INTERESSI", "num": ""],
            // TASI
            "RIGA_TASI_1": ["COTR": ["key": "COTR_RIGA_1", "num": ""], "IMP": ["key": "IMPORTO_RIGA_1", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""]],
            "RIGA_TASI_2": ["COTR": ["key": "COTR_RIGA_2", "num": ""], "IMP": ["key": "IMPORTO_RIGA_2", "num": ""], "NFAB": ["key": "N_FAB_RIGA_2", "num": ""]],
            "RIGA_TASI_3": ["COTR": ["key": "COTR_RIGA_3", "num": ""], "IMP": ["key": "IMPORTO_RIGA_3", "num": ""], "NFAB": ["key": "N_FAB_RIGA_3", "num": ""]],
            // Ravvedimenti
            "RIGA_RAVP_1"        : ["COTR": ["key": "COTR_RIGA_1", "num": ""], "IMP": ["key": "IMPORTO_RIGA_1", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_1", "num": ""]],
            "RIGA_RAVP_2"        : ["COTR": ["key": "COTR_RIGA_2", "num": ""], "IMP": ["key": "IMPORTO_RIGA_2", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_2", "num": ""]],
            "RIGA_RAVP_3"        : ["COTR": ["key": "COTR_RIGA_3", "num": ""], "IMP": ["key": "IMPORTO_RIGA_3", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_3", "num": ""]],
            "RIGA_RAVP_4"        : ["COTR": ["key": "COTR_RIGA_4", "num": ""], "IMP": ["key": "IMPORTO_RIGA_4", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_4", "num": ""]],
            "RIGA_RAVP_5"        : ["COTR": ["key": "COTR_RIGA_5", "num": ""], "IMP": ["key": "IMPORTO_RIGA_5", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_5", "num": ""]],
            "RIGA_RAVP_6"        : ["COTR": ["key": "COTR_RIGA_6", "num": ""], "IMP": ["key": "IMPORTO_RIGA_6", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_6", "num": ""]],
            "RIGA_RAVP_7"        : ["COTR": ["key": "COTR_RIGA_7", "num": ""], "IMP": ["key": "IMPORTO_RIGA_7", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_7", "num": ""]],
            "RIGA_RAVP_8"        : ["COTR": ["key": "COTR_RIGA_8", "num": ""], "IMP": ["key": "IMPORTO_RIGA_8", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_8", "num": ""]],
            "RIGA_RAVP_9"        : ["COTR": ["key": "COTR_RIGA_9", "num": ""], "IMP": ["key": "IMPORTO_RIGA_9", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_9", "num": ""]],
            "RIGA_RAVP_10"       : ["COTR": ["key": "COTR_RIGA_10", "num": ""], "IMP": ["key": "IMPORTO_RIGA_10", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_10", "num": ""]],
            // TARSU
            "RIGA_TARSU_1"        : ["COTR": ["key": "COTR_RIGA_1", "num": ""], "IMP": ["key": "IMPORTO_RIGA_1", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_1", "num": ""]],
            "RIGA_TARSU_2"        : ["COTR": ["key": "COTR_RIGA_2", "num": ""], "IMP": ["key": "IMPORTO_RIGA_2", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_2", "num": ""]],
            "RIGA_TARSU_3"        : ["COTR": ["key": "COTR_RIGA_3", "num": ""], "IMP": ["key": "IMPORTO_RIGA_3", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_3", "num": ""]],
            "RIGA_TARSU_4"        : ["COTR": ["key": "COTR_RIGA_4", "num": ""], "IMP": ["key": "IMPORTO_RIGA_4", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_4", "num": ""]],
            "RIGA_TARSU_5"        : ["COTR": ["key": "COTR_RIGA_5", "num": ""], "IMP": ["key": "IMPORTO_RIGA_5", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_5", "num": ""]],
            "RIGA_TARSU_6"        : ["COTR": ["key": "COTR_RIGA_6", "num": ""], "IMP": ["key": "IMPORTO_RIGA_6", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_6", "num": ""]],
            "RIGA_TARSU_7"        : ["COTR": ["key": "COTR_RIGA_7", "num": ""], "IMP": ["key": "IMPORTO_RIGA_7", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_7", "num": ""]],
            "RIGA_TARSU_8"        : ["COTR": ["key": "COTR_RIGA_8", "num": ""], "IMP": ["key": "IMPORTO_RIGA_8", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_8", "num": ""]],
            "RIGA_TARSU_9"        : ["COTR": ["key": "COTR_RIGA_9", "num": ""], "IMP": ["key": "IMPORTO_RIGA_9", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_9", "num": ""]],
            "RIGA_TARSU_10"       : ["COTR": ["key": "COTR_RIGA_10", "num": ""], "IMP": ["key": "IMPORTO_RIGA_10", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""], "RATEAZ": ["key": "RATEAZ_RIGA_10", "num": ""]],
            // Imposte
            "RIGA_IMP_1"          : ["COTR": ["key": "COTR_RIGA_1", "num": ""], "IMP": ["key": "IMPORTO_RIGA_1", "num": ""], "NFAB": ["key": "N_FAB_RIGA_1", "num": ""]],
            "RIGA_IMP_2"          : ["COTR": ["key": "COTR_RIGA_2", "num": ""], "IMP": ["key": "IMPORTO_RIGA_2", "num": ""], "NFAB": ["key": "N_FAB_RIGA_2", "num": ""]],
            "RIGA_IMP_3"          : ["COTR": ["key": "COTR_RIGA_3", "num": ""], "IMP": ["key": "IMPORTO_RIGA_3", "num": ""], "NFAB": ["key": "N_FAB_RIGA_3", "num": ""]],
            "RIGA_IMP_4"          : ["COTR": ["key": "COTR_RIGA_4", "num": ""], "IMP": ["key": "IMPORTO_RIGA_4", "num": ""], "NFAB": ["key": "N_FAB_RIGA_4", "num": ""]],
            "RIGA_IMP_5"          : ["COTR": ["key": "COTR_RIGA_5", "num": ""], "IMP": ["key": "IMPORTO_RIGA_5", "num": ""], "NFAB": ["key": "N_FAB_RIGA_5", "num": ""]],
            "RIGA_IMP_6"          : ["COTR": ["key": "COTR_RIGA_6", "num": ""], "IMP": ["key": "IMPORTO_RIGA_6", "num": ""], "NFAB": ["key": "N_FAB_RIGA_6", "num": ""]],
            "RIGA_IMP_7"          : ["COTR": ["key": "COTR_RIGA_7", "num": ""], "IMP": ["key": "IMPORTO_RIGA_7", "num": ""], "NFAB": ["key": "N_FAB_RIGA_7", "num": ""]],
            "RIGA_IMP_8"          : ["COTR": ["key": "COTR_RIGA_8", "num": ""], "IMP": ["key": "IMPORTO_RIGA_8", "num": ""], "NFAB": ["key": "N_FAB_RIGA_8", "num": ""]],
            "RIGA_IMP_9"          : ["COTR": ["key": "COTR_RIGA_9", "num": ""], "IMP": ["key": "IMPORTO_RIGA_9", "num": ""], "NFAB": ["key": "N_FAB_RIGA_9", "num": ""]],
            "RIGA_IMP_10"         : ["COTR": ["key": "COTR_RIGA_10", "num": ""], "IMP": ["key": "IMPORTO_RIGA_10", "num": ""], "NFAB": ["key": "N_FAB_RIGA_10", "num": ""]],
            // Altro
            "ANNO"                : ["key": "ANNO", "num": ""],
    ]

    /*
        ATTENZIONE: la distinzione per tipo tributo era nata quando nelle strutture si gestivano i codici tributo,
        informazioni oggi recuperate direttamente nelle query. Per questo motivo con il solo dettaglio relativo ad ICI
        si possono stampare tutti gli F24. Si dovrebbe fare un lavoro di refactoring per ripulire il codice ed utilizzare
        un solo DettaglioDati.
     */

    @Override
    void visit(DettaglioDatiF24ICI dettaglioF24) {

        if (dettaglioF24.dettagli == null) {
            return
        }

        // RAVVEDIMENTO OPEROSO
        if (dettaglioF24.dettagli[0].RAVVEDIMENTO == "X") {
            creaRigheDettaglioRavp(dettaglioF24 as DettaglioDatiF24ICI)
        } else if (dettaglioF24.dettagli[0].TRIBUTO == "ICI") {
            // ICI
            if ((dettaglioF24.dettagli[0].ANNO.trim() as Integer) < 2012) {
                creaRigheDettaglioICI(dettaglioF24 as DettaglioDatiF24ICI)
            } else if ((dettaglioF24.dettagli[0].ANNO.trim() as Integer) >= 2012) {
                // IMU
                creaRigheDettaglioTASI(dettaglioF24 as DettaglioDatiF24ICI)
            }
        } else if (dettaglioF24.dettagli[0].TRIBUTO == "TASI") {
            // TASI
            creaRigheDettaglioTASI(dettaglioF24 as DettaglioDatiF24ICI)
        } else if (dettaglioF24.dettagli[0].TRIBUTO == "TARSU") {
            // TARSU
            creaRigheDettaglioTARSU(dettaglioF24 as DettaglioDatiF24ICI)
        } else if (dettaglioF24.dettagli[0].TRIBUTO in ['ICP', 'TOSAP']) {
            // ICP
            creaRigheDettaglioICP(dettaglioF24 as DettaglioDatiF24ICI)
        } else if (dettaglioF24.dettagli[0].TIPO == "I") {
            creaRigheDettaglioImposta(dettaglioF24 as DettaglioDatiF24ICI)
        }

        // dettaglioF24.f24Bean.dettagli.sort { it.codiceTributo }
    }

    private void creaRigheDettaglioIMU(DettaglioDatiF24ICI dettaglioF24) {
        // Sanzioni
        creaSingolaRiga(dettaglioF24, queryKeys.SANZIONI_ICI)

        // Interessi
        creaSingolaRiga(dettaglioF24, queryKeys.INTERESSI_ICI)
    }

    private void creaRigheDettaglioTASI(DettaglioDatiF24ICI dettaglioF24) {
        creaSingolaRigaTASI(dettaglioF24, queryKeys.RIGA_TASI_1)
        creaSingolaRigaTASI(dettaglioF24, queryKeys.RIGA_TASI_2)
        creaSingolaRigaTASI(dettaglioF24, queryKeys.RIGA_TASI_3)
    }

    private void creaRigheDettaglioICI(DettaglioDatiF24ICI dettaglioF24) {

        // Abitazione principale
        creaSingolaRiga(dettaglioF24, queryKeys.ABITAZIONEPRINCIPALE)

        // Terreni
        creaSingolaRiga(dettaglioF24, queryKeys.TERRENI)

        // Aree
        creaSingolaRiga(dettaglioF24, queryKeys.AREE)

        // Altri
        creaSingolaRiga(dettaglioF24, queryKeys.ALTRI)

        // Sanzioni
        creaSingolaRiga(dettaglioF24, queryKeys.SANZIONI_ICI)

        // Interessi
        creaSingolaRiga(dettaglioF24, queryKeys.INTERESSI_ICI)

    }

    private void creaRigheDettaglioImposta(DettaglioDatiF24ICI dettaglioF24) {
        (1..10).each {
            creaSingolaRigaImp(dettaglioF24, queryKeys."RIGA_IMP_${it}")
        }
    }

    private void creaRigheDettaglioRavp(DettaglioDatiF24ICI dettaglioF24) {
        (1..10).each {
            creaSingolaRigaRavp(dettaglioF24, queryKeys."RIGA_RAVP_${it}")
        }
    }

    private void creaRigheDettaglioTARSU(DettaglioDatiF24ICI dettaglioF24) {
        (1..10).each {
            creaSingolaRigaTARSU(dettaglioF24, queryKeys."RIGA_TARSU_${it}")
        }
    }

    private void creaRigheDettaglioICP(DettaglioDatiF24ICI dettaglioF24) {
        (1..10).each {
            creaSingolaRigaTARSU(dettaglioF24, queryKeys."RIGA_TARSU_${it}")
        }
    }

    private void creaSingolaRiga(DettaglioDatiF24ICI dettaglioF24, Map keys) {

        dettaglioF24.dettagli.each { row ->

            if ((Math.round(row[keys.key] ?: 0)) != 0) {

                F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()
                f24DettaglioBean.sezione = "EL"
                f24DettaglioBean.codiceEnte = dettaglioF24.siglaComune

                f24DettaglioBean.importiDebito = new BigDecimal(row[keys.key]).setScale(0, RoundingMode.HALF_UP)
                f24DettaglioBean.numeroImmobili = row[keys.NFAB.key]?.trim() ? new Integer(row[keys.NFAB.key].trim() + "") : null
                f24DettaglioBean.annoRiferimento = row[queryKeys.ANNO.key]

                if (row.CODTRIBUTOF24 == null) {
                    throw new RuntimeException("NOC_COD_TRIBUTO", new Throwable("Inserire l'indicazione del Codice Tributo F24 nei dizionari delle Sanzioni."))
                }

                f24DettaglioBean.codiceTributo = row.CODTRIBUTOF24

                f24DettaglioBean.rateazione = ""

                f24DettaglioBean.acconto = "X"
                f24DettaglioBean.saldo = "X"

                dettaglioF24.f24Bean.dettagli << f24DettaglioBean
            }
        }
    }

    private void creaSingolaRigaTASI(DettaglioDatiF24ICI dettaglioF24, Map keys) {
        dettaglioF24.dettagli.each { row ->
            if ((Math.round(row[keys.IMP.key] ?: 0)) != 0) {

                F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()
                f24DettaglioBean.sezione = "EL"
                f24DettaglioBean.codiceEnte = dettaglioF24.siglaComune

                f24DettaglioBean.importiDebito = new BigDecimal(row[keys.IMP.key]).setScale(0, RoundingMode.HALF_UP)
                f24DettaglioBean.numeroImmobili = row[keys.NFAB.key]?.trim() ? new Integer(row[keys.NFAB.key].trim() + "") : null
                f24DettaglioBean.annoRiferimento = row[queryKeys.ANNO.key]

                f24DettaglioBean.codiceTributo = row[keys.COTR.key]

                f24DettaglioBean.rateazione = ""

                f24DettaglioBean.acconto = "X"
                f24DettaglioBean.saldo = "X"

                dettaglioF24.f24Bean.dettagli << f24DettaglioBean
            }
        }
    }

    private void creaSingolaRigaRavp(DettaglioDatiF24ICI dettaglioF24, Map keys) {
        dettaglioF24.dettagli.each { row ->

            if ((Math.round(row[keys.IMP.key] ?: 0)) != 0) {

                F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()
                f24DettaglioBean.sezione = "EL"
                f24DettaglioBean.codiceEnte = dettaglioF24.siglaComune

                f24DettaglioBean.importiDebito = new BigDecimal(row[keys.IMP.key]).setScale(0, RoundingMode.HALF_UP)
                f24DettaglioBean.numeroImmobili = keys.IMP.num != "" ? new Integer(row[keys.IMP.num] + "") : null
                f24DettaglioBean.annoRiferimento = row[queryKeys.ANNO.key]

                f24DettaglioBean.codiceTributo = row[keys.COTR.key]

                f24DettaglioBean.rateazione = (row[keys.RATEAZ?.key] ?: '')

                f24DettaglioBean.acconto = (row['ACCONTO']?.trim() ? 'X' : '')
                f24DettaglioBean.saldo = (row['SALDO']?.trim() ? 'X' : '')
                f24DettaglioBean.ravvedimento = 'X'

                def numFabb = row[keys.NFAB.key]?.trim()

                if (numFabb && !numFabb.isEmpty()) {
                    f24DettaglioBean.numeroImmobili = (numFabb as Integer)
                }

                dettaglioF24.f24Bean.dettagli << f24DettaglioBean
            }
        }
    }

    private void creaSingolaRigaImp(DettaglioDatiF24ICI dettaglioF24, Map keys) {
        dettaglioF24.dettagli.each { row ->

            if ((Math.round(row[keys.IMP.key] ?: 0)) != 0) {

                F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()
                f24DettaglioBean.sezione = "EL"
                f24DettaglioBean.codiceEnte = dettaglioF24.siglaComune
                f24DettaglioBean.titoloF24 = row["TITOLO_F24"]

                f24DettaglioBean.importiDebito = new BigDecimal(row[keys.IMP.key]).setScale(0, RoundingMode.HALF_UP)
                f24DettaglioBean.numeroImmobili = keys.IMP.num != "" ? new Integer(row[keys.IMP.num] + "") : null
                f24DettaglioBean.annoRiferimento = row[queryKeys.ANNO.key]

                f24DettaglioBean.codiceTributo = row[keys.COTR.key]

                f24DettaglioBean.rateazione = ""

                f24DettaglioBean.acconto = (row['ACCONTO']?.trim() ? 'X' : '')
                f24DettaglioBean.saldo = (row['SALDO']?.trim() ? 'X' : '')

                def numFabb = row[keys.NFAB.key]?.trim()

                if (numFabb && !numFabb.isEmpty()) {
                    f24DettaglioBean.numeroImmobili = (numFabb as Integer)
                }

                dettaglioF24.f24Bean.dettagli << f24DettaglioBean
            }
        }
    }

    private void creaSingolaRigaTARSU(DettaglioDatiF24ICI dettaglioF24, Map keys) {
        dettaglioF24.dettagli.each { row ->

            if ((Math.round(row[keys.IMP.key] ?: 0)) != 0) {

                F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()
                f24DettaglioBean.sezione = "EL"
                f24DettaglioBean.codiceEnte = dettaglioF24.siglaComune

                f24DettaglioBean.importiDebito = new BigDecimal(row[keys.IMP.key]).setScale(0, RoundingMode.HALF_UP)
                f24DettaglioBean.numeroImmobili = keys.IMP.num != "" ? new Integer(row[keys.IMP.num] + "") : null
                f24DettaglioBean.annoRiferimento = row[queryKeys.ANNO.key]

                f24DettaglioBean.codiceTributo = row[keys.COTR.key]

                f24DettaglioBean.rateazione = row[keys.RATEAZ.key] ?: ''

                f24DettaglioBean.acconto = (row['ACCONTO']?.trim() ? 'X' : '')
                f24DettaglioBean.saldo = (row['SALDO']?.trim() ? 'X' : '')

                def numFabb = row[keys.NFAB.key]?.trim()

                if (numFabb && !numFabb.isEmpty()) {
                    f24DettaglioBean.numeroImmobili = (numFabb as Integer)
                }

                dettaglioF24.f24Bean.dettagli << f24DettaglioBean
            }
        }
    }
}
