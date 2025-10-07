package it.finmatica.tr4.oggetti.oggettiPertinenza

import it.finmatica.tr4.oggetti.oggettiPertinenza.OggettiPertinenza
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.transform.AliasToEntityMapResultTransformer


class OggettiPertinenzaService {

    static transactional = false

    def sessionFactory
    def servletContext
    JasperService jasperService
    def ad4EnteService

    def genera() {
        List<OggettiPertinenza> listaDati = new ArrayList<OggettiPertinenza>()
        OggettiPertinenza oggetto = new OggettiPertinenza()
        oggetto.oggetti = oggetti()

        listaDati.add(oggetto)
        JasperReportDef reportDef = new JasperReportDef(name: 'oggettiPertinenza.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])
        return (oggetto.oggetti.empty) ? null : jasperService.generateReport(reportDef)
    }

    private def oggetti() {
        def sqlOggetti = """
            select oggetti_contribuente.cod_fiscale,
                   translate(sogg.cognome_nome, '/', ' ') cog_nom,
                   oggetti_pratica_a.pratica,
                   oggetti_pratica_a.anno,
                   oggetti_a.oggetto,
                   oggetti_a.tipo_oggetto,
                   oggetti_a.indirizzo_localita,
                   oggetti_a.num_civ,
                   oggetti_a.suffisso,
                   oggetti_a.sezione,
                   oggetti_a.foglio,
                   oggetti_a.numero,
                   oggetti_a.subalterno,
                   oggetti_a.zona,
                   oggetti_a.classe_catasto,
                   oggetti_a.categoria_catasto,
                   oggetti_pratica_b.pratica PRATICA_1,
                   oggetti_pratica_b.anno ANNO_1,
                   oggetti_b.oggetto OGGETTO_1,
                   oggetti_b.tipo_oggetto TIPO_OGGETTO_1,
                   oggetti_b.indirizzo_localita INDIRIZZO_LOCALITA_1,
                   oggetti_b.num_civ NUM_CIV_1,
                   oggetti_b.suffisso SUFFISSO_1,
                   oggetti_b.sezione SEZIONE_1,
                   oggetti_b.foglio FOGLIO_1,
                   oggetti_b.numero NUMERO_1,
                   oggetti_b.subalterno SUBALTERNO_1,
                   oggetti_b.zona ZONA_1,
                   oggetti_b.classe_catasto CLASSE_CATASTO_1,
                   oggetti_b.categoria_catasto CATEGORIA_CATASTO_1
              from oggetti              oggetti_a,
                   oggetti              oggetti_b,
                   oggetti_pratica      oggetti_pratica_a,
                   oggetti_pratica      oggetti_pratica_b,
                   oggetti_contribuente,
                   contribuenti         cont,
                   soggetti             sogg
             where oggetti_contribuente.cod_fiscale = cont.cod_fiscale
               and cont.ni = sogg.ni
               and (oggetti_a.oggetto = oggetti_pratica_a.oggetto)
               and (oggetti_pratica_a.oggetto_pratica =
                   oggetti_contribuente.oggetto_pratica)
               and (oggetti_pratica_a.oggetto_pratica_rif_ap =
                   oggetti_pratica_b.oggetto_pratica)
               and (oggetti_pratica_b.oggetto = oggetti_b.oggetto)
             order by oggetti_a.oggetto,
                      oggetti_pratica_a.pratica,
                      oggetti_contribuente.cod_fiscale,
                      oggetti_pratica_a.anno
        """

        def oggetti = execSql(sqlOggetti)

        return oggetti
    }

    private execSql(def query) {
        def results = sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }
        return results
    }

}
