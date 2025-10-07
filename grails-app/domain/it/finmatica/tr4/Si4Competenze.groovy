package it.finmatica.tr4

import it.finmatica.ad4.Ad4Tr4Utente
import it.finmatica.ad4.autenticazione.Ad4Utente

class Si4Competenze {

	Ad4Utente utente
	Ad4Tr4Utente utenteTr4
	String oggetto
	String accesso
	String ruolo
	Date dal
	Date al
	Date dataAggiornamento
	Ad4Utente utenteAggiornamento
	Si4Abilitazioni si4Abilitazioni

	static belongsTo = [Si4Abilitazioni]
	static transients = ['utenteTr4']

	static mapping = {

		id column: "ID_COMPETENZA", generator: "sequence", params: [sequence: "COMP_SQ"]
		utente column: "utente"
		utenteTr4 column: "utente", updateable: false, insertable: false
		utenteAggiornamento column: "utente_aggiornamento"

		si4Abilitazioni column: "id_abilitazione"
		dal sqlType: 'Date', column: 'dal'
		al sqlType: 'Date', column: 'al'
		dataAggiornamento sqlType: 'Date', column: 'data_aggiornamento'

		version false
		table "si4_competenze"
	}

	static constraints = {
		utente maxSize: 8
		oggetto maxSize: 250
		accesso maxSize: 1
		ruolo nullable: true, maxSize: 250
		dal nullable: true
		al nullable: true
		dataAggiornamento nullable: true
		utenteAggiornamento nullable: true, maxSize: 8
	}
}
