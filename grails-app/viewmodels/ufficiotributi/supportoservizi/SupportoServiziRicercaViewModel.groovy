package ufficiotributi.supportoservizi

import it.finmatica.tr4.imposte.supportoservizi.FiltroRicercaSupportoServizi
import it.finmatica.tr4.supportoservizi.SupportoServiziService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class SupportoServiziRicercaViewModel {

    // services
    def springSecurityService

    SupportoServiziService supportoServiziService

    // componenti
    Window self

    // filtri
    FiltroRicercaSupportoServizi parametri

    // dizionari
    def listaTipiPersona = [
            [tipo: null, descrizione: ''],
            [tipo: 'P.F.', descrizione: 'Persona Fisica'],
            [tipo: 'P.G.', descrizione: 'Persona Giuridica'],
            [tipo: 'I.P.', descrizione: 'Intestazioni Particolari'],
    ]
    def listaTipiImmobili = [
            [tipo: null, descrizione: ''],
            [tipo: 'F', descrizione: 'Fabbricati'],
            [tipo: 'T', descrizione: 'Terreni'],
    ]

    def listaTipiTributo
    def listaUtenti
    def listaTipologie
    def listaSegnalazioniIni
    def listaSegnalazioniUlt
    def listaTipiAtto

    def utentiSelezionati = []
    def segnalazioniIniSelezionate = []
    def segnalazioniUltSelezionate = []
    def tipiAttoSelezionati = []

    def listaFetch = []

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") FiltroRicercaSupportoServizi parametriRicerca) {

        this.self = w

        parametri = parametriRicerca ?: new FiltroRicercaSupportoServizi()

        def elencoTipiTributo = supportoServiziService.getElencoTributi()
        listaTipiTributo = []
        listaTipiTributo << [codice: null, descrizione: '']
        elencoTipiTributo.each { listaTipiTributo << it }

        def elencoUtenti = supportoServiziService.getElencoUtenti()
        listaUtenti = []
        elencoUtenti.each { listaUtenti << [codice: it, descrizione: it] }

        def elencoTipologie = supportoServiziService.getElencoTipologie()
        listaTipologie = []
        listaTipologie << null
        elencoTipologie.each { listaTipologie << it }

        def elencoSegnalazioni = supportoServiziService.getElencoSegnalazioniIni()
		listaSegnalazioniIni = preparaListaSegnalazioni(elencoSegnalazioni)
		elencoSegnalazioni = supportoServiziService.getElencoSegnalazioniUlt()
		listaSegnalazioniUlt = preparaListaSegnalazioni(elencoSegnalazioni)

        listaTipiAtto = supportoServiziService.getElencoTipiAtto()

        def selezione = parametri.segnalazioniIniziali ?: []
        segnalazioniIniSelezionate = aggiornaSelezionati(listaSegnalazioniIni, selezione)
		selezione = parametri.segnalazioniUltime ?: []
		segnalazioniUltSelezionate = aggiornaSelezionati(listaSegnalazioniUlt, selezione)
        selezione = parametri.utenti ?: []
        utentiSelezionati = aggiornaSelezionati(listaUtenti, selezione)
        selezione = parametri.tipiAtto ?: []
        tipiAttoSelezionati = aggiornaSelezionati(listaTipiAtto, selezione)
    }

    @NotifyChange("elencoUtentiSelezionati")
    @Command
    def onSelectUtente() {

    }

    String getElencoUtentiSelezionati() {

        return utentiSelezionati?.descrizione?.join(", ")
    }

    @NotifyChange("elencoSegnalazioniIniSelezionate")
    @Command
    def onSelectSegnalazioneIni() {

    }

    String getElencoSegnalazioniIniSelezionate() {

        String result = segnalazioniIniSelezionate?.descrizione?.join(", ")

        if ((result.size() > 40) & (segnalazioniIniSelezionate.size() > 1)) {
            result = segnalazioniIniSelezionate?.descrBreve?.join(", ")
        }

        return result
    }

    @NotifyChange("elencoSegnalazioniUltSelezionate")
    @Command
    def onSelectSegnalazioneUlt() {

    }

    String getElencoSegnalazioniUltSelezionate() {

        String result = segnalazioniUltSelezionate?.descrizione?.join(", ")

        if ((result.size() > 40) & (segnalazioniUltSelezionate.size() > 1)) {
            result = segnalazioniUltSelezionate?.descrBreve?.join(", ")
        }

        return result
    }

    @NotifyChange("elencoTipiAttoSelezionati")
    @Command
    def onSelectTipoAtto() {

    }

    String getElencoTipiAttoSelezionati() {

        String result = tipiAttoSelezionati?.descrizione?.join(", ")

        if ((result.size() > 40) && (tipiAttoSelezionati.size() > 1)) {
            result = tipiAttoSelezionati?.codice?.join(", ")
        }

        return result
    }

    @Command
    def onSvuotaFiltri() {

        parametri.pulisci()

        utentiSelezionati = []
        segnalazioniIniSelezionate = []
		segnalazioniUltSelezionate = []
        tipiAttoSelezionati = []

        BindUtils.postNotifyChange(null, null, this, "parametri")
        BindUtils.postNotifyChange(null, null, this, "utentiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "segnalazioniIniSelezionate")
        BindUtils.postNotifyChange(null, null, this, "segnalazioniUltSelezionate")
        BindUtils.postNotifyChange(null, null, this, "tipiAttoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoUtentiSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoSegnalazioniIniSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoSegnalazioniUltSelezionate")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiAttoSelezionati")
    }

    @Command
    def onCerca() {
		
		if(!verificaParametri())
			return;

        parametri.utenti = aggiornaSelezione(utentiSelezionati)
        parametri.segnalazioniIniziali = aggiornaSelezione(segnalazioniIniSelezionate)
        parametri.segnalazioniUltime = aggiornaSelezione(segnalazioniUltSelezionate)
        parametri.tipiAtto = aggiornaSelezione(tipiAttoSelezionati)

        Events.postEvent(Events.ON_CLOSE, self, [status: "cerca", filtri: parametri])
    }

    @Command
    def onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }
	
	/**
	 * predispone lista segnalazioni
	 */
	def preparaListaSegnalazioni(def elencoSegnalazioni) {
		
		def listaSegnalazioni = []
		
		elencoSegnalazioni.each {
			String segnalazione = it ?: ''
			if(segnalazione.length() > 0) {
				listaSegnalazioni << [ codice: it, descrizione: it, descrBreve: it ]
			}
		}
		listaSegnalazioni.each {
			def idx = it.descrBreve.indexOf(" - ")
			if (idx > 0) {
				it.descrBreve = it.descrBreve.substring(0, idx)
			}
		}
		
		return listaSegnalazioni
	}

    /**
     * Aggionra selezionati x codice da lista
     *
     * @param lista
     * @param selezionati
     * @return
     */
    private def aggiornaSelezionati(def lista, def selezionati) {

        def listaSelezionati = []

        selezionati.each {

            def codice = it
            def selezione = lista.find { it.codice == codice }

            if (selezione) {
                listaSelezionati << selezione
            }
        }

        return listaSelezionati
    }

    /**
     * Elencoa selezionati in lista
     *
     * @param lista
     * @return
     */
    private def aggiornaSelezione(def lista) {

        def selezionati = []

        lista.each {
            selezionati << it.codice
        }

        return selezionati
    }
	
	def verificaParametri() {
		
		boolean result = true
		
        def errori = []

		Short annoDa = parametri.annoDa ?: 1900 
		Short annoA = parametri.annoA ?: 2999
		
		if(annoDa > annoA) {
			errori << "Valore di 'Anno da' non coerente\n"
		}
		
        if (errori.size() > 0) {

            String message = "Attenzione:\n\n"
            errori.each { message += it }
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_WARNING, null, "before_center", 3000, true)
			
            result = false
        }

		return result
	}
}
