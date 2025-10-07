package archivio.dizionari


import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.RivalutazioneRenditaDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.rivalutazioniRendita.RivalutazioniRenditaService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaRivalutazioniRenditaViewModel extends TabListaGenericaTributoViewModel {

    // Servizi
    RivalutazioniRenditaService rivalutazioniRenditaService

    // Componenti
    Window self

    // Modello
    RivalutazioneRenditaDTO rivalutazioneRenditaSelezionato
    Collection<RivalutazioneRenditaDTO> listaRivalutazioniRendita
    Collection<TipoOggettoDTO> tipiOggettoList = []
    def labels

    // Ricerca
    def filtro = [:]
    def filtroAttivo = false

    @Init
    def init(@ContextParam(ContextType.COMPONENT) Window w,
             @ExecutionArgParam("tipoTributo") def tipoTributo,
             @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, null, tabIndex)

        loadTipiOggetto()

        labels = commonService.getLabelsProperties('dizionario')
    }

    /**
     * Il parametro tipiOggettoList varia a seconda del tipo tributo selezionato
     * al momento ICI/IMU e TASI, restituiscono liste differenti.
     * Per mantenere efficiente il caricamento della lista, questo avviene in fase di @init
     * tuttavia va rieseguito dopo che avviene un cambio tributo
     * @see TabListaGenericaTributoViewModel#onCambiaTipoTributo()
     */
    @Override
    def aggiornaCompetenze() {
        super.aggiornaCompetenze()
        loadTipiOggetto()
    }


    // Eventi interfaccia
    @Override
    @Command
    void onRefresh() {
        lettura = lettura || !(tipoTributoSelezionato.tipoTributo == 'ICI')
        rivalutazioneRenditaSelezionato = null

        listaRivalutazioniRendita = rivalutazioniRenditaService.getByCriteria(
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        da         : filtro?.da,
                        a          : filtro?.a,
                        tipoOggetto: filtro?.tipoOggetto,
                        daAliquota : filtro?.daAliquota,
                        aAliquota  : filtro?.aAliquota,
                ])

        BindUtils.postNotifyChange(null, null, this, "rivalutazioneRenditaSelezionato")
        BindUtils.postNotifyChange(null, null, this, "listaRivalutazioniRendita")
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRivalutazioniRendita.zul", self,
                [tipoTributo    : tipoTributoSelezionato.tipoTributo,
                 selezionato    : rivalutazioneRenditaSelezionato.clone(),
                 tipiOggettoList: tipiOggettoList,
                 isModifica     : true,
                 isClone        : false,
                 isLettura      : lettura],
                { event -> if (event.data?.rivalutazioneRendita) modifyElement(event.data?.rivalutazioneRendita) })
    }


    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRivalutazioniRendita.zul", self,
                [
                        tipoTributo    : tipoTributoSelezionato.tipoTributo,
                        selezionato    : null,
                        tipiOggettoList: tipiOggettoList,
                        isModifica     : false,
                        isClone        : false
                ], { event -> if (event.data?.rivalutazioneRendita) addElement(event.data?.rivalutazioneRendita) })
    }

    @Command
    def onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRivalutazioniRendita.zul", self,
                [
                        tipoTributo    : tipoTributoSelezionato.tipoTributo,
                        selezionato    : rivalutazioneRenditaSelezionato.clone(),
                        tipiOggettoList: tipiOggettoList,
                        isModifica     : false,
                        isClone        : true
                ], { event -> if (event.data?.rivalutazioneRendita) addElement(event.data?.rivalutazioneRendita) })
    }


    @Command
    def onElimina() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        rivalutazioniRenditaService.elimina(rivalutazioneRenditaSelezionato)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls() {

        if (listaRivalutazioniRendita) {
            def lista = listaRivalutazioniRendita.collect {
                [anno       : it.anno,
                 tipoOggetto: "${it.tipoOggetto.tipoOggetto} - ${it.tipoOggetto.descrizione}",
                 aliquota   : it.aliquota]
            }

            Map fields = [
                    "anno"       : "Anno",
                    "tipoOggetto": "Tipo Oggetto",
                    "aliquota"   : "Aliquota",
            ]

            XlsxExporter.exportAndDownload("RivalutazioniRendita_${tipoTributoSelezionato.tipoTributoAttuale}", lista, fields)
        }
    }


    @Command
    def editSelected() {
        onModifica()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaRivalutazioniRenditaRicerca.zul", self,
                [
                        filtro         : filtro,
                        tipiOggettoList: tipiOggettoList,
                ], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @Command
    onSalva() {
        onChiudi()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private loadTipiOggetto() {
        this.tipiOggettoList = OggettiCache.TIPI_OGGETTO.valore.findAll {
            this.tipoTributoSelezionato.tipoTributo in it.oggettiTributo.tipoTributo.tipoTributo
        } as Collection<TipoOggettoDTO>
    }

    private def modifyElement(RivalutazioneRenditaDTO elementFromEvent) {
        //Se è stata modificata la chiave primaria, occorre eliminare la precedente entità
        if (isPrimaryModified(rivalutazioneRenditaSelezionato, elementFromEvent)) {
            rivalutazioniRenditaService.elimina(rivalutazioneRenditaSelezionato)
        }

        addElement(elementFromEvent)
    }

    private def addElement(RivalutazioneRenditaDTO elementFromEvent) {
        rivalutazioniRenditaService.salva(elementFromEvent)

        def message = "Salvataggio avvenuto con successo"
        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

        onRefresh()
    }

    private static def isPrimaryModified(RivalutazioneRenditaDTO source, RivalutazioneRenditaDTO dest) {
        return !(
                source.anno.equals(dest.anno)
                        && source.tipoOggetto.tipoOggetto.equals(dest.tipoOggetto.tipoOggetto))
    }
}
