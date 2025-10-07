package it.finmatica.tr4.catasto


import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.transform.AliasToEntityMapResultTransformer

class VisuraService {

    static transactional = false

    def sessionFactory
    def servletContext
    JasperService jasperService
    def ad4EnteService

    def generaVisura(def codFiscale) {
        List<Visura> datiVisura = new ArrayList<Visura>()
        Visura visura = new Visura()
        visura.testata = testata(codFiscale)
        visura.fabbricati = fabbricati(codFiscale)
        visura.terreni = terreni(codFiscale)

        datiVisura.add(visura)
        JasperReportDef reportDef = new JasperReportDef(name: 'visura.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiVisura
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])

        return (visura.terreni.empty && visura.fabbricati.empty) ? null : jasperService.generateReport(reportDef)
    }

    private def testata(String codFiscale) {

        def sqlTestata = """
            select sogg.nome "nome",
                   nvl(sogg.cognome, sogg.denominazione) "cognome",
                   nvl(sogg.codice_fiscale, sogg.codice_fiscale_2) "codFiscale",
                   comu.denominazione "cittaNasc",
                   to_char(to_date(sogg.data_nascita, 'DDMMYYYY'), 'DD/MM/YYYY') "dataNasc",
                   comune.nome "nomeComune",
                   comune.codice "codiceComune",
                   comune.provincia "provinciaComune"
              from cc_soggetti sogg,
                   ad4_comuni comu,
                   (select 'COMUNE DI '||comu.denominazione nome,
                        comu.sigla_cfis codice,
                        prov.denominazione provincia
                    from dati_generali dage, ad4_comuni comu, ad4_provincie prov
                    where dage.pro_cliente     = comu.provincia_stato(+)
                        and dage.com_cliente     = comu.comune(+)
                        and comu.provincia_stato = prov.provincia(+)) comune
             where sogg.luogo_nascita = comu.sigla_cfis(+)
               and sogg.cod_fiscale_ric = '${codFiscale}'
        """

        return execSql(sqlTestata)[0]
    }

    private def fabbricati(String codFiscale) {
        def sqlFabbricati = """
            select rownum "rowId", visura_immobili.*
          from (select immo.contatore "idImmobile",
                       immo.data_efficacia,
                       immo.data_fine_efficacia,
                       (select max(immo1.data_efficacia)
                          from immobili_catasto_urbano immo1
                         where immo1.contatore = immo.contatore) maxDE,
                       (select max(nvl(immo2.data_fine_efficacia,
                                       to_date('99991231', 'YYYYMMDD')))
                          from immobili_catasto_urbano immo2
                         where immo2.contatore = immo.contatore) maxDFE,
                       nvl(immo.tit_cod_caus_atto_generante, '') "causaAttoGenerante",
                       nvl(immo.tit_des_atto_generante, '') "desAttoGenerante",
                       nvl(to_char(to_date(immo.tit_data_registrazione_atti,
                                           'DDMMYYYY'),
                                   'DD/MM/YYYY'),
                           '') "dataAttoGenerante",
                       immo.sezione "sezione",
                       immo.foglio "foglio",
                       immo.numero "numero",
                       immo.subalterno "subalterno",
                       immo.zona "zona",
                       immo.categoria "categoria",
                       immo.classe "classe",
                       decode(upper(substr(immo.categoria, 1, 1)),
                              'A',
                              to_number(immo.consistenza),
                              0) "consVani",
                       decode(upper(substr(immo.categoria, 1, 1)),
                              'B',
                              to_number(immo.consistenza),
                              0) "consM3",
                       decode(upper(substr(immo.categoria, 1, 1)),
                              'C',
                              to_number(immo.consistenza),
                              0) "consM2",
                       immo.consistenza || decode(upper(substr(immo.categoria, 1, 1)),
                                                  'A',
                                                  ' vani',
                                                  'B',
                                                  ' m<sup>3</sup>',
                                                  'C',
                                                  ' m<sup>2</sup>',
                                                  '') "consistenza",
                       immo.superficie "superficie",
                       to_number(immo.rendita_euro) "rendita",
                       topo.descrizione || ' ' || immo.indirizzo ||
                       decode(immo.num_civ, null, '', ' n. ' || immo.num_civ) ||
                       decode(immo.piano, null, '', ' piano: ' || immo.piano) "indirizzo",
                       initcap(tino.descrizione) || ' del ' ||
                       to_char(immo.data_iscrizione, 'DD/MM/YYYY') "derivanteDal01",
                       'in atti dal ' || to_char(immo.data_iscrizione, 'DD/MM/YYYY') "derivanteDal02",
                       immo.tit_des_atto_generante "derivanteDal03",
                       '(n. ' || ltrim(immo.tit_numero_nota, '0') || '.' ||
                       ltrim(immo.tit_progressivo_nota, '0') || '/' ||
                       ltrim(immo.tit_anno_nota, '0') || ')' "derivanteDal04",
                       immo.note "note",
                       immo.estremi_catasto "estremiCatasto"
                  from immobili_soggetto_cc immo,
                       web_cc_toponimi      topo,
                       cc_tipi_nota         tino
                 where immo.toponimo = topo.id_toponimo(+)
                   and immo.tit_tipo_nota = tino.tipo_nota(+)
                   and tino.tipo_catasto = 'F'
                   and immo.cod_fiscale_ric = '$codFiscale'
                   and immo.data_efficacia =
                       (select max(immo1.data_efficacia)
                          from immobili_catasto_urbano immo1
                         where immo1.contatore = immo.contatore
                           and immo1.data_efficacia <=
                               nvl(immo.data_fine_validita,
                                   to_date('99991231', 'YYYYMMDD'))
                           and nvl(immo1.data_fine_efficacia,
                                   to_date('99991231', 'YYYYMMDD')) >=
                               immo.data_validita)
                 order by immo.estremi_catasto) visura_immobili 
        """

        def fabbricati = execSql(sqlFabbricati)
        fabbricati.each {
            it.soggetti = soggetti(it.idImmobile)
        }

        return fabbricati
    }

    private def terreni(String codFiscale) {
        def sqlTerreni = """
            select rownum "rowId", visura.*
               from (select distinct terr.tit_causale_atto_generante "causaAttoGenerante",
                            terr.tit_des_atto_generante "desAttoGenerante",
                            terr.tit_data_registrazione_atti "dataAttoGenerante",
                            terr.id_immobile "idImmobile",
                            terr.foglio "foglio",
                            terr.numero "numero",
                            terr.subalterno "subalterno",
                            tiqu.descrizione "desQual",
                            terr.classe "classe",
                            terr.ettari "ettari",
                            terr.are "are",
                            terr.centiare "centiare",
                            to_number(nvl(terr.ettari, '00000') ||
                                  nvl(terr.are, '00') ||
                                  nvl(terr.centiare, '00')) "superficie",
                            terr.reddito_dominicale_lire "reddDomLire",
                            to_number(terr.reddito_dominicale_euro) "reddDomEu",
                            terr.reddito_agrario_lire "reddAgrLire",
                            to_number(terr.reddito_agrario_euro) "reddAgrEu",
                            initcap(tino.descrizione) || ' del ' ||
                            to_char(terr.data_iscrizione, 'DD/MM/YYYY') "derivanteDal01",
                            'in atti dal ' ||
                            to_char(terr.data_iscrizione, 'DD/MM/YYYY') "derivanteDal02",
                            terr.ter_des_atto_generante "derivanteDal03",
                            '(n. ' || terr.numero_nota || '.' ||
                            terr.progressivo_nota || '/' || terr.anno_nota || ')' "derivanteDal04",
                            terr.annotazione "note",
                            terr.estremi_catasto "estremiCatasto"
              from immobili_catasto_terreni terr,
                   cc_titolarita               tito,
                   cc_soggetti                 sogg,
                   tipi_qualita                tiqu,
                   cc_tipi_nota                tino
             where terr.id_immobile = tito.id_immobile
               and tito.id_soggetto = sogg.id_soggetto
               and terr.qualita = tiqu.tipo_qualita(+)
               and terr.tipo_nota = tino.tipo_nota(+)
               and tino.tipo_catasto = 'T'
               and sogg.cod_fiscale_ric = '${codFiscale}'
               and terr.data_efficacia =
                   (select max(terr1.data_efficacia)
                          from immobili_catasto_terreni terr1
                         where terr1.id_immobile = terr.id_immobile
                           and terr1.data_efficacia <=
                               nvl(terr.data_fine_validita,
                                   to_date('99991231', 'YYYYMMDD'))
                           and nvl(terr1.data_fine_efficacia,
                                   to_date('99991231', 'YYYYMMDD')) >=
                               terr.data_validita)
             order by terr.estremi_catasto) visura
        """

        def terreni = execSql(sqlTerreni)
        terreni.each {
            it.soggetti = soggetti(it.idImmobile)
        }

        return terreni
    }

    private def soggetti(def idImmobile) {
        def slqSoggetti = """
            select ROWNUM "rowId", intestazione_immobili.*
              from (select replace(prop.cognome_nome, '/', ' ') "cognomeNome",
                           prop.des_com_nas "cittaNas",
                           to_char(prop.data_nas, 'MM/DD/YYYY') "dataNas",
                           decode(prop.sesso, 1, 'M', 2, 'F', '') "sesso",
                           prop.cod_fiscale "codFiscale",
                           prop.des_diritto "desDiritto",
                           prop.numeratore "numeratore",
                           prop.denominatore "denominatore",
                           decode(prop.regime,
                                  'C',
                                  'in regime di comunione dei beni',
                                  'P',
                                  'in regime di bene personale',
                                  'S',
                                  'in regime di separazione dei beni',
                                  'D',
                                  'in regime di comunione de residuo',
                                  '') "desRegime",
                           prop.tipo_soggetto "tipoSoggetto"
                      from proprietari_catasto_urbano prop
                     where prop.id_immobile = ${idImmobile}
                        and prop.data_validita =
                           (select max(prop1.data_validita)
                              from proprietari_catasto_urbano prop1
                             where prop1.id_immobile = ${idImmobile})
                       and nvl(prop.data_fine_validita, to_date('99991231', 'YYYYMMDD')) =
                           (select max(nvl(prop2.data_fine_validita,
                                           to_date('99991231', 'YYYYMMDD')))
                              from proprietari_catasto_urbano prop2
                             where prop2.id_immobile = ${idImmobile})
                                 order by 1) intestazione_immobili
        """

        return execSql(slqSoggetti)
    }

    private execSql(def query) {
        def results = sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return results
    }
}
