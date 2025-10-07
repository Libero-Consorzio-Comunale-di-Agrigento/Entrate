package archivio.dizionari


import grails.util.Holders
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.competenze.CompetenzeService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zul.Window

abstract class TabListaGenericaTributoViewModel {

    protected def ExportXlsMode = [
            TUTTI    : "TUTTI",
            PARAMETRI: "PARAMETRI"
    ]

    // Componenti
    Window self

    // Servizi
    CommonService commonService
    CompetenzeService competenzeService

    // Stato
    def listaTipiTributo
    def tipoTributoSelezionato
    def selectedAnno
    boolean selezioneTipoTributoVisibile
    boolean lettura = false
    boolean selected = false
    def tabIndex
    def copiaAnnoEnabled

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("annoTributo") def annoTributo,
         @ExecutionArgParam("tabIndex") def tabIndex
    ) {
        this.self = w ?: this.self

        this.competenzeService = (CompetenzeService) Holders.grailsApplication.mainContext.getBean("competenzeService")
        this.listaTipiTributo = this.competenzeService.tipiTributoUtenza()

        this.selezioneTipoTributoVisibile = !tipoTributo
        this.tipoTributoSelezionato = selezioneTipoTributoVisibile ? listaTipiTributo[0] : listaTipiTributo.find { it.tipoTributo == tipoTributo }
        this.selectedAnno = annoTributo

        this.lettura =
                competenzeService.tipoAbilitazioneUtente(tipoTributoSelezionato?.tipoTributo) != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO

        this.tabIndex = tabIndex

        // Per il dizionario sulla prima tab si caricano i dati
        if (tabIndex == 0) {
            onRefresh()
        }
    }

    @GlobalCommand
    setTipoTributoAttivo(@BindingParam("tipoTributo") def tipoTributo,
                         @BindingParam("selectedTabIndex") def selectedTabIndex) {

        // Si aggiornano i dati solo se il viewmodel è relativo al tab selezionato
        if (selectedTabIndex == tabIndex) {
            this.tipoTributoSelezionato = listaTipiTributo.find { it.tipoTributo == tipoTributo }
            onCambiaTipoTributo()

            BindUtils.postNotifyChange(null, null, this, "tipoTributoSelezionato")
        }
    }

    @Command
    onCambiaTipoTributo() {

        aggiornaCompetenze()

        onRefresh()
    }

    @Command
    def onSelectAnno() {
        onRefresh()
        BindUtils.postGlobalCommand(null, null, "setAnnoTributoAttivo", [annoTributo: selectedAnno])
    }

    def aggiornaCompetenze() {
        String tipoTributo = tipoTributoSelezionato?.tipoTributo ?: '-'
        lettura = competenzeService.tipoAbilitazioneUtente(tipoTributo) != CompetenzeService.TIPO_ABILITAZIONE.AGGIORNAMENTO
        BindUtils.postNotifyChange(null, null, this, "lettura")
    }

    def checkCondizioneAnnoEnabled() {
        return false
    }

    def openCopiaAnnoIfEnabled() {
        if (!copiaAnnoEnabled) {
            return
        }
        openCopiaAnno()
    }

    def refreshCopiaAnnoEnabled() {
        copiaAnnoEnabled = !lettura &&
                selectedAnno != null &&
                checkCondizioneAnnoEnabled()
        BindUtils.postNotifyChange(null, null, this, 'copiaAnnoEnabled')
    }

    protected void openCopiaAnno() {}

    abstract void onRefresh()


}
