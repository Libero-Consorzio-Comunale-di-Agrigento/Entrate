package it.finmatica.tr4.reports

import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.WebCalcoloIndividuale
import it.finmatica.tr4.reports.F24.DatiF24
import it.finmatica.tr4.reports.F24.DatiF24Factory
import it.finmatica.tr4.reports.beans.F24Bean
import org.hibernate.transform.AliasToEntityMapResultTransformer

class F24Service {
    static transactional = false
    DatiF24Factory datiF24Factory
    DatiGeneraliService datiGeneraliService
    def sessionFactory

    def caricaDatiF24(String codiceFiscale, String tipoTributo, int tipoPagamento, short anno) {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, tipoTributo, tipoPagamento)
        List<F24Bean> f24 = datiF24.getDatiF24(codiceFiscale, anno)
    }

    def caricaDatiF24(String codiceFiscale) {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, "Bianco", -1)
        List<F24Bean> f24 = datiF24.getDatiF24(codiceFiscale)
    }

    def caricaDatiF24(def pratica, def tipo = 'V', def ridotto = false) {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, pratica, tipo)
        List<F24Bean> f24 = datiF24.getDatiF24(pratica.id as Long, ridotto)
    }

    def caricaDatiF24(String codiceFiscale, Long ruolo, String tipo, String rataUnica = 'S') {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, 'Ruolo', -1)
        List<F24Bean> f24 = datiF24.getDatiF24(codiceFiscale, ruolo, tipo, rataUnica)
    }

    def caricaDatiF24(short anno, String tipoTributo, String codFiscale, String tipoVersamento, String dovutoVersato) {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, null, 'I')
        List<F24Bean> f24 = datiF24.getDatiF24(anno, tipoTributo, codFiscale, tipoVersamento, dovutoVersato)
    }

    def caricaDatiF24(String codiceFiscale, String tipoTributo, int tipoPagamento, short anno, Map data) {
        Ad4ComuneDTO ad4Comune = datiGeneraliService.getComuneCliente()
        DatiF24 datiF24 = datiF24Factory.creaDatiF24(ad4Comune.siglaCodiceFiscale, tipoTributo, tipoPagamento)
        List<F24Bean> f24 = datiF24.getDatiF24(codiceFiscale, anno, data)
    }

    def checkF24Tributo(String tipoTributo, def idPratica) {

        def sql = """
                select count(1) "valore"
                  from sanzioni sanz, sanzioni_pratica sapr
                 where sapr.pratica = :pPratica
                   and sapr.cod_sanzione = sanz.cod_sanzione
                   and sapr.sequenza_sanz = sanz.sequenza
                   and sanz.tipo_tributo = '${tipoTributo}'
                   and sanz.cod_tributo_f24 is null
		"""

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('pPratica', idPratica)

            list()
        }[0].valore == 0
    }

    def checkF24Tarsu(def idPratica) {
        return checkF24Tributo('TARSU', idPratica)
    }

    def existsCalcoloIndividuale(tipoTributo, anno, codFiscale) {

        def results = WebCalcoloIndividuale.createCriteria().list {
            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("anno", anno as short)
            eq("contribuente.codFiscale", codFiscale)
        }

        return !results.empty
    }
}
