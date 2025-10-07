package it.finmatica.tr4

import it.finmatica.ad4.dizionari.Ad4ComuneTr4

class DatoGenerale {

	Long chiave
	Ad4ComuneTr4 comuneCliente
	
	String flagIntegrazioneGsd
	String flagIntegrazioneTrb
	Byte faseEuro
	BigDecimal cambioEuro
	String codComuneRuolo
	String flagCatastoCu
	String flagProvincia
	Integer codAbi
	Integer codCab
	String codAzienda
	String flagAccTotale
	String flagCompetenze
	String tipoComune
	String area

	static mapping = {
		id name: "chiave", generator: "assigned"
		columns {
			comuneCliente {
				column name: "com_cliente"
				column name: "pro_cliente"
			}
		}
		
		table 'dati_generali'
		version false
	}

	static constraints = {
		flagIntegrazioneGsd nullable: true, maxSize: 1
		flagIntegrazioneTrb nullable: true, maxSize: 1
		faseEuro nullable: true
		cambioEuro nullable: true
		codComuneRuolo nullable: true, maxSize: 6
		flagCatastoCu nullable: true, maxSize: 1
		flagProvincia nullable: true, maxSize: 1
		codAbi nullable: true
		codCab nullable: true
		codAzienda nullable: true, maxSize: 5
		flagAccTotale nullable: true, maxSize: 1
		flagCompetenze nullable: true, maxSize: 1
		tipoComune nullable: true, maxSize: 3
		area nullable: true, maxSize: 20
	}
}
