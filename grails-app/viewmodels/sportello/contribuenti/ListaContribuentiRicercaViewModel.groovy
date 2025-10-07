package sportello.contribuenti

import it.finmatica.tr4.Fonte
import it.finmatica.tr4.TipoContatto
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.FiltroRicercaStatiContribuente
import it.finmatica.tr4.contribuenti.StatoContribuenteService
import it.finmatica.tr4.datiesterni.TitoloDocumento
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.dto.TipoStatoContribuenteDTO
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class ListaContribuentiRicercaViewModel {

    Window self

    // services
    SoggettiService soggettiService
    StatoContribuenteService statoContribuenteService
    CompetenzeService competenzeService

    // modalità lista
    boolean listaVisibile = false
    boolean ricercaSoggCont = false
    def listaContribuenti
    def soggettoSelezionato

    def modalitaContribuente

    // filtri
    def filtri = [
            contribuente             : "s",
            cognomeNome              : "",
            cognome                  : "",
            nome                     : "",
            indirizzo                : "",
            codFiscale               : "",
            id                       : null,
            codContribuente        : null,
            //
            codFiscaleEscluso        : "",
            idEscluso                : null,
            //
            tipiPratica              : [],
            tipiTributo              : [],
            //
            filtriAggiuntivi         : false,
            //
            tipoContatto             : null,
            annoContatto             : null,
            //
            titoloDocumento          : "",
            nomeFileDocumento        : "",
            validoDaDocumento        : null,
            validoADocumento         : null,
            //
            fonteVersamento          : null,
            ordinarioVersamento      : false,
            tipoVersamento           : null,
            rataVersamento           : null,
            tipoPraticaVersamento    : null,
            statoPraticaVersamento   : null,
            ruoloVersamento          : null,
            progrDocVersamento       : null,
            annoDaVersamento         : null,
            annoAVersamento          : null,
            pagamentoDaVersamento    : null,
            pagamentoAVersamento     : null,
            registrazioneDaVersamento: null,
            registrazioneAVersamento : null,
            importoDaVersamento      : null,
            importoAVersamento       : null,
            soloConVersamenti        : false,
            //
            statoAttivi              : false,
            statoCessati             : false,
            annoStato                : null,
            //
            statoContribuenteFilter  : new FiltroRicercaStatiContribuente()
    ]


    boolean filtriAggiuntivi = false
    def filtriAggiuntiviTab = null

    boolean flagTipoERataVersamento = true

    def listTipiTributo = []
    def tipiTributoSelezionati = []

    def tipiTributo = []

    def listTipiPratica = [
            [codice: null, descrizione: ''],
            [codice: 'D', descrizione: 'Dichiarazione'],
            [codice: 'L', descrizione: 'Liquidazione/Infrazione'],
            [codice: 'A', descrizione: 'Accertamento'],
            [codice: 'R', descrizione: 'Ravvedimento'],
    ]
    def tipiPraticaSelezionati = []

    def listTitoliDocumento = []
    def titoloDocumentoSelezionato = null

    def listTipiContatto = []
    def tipoContattoSelezionato = null

    def listFontiVersamento = []
    def fonteVersamentoSelezionata = null

    def listTipiVersamento = [
            [codice: null, descrizione: ''],
            [codice: 'T', descrizione: 'Tutti'],
            [codice: 'A', descrizione: 'Acconto'],
            [codice: 'S', descrizione: 'Saldo'],
            [codice: 'U', descrizione: 'Unico'],
    ]
    def tipoVersamentoSelezionato = []

    def listRateVersamento = [
            [codice: null, descrizione: ''],
            [codice: 'T', descrizione: 'Tutte'],
            [codice: '0', descrizione: 'Unica'],
            [codice: '1', descrizione: 'Prima'],
            [codice: '2', descrizione: 'Seconda'],
            [codice: '3', descrizione: 'Terza'],
            [codice: '4', descrizione: 'Quarta'],
    ]
    def rataVersamentoSelezionata = []

    def listTipiPraticaVersamento = [
            [codice: null, descrizione: ''],
            [codice: 'T', descrizione: 'Tutti'],
            [codice: 'D', descrizione: 'Dichiarazione'],
            [codice: 'L', descrizione: 'Liquidazione/Infrazione'],
            [codice: 'A', descrizione: 'Accertamento'],
            [codice: 'R', descrizione: 'Ravvedimento'],
    ]
    def tipoPraticaVersamentoSelezionato = null

    def listStatiPraticaVersamento = []
    def statoPraticaVersamentoSelezionato = null

    def listProgrDocVersamento = []
    def progrDocVersamentoSelezionato = null

    List<TipoStatoContribuenteDTO> tipoStatoContribuenteList

    // paginazione
    def pagingDetails = [
            activePage: 0,
            pageSize  : 10,
            totalSize : 0
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("filtri") def f
         , @ExecutionArgParam("listaVisibile") def lv
         , @ExecutionArgParam("ricercaSoggCont") def rsc) {

        this.self = w

        listaVisibile = lv ?: false
        ricercaSoggCont = rsc ?: false

        if (listaVisibile != false) {
            this.self.setWidth("1000px")
        }

        if (f) {
            filtri = f
        }

        modalitaContribuente = true
        if (filtri.contribuente) {
            if (filtri.contribuente == "-") modalitaContribuente = false
        }

        filtriAggiuntivi = modalitaContribuente
        if (filtriAggiuntivi != false) {
            pagingDetails.pageSize = 8
        }

        Short anno = Calendar.getInstance().get(Calendar.YEAR)
        listTipiTributo = soggettiService.getListaTributi(anno)

        this.tipiTributo = [null] + competenzeService.tipiTributoUtenza()

        List<TitoloDocumento> elencoTitoliDocumento = TitoloDocumento.findAll()
        elencoTitoliDocumento.sort { it.descrizione }

        listTitoliDocumento = [
                [codice: null, descrizione: ''],
                [codice: -1, descrizione: 'Tutti'],
        ]
        elencoTitoliDocumento.each {
            def titoloDocumento = [:]
            titoloDocumento.codice = it.id
            titoloDocumento.descrizione = it.descrizione
            listTitoliDocumento << titoloDocumento
        }

        List<TipoContatto> elencoTipiContatto = TipoContatto.findAll()
        elencoTipiContatto.sort { it.tipoContatto }

        listTipiContatto = [
                [codice: null, descrizione: ''],
                [codice: -1, descrizione: 'Tutti'],
        ]
        elencoTipiContatto.each {
            def tipoContatto = [:]
            tipoContatto.codice = it.tipoContatto
            tipoContatto.descrizione = (it.tipoContatto as String) + " - " + it.descrizione
            listTipiContatto << tipoContatto
        }

        List<FonteDTO> elencoFonti = Fonte.findAllByFonteGreaterThanEquals("0", [sort: "fonte", order: "asc"]).toDTO()

        listFontiVersamento = [
                [codice: null, descrizione: ''],
                [codice: -1, descrizione: 'Tutte'],
        ]
        elencoFonti.each {
            def fonte = [:]
            fonte.codice = it.fonte
            fonte.descrizione = (it.fonte as String) + " - " + it.descrizione
            listFontiVersamento << fonte
        }

        List<TipoStato> elencoTipiStato = TipoStato.findAll()
        elencoTipiStato.sort { it.descrizione }

        listStatiPraticaVersamento = [
                [codice: null, descrizione: ''],
                [codice: '-', descrizione: 'Tutti'],
        ]
        elencoTipiStato.each {
            def stato = [:]
            stato.codice = it.tipoStato
            stato.descrizione = it.descrizione
            listStatiPraticaVersamento << stato
        }

        def selezione

        selezione = filtri.tipiTributo ?: []
        tipiTributoSelezionati = aggiornaSelezionati(listTipiTributo, selezione)
        selezione = filtri.tipiPratica ?: []
        tipiPraticaSelezionati = aggiornaSelezionati(listTipiPratica, selezione)

        selezione = filtri.tipoContatto
        tipoContattoSelezionato = listTipiContatto.find { it.codice == selezione }

        selezione = null //	filtri.titoloDocumento
        titoloDocumentoSelezionato = listTitoliDocumento.find { it.codice == selezione }

        selezione = filtri.fonteVersamento
        fonteVersamentoSelezionata = listFontiVersamento.find { it.codice == selezione }
        selezione = filtri.tipoVersamento
        tipoVersamentoSelezionato = listTipiVersamento.find { it.codice == selezione }
        selezione = filtri.rataVersamento
        rataVersamentoSelezionata = listRateVersamento.find { it.codice == selezione }
        selezione = filtri.tipoPraticaVersamento
        tipoPraticaVersamentoSelezionato = listTipiPraticaVersamento.find { it.codice == selezione }
        selezione = filtri.statoPraticaVersamento
        statoPraticaVersamentoSelezionato = listStatiPraticaVersamento.find { it.codice == selezione }

        ricaricaListProgDoc(true)

        filtri.filtriAggiuntivi = (tipoContattoSelezionato?.codice != null) ||
                (filtri.annoContatto != null) ||
                //		titoloDocumentoSelezionato?.codice != null ||
                (filtri.titoloDocumento) ||
                (filtri.nomeFileDocumento) ||
                (filtri.validoDaDocumento != null) ||
                (filtri.validoADocumento != null) ||
                fonteVersamentoSelezionata?.codice != null ||
                filtri.ordinarioVersamento ||
                tipoVersamentoSelezionato?.codice != null ||
                rataVersamentoSelezionata?.codice != null ||
                tipoPraticaVersamentoSelezionato?.codice != null ||
                filtri.statoPraticaVersamento != null ||
                filtri.ruoloVersamento != null ||
                progrDocVersamentoSelezionato?.codice != null ||
                filtri.annoDaVersamento != null ||
                filtri.annoAVersamento != null ||
                filtri.pagamentoDaVersamento != null ||
                filtri.pagamentoAVersamento != null ||
                filtri.registrazioneDaVersamento != null ||
                filtri.registrazioneAVersamento != null ||
                filtri.importoDaVersamento != null ||
                filtri.importoAVersamento != null ||
                filtri.statoAttivi ||
                filtri.statoCessati ||
                (filtri.annoStato != null) ||
                filtri.statoContribuenteFilter?.isActive()

        aggiornaPerTributo()

        tipoStatoContribuenteList = statoContribuenteService.listTipiStatoContribuente()
        tipoStatoContribuenteList.add(0, null)
    }

    @Command
    onSvuotaFiltri() {

        filtri.cognomeNome = ""
        filtri.cognome = ""
        filtri.nome = ""
        filtri.codFiscale = ""
        filtri.indirizzo = ""
        filtri.id = null
        filtri.codContribuente = null


        tipiTributoSelezionati = []
        tipiPraticaSelezionati = []

        svuotaFiltriAggiuntivi()
        ricaricaListProgDoc(false)

        aggiornaPerTributo()

        BindUtils.postNotifyChange(null, null, this, "filtri")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "tipiTributoSelezionati")
        BindUtils.postNotifyChange(null, null, this, "elencoTipiPraticaSelezionati")
        BindUtils.postNotifyChange(null, null, this, "tipiPraticaSelezionati")
        BindUtils.postNotifyChange(null, null, this, "titoloDocumentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "tipoContattoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "fonteVersamentoSelezionata")
        BindUtils.postNotifyChange(null, null, this, "tipoVersamentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "rataVersamentoSelezionata")
        BindUtils.postNotifyChange(null, null, this, "tipoPraticaVersamentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "statoPraticaVersamentoSelezionato")

    }

    def svuotaFiltriAggiuntivi() {
        filtri.tipoContatto = null
        filtri.annoContatto = null

        filtri.titoloDocumento = ""
        filtri.nomeFileDocumento = ""
        filtri.validoDaDocumento = null
        filtri.validoADocumento = null

        filtri.fonteVersamento = null
        filtri.ordinarioVersamento = false
        filtri.tipoVersamento = null
        filtri.rataVersamento = null
        filtri.tipoPraticaVersamento = null
        filtri.statoPraticaVersamento = null
        filtri.ruoloVersamento = null
        filtri.progrDocVersamento = null
        filtri.annoDaVersamento = null
        filtri.annoAVersamento = null
        filtri.pagamentoDaVersamento = null
        filtri.pagamentoAVersamento = null
        filtri.registrazioneDaVersamento = null
        filtri.registrazioneAVersamento = null
        filtri.importoDaVersamento = null
        filtri.importoAVersamento = null
        filtri.soloConVersamenti = false

        filtri.statoAttivi = false
        filtri.statoCessati = false
        filtri.annoStato = null

        filtri.statoContribuenteFilter?.reset()

        filtri.filtriAggiuntivi = false

        tipoContattoSelezionato = null

        titoloDocumentoSelezionato = null

        progrDocVersamentoSelezionato = null

        fonteVersamentoSelezionata = null
        tipoVersamentoSelezionato = null
        rataVersamentoSelezionata = null
        tipoPraticaVersamentoSelezionato = null
        statoPraticaVersamentoSelezionato = null
    }

    @Command
    def onOpenCloseFiltriAggiuntivi(@ContextParam(ContextType.TRIGGER_EVENT) Event event) {

        Boolean openEvent = event.target.isOpen()

        filtri.filtriAggiuntivi = openEvent
        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    @Command
    def onCheckFiltriAggiuntivi() {
        if (!filtri.filtriAggiuntivi) {
            svuotaFiltriAggiuntivi()

            BindUtils.postNotifyChange(null, null, this, "filtri")
            BindUtils.postNotifyChange(null, null, this, "elencoTipiTributoSelezionati")
            BindUtils.postNotifyChange(null, null, this, "tipiTributoSelezionati")
            BindUtils.postNotifyChange(null, null, this, "elencoTipiPraticaSelezionati")
            BindUtils.postNotifyChange(null, null, this, "tipiPraticaSelezionati")
            BindUtils.postNotifyChange(null, null, this, "titoloDocumentoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "tipoContattoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "fonteVersamentoSelezionata")
            BindUtils.postNotifyChange(null, null, this, "tipoVersamentoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "rataVersamentoSelezionata")
            BindUtils.postNotifyChange(null, null, this, "tipoPraticaVersamentoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "statoPraticaVersamentoSelezionato")
            BindUtils.postNotifyChange(null, null, this, "progrDocVersamentoSelezionato")

        }
    }

    @Command
    def onFiltriAggiuntiviTabs() {

    }

    @NotifyChange("elencoTipiTributoSelezionati")
    @Command
    def onSelectTipiTributo() {

        ricaricaListProgDoc(true)

        aggiornaPerTributo()
    }

    String getElencoTipiTributoSelezionati() {

        return tipiTributoSelezionati?.nome?.join(", ")
    }

    @NotifyChange("elencoTipiPraticaSelezionati")
    @Command
    def onSelectTipiPratica() {

    }

    String getElencoTipiPraticaSelezionati() {

        return tipiPraticaSelezionati?.codice?.join(", ")
    }

    @Command
    def onSelectTipoContatto() {

    }

    @Command
    def onSelectTitoloDocumento() {

    }

    @Command
    def onSelectFonteVersamento() {

    }

    @Command
    def onSelectTipoVersamento() {

    }

    @Command
    def onSelectRataVersamento() {

    }

    @Command
    def onSelectTipoPraticaVersamento() {

    }

    @Command
    def onSelectStatoPraticaVersamento() {

    }

    @Command
    def onCheckedStatoAttivi() {

        if (filtri.statoCessati != false) {
            filtri.statoCessati = false
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    @Command
    def onCheckedStatoCessati() {

        if (filtri.statoAttivi != false) {
            filtri.statoAttivi = false
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
    }

    @Command
    def onSelectProgrDocVersamento() {

    }

    @Command
    onCerca() {

        if (!validaFiltri()) return

        if (listaVisibile) {
            caricaLista(true)
        } else {
            def filtriNow = completaFiltri()
            Events.postEvent(Events.ON_CLOSE, self, [status: "Cerca", filtri: filtriNow])
        }
    }

    @Command
    onRefresh() {

        caricaLista(true)
    }

    @Command
    def onPaging() {

        caricaLista()
    }

    @Command
    onScegliSoggetto() {

        def filtriNow = completaFiltri()

        Long idSoggetto
        String cfSogetto

        idSoggetto = soggettoSelezionato.id
        if (modalitaContribuente) {
            cfSogetto = soggettoSelezionato.contribuente.codFiscale
        } else {
            cfSogetto = soggettoSelezionato.codFiscale
        }

        Events.postEvent(Events.ON_CLOSE, self, [status: "Sogggetto", filtri: filtriNow, idSoggetto: idSoggetto, cfSoggetto: cfSogetto])
    }

    @Command
    onChiudi() {

        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    // Ricarica elenco in modalità lista
    private caricaLista(def resetPaginazione = false) {

        def filtriNow = completaFiltri()

        if (resetPaginazione) {
            pagingDetails.activePage = 0
        }

        def elenco = soggettiService.listaSoggetti(filtriNow, pagingDetails.pageSize, pagingDetails.activePage,
                ["contribuenti", "comuneResidenza", "comuneResidenza.ad4Comune", "archivioVie"])
        listaContribuenti = elenco.lista
        pagingDetails.totalSize = elenco.totale

        if (elenco.totale < (pagingDetails.pageSize * pagingDetails.activePage)) {
            caricaLista(true)
        }

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
        BindUtils.postNotifyChange(null, null, this, "pagingDetails")
    }

    // Completa il filtri
    private def completaFiltri() {

        def filtriNow = filtri.clone()

        filtriNow.ricercaSoggCont = ricercaSoggCont

        filtriNow.tipiTributo = aggiornaSelezione(tipiTributoSelezionati)
        filtriNow.tipiPratica = aggiornaSelezione(tipiPraticaSelezionati)

        filtriNow.tipoContatto = tipoContattoSelezionato?.codice

        filtriNow.fonteVersamento = fonteVersamentoSelezionata?.codice

        filtriNow.tipoVersamento = tipoVersamentoSelezionato?.codice
        filtriNow.rataVersamento = rataVersamentoSelezionata?.codice

        filtriNow.tipoPraticaVersamento = tipoPraticaVersamentoSelezionato?.codice
        filtriNow.statoPraticaVersamento = statoPraticaVersamentoSelezionato?.codice
        filtriNow.progrDocVersamento = progrDocVersamentoSelezionato?.codice

        return filtriNow
    }

    // Valida i filtri, false se errore
    private def validaFiltri() {

        String message = ""

        if (filtri.annoContatto != null) {
            if ((filtri.annoContatto < 1900) || (filtri.annoContatto > 2099)) {
                message += "- Il valore di Contatti -> 'Anno' deve essere compreso tra 1900 e 2099, oppure lasciare vuoto !\n"
            }
        }

        if (filtri.annoStato != null) {
            if ((filtri.annoStato < 1900) || (filtri.annoStato > 2099)) {
                message += "- Il valore di Stato -> Anno deve essere compreso tra 1900 e 2099, oppure lasciare vuoto !\n"
            }
        }

        def annoDaVersamento = filtri.annoDaVersamento ?: 1900
        def annoAVersamento = filtri.annoAVersamento ?: 2099

        if ((annoDaVersamento < 1900) || (annoDaVersamento > 2099)) {
            message += "- Il valore di Versamenti -> Anno Da deve essere compreso tra 1900 e 2099, oppure lasciare vuoto !\n"
        } else {
            if ((annoAVersamento < annoDaVersamento) || (annoAVersamento > 2099)) {
                message += "- Il valore di Versamenti -> Anno A deve essere maggiore o uguale ad Anno Da e minore o uguale di 2099, oppure lasciare vuoto !\n"
            }
        }

        def pagamentoDaVersamento = filtri.pagamentoDaVersamento ?: new Date(1900, 1, 1)
        def pagamentoAVersamento = filtri.pagamentoDaVersamento ?: new Date(2099, 1, 1)

        def registrazioneDaVersamento = filtri.registrazioneDaVersamento ?: new Date(1900, 1, 1)
        def registrazioneAVersamento = filtri.registrazioneAVersamento ?: new Date(2099, 1, 1)

        def importoDaVersamento = filtri.importoDaVersamento ?: 0.0
        def importoAVersamento = filtri.importoAVersamento ?: Double.MAX_VALUE

        if (importoDaVersamento < 0.0) {
            message += "- Il valore di Versamenti -> Importo Da deve essere maggiore o uguale a 0.00, oppure lasciare vuoto !\n"
        } else {
            if (importoAVersamento <= importoDaVersamento) {
                message += "- Il valore di Versamenti -> Importo A deve essere maggiore a Importo Da, oppure lasciare vuoto !\n"
            }
        }

        try {
            filtri.statoContribuenteFilter?.validate()
        } catch (IllegalArgumentException e) {
            message += "- " + e.localizedMessage + "\n"
        }

        if (!message.isEmpty()) {
            message = "Attenzione :\n\n" + message
            Messagebox.show(message, "Errore di comnpilazione", Messagebox.OK, Messagebox.INFORMATION)
        }

        return message.isEmpty()
    }

    // Ricarica Prog Doc in base a tributi
    def ricaricaListProgDoc(boolean select) {

        def selezioneOld = progrDocVersamentoSelezionato?.codice

        def elencoTributi = []
        tipiTributoSelezionati.each {
            elencoTributi << it.codice
        }

        listProgrDocVersamento = [
                [codice: null, descrizione: ''],
                [codice: -1, descrizione: 'Tutti']
        ]

        def elencoProgrDoc = soggettiService.getListaProgrDocPerTributi(elencoTributi)
        elencoProgrDoc.each {
            listProgrDocVersamento << it
        }

        if (select) {
            def selezione = selezioneOld ?: filtri.progrDocVersamento
            progrDocVersamentoSelezionato = listProgrDocVersamento.find { it.codice == selezione }
        } else {
            progrDocVersamentoSelezionato = null
        }

        BindUtils.postNotifyChange(null, null, this, "progrDocVersamentoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listProgrDocVersamento")
    }

    // Aggiorna flag per tipo tributo
    def aggiornaPerTributo() {

        def tributiConRateazione = tipiTributoSelezionati.findAll { it.codice in ['ICI', 'TASI', 'CUNI'] }

        flagTipoERataVersamento = tributiConRateazione.size() > 0

        BindUtils.postNotifyChange(null, null, this, "flagTipoERataVersamento")
    }

    // Aggionra selezionati x codice da lista
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

    // Elencoa selezionati in lista
    private def aggiornaSelezione(def lista) {

        def selezionati = []

        lista.each {
            selezionati << it.codice
        }

        return selezionati
    }
}
