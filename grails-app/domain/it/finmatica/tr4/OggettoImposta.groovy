package it.finmatica.tr4


import it.finmatica.tr4.pratiche.OggettoContribuente
import it.finmatica.tr4.tipi.SiNoType

class OggettoImposta {

	Short anno
	BigDecimal imposta
	BigDecimal impostaAcconto
	BigDecimal impostaDovuta
	BigDecimal impostaDovutaAcconto
	BigDecimal importoVersato
	BigDecimal aliquota
	BigDecimal importoRuolo
	boolean flagCalcolo
	String	utente
	Date lastUpdated
	String note
	BigDecimal detrazione
	BigDecimal detrazioneAcconto
	BigDecimal addizionaleEca
	BigDecimal maggiorazioneEca
	BigDecimal addizionalePro
	BigDecimal iva
	Long numBollettino
	BigDecimal fattura
	String dettaglioOgim
	BigDecimal aliquotaIva
	BigDecimal importoPf
	BigDecimal importoPv
	BigDecimal imponibile
	BigDecimal detrazioneImponibile
	BigDecimal detrazioneImponibileAcconto
	BigDecimal imponibileD
	BigDecimal detrazioneImponibileD
	BigDecimal detrazioneImponibileDAcc
	BigDecimal detrazioneRimanenteCain
	BigDecimal detrazioneRimanenteCainAcc
	BigDecimal impostaErariale
	BigDecimal impostaErarialeAcconto
	BigDecimal detrazioneFigli
	BigDecimal detrazioneFigliAcconto
	BigDecimal aliquotaErariale
	BigDecimal maggiorazioneTares
	BigDecimal impostaErarialeDovuta
	BigDecimal impostaErarialeDovutaAcc
	BigDecimal aliquotaStd
	BigDecimal impostaAliquota
	BigDecimal impostaStd
	BigDecimal impostaDovutaStd
	BigDecimal impostaMini
	BigDecimal impostaDovutaMini
	BigDecimal detrazioneStd
	BigDecimal detrazionePrec
	BigDecimal aliquotaPrec
	BigDecimal aliquotaErarPrec
	
	BigDecimal impostaPrePerc
	BigDecimal impostaAccontoPrePerc
	String tipoRapporto
	BigDecimal percentuale
	Short mesiPossesso
	Short mesiAffitto
	
	BigDecimal aliquotaAcconto
	
	Short tipoTariffaBase
	BigDecimal impostaBase
	BigDecimal addizionaleEcaBase
	BigDecimal maggiorazioneEcaBase
	BigDecimal addizionaleProBase
	BigDecimal ivaBase
	BigDecimal importoPfBase
	BigDecimal importoPvBase
	BigDecimal importoRuoloBase
	String dettaglioOgimBase
	BigDecimal percRiduzionePf
	BigDecimal percRiduzionePv
	BigDecimal importoRiduzionePf
	BigDecimal importoRiduzionePv
	Short daMesePossesso
	BigDecimal impostaPeriodo
	
	TipoAliquota tipoAliquota
	TipoAliquota tipoAliquotaPrec	
	Ruolo	ruolo
	TipoTributo tipoTributo
	
	static belongsTo	= [ oggettoContribuente:	OggettoContribuente ]
	
	SortedSet<RuoloContribuente> ruoliContribuente
	
	static hasMany		= [ ruoliContribuente:		RuoloContribuente 
						  , rateImposta:			RataImposta 
						  , versamenti: 			Versamento
						  , familiariOgim:			FamiliareOgim ]
	
	static mapping = {
		id 		column: "oggetto_imposta", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "OGGETTI_IMPOSTA_NR"]
		
