package it.finmatica.tr4.reports.F24

import groovy.sql.Sql
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.contribuenti.F24ImposteService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.beans.F24Bean
import org.hibernate.FetchMode

class DatiF24Imposta extends AbstractDatiF24 {

    F24ImposteService f24ImposteService
    ContribuentiService contribuentiService

    @Override
    List<F24Bean> getDatiF24(short anno, String tipoTributo, String codFiscale, String tipoVersamento, String dovutoVersato) {
        List<F24Bean> listaF24 = new ArrayList<F24Bean>()

        f24Bean = new F24Bean()

        ContribuenteDTO contribuente = Contribuente.createCriteria().get {
            eq("codFiscale", codFiscale)
            fetchMode("soggetto", FetchMode.JOIN)
        }.toDTO([
                "soggetto",
                "soggetto.comuneNascita",
                "soggetto.comuneNascita.ad4Comune",
                "soggetto.comuneNascita.ad4Comune.provincia"
        ])

        gestioneTestata(contribuente)
        gestioneErede([codFiscale: contribuentiService.fPrimoEredeCodFiscale(contribuente.soggetto.id)])

        listaF24.add(f24Bean)

        def dettaglio = f24ImposteService.f24ImpostaDettaglio(anno, tipoTributo, codFiscale, tipoVersamento, dovutoVersato)
        DettaglioDatiF24ICI dettaglioF24ICI = new DettaglioDatiF24ICI(siglaComune, tipoPagamento, f24Bean, dettaglio)
        dettaglioF24ICI.accept(new DettaglioDatiF24ViolazioneVisitor())
        f24Bean.saldo = f24Bean.dettagli.sum {it.importiDebito}

        return listaF24

    }
}
