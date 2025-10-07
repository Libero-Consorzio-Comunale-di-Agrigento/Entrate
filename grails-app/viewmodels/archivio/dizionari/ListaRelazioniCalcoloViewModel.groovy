package archivio.dizionari

import it.finmatica.tr4.RelazioneOggettoCalcolo
import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.relazioniCalcolo.RelazioniCalcoloService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaRelazioniCalcoloViewModel extends TabListaGenericaTributoViewModel {

    // Componenti
    Window self

    // Services
    RelazioniCalcoloService relazioniCalcoloService

    // Comuni
    def listaRelazioni
    def relazioneSelezionata
    def filtroAttivo
    def filtri
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("annoTributo") def an,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, an, tabIndex)
        labels = commonService.getLabelsProperties('dizionario')
    }


    @Command
    void onRefresh() {
        relazioneSelezionata = null
        listaRelazioni = relazioniCalcoloService.getListaRelazioniCalcolo(tipoTributoSelezionato.tipoTributo, selectedAnno, filtri)

        BindUtils.postNotifyChange(null, null, this, "relazioneSelezionata")
        BindUtils.postNotifyChange(null, null, this, "listaRelazioni")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return relazioniCalcoloService.noneRelazioneCalcoloForAnno(tipoTributoSelezionato.tipoTributo, selectedAnno) &&
                !relazioniCalcoloService.getListaAnniDuplicaDaAnno(tipoTributoSelezionato.tipoTributo).empty
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaRelazioniCalcoloDaAnno.zul", self,
                [anno       : selectedAnno,
                 tipoTributo: tipoTributoSelezionato.tipoTributo],
                { event ->
                    if (event.data) {
                        if (event.data.anno) {
                            Clients.showNotification("Duplicazione da anno ${event.data.anno} avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)
                            onRefresh()
                        }
                    }
                })
    }

    @Command
    def onSelectAnno() {
        onRefresh()
    }

    @Command
    def onAggiungiRelazioneCalcolo() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRelazioniCalcolo.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        anno       : selectedAnno,
                        modifica   : true
                ], { event ->
            if (event.data) {
                if (event.data?.relazione) {

                    RelazioneOggettoCalcolo relazione = event.data.relazione

                    relazioniCalcoloService.salvaRelazioneCalcolo(relazione)

                    def message = "Salvataggio avvenuto con successo"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                    onRefresh()
                }
            }
        })
    }

    @Command
    def onModificaRelazioneCalcolo() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRelazioniCalcolo.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        anno       : selectedAnno,
                        modifica   : !lettura,
                        relazione  : clonaRelazione(relazioneSelezionata, true)
                ], { event ->
            if (event.data) {
                if (event.data?.relazione) {

                    relazioniCalcoloService.salvaRelazioneCalcolo(event.data.relazione)

                    def message = "Salvataggio avvenuto con successo"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                    onRefresh()
                }
            }
        })
    }

    @Command
    def onDuplicaRelazioneCalcolo() {
        commonService.creaPopup("/archivio/dizionari/dettaglioRelazioniCalcolo.zul", self,
                [
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        anno       : selectedAnno,
                        modifica   : true,
                        relazione  : clonaRelazione(relazioneSelezionata)
                ], { event ->
            if (event.data) {
                if (event.data?.relazione) {

                    relazioniCalcoloService.salvaRelazioneCalcolo(event.data.relazione)

                    def message = "Salvataggio avvenuto con successo"
                    Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                    onRefresh()
                }
            }
        })
    }

    @Command
    def onEliminaRelazioneCalcolo() {
        Messagebox.show(
                "Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        relazioniCalcoloService.eliminaRelazioneCalcolo(relazioneSelezionata)

                        def message = "Eliminazione avvenuta con successo"
                        Clients.showNotification(message, Clients.NOTIFICATION_TYPE_INFO, self, "middle_center", 3000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    def onExportXls(@BindingParam("modalita") String modalita) {
        def mode = ExportXlsMode[modalita]

        def lista = getListaForXls(mode)

        if (lista) {

            def listaStampa = []

            // Fix per la stampa delle categorie catasto non stampabili normalmente
            lista.each {
                def relDTO = it.toDTO()
                relDTO.catCatastoString = relDTO.categoriaCatasto ? relDTO.categoriaCatasto.categoriaCatasto + " - " + relDTO.categoriaCatasto.descrizione : ""
                listaStampa << relDTO
            }

            Map fields = [
                    "anno"            : "Anno",
                    "tipoOggetto"     : "Tipo Oggetto",
                    "catCatastoString": "Categoria Catasto",
                    "tipoAliquota"    : "Tipo Aliquota"
            ]

            def formatters = [
                    "tipoOggetto" : { tOgg -> (tOgg.tipoOggetto + " - " + tOgg.descrizione) },
                    "tipoAliquota": { aliq -> (aliq.tipoAliquota + " - " + aliq.descrizione) }
            ]

            def filename = getNomeFileXls(mode)

            XlsxExporter.exportAndDownload(filename, listaStampa, fields, formatters)

        }
    }

    private def getListaForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return listaRelazioni
        }
        if (mode == ExportXlsMode.TUTTI) {
            return relazioniCalcoloService.getListaRelazioniCalcolo(tipoTributoSelezionato.tipoTributo)
        }
    }

    private def getNomeFileXls(String mode) {
        return "RelazioniCalcolo_${tipoTributoSelezionato.tipoTributoAttuale}${mode == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
    }

    @Command
    def openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaRelazioniCalcoloRicerca.zul", self,
                [
                        filtri     : filtri,
                        tipoTributo: tipoTributoSelezionato.tipoTributo,
                        anno       : selectedAnno
                ], { event ->
            if (event.data) {
                if (event.data?.filtri) {

                    this.filtri = event.data?.filtri
                    controllaFiltro()
                    onRefresh()
                }
            }
        })
    }

    private def clonaRelazione(def relazione, def copiaId = false) {

        RelazioneOggettoCalcolo newRel = new RelazioneOggettoCalcolo()

        newRel.anno = relazione.anno
        newRel.tipoAliquota = relazione.tipoAliquota
        newRel.categoriaCatasto = relazione.categoriaCatasto
        newRel.tipoOggetto = relazione.tipoOggetto

        if (copiaId) {
            newRel.id = relazione.id
        }

        return newRel
    }

    private def controllaFiltro() {

        filtroAttivo = filtri.daTipoOggetto != null || filtri.aTipoOggetto != null ||
                filtri.daCatCatasto != null || filtri.aCatCatasto != null ||
                filtri.daTipoAliquota != null || filtri.aTipoAliquota != null

        BindUtils.postNotifyChange(null, null, this, "filtroAttivo")
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

}
