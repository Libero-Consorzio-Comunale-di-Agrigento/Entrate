package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.contribuenti.F24RateService
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.beans.F24Bean

import java.text.DecimalFormat

class DatiF24Rate extends AbstractDatiF24 {

    F24RateService f24RateService

    @Override
    List<F24Bean> getDatiF24(Long pratica, Boolean ridotto) {
        List<F24Bean> listaF24 = new ArrayList<F24Bean>()


        PraticaTributoDTO praticaDTO = PraticaTributo.get(pratica).toDTO([
                "contribuente",
                "contribuente.soggetto.comuneNascita",
                "contribuente.soggetto.comuneNascita.ad4Comune",
                "contribuente.soggetto.comuneNascita.ad4Comune.provincia"
        ])

        def dettaglio = f24RateService.f24RateDettaglio(pratica)
        def rata = 1
        dettaglio.each {
            f24Bean = new F24Bean()

            // Crezione identificativo operazione
            String identificativoOperazione = generaIdentificativoOperazione(praticaDTO, rata++)

            gestioneTestata(praticaDTO.contribuente)
            f24Bean.identificativoOperazione = identificativoOperazione

            listaF24.add(f24Bean)

            DettaglioDatiF24 dettaglioF24 = new DettaglioDatiF24(siglaComune, tipoPagamento, f24Bean, it)
            dettaglioF24.accept(new DettaglioDatiF24RateVisitor())

            f24Bean.saldo = f24Bean.dettagli.sum { it.importiDebito }
            f24Bean.saldoDecimali = new DecimalFormat("#,##0.00").format(f24Bean.saldo)[-2..-1]
        }

        return listaF24

    }
}
