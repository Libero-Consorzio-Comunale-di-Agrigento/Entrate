package sportello.contribuenti

import document.FileNameGenerator
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.calcoloindividuale.CalcoloIndividualeBean
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.CalcoloService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.OggettoImpostaDTO
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.reports.F24Service
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class CalcoloIndividualeStampeViewModel {

    // services
    ContribuentiService contribuentiService
    CalcoloService calcoloService
    F24Service f24Service
    JasperService jasperService
    ServletContext servletContext
    Ad4EnteService ad4EnteService
    ModelliService modelliService
    CommonService commonService

    // componenti
    Window self

    // dati
    Short anno
    List<OggettoImpostaDTO> listaOggetti
    BigDecimal valoreTerreniRidotti
    String codFiscale
    String rbTributi
    boolean salvaPerStampaF24 = false
    def listaImposte
    boolean disabilitaF24Unico = true
    def abilitaInvioMail = false
    def stampaParametri = [riepilogo: false, acconto: false, saldo: false, unico: false, imuTasi: false, invioMail: false]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w
         , @ExecutionArgParam("listaImposte") def listaImposte
         , @ExecutionArgParam("disabilitaF24Unico") boolean disabilitaF24Unico
         , @ExecutionArgParam("anno") def anno
         , @ExecutionArgParam("codFiscale") def codFiscale
         , @ExecutionArgParam("listaOggetti") def listaOggetti
         , @ExecutionArgParam("valoreTerreniRidotti") def valoreTerreniRidotti
         , @ExecutionArgParam("rbTributi") def rbTributi
         , @ExecutionArgParam("salvaPerStampaF24") def salvaPerStampaF24) {

        this.self = w
        this.listaImposte = listaImposte
        this.disabilitaF24Unico = disabilitaF24Unico
        this.anno = anno
        this.codFiscale = codFiscale
        this.listaOggetti = listaOggetti
        this.valoreTerreniRidotti = valoreTerreniRidotti
        this.rbTributi = rbTributi
        this.salvaPerStampaF24 = salvaPerStampaF24
    }

    @Command
    onChiudiPopup() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onStampa() {

        if (salvaPerStampaF24) {
            Clients.showNotification("Salvare il calcolo prima di procedere con la stampa.", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
        } else {
            List<byte[]> documents = []

            if (stampaParametri.riepilogo) {
                documents.add(ModelliCommons.finalizzaPagineDocumento(stampaRiepilogo()))
            }

            if (stampaParametri.unico) {
                documents.add(ModelliCommons.finalizzaPagineDocumento(generaF24(2, (stampaParametri.imuTasi) ? "UNICO" : rbTributi)))
            } else {
                if (stampaParametri.acconto) {
                    documents.add(ModelliCommons.finalizzaPagineDocumento(generaF24(0, (stampaParametri.imuTasi) ? "UNICO" : rbTributi)))
                }

                if (stampaParametri.saldo) {
                    documents.add(ModelliCommons.finalizzaPagineDocumento(generaF24(1, (stampaParametri.imuTasi) ? "UNICO" : rbTributi)))
                }
            }

            if (documents?.size() > 0) {
                def stampaElenco = modelliService.mergePdf(documents)
                if (stampaElenco instanceof String) {
                    Clients.showNotification(stampaElenco, Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
                } else {
                    String nomeFile = FileNameGenerator.generateFileName(
                            FileNameGenerator.GENERATORS_TYPE.JASPER,
                            FileNameGenerator.GENERATORS_TITLES.CALCOLO_INDIVIDUALE,
                            [codFiscale: codFiscale])
                    AMedia amedia = new AMedia(nomeFile, "pdf", "application/x-pdf", stampaElenco)

                    if (stampaParametri.invioMail) {
                        commonService.creaPopup("/messaggistica/email/email.zul", self,
                                [
                                        codFiscale: codFiscale, fileAllegato: amedia, parametri: [
                                        anno             : anno,
                                        tipoTributo      : rbTributi,
                                        tipoComunicazione: 'LCO'
                                ]
                                ], {
                            onChiudiPopup()
                        })
                    } else {
                        Filedownload.save(amedia)
                        onChiudiPopup()
                    }
                }
            }

        }
    }

    @Command
    def onCheckRiepilogo() {
        if (stampaParametri.riepilogo) {
            stampaParametri.imuTasi = false
        }

        onCheckInvioMail()

        BindUtils.postNotifyChange(null, null, this, "stampaParametri")
    }

    @Command
    def onCheckAccontoSaldoUnico() {
        if (!stampaParametri.acconto && !stampaParametri.saldo && !stampaParametri.unico) {
            stampaParametri.imuTasi = false
        }

        onCheckInvioMail()

        BindUtils.postNotifyChange(null, null, this, "stampaParametri")
    }

    @Command
    def onCheckImuTasi() {
        if (stampaParametri.imuTasi) {
            stampaParametri.riepilogo = false
        }

        onCheckInvioMail()

        BindUtils.postNotifyChange(null, null, this, "riepilogo")
    }

    @Command
    def onCheckInvioMail() {

        abilitaInvioMail = (stampaParametri.imuTasi) || (stampaParametri.unico) || (stampaParametri.saldo) || (stampaParametri.acconto) || (stampaParametri.riepilogo)

        if (stampaParametri.invioMail && !abilitaInvioMail) {
            stampaParametri.invioMail = false
        }

        BindUtils.postNotifyChange(null, null, this, "stampaParametri")
        BindUtils.postNotifyChange(null, null, this, "abilitaInvioMail")

    }

    private byte[] stampaRiepilogo() {
        def calcoloIndividuale = []
        CalcoloIndividualeBean calcoloIndividualeBean = new CalcoloIndividualeBean()
        calcoloIndividualeBean.anno = anno
        calcoloIndividualeBean.contribuente = contribuentiService.getDatiTestata(codFiscale)
        calcoloIndividualeBean.tipoTributo = TipoTributo.get(rbTributi).getTipoTributoAttuale(anno)
        calcoloIndividualeBean.listaOggetti = listaOggetti
        calcoloIndividualeBean.listaImposte = listaImposte

        calcoloIndividuale << calcoloIndividualeBean

        JasperReportDef reportDef = new JasperReportDef(name: 'calcoloIndividuale.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: calcoloIndividuale
                , parameters: [SUBREPORT_DIR                  : servletContext.getRealPath('/reports') + "/",
                               ENTE                           : ad4EnteService.getEnte(),
                               valoreTerreniRidotti           : valoreTerreniRidotti,
                               valoreTerreniRidottiFuoriComune: calcoloService.terreniRidottiFuoriComune(codFiscale, anno)])

        def calcolo = jasperService.generateReport(reportDef)
        return calcolo.toByteArray()
    }

    private byte[] generaF24(int tipoPagamento, String tipoTributo) {
        List f24data = f24Service.caricaDatiF24(codFiscale, tipoTributo, tipoPagamento, anno)

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)
        return f24file.toByteArray()
    }

}
