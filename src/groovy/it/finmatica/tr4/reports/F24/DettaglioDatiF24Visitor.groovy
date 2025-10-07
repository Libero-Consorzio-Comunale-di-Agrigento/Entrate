package it.finmatica.tr4.reports.F24

import it.finmatica.tr4.dto.WebCalcoloDettaglioDTO
import it.finmatica.tr4.reports.beans.F24Bean
import it.finmatica.tr4.reports.beans.F24DettaglioBean

import java.math.RoundingMode

class DettaglioDatiF24Visitor extends DettaglioDatiF24VisitorAbstract {


	@Override
	public void visit(DettaglioDatiF24ICI dettaglioF24) {
		for (WebCalcoloDettaglioDTO riga in dettaglioF24.dettagli) {
			gestioneTipoOggettoICI(dettaglioF24, riga)
		}
	}

	@Override
	public void visit(DettaglioDatiF24TASI dettaglioF24) {
		for (WebCalcoloDettaglioDTO riga in dettaglioF24.dettagli) {
			gestioneTipoOggettoTASI(dettaglioF24, riga)
		}
	}

	@Override
	public void visit(DettaglioDatiF24Ruolo dettaglioF24) {

		for (int riga = 1; riga <= 3; riga++) {
			if (dettaglioF24.dettagli["COTR_RIGA_${riga}"]) {

				F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()

				f24DettaglioBean.sezione 			= "EL"
				f24DettaglioBean.codiceTributo		= dettaglioF24.dettagli["COTR_RIGA_${riga}"]
				f24DettaglioBean.codiceEnte			= dettaglioF24.dettagli.CODICE_COMUNE
				f24DettaglioBean.numeroImmobili		= dettaglioF24.dettagli["N_FAB_RIGA_${riga}"] != null ? Integer.parseInt(dettaglioF24.dettagli["N_FAB_RIGA_${riga}"].trim()) : null

				f24DettaglioBean.rateazione			=
						dettaglioF24.dettagli["COTR_RIGA_${riga}"] == '3955' ? '0101' : dettaglioF24.dettagli.RATEAZIONE

				f24DettaglioBean.annoRiferimento	= dettaglioF24.dettagli.ANNO
				f24DettaglioBean.importiDebito		= dettaglioF24.dettagli["IMPORTO_RIGA_${riga}"]
				f24DettaglioBean.rataRuolo			= dettaglioF24.dettagli.ORD2

				dettaglioF24.f24Bean.dettagli << f24DettaglioBean
			}
		}
	}

	//riga di dettaglio ICI che a volte deve distinguere
	//la quota da versare allo stato da quella per il comune
	public void creaRigaDettaglioICI(DettaglioDatiF24ICI dettaglioF24, F24Bean f24Bean, WebCalcoloDettaglioDTO dettaglio, String tipoVersamento) {
		F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()


		f24DettaglioBean.sezione 			= "EL"
		f24DettaglioBean.codiceTributo		= (tipoVersamento == null) ? dettaglioF24.codiciTributo[dettaglio.tipoOggetto.getValore()]
				: dettaglioF24.codiciTributo[dettaglio.tipoOggetto.getValore()][tipoVersamento]
		f24DettaglioBean.codiceEnte 		= dettaglioF24.siglaComune
		f24DettaglioBean.acconto 			= (dettaglioF24.tipoPagamento == 0) || (dettaglioF24.tipoPagamento == 2)
		f24DettaglioBean.saldo 				= (dettaglioF24.tipoPagamento == 1) || (dettaglioF24.tipoPagamento == 2)
		f24DettaglioBean.numeroImmobili 	= dettaglio.numFabbricati
		f24DettaglioBean.rateazione 		= f24DettaglioBean.codiceTributo == dettaglioF24.codiciTributo["ABITAZIONE_PRINCIPALE"] ? "0101" : ""
		f24DettaglioBean.annoRiferimento	= String.valueOf(dettaglio.calcoloIndividuale.anno)

		if (dettaglioF24.tipoPagamento == 0) {
			f24DettaglioBean.importiDebito 	= (tipoVersamento == null || tipoVersamento == "COMUNE")? dettaglio.acconto.subtract(dettaglio.accontoErar?:0).setScale(0, RoundingMode.HALF_UP) : dettaglio.accontoErar.setScale(0, RoundingMode.HALF_UP)
		} else if (dettaglioF24.tipoPagamento == 1) {
			f24DettaglioBean.importiDebito 	= (tipoVersamento == null || tipoVersamento == "COMUNE")? dettaglio.saldo.subtract(dettaglio.saldoErar?:0).setScale(0, RoundingMode.HALF_UP) : dettaglio.saldoErar.setScale(0, RoundingMode.HALF_UP)
		} else {
			f24DettaglioBean.importiDebito 	= (tipoVersamento == null || tipoVersamento == "COMUNE")? dettaglio.acconto.subtract(dettaglio.accontoErar?:0).add(dettaglio.saldo.subtract(dettaglio.saldoErar?:0)).setScale(0, RoundingMode.HALF_UP) :
					dettaglio.accontoErar.add(dettaglio.saldoErar).setScale(0, RoundingMode.HALF_UP)
		}

		(f24DettaglioBean.importiDebito.compareTo(BigDecimal.ZERO) == 1) && f24Bean.dettagli << f24DettaglioBean
	}

