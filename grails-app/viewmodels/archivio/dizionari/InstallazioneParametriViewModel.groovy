package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.codifiche.CodificheService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.InstallazioneParametroDTO
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Executions
import org.zkoss.zk.ui.event.Event
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class InstallazioneParametriViewModel {

    // componenti
    Window self

    String currentShortParam = null

    OggettiCacheMap oggettiCacheMap

    List<InstallazioneParametroDTO> installazioneParametroList
    InstallazioneParametroDTO installazioneParametroSelezionato
    List<String> shortParamsList

    // Services
    CodificheService codificheService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {

        this.self = w
        installazioneParametroList = codificheService.installazioneParametroList()
        shortParamsList = codificheService.shortParamsList()

    }

    @Command
    def onRefresh() {
        installazioneParametroList = codificheService.installazioneParametroList(currentShortParam)
        BindUtils.postNotifyChange(null, null, this, "installazioneParametroList")
    }

    @Command
    def onModificaParametro() {
        dettaglioParametro(installazioneParametroSelezionato)
    }

    @Command
    def onNuovoParametro() {
        dettaglioParametro(new InstallazioneParametroDTO())
    }

    @Command
    def onEliminaParametro() {

        String messaggio = "Eliminare il parametro ${installazioneParametroSelezionato.getParametro()}?"

        Messagebox.show(messaggio, "Attenzione",

                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) throws Exception {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            codificheService.eliminaInstallazioneParametro(installazioneParametroSelezionato)
                            oggettiCacheMap.refresh(OggettiCache.INSTALLAZIONE_PARAMETRI)
                            onRefresh()

                        }
                    }
                }
        )
    }

    @Command
    def onDuplicaParametro() {
        dettaglioParametro(new InstallazioneParametroDTO(
                [
                        descrizione: installazioneParametroSelezionato.descrizione,
                        valore     : installazioneParametroSelezionato.valore
                ]
        ))
    }

    private void dettaglioParametro(InstallazioneParametroDTO ip) {

        Window w = Executions.createComponents("/archivio/dizionari/dettaglioInstallazioneParametro.zul", self,
                [installazioneParametro: ip])

        w.doModal()
        w.onClose() { event ->
            //carico la lisa dei parametri aggiornata
            onRefresh()
        }
    }

    @Command
    def onExportXls() {

        Map fields

        if (installazioneParametroList) {

            fields = [
                    "parametro"  : "parametro",
                    "valore"     : "valore",
                    "descrizione": "descrizione"
            ]

            def nomeFile = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.XLSX,
                    FileNameGenerator.GENERATORS_TITLES.INSTALLAZIONE_PARAMETRI,
                    [:])

            XlsxExporter.exportAndDownload(nomeFile, installazioneParametroList, fields)

        }
    }
}
