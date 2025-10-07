package it.finmatica.tr4.oggetti.oggettipervia

import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.transform.AliasToEntityMapResultTransformer


class OggettiPerViaService {

    static transactional = false

    def sessionFactory
    def servletContext
    JasperService jasperService
    def ad4EnteService

    def genera(LinkedHashMap<Object, Object> listaCampiRicerca) {
        List<OggettiPerVia> listaDati = new ArrayList<OggettiPerVia>()
        OggettiPerVia oggetto = new OggettiPerVia()
        oggetto.testata = testata(listaCampiRicerca)
        oggetto.oggetti = oggetti(listaCampiRicerca)

        listaDati.add(oggetto)
        JasperReportDef reportDef = new JasperReportDef(name: 'oggettiPerVia.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])
        return (oggetto.oggetti.empty) ? null : jasperService.generateReport(reportDef)
    }

    private def testata(LinkedHashMap<Object, Object> listaCampiRicerca) {
        def sqlTestata = """
            select '${(listaCampiRicerca.get("situazione_anno"))?'31/12/'+listaCampiRicerca.get("situazione_anno"):''}' "situazioneAnno"
              from dual
        """
        return execSql(sqlTestata)[0]
    }

    private def oggetti(LinkedHashMap<Object, Object> listaCampiRicerca) {
        def sqlOggetti = """
          SELECT DISTINCT   OGGETTI.OGGETTO "oggetto",
                   OGGETTI.TIPO_OGGETTO "tipoOggetto",
                   LPAD (OGGETTI.ZONA, 3) "zona",
                   LPAD (sezione, 3) "sezione",
                   LPAD (foglio, 5) "foglio",
                   LPAD (OGGETTI.NUMERO, 5) "numero",
                   LPAD (subalterno, 4) "subalterno",
                   LPAD (OGGETTI.PROTOCOLLO_CATASTO, 6) "protocolloCatasto",
                   LPAD (OGGETTI.ANNO_CATASTO, 4) "annoCatasto",
                   LPAD (OGGETTI.PARTITA, 8) "partita",
                   OGGETTI.CATEGORIA_CATASTO "categoriaCatasto",      
                   DECODE (OGGETTI.COD_VIA,NULL, OGGETTI.INDIRIZZO_LOCALITA,ARCHIVIO_VIE.DENOM_UFF)
                   || DECODE (OGGETTI.num_civ, NULL, '', ', ' || OGGETTI.num_civ)
                   || DECODE (OGGETTI.suffisso, NULL, '', '/' || OGGETTI.suffisso) "indirizzo",
                      DECODE (OGGETTI.COD_VIA,NULL, OGGETTI.INDIRIZZO_LOCALITA,ARCHIVIO_VIE.DENOM_ORD)
                   || DECODE (OGGETTI.num_civ,NULL, '',', ' || LPAD (OGGETTI.num_civ, 6))
                   || DECODE (OGGETTI.suffisso,NULL, '','/' || LPAD (OGGETTI.suffisso, 5)) "indirizzoOrd",
                   f_descrizione_titr (PRATICHE_TRIBUTO.TIPO_TRIBUTO,PRATICHE_TRIBUTO.ANNO) "tipoTributo",
                   UTILIZZI_OGGETTO.TIPO_UTILIZZO  "tipoUtilizzo",
                   (select tipo_utilizzo||' - '||descrizione tipoUtilizzoDescr from tipi_utilizzo where tipo_utilizzo=UTILIZZI_OGGETTO.TIPO_UTILIZZO ) "tipoUtilizzoDescr",
                   OGGETTI_PRATICA.CONSISTENZA "consistenza" ,
                   PRATICHE_TRIBUTO.TIPO_TRIBUTO "tributoFiltro"
              FROM OGGETTI,
                   ARCHIVIO_VIE,
                   PRATICHE_TRIBUTO,
                   OGGETTI_CONTRIBUENTE,
                   OGGETTI_PRATICA,
                   UTILIZZI_OGGETTO
             WHERE     (oggetti.cod_via = archivio_vie.cod_via(+))
                   AND (oggetti_pratica.oggetto = utilizzi_oggetto.oggetto(+))
                   AND (PRATICHE_TRIBUTO.PRATICA = OGGETTI_PRATICA.PRATICA)
                   AND (OGGETTI_CONTRIBUENTE.OGGETTO_PRATICA = OGGETTI_PRATICA.OGGETTO_PRATICA)
                   AND (OGGETTI.OGGETTO = OGGETTI_PRATICA.OGGETTO)
                   AND (PRATICHE_TRIBUTO.TIPO_PRATICA IN ('D', 'A'))
                   AND (DECODE (PRATICHE_TRIBUTO.TIPO_PRATICA,'A', PRATICHE_TRIBUTO.FLAG_DENUNCIA,'S') = 'S')
                   AND (NVL (PRATICHE_TRIBUTO.STATO_ACCERTAMENTO, 'D') = 'D')
        """

        //Tipo oggetto
        if(listaCampiRicerca.get("tipo_oggetto")) {
            sqlOggetti += " AND OGGETTI.TIPO_OGGETTO = " + listaCampiRicerca.get("tipo_oggetto")
        }
        //Indirizzo
        if(listaCampiRicerca.get("indirizzo")) {
            sqlOggetti += " AND OGGETTI.COD_VIA = " + listaCampiRicerca.get("indirizzo")
        }
        //Numero Civico
        if(listaCampiRicerca.get("civico_da") && listaCampiRicerca.get("civico_a")) {
            sqlOggetti += "  AND (OGGETTI.NUM_CIV BETWEEN " + listaCampiRicerca.get("civico_da") + " AND " + listaCampiRicerca.get("civico_a") + ") "
        }
        else {
            if(listaCampiRicerca.get("civico_da") && listaCampiRicerca.get("civico_a").equals("")){
                sqlOggetti += " AND OGGETTI.NUM_CIV >= " + listaCampiRicerca.get("civico_da")
            }
            else
            if(listaCampiRicerca.get("civico_a") && listaCampiRicerca.get("civico_da").equals("")){
                sqlOggetti += " AND OGGETTI.NUM_CIV <= " + listaCampiRicerca.get("civico_a")
            }
        }
        //Tipo Numero Civico Pari o dispari
        if(listaCampiRicerca.get("tipo_numero_civico").equals("P")) {
            sqlOggetti += " AND MOD (OGGETTI.NUM_CIV, 2) = 0 "
        }

        if(listaCampiRicerca.get("tipo_numero_civico").equals("D")) {
            sqlOggetti += " AND MOD (OGGETTI.NUM_CIV, 2) = 1 "
        }
        //Oggetto
        if(listaCampiRicerca.get("oggetto")) {
            sqlOggetti += " AND OGGETTI.OGGETTO = " + listaCampiRicerca.get("oggetto")
        }
        //Cessato
        if(!listaCampiRicerca.get("cessato").equals("")) {
            def anno = (listaCampiRicerca.get("situazione_anno"))?listaCampiRicerca.get("situazione_anno"):"9999"

            sqlOggetti += """  
                            AND F_OGGETTO_CESSATO (oggetti_pratica.oggetto,pratiche_tributo.tipo_tributo,
                                TO_DATE ('3112' || LPAD (TO_CHAR (${anno}), 4, '0'), 'ddmmyyyy'),
                                NVL ('${listaCampiRicerca.get("cessato")}', 'N')) = 'S'  """
        }
        //Situazione anno
        def anno = (listaCampiRicerca.get("situazione_anno"))?listaCampiRicerca.get("situazione_anno"):"9998"
        sqlOggetti += """  
                        AND F_POSSESSO(oggetti_pratica.oggetto_pratica,oggetti_contribuente.cod_fiscale,
                            to_date('3112'||lpad(to_char(${anno}),4,'0'),'ddmmyyyy'),
                            nvl('${listaCampiRicerca.get("cessato")}','N')) = 'S' """
        sqlOggetti += """  
                        AND NVL (oggetti.data_cessazione, TO_DATE ('31129999', 'ddmmyyyy')) >
                            TO_DATE ('3112' || LPAD (TO_CHAR (${anno}), 4, '0'), 'ddmmyyyy')
                      """
        //Rendita Da-a
        if(listaCampiRicerca.get("rendita_da") && listaCampiRicerca.get("rendita_a")) {
            sqlOggetti += "  AND (f_rendita(OGGETTI_PRATICA.VALORE,OGGETTI.TIPO_OGGETTO,PRATICHE_TRIBUTO.ANNO,OGGETTI.CATEGORIA_CATASTO) BETWEEN " + listaCampiRicerca.get("rendita_da") + " AND " + listaCampiRicerca.get("rendita_a") + ") "
        }
        else {
            if(listaCampiRicerca.get("rendita_da")) {
                sqlOggetti += "  AND (f_rendita(OGGETTI_PRATICA.VALORE,OGGETTI.TIPO_OGGETTO,PRATICHE_TRIBUTO.ANNO,OGGETTI.CATEGORIA_CATASTO) >= " + listaCampiRicerca.get("rendita_da") + ") "
            }
        }

        //Cons Da-a
        if(listaCampiRicerca.get("cons_da") && listaCampiRicerca.get("cons_a")) {
            sqlOggetti += "  AND (OGGETTI_PRATICA.CONSISTENZA BETWEEN " + listaCampiRicerca.get("cons_da") + " AND " + listaCampiRicerca.get("cons_a") + ") "
        }
        else {
            if(listaCampiRicerca.get("cons_da")) {
                sqlOggetti += "  AND (OGGETTI_PRATICA.CONSISTENZA >= " + listaCampiRicerca.get("cons_da") + ") "
            }
        }

        //Partita
        if(listaCampiRicerca.get("partita")) {
            sqlOggetti += """  AND OGGETTI.PARTITA = '${listaCampiRicerca.get("partita")}' 
                          """
        }
        //Zona
        if(listaCampiRicerca.get("zona")) {
            sqlOggetti += """  AND OGGETTI.ZONA = '${listaCampiRicerca.get("zona")}' 
                          """
        }
        //Sezione
        if(listaCampiRicerca.get("sezione")) {
            sqlOggetti += """  AND OGGETTI.SEZIONE = '${listaCampiRicerca.get("sezione")}' 
                          """
        }
        //Foglio
        if(listaCampiRicerca.get("foglio")) {
            sqlOggetti += """  AND OGGETTI.FOGLIO = '${listaCampiRicerca.get("foglio")}' 
                          """
        }
        //Numero
        if(listaCampiRicerca.get("numero")) {
            sqlOggetti += """  AND OGGETTI.NUMERO = '${listaCampiRicerca.get("numero")}' 
                          """
        }
        //subalterno
        if(listaCampiRicerca.get("subalterno")) {
            sqlOggetti += """  AND OGGETTI.SUBALTERNO = '${listaCampiRicerca.get("subalterno")}' 
                          """
        }
        //Anno Catasto
        if(listaCampiRicerca.get("anno_catasto")) {
            sqlOggetti += """  AND OGGETTI.ANNO_CATASTO = '${listaCampiRicerca.get("anno_catasto")}' 
                          """
        }
        //Protocollo
        if(listaCampiRicerca.get("protocollo_catasto")) {
            sqlOggetti += """  AND OGGETTI.PROTOCOLLO_CATASTO = '${listaCampiRicerca.get("protocollo_catasto")}' 
                          """
        }
        //Categoria
        if(listaCampiRicerca.get("categoria")) {
            sqlOggetti += """  AND OGGETTI.CATEGORIA_CATASTO = '${listaCampiRicerca.get("categoria")}' 
                          """
        }
        //Classe
        if(listaCampiRicerca.get("classe")) {
            sqlOggetti += """  AND OGGETTI.CLASSE_CATASTO = '${listaCampiRicerca.get("classe")}' 
                          """
        }
        //Abitazione principale
        if(listaCampiRicerca.get("abitazione_principale").equals("S")) {
            sqlOggetti += """  AND OGGETTI_CONTRIBUENTE.FLAG_AB_PRINCIPALE = '${listaCampiRicerca.get("abitazione_principale")}' 
                          """
        }
        //Esclusi
        if(listaCampiRicerca.get("esclusi").equals("S")) {
            sqlOggetti += """  AND OGGETTI_CONTRIBUENTE.FLAG_ESCLUSIONE = '${listaCampiRicerca.get("esclusi")}' 
                          """
        }
        //Ridotti
        if(listaCampiRicerca.get("ridotti").equals("S")) {
            sqlOggetti += """  AND OGGETTI_CONTRIBUENTE.FLAG_RIDUZIONE = '${listaCampiRicerca.get("ridotti")}' 
                          """
        }
        //Tipo utilizzo
        if(listaCampiRicerca.get("tipo_utilizzo")) {
            sqlOggetti += " AND UTILIZZI_OGGETTO.TIPO_UTILIZZO =" + listaCampiRicerca.get("tipo_utilizzo")
        }

        //Tipo tributo
        if(listaCampiRicerca.get("tipiTributo")) {
            def tipiTributo = listaCampiRicerca.get("tipiTributo")
            String sequenza = ""

            if (tipiTributo.ICI) {
                sequenza +="'ICI',"
            }
            if (tipiTributo.TASI) {
                sequenza +="'TASI',"
            }
            if (tipiTributo.TARSU) {
                sequenza +="'TARSU',"
            }
            if (tipiTributo.ICP) {
                sequenza +="'ICP',"
            }
            if (tipiTributo.TOSAP) {
                sequenza +="'TOSAP',"
            }

            if(sequenza.size()>0){
                sqlOggetti += "  and PRATICHE_TRIBUTO.TIPO_TRIBUTO in ("+sequenza.substring(0,sequenza.length()-1)+") "
            }
            else{ //nel caso in cui viene deselezionato tutti i tipi di tributi non produce nulla
                sqlOggetti += "  and PRATICHE_TRIBUTO.TIPO_TRIBUTO in ('') "
            }

        }

        if(listaCampiRicerca.get("ordinamento")!=null && listaCampiRicerca.get("ordinamento").equals("estremi")){
            sqlOggetti+=""" order by "zona" asc,"sezione" asc,"foglio" asc,"numero" asc,"subalterno" asc, "annoCatasto" asc, "protocolloCatasto" asc,"partita" asc,"indirizzoOrd" asc,"tipoTributo" asc """
        }
        else {
            sqlOggetti+=""" order by "indirizzoOrd" asc,"zona" asc,"sezione" asc,"foglio" asc,"numero" asc,"subalterno" asc, "annoCatasto" asc, "protocolloCatasto" asc,"partita" asc, "tipoTributo" asc """
        }

        def oggetti = execSql(sqlOggetti)

        if(listaCampiRicerca.get("stampa_proprietari").equals("S")) {
            oggetti.each {
                it.proprietari = proprietari(listaCampiRicerca,it.oggetto,it.tributoFiltro)
            }
        }

        return oggetti
    }

    private def proprietari(LinkedHashMap<Object, Object> listaCampiRicerca,def idOggetto,def tributoFiltro) {

        def anno_rif =  (listaCampiRicerca.get("situazioneAnnoRif"))?listaCampiRicerca.get("situazioneAnnoRif"):"9999"
        def slqProprietari = """
                            select distinct nvl(ogpr.tipo_oggetto, oggetti.tipo_oggetto) "tipoOggetto",
                                contribuenti.cod_fiscale "codFiscale",
                                to_char(soggetti.data_nas, 'MM/DD/YYYY') "dataNascita",
                                pratiche_tributo.pratica "pratica",
                                pratiche_tributo.anno "anno",
                                ogco.perc_possesso "possesso",
                                ogpr.valore "valore",
                                translate(soggetti.cognome_nome, '/', ' ') "proprietario",
                                decode(nvl(soggetti.cap, ad4_comuni.cap),
                                       null,
                                       '',
                                       ad4_comuni.denominazione) || ' ' ||
                                decode(ad4_provincie.sigla,
                                       null,
                                       '',
                                       ' (' || ad4_provincie.sigla || ')') "residenzaSoggetto"
                              from oggetti,
                                   oggetti_pratica      ogpr,
                                   oggetti_contribuente ogco,
                                   soggetti,
                                   contribuenti,
                                   ad4_provincie,
                                   ad4_comuni,
                                   pratiche_tributo
                             where oggetti.oggetto = ogpr.oggetto
                               and ogpr.oggetto_pratica = ogco.oggetto_pratica
                               and ogco.cod_fiscale = contribuenti.cod_fiscale
                               and contribuenti.ni = soggetti.ni
                               and soggetti.cod_com_nas = ad4_comuni.comune(+)
                               and soggetti.cod_pro_nas = ad4_comuni.provincia_stato(+)
                               and ad4_comuni.provincia_stato = ad4_provincie.provincia(+)
                               and pratiche_tributo.pratica = ogpr.pratica
                               and pratiche_tributo.tipo_pratica in ('D', 'A')
                               and decode(pratiche_tributo.tipo_pratica,
                                          'A',
                                          pratiche_tributo.flag_denuncia,
                                          'S') = 'S'
                               and nvl(pratiche_tributo.stato_accertamento, 'D') = 'D'
                               and oggetti.oggetto = ${idOggetto}
                               and pratiche_tributo.tipo_tributo || '' = '${tributoFiltro}'
                               and f_possesso(ogpr.oggetto_pratica,
                                              ogco.cod_fiscale,
                                              to_date('3112' || lpad(to_char(${anno_rif}), 4, '0'),
                                                      'ddmmyyyy'),
                                              nvl('${listaCampiRicerca.get("stampa_cessati")}', 'N')) = 'S'
                             order by contribuenti.cod_fiscale asc                        
                            """

        return execSql(slqProprietari)
    }


    private execSql(def query) {
        def results = sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

}
