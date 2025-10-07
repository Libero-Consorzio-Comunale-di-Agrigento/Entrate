package sportello.contribuenti

import commons.SostituzioneContribuenteViewModel
import document.FileNameGenerator
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.FiltroRicercaStatiContribuente
import it.finmatica.tr4.contribuenti.StatoContribuenteService
import it.finmatica.tr4.dto.ContribuenteDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.select.annotation.Wire
import org.zkoss.zul.Paging
import org.zkoss.zul.Window

class ListaContribuentiViewModel extends SostituzioneContribuenteViewModel {

    StatoContribuenteService statoContribuenteService
    CompetenzeService competenzeService

    ContribuenteDTO contribuenteDTO

    @Wire("#paging")
    protected Paging paging

    def listaContribuenti
    Long idSoggetto

    // paginazione
    int activePage = 0
    int pageSize = 30
    int totalSize

    // dati
    def tipiTributoActive
    Map latestStatiDescriptions
    boolean stampaVisibile = true
    boolean filtroAttivo = false
    boolean presenzaContribuenti = false

    def filtriContribuente = [
            soloContribuenti         : false
            , contribuente           : "s"
            , cognomeNome            : ""
            , cognome                : ""
            , nome                   : ""
            , codFiscale             : ""
            , indirizzo              : ""
            , id                     : null,
            //
            tipiPratica              : [],
            tipiTributo              : [],
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
            //
            statoAttivi              : false,
            statoCessati             : false,
            annoStato                : null,
            //
            statoContribuenteFilter  : new FiltroRicercaStatiContribuente()
    ]

