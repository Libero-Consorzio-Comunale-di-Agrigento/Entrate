package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.reports.beans.F24Bean
import it.finmatica.tr4.reports.beans.F24DettaglioBean

abstract class AbstractDatiF24 implements DatiF24 {

    String siglaComune //codice ente
    int tipoPagamento  // acconto - saldo - unico

    //protected RigaDettaglioVisitor rigaDettaglioVisitor //oggetto per gestire le 'differenze' tra ICI e TASI
    protected F24Bean f24Bean //rappresenta il modello F24

    @Override
    void setSiglaComune(String siglaComune) {
        this.siglaComune = siglaComune
    }

    @Override
    void setTipoPagamento(int tipoPagamento) {
        this.tipoPagamento = tipoPagamento
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, short anno) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, short anno, Map data) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    @Override
    List<F24Bean> getDatiF24(Long pratica, Boolean ridotto) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, Long ruolo, String tipo) {
        return getDatiF24(codiceFiscale, ruolo, tipo, 'SI')
    }

    @Override
    List<F24Bean> getDatiF24(String codiceFiscale, Long ruolo, String tipo, String rataUnica) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    @Override
    List<F24Bean> getDatiF24(short anno, String tipoTributo, String codFiscale, String tipoVersamento, String dovutoVersato) {
        throw new RuntimeException("Funzionalità non implementata")
    }

    protected String generaIdentificativoOperazione(PraticaTributoDTO praticaDTO, def rata = null) {
        return CommonService.generaIdentificativoOperazione(praticaDTO, rata)
    }

    def gestioneTestata(ContribuenteDTO contribuente) {

        f24Bean.codFiscale = contribuente.codFiscale.padRight(16, ' ')
        f24Bean.cognome = contribuente.soggetto.cognome
        f24Bean.nome = contribuente.soggetto.nome
        f24Bean.dataNascita = contribuente.soggetto.dataNas
        f24Bean.sesso = contribuente.soggetto.sesso
        f24Bean.comune = contribuente.soggetto.comuneNascita?.ad4Comune?.denominazione
        f24Bean.provincia = contribuente.soggetto.comuneNascita?.ad4Comune?.provincia?.sigla
        f24Bean.dettagli = new ArrayList<F24DettaglioBean>()

    }

    def gestioneErede(def erede) {
        f24Bean.codFiscaleErede = erede.codFiscale ?: ''.padRight(16, ' ')
        f24Bean.codiceIdentificativo = erede.codFiscale ? '07' : ''.padRight(2, ' ')
    }
}