		imponibileD					column: "imponibile_d"
		detrazioneImponibileD       column: "detrazione_imponibile_d"
		detrazioneImponibileDAcc    column: "detrazione_imponibile_d_acc"
		ruolo						column: "ruolo"
		tipoTributo					column: "tipo_tributo", updateable: false, insertable: false
		flagCalcolo			    	type: SiNoType
		lastUpdated	sqlType:'Date', column:'DATA_VARIAZIONE'
		utente	column: "utente"
		columns {
			tipoAliquota {
				column name: "tipo_tributo"
				column name: "tipo_aliquota"
			}
			tipoAliquotaPrec {
				column name: "tipo_tributotipo_aliquota_prec"
				column name: "tipo_aliquota_prec"
			}
			oggettoContribuente {
				column name: "cod_fiscale"
				column name: "oggetto_pratica"
			}
		}
		
		table 'web_oggetti_imposta'
		version false
	}

	static constraints = {
		impostaAcconto 				nullable: true
		impostaDovuta 				nullable: true
		impostaDovutaAcconto		nullable: true
		importoVersato 				nullable: true
		tipoAliquota 				nullable: true
		aliquota 					nullable: true
		ruolo 						nullable: true
		importoRuolo 				nullable: true
		flagCalcolo 				nullable: true, maxSize: 1
		utente 						maxSize: 8
		note 						nullable: true, maxSize: 2000
		detrazione 					nullable: true
		detrazioneAcconto			nullable: true
		addizionaleEca 				nullable: true
		maggiorazioneEca			nullable: true
		addizionalePro 				nullable: true
		iva 						nullable: true
		numBollettino 				nullable: true
		fattura 					nullable: true
		dettaglioOgim 				nullable: true, maxSize: 2000
		aliquotaIva 				nullable: true
		importoPf 					nullable: true
		importoPv 					nullable: true
		imponibile 					nullable: true
		detrazioneImponibile 		nullable: true
		detrazioneImponibileAcconto nullable: true
		imponibileD 				nullable: true
		detrazioneImponibileD 		nullable: true
		detrazioneImponibileDAcc 	nullable: true
		detrazioneRimanenteCain 	nullable: true
		detrazioneRimanenteCainAcc 	nullable: true
		impostaErariale 			nullable: true
		impostaErarialeAcconto 		nullable: true
		detrazioneFigli 			nullable: true
		detrazioneFigliAcconto 		nullable: true
		aliquotaErariale 			nullable: true
		maggiorazioneTares 			nullable: true
		impostaErarialeDovuta 		nullable: true
		impostaErarialeDovutaAcc 	nullable: true
		aliquotaStd 				nullable: true
		impostaAliquota 			nullable: true
		impostaStd 					nullable: true
		impostaDovutaStd 			nullable: true
		impostaMini 				nullable: true
		impostaDovutaMini 			nullable: true
		detrazioneStd 				nullable: true
		impostaPrePerc 				nullable: true
		impostaAccontoPrePerc 		nullable: true
		tipoRapporto 				nullable: true, maxSize: 1
		percentuale 				nullable: true
		mesiPossesso 				nullable: true
		mesiAffitto 				nullable: true
		lastUpdated				nullable: true
		utente						nullable: true
		detrazionePrec				nullable: true
		tipoAliquotaPrec			nullable: true
		aliquotaPrec				nullable: true
		aliquotaErarPrec			nullable: true
		aliquotaAcconto			    nullable: true

		tipoTariffaBase				nullable: true
		impostaBase					nullable: true
		addizionaleEcaBase			nullable: true
		maggiorazioneEcaBase		nullable: true
		addizionaleProBase			nullable: true
		ivaBase						nullable: true
		importoPfBase				nullable: true
		importoPvBase				nullable: true
		importoRuoloBase			nullable: true
		dettaglioOgimBase			nullable: true
		percRiduzionePf				nullable: true
		percRiduzionePv				nullable: true
		importoRiduzionePf			nullable: true
		importoRiduzionePv			nullable: true
		daMesePossesso				nullable: true
		impostaPeriodo				nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente	= springSecurityService.currentUser.id
	}
	
	def beforeInsert () {
		utente	= utente?:springSecurityService.currentUser.id
	}
}
