package ufficiotributi

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.dto.Si4CompetenzeDTO
import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO

import grails.plugins.springsecurity.SpringSecurityService

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Window

class UfficioTributiIndexViewModel {

    // services
    CompetenzeService competenzeService
    CommonService commonService
	SpringSecurityService springSecurityService
	
    // componenti
    Window self

    // stato
    String selectedSezione
    String urlSezione

    def cbTributiAbilitati = [:]
	
	Boolean supportoServiziAbilitato

    def pagineArchivio = [
            imposte           : "/ufficiotributi/imposte/imposte.zul",
            emissione         : "/ufficiotributi/imposte/listeDiCaricoRuoli.zul",
            importDati        : "/ufficiotributi/datiesterni/importDati.zul",
            fornitureAE       : "/ufficiotributi/datiesterni/fornitureAE.zul",
            dichiarazioni     : "/ufficiotributi/bonificaDati/dichiarazioni.zul",
            versamentiPratiche: "/ufficiotributi/versamenti/listaVersamenti.zul",
            docfa             : "/ufficiotributi/bonificaDati/docfa/docfa.zul",
            nonDichiarati     : "/ufficiotributi/bonificaDati/nonDichiarati/nonDichiarati.zul",
            elaborazioni      : "/elaborazioni/listaElaborazioni.zul",
            versamenti        : "/ufficiotributi/bonificaDati/versamenti/versamenti.zul",
            sgravi            : "/ufficiotributi/imposte/sgravi.zul",
            compensazioni     : "/ufficiotributi/imposte/compensazioni.zul",
            supportoServizi   : "/ufficiotributi/supportoservizi/supportoServizi.zul",
            detrazioni        : "/ufficiotributi/detrazioni/elencoDetrazioni.zul",
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        String elemento = Sessions.getCurrent().getAttribute("elemento")
        Sessions.getCurrent().removeAttribute("elemento")
        setSelectedSezione(elemento)
		
		verificaCompetenze()
    }

    List<String> getPatterns() {
        return pagineArchivio.collect { it.key }
    }

    void handleBookmarkChange(String bookmark) {
        setSelectedSezione(bookmark)
    }

    void setSelectedSezione(String value) {
        if (value == null || value.length() == 0) {
            urlSezione = null
        }

        selectedSezione = value
        urlSezione = pagineArchivio[selectedSezione]

        BindUtils.postNotifyChange(null, null, this, "urlSezione")
        BindUtils.postNotifyChange(null, null, this, "selectedSezione")
    }
	
    private verificaCompetenze() {
        competenzeService.tipiTributoUtenza().each {
            cbTributiAbilitati << [(it.tipoTributo): true]
        }
		
		supportoServiziAbilitato =
                competenzeService.tipoAbilitazioneNoCmpetenze(CompetenzeService.FUNZIONI.SUPPORTO_SERVIZI_MENU) != null

    }
}
