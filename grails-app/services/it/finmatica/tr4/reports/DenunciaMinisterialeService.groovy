package it.finmatica.tr4.reports

import grails.transaction.Transactional
import it.finmatica.ad4.Ad4EnteService
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.reports.modelloministeriale.*
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService

@Transactional
class DenunciaMinisterialeService {

    def servletContext
    CommonService commonService
    JasperService jasperService
    Ad4EnteService ad4EnteService


    // Restituisce in byte[] il pdf generato
    byte[] generaDenuncia(def pratica, def immobiliPerModello = 3, def contitolariPerModello = 1) {

        if (pratica == null || pratica.tipoPratica != 'D' || pratica.tipoTributo.tipoTributo != 'ICI') {
            throw new RuntimeException("Pratica incorretta, deve essere una denuncia di tipo IMU.")
        }

        List<ModelloMinisterialeVisitable> lista = []

        // IMMOBILI
        def datiImmobili = getDatiImmobili(pratica.contribuente.codFiscale, pratica.id)

        datiImmobili.each {
            lista << new ModelloMinisterialeIMUImmobile(it)
        }

        // CONTITOLARI
        def datiContitolari = getDatiContitolari(pratica.contribuente.codFiscale, pratica.id)

        datiContitolari.each {
            lista << new ModelloMinisterialeIMUContitolare(it)
        }


        // DICHIARANTE
        def datiDichiarante = getDatiFrontespizio(pratica.contribuente.codFiscale, pratica.id)
        lista << new ModelloMinisterialeIMUDichiarante(datiDichiarante)

        // CONTRIBUENTE
        Contribuente datiContribuente = Contribuente.findByCodFiscale(pratica.contribuente.codFiscale as String)
        lista << new ModelloMinisterialeIMUContribuente(datiContribuente, datiDichiarante)

        ModelloMinisterialeIMUVisitor visitor = new ModelloMinisterialeIMUVisitor()
        lista.each {
            it.accept(visitor)
        }

        def container = visitor.container

        // Imposta il numero di modelli totali
        container.finalizzaModelli()

        def dati = []
        dati << container

        JasperReportDef reportDef = new JasperReportDef(name: 'denunciaMinisteriale.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: dati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte(),
                               anno         : pratica.anno])

        def report = jasperService.generateReport(reportDef)

        return report.toByteArray()
    }

    def getDatiFrontespizio(def codFiscale, def pratica) {

        if (codFiscale == null || pratica == null) {
            return null
        }

        def dati = commonService.refCursorToCollection("stampa_denunce_imu.frontespizio('$codFiscale', $pratica)")[0]

        return dati
    }

    def getDatiImmobili(def codFiscale, def pratica) {

        if (codFiscale == null || pratica == null) {
            return null
        }

        def dati = commonService.refCursorToCollection("stampa_denunce_imu.immobili('$codFiscale', $pratica)")

        return dati
    }

    def getDatiContitolari(def codFiscale, def pratica) {

        if (codFiscale == null || pratica == null) {
            return null
        }

        def dati = commonService.refCursorToCollection("stampa_denunce_imu.contitolari('$codFiscale', $pratica)").sort {
            it["NUM_ORDINE"] as int
        }

        return dati
    }
}
