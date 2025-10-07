package pratiche

import document.FileNameGenerator
import it.finmatica.tr4.SanzionePratica
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.RavvedimentoReportService
import it.finmatica.tr4.modelli.ModelliCommons
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.reports.F24Service
import net.sf.jmimemagic.Magic
import net.sf.jmimemagic.MagicMatch
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import javax.servlet.ServletContext

class DettaglioStampeViewModel {

    ServletContext servletContext

    // Servizi
    RavvedimentoReportService ravvedimentoReportService
    F24Service f24Service
    JasperService jasperService
    CommonService commonService
    ModelliService modelliService

    // Componenti
    Window self

    // Comuni
    def filtri

    // Dati
    def pratica
    def listaCanoni
    def oggettiImu
    def sanzioni
    def versato
    def debiti
    def crediti

    def abilitaGeneraF24
    def abilitaAvvisoAgID

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("pratica") def pt,
         @ExecutionArgParam("listaCanoni") def lc,
         @ExecutionArgParam("oggettiImu") def oi,
         @ExecutionArgParam("sanzioni") def sn,
         @ExecutionArgParam("versato") def vs,
         @ExecutionArgParam("debiti") def db,
         @ExecutionArgParam("crediti") def cr,
         @ExecutionArgParam("abilitaGeneraF24") def agf24,
         @ExecutionArgParam("abilitaAvvisoAgID") def aagid) {

        this.self = w

        this.pratica = pt
        this.listaCanoni = lc
        this.oggettiImu = oi
        this.sanzioni = sn
        this.versato = vs

        this.debiti = db
        this.crediti = cr

        this.abilitaGeneraF24 = agf24
        this.abilitaAvvisoAgID = aagid

        initFiltri()
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    onStampa() {

        AMedia aMedia

        if(filtri.cbPratica) {
            if (filtri.cbAgID) {
                aMedia = unisciPraticaAgID()
                esportaDocumento(aMedia)
            }
            else {
                if (filtri.cbF24) {
                    aMedia = unisciPraticaF24()
                    esportaDocumento(aMedia)
                }
                else {
                    aMedia = onGeneraReportRavvedimento()
                    esportaDocumento(aMedia)
                }
            }
        }
        else {
            if (filtri.cbAgID) {
                aMedia = generaAvvisoAgID()
                esportaDocumento(aMedia)
            }
            else {
                if (filtri.cbF24) {
                    onF24Violazione()
                }
            }
        }
    }

    private def esportaDocumento(AMedia aMedia) {

        if (aMedia == null) {
            Clients.showNotification("Errore nella generazione dei documenti", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        if (filtri.cbMail) {
            inviaTramiteEmail(pratica.contribuente.codFiscale, aMedia)
        } else {
            Filedownload.save(aMedia)
            onChiudi()
        }
    }

    @Command
    def checkAbilitazioneMail() {

        if(filtri.cbF24) {
            filtri.cbAgID = false
        }

        if (!filtri.cbPratica && !filtri.cbF24 && !filtri.cbAgID) {
            filtri.cbMail = false
        }

        BindUtils.postNotifyChange(null, null, this, "filtri")
    }

    private def onGeneraReportRavvedimento(def returnDoc = false) {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.RAVVEDIMENTO,
                [
                        idDocumento: pratica.id,
                        codFiscale : pratica.contribuente.codFiscale])

        def scheda = ravvedimentoReportService.generaReportRavvedimento(nomeFile, pratica.id,
                pratica.tipoTributo.tipoTributo == 'CUNI' ? listaCanoni : oggettiImu,
                sanzioni ?: caricaSanzioniPratica(), versato, debiti, crediti)

        Magic parser = new Magic()
        MagicMatch match = parser.getMagicMatch(scheda.toByteArray())


        if (returnDoc) {
            return scheda
        }

        return new AMedia(nomeFile, match.extension, match.mimeType, scheda.toByteArray())

    }

    private def onF24Violazione() {

        if (pratica.tipoTributo.tipoTributo == 'TARSU' && !f24Service.checkF24Tarsu(pratica.id)) {

            Messagebox.show("Manca l'indicazione del Codice Tributo F24 nei dizionari delle Sanzioni! Si desidera proseguire?", "Attenzione",
                    Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                    new org.zkoss.zk.ui.event.EventListener() {
                        void onEvent(Event e) {
                            if (Messagebox.ON_YES.equals(e.getName())) {
                                esportaDocumento(f24Violazione())
                            }
                        }
                    }
            )

        } else {
            esportaDocumento(f24Violazione())
        }
    }

    private def generaAvvisoAgID(def baseDoc = null, def extractDoc = false ) {

        def avviso = modelliService.generaAvvisiAgidPratica(baseDoc, pratica.id)

        if (avviso instanceof String) {
            Clients.showNotification(avviso, Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 10000, true)
            throw new Exception(avviso)
        }

        if(extractDoc) {
            return avviso
        }

        String nomeFile = "AGID_" + (pratica.id as String).padLeft(10, "0") + "_" + pratica.contribuente.codFiscale.padLeft(16, "0")

        def media = commonService.fileToAMedia(nomeFile, avviso)

        return media
    }

    private def f24Violazione(def extractDoc = false) {

        String nomeFile = FileNameGenerator.generateFileName(
                FileNameGenerator.GENERATORS_TYPE.JASPER,
                FileNameGenerator.GENERATORS_TITLES.F24,
                [
                        idDocumento: pratica.id,
                        codFiscale : pratica.contribuente.codFiscale
                ]
        )

        List f24data

        try {
            f24data = f24Service.caricaDatiF24(pratica)
        } catch (Exception e) {
            Clients.showNotification(e.cause?.detailMessage, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)

            if (e.message == 'NOC_COD_TRIBUTO') {
                return
            }

            throw e
        }

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        def f24file = jasperService.generateReport(reportDef)

        if (extractDoc) {
            return f24file
        }

        return new AMedia(nomeFile, "pdf", reportDef.fileFormat.mimeTyp, f24file.toByteArray())
    }

    private caricaSanzioniPratica() {

        if (!sanzioni) {
            if (pratica.id) {
                PraticaTributo praticaRaw = pratica.toDomain()
                sanzioni = SanzionePratica.findAllByPratica(praticaRaw).toDTO().sort { it.sanzione.codSanzione }
            } else {
                sanzioni = []
            }
        }

        return sanzioni
    }

    private inviaTramiteEmail(String codFiscale, AMedia amedia) {
        commonService.creaPopup("/messaggistica/email/email.zul", self,
                [codFiscale: codFiscale, fileAllegato: amedia, fileStampa: null])
    }

    private def unisciPraticaF24() {

        def nomeFile = "Ravvedimento_" + (pratica.id as String).padLeft(10, "0") + "_" + pratica.contribuente.codFiscale.padLeft(16, "0")

        def praticaDoc = onGeneraReportRavvedimento(true)

        def f24Doc = f24Violazione(true)
        def documento = ModelliCommons.allegaDocumentoPdf(praticaDoc.toByteArray(), f24Doc.toByteArray(), true)

        Magic parser = new Magic()
        MagicMatch match = parser.getMagicMatch(documento)

        return new AMedia(nomeFile, match.extension, match.mimeType, documento)
    }

    private def unisciPraticaAgID() {

        def nomeFile = "Ravvedimento_" + (pratica.id as String).padLeft(10, "0") + "_" + pratica.contribuente.codFiscale.padLeft(16, "0")

        def praticaDoc = onGeneraReportRavvedimento(true)

        def documento = generaAvvisoAgID(praticaDoc.toByteArray(),true)

        Magic parser = new Magic()
        MagicMatch match = parser.getMagicMatch(documento)

        return new AMedia(nomeFile, match.extension, match.mimeType, documento)
    }

    private def initFiltri() {
        filtri = [
                cbPratica : false,
                cbF24     : false,
                cbAgID    : false,
                cbMail    : false
        ]
    }
}
