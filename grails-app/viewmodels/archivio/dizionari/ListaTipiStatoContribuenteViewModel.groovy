package archivio.dizionari

import document.FileNameGenerator
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.TipoStatoContribuenteService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaTipiStatoContribuenteViewModel {

    Window self

    CommonService commonService
    TipoStatoContribuenteService tipoStatoContribuenteService

    def tipoStatoContribuenteSelezionato
    def listaTipiStatoContribuente

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w
        onRefresh()
    }

    @Command
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTipoStatoContribuente.zul",
                self,
                [tipoStatoContribuente: tipoStatoContribuenteSelezionato,
                 openingMode          : DettaglioTipoStatoContribuenteViewModel.OpeningMode.EDIT],
                {
                    onRefresh()
                })
    }

    @Command
    def onAggiungi() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTipoStatoContribuente.zul",
                self,
                [openingMode: DettaglioTipoStatoContribuenteViewModel.OpeningMode.CREATE],
                {
                    onRefresh()
                })
    }

    @Command
    def onElimina() {

        String msg = "Il tipo stato contribuente verrà eliminato e non sarà recuperabile.\nSi conferma l'operazione?"

        Messagebox.show(msg,
                "Eliminazione Tipo Stato Contribuente",
                Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION,
                { event ->
                    if (event.getName().equals("onOK")) {
                        tipoStatoContribuenteService.deleteTipoStatoContribuente(tipoStatoContribuenteSelezionato)
                        Clients.showNotification("Eliminazione avvenuta con successo!", Clients.NOTIFICATION_TYPE_INFO, self, "before_center", 5000, true)

                        onRefresh()
                    }
                })
    }

    @Command
    onDuplica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTipoStatoContribuente.zul",
                self,
                [tipoStatoContribuente: tipoStatoContribuenteSelezionato,
                 openingMode          : DettaglioTipoStatoContribuenteViewModel.OpeningMode.CLONE],
                {
                    onRefresh()
                })
    }

    @Command
    def onExportXls() {
        if (listaTipiStatoContribuente.isEmpty()) {
            return
        }

        Map fields = ["id"              : 'Codice',
                      "descrizione"     : 'Descrizione',
                      "descrizioneBreve": 'Descrizione Breve']

        def nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.XLSX,
                FileNameGenerator.GENERATORS_TITLES.TIPI_STATO_CONTRIBUENTE,
                [:])

        XlsxExporter.exportAndDownload(nomeFile, listaTipiStatoContribuente, fields)
    }

    @Command
    onRefresh() {
        tipoStatoContribuenteSelezionato = null
        BindUtils.postNotifyChange(null, null, this, "tipoStatoContribuenteSelezionato")

        listaTipiStatoContribuente = tipoStatoContribuenteService.listTipiStatoContribuente()
        BindUtils.postNotifyChange(null, null, this, "listaTipiStatoContribuente")
    }

}
