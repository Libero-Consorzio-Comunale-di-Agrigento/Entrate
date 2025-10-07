package it.finmatica.tr4

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.contribuenti.ContribuentiService

class CalcoloIndividualeController {

	ContribuentiService contribuentiService
	SpringSecurityService springSecurityService
	TributiSession tributiSession

	public def eliminaWCIN() {
		log.warn("Chiusura del browser rilevata: elimino WEB_CALCOLO_INDIVIDUALE per l'utente ${springSecurityService.principal.username}")
		contribuentiService.eliminaWCIN(tributiSession.idWCIN)
		render "ok"
	}
}
