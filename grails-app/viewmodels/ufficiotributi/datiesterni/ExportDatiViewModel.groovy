package ufficiotributi.datiesterni


import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.datiesterni.ExportDatiService
import it.finmatica.tr4.jobs.ExportDatiJob
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.Command
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class ExportDatiViewModel {

    // Componenti
    Window self

    // Servizi
    ExportDatiService exportDatiService
    CommonService commonService

    def springSecurityService

    // Modello
    def listaExport = []
    def listaParametriExport = []
    def listaParametriExportInput = []
    def listaParametriExportOutput = []
    def tipoExportSelezionato
    def tempoEsecuzione = " "

    def params
    def paramsOut
    def paramsListValue

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w) {
        this.self = w

        listaExport = exportDatiService.listaTipiExport()
        tipoExportSelezionato = listaExport[0]

        initParams()

    }

    @Command
    def onChangeTipoExport() {
        initParams()
        BindUtils.postNotifyChange(null, null, this, "listaParametriExport")
    }

    @Command
    def onEsporta() {

        ExportDatiJob.triggerNow([
                customDescrizioneJob: tipoExportSelezionato.descrizione,
                codiceUtenteBatch   : springSecurityService.currentUser.id,
                codiciEntiBatch     : springSecurityService.principal.amministrazione.codice,
                tipoExport          : tipoExportSelezionato,
                paramsIn            : params,
                listaParametriExport: listaParametriExport
        ])

        Clients.showNotification("Elaborazione ${tipoExportSelezionato.descrizione} lanciata con successo",
                Clients.NOTIFICATION_TYPE_INFO,
                self,
                "before_center",
                8000,
                true)
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private initParams() {

        params = [:]
        paramsListValue = [:]

        listaParametriExport = exportDatiService.listaParametriExport(tipoExportSelezionato)
        listaParametriExportInput = listaParametriExport.findAll { it.tipoParametro == 'I' }
        listaParametriExportOutput = listaParametriExport.findAll { it.tipoParametro == 'U' }

        listaParametriExport.findAll { it.tipoParametro == 'I' }
                .sort { it.parametroExport }
                .each {
                    if (!params[(it.tipoExport)]) {
                        params[(it.tipoExport)] = [:]
                    }
                    params[(it.tipoExport)] << [(it.parametroExport): it.ultimoValore]

                    if (!(it.querySelezione ?: '').empty) {
                        if (!paramsListValue[it.tipoExport]) {
                            paramsListValue[it.tipoExport] = [:]
                        }
                        paramsListValue[(it.tipoExport)] << [(it.parametroExport): exportDatiService.listaValoriParametro(it)]
                    }
                }

        tempoEsecuzione(null)

        BindUtils.postNotifyChange(null, null, this, "params")
        BindUtils.postNotifyChange(null, null, this, "listaParametriExport")
        BindUtils.postNotifyChange(null, null, this, "listaParametriExportInput")
        BindUtils.postNotifyChange(null, null, this, "listaParametriExportOutput")
    }

    private tempoEsecuzione(def time) {
        if (time == null) {
            tempoEsecuzione = " "
        } else {
            tempoEsecuzione = "Esportazione eseguita in $time"
        }
        BindUtils.postNotifyChange(null, null, this, "tempoEsecuzione")
    }
}
