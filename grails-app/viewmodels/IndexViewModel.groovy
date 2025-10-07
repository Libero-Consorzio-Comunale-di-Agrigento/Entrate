import it.finmatica.datiesterni.beans.ImportDicEncEcPf
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.Page
import org.zkoss.zk.ui.Sessions
import org.zkoss.zk.ui.util.Clients

import java.util.jar.Manifest

class IndexViewModel {

    TributiSession tributiSession
    ComunicazioniTestiService comunicazioniTestiService

    // services
    def springSecurityService
    CompetenzeService competenzeService
    CommonService commonService
    DatiGeneraliService datiGeneraliService

    ImportDicEncEcPf importDicEncEcPf

    def grailsApplication

    def dataAttuale = new Date()

    def elaborazioneCSS = "afc-button-header"

    // componenti

    // sezioni (referenziate anche dai bottoni)
    def sezioni = [
            pratiche        : "/pratiche/index.zul"
            , ufficioTributi: "/ufficiotributi/index.zul"
            , archivio      : "/archivio/index.zul"
            , sportello     : "/sportello/index.zul"
            , dizionari     : "/archivio/index.zul"
            , tefa          : "/tefa/index.zul"
            , home          : "home.zul"
    ]

    String selectedSezione
    String urlSezione

    def listaTipiTributo = []

    boolean denunceVisible = false
    boolean impostaVisible = false
    boolean archivioVisible = false
    boolean sportelloVisible = false
    boolean gestioneTefa = false

    def urlPortale

    def pulsantiAlto = [
            [titolo       : "SPORTELLO"
             , descrizione: "Visualizzazione dettagliata della situazione del contribuente (Denunce, Versamenti, Imposte, Oggetti)"
             , immagine   : "/images/afc/36x36/registry.png"
             , sezione    : "sportello"
             , elemento   : "contribuenti"
             , enabled    : true]
            ,
            [titolo       : "ARCHIVIO"
             , descrizione: "Gestione dell'archivio degli Oggetti e Soggetti"
             , immagine   : "/images/afc/36x36/home.png"
             , sezione    : "archivio"
             , elemento   : "archivio"
             , enabled    : true]
            ,
            [titolo       : "PRATICHE"
             , descrizione: "Gestione pratiche"
             , immagine   : "/images/afc/36x36/todo.png"
             , sezione    : "pratiche"
             , elemento   : "pratiche"
             , tributo    : ""
             , enabled    : true]
            ,
            [titolo       : "IMPOSTE E VERSAMENTI"
             , descrizione: "Dettaglio delle Imposte e dei Versamenti"
             , immagine   : "/images/afc/36x36/cash.png"
             , sezione    : "ufficioTributi"
             , elemento   : "imposte"
             , enabled    : true]
    ]
    def pulsantiBasso = [
            [titolo       : "IMPORT/EXPORT DATI"
             , descrizione: "Funzioni per le importazioni da banche dati esterne e l'esportazione dei dati"
             , immagine   : "/images/afc/36x36/folder_ABC.png"
             , sezione    : "ufficioTributi"
             , elemento   : "importDati"
             , enabled    : true]
            ,
            [titolo       : "BONIFICHE"
             , descrizione: "Funzioni per la bonifica dei dati a seguito di importazioni da banche dati esterne"
             , immagine   : "/images/afc/36x36/edit_windows.png"
             , sezione    : "ufficioTributi"
             , elemento   : "dichiarazioni"
             , enabled    : true]
            ,
            [titolo       : "CATASTO"
             , descrizione: "Ricerche in Catasto"
             , immagine   : "/images/afc/36x36/archive.png"
             , sezione    : "archivio"
             , elemento   : "catasto",
             enabled      : true]
            ,
            [titolo       : "DIZIONARI"
             , descrizione: "Gestione Dizionari"
             , immagine   : "/images/afc/36x36/dictionary.png"
             , sezione    : "archivio"
             , elemento   : "dizionari"
             , enabled    : true]
    ]

    @NotifyChange([
            "urlSezione",
            "selectedSezione"
    ])

