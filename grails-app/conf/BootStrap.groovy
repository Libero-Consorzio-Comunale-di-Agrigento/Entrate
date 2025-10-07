import com.aspose.words.FolderFontSource
import com.aspose.words.FontSettings
import com.aspose.words.FontSourceBase
import com.aspose.words.License
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.commons.modelli.ConfigurazioneModelli
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.jobs.GisJob
import it.finmatica.tr4.jobs.TrasmissioniJob
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.trasmissioni.TrasmissioniService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService

import javax.servlet.ServletContext

class BootStrap {

    def grailsApplication
    ServletContext servletContext

    def springSecurityService

    ModelliService modelliService
    ElaborazioniService elaborazioniService
    TrasmissioniService trasmissioniService

    IntegrazioneWEBGISService integrazioneWEBGISService

    def init = { servletContext ->

        OggettiCacheMap ocm = grailsApplication.mainContext.getBean('oggettiCacheMap') as OggettiCacheMap
        ocm.refresh()

        log.info "Licensa Aspose: " + servletContext.getRealPath('/WEB-INF/Aspose.Words.lic')
        License lic = new License()
        try {
            lic.setLicense(servletContext.getRealPath('/WEB-INF/Aspose.Words.lic'))
        } catch (Exception e) {
            log.error "Licensa Aspose non trovata o scaduta."
        }

        // Initializzazione font
        FontSourceBase[] originalFontSources = FontSettings.getDefaultInstance().getFontsSources()
        FolderFontSource folderFontSource =
                new FolderFontSource(new File(servletContext.getRealPath('/fonts/'))
                        .parentFile.absolutePath, true)

        FontSourceBase[] updatedFontSources = [originalFontSources[0], folderFontSource]
        FontSettings.getDefaultInstance().setFontsSources(updatedFontSources)


        // Installazione modelli di stampa
        (new ConfigurazioneModelli(servletContext, modelliService)).installaModelli()

        // All'avvio della webapp in Tomcat, se sono presenti elaborazioni massive in corso si marcano come concluse con errore
        // In try/catch perche' in caso di errore non deve bloccare l'avvio
        try {
            if (getClass().getProtectionDomain().getCodeSource().getLocation().getFile().contains("WEB-INF")) {
                elaborazioniService.chiudiElaborazioniPendenti()
            }
        } catch (Exception e) {
            log.error e
        }

        String gisJobCron = integrazioneWEBGISService.leggiWebGISCron()

        if (gisJobCron.length() > 0) {

            def configBatch = integrazioneWEBGISService.leggiConfigurazioneBatch()

            log.info "#####################################################################################"
            log.info " GisJob - Attivato pianificazione : [${gisJobCron}] -> ${configBatch.utente}/${configBatch.enti}"
            log.info "#####################################################################################"
            GisJob.schedule(gisJobCron, [codiceUtenteBatch: configBatch.utente, codiciEntiBatch: configBatch.enti])
        }

        // Caricamento FTP Trasmissioni
        log.info "Inizio caricamento file FTP_TRASMISSIONI"
        def ftpFolder = trasmissioniService.getParametroFtpFolder()
        def ftpCron = trasmissioniService.getParametroFtpCron()

        if (trasmissioniService.isTrasmissioniJobAttivabile()) {

            log.info "FTP_FOLDER: ${ftpFolder}"
            log.info "FTP_CRON: ${ftpCron}"

            def enti = trasmissioniService.leggiConfigurazioneBatch()
            def utente = "JOB_AUTO"

            log.info "#####################################################################################"
            log.info " TrasmissioniJob - Attivato pianificazione : [${ftpCron}] -> ${utente}/${enti}"
            log.info "#####################################################################################"

            TrasmissioniJob.schedule(ftpCron,
                    [
                            codiceUtenteBatch: utente,
                            codiciEntiBatch  : enti
                    ])

        } else {
            log.info "Errore: parametro FTP_FOLDER non esistente ($ftpFolder)"
        }
    }

    def destroy = {
    }
}