    @NotifyChange(["totalSize", "activePage"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w

        this.tipiTributoActive = [null] + competenzeService.tipiTributoUtenza()
                .findAll { it.visibileInSportello }
                .sort { it.ordine }

        apriMascheraRicerca()
    }

    @Command
    openCloseFiltri() {

        apriMascheraRicerca()
    }

    @Command
    def onModifica() {
        onModificaContribuente(null)
    }

    private def onModificaContribuente(def idSogg = null) {

        commonService.creaPopup("/sportello/contribuenti/situazioneContribuente.zul", self,
                [idSoggetto: idSogg != null ? idSogg : soggettoSelezionato.id],
                { event ->
                    if (event.data) {

                        if (event.data.aggiornaListaContribuenti) {
                            onRefresh()
                        }

                        if (event.data.aggiornaSituazioneContribuente) {
                            idSoggetto = event.data.idSoggetto
                            onModificaContribuente(idSoggetto)
                        }
                    }
                }
        )
    }

    @Command
    onSoggettiCatasto() {

        Long idSoggetto = soggettoSelezionato.id

        Window w = Executions.createComponents("/sportello/contribuenti/soggettiACatasto.zul", self, [idSoggetto: idSoggetto])
        w.doModal()
    }

    @Command
    onRefresh() {
        caricaLista()
    }


    @Command
    onVersamentiContribuente() {
        Window w = Executions.createComponents("/sportello/contribuenti/versamentiContribuente.zul", self, [idSoggetto: soggettoSelezionato.id])
        w.onClose {
            caricaLista()
        }
        w.doModal()
    }

    @Command
    onDocumentiContribuente() {
        Window w = Executions.createComponents("/sportello/contribuenti/documentiContribuente.zul", self, [idSoggetto: soggettoSelezionato.id])
        w.onClose {
            caricaLista()
        }
        w.doModal()
    }

    @Command
    def onDovutoVersato() {
        // [cognomeNome: soggettoSelezionato.cognomeNome, codFiscale: soggettoSelezionato.contribuente.codFiscale, idSoggetto: soggettoSelezionato.id]
        Window w = Executions.createComponents("/imposta/dovutoVersato.zul", self, [cognomeNome: null, codFiscale: null, idSoggetto: null])
        w.onClose {
            //caricaLista()
        }
        w.doModal()
    }

    @Command
    def onContribuentiToXls() {

        def converters = [:]
        def filtriNow = filtriContribuente.clone()
        filtriNow.campiExtra = true

        Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR)
        def elencoTipiTributo = soggettiService.getListaTributi(annoCorrente)

        def tipiTributo = filtriNow?.tipiTributo ?: []
        def tipiPratica = filtriNow?.tipiPratica ?: []

        Integer xlsRigheMax = Integer.MAX_VALUE

        def elenco = soggettiService.listaSoggettiSQL(filtriNow, xlsRigheMax, 0)
        def lista = elenco.lista
        def righeTotali = elenco.totale

        String nomiTributi = ''
        if (tipiTributo.size() > 0) {
            nomiTributi = tipiTributo.join(", ")
        } else {
            nomiTributi = 'Tutti'
        }

        def intestazione = [
                "Tipi Tributo": nomiTributi
        ]

        def fields = [
                'contribuente'   : 'Contribuente',
                'id'             : 'N.Ind.',
                'cognomeNome'    : 'Cognome e Nome',
                'codFiscaleCont' : 'Cod.Fiscale',
                'dataNas'        : 'Data Nascita',
                'partitaIva'     : 'Partita IVA',
                'indirizzo'      : 'Indirizzo',
                'comuneResidenza': 'Comune'
        ] + tipiTributoActive.findAll { it != null }.collectEntries { [("latestStati.${it.tipoTributo}".toString()): it.tipoTributoAttuale] }

        if (!lista.empty) {

            def record = lista[0]

            def keys = record.keySet()

            if (keys.find { it == 'tipoTributo' }) {
                fields << ['tipoTributo': 'Tipo Tributo']
            }
            if (keys.find { it == 'tipoPratica' }) {
                fields << ['tipoPratica': 'Tipo Pratica']
            }
            if (keys.find { it == 'pratTipoAtto' }) {
                fields << ['pratTipoAtto': 'Tipo Atto']
                fields << ['pratImpTotale': 'Importo Totale']
                fields << ['pratImpRidotto': 'Importo Ridotto']
            }
            if (keys.find { it == 'tipoContatto' }) {
                fields << ['tipoTributoContatto': 'Tipo Tributo Cont.']
                fields << ['tipoContatto': 'Tipo Contatto']
                fields << ['annoContatto': 'Anno Contatto']
                fields << ['dataContatto': 'Data Contatto']
                fields << ['tipoRichiedente': 'Tipo Richiedente']
            }
            if (keys.find { it == 'docTitolo' }) {
                fields << ['docTitolo': 'Titolo Doc.']
                fields << ['docDataInserimento': 'Doc. Inserito Il']
                fields << ['docValiditaDal': 'Doc. Valido Dal']
                fields << ['docValiditaAl': 'Doc. Valido Al']
                fields << ['docInformazioni': 'Informazioni Doc.']
                fields << ['docNote': 'Note Documento']
                fields << ['docNomeFile': 'Nome File']
            }
            if (keys.find { it == 'versTipoTributo' }) {
                fields << ['versTipoTributo': 'Tipo Tributo Vers.']
            }
            if (keys.find { it == 'versAnno' }) {
                fields << ['versTipoPratica': 'Tipo Pr. Vers.']
                fields << ['versStatoPratica': 'Stato Pr. Vers.']
                fields << ['versAnno': 'Anno Vers.']
                if (tipiTributo.find { it in ['ICP', 'TOSAP'] } == null) {
                    fields << ['versTipo': 'Tipo Vers.']
                }
                if (tipiTributo.find { it in ['ICIAP'] } == null) {
                    fields << ['versRata': 'Rata Vers.']
                    converters << ["versRata": Converters.decimalToInteger]
                }
                fields << ['versImpVersato': 'Importo Vers.']
                fields << ['versDataPag': 'Data Pag.']
                fields << ['versDataReg': 'Data Reg.']
                fields << ['versFonte': 'Fonte']
                fields << ['versProgDoc': 'Prog. Doc. Vers.']

                converters << ["versFonte": Converters.decimalToInteger]
                converters << ["versAnno": Converters.decimalToInteger]
                converters << ["versProgDoc": Converters.decimalToInteger]

                if (tipiTributo.find { it in ['ICI', 'TASI', 'ICIAP'] }) {

                    fields << ['versNumFab': 'Num. Fabbr.']

                    fields << ['versNumFabAb': 'Num. Fabbr. A.P.']
                    fields << ['versAb': 'Abitazione Pirncipale']

                    fields << ['versNumFabTe': 'Num. Terr. Agricoli']
                    fields << ['versTer': 'Terr. Agricoli']
                    if (tipiTributo.find { it in ['ICI'] }) {

                        fields << ['versTerEr': 'Terr. Agricoli Stato']
                        fields << ['versTerCm': 'Terr. Agricoli Comune']
                    }

                    fields << ['versNumFabAF': 'Num. Aree Fabbr.']
                    fields << ['versAF': 'Aree Fabbr.']
                    if (tipiTributo.find { it in ['ICI'] }) {

                        fields << ['versAfEr': 'Aree Fabbr. Stato']
                        fields << ['versAFCm': 'Aree Fabbr. Comune']
                    }

                    fields << ['versNumFabAl': 'Num. Altri Fabbr.']
                    fields << ['versFabAl': 'Altri Fabbr.']
                    if (tipiTributo.find { it in ['ICI'] }) {

                        fields << ['versFabAlEr': 'Altri Fabbr. Stato']
                        fields << ['versFabAlCm': 'Altri Fabbr. Comune']
                    }

                    fields << ['versNumFabRu': 'Num. Fabbr. Rur.']
                    fields << ['versRur': 'Fabbr. Rur.']
                    if (tipiTributo.find { it in ['ICI'] }) {

                        fields << ['versRurEr': 'Fabbr. Rur. Stato']
                        fields << ['versRurCm': 'Fabbr. Rur. Comune']
                    }

                    if (tipiTributo.find { it in ['ICI'] }) {

                        fields << ['versNumFabD': 'Num. Fabbr. D']
                        fields << ['versFabD': 'Fabbr. D']
                        fields << ['versFabDEr': 'Fabbr. D Stato']
                        fields << ['versFabDCm': 'Fabbr. D Comune']
                        fields << ['versNumFabMe': 'Num. Fabbr. Merce']
                        fields << ['versFabMe': 'Fabbr. Merce']
                    }

                    fields << ['versDet': 'Detrazioni']
                }

                if (tipiTributo.find { it in ['TARSU'] }) {

                    fields << ['versSpeSped': 'Spese di Spedizione']
                    fields << ['versSpeMora': 'Spese di Mora']
                    fields << ['versImpMagTAR': 'C.Pereq.']
                    fields << ['versImpDov': 'Importo Dovuto']
                    fields << ['versImposta': 'Imposta']
                    fields << ['versAddECA': 'Add.+Magg ECA']
                    fields << ['versAddPro': 'Add.Provinciale']
                    fields << ['versMagTAR': 'C.Pereq.']
                    fields << ['versSanz': 'Sanzioni']
                    fields << ['versInteressi': 'Interessi']
                    fields << ['versImpDovRid': 'Importo Ridotto']
                    fields << ['versImpostaRid': 'Imposta Ridotta']
                    fields << ['versSanzRid': 'Sanzioni Ridotte']
                    fields << ['versImpSpese': 'Spese']

                    fields << ['versComp': 'Comp.']
                }
            }
        }

        def datiDaEsportare = []
        def datoDaEsportare

        fetchLastStatiDescriptions()
        lista.each {
            datoDaEsportare = it.clone()
            datoDaEsportare.latestStati = latestStatiDescriptions[it.codFiscaleCont]
            datiDaEsportare << datoDaEsportare
        }

        def keys = fields.keySet()

        converters << ["id": Converters.decimalToInteger, 'contribuente' : { value -> value == 'Si' ? 'S' : 'N' }]

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.ELENCO_CONTRIBUENTI,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, datiDaEsportare as List, fields, converters)
    }

    @Command
    onAggiornaContribuente() {

        commonService.creaPopup(
                "/sportello/contribuenti/dettagliContribuente.zul",
                self,
                [soggetto: soggettoSelezionato],
                { event ->
                    if (event.data) {
                        if (event.data.status == "Salva") {
                            caricaLista()
                        }
                    }
                }
        )
    }

    private caricaLista() {

        def filtriNow = filtriContribuente.clone()

        filtriNow.soloContribuenti = filtriNow.contribuente.toUpperCase() == 'S'

        def elenco = soggettiService.listaSoggetti(filtriNow, pageSize, activePage,
                ["contribuenti", "comuneResidenza", "comuneResidenza.ad4Comune", "archivioVie"])
        listaContribuenti = elenco.lista
        totalSize = elenco.totale
        if (totalSize <= pageSize) {
            activePage = 0
        }
        paging.setTotalSize(totalSize)

        // Ricerca soli contribuenti
        if (filtriNow.contribuente == 's') {
            // E' presente almeno un contribuente
            presenzaContribuenti = listaContribuenti.any { it.contribuente }
        }

        if (!filtriNow.soloContribuenti) {
            // Gestione soggetto non contribuente o non presente
            controlloPresenzaSoggNonContribuenti()
        }

        fetchLastStatiDescriptions()

        BindUtils.postNotifyChange(null, null, this, "listaContribuenti")
        BindUtils.postNotifyChange(null, null, this, "totalSize")
        BindUtils.postNotifyChange(null, null, this, "activePage")
    }

    private void fetchLastStatiDescriptions() {
        def codFiscaleList = listaContribuenti
                .findAll { it.contribuente }
                .collect { it.contribuente.codFiscale }
        if (codFiscaleList.empty) {
            latestStatiDescriptions = [:]
            BindUtils.postNotifyChange(null, null, this, "latestStatiDescriptions")
            return
        }

        def latestStati = statoContribuenteService.findLatestStatiContribuente(codFiscaleList)
        latestStatiDescriptions = statoContribuenteService.getStatiContribuenteDescription(latestStati)
        BindUtils.postNotifyChange(null, null, this, "latestStatiDescriptions")
    }

    private apriMascheraRicerca() {

        commonService.creaPopup("/sportello/contribuenti/listaContribuentiRicerca.zul", self, [filtri: filtriContribuente],)
                { event ->
                    if (event.data) {
                        if (event.data.status == "Cerca") {
                            filtriContribuente = event.data.filtri
                            filtroAttivo = isFiltroAttivo()
                            activePage = 0
                            caricaLista()

                            if (filtriContribuente.contribuente == 's' && listaContribuenti.size() == 1) {
                                soggettoSelezionato = listaContribuenti[0]
                                onModifica()
                            }
                        }
                    }
                    BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
                    BindUtils.postNotifyChange(null, null, this, "filtriContribuente")
                    BindUtils.postNotifyChange(null, null, this, "soggettoSelezionato")
                }
    }

    boolean isFiltroAttivo() {

        return (filtriContribuente.cognomeNome != ""
                || filtriContribuente.cognome != ""
                || filtriContribuente.nome != ""
                || filtriContribuente.codFiscale != ""
                || filtriContribuente.indirizzo != ""
                || filtriContribuente.id != null
                || filtriContribuente.codContribuente != null
                || (filtriContribuente.tipiPratica ?: []).size() > 0
                || (filtriContribuente.tipiTributo ?: []).size() > 0
                || filtriContribuente.tipoContatto != null
                || filtriContribuente.annoContatto != null
                || filtriContribuente.titoloDocumento != ""
                || filtriContribuente.nomeFileDocumento != ""
                || filtriContribuente.validoDaDocumento != null
                || filtriContribuente.validoADocumento != null
                || filtriContribuente.fonteVersamento != null
                || filtriContribuente.ordinarioVersamento
                || filtriContribuente.tipoVersamento != null
                || filtriContribuente.rataVersamento != null
                || filtriContribuente.tipoPraticaVersamento != null
                || filtriContribuente.statoPraticaVersamento != null
                || filtriContribuente.ruoloVersamento != null
                || filtriContribuente.progrDocVersamento != null
                || filtriContribuente.annoDaVersamento != null
                || filtriContribuente.annoAVersamento != null
                || filtriContribuente.pagamentoDaVersamento != null
                || filtriContribuente.pagamentoAVersamento != null
                || filtriContribuente.registrazioneDaVersamento != null
                || filtriContribuente.registrazioneAVersamento != null
                || filtriContribuente.importoDaVersamento != null
                || filtriContribuente.importoAVersamento != null
                || filtriContribuente.statoAttivi
                || filtriContribuente.statoCessati
                || filtriContribuente.statoContribuenteFilter.isActive())
    }

    // Crea popup
    private def apriSceltaRecapito(def soggOrigine, def soggDestinazione) {


        commonService.creaPopup("/sportello/contribuenti/sostituzioneContribuenteRecapito.zul",
                self,
                [
                        soggOrigine     : soggOrigine,
                        soggDestinazione: soggDestinazione
                ],
                { event ->
                    if (event?.data) {
                        if (event.data?.completato == true) {
                            onRefresh()
                        }

                    }
                }
        )
    }

    private def controlloPresenzaSoggNonContribuenti() {

        // Si evita di aprire la maschera di creazione nel caso esista già un contribuente
        if (filtriContribuente.contribuente == 'e' && !presenzaContribuenti && listaContribuenti.isEmpty()) {

            if ((!"${filtriContribuente.nome ?: ''}${filtriContribuente.cognome ?: ''}${filtriContribuente.codFiscale ?: ''}".contains('%')) &&
                    (filtriContribuente.nome || filtriContribuente.cognome || filtriContribuente.codFiscale)) {
                apriMascheraCreazioneSoggetto()
            }

        }
    }

    private def apriMascheraCreazioneSoggetto() {

        def msg = "La ricerca non ha trovato nessun contribuente o soggetto.\nSi desidera creare un nuovo soggetto?"

        Messagebox.show(msg, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.name) {
                        creaSoggetto()
                    }
                }
        )
    }

    private def creaSoggetto() {

        commonService.creaPopup("/archivio/soggetto.zul",
                self,
                [
                        idSoggetto   : -1,
                        nome         : filtriContribuente.nome,
                        cognome      : filtriContribuente.cognome,
                        codiceFiscale: filtriContribuente.codFiscale
                ],
                { event ->
                    if (event?.data) {
                        caricaLista()

                        if (event.data?.Soggetto) {
                            onModificaContribuente(event.data.Soggetto.id)
                        }
                    }
                }
        )

    }

    // Crea popup
    @Deprecated
    private void creaPopup(String zul, def parametri) {

        Window w = Executions.createComponents(zul, self, parametri)
        w.doModal()
        w.onClose { caricaLista() }
    }

    @Override
    void closeAndOpenContribuente(def idSoggetto) {
    }
}