    @org.zkoss.bind.annotation.Init
    init(@ContextParam(ContextType.PAGE) Page page) {

        inizializzaCompetenze()

        gestioneTefa = competenzeService.tipoAbilitazioneNoCmpetenze(CompetenzeService.FUNZIONI.GESTIONE_TEFA)

        if (competenzeService.tipoAbilitazioneNoCmpetenze(CompetenzeService.FUNZIONI.GESTIONE_TEFA)) {
            selectedSezione = "tefa"
            Sessions.getCurrent().setAttribute("elemento", "fornitureAE")
        } else {
            selectedSezione = "home"
        }

        urlSezione = sezioni[selectedSezione]

        // Calcolo della lista di tipi tributo in funzione alle competenze
        listaTipiTributo = OggettiCache.TIPI_TRIBUTO.valore.collect {
            [codice    : it.tipoTributo
             , visibile: (it.tipoTributo == "TASI" || it.tipoTributo == "ICI" || it.tipoTributo == "TARSU")
                    && (competenzeService.tipoAbilitazioneUtente(it.tipoTributo) != null)]
        }.sort { it.index }

        pulsantiAlto.find { it.titolo == "PRATICHE" }["tributo"] = listaTipiTributo.find { it.visibile }?.codice
        pulsantiBasso.find { it.titolo == "CATASTO" }["enabled"] =
                competenzeService.tipoAbilitazioneUtente("ICI") || competenzeService.tipoAbilitazioneUtente("TASI")

        // Se non si hanno competenze si disabilitano tutti i bottoni.
        if (datiGeneraliService.gestioneCompetenzeAbilitata() && competenzeService.tipiTributoUtenza().empty) {
            pulsantiAlto.each { it["enabled"] = false }
            pulsantiBasso.each { it["enabled"] = false }

            elaborazioneCSS += " disabled"
        }

        urlPortale = commonService.costruisceUrlPortale()

        controllaOggettiInvalidi()
    }

    List<String> getPatterns() {
        return sezioni.collect { it.key }
    }

    @Command
    visualizzaTask(@BindingParam("sezione") String sezione) {
        selectedSezione = sezione
        urlSezione = "/dizionari/jobs/afcElaborazioneListaExtended.zul"
        BindUtils.postNotifyChange(null, null, this, "urlSezione")
    }

    @Command
    apriSezione(@BindingParam("sezione") String sezione,
                @BindingParam("titolo") String titolo,
                @BindingParam("elemento") @Default("") String elemento) {

        if (sezione == "evasione") {
            String port = (Executions.getCurrent().getServerPort() == 80) ? "" : (":" + Executions.getCurrent().getServerPort())
            String url = Executions.getCurrent().getScheme() + "://" + Executions.getCurrent().getServerName() + port + sezioni[sezione]

            Clients.evalJavaScript("window.open('${url}','_blank');")
        } else if (sezioni[sezione]) {
            selectedSezione = sezione
            urlSezione = sezioni[selectedSezione]

            Map pulsantePremuto = (pulsantiAlto + pulsantiBasso).find { it.titolo == titolo }
            // TODO utilizzare bean di sessione
            if (pulsantePremuto?.elemento) Sessions.getCurrent().setAttribute("elemento", pulsantePremuto.elemento)
            if (pulsantePremuto?.tributo) Sessions.getCurrent().setAttribute("tributo", pulsantePremuto.tributo)

            if (!elemento.isEmpty())
                Sessions.getCurrent().setAttribute("elemento", elemento)

            BindUtils.postNotifyChange(null, null, this, "urlSezione")
            BindUtils.postNotifyChange(null, null, this, "selectedSezione")
        } else {
            Clients.showNotification("In fase di realizzazione", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
        }
    }

    @Command
    def onPortale() {
        Clients.evalJavaScript("window.open('${urlPortale}','_blank');")
    }

    @Command
    doLogout() {
        Executions.sendRedirect("/logout")
    }

    String getVersioneApplicazione() {

        InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream("META-INF/MANIFEST.MF")
        Manifest manifest = new Manifest(inputStream)

        String versione = grailsApplication.metadata['app.version']
        String buildNumber = grailsApplication.metadata['app.buildNumber']

        if (buildNumber == 'UNKNOWN') {
            buildNumber = null
        }

        buildNumber = buildNumber ? "(build #$buildNumber)" : ""

        return "© Gruppo Finmatica - TributiWeb v$versione $buildNumber"
    }

    String getNomeApplicazione() {
        return grailsApplication.metadata['app.name']
    }

    String getAmministrazioneUtente() {
        return springSecurityService.principal.amm()?.descrizione
    }

    String getUtenteCollegato() {
        return springSecurityService.principal.cognomeNome
    }

    private inizializzaCompetenze() {
        // Competenze già inizializzate
        if (tributiSession.competenze) {
            return
        }

        tributiSession.competenze = competenzeService.caricaCompetenze()
    }

    private def controllaOggettiInvalidi() {

        // Solamente al primo login si controlla la presenza di oggetti invalidi
        if (!tributiSession.oggInvalidiFirstTime) {
            return
        }

        tributiSession.oggInvalidiFirstTime = false

        def listaOggetti = commonService.getOggettiInvalidi()

        if (listaOggetti.size() > 0) {
            commonService.creaPopup("/oggettiInvalidi.zul", null, [listOggInvalidi: listaOggetti])
        }

    }
}
