package it.finmatica.tr4.svuotamenti

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Oggetto
import it.finmatica.tr4.Svuotamento

@Transactional
class SvuotamentiService {

    def dataSource

    def eliminaSvuotamento(def contribuente, def oggetto, def rfid, def sequenza) {
        return Svuotamento
                .findByContribuenteAndOggettoAndCodRfidAndSequenza(contribuente, Oggetto.get(oggetto), rfid, sequenza)
                ?.delete(falush: true, failOnError: true)
    }

    def salvaSvuotamento(def svuotamento, def old) {

        if (old && old.rfid?.idCodiceRfid != svuotamento.idCodiceRfid) {
            eliminaSvuotamento(old.contribuente, old.oggetto, old.codRfid, old.sequenza)
        }

        def svuotamentoInstance = new Svuotamento(svuotamento)

        svuotamentoInstance.sequenza = (svuotamentoInstance.sequenza && old.rfid?.idCodiceRfid == svuotamento.idCodiceRfid) ?:
                getNextSequenza(svuotamentoInstance.contribuente.codFiscale, svuotamentoInstance.oggetto.id, svuotamentoInstance.codRfid)

        return svuotamentoInstance.save(flush: true, failOnError: true)
    }


    private def getNextSequenza(def codFiscale, def oggetto, def codRfid) {

        Short newSequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call svuotamenti_nr(?, ?, ?, ?)}',
                [
                        codFiscale,
                        oggetto,
                        codRfid,
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }

}
