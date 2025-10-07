package archivio.dizionari

import it.finmatica.tr4.coefficientiDomestici.CoefficientiDomesticiService
import it.finmatica.tr4.export.XlsxExporter
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class ListaCoefficientiDomesticiViewModel extends TabListaGenericaTributoViewModel {

    // Services
    CoefficientiDomesticiService coefficientiDomesticiService

    // Comuni
    def listaCoefficientiDomestici
    def coefficienteDomesticoSelezionato

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

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    @Override
    void onRefresh() {

        def filtriNow = [
                anno: selectedAnno,
                *   : filtro
        ]

        this.listaCoefficientiDomestici = coefficientiDomesticiService.getListaCoefficientiDomestici(filtriNow)
        this.coefficienteDomesticoSelezionato = null

        refreshCopiaAnnoEnabled()
        openCopiaAnnoIfEnabled()

        BindUtils.postNotifyChange(null, null, this, "listaCoefficientiDomestici")
        BindUtils.postNotifyChange(null, null, this, "coefficienteDomesticoSelezionato")
    }

    @Override
    def checkCondizioneAnnoEnabled() {
        return coefficientiDomesticiService.getCountCoefficientiDomesticiByAnno(selectedAnno) == 0 &&
                !coefficientiDomesticiService.getListaAnniDuplicaDaAnno().empty
    }

    @Override
    protected void openCopiaAnno() {
        commonService.creaPopup("/archivio/dizionari/copiaCoefficientiDomesticiDaAnno.zul", self,
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
        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteDomestico.zul", self,
                [
                        coefficienteDomesticoSelezionato: coefficienteDomesticoSelezionato.dto,
                        tipoOperazione                  : lettura ? DettaglioCoefficienteDomesticoViewModel.TipoOperazione.VISUALIZZAZIONE : DettaglioCoefficienteDomesticoViewModel.TipoOperazione.MODIFICA,
                        anno                            : selectedAnno
                ],
                { event ->
                    onRefresh()
                })

    }

    @Command
    def onAggiungi() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteDomestico.zul", self,
                [
                        coefficienteDomesticoSelezionato: null,
                        tipoOperazione                  : DettaglioCoefficienteDomesticoViewModel.TipoOperazione.INSERIMENTO,
                        anno                            : selectedAnno
                ],
                { event ->
                    onRefresh()
                })
    }

    @Command
    def onDuplica() {

        commonService.creaPopup("/archivio/dizionari/dettaglioCoefficienteDomestico.zul", self,
                [
                        coefficienteDomesticoSelezionato: coefficienteDomesticoSelezionato.dto,
                        tipoOperazione                  : DettaglioCoefficienteDomesticoViewModel.TipoOperazione.CLONAZIONE,
                        anno                            : selectedAnno
                ],
                { event ->
                    onRefresh()
                })
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
                        coefficientiDomesticiService.eliminaCoefficienteDomestico(coefficienteDomesticoSelezionato.dto)

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

        Map fields = ["anno"                 : "Anno",
                      "numeroFamiliari"      : "Familiari",
                      "coeffAdattamento"     : "Coeff.Adattamento - Ab.Principale",
                      "coeffAdattamentoNoAp" : "Coeff.Adattamento - Altre Utenze",
                      "coeffProduttivita"    : "Coeff.Produttività - Ab.Principale",
                      "coeffProduttivitaNoAp": "Coeff.Produttività - Altre Utenze"]

        def bigDecimalFormats = [
                coeffAdattamento     : getCoefficienteFormat(),
                coeffAdattamentoNoAp : getCoefficienteFormat(),
                coeffProduttivita    : getCoefficienteFormat(),
                coeffProduttivitaNoAp: getCoefficienteFormat()
        ]

        def nomeFile = getNomeFileXls(mode)

        XlsxExporter.exportAndDownload(nomeFile, lista, fields, [:], bigDecimalFormats)
    }

    private def getListaForXls(String mode) {
        if (mode == ExportXlsMode.PARAMETRI) {
            return listaCoefficientiDomestici
        }
        if (mode == ExportXlsMode.TUTTI) {
            return coefficientiDomesticiService.getListaCoefficientiDomestici()
        }
    }

    private def getNomeFileXls(String mode) {
        return "CoefficientiDomestici_${tipoTributoSelezionato.tipoTributoAttuale}${mode == ExportXlsMode.PARAMETRI ? "_$selectedAnno" : ''}"
    }

    def getCoefficienteFormat() {
        return '#,##0.0000'
    }

    @Command
    def onDuplicaDaAnno() {
        openCopiaAnnoIfEnabled()
    }

    @Command
    openCloseFiltri() {
        commonService.creaPopup("/archivio/dizionari/listaCoefficientiDomesticiRicerca.zul", self, [filtro: filtro], { event ->
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
