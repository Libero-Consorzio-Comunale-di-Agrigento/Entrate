package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.archivio.dizionari.FiltroRicercaDatiContabili
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.datiContabili.DatiContabiliService
import it.finmatica.tr4.dto.DatiContabiliDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Listcell
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaDatiContabiliViewModel {

    // Componenti
    Window self

    // Servizi
    CommonService commonService
    DatiGeneraliService datiGeneraliService
    CompetenzeService competenzeService
    DatiContabiliService datiContabiliService

    // Modello
    FiltroRicercaDatiContabili parRicerca
    List<DatiContabiliDTO> lista
    def elenco = []
    DatiContabiliDTO elementoSelezionato
    TributiSession tributiSession
    boolean filtroAttivo = false
    boolean ricercaAnnullata = false
    def tipoTributo

    Boolean flagProvincia = false

    def elencoCompetenza = []

    Boolean lettura = true
    Boolean abilitaNuovo = false

    /// Paginazione
    def pagingList = [
            activePage: 0,
            pageSize  : 25,
            totalSize : 0
    ]

    def listaTipoImposta = [[codice: null, descrizione: '']
                            , [codice: 'O', descrizione: 'Ordinario']
                            , [codice: 'V', descrizione: 'Violazioni']
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w, @ExecutionArgParam("tipoTributo") String tt) {

        this.self = w

        tipoTributo = tt

	    this.flagProvincia = datiGeneraliService.flagProvinciaAbilitato()

        parRicerca = new FiltroRicercaDatiContabili()

        def tributiUtenza = competenzeService.tipiTributoUtenza().collect { it.tipoTributo }

        elencoCompetenza = []
        tributiUtenza.each { tipoTributo ->
            def competenza = [
                    tipoTributo: tipoTributo,
                    modifica   : competenzeService.utenteAbilitatoScrittura(tipoTributo)
            ]
            elencoCompetenza << competenza
        }
        lettura = true

        abilitaNuovo = (elencoCompetenza.count { it.modifica != false } > 0)

        filtroAttivo = verificaCampiFiltranti()

        if (filtroAttivo) {
            caricaLista(true)
        } else {
            openCloseFiltri()
        }
    }

    @NotifyChange("lista")
    @Command
    onRefresh() {
        caricaLista(true)
    }

    @Command
    def onCambioPagina() {
        caricaLista(false)
    }

    @Command
    onAggiungi() {
        Window w = Executions.createComponents("/archivio/dizionari/datiContabili.zul",
                    self,
                    [
                        flagProvincia: flagProvincia,
                        dato: null,
                        modifica: false,
                        duplica: false
                    ]
        )
        w.doModal()
        w.onClose() { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
        w.doModal()
    }

    @Command
    def onSelezionato() {

        boolean modifica = selezioneModificabile()

        lettura = !modifica
        BindUtils.postNotifyChange(null, null, this, "lettura")
    }

    @Command
    def onModifica() {

        boolean modifica = selezioneModificabile()

        commonService.creaPopup("/archivio/dizionari/datiContabili.zul",
                self,
                [
                    flagProvincia: flagProvincia,
                    dato: elementoSelezionato,
                    modifica: modifica,
                    duplica: false
                ]
        ) { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
    }

    @Command
    onDuplica() {

        commonService.creaPopup("/archivio/dizionari/datiContabili.zul",
                self,
                [
                    flagProvincia: flagProvincia,
                    dato: elementoSelezionato, 
                    modifica: false, 
                    duplica: true
                ]
        ) { event ->
            if (event.data) {
                if (event.data.chiudi) {
                    caricaLista(true)
                }
            }
        }
    }

    @Command
    onElimina() {
        Messagebox.show("Il dato verra' eliminato. Proseguire?", "Eliminazione Dato",
                Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            def elemento = datiContabiliService.cancella(elementoSelezionato)
                            Clients.showNotification("Dato eliminato con successo", Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
                            caricaLista(true)
                        }
                    }
                }
        )
    }

    @Command
    getDescrizioneImposta(@BindingParam("arg") Listcell l, @BindingParam("codice") def codice) {
        l.setLabel(listaTipoImposta.find { it.codice == codice }?.descrizione)
    }

    @Command
    getDescrizionePratica(@BindingParam("arg") Listcell l, @BindingParam("codice") def codice) {
        l.label = codice ? TipoPratica.valueOf(codice)?.descrizione : ""
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaDatiContabiliRicerca.zul",
                self,
                [
                    flagProvincia: flagProvincia,
                    parRicerca: parRicerca
                ]
        ) { event ->
            if (event.data) {
                if (event.data.status == "Cerca") {
                    parRicerca = event.data.parRicerca
                    BindUtils.postNotifyChange(null, null, this, "parRicerca")
                    tributiSession.filtroRicercaDatiContabili = parRicerca
                    ricercaAnnullata = false
                    onCerca()
                }
                if (event.data.status == "Chiudi") {
                    ricercaAnnullata = true
                }
            }
            filtroAttivo = verificaCampiFiltranti()
            BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
        }
    }

    @Command
    onCerca() {
        pagingList.activePage = 0
        caricaLista(true)
        elementoSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "elementoSelezionato")
        BindUtils.postNotifyChange(null, null, this, "pagingList")
    }

    @Command
    def onExportXls() {

        String titolo = "Dati Contabili"
        def fields = []

        if (lista) {
            fields = [
                    "descrizioneTitr"      : "Tipo Tributo",
                    "anno"                 : "Anno",
                    "tipoImposta"          : "Tipo Imposta",
                    "tipoPratica"          : "Tipo Pratica",
                    "statoPratica"         : "Stato Pratica",
                    "emissioneDal"         : "Emissione Dal",
                    "emissioneAl"          : "Emissione Al",
                    "ripartizioneDal"      : "Ripartizione Dal",
                    "ripartizioneAl"       : "Ripartizione Al",
            ]
            if(this.flagProvincia) {
                fields << [
                    "desEnteComunale"      : "Ente"
                ]
            }
            fields << [
                    "tributo.id"           : "Tributo"
            ]
            if(parRicerca.filtroTipoTributo in [null,'CUNI']) {
                fields << [
                        "tipoOccupazione.id"  : "Tipo Occupazione"
                ]
            }
            fields << [
                    "descrizioneTributoF24": "Codice Tributo F24",
                    "annoAcc"              : "Anno Accertamento Contabile",
                    "numeroAcc"            : "Numero Accertamento Contabile"
            ]

            def formatters = [
                    statoPratica         : { sp -> sp ? "${sp.tipoStato} - ${sp.descrizione}" : null },
                    tipoImposta          : { codice -> codice ? listaTipoImposta.find { it.codice == codice }?.descrizione : null },
                    tipoPratica          : { codice -> codice ? TipoPratica.valueOf(codice)?.descrizione : null },
                    descrizioneTributoF24: { row -> row.codTributoF24 ? "${row.codTributoF24} - ${row.descrizioneTitr}" : null }
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.DATI_CONTABILI,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, lista, fields, formatters)
        }
    }

    private caricaLista(boolean resetPaginazione) {

        if (elenco.empty || resetPaginazione) {
            pagingList.activePage = 0

            elenco = datiContabiliService.getDatiContabili(parRicerca)
            pagingList.totalSize = elenco.size()

            BindUtils.postNotifyChange(null, null, this, "pagingList")
        }

        int fromIndex = pagingList.pageSize * pagingList.activePage
        int toIndex = Math.min((fromIndex + pagingList.pageSize), pagingList.totalSize)
        lista = elenco.subList(fromIndex, toIndex)
        elementoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "lista")
        BindUtils.postNotifyChange(null, null, this, "elementoSelezionato")
    }

    boolean verificaCampiFiltranti() {
        return parRicerca ? parRicerca.isDirty() : false
    }

    boolean selezioneModificabile() {

        def tipoTributo = elementoSelezionato.tipoTributo.tipoTributo
        def competenza = elencoCompetenza.find { it.tipoTributo == tipoTributo }
        boolean modifica = (competenza) ? competenza.modifica : true

        return modifica
    }
}
