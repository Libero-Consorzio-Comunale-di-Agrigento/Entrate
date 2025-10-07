package it.finmatica.tr4.supportoservizi

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.tipi.SiNoType

// Oggetto alternativo a SupportoServizi, da usare solo per leggere i dati
// Si appoggia su da una vista r/o con sort specifico

class SupportoServiziWeb implements Serializable {

	TipoTributo tipoTributo

	String tipologia
	String segnalazioneIniziale
	String segnalazioneUltima
	String cognomeNome
	String codFiscale
	Short anno

	Integer numOggetti
	Integer numFabbricati
	Integer numTerreni
	Integer numAree
	Double differenzaImposta
	String resStoricoGsdInizioAnno
	String resStoricoGsdFineAnno
	Short residenteDaAnno
	String tipoPersona
	Date dataNas
	String aireStoricoGsdInizioAnno
	String aireStoricoGsdFineAnno
	boolean flagDeceduto
	Date dataDecesso
	String contribuenteDaFare
	Double minPercPossesso
	Double maxPercPossesso
	boolean flagDiffFabbricatiCatasto
	boolean flagDiffTerreniCatasto
	Integer fabbricatiNonCatasto
	Integer terreniNonCatasto
	Integer catastoNonTr4Fabbricati
	Integer catastoNonTr4Terreni
	boolean flagLiqAcc
	String liquidazioneAds
	String iterAds
	boolean flagRavvedimento
	Double versato
	Double dovuto
	Double dovutoComunale
	Double dovutoErariale
	Double dovutoAcconto
	Double dovutoComunaleAcconto
	Double dovutoErarialeAcconto
	Double diffTotContr
	Integer denunceImu
	String codiceAttivitaCont
	String residenteOggi
	Integer abPrincipali
	Integer pertinenze
	Integer altriFabbricati
	Integer fabbricatiD
	Integer terreni
	Integer terreniRidotti
	Integer aree
	Integer abitativo
	Integer commercialiArtigianali
	Integer rurali
	String cognome
	String nome
	String cognomeNomeRic
	String cognomeRic
	String nomeRic

	String utenteAssegnato
	String utenteOperativo

	String numero
	Date data
	TipoStato stato
	TipoAtto tipoAtto
	Date dataNotifica
	
	String liq2Utente
	String liq2Numero
	Date liq2Data
	TipoStato liq2Stato
	TipoAtto liq2TipoAtto
	Date liq2DataNotifica
	
	String note
	
	Short annoOrd
	String tipoTributoOrd
	BigDecimal differenzaImpostaOrd
	String codFiscaleOrd
	
	String utentePaUt
	
	Ad4Utente utente
	Date dataVariazione

	static mapping = {
		id column: "ID", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SUPPORTO_SERVIZI_NR"]

		tipoTributo column: "tipo_tributo"
		tipoAtto column: "tipo_atto"

		catastoNonTr4Fabbricati column: "catasto_non_tr4_fabbricati"
		catastoNonTr4Terreni column: "catasto_non_tr4_terreni"

		fabbricatiD column: "fabbricati_d"

		stato column: "stato"

		liq2Utente column: "liq2_utente"
		liq2Numero column: "liq2_numero"
		liq2Data column: "liq2_data"
		liq2Stato column: "liq2_stato"
		liq2TipoAtto column: "liq2_tipo_atto"
		liq2DataNotifica column: "liq2_data_notifica"

		flagDeceduto type: SiNoType
		flagDiffFabbricatiCatasto type: SiNoType
		flagDiffTerreniCatasto type: SiNoType
		flagLiqAcc type: SiNoType
		flagRavvedimento type: SiNoType
		
		utentePaUt column: "utente_paut", ignoreNotFound: true

		utente column: "utente", ignoreNotFound: true

		table "web_supporto_servizi"

		version false
	}

	static constraints = {
		tipologia nullable: false, maxSize: 50
		segnalazioneIniziale nullable: true, maxSize: 100
		segnalazioneUltima nullable: true, maxSize: 100
		cognomeNome nullable: false, maxSize: 100
		codFiscale nullable: false, maxSize: 16
		anno nullable: false, maxSize: 4

		numOggetti nullable: true
		numFabbricati nullable: true
		numTerreni nullable: true
		numAree nullable: true
		differenzaImposta nullable: true
		resStoricoGsdInizioAnno nullable: true, maxSize: 9
		resStoricoGsdFineAnno nullable: true, maxSize: 9
		residenteDaAnno nullable: true
		tipoPersona nullable: true, maxSize: 50
		dataNas nullable: true
		aireStoricoGsdInizioAnno nullable: true, maxSize: 4
		aireStoricoGsdFineAnno nullable: true, maxSize: 4
		flagDeceduto nullable: false
		dataDecesso nullable: true
		contribuenteDaFare nullable: true, maxSize: 1
		minPercPossesso nullable: true
		maxPercPossesso nullable: true
		flagDiffFabbricatiCatasto nullable: false
		flagDiffTerreniCatasto nullable: false
		fabbricatiNonCatasto nullable: true
		terreniNonCatasto nullable: true
		catastoNonTr4Fabbricati nullable: true
		catastoNonTr4Terreni nullable: true
		flagLiqAcc nullable: false
		liquidazioneAds nullable: true, maxSize: 2000
		iterAds nullable: true, maxSize: 2000
		flagRavvedimento nullable: false
		tipoTributo nullable: true, maxSize: 5
		versato nullable: true
		dovuto nullable: true
		dovutoComunale nullable: true
		dovutoErariale nullable: true
		dovutoAcconto nullable: true
		dovutoComunaleAcconto nullable: true
		dovutoErarialeAcconto nullable: true
		diffTotContr nullable: true
		denunceImu nullable: true
		codiceAttivitaCont nullable: true, maxSize: 5
		residenteOggi nullable: true, maxSize: 50
		abPrincipali nullable: true
		pertinenze nullable: true
		altriFabbricati nullable: true
		fabbricatiD nullable: true
		terreni nullable: true
		terreniRidotti nullable: true
		aree nullable: true
		abitativo nullable: true
		commercialiArtigianali nullable: true
		rurali nullable: true
		cognome nullable: true, maxSize: 100
		nome nullable: true, maxSize: 100
		cognomeNomeRic nullable: true, maxSize: 100
		cognomeRic nullable: true, maxSize: 100
		nomeRic nullable: true, maxSize: 100
		utenteAssegnato nullable: true, maxSize: 8

		utenteOperativo nullable: true, maxSize: 8
		numero nullable: true, maxSize: 15
		data nullable: true
		stato nullable: true, maxSize: 2
		tipoAtto nullable: true, maxSize: 2
		dataNotifica nullable: true
		
		liq2Utente nullable: true, maxSize: 8
		liq2Numero nullable: true, maxSize: 15
		liq2Data nullable: true
		liq2Stato nullable: true, maxSize: 2
		liq2TipoAtto nullable: true, maxSize: 2
		liq2DataNotifica nullable: true
		
		note nullable: true, maxSize: 2000

		utente nullable: true, maxSize: 8
		dataVariazione nullable: false
	}

	SpringSecurityService springSecurityService
	static transients = ['springSecurityService']

	def beforeValidate() {
		utente = utente ?: springSecurityService.currentUser
	}

	def beforeInsert() {
		utente = utente ?: springSecurityService.currentUser
	}
}
