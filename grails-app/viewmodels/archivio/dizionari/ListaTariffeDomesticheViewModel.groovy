package archivio.dizionari

import it.finmatica.tr4.export.XlsxExporter
import it.finmatica.tr4.tariffeDomestiche.TariffeDomesticheService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaTariffeDomesticheViewModel extends TabListaGenericaTributoViewModel {

    // Services
    TariffeDomesticheService tariffeDomesticheService

    // Comuni
    def listaTariffeDomestiche
    def tariffaDomesticaSelezionata
    def labels

    // Ricerca
    def filtro
    def filtroAttivo = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") String tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex) {

        super.init(w, tipoTributo, annoTributo, tabIndex)

        this.filtro = [:]
        labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    void onRefresh() {

        def filtriNow = [
                anno: selectedAnno,
                *   : filtro
        ]

        this.listaTariffeDomestiche = tariffeDomesticheService.getListaTariffeDomestiche(filtriNow)
        this.tariffaDomesticaSelezionata = null

        BindUtils.postNotifyChange(null, null, this, "listaTariffeDomestiche")
        BindUtils.postNotifyChange(null, null, this, "tariffaDomesticaSelezionata")

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return tariffeDomesticheService.getCountTariffeDomesticheByAnno(selectedAnno) == 0 &&
                !tariffeDomesticheService.getListaAnniDuplicaDaAnno().empty
    }

    void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaTariffeDomesticheDaAnno.zul", self,
                [anno: selectedAnno],
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
    def onModifica() {
        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaDomestica.zul", self,
                [
                    tariffaDomesticaSelezionata: tariffaDomesticaSelezionata.dto,
                    tipoOperazione             : lettura ? DettaglioTariffaDomesticaViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioTariffaDomesticaViewModel.TipoOperazione.MODIFICA,
                    anno                       : selectedAnno
                ],
                { event ->
                    onRefresh()
                })

    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaDomestica.zul", self,
                [
                    tariffaDomesticaSelezionata: null,
                    tipoOperazione             : DettaglioTariffaDomesticaViewModel.TipoOperazione.INSERIMENTO,
                    anno                       : selectedAnno
                ],
                { event ->
                    onRefresh()
                })
    }

    @Command
    def onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioTariffaDomestica.zul", self,
                [
                    tariffaDomesticaSelezionata: tariffaDomesticaSelezionata.dto,
                    tipoOperazione             : DettaglioTariffaDomesticaViewModel.TipoOperazione.CLONAZIONE,
                    anno                       : selectedAnno
                ],
                { event ->
                    onRefresh()
                })
    }

    @Command
    def onElimina() {

        Messagebox.show("Si è scelto di eliminare l'elemento.\nSi conferma l'operazione?",
                "Attenzione",
                Messagebox.YES | Messagebox.NO,
                Messagebox.EXCLAMATION,
                { e ->
                    if (Messagebox.ON_YES == e.getName()) {
                        tariffeDomesticheService.eliminaTariffaDomestica(tariffaDomesticaSelezionata.dto)

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

        Map fields = [
                "anno"                      : "Anno",
                "numeroFamiliari"           : "Familiari",
                "tariffaQuotaFissa"         : "Tariffa Quota Fissa - Ab. Principale",
                "tariffaQuotaFissaNoAp"     : "Tariffa Quota Fissa - Altre Utenze",
                "tariffaQuotaVariabile"     : "Tariffa Quota Variabile - Ab. Principale",
                "tariffaQuotaVariabileNoAp" : "Tariffa Quota Variabile - Altre Utenze",
                "svuotamentiMinimi"         : "Svuotamenti Minimi",
        ]

        def bigDecimalFormats = [
                tariffaQuotaFissa           : getTariffaFormat(),
                tariffaQuotaFissaNoAp       : getTariffaFormat(),
                tariffaQuotaVariabile       : getTariffaFormat(),
                tariffaQuotaVariabileNoAp   : getTariffaFormat()
        ]

        def nomeFile = getNomeFileXls(mode)

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, [:], bigDecimalFormats)
    }

    private def getListaForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return listaTariffeDomestiche
        }
        if (mode == ExportXlsMode.TUTTI) {
            return tariffeDomesticheService.getListaTariffeDomestiche()
        }
    }

    private def getNomeFileXls(String mode) {
        return "CoefficientiDomestici_${tipoTributoSelezionato.tipoTributoAttuale}${mode == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
    }

    def getTariffaFormat() {
        return '#,##0.00000'
    }

    @Command
    def onSelectAnno() {
        onRefresh()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaTariffeDomesticheRicerca.zul", self, [filtro: filtro], { event ->
            if (event.data) {
                this.filtro = event.data.filtro
                this.filtroAttivo = event.data.isFiltroAttivo

                BindUtils.postNotifyChange(null, null, this, "filtro")
                BindUtils.postNotifyChange(null, null, this, "filtroAttivo")

                onRefresh()
            }
        })
    }

    @GlobalCommand
    def setAnnoTributoAttivo(@BindingParam("annoTributo") def annoTributo) {

        this.selectedAnno = annoTributo

        BindUtils.postNotifyChange(null, null, this, "selectedAnno")
    }
}
