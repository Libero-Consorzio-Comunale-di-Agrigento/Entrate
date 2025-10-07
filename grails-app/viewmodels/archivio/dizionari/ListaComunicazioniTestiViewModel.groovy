package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.comunicazionitesti.ComunicazioniTestiService
import it.finmatica.tr4.dto.comunicazioni.DettaglioComunicazioneDTO
import it.finmatica.tr4.dto.comunicazioni.testi.ComunicazioneTestiDTO
import it.finmatica.tr4.export.Converters
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.smartpnd.SmartPndService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.EventListener
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaComunicazioniTestiViewModel extends TabListaGenericaTributoViewModel {

    ComunicazioniTestiService comunicazioniTestiService
    ComunicazioniService comunicazioniService
    SmartPndService smartPndService

    Window self

    def filtroComunicazioniParametriAttivo = false
    def filtroDettagliComunicazioneAttivo = false
    def filtroComunicazioneTestiAttivo = false
    def filtroComunicazioniParametri = [
            flagFirma     : 'T',
            flagProtocollo: 'T',
            flagPec       : 'T',
            descrizione   : ''
    ]
    def filtroDettagliComunicazione = [:]
    def filtroComunicazioneTesti = [:]

    def listaComunicazioniParametri = []
    def comunicazioneParametriSelezionato
    def listaDettagliComunicazione = []
    def dettaglioComunicazioneSelezionato

    def listaComunicazioneTesti = []
    def comunicazioneTestoSelezionato

    def smartPndAbilitato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        this.smartPndAbilitato = smartPndService.smartPNDAbilitato()

        onRefreshComunicazioniParametri()
    }

    @Command
    onRefreshComunicazioniParametri() {
        listaComunicazioniParametri?.clear()
        comunicazioneParametriSelezionato = null

        listaComunicazioniParametri = comunicazioniService.getListaComunicazioneParametri([
                tipoTributo: tipoTributoSelezionato.tipoTributo,
                *          : filtroComunicazioniParametri
        ]).sort { it.descrizione }

        onRefreshDettagliComunicazione()
        onRefreshComunicazioneTesti()

        BindUtils.postNotifyChange(null, null, this, "listaComunicazioniParametri")
        BindUtils.postNotifyChange(null, null, this, "comunicazioneParametriSelezionato")

    }

    @Command
    openCloseFiltroComunicazioniParametri() {
        commonService.creaPopup("/archivio/dizionari/listaComunicazioniParametriRicerca.zul", self,
                [
                        filtro: filtroComunicazioniParametri
                ], { event ->
            if (event?.data) {
                filtroComunicazioniParametri = event.data.filtro
                filtroComunicazioniParametriAttivo = event.data.isFiltroAttivo
                onRefreshComunicazioniParametri()

                BindUtils.postNotifyChange(null, null, this, "filtroComunicazioniParametriAttivo")
            }
        })
    }

    @Command
    onSelezionaComunicazionePrametri() {
        onRefreshDettagliComunicazione()
        onRefreshComunicazioneTesti()
    }

    @Command
    onRefreshDettagliComunicazione() {
        listaDettagliComunicazione?.clear()
        dettaglioComunicazioneSelezionato = null

        caricaListaDettagliComunicazione()

        BindUtils.postNotifyChange(null, null, this, "listaDettagliComunicazione")
        BindUtils.postNotifyChange(null, null, this, "dettaglioComunicazioneSelezionato")
    }

    @Command
    onAggiungiDettaglioComunicazione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazione.zul", self,
                [
                        dettaglioComunicazione: new DettaglioComunicazioneDTO(
                                [
                                        tipoTributo      : OggettiCache.TIPI_TRIBUTO.valore.find {
                                            it.tipoTributo == comunicazioneParametriSelezionato.tipoTributo
                                        },
                                        tipoComunicazione: comunicazioneParametriSelezionato.tipoComunicazione,
                                        tipoCanale       : filtroDettagliComunicazione.tipoCanale
                                ]
                        ),
                        lettura               : lettura
                ], {
            event ->
                if (event.data?.dettaglioComunicazione) {
                    salvaDettaglioComunicazione(event.data.dettaglioComunicazione)
                }
        })
    }

    @Command
    onModificaDettaglioComunicazione() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazione.zul", self,
                [
                        dettaglioComunicazione: dettaglioComunicazioneSelezionato,
                        lettura               : lettura
                ], { event ->
            if (event.data?.dettaglioComunicazione) {
                salvaDettaglioComunicazione(event.data.dettaglioComunicazione)
            }
        })
    }

    @Command
    def onDuplicaDettaglioComunicazione() {

        def dtoClonato = commonService.clona(dettaglioComunicazioneSelezionato)
        dtoClonato.descrizione = "${dtoClonato.descrizione} (COPIA)"
        dtoClonato.sequenza = null

        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazione.zul", self,
                [
                        dettaglioComunicazione: dtoClonato,
                        lettura               : lettura
                ], { event ->
            if (event.data?.dettaglioComunicazione) {
                salvaDettaglioComunicazione(event.data.dettaglioComunicazione)
            }
        })
    }

    @Command
    def onEliminaDettaglioComunicazione() {
        String msg = "Si è scelto di eliminare l'elemento.\n" + "Una volta eliminato non sarà recuperabile.\n" + "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione componente", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {
            void onEvent(Event event) throws Exception {
                if (org.zkoss.zhtml.Messagebox.ON_OK.equals(event.getName())) {
                    comunicazioniService.eliminaDettaglioComunicazione(dettaglioComunicazioneSelezionato)
                    onRefreshDettagliComunicazione()

                    Clients.showNotification("Eliminazione avvenuta con successo", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
            }
        })
    }

    @Command
    onRefreshComunicazioneTesti() {
        listaComunicazioneTesti?.clear()
        comunicazioneTestoSelezionato = null

        if (comunicazioneParametriSelezionato) {

            def criteria = [:]
            criteria << [tipoTributo: comunicazioneParametriSelezionato.tipoTributo]
            criteria << [tipoComunicazione: comunicazioneParametriSelezionato.tipoComunicazione]

            filtroComunicazioneTesti.each {
                criteria << [(it.getKey()): it.value]
            }
            listaComunicazioneTesti = comunicazioniTestiService.getListaComunicazioneTesti(
                    criteria
            )
        }

        BindUtils.postNotifyChange(null, null, this, "listaComunicazioneTesti")
        BindUtils.postNotifyChange(null, null, this, "comunicazioneTestoSelezionato")
    }

    @Command
    onAggiungiComunicazioneTesto() {
        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazioniTesto.zul", self,
                [
                        comunicazioneTesto: new ComunicazioneTestiDTO(
                                [
                                        tipoTributo      : OggettiCache.TIPI_TRIBUTO.valore.find {
                                            it.tipoTributo == comunicazioneParametriSelezionato.tipoTributo
                                        }?.tipoTributo,
                                        tipoComunicazione: comunicazioneParametriSelezionato.tipoComunicazione,
                                        tipoCanale       : filtroComunicazioneTesti.tipoCanale

                                ]
                        ),
                        lettura           : lettura
                ], { event ->
            if (event.data?.testo) {
                salva(event.data.testo)
            }
        })
    }

    @Command
    onModificaComunicazioneTesto() {

        ComunicazioneTestiDTO comunicazioneTesto = comunicazioneTestoSelezionato
        // Refresh lista allegati testo
        comunicazioneTesto.allegatiTesto = comunicazioniTestiService.getListaAllegatiTesto(comunicazioneTesto)

        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazioniTesto.zul", self,
                [
                        comunicazioneTesto: commonService.clona(comunicazioneTestoSelezionato),
                        lettura           : lettura
                ], { event ->
            if (event.data?.testo) {
                modificaComunicazioneTesto(event.data.testo)
                onRefreshComunicazioneTesti()
            }
        })
    }

    @Command
    def onEliminaComunicazioneTesto() {
        String msg = "Si è scelto di eliminare l'elemento.\n" + "Una volta eliminato non sarà recuperabile.\n" + "Si conferma l'operazione?"

        Messagebox.show(msg, "Eliminazione componente", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new EventListener() {
            void onEvent(Event event) throws Exception {
                if (Messagebox.ON_OK.equals(event.getName())) {
                    comunicazioniTestiService.elimina(comunicazioneTestoSelezionato)
                    onRefreshComunicazioneTesti()

                    Clients.showNotification("Eliminazione avvenuta con successo", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                }
            }
        })
    }

    @Command
    def onDuplicaComunicazioneTesto() {

        def clone = commonService.clona(comunicazioneTestoSelezionato)

        clone.allegatiTesto.each {
            it.id = null
        }

        clone.descrizione = "${clone.descrizione} (COPIA)"
        clone.id = null
        // Refresh lista allegati testo
        clone.allegatiTesto = comunicazioniTestiService.getListaAllegatiTesto(comunicazioneTestoSelezionato)

        commonService.creaPopup("/archivio/dizionari/dettaglioComunicazioniTesto.zul", self,
                [
                        comunicazioneTesto: clone,
                        lettura           : lettura
                ], { event ->
            if (event.data?.testo) {
                salva(event.data.testo)
                onRefreshComunicazioneTesti()
            }
        })
    }

    @Command
    onExportXlsComunicazioniParametri() {
        Map fields = [:]
        def converters = [:]

        if (listaComunicazioniParametri) {
            fields = [
                    "descrizione": "Descrizione"
            ]

            if (!smartPndAbilitato) {
                fields << [
                        flagFirma     : "Firma",
                        flagProtocollo: "Protocollo",
                        flagPec       : "PEC"
                ]

                converters = [
                        "flagFirma"     : Converters.flagNullToString,
                        "flagProtocollo": Converters.flagNullToString,
                        "flagPec"       : Converters.flagNullToString
                ]
            }

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.COMUNICAZIONI,
                    [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

            XlsxExporter.exportAndDownload(
                    nomeFile,
                    listaComunicazioniParametri,
                    fields,
                    converters)

        }
    }

    @Command
    onExportXlsDettagliComunicazione() {
        Map fields

        if (listaDettagliComunicazione) {

            fields = !smartPndAbilitato ? [
                    "descrizione"           : "Descrizione",
                    "tipoCanale.descrizione": "Tipo Canale",
                    "tag"                   : "Tag",
            ] : [
                    "descrizione"                                : "Descrizione",
                    "tipoCanale.descrizione"                     : "Tipo Canale",
                    "tipoComunicazionePndObj.tipoComunicazione"  : "Tipo Comunicazione SmartPND",
                    "tipoComunicazionePndObj.tagAppio"           : "Tag AppIO",
                    "tipoComunicazionePndObj.tagMail"            : "Tag PEC",
                    "tipoComunicazionePndObj.tagPnd"             : "Tag PND",
                    "tipoComunicazionePndObj.daFirmareDescr"     : "Firma",
                    "tipoComunicazionePndObj.daProtocollareDescr": "Protocollo",
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.COMUNICAZIONI_DETTAGLI,
                    [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

            def converters = [:]
            XlsxExporter.exportAndDownload(
                    nomeFile,
                    listaDettagliComunicazione,
                    fields,
                    converters)
        }

    }

    @Command
    onExportXlsTesti() {
        Map fields
        if (listaComunicazioneTesti) {
            fields = [
                    "descrizione"           : "Descrizione",
                    "tipoCanale.descrizione": "Tipo Canale",
                    "oggetto"               : "Oggetto",
                    "testo"                 : "Testo",
                    "presenzaAllegati"      : "Allegati",
                    "note"                  : "Note"
            ]

            def converters = [presenzaAllegati: Converters.flagBooleanToString]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.COMUNICAZIONI_TESTI,
                    [tipoTributo: tipoTributoSelezionato.tipoTributoAttuale])

            XlsxExporter.exportAndDownload(nomeFile,
                    listaComunicazioneTesti, fields, converters)
        }
    }

    @Command
    openCloseFiltroDettagliComunicazione() {
        commonService.creaPopup("/archivio/dizionari/listaDettagliComunicazioneRicerca.zul", self,
                [
                        filtro: filtroDettagliComunicazione
                ], { event ->
            if (event?.data) {
                filtroDettagliComunicazione = event.data.filtro
                filtroDettagliComunicazioneAttivo = event.data.isFiltroAttivo

                onRefreshDettagliComunicazione()

                BindUtils.postNotifyChange(null, null, this, "filtroDettagliComunicazione")
                BindUtils.postNotifyChange(null, null, this, "filtroDettagliComunicazioneAttivo")
            }
        })
    }

    @Command
    openCloseFiltroTesti() {
        commonService.creaPopup("/archivio/dizionari/listaTestiRicerca.zul", self,
                [
                        filtroPerComunicazione: filtroComunicazioneTesti
                ], {
            event ->
                if (event?.data) {
                    filtroComunicazioneTesti = event.data.filtro
                    filtroComunicazioneTestiAttivo = event.data.isFiltroAttivo

                    onRefreshComunicazioneTesti()

                    BindUtils.postNotifyChange(null, null, this, "filtroComunicazioneTesti")
                    BindUtils.postNotifyChange(null, null, this, "filtroComunicazioneTestiAttivo")
                }
        })
    }

    @Override
    void onRefresh() {
        onRefreshComunicazioniParametri()
    }

    private void caricaListaDettagliComunicazione() {

        if (!comunicazioneParametriSelezionato) {
            return
        }

        listaDettagliComunicazione = comunicazioniService.getListaDettagliComunicazioneInfo([
                tipoTributo      : tipoTributoSelezionato.tipoTributo,
                tipoComunicazione: comunicazioneParametriSelezionato.tipoComunicazione,
                *                : filtroDettagliComunicazione
        ])
    }

    private def modificaComunicazioneTesto(def elementFromEvent) {
        comunicazioneTestoSelezionato.descrizione = elementFromEvent.descrizione
        comunicazioneTestoSelezionato.oggetto = elementFromEvent.oggetto
        comunicazioneTestoSelezionato.testo = elementFromEvent.testo
        comunicazioneTestoSelezionato.note = elementFromEvent.note
        salva(comunicazioneTestoSelezionato)
    }

    private def salva(def comunicazioneTesto) {
        comunicazioniTestiService.salvaComunicazioneTesto(comunicazioneTesto)
        onRefreshComunicazioneTesti()

        Clients.showNotification("Testo salvato", Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
    }

    private def salvaDettaglioComunicazione(def dettaglioComunicazione) {
        comunicazioniService.salvaDettaglioComunicazione(dettaglioComunicazione)
        onRefreshDettagliComunicazione()

        Clients.showNotification("Dettaglio Comunicazione salvato", Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)
    }
}