	//riga di dettaglio TASI che non versa niente allo stato
	public void creaRigaDettaglioTASI(DettaglioDatiF24TASI dettaglioF24, F24Bean f24Bean, WebCalcoloDettaglioDTO dettaglio) {
		F24DettaglioBean f24DettaglioBean = new F24DettaglioBean()

		f24DettaglioBean.sezione 			= "EL"
		f24DettaglioBean.codiceTributo		= dettaglioF24.codiciTributo[dettaglio.tipoOggetto.getValore()]
		f24DettaglioBean.codiceEnte 		= dettaglioF24.siglaComune
		f24DettaglioBean.acconto 			= (dettaglioF24.tipoPagamento == 0) || (dettaglioF24.tipoPagamento == 2)
		f24DettaglioBean.saldo 				= (dettaglioF24.tipoPagamento == 1) || (dettaglioF24.tipoPagamento == 2)
		f24DettaglioBean.numeroImmobili 	= dettaglio.numFabbricati
		f24DettaglioBean.rateazione 		= ""
		f24DettaglioBean.annoRiferimento	= String.valueOf(dettaglio.calcoloIndividuale.anno)

		if (dettaglioF24.tipoPagamento == 0)
			f24DettaglioBean.importiDebito 	= dettaglio.acconto.setScale(0, RoundingMode.HALF_UP)
		else if (dettaglioF24.tipoPagamento == 1)
			f24DettaglioBean.importiDebito 	= dettaglio.saldo.setScale(0, RoundingMode.HALF_UP)
		else
			f24DettaglioBean.importiDebito 	= dettaglio.acconto.add(dettaglio.saldo).setScale(0, RoundingMode.HALF_UP)

		(f24DettaglioBean.importiDebito.compareTo(BigDecimal.ZERO) == 1) && f24Bean.dettagli << f24DettaglioBean
	}

	public void gestioneTipoOggettoICI(DettaglioDatiF24ICI dettaglioF24, WebCalcoloDettaglioDTO dettaglio) {
		if (   dettaglio.acconto 		!= null	&& dettaglio.acconto.compareTo(BigDecimal.ZERO)
		|| dettaglio.accontoErar 	!= null	&& dettaglio.accontoErar.compareTo(BigDecimal.ZERO)
		|| dettaglio.saldo 			!= null	&& dettaglio.saldo.compareTo(BigDecimal.ZERO)
		|| dettaglio.saldoErar 		!= null	&& dettaglio.saldoErar.compareTo(BigDecimal.ZERO))
			switch (dettaglio.tipoOggetto) {
				case 'TERRENO':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "STATO")
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "COMUNE")
					break
				case 'AREA':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "STATO")
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "COMUNE")
					break
				case 'ABITAZIONE_PRINCIPALE':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, null)
					break
				case 'ALTRO_FABBRICATO':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "STATO")
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "COMUNE")
					break
				case 'RURALE':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, null)
					break
				case 'FABBRICATO_D':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "STATO")
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, "COMUNE")
					break
				case 'DETRAZIONE':
					impostaDetrazione(dettaglioF24, dettaglio)
					break
				case 'FABBRICATO_MERCE':
					creaRigaDettaglioICI(dettaglioF24, dettaglioF24.f24Bean, dettaglio, null)
					break
				default: break
			}
	}

	public void gestioneTipoOggettoTASI(DettaglioDatiF24TASI dettaglioF24, WebCalcoloDettaglioDTO dettaglio) {
		if (   dettaglio.acconto	!= null && dettaglio.acconto.compareTo(BigDecimal.ZERO)
		|| dettaglio.saldo		!= null && dettaglio.saldo.compareTo(BigDecimal.ZERO))
			switch (dettaglio.tipoOggetto) {
				case 'AREA':
					creaRigaDettaglioTASI(dettaglioF24, dettaglioF24.f24Bean, dettaglio)
					break
				case 'ABITAZIONE_PRINCIPALE':
					creaRigaDettaglioTASI(dettaglioF24, dettaglioF24.f24Bean, dettaglio)
					break
				case 'ALTRO_FABBRICATO':
					creaRigaDettaglioTASI(dettaglioF24, dettaglioF24.f24Bean, dettaglio)
					break
				case 'RURALE':
					creaRigaDettaglioTASI(dettaglioF24, dettaglioF24.f24Bean, dettaglio)
					break
				case 'DETRAZIONE':
					impostaDetrazione(dettaglioF24, dettaglio)
					break
				default: break
			}
	}

	//il valore della detrazione viene salvato in una variabile
	// e non inserito in una riga di dettaglio
	//perchè poi verra' messo nella stessa riga dell'abitazione principale
	private impostaDetrazione(DettaglioDatiF24Interface dettaglioF24, WebCalcoloDettaglioDTO dettaglio) {
		if (dettaglioF24.tipoPagamento == 0)
			dettaglioF24.detrazione = dettaglio.acconto
		else if (dettaglioF24.tipoPagamento == 1)
			dettaglioF24.detrazione = dettaglio.saldo
		else
			dettaglioF24.detrazione = dettaglio.acconto.add(dettaglio.saldo)
	}
}
