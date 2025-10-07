package archivio


import it.finmatica.ad4.dto.dizionari.Ad4ComuneTr4DTO
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.*
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaSoggettiRicercaViewModel {

    Window self

    // services
    SoggettiService soggettiService
    DatiGeneraliService datiGeneraliService

    // paginazione bandbox
    def pagingDetails = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    def filtri = [
            personaFisica     : true,
            personaGiuridica  : true,
            personaParticolare: true,
            residente         : true,
            contribuente      : true,
            gsd               : true,
            codFiscale        : "",
            fonte             : -1,
            indirizzo         : "",
            id                : null,
            cognome           : "",
            nome              : "",
            ricercaSoggCont   : false,
            ///
            filtriAggiuntivi  : false,
            ///
            pressoCognome     : "",
            pressoNome        : "",
            pressoCodFiscale  : "",
            pressoIndirizzo   : "",
            pressoComune      : null,
            pressoNi          : null,
            pressoFonte       : null,
            pressoNote        : "",
            ///
            rappCognNome      : "",
            rappCodFis        : "",
            rappTipoCarica    : null,
            rappIndirizzo     : "",
            rappComune        : null,
            ///
            erediCognome      : "",
            erediNome         : "",
            erediCodFiscale   : "",
            erediIndirizzo    : "",
            erediId           : null,
            erediFonte        : null,
            erediNote         : "",
            ///
            recapTipiTributo  : [],
            recapTipiRecapito : [],
            recapIndirizzo    : "",
            recapDescr        : "",
            recapPresso       : "",
            recapNote         : "",
            recapDal          : null,
            recapAl           : null,
            ///
            familAnno         : null,
            familDal          : null,
            familAl           : null,
            familNumeroDa     : null,
            familNumeroA      : null,
            familNote         : "",
            ///
            delegTipiTributo  : [],
            delegIBAN         : "",
            delegDescr        : "",
            delegCodFisInt    : "",
            delegCognNomeInt  : "",
            delegCessata      : null,
            delegRitiroDal    : null,
            delegRitiroAl     : null,
            delegRataUnica    : null,
            delegNote         : "",
            ///
    ]
    boolean filtriAggiuntivi = false
    def filtriAggiuntiviTab = null

    def listTipiCarica = []
    def listTipiTributo = []
    def listTipiRecapito = []

    def listFontiPresso = []
    def pressoFonteSelezionata = null

    def listFontiEredi = []
    def erediFonteSelezionata = null

    def listDelegCessata = [
            [codice: null, descrizione: ""],
            [codice: true, descrizione: "Si"],
            [codice: false, descrizione: "No"],
    ]
    def delegCessataSelezionata = []

    def listDelegRataUnica = [
            [codice: null, descrizione: ""],
            [codice: true, descrizione: "Si"],
            [codice: false, descrizione: "No"],
    ]
    def delegRataUnicaSelezionata = []

    def pressoSoggetto = [
            cognomeNome: ""
    ]

    def pressoComune = [
            denominazione: ""
    ]

    def rappComune = [
            denominazione: ""
    ]

    def pressoComuneSelezionato = null

    def rappTipoCaricaSelezionata = null
    def rappComuneSelezionato = null

    def recapTipiTributoSelezionati = []
    def recapTipiRecapitoSelezionati = []

    def delegTipiTributoSelezionati = []

    def listaFetch = []
    def listaFonti

    def listaSoggetti
    def soggettoSelezionato

    boolean listaVisibile = false
    boolean ricercaSoggCont
    boolean soloContribuenti
    boolean integrazioneGSD = false
    def listaAnadev

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtri") def f,
         @ExecutionArgParam("listaVisibile") @Default('false') boolean lv,
         @ExecutionArgParam("ricercaSoggCont") @Default('false') boolean rsc,
         @ExecutionArgParam("soloContribuenti") @Default('false') boolean sc,
         @ExecutionArgParam("eseguiRicerca") @Default('false') boolean eseguiRicerca) {

        this.self = w

        filtri = f ?: filtri
        listaVisibile = lv ?: false

        filtriAggiuntivi = true

        if (listaVisibile != false) {
            this.self.setWidth("1150px")
        } else {
            this.self.setWidth("900px")
        }

        integrazioneGSD = datiGeneraliService.integrazioneGSDAbilitata()

        listaFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        //listaAnadev = Anadev.findAllBySegnalazione(false).toDTO()
        listaAnadev = Anadev.list().toDTO()

        ricercaSoggCont = rsc
        soloContribuenti = sc
        filtri.ricercaSoggCont = ricercaSoggCont
        filtri.soloContribuenti = soloContribuenti

        Short anno = Calendar.getInstance().get(Calendar.YEAR)
        listTipiTributo = soggettiService.getListaTributi(anno)

        listFontiPresso = [
                [codice: null, descrizione: ''],
                [codice: -1, descrizione: 'Tutte'],
        ]
        listaFonti.each {
            def fonte = [:]
            fonte.codice = it.fonte
            fonte.descrizione = (it.fonte as String) + " - " + it.descrizione
            listFontiPresso << fonte
        }
        listFontiEredi = listFontiPresso.clone()

        listTipiCarica = []
        def elencoTipiCarica = TipoCarica.list().toDTO()
        def tipoCarica = new TipoCarica(descrizione: "Tutti")
        tipoCarica.id = -1
        listTipiCarica << tipoCarica
        elencoTipiCarica.each {
            listTipiCarica << it
        }

        listTipiRecapito = []
        def elencoTipiRecapito = TipoRecapito.findAll()
        elencoTipiRecapito.each {
            def tipoRecapito = [:]
            tipoRecapito.codice = it.id
            tipoRecapito.descrizione = it.descrizione
            listTipiRecapito << tipoRecapito
        }

        def selezione

        pressoComuneSelezionato = filtri.pressoComune
        aggiornaComunePresso()

        selezione = filtri.pressoFonte
        pressoFonteSelezionata = listFontiPresso.find { it.codice == selezione }

        selezione = filtri.rappTipoCarica ?: 0
        rappTipoCaricaSelezionata = listTipiCarica.find { it.id == selezione }

        rappComuneSelezionato = filtri.rappComune
        aggiornaComuneRappresentante()

        selezione = filtri.erediFonte
        erediFonteSelezionata = listFontiEredi.find { it.codice == selezione }

        selezione = filtri.recapTipiTributo ?: []
        recapTipiTributoSelezionati = aggiornaSelezionati(listTipiTributo, selezione)
        selezione = filtri.recapTipiRecapito ?: []
        recapTipiRecapitoSelezionati = aggiornaSelezionati(listTipiRecapito, selezione)

        aggiornaSoggettoPressoDaNI()

        selezione = filtri.delegTipiTributo ?: []
        delegTipiTributoSelezionati = aggiornaSelezionati(listTipiTributo, selezione)
        selezione = filtri.delegCessata
        delegCessataSelezionata = listDelegCessata.find { it.codice == selezione }
        selezione = filtri.delegRataUnica
        delegRataUnicaSelezionata = listDelegRataUnica.find { it.codice == selezione }

        filtri.filtriAggiuntivi = (filtri.pressoCognome != "") ||
                (filtri.pressoNome != "") ||
                (filtri.pressoCodFiscale != "") ||
                (filtri.pressoIndirizzo != "") ||
                (filtri.pressoComune != null) ||
                (filtri.pressoNi != null) ||
                (pressoFonteSelezionata?.codice != null) ||
                (filtri.pressoNote != "") ||
                (filtri.rappCognNome != "") ||
                (filtri.rappCodFis != "") ||
                (filtri.rappTipoCarica != null) ||
                (filtri.rappIndirizzo != "") ||
                (filtri.rappComune != null) ||
                (filtri.erediCognome != "") ||
                (filtri.erediNome != "") ||
                (filtri.erediCodFiscale != "") ||
                (filtri.erediIndirizzo != "") ||
                (filtri.erediId != null) ||
                (erediFonteSelezionata?.codice != null) ||
                (filtri.erediNote != "") ||
                (recapTipiTributoSelezionati.size() > 0) ||
                (recapTipiRecapitoSelezionati.size() > 0) ||
                (filtri.recapIndirizzo != "") ||
                (filtri.recapDescr != "") ||
                (filtri.recapPresso != "") ||
                (filtri.recapNote != "") ||
                (filtri.recapDal != null) ||
                (filtri.recapAl != null) ||
                (filtri.familAnno != null) ||
                (filtri.familDal != null) ||
                (filtri.familAl != null) ||
                (filtri.familNumeroDa != null) ||
                (filtri.familNumeroA != null) ||
                (filtri.familNote != "") ||
                (delegTipiTributoSelezionati.size() > 0) ||
                (filtri.delegIBAN != "") ||
                (filtri.delegDescr != "") ||
                (filtri.delegCodFisInt != "") ||
                (filtri.delegCognNomeInt != "") ||
                delegCessataSelezionata?.codice != null ||
                (filtri.delegRitiroDal != null) ||
                (filtri.delegRitiroAl != null) ||
                delegRataUnicaSelezionata?.codice != null ||
                (filtri.delegNote != "")

        if (eseguiRicerca) {
            onCerca()
        }
    }

    @Command
    onSvuotaFiltri() {

        filtri.codFiscale = ""
        filtri.indirizzo = ""
        filtri.id = null
        filtri.fonte = -1
        filtri.cognome = ""
        filtri.nome = ""
        filtri.ricercaSoggCont = ricercaSoggCont
        filtri.soloContribuenti = soloContribuenti

        ///	filtri.filtriAggiuntivi = false

        filtri.pressoCognome = ""
        filtri.pressoNome = ""
        filtri.pressoCodFiscale = ""
        filtri.pressoIndirizzo = ""
        filtri.pressoComune = null
        filtri.pressoNi = null
        filtri.pressoFonte = null
        filtri.pressoNote = ""

        filtri.rappCognNome = ""
        filtri.rappCodFis = ""
        filtri.rappTipoCarica = null
        filtri.rappIndirizzo = ""
        filtri.rappComune = null

        filtri.erediCognome = ""
        filtri.erediNome = ""
        filtri.erediCodFiscale = ""
        filtri.erediIndirizzo = ""
        filtri.erediId = null
        filtri.erediFonte = null
        filtri.erediNote = ""

        filtri.recapTipiTributo = []
        filtri.recapTipiRecapito = []
        filtri.recapIndirizzo = ""
        filtri.recapDescr = ""
        filtri.recapPresso = ""
        filtri.recapNote = ""
        filtri.recapDal = null
        filtri.recapAl = null

        filtri.familAnno = null
        filtri.familDal = null
        filtri.familAl = null
        filtri.familNumeroDa = null
        filtri.familNumeroA = null
        filtri.familNote = ""

        filtri.delegTipiTributo = []
        filtri.delegIBAN = ""
        filtri.delegDescr = ""
        filtri.delegCodFisInt = ""
        filtri.delegCognNomeInt = ""
        filtri.delegCessata = null
        filtri.delegRitiroDal = null
        filtri.delegRitiroAl = null
        filtri.delegRataUnica = null
        filtri.delegNote = ""

        pressoComuneSelezionato = null
        pressoFonteSelezionata = null

        rappTipoCaricaSelezionata = null
        rappComuneSelezionato = null

        erediFonteSelezionata = null

        recapTipiTributoSelezionati = []
        recapTipiRecapitoSelezionati = []

        delegTipiTributoSelezionati = []
        delegCessataSelezionata = null
        delegRataUnicaSelezionata = null

        listaSoggetti = []
        soggettoSelezionato = null

        pagingDetails.activePage = 0
        pagingDetails.totalSize = 0

        aggiornaSoggettoPressoDaNI()
        aggiornaComunePresso()

        aggiornaComuneRappresentante()

        BindUtils.postNotifyChange(null, null, this, "pressoComuneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pressoFonteSelezionata")
        BindUtils.postNotifyChange(null, null, this, "rappTipoCaricaSelezionata")
        BindUtils.postNotifyChange(null, null, this, "rappComuneSelezionato")
        BindUtils.postNotifyChange(null, null, this, "erediFonteSelezionata")
        BindUtils.postNotifyChange(null, null, this, "elencoRecapTipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "recapTipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoRecapTipiRecapitoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "recapTipiRecapitoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoDelegTipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "delegTipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "delegCessataSelezionata")
        BindUtils.postNotifyChange(null, null, this, "delegRataUnicaSelezionata")

        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "soggettoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaSoggetti")
        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
    }

    @Command
    def onOpenCloseFiltriAggiuntivi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        Boolean openEvent = event.target.isOpen()

        filtri.filtriAggiuntivi = openEvent
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    def onFiltriAggiuntiviTabs() {

    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onScegliSoggetto() {

        def filtriNow = completaFiltri()
        Events.postEvent(Events.ON_CLOSE, self, [status: "Soggetto", filtri: filtriNow, Soggetto: soggettoSelezionato])
    }

    @Command
    onCerca() {

        if (listaVisibile) {
            caricaLista()
            self.invalidate()
        } else {
            def filtriNow = completaFiltri()
            Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: filtriNow])
        }
    }

    @Command
    onRefresh() {

        caricaLista()
    }

    @Command
    onSelectIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        filtri.indirizzo = (event.data.denomUff ?: null)
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onSelectSoggettoPresso(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        def pressoSelezionato = event.getData() ?: null
        BindUtils.postNotifyChange(null, null, this, "pressoSelezionato")

        filtri.pressoNi = pressoSelezionato.id
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onChangeSoggettoPresso() {

        aggiornaSoggettoPressoDaNI()
    }

    @Command
    def onSelectPressoIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        filtri.pressoIndirizzo = (event.data.denomUff ?: null)
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    onSelectPressoComune(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (event.getData()) {

            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            pressoComuneSelezionato = ad4ComuneTr4DTO
        } else {
            pressoComuneSelezionato = null
        }
        BindUtils.postNotifyChange(null, null, this, "pressoComuneSelezionato")

        aggiornaComunePresso()
    }

    @Command
    def onSelectPressoFonte() {

    }

    @Command
    onSelectRappComune(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        if (event.getData()) {

            Ad4ComuneTr4DTO ad4ComuneTr4DTO = new Ad4ComuneTr4DTO()
            ad4ComuneTr4DTO.ad4Comune = event.getData()
            ad4ComuneTr4DTO.comune = event.getData().comune
            ad4ComuneTr4DTO.provinciaStato = event.getData().provincia ? event.getData().provincia.id : event.getData().stato.id
            rappComuneSelezionato = ad4ComuneTr4DTO
        } else {
            rappComuneSelezionato = null
        }
        BindUtils.postNotifyChange(null, null, this, "rappComuneSelezionato")

        aggiornaComuneRappresentante()
    }

    @Command
    def onSelectErediFonte() {

    }

    @Command
    onSelectErediIndirizzo(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        filtri.erediIndirizzo = (event.data.denomUff ?: null)
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @NotifyChange("elencoRecapTipiTributoSelezionati")
    @Command
    def onSelectRecapTipiTributo() {

    }

    String getElencoRecapTipiTributoSelezionati() {

        return recapTipiTributoSelezionati?.nome?.join(", ")
    }

    @NotifyChange("elencoRecapTipiRecapitoSelezionati")
    @Command
    def onSelectRecapTipiRecapito() {

    }

    String getElencoRecapTipiRecapitoSelezionati() {

        return recapTipiRecapitoSelezionati?.descrizione?.join(", ")
    }

    @NotifyChange("elencoDelegTipiTributoSelezionati")
    @Command
    def onSelectDelegTipiTributo() {

    }

    String getElencoDelegTipiTributoSelezionati() {

        return delegTipiTributoSelezionati?.nome?.join(", ")
    }

    @Command
    def onSelectDelegCessata() {

    }

    @Command
    def onSelectDelegRataUnica() {

    }
    ///
    /// *** Carica lista soggetti
    ///
    private caricaLista() {

        def filtriNow = completaFiltri()

        def elenco = soggettiService.listaSoggetti(filtriNow, pagingDetails.pageSize, pagingDetails.activePage,
                ["contribuenti", "comuneNascita.ad4Comune", "comuneNascita.ad4Comune.provincia"])
        listaSoggetti = elenco.lista
        pagingDetails.totalSize = elenco.totale
        if (pagingDetails.totalSize <= pagingDetails.pageSize) pagingDetails.activePage = 0

        //Sistemazione della descrizione dello stato in caso di valori nulli
        listaSoggetti.each {
            if (it.stato && it.stato.descrizione == null) {
                int indice = it.stato?.id
                it.stato.descrizione = listaAnadev.find { l -> l.id == indice }?.descrizione
            }
        }

        BindUtils.postNotifyChange(null, null, this, "listaSoggetti")
        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
    }

    ///
    /// *** Completa il filtri
    ///
    private def completaFiltri() {

        def filtriNow = filtri.clone()

        filtriNow.pressoComune = pressoComuneSelezionato
        filtriNow.pressoFonte = pressoFonteSelezionata?.codice

        filtriNow.rappTipoCarica = rappTipoCaricaSelezionata?.id
        filtriNow.rappComune = rappComuneSelezionato

        filtriNow.erediFonte = erediFonteSelezionata?.codice

        filtriNow.recapTipiTributo = aggiornaSelezione(recapTipiTributoSelezionati)
        filtriNow.recapTipiRecapito = aggiornaSelezione(recapTipiRecapitoSelezionati)

        filtriNow.delegTipiTributo = aggiornaSelezione(delegTipiTributoSelezionati)

        filtriNow.delegCessata = delegCessataSelezionata?.codice
        filtriNow.delegRataUnica = delegRataUnicaSelezionata?.codice

        return filtriNow
    }

    ///
    /// *** Aggiorna descrizione Presso da pressoNI del filtro
    ///
    def aggiornaSoggettoPressoDaNI() {

        Soggetto presso = null

        if (filtri.pressoNi > 0) {
            presso = Soggetto.get(filtri.pressoNi)
        }
        pressoSoggetto = [cognomeNome: (presso) ? presso.cognomeNome : ""]
        BindUtils.postNotifyChange(null, null, this, "pressoSoggetto")
    }

    ///
    /// *** Aggiorna descrizione Comune Presso
    ///
    def aggiornaComunePresso() {

        pressoComune = [denominazione: (pressoComuneSelezionato) ? pressoComuneSelezionato.ad4Comune.denominazione : ""]
        BindUtils.postNotifyChange(null, null, this, "pressoComune")
    }

    ///
    /// *** Aggiorna descrizione Comune Rappresentante
    ///
    def aggiornaComuneRappresentante() {

        rappComune = [denominazione: (rappComuneSelezionato) ? rappComuneSelezionato.ad4Comune.denominazione : ""]
        BindUtils.postNotifyChange(null, null, this, "rappComune")
    }

    ///
    /// *** Aggionra selezionati x codice da lista
    ///
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

    ///
    /// *** Elencoa selezionati in lista
    ///
    private def aggiornaSelezione(def lista) {

        def selezionati = []

        lista.each {
            selezionati << it.codice
        }

        return selezionati
    }
}
