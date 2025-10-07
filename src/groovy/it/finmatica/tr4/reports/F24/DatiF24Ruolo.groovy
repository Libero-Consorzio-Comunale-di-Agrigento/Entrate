package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.reports.beans.F24Bean
import org.hibernate.FetchMode

class DatiF24Ruolo extends AbstractDatiF24 {

    ImposteService imposteService

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, Long ruolo, String tipo, String rataUnica) {

        def r = Ruolo.get(ruolo)

        List<F24Bean> listaF24 = new ArrayList<F24Bean>()

        ContribuenteDTO contribuente = Contribuente.createCriteria().get {
            eq("codFiscale", codiceFiscale)
            fetchMode("soggetto", FetchMode.JOIN)
        }.toDTO([
                "soggetto",
                "soggetto.comuneNascita",
                "soggetto.comuneNascita.ad4Comune",
                "soggetto.comuneNascita.ad4Comune.provincia"
        ])

        // String stampaTrib = 'S', String stampaMagg = 'S'
        def righe = imposteService.f24Ruolo(codiceFiscale, ruolo,
                tipo == 'COMPLETO' || tipo == 'TRIBUTO' ? 'S' : 'N',
                tipo == 'COMPLETO' || tipo == 'MAGGIORAZIONE' ? 'S' : 'N')

        for (int i = 0; i < righe.size() - (rataUnica in ['S', 'SI'] ? 0 : 1); i++) {

            if (righe[i]['ORD2'] == 99 && (tipo == 'MAGGIORAZIONE' || r.rate == 1)) continue

            inizializzaF24(contribuente)
            f24Bean.identificativoOperazione = righe[i]['IDENTIFICATIVO_OPERAZIONE']
            DettaglioDatiF24Ruolo dettaglioF24ruolo = new DettaglioDatiF24Ruolo(siglaComune, tipoPagamento, f24Bean, righe[i])
            dettaglioF24ruolo.accept(new DettaglioDatiF24Visitor())

            f24Bean.saldo = f24Bean.dettagli.sum { it.importiDebito }
            listaF24.add(f24Bean)
        }

        return listaF24
    }

    private inizializzaF24(def contribuente) {
        f24Bean = new F24Bean()
        gestioneTestata(contribuente)
    }


}
