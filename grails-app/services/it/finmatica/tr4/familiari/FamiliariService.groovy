package it.finmatica.tr4.familiari


import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.ContribuentiService

import java.text.SimpleDateFormat

class FamiliariService {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE
    }

    ContribuentiService contribuentiService
    CommonService commonService

    def verificaFamiliare(def familiare, def listaFamiliari, def tipoOperazione) {

        def errorMessage = ""

        //Controllo presenza parametro numero familiari obbligatorio
        if (!familiare.numeroFamiliari) {
            errorMessage += "Il valore Numero Familiari è obbligatorio\n"
        }

        //Controllo linearità date
        if (familiare.dal) {
            if (familiare.dal > (familiare.al ?: new Date(Long.MAX_VALUE))) {
                errorMessage += "Il valore Dal non può essere maggiore di Al\n"
            }
        } else {
            errorMessage += "Il valore Dal non può essere vuoto\n"
        }

        //Controllo se le date hanno lo stesso anno del parametro anno
        if (familiare.anno && familiare.dal) {
            if (familiare.anno != commonService.yearFromDate(familiare.dal) ||
                    familiare.al && familiare.anno != commonService.yearFromDate(familiare.al)) {
                errorMessage += "Gli anni delle date Dal e Al devono coincidere con l'anno ${familiare.anno}\n"
            }
        }

        // In inserimento, controllo se esiste già un'entità con lo stesso id composto (soggetto-anno-dal)
        if (tipoOperazione in [TipoOperazione.INSERIMENTO, TipoOperazione.CLONAZIONE]) {
            if (contribuentiService.getFamiliareContribuente(familiare.soggetto, familiare.anno, familiare.dal)) {
                errorMessage += "Esiste già un Familiare con lo stesso Anno e data Dal\n"
            }
        }

        def messaggioData = controllaIntersezioniDate(familiare, listaFamiliari)
        if (!messaggioData.empty) {
            errorMessage += messaggioData
        }

        return errorMessage
    }


    def controllaIntersezioniDate(def familiare, def listaFamiliari) {

        if (!listaFamiliari.empty && familiare?.dal != null) {

            def listaDate = []

            def listaFamiliariTmp = listaFamiliari.collect {
                [
                        dal        : it.dal,
                        al         : it.al,
                        anno       : it.anno,
                        lastUpdated: it.lastUpdated
                ]
            }

            chiudiPeriodiAperti(listaFamiliariTmp).each {

                listaDate += [
                        dataInizio: it.dal,
                        dataFine  : it.al
                ]
            }

            if (commonService.isOverlapping(familiare.dal, familiare.al, listaDate)) {
                return "Sono presenti delle intersezioni di periodo Dal/Al tra le altre date Familiari"
            } else {
                return ""
            }

        }

        return ""
    }

    def getNumPeriodiAperti(def listaFamiliari) {
        return listaFamiliari.count { !it.al }
    }

    def chiudiPeriodiAperti(def listaFamiliari, def salva = false, def updateDataVariazione = false) {

        def familiariResult = []

        //Raggruppa le date per anno e ordina ogni data in ordine decrescente rispetto al parametro dal
        def familiariPerAnno = listaFamiliari.groupBy {
            it.anno
        }.each {
            it.value = it.value.sort { it.dal }.reverse()
        }

        def maxAnno = listaFamiliari.collect { it.anno }.max()

        /** Per ogni data, quella maggiore viene completata con l'ultima dell'anno,
         *  mentre ognuna delle precedenti viene completata come la successiva meno 1 giorno
         *  L'ultimo anno non si chiude automaticamente.
         */
        familiariPerAnno.each { anno ->
            def familiari = anno.value

            for (int i = 0; i < familiari.size(); i++) {

                if (anno.key < maxAnno) {
                    if (i == 0) {
                        familiari[i].al = familiari[i].al ?:
                                new SimpleDateFormat("yyyyMMdd").parse("${anno.key}1231")
                    } else {
                        familiari[i].al = familiari[i].al ?:
                                familiari[i - 1].dal.minus(1)
                    }

                    if (updateDataVariazione) {
                        familiari[i].lastUpdated = new Date()
                    }
                }

                familiariResult << familiari[i]

                if (salva) {
                    familiari[i].toDomain().save(failOnError: true, flush: true)
                }
            }
        }

        return familiariResult
    }

}
