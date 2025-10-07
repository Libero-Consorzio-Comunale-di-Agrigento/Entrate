package ufficiotributi.supportoservizi

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.supportoservizi.SupportoServiziService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SupportoServiziAssegnaContribuentiViewModel {

    // services
    CompetenzeService competenzeService
    SupportoServiziService supportoServiziService
    CommonService commonService

    // componenti
    Window self

    // filtri
    Map parametri = [
            tipoTributo		: null,
            utente			: null,
            numeroCasi		: null,
            numOggettiDa	: null,
            numOggettiA		: null,
            tipoImmobili	: null,
			minPossessoDa	: null,
			minPossessoA	: null,
			flagLiqNonNot   : 'I',
			flagFabbricati  : 'I',
			flagTerreni     : 'I',
			flagAreeFabbr   : 'I',
			flagContitolari : 'S',
    ]
	
    // dizionari
    def listaTipiImmobili = [
            [tipo: null, descrizione: ''],
            [tipo: 'F', descrizione: 'Fabbricati'],
            [tipo: 'T', descrizione: 'Terreni'],
    ]

    def listaTipiTributo
    def listaUtenti

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
		
		def tipiTributoScrittura = competenzeService.tipiTributoUtenzaScrittura().collect { it.tipoTributo }
		
        def elencoTipiTributo = supportoServiziService.getElencoTributi()
		listaTipiTributo = elencoTipiTributo.findAll { it.codice in tipiTributoScrittura }
		
        caricaElencoUtenti()
    }

    def caricaElencoUtenti() {

        def elencoUtenti = supportoServiziService.getElencoUtentiPerTipoTributo(parametri.tipoTributo, competenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO)
        listaUtenti = []
        listaUtenti << 'Tutti'
        elencoUtenti.each { listaUtenti << it }

        if (elencoUtenti.find { it == parametri.utente } == null) {
            parametri.utente = null
            BindUtils.postNotifyChange(null, null, this, "parametri")
        }

        BindUtils.postNotifyChange(null, null, this, "listaUtenti")
    }

    @Command
    def onSelectTipoTributo() {

        caricaElencoUtenti()
    }

    @Command
    def onOK() {

        if (!validaParametri()) {
            return
        }
		
		def parametriNow = parametri.clone()
		
		if(parametriNow.flagLiqNonNot == 'I') parametriNow.flagLiqNonNot = null
		if(parametriNow.flagFabbricati == 'I') parametriNow.flagFabbricati = null
		if(parametriNow.flagTerreni == 'I') parametriNow.flagTerreni = null
		if(parametriNow.flagAreeFabbr == 'I') parametriNow.flagAreeFabbr = null
		
        Events.postEvent(Events.ON_CLOSE, self, [parametri: parametriNow])
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    // Valida parametri -> True se ok
    private boolean validaParametri() {

        String message = ""

        if (parametri.tipoTributo == null) {
            message += "Tipo Tributo non specificato\n"
        }
        if (parametri.utente == null) {
            message += "Assegna a non specificato\n"
        }
        if (parametri.numeroCasi == null) {
            message += "Numero casi non specificato\n"
        }

        if (!(message.isEmpty())) {
            message = "Attenzione : \n\n" + message
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }

        return message.isEmpty()
    }
}
