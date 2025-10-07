package archivio

import commons.SostituzioneContribuenteViewModel
import document.FileNameGenerator
import it.finmatica.tr4.Anadev
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.AnadevDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

import java.text.DecimalFormat

class ListaSoggettiViewModel extends SostituzioneContribuenteViewModel {

    Window self

    // Servizi
    CommonService commonService

    @Wire("#paging")
    protected Paging paging

    def listaSoggetti

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    // dati
    boolean stampaVisibile = true
    boolean filtroAttivo = false
    boolean integrazioneGSD = false

    def filtri = [personaFisica       : true
                  , personaGiuridica  : true
                  , personaParticolare: true
                  , residente         : "e"
                  , contribuente      : "e"
                  , gsd               : "e"
                  , cognome           : ""
                  , nome              : ""
                  , codFiscale        : ""
                  , fonte             : -1
                  , indirizzo         : ""
                  , id                : null,
                  ///
                  pressoCognome       : "",
                  pressoNome          : "",
                  pressoCodFiscale    : "",
                  pressoIndirizzo     : "",
                  pressoComune        : null,
                  pressoNi            : null,
                  pressoFonte         : null,
                  pressoNote          : "",
                  ///
                  rappCognNome        : "",
                  rappCodFis          : "",
                  rappTipoCarica      : null,
                  rappIndirizzo       : "",
                  rappComune          : null,
                  ///
                  erediCognome        : "",
                  erediNome           : "",
                  erediCodFiscale     : "",
                  erediId             : null,
                  erediIndirizzo      : "",
                  erediFonte          : null,
                  erediNote           : "",
                  ///
                  recapTipiTributo    : [],
                  recapTipiRecapito   : [],
                  recapIndirizzo      : "",
                  recapDescr          : "",
                  recapPresso         : "",
                  recapNote           : "",
                  recapDal            : null,
                  recapAl             : null,
                  ///
                  familAnno           : null,
                  familDal            : null,
                  familAl             : null,
                  familNumeroDa       : null,
                  familNumeroA        : null,
                  familNote           : "",
                  ///
                  delegTipiTributo    : [],
                  delegIBAN           : "",
                  delegDescr          : "",
                  delegCodFisInt      : "",
                  delegCognNomeInt    : "",
                  delegCessata        : null,
                  delegRitiroDal      : null,
                  delegRitiroAl       : null,
                  delegRataUnica      : null,
                  delegNote           : "",
                  ///
    ]

    ArrayList<AnadevDTO> listaAnadev

