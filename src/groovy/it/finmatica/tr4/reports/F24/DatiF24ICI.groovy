package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.WebCalcoloIndividuale
import it.finmatica.tr4.dto.WebCalcoloIndividualeDTO
import it.finmatica.tr4.reports.beans.F24Bean
import it.finmatica.tr4.reports.beans.F24DettaglioBean
import org.hibernate.FetchMode

import java.sql.Date
import java.text.SimpleDateFormat

class DatiF24ICI extends AbstractDatiF24 {


    @Override
    public List<F24Bean> getDatiF24(String codiceFiscale, short anno) {
        List<F24Bean> listaF24 = new ArrayList<F24Bean>()

        WebCalcoloIndividualeDTO webCalcoloIndividuale = WebCalcoloIndividuale.createCriteria().get {
            eq("contribuente.codFiscale", codiceFiscale)
            eq("tipoTributo.tipoTributo", "ICI")
            eq("anno", anno)
            fetchMode("contribuente", FetchMode.JOIN)
            fetchMode("contribuente.soggetto", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita.ad4Comune", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita.ad4Comune.provincia", FetchMode.JOIN)
            fetchMode("webCalcoloDettagli", FetchMode.JOIN)
        }.toDTO(["webCalcoloDettagli", "contribuente", "contribuente.soggetto.comuneNascita", "contribuente.soggetto.comuneNascita.ad4Comune", "contribuente.soggetto.comuneNascita.ad4Comune.provincia"])

        f24Bean = new F24Bean();
        super.gestioneTestata(webCalcoloIndividuale.contribuente)

        DettaglioDatiF24ICI dettaglioF24ICI = new DettaglioDatiF24ICI(siglaComune, tipoPagamento, f24Bean, webCalcoloIndividuale.webCalcoloDettagli)
        dettaglioF24ICI.accept(new DettaglioDatiF24Visitor())
        f24Bean.dettagli.sort { it.codiceTributo }
        f24Bean.dettagli.find { it.codiceTributo == DettaglioDatiF24ICI.codiciTributo["ABITAZIONE_PRINCIPALE"] }?.detrazione = dettaglioF24ICI.detrazione
        f24Bean.saldo = f24Bean.dettagli.sum { it.importiDebito }
        listaF24.add(f24Bean)

        return listaF24
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, short anno, Map data) {
        List<F24Bean> listaF24 = new ArrayList<F24Bean>()

        WebCalcoloIndividualeDTO webCalcoloIndividuale = WebCalcoloIndividuale.createCriteria().get {
            eq("contribuente.codFiscale", codiceFiscale)
            eq("tipoTributo.tipoTributo", "ICI")
            eq("anno", anno)
            fetchMode("contribuente", FetchMode.JOIN)
            fetchMode("contribuente.soggetto", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita.ad4Comune", FetchMode.JOIN)
            fetchMode("contribuente.soggetto.comuneNascita.ad4Comune.provincia", FetchMode.JOIN)
            fetchMode("webCalcoloDettagli", FetchMode.JOIN)
        }.toDTO(["webCalcoloDettagli", "contribuente", "contribuente.soggetto.comuneNascita", "contribuente.soggetto.comuneNascita.ad4Comune", "contribuente.soggetto.comuneNascita.ad4Comune.provincia"])

        f24Bean = new F24Bean();

        if (codiceFiscale.toUpperCase().startsWith("GUEST")) {
            gestioneTestata(codiceFiscale, data)
        } else {
            f24Bean.codFiscaleErede = data?.codFiscaleCoobbligato
            f24Bean.codiceIdentificativo = data?.codIdentificativo
            super.gestioneTestata(webCalcoloIndividuale.contribuente)
        }

        DettaglioDatiF24ICI dettaglioF24ICI = new DettaglioDatiF24ICI(siglaComune, tipoPagamento, f24Bean, webCalcoloIndividuale.webCalcoloDettagli)
        dettaglioF24ICI.accept(new DettaglioDatiF24Visitor())
        f24Bean.dettagli.sort { it.codiceTributo }
        f24Bean.dettagli.find { it.codiceTributo == DettaglioDatiF24ICI.codiciTributo["ABITAZIONE_PRINCIPALE"] }?.detrazione = dettaglioF24ICI.detrazione
        f24Bean.saldo = f24Bean.dettagli.sum { it.importiDebito }
        listaF24.add(f24Bean)


        return listaF24
    }


    def gestioneTestata(def codFiscale, Map data) {

        f24Bean.codFiscale = data?.soggettoCf?.padRight(16, ' ') ?: "".padRight(16, ' ')
        f24Bean.cognome = data?.soggettoCognome ?: ""
        f24Bean.nome = data?.soggettoNome ?: ""

        if (data?.soggettoDataNascita != null && data.soggettoDataNascita != "") {
            f24Bean.dataNascita = new Date(new SimpleDateFormat("ddMMyyyy").parse(data?.soggettoDataNascita).time)
        }
        f24Bean.sesso = data?.soggettoSesso
        f24Bean.comune = data?.soggettoLuogoNascita
        f24Bean.provincia = data?.soggettoProvNascita
        f24Bean.dettagli = new ArrayList<F24DettaglioBean>()

        f24Bean.codFiscaleErede = data?.codFiscaleCoobbligato ?: ""
        f24Bean.codiceIdentificativo = data?.codIdentificativo ?: ""

    }


}
