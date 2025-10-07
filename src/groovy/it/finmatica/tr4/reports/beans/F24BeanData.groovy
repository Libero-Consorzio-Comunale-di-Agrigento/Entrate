package it.finmatica.tr4.reports.beans

import java.text.SimpleDateFormat;

class F24BeanData {
	public static java.util.Collection getF24Bean() {
		java.util.Collection f24 = new ArrayList();
		
		for (i in 0..1) {
			F24Bean f24Bean = new F24Bean();
			f24Bean.codFiscale = "FGLSST79P07H769N"
			f24Bean.cognome = "FOGLIA ${i}"
			f24Bean.nome = "SEVASTIAN"
			f24Bean.dataNascita = new SimpleDateFormat("dd/MM/yyyy").parse("07/09/1979")
			f24Bean.dettaglio = new ArrayList<F24DettaglioBean>()
			f24Bean.saldo = new BigDecimal(100+i)
			
			for (j in 0..9) {
				F24DettaglioBean abitazionePrincipale = new F24DettaglioBean()
				abitazionePrincipale.sezione = "EL"
				abitazionePrincipale.codiceTributo = "3912"
				abitazionePrincipale.codiceEnte = "I684"
				abitazionePrincipale.acconto = false
				abitazionePrincipale.saldo = true
				abitazionePrincipale.numeroImmobili = 2+i
				abitazionePrincipale.rateazione = "0101"
				abitazionePrincipale.annoRiferimento = "2014"
				abitazionePrincipale.detrazione = new BigDecimal(50+i)
				abitazionePrincipale.importiDebito = new BigDecimal(782+i)
				
				f24Bean.dettaglio << abitazionePrincipale
			}
			/*F24DettaglioBean terreniComune = new F24DettaglioBean()
			terreniComune.sezione = "EL"
			terreniComune.codiceTributo = "3914"
			terreniComune.codiceEnte = "I684"
			terreniComune.acconto = true
			terreniComune.saldo = true
			terreniComune.numeroImmobili = 2+i
			terreniComune.rateazione = "0101"
			terreniComune.annoRiferimento = "2014"
			terreniComune.importiDebito = new BigDecimal(1569+i)*/
			
			//f24Bean.dettaglio << terreniComune
			
			f24.add(f24Bean)
		}
		
		//f24.add(f24Bean);
		
		return f24;
	}
	
}