    @NotifyChange(["listaSoggetti", "totalSize", "activePage"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        integrazioneGSD = datiGeneraliService.integrazioneGSDAbilitata()
        //listaAnadev = Anadev.findAllBySegnalazione(false).toDTO()
        listaAnadev = Anadev.list().toDTO()
    }

    @Command
    openCloseFiltri() {
        apriMascheraRicerca()
    }

    @Command
    onModifica() {
        Window w = Executions.createComponents("/archivio/soggetto.zul", self, [idSoggetto: soggettoSelezionato.id])
        w.onClose {
            if (filtroAttivo) {
                caricaLista()
            }
        }
        w.doModal()
    }

    @Command
    onPaging() {
        caricaLista()
    }

    @Command
    onRefresh() {
        activePage = 0
        caricaLista()
    }

    @Command
    onNuovo() {
        Window w = Executions.createComponents("/archivio/soggetto.zul", self, [idSoggetto: -1])
        w.onClose {
            if (filtroAttivo) {
                caricaLista()
            }
        }
        w.doModal()
    }

    private caricaLista() {

        filtri.soloContribuenti = filtri.contribuente.toUpperCase() == 'S'

        def elenco = soggettiService.listaSoggetti(filtri, pageSize, activePage, ["contribuenti"])

        listaSoggetti = elenco.lista
        totalSize = elenco.totale
        if (totalSize <= pageSize) activePage = 0
        paging.setTotalSize(totalSize)
        //Sistemazione della descrizione dello stato in caso di valori nulli
        listaSoggetti.each {
            if (it.stato && it.stato.descrizione == null) {
                int indice = it.stato?.id
                it.stato.descrizione = listaAnadev.find { l -> l.id == (indice as Long) }?.descrizione
            }
        }
        BindUtils.postNotifyChange(null, null, this, "listaSoggetti")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    private apriMascheraRicerca() {
        Window w = Executions.createComponents("/archivio/listaSoggettiRicerca.zul", self, [filtri: filtri, ricercaSoggCont: true])
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    filtri = event.data.filtri
                    caricaLista()
                    if (listaSoggetti.size() == 1) {
                        soggettoSelezionato = listaSoggetti[0]
                        BindUtils.postNotifyChange(null, null, this, "soggettoSelezionato")
                        onModifica()
                    }
                }
            }
            BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
            BindUtils.postNotifyChange(null, null, this, "filtri")
        }
        w.doModal()
    }

    boolean isFiltroAttivo() {
        return (filtri.codFiscale != "" ||
                filtri.indirizzo != "" || filtri.id != null || filtri.fonte != -1) ||
                (filtri.pressoCognome != "") ||
                (filtri.pressoNome != "") ||
                (filtri.pressoCodFiscale != "") ||
                (filtri.pressoIndirizzo != "") ||
                (filtri.pressoComune != null) ||
                (filtri.pressoNi != null) ||
                (filtri.pressoFonte != null) ||
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
                (filtri.erediFonte != null) ||
                (filtri.erediNote != "") ||
                ((filtri.recapTipiTributo ?: []).size() > 0) ||
                ((filtri.recapTipiRecapito ?: []).size() > 0) ||
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
                (filtri.delegTipiTributo.size() > 0) ||
                (filtri.delegIBAN != "") ||
                (filtri.delegDescr != "") ||
                (filtri.delegCodFisInt != "") ||
                (filtri.delegCognNomeInt != "") ||
                (filtri.delegCessata != null) ||
                (filtri.delegRitiroDal != null) ||
                (filtri.delegRitiroAl != null) ||
                (filtri.delegRataUnica != null) ||
                (filtri.delegNote != "")
    }

    @Command
    onSituazioneContribuente() {
        //Window w = Executions.createComponents("/sportello/contribuenti/situazioneContribuente.zul", self, [idSoggetto: soggettoSelezionato.id])
        //w.doModal()
        def ni = soggettoSelezionato.id
        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    @Command
    onVariazioniAnagraficheResidenze() {
        commonService.creaPopup("/archivio/variazioniAnaRes.zul", self, [:])
    }

    @Command
    onCalcoloFamiliari(@BindingParam("soggetto") @Default("false") boolean soggetto) {
        String titolo = (soggetto) ? "Calcolo del Numero Familiari del Soggetto: " + soggettoSelezionato.cognome + " " + soggettoSelezionato.nome : "Calcolo del Numero Familiari per tutti i Soggetti"
        String contribuenteDescr = (soggetto && soggettoSelezionato.contribuente) ? ("Contribuente:    " + soggettoSelezionato.cognome + " " + soggettoSelezionato.nome + " - " + soggettoSelezionato.codFiscale) : ""
        Window w = Executions.createComponents("/archivio/calcoloFamiliari.zul", self, [idSoggetto: (soggetto) ? soggettoSelezionato?.id : -1, titolo: titolo, contribuenteDescr: contribuenteDescr])
        w.doModal()
    }

    @Command
    onDuplicaFamiliari() {
        Window w = Executions.createComponents("/archivio/duplicaNumeroFamiliari.zul", self, [soggetto: soggettoSelezionato])
        w.doModal()
    }

    @Command
    onCodiciFiscaliIncoerenti() {
        Window w = Executions.createComponents("/archivio/codiciFiscaliIncoerenti.zul", self, [soggetto: null])
        w.doModal()
    }

    @Command
    onFamiglieNonContribuenti() {
        Window w = Executions.createComponents("/archivio/famiglieNonContribuenti.zul", self, [soggetto: null])
        w.doModal()
    }

    @Command
    onCodiciFiscaliDoppi() {
        Window w = Executions.createComponents("/archivio/codiciFiscaliDoppi.zul", self, [soggetto: null, integrazioneGSD: integrazioneGSD])
        w.doModal()
    }

    @Command
    def onComponentiDellaFamiglia() {
        commonService.creaPopup(
                "/sportello/contribuenti/componentiDellaFamiglia.zul", self,
                [sogg: soggettoSelezionato, modificaCognomeNomeCodFiscale: true]
        )
    }

    @Command
    def onEventiResidenzeStoriche() {

        Window w = Executions.createComponents("/sportello/contribuenti/eventiResidenzeStoriche.zul", self, [sogg: soggettoSelezionato])
        w.doModal()
    }

    @Command
    onSostituzioneContribuente() {

        Long idOriginale = soggettoSelezionato.id
        String cfOriginale = soggettoSelezionato.contribuente.codFiscale

        def filtri = [
                contribuente     : "-",
                cognomeNome      : "",
                cognome          : "",
                nome             : "",
                indirizzo        : "",
                codFiscale       : "",
                id               : null,
                codFiscaleEscluso: null,
                idEscluso        : idOriginale
        ]

        Window w = Executions.createComponents("/sportello/contribuenti/listaContribuentiRicerca.zul", self,
                                                [
                                                    filtri: filtri,
                                                    listaVisibile: true,
                                                    ricercaSoggCont: true
                                                ]
        )
        w.onClose { event ->
            if (event.data) {
                if (event.data.status == "Sogggetto") {
                    Long idDestinazione = event.data.idSoggetto
                    String cfDestinazione = event.data.cfSoggetto
                    sostituisciContribuenteCheck(idOriginale, cfOriginale, idDestinazione, cfDestinazione)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onSoggettiToXls() {

        DecimalFormat valuta = new DecimalFormat("€ #,##0.00")

        def filtriNow = filtri.clone()
        filtriNow.campiExtra = true

        Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR)
        def elencoTipiTributo = soggettiService.getListaTributi(annoCorrente)

        Integer xlsRigheMax = Integer.MAX_VALUE

        def elenco = soggettiService.listaSoggettiSQL(filtriNow, xlsRigheMax, 0)
        def lista = elenco.lista
        def righeTotali = elenco.totale

        String nomiTributi = 'Tutti'

        def intestazione = [
                "Tipi Tributo": nomiTributi
        ]

        def fields = [:]

        if (integrazioneGSD) {
            fields << ['gsd': 'GSD']
        }
        fields << ['residente': 'Res.']
        fields << ['contribuente': 'Contr.']
        fields << ['id': 'N.Ind.']
        fields << ['cognomeNome': 'Cognome e Nome']
        fields << ['codFiscale': 'Cod.Fiscale']
        fields << ['dataNas': 'Data Nascita']
        fields << ['partitaIva': 'Partita IVA']
        fields << ['indirizzo': 'Indirizzo']
        fields << ['comuneResidenza': 'Comune']
        fields << ['statoEvento': 'Evento']
        fields << ['dataUltEve': 'Data Evento']
        fields << ['comuneEvento': 'Comune Evento']

        if (lista.size() > 0) {

            def record = lista[0]

            def keys = record.keySet()

            if (keys.find { it == 'pressoFonte' }) {
                fields << ['pressoFonte': 'Fonte Presso']
                fields << ['pressoCognNome': 'Cognome e Nome Presso']
                fields << ['pressoCodFis': 'Cod.Fis. Presso']
                fields << ['pressoIndirizzo': 'Indirizzo Presso']
                fields << ['pressoComune': 'Comune Presso']
                fields << ['pressoNote': 'Note Presso']
            }

            if (keys.find { it == 'rappCognNome' }) {
                fields << ['rappCognNome': 'Cognome e Nome Rapp.']
                fields << ['rappCodFis': 'Cod.Fis. Rapp.']
                fields << ['rappTipoCarica': 'Tipo Carica']
                fields << ['rappIndirizzo': 'Indirizzo Rapp.']
                fields << ['rappComune': 'Comune Rapp.']
            }

            if (keys.find { it == 'eredFonte' }) {
                fields << ['eredFonte': 'Fonte Erede']
                fields << ['eredCognNome': 'Cognome e Nome Erede']
                fields << ['eredCodFis': 'Cod.Fis. Erede']
                fields << ['eredIndirizzo': 'Indirizzo Erede']
                fields << ['eredComune': 'Comune Erede']
                fields << ['eredNote': 'Note Erede']
            }

            if (keys.find { it == 'recaTipoTributo' }) {
                fields << ['recaTipoTributo': 'Tipo Tributo Recap.']
                fields << ['recaTipoRecapito': 'Tipo Recapito']
                fields << ['recaDescrizione': 'Descrizione Recap.']
                fields << ['recaIndirizzo': 'Indirizzo Recap.']
                fields << ['recaComune': 'Comune Recap.']
                fields << ['recaPresso': 'Presso']
                fields << ['recaNote': 'Note Recapito']
                fields << ['recaDal': 'Recapito Dal']
                fields << ['recaAl': 'Recapito Al']
            }

            if (keys.find { it == 'familAnno' }) {
                fields << ['familAnno': 'Anno']
                fields << ['familDal': 'Dal']
                fields << ['familAl': 'Al']
                fields << ['familNumero': 'Numero Familiari']
                fields << ['familNote': 'Note Familiari']
            }

            if (keys.find { it == 'delegTipoTributo' }) {
                fields << ['delegTipoTributo': 'Tipo Tributo Delega']
                fields << ['delegIBAN': 'IBAN Delega']
                fields << ['delegDescr': 'Descrizione Delega']
                fields << ['delegCodFisInt': 'Cod.Fis. Int. Delega']
                fields << ['delegCognNomeInt': 'Cogn. e Nome Int. Delega']
                fields << ['delegCessata': 'Delega Cessata']
                fields << ['delegDataRitiro': 'Data Ritiro Delega']
                fields << ['delegRataUnica': 'Rata Unica']
                fields << ['delegNote': 'Note Delega']
            }
        }

        def parameters = [
                "intestazione"   : intestazione,
                "title"          : "Elenco Soggetti",
                "title.font.size": "12"
        ]

        def datiDaEsportare = []
        def datoDaEsportare

        def datoPerErrore = null

        lista.each {

            datoDaEsportare = it.clone()

            datiDaEsportare << datoDaEsportare
        }

        if (datoPerErrore != null) {
            datiDaEsportare << datoPerErrore
        }

        def keys = fields.keySet()
        def tipoTributoXlat = null

        datiDaEsportare.each {

            def record = it

            if (keys.find { it == 'recaTipoTributo' }) {
                tipoTributoXlat = elencoTipiTributo.find { it.codice == record.recaTipoTributo }
                if (tipoTributoXlat != null) record.recaTipoTributo = tipoTributoXlat.nome
            }

            if (keys.find { it == 'delegTipoTributo' }) {
                tipoTributoXlat = elencoTipiTributo.find { it.codice == record.delegTipoTributo }
                if (tipoTributoXlat != null) record.delegTipoTributo = tipoTributoXlat.nome
            }
        }

        def formatters = [:]

        formatters << ["id": Converters.decimalToInteger]

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_SOGGETTI,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields, formatters)

    }

    @Command
    def onElimina() {

        String msg = "Si è scelto di eliminare il soggetto ${soggettoSelezionato.cognome} ${soggettoSelezionato.nome} (N.Ind. ${soggettoSelezionato.id}).\n" +
                "Il soggetto verrà eliminato e non sarà recuperabile.\n" +
                "Si conferma l'operazione?"


        Messagebox.show(msg, "Eliminazione Soggetto", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {
                    def messaggio = soggettiService.eliminaSoggetto(soggettoSelezionato)
                    visualizzaRisultatoEliminazione(messaggio)
                }
            }
        })
    }

    @Command
    def onAllineamentoComuni(){
        commonService.creaPopup("/archivio/allineamentoComuni.zul", self, [:])
    }

    private def visualizzaRisultatoEliminazione(def messaggio) {
        if (messaggio.length() == 0) {
            messaggio = "Eliminazione avvenuta con successo!"
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
            onRefresh()
        } else {
            Clients.showNotification("${messaggio}", Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 5000, true)
        }
    }

    @Override
    void closeAndOpenContribuente(def idSoggetto) {
    }

}
