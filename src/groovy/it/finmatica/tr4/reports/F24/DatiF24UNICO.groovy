package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.WebCalcoloDettaglio
import it.finmatica.tr4.dto.WebCalcoloDettaglioDTO
import it.finmatica.tr4.reports.beans.F24Bean
import it.finmatica.tr4.sportello.TipoOggettoCalcolo

import java.math.RoundingMode

import org.hibernate.FetchMode
import org.hibernate.criterion.CriteriaSpecification

class DatiF24UNICO extends AbstractDatiF24 {
	@Override
	public List<F24Bean> getDatiF24(String codiceFiscale, short anno) {
		List<F24Bean> listaF24 = new ArrayList<F24Bean>()

		List<WebCalcoloDettaglioDTO> webCalcoloDettagli = WebCalcoloDettaglio.createCriteria().list{
			createAlias("calcoloIndividuale", "cain", CriteriaSpecification.INNER_JOIN)	
			
			eq("cain.contribuente.codFiscale"	, codiceFiscale)
			eq("cain.anno"						, anno)
						
			or {
				gt("acconto"	, BigDecimal.ZERO)
				gt("saldo"		, BigDecimal.ZERO)
				gt("accontoErar", BigDecimal.ZERO)
				gt("saldoErar"	, BigDecimal.ZERO)
			}
			fetchMode("cain.contribuente", FetchMode.JOIN)
			fetchMode("cain.tipoTributo", FetchMode.JOIN)
			fetchMode("cain.contribuente.soggetto", FetchMode.JOIN)
			fetchMode("cain.contribuente.soggetto.comuneNascita", FetchMode.JOIN)
			fetchMode("cain.contribuente.soggetto.comuneNascita.ad4Comune", FetchMode.JOIN)
			fetchMode("cain.contribuente.soggetto.comuneNascita.ad4Comune.provincia", FetchMode.JOIN)
			
			order("cain.tipoTributo.tipoTributo")
		}.toDTO(["calcoloIndividuale", "calcoloIndividuale.contribuente", "calcoloIndividuale.contribuente.soggetto.comuneNascita", "calcoloIndividuale.contribuente.soggetto.comuneNascita.ad4Comune", "calcoloIndividuale.contribuente.soggetto.comuneNascita.ad4Comune.provincia"])

		//Devo contare quante righe uscirebbero nell'f24
		//(se sono piu' di dieci faccio due modelli f24 separati)
		//Una riga di webCalcoloDettagli che abbia valori
		//positivi per la parte del comune e anche quella dello stato
		//si spezza in due righe  in f24, quindi devo aggiungere 
		//le righe dello stato alle righe per il comune.
		int righeDaStampare
		int righeStato
		int righeComune
		if (tipoPagamento == 0) {
			righeStato	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && it.accontoErar?.setScale(0, RoundingMode.HALF_UP) 	> 0 }.size()
			righeComune	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && it.acconto?.setScale(0, RoundingMode.HALF_UP) 		> 0 }.size()
		}
		if (tipoPagamento == 1) {
			righeStato	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && it.saldoErar?.setScale(0, RoundingMode.HALF_UP) > 0 }.size()
			righeComune	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && it.saldo?.setScale(0, RoundingMode.HALF_UP) 	> 0 }.size()
		}
		if (tipoPagamento == 2) {
			righeStato	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && ((it.accontoErar?:BigDecimal.ZERO).add(it.saldoErar?:BigDecimal.ZERO))?.setScale(0, RoundingMode.HALF_UP) 	> 0 }.size()
			righeComune	= webCalcoloDettagli.findAll{it.tipoOggetto != TipoOggettoCalcolo.DETRAZIONE && it.tipoOggetto != TipoOggettoCalcolo.TOTALE && ((it.acconto?:BigDecimal.ZERO).add(it.saldo?:BigDecimal.ZERO))?.setScale(0, RoundingMode.HALF_UP) 		> 0 }.size()
		}
		righeDaStampare = righeComune+righeStato
		
		inizializzaF24(siglaComune, tipoPagamento, webCalcoloDettagli)
		
		def dettagliICI		= webCalcoloDettagli.findAll {it.calcoloIndividuale.tipoTributo.tipoTributo == "ICI"}
		def dettagliTASI	= webCalcoloDettagli.findAll {it.calcoloIndividuale.tipoTributo.tipoTributo == "TASI"}
		
		riempiRigheICI(dettagliICI)
		
		//se devo fare un nuovo f24 (righe > 10) devo completare l'F24 dell'ICI
		//e inserirlo nella lista da restituire 
		//e poi creare un nuovo f24Bean e mettere la testata nel nuovo f24
		if (righeDaStampare > 10) {
		//ordina le righe dell'ICI e inserisce la somma finale
			concludiF24()
		//aggiunge F24ICI alla rista da restituire
			listaF24.add(f24Bean)
		//prepara un nuovo F24
			inizializzaF24(siglaComune, tipoPagamento, webCalcoloDettagli)
		}
		
		riempiRigheTASI(dettagliTASI)
		
		//ordina le righe dell'F24 e inserisce la somma finale 
		//potrebbe essere F24 di ICI e TASI insieme oppure 
		//il secondo F24, quello della TASI
		concludiF24()
		
		listaF24.add(f24Bean)

		return listaF24
	}

	private riempiRigheTASI(Collection dettagliTASI) {
		DettaglioDatiF24TASI dettaglioF24TASI = new DettaglioDatiF24TASI(siglaComune, tipoPagamento, f24Bean, dettagliTASI)
		dettaglioF24TASI.accept(new DettaglioDatiF24Visitor())
		f24Bean.dettagli.find {it.codiceTributo == DettaglioDatiF24TASI.codiciTributo["ABITAZIONE_PRINCIPALE"]}?.detrazione = dettaglioF24TASI.detrazione
		
	}

	private riempiRigheICI(Collection dettagliICI) {
		DettaglioDatiF24ICI dettaglioF24ICI = new DettaglioDatiF24ICI(siglaComune, tipoPagamento, f24Bean, dettagliICI)
		dettaglioF24ICI.accept(new DettaglioDatiF24Visitor())
		f24Bean.dettagli.find {it.codiceTributo == DettaglioDatiF24ICI.codiciTributo["ABITAZIONE_PRINCIPALE"]}?.detrazione = dettaglioF24ICI.detrazione
		
	}

	private concludiF24() {
		f24Bean.dettagli.sort{ it.codiceTributo }
		f24Bean.saldo = f24Bean.dettagli.sum {it.importiDebito}
	}

	private inizializzaF24(String siglaComune, int tipoPagamento, List<WebCalcoloDettaglio> webCalcoloDettagli) {
		f24Bean = new F24Bean()
		gestioneTestata(webCalcoloDettagli[0].calcoloIndividuale.contribuente)
	}


}
