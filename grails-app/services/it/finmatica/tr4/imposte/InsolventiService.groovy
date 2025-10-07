package it.finmatica.tr4.imposte

import grails.transaction.Transactional
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.TipoTributoDTO
import it.finmatica.tr4.insolventi.FiltroRicercaInsolventi
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.text.SimpleDateFormat

@Transactional
class InsolventiService {

    def dataSource
    def servletContext
    JasperService jasperService
    SessionFactory sessionFactory
    CommonService commonService


    def generaStampa(def tipoTributo, def filtri, def dati, def paging) {

        def datiInsolventi = []
        def insolventi = [:]
        insolventi.testata = [
                "tipoTributo": tipoTributo,
                "anno"       : dati.anno,
                "ordinamento": dati.ordinamento
        ]

        insolventi.dati = filtri.aRuolo ? getListaInsolventi(filtri, dati, paging).records : getListaInsolventiNonARuolo(filtri, dati, paging).records

        insolventi.aRuolo = filtri.aRuolo

        datiInsolventi << insolventi

        JasperReportDef reportDef = new JasperReportDef(name: 'insolventi.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiInsolventi
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        return insolventi.dati == null ? null : jasperService.generateReport(reportDef)
    }

    def getListaInsolventi(def filtri, def dati, def paging) {

        def parametri = [:]
        def orderBy = ""
        def versato = ""

        //Parametri del filtro
        parametri << ['p_cognome': filtri.cognome ?: "%"]
        parametri << ['p_nome': filtri.nome ?: "%"]
        parametri << ["p_cf": filtri.codFiscale ?: "%"]
        parametri << ["p_imp_da": filtri.impDa ?: 0]
        parametri << ["p_imp_a": filtri.impA ?: Long.MAX_VALUE]
        parametri << ["p_ruolo": !filtri.aRuolo ? 0 : (filtri.ruolo?.id ?: 0)]
        parametri << ["p_insolventi": !filtri.aRuolo ? 'N' : (filtri.insolventi ? 'S' : 'N')]
        parametri << ["p_rimborsi": !filtri.aRuolo ? 'N' : (filtri.rimborsi ? 'S' : 'N')]
        parametri << ["p_pag_corretti": filtri.pagCorretti ? 'S' : 'N']

        //Parametri imposta
        parametri << ["p_tipo_trib": dati.tipoTributo]
        parametri << ["p_anno": dati.anno]
        parametri << ["p_tributo": filtri.tributo as int]

        //Ordinamento
        if (dati.ordinamento == "Codice Fiscale") {
            orderBy = " ORDER BY COD_FISCALE "
        } else {
            orderBy = " ORDER BY COGNOME, NOME "
        }

        //Versamenti
        if (dati.versato == "Con") {
            versato = """
                        AND nvl(f_tot_vers_cont_ruol(imru.anno,
                                                     imru.cod_fiscale,
                                                     :p_tipo_trib,
                                                     decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                     'V'),
                                                      0) > 0 
                      """
        } else if (dati.versato == "Senza") {
            versato = """
                        AND nvl(f_tot_vers_cont_ruol(imru.anno,
                                                     imru.cod_fiscale,
                                                     :p_tipo_trib,
                                                     decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                     'V'),
                                                      0) = 0 
                      """
        }

        def query = """
                            select imru.anno anno,
                                   imru.cod_fiscale cod_fiscale,
                                   sum(imru.imposta_ruolo) imposta_ruolo,
                                   sum(imru.imposta) imposta,
                                   sum(imru.imposta_lorda) imposta_lorda,
                                   nvl(sum(imru.addizionale_eca), 0) + nvl(sum(imru.iva), 0) +
                                   nvl(sum(imru.maggiorazione_eca), 0) add_magg_eca,
                                   sum(imru.addizionale_pro) addizionale_pro,
                                   sum(imru.maggiorazione_tares) maggiorazione_tares,
                                   sum(importo_sgravio) importo_sgravio,
                                   nvl(sum(addizionale_eca_sgravio), 0) + nvl(sum(iva_sgravio), 0) +
                                   nvl(sum(maggiorazione_eca_sgravio), 0) add_magg_eca_sgravio,
                                   sum(addizionale_pro_sgravio) addizionale_pro_sgravio,
                                   sum(maggiorazione_tares_sgravio) maggiorazione_tares_sgravio,
                                   sum(sgravio_tot) sgravio_tot,
                                   nvl(f_tot_vers_cont_ruol(imru.anno,
                                                            imru.cod_fiscale,
                                                            :p_tipo_trib,
                                                            decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                            'V'),
                                       0) versato,
                                   nvl(f_tot_vers_cont_ruol(imru.anno,
                                                            imru.cod_fiscale,
                                                            :p_tipo_trib,
                                                            decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                            'VN'),
                                       0) versato_netto,
                                   nvl(f_tot_vers_cont_ruol(imru.anno,
                                                            imru.cod_fiscale,
                                                            :p_tipo_trib,
                                                            decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                            'V'),
                                       0) -
                                   nvl(f_tot_vers_cont_ruol(imru.anno,
                                                            imru.cod_fiscale,
                                                            :p_tipo_trib,
                                                            decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo),
                                                            'VN'),
                                       0) versato_maggiorazione,
                                   sum(imru.imposta_ruolo) -
                                   nvl(f_tot_vers_cont_ruol(imru.anno,
                                                            imru.cod_fiscale,
                                                            :p_tipo_trib,
                                                            decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)),
                                       0) - nvl(sum(sgravio_tot), 0) differenza,
                                   max(translate(sogg.cognome_nome, '/', ' ')) csoggnome,
                                   max(decode(length(cont.cod_fiscale), 11, null, cont.cod_fiscale)) cod_fis,
                                   max(decode(length(cont.cod_fiscale), 11, cont.cod_fiscale, null)) p_iva,
                                   max(decode(sogg.cod_via,
                                              null,
                                              sogg.denominazione_via,
                                              arvi.denom_uff) ||
                                       decode(sogg.num_civ, null, '', ', ' || sogg.num_civ) ||
                                       decode(sogg.suffisso, null, '', '/' || sogg.suffisso)) indirizzo_dich,
                                   max(decode(nvl(sogg.cap, comu.cap),
                                              null,
                                              '',
                                              nvl(sogg.cap, comu.cap) || ' ') || comu.denominazione ||
                                       decode(prov.sigla, null, '', ' (' || prov.sigla || ')')) residenza_dich,
                                   max(upper(replace(sogg.cognome, ' ', ''))) cognome,
                                   max(upper(replace(sogg.nome, ' ', ''))) nome,
                                   :p_insolventi insolventi,
                                   :p_rimborsi rimborsi,
                                   to_number(:p_tributo) tributo,
                                   rpad(:p_tipo_trib, 5, ' ') titr,
                                   max(cont.ni) ni
                              from (select ogim.cod_fiscale,
                                           round(sum(ogim.imposta + nvl(ogim.addizionale_eca, 0) +
                                                     nvl(ogim.maggiorazione_eca, 0) +
                                                     nvl(ogim.addizionale_pro, 0) + nvl(ogim.iva, 0)),
                                                 0) + round(sum(nvl(ogim.maggiorazione_tares, 0)), 0) imposta_ruolo,
                                           sum(ogim.imposta) imposta,
                                           sum(ogim.addizionale_eca) addizionale_eca,
                                           sum(ogim.maggiorazione_eca) maggiorazione_eca,
                                           sum(ogim.addizionale_pro) addizionale_pro,
                                           sum(ogim.iva) iva,
                                           sum(ogim.maggiorazione_tares) maggiorazione_tares,
                                           round(sum(ogim.imposta + nvl(ogim.addizionale_eca, 0) +
                                                     nvl(ogim.maggiorazione_eca, 0) +
                                                     nvl(ogim.addizionale_pro, 0) + nvl(ogim.iva, 0)),
                                                 0) imposta_lorda,
                                           ogim.ruolo,
                                           ogim.anno
                                      from pratiche_tributo prtr,
                                           tipi_tributo     titr,
                                           codici_tributo   cotr,
                                           oggetti_pratica  ogpr,
                                           oggetti_imposta  ogim,
                                           ruoli            ruol
                                     where titr.tipo_tributo = cotr.tipo_tributo
                                       and cotr.tributo = ogpr.tributo + 0
                                       and cotr.tipo_tributo = prtr.tipo_tributo || ''
                                       and prtr.tipo_tributo || '' = :p_tipo_trib
                                       and prtr.cod_fiscale || '' = ogim.cod_fiscale
                                       and prtr.pratica = ogpr.pratica
                                       and ogpr.oggetto_pratica = ogim.oggetto_pratica
                                       and ogpr.tributo =
                                           decode(:p_tributo, -1, ogpr.tributo, :p_tributo)
                                       and ogim.ruolo is not null
                                       and ogim.flag_calcolo = 'S'
                                       and ogim.anno = :p_anno
                                       and ogim.ruolo =
                                           nvl(nvl(decode(:p_ruolo, 0, to_number(''), :p_ruolo),
                                                   f_ruolo_totale(ogim.cod_fiscale,
                                                                  :p_anno,
                                                                  :p_tipo_trib,
                                                                  :p_tributo)),
                                               ogim.ruolo)
                                       and ogim.cod_fiscale like :p_cf
                                       and ruol.ruolo = ogim.ruolo
                                       and ruol.invio_consorzio is not null
                                     group by ogim.cod_fiscale, ogim.ruolo, ogim.anno) imru,
                                   (select sum(nvl(importo, 0) - nvl(addizionale_eca, 0) -
                                               nvl(maggiorazione_eca, 0) - nvl(addizionale_pro, 0) -
                                               nvl(iva, 0) - nvl(maggiorazione_tares, 0)) importo_sgravio,
                                           sum(addizionale_eca) addizionale_eca_sgravio,
                                           sum(maggiorazione_eca) maggiorazione_eca_sgravio,
                                           sum(addizionale_pro) addizionale_pro_sgravio,
                                           sum(iva) iva_sgravio,
                                           sum(maggiorazione_tares) maggiorazione_tares_sgravio,
                                           sum(nvl(importo, 0)) sgravio_tot,
                                           ruolo,
                                           cod_fiscale
                                      from sgravi
                                     where ruolo = nvl(nvl(decode(:p_ruolo, 0, to_number(''), :p_ruolo),
                                                           f_ruolo_totale(cod_fiscale,
                                                                          :p_anno,
                                                                          :p_tipo_trib,
                                                                          :p_tributo)),
                                                       ruolo)
                                     group by cod_fiscale, ruolo) sgra,
                                   contribuenti cont,
                                   soggetti sogg,
                                   archivio_vie arvi,
                                   ad4_comuni comu,
                                   ad4_provincie prov
                             where imru.cod_fiscale = cont.cod_fiscale
                               and nvl(sogg.nome_ric, '%') like :p_nome
                               and nvl(sogg.cognome_ric, '%') like :p_cognome
                               and cont.ni = sogg.ni
                               and sogg.cod_via = arvi.cod_via(+)
                               and comu.provincia_stato = prov.provincia(+)
                               and sogg.cod_pro_res = comu.provincia_stato(+)
                               and sogg.cod_com_res = comu.comune(+)
                               and imru.cod_fiscale = sgra.cod_fiscale(+)
                               and imru.ruolo = sgra.ruolo(+)
                               ${versato}
                             group by imru.cod_fiscale, imru.anno
                            having abs(sum(imru.imposta_ruolo) - nvl(f_tot_vers_cont_ruol(imru.anno, imru.cod_fiscale, :p_tipo_trib, decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)), 0) - nvl(sum(sgravio_tot), 0)) between abs(nvl(:p_imp_da, 0)) and abs(nvl(:p_imp_a, 9999999999999999)) and (sum(imru.imposta_ruolo) > nvl(f_tot_vers_cont_ruol(imru.anno, imru.cod_fiscale, :p_tipo_trib, decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)), 0) - nvl(sum(sgravio_tot), 0) or nvl(f_tot_vers_cont_ruol(imru.anno, imru.cod_fiscale, :p_tipo_trib, decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)), 0) > 0 or nvl(sum(sgravio_tot), 0) > 0) and (:p_pag_corretti = 'S' or (:p_rimborsi = 'S' and sum(imru.imposta_ruolo) - nvl(f_tot_vers_cont_ruol(imru.anno, imru.cod_fiscale, :p_tipo_trib, decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)), 0) - nvl(sum(sgravio_tot), 0) < 0) or (:p_insolventi = 'S' and sum(imru.imposta_ruolo) - nvl(f_tot_vers_cont_ruol(imru.anno, imru.cod_fiscale, :p_tipo_trib, decode(nvl(:p_ruolo, 0), 0, null, :p_ruolo)), 0) - nvl(sum(sgravio_tot), 0) > 0))
                           ${orderBy}
                            """


        def queryTot = """
                                select count(*) total_count, 
                                nvl(sum(imposta_ruolo),0) tot_imposta_ruolo,
                                nvl(sum(sgravio_tot),0) tot_sgravio_tot,
                                nvl(sum(versato),0) tot_versato,
                                nvl(sum(differenza),0) tot_differenza,
                                nvl(sum(imposta),0) tot_imposta,
                                nvl(sum(add_magg_eca),0) tot_add_magg_eca,
                                nvl(sum(addizionale_pro),0) tot_add_pro,
                                nvl(sum(importo_sgravio),0) tot_importo_sgravio,
                                nvl(sum(add_magg_eca_sgravio),0) tot_add_magg_eca_sgravio,
                                nvl(sum(addizionale_pro_sgravio),0) tot_add_pro_sgravio, 
                                nvl(sum(imposta_lorda),0) - (nvl(sum(importo_sgravio),0) + nvl(sum(add_magg_eca_sgravio),0) + nvl(sum(addizionale_pro_sgravio),0))  tot_dovuto,
                                nvl(sum(versato_netto),0) tot_versato_netto, 
                                (nvl(sum(imposta_lorda),0) - (nvl(sum(importo_sgravio),0) + nvl(sum(add_magg_eca_sgravio),0) + nvl(sum(addizionale_pro_sgravio),0))) - nvl(sum(versato_netto),0) tot_diff_no_magg,
                                nvl(sum(maggiorazione_tares),0) tot_magg_tares,
                                nvl(sum(maggiorazione_tares_sgravio),0) tot_magg_tares_sgravio,
                                nvl(sum(versato_maggiorazione),0) tot_versato_magg,
                                nvl(sum(maggiorazione_tares),0) - nvl(sum(maggiorazione_tares_sgravio),0) - nvl(sum(versato_maggiorazione),0) tot_diff_magg
                                from  (${query})
                             """

        def totali =
                sessionFactory.currentSession.createSQLQuery(queryTot).with {
                    parametri.each { k, v ->
                        setParameter(k, v)
                    }
                    resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
                    list()
                }[0]

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setFirstResult(paging.activePage * paging.pageSize)
            setMaxResults(paging.pageSize)

            list()
        }

        //Eseguo calcoli
        result.each {
            it.dovuto = (it.impostaLorda ?: 0) - ((it.importoSgravio ?: 0) + (it.addMaggEcaSgravio ?: 0) + (it.addizionaleProSgravio ?: 0))
            it.differenzaNoMaggioraz = (it.dovuto ?: 0) - (it.versatoNetto ?: 0)
            it.differenzaMaggioraz = (it.maggiorazioneTares ?: 0) - (it.maggiorazioneTaresSgravio ?: 0) - (it.versatoMaggiorazione ?: 0)
        }

        return [totali: totali, records: result]
    }

    def getListaInsolventiNonARuolo(def filtri, def dati, def paging) {

        def parametri = [:]
        def orderBy = ""
        def versato = ""

        //Parametri del filtro
        parametri << ['p_cognome': filtri.cognome ?: "%"]
        parametri << ['p_nome': filtri.nome ?: "%"]
        parametri << ["p_cf": filtri.codFiscale ?: "%"]
        parametri << ["p_imp_da": filtri.impDa ?: 0]
        parametri << ["p_imp_a": filtri.impA ?: Long.MAX_VALUE]
        parametri << ["p_pag_corretti": filtri.pagCorretti ? 'S' : 'N']

        //Parametri imposta
        parametri << ["p_tipo_trib": dati.tipoTributo]
        parametri << ["p_anno": dati.anno]
        parametri << ["p_tributo": filtri.tributo]

        //Ordinamento
        if (dati.ordinamento == "Codice Fiscale") {
            orderBy = " ORDER BY COD_FISCALE "
        } else {
            orderBy = " ORDER BY COGNOME, NOME "
        }

        //Versamenti
        if (dati.versato == "Con") {
            versato = """
                        AND nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0) > 0 
                      """
        } else if (dati.versato == "Senza") {
            versato = """
                        AND nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0) = 0 
                      """
        }

        def query = """
                           select sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                           + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0)) 
                           - nvl(f_dovuto(max(cont.ni), :p_anno, :p_tipo_trib, 0, :p_tributo
                                         , 'S', null),0) dovuto
                          ,ogim.anno
                          ,ogim.cod_fiscale
                          ,max(nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0)) versato
                          ,max(nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'T'),0)) tardivo
                          ,decode(sign(ogim.anno - 2007)
                                 ,-1, sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                               + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                ,decode(:p_tipo_trib
                                       ,'TARSU',decode(max(titr.flag_tariffa)
                                                      ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                    + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                      ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                      + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                            ,0
                                                            )
                                                      )
                                       ,decode(max(titr.flag_canone)
                                              ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                            + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                              ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                              + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                    ,0
                                                    )
                                              )
                                       )
                                 ) -
                           nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0) netto
                          ,max(translate(sogg.cognome_nome,'/',' ')) csoggnome
                          ,max(decode(length(cont.cod_fiscale),11,null,cont.cod_fiscale)) cod_fis
                          ,max(decode(length(cont.cod_fiscale),11,cont.cod_fiscale,null)) p_iva
                          ,max(decode(sogg.cod_via,null,sogg.denominazione_via,arvi.denom_uff)||
                               decode(sogg.num_civ,null,'',', '||sogg.num_civ)||
                               decode(sogg.suffisso,null,'','/'||sogg.suffisso )
                              ) indirizzo_dich
                          ,max(decode(nvl(sogg.cap,comu.cap),null,'',nvl(sogg.cap,comu.cap)||' ')||
                               comu.denominazione||
                               decode(prov.sigla,null,'',' ('||prov.sigla||')')
                              ) residenza_dich
                          ,max(upper(replace(sogg.cognome,' ',''))) cognome
                          ,max(upper(replace(sogg.nome,' ',''))) nome
                          ,to_number(:p_tributo) tributo
                          ,rpad(:p_tipo_trib,5,' ') tipo_trib
                          ,max(cont.ni)             ni
                      from archivio_vie       arvi
                          ,ad4_comuni         comu
                          ,ad4_provincie      prov
                          ,soggetti           sogg
                          ,contribuenti       cont
                          ,dati_generali      dage
                          ,pratiche_tributo   prtr
                          ,rapporti_tributo   ratr
                          ,oggetti_pratica    ogpr
                          ,oggetti_imposta    ogim
                          ,tipi_tributo       titr
                     where comu.provincia_stato  = prov.provincia (+)
                       and sogg.cod_pro_res      = comu.provincia_stato (+)
                       and sogg.cod_com_res      = comu.comune (+)
                       and sogg.cod_via          = arvi.cod_via (+)
                       and cont.ni               = sogg.ni
                       and ratr.cod_fiscale      = cont.cod_fiscale
                       and ratr.pratica          = prtr.pratica
                       and prtr.tipo_tributo||'' = :p_tipo_trib
                       and titr.tipo_tributo||'' = :p_tipo_trib
                       and prtr.pratica          = ogpr.pratica
                       and decode(prtr.tipo_pratica,'A',prtr.anno,ogim.anno - 1)
                                                 < ogim.anno
                       and nvl(prtr.stato_accertamento,'D')
                                                 = 'D'
                       and cont.cod_fiscale       like :p_cf
                       and nvl(sogg.nome_ric, '%') like :p_nome
                       and nvl(sogg.cognome_ric, '%') like :p_cognome
                       and nvl(ogpr.tributo,-2)   = decode(:p_tributo,-1,nvl(ogpr.tributo,-2),:p_tributo)
                       and ogpr.oggetto_pratica  = ogim.oggetto_pratica
                       and ogim.anno             = :p_anno
                       and nvl(ogim.ruolo,-1) = nvl(nvl(f_ruolo_totale(ogim.cod_fiscale, :p_anno, :p_tipo_trib,:p_tributo),ogim.ruolo),-1)
                     ${versato}
                     group by
                           ogim.anno
                          ,ogim.cod_fiscale
                    having decode(sign(ogim.anno - 2007)
                                 ,-1, sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                               + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                ,decode(:p_tipo_trib
                                       ,'TARSU',decode(max(titr.flag_tariffa)
                                                      ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                    + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                      ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                      + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                            ,0
                                                            )
                                                      )
                                       ,decode(max(titr.flag_canone)
                                              ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                            + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                              ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                              + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                    ,0
                                                    )
                                              )
                                       )
                                 ) 
                           -  nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0)
                           - nvl(f_dovuto(max(cont.ni), :p_anno, :p_tipo_trib, 0, :p_tributo
                                         , 'S', null),0)
                                           between abs(nvl(:p_imp_da,0))
                                               and abs(nvl(:p_imp_a ,9999999999999999))
                       and (  :p_pag_corretti = 'S'
                             or decode(sign(ogim.anno - 2007)
                                    ,-1, sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                  + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                   ,decode(:p_tipo_trib
                                          ,'TARSU',decode(max(titr.flag_tariffa)
                                                         ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                       + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                         ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                         + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                               ,0
                                                               )
                                                         )
                                          ,decode(max(titr.flag_canone)
                                                 ,'S',sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                               + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                 ,round(sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
                                                                                 + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
                                                       ,0
                                                       )
                                                 )
                                          )
                                    )- nvl(f_dovuto(max(cont.ni), :p_anno, :p_tipo_trib, 0, :p_tributo
                                         , 'S', null),0)
                                                 >
                               nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'V'),0)
                            or nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,:p_tipo_trib,'T'),0)
                                                 > 0
                           )
                           ${orderBy}             
                            """


        def queryTot = """
                                select count(*) total_count, 
                                nvl(sum(dovuto),0) tot_dovuto,
                                nvl(sum(versato),0) tot_versato,
                                nvl(sum(netto),0) tot_netto,
                                nvl(sum(tardivo),0) tot_tardivo
                                from  (${query})
                             """

        def totali =
                sessionFactory.currentSession.createSQLQuery(queryTot).with {
                    parametri.each { k, v ->
                        setParameter(k, v)
                    }
                    resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
                    list()
                }[0]

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setFirstResult(paging.activePage * paging.pageSize)
            setMaxResults(paging.pageSize)

            list()
        }


        return [totali: totali, records: result]
    }

    def getInsolventiGenerale(FiltroRicercaInsolventi filtri, def paging, def sortBy = null, Boolean ignoraTotali = false) {

        def parametri = [:]

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")

        String finalWhere = ""

        String tipoTributo = filtri.tipoTributo

        parametri << ['p_tipo_tributo': tipoTributo]

        parametri << ['p_cognome': filtri.cognome ?: "%"]
        parametri << ['p_nome': filtri.nome ?: "%"]
        parametri << ['p_cf': filtri.codFiscale ?: "%"]
        if (filtri.codContribuente) {
            parametri << ['p_cod_contribuente': filtri.codContribuente]
        }

        parametri << ['p_anno_da': filtri.annoDa ?: 1900]
        parametri << ['p_anno_a': filtri.annoA ?: 9999]
        parametri << ['p_data_noti_da': filtri.notificaDal ? sdf.format(filtri.notificaDal) : '01/01/1900']
        parametri << ['p_data_noti_a': filtri.notificaAl ? sdf.format(filtri.notificaAl) : '31/12/9999']

        parametri << ['p_imp_da': filtri.impDa ?: Long.MIN_VALUE]
        parametri << ['p_imp_a': filtri.impA ?: Long.MAX_VALUE]

        if (filtri.filtroRuolo != "Tutti") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            if (filtri.filtroRuolo == "Con") {
                if (filtri.ruolo != null) {
                    parametri << ["p_ruolo": (filtri.ruolo?.id ?: 0)]
                    finalWhere += "(ruolo = :p_ruolo)"
                } else {
                    finalWhere += "(ruolo is not null)"
                }

            } else if (filtri.filtroRuolo == "Senza") {
                finalWhere += "(ruolo is null)"
            }
        }

        if (filtri.praticheRateizzate != "Tutti") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            if (filtri.praticheRateizzate == "Si") {
                finalWhere += " tipo_atto = 90 "
            } else if (filtri.praticheRateizzate == "No") {
                finalWhere += " (tipo_atto != 90 or tipo_atto is null) "
            }
        }

        String tipoFilter = ""

        if ((filtri.filtroTipiAtto.imp) || (filtri.filtroTipiAtto.liq) || (filtri.filtroTipiAtto.acc)) {

            if (filtri.filtroTipiAtto.imp) {
                if (!tipoFilter.isEmpty()) tipoFilter += " OR "
                tipoFilter += "ins_imp = 'SI'"
            }
            if (filtri.filtroTipiAtto.liq) {
                if (!tipoFilter.isEmpty()) tipoFilter += " OR "
                tipoFilter += "ins_liq = 'SI'"
            }
            if (filtri.filtroTipiAtto.acc) {
                if (!tipoFilter.isEmpty()) tipoFilter += " OR "
                tipoFilter += "ins_acc = 'SI'"
            }
        } else {
            tipoFilter = "ins_imp = 'NO' AND ins_liq = 'NO' AND ins_acc = 'NO'"
        }
        if (!finalWhere.isEmpty()) {
            finalWhere += " AND "
        }
        finalWhere += "(${tipoFilter})"

        if (filtri.filtroVersamenti == "Con") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            finalWhere += "(versato > 0)"
        } else if (filtri.filtroVersamenti == "Senza") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            finalWhere += "(versato = 0)"
        }
        if (filtri.filtroIngiunzione == "Con") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            finalWhere += "(ingiunzione is not null)"
        } else if (filtri.filtroIngiunzione == "Senza") {
            if (!finalWhere.isEmpty()) {
                finalWhere += " AND "
            }
            finalWhere += "(ingiunzione is null)"
        }

        String sqlSortBy = " order by "

        sortBy.each { k, v ->
            if (v.verso) {
                sqlSortBy += "${k} ${v.verso}, "
            }
        }

        String sql = """
				select sum(nvl(ogim.imposta, 0) + nvl(ogim.addizionale_eca,0) 
				                                + nvl(ogim.maggiorazione_eca,0)
				                                + nvl(ogim.addizionale_pro,0) 
				                                + nvl(ogim.iva,0))                                     dovuto
				      ,decode(sign(ogim.anno - 2007)     
				              ,-1, sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                           + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0)) 
				              ,decode(prtr.tipo_tributo
				                     ,'TARSU',decode(titr.flag_tariffa 
				                                    ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                 + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                    ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                   + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                           ,0)
				                                    )
				                     ,decode(titr.flag_canone
				                            ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                            ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                   ,0)
				                            )
				                     )
				              )                                                                        dovuto_arr
				      ,ogim.anno
				      ,ogim.cod_fiscale																   cod_fiscale
				      ,sogg.ni                                                                         ni
				      ,nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,prtr.tipo_tributo,'V'),0)        versato
				      ,nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,prtr.tipo_tributo,'T'),0)        tardivo
				      ,translate(sogg.cognome_nome,'/',' ')                                            contribuente
				      ,decode(sogg.cod_via,null,sogg.denominazione_via,arvi.denom_uff)||
				           decode(sogg.num_civ,null,'',', '||sogg.num_civ)||
				           decode(sogg.suffisso,null,'','/'||sogg.suffisso )                           indirizzo_dich
				      ,decode(nvl(sogg.cap,comu_res.cap)
				             ,null,''
				             ,nvl(sogg.cap,comu_res.cap)||' '
				             )||
				             comu_res.denominazione||
				             decode(prov_res.sigla,null,'',' ('||prov_res.sigla||')')                  residenza_dich
				      ,prtr.tipo_tributo                                                               tipo_trib
				      ,f_descrizione_titr(prtr.tipo_tributo,ogim.anno)                                 descr_tipo_tributo
				      ,to_char(null)                                                                   tipo_pratica
				      ,to_char(SOGG.DATA_NAS,'dd/mm/yyyy')                                             data_nascita
				      ,comu_nas.denominazione 
				           ||decode(prov_nas.sigla
				                   ,null, ''
				                   ,' (' || prov_nas.sigla
				                         || decode(prov_nas.sigla
				                                  ,null, ''
				                                  , ' )'
				                                  )
				                   )                                                                   luogo_nascita
				     , TRANSLATE(SOGG.RAPPRESENTANTE, '/',' ')                                         rappresentante
				     , SOGG.COD_FISCALE_RAP                                                            cod_fiscale_rap
				     , SOGG.INDIRIZZO_RAP                                                              indirizzo_rap
				     , comu_rap.denominazione 
				           ||decode(prov_rap.sigla
				                   ,null, ''
				                   ,' (' || prov_rap.sigla
				                         || decode(prov_rap.sigla
				                                  ,null, ''
				                                  ,' )'
				                                  )
				                   )                                                                   comune_rap
				     , to_number(null)                                                                 ruolo        
				     , to_char(null)                                                                   numero_pratica
				     , to_date(null)                                                                   data_notifica
				     , to_number(null)                                                                 pratica
				     , to_date(null)                                                                   data_pratica
				     , to_char(null)                                                                   vers_multipli
				     , to_date(null)                                                                   data_pagamento
				     , to_number(null)                                                                 importo_tributo
				     ,'SI'                                                                             ins_imp
				     ,'NO'                                                                             ins_acc
				     ,'NO'                                                                             ins_liq
				     , F_PRIMO_EREDE(sogg.ni)                                                          primo_erede
				     , to_number(null)                                                                 ingiunzione
				     , to_number(null)                                                                 tipo_atto
				  from archivio_vie       arvi
				      ,ad4_comuni         comu_res
				      ,ad4_provincie      prov_res
				      ,ad4_comuni         comu_nas
				      ,ad4_provincie      prov_nas
				      ,ad4_comuni         comu_rap
				      ,ad4_provincie      prov_rap
				      ,soggetti           sogg
				      ,contribuenti       cont
				      ,dati_generali      dage
				      ,pratiche_tributo   prtr
				      ,rapporti_tributo   ratr
				      ,oggetti_pratica    ogpr
				      ,oggetti_imposta    ogim
				      ,tipi_tributo       titr
				 where comu_res.provincia_stato = prov_res.provincia (+)
				   and sogg.cod_pro_res         = comu_res.provincia_stato (+)
				   and sogg.cod_com_res         = comu_res.comune (+)
				   and comu_nas.provincia_stato = prov_nas.provincia (+)
				   and sogg.cod_pro_nas         = comu_nas.provincia_stato (+)
				   and sogg.cod_com_nas         = comu_nas.comune (+)
				   and comu_rap.provincia_stato = prov_rap.provincia (+)
				   and sogg.cod_pro_rap         = comu_rap.provincia_stato (+)
				   and sogg.cod_com_rap         = comu_rap.comune (+)
				   and sogg.cod_via             = arvi.cod_via (+)
				   and cont.ni                  = sogg.ni
				   and ratr.cod_fiscale         = cont.cod_fiscale
				   and ratr.pratica             = prtr.pratica
				   and prtr.pratica             = ogpr.pratica
				   and prtr.tipo_tributo        = :p_tipo_tributo
				   and titr.tipo_tributo||''    = prtr.tipo_tributo
				   and decode(prtr.tipo_pratica,'A',prtr.anno,ogim.anno - 1) < ogim.anno
				   and nvl(prtr.stato_accertamento,'D') = 'D'
				   and cont.cod_fiscale like :p_cf
                   and nvl(sogg.nome_ric,'%') like :p_nome
                   and nvl(sogg.cognome_ric,'%') like :p_cognome
				   and ogpr.oggetto_pratica  = ogim.oggetto_pratica
				   and ogim.cod_fiscale         = cont.cod_fiscale
				   and ogim.anno          between :p_anno_da
				                          and     :p_anno_a
				   and prtr.data_notifica between to_date(:p_data_noti_da, 'dd/mm/yyyy')
				                          and     to_date(:p_data_noti_a, 'dd/mm/yyyy')   """
        if (filtri.codContribuente) {
            sql += "and cont.cod_contribuente = :p_cod_contribuente "
        }
        sql += """
				 group by
				       ogim.anno
				      ,ogim.cod_fiscale
				      ,sogg.ni
				      ,prtr.tipo_tributo
				      ,sogg.cognome_nome
				      ,SOGG.DATA_NAS
				      ,sogg.cod_via
				      ,sogg.denominazione_via
				      ,arvi.denom_uff
				      ,sogg.num_civ
				      ,sogg.suffisso
				      ,sogg.cap
				      ,comu_res.cap
				      ,comu_res.denominazione
				      ,prov_res.sigla
				      ,comu_nas.denominazione 
				      ,prov_nas.sigla
				      ,SOGG.RAPPRESENTANTE
				      ,SOGG.COD_FISCALE_RAP
				      ,SOGG.INDIRIZZO_RAP   
				      ,comu_rap.denominazione 
				      ,prov_rap.sigla
				      ,titr.flag_tariffa
				      ,titr.flag_canone
				 having decode(sign(ogim.anno - 2007)     
				              ,-1, sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                           + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0)) 
				              ,decode(prtr.tipo_tributo
				                     ,'TARSU',decode(titr.flag_tariffa 
				                                    ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                 + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                    ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                   + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                           ,0)
				                                    )
				                     ,decode(titr.flag_canone
				                            ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                            ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                   ,0)
				                            )
				                     )
				              )
				       - nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,prtr.tipo_tributo,'V'),0)
				                       between nvl(:p_imp_da,-999999999999999)
				                           and nvl(:p_imp_a ,9999999999999999)
				   and ( decode(sign(ogim.anno - 2007)     
				              ,-1, sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                           + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0)) 
				              ,decode(prtr.tipo_tributo
				                     ,'TARSU',decode(titr.flag_tariffa 
				                                    ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                 + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                    ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                                   + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                           ,0)
				                                    )
				                     ,decode(titr.flag_canone
				                            ,'S',sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                            ,round(sum(nvl(ogim.imposta,0) + nvl(ogim.addizionale_eca,0) + nvl(ogim.maggiorazione_eca,0)
				                                                          + nvl(ogim.addizionale_pro,0) + nvl(ogim.iva,0))
				                                   ,0)
				                            )
				                     )
				              ) >
				           nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,prtr.tipo_tributo,'V'),0)
				        or nvl(f_tot_vers_cont(ogim.anno,ogim.cod_fiscale,prtr.tipo_tributo,'T'),0) > 0
				       )
		"""

        if (tipoTributo != 'TARSU') {
            sql += """
				UNION ALL
				SELECT F_ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,1)                               dovuto
				     , nvl(decode(nvl(titr.flag_canone,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                 ,'N1',ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,0) 
				                 ,ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,2)
				                 ),0)                                                           dovuto_arr
				     , PRATICHE_TRIBUTO.ANNO                                                    anno
				     , CONTRIBUENTI.COD_FISCALE                                                 cod_fiscale
				     , soggetti.ni                                                              ni
				     , nvl(vers.i_vtutti,0)                                                     versato
				     , nvl(vers.i_vtutti,0) - nvl(tot_vers.I_V,0)                               tardivo
				     , TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ')                                contribuente
				     , decode ( SOGGETTI.COD_VIA
				              , NULL, DENOMINAZIONE_VIA
				              , DENOM_UFF
				              )||decode( num_civ
				                       , NULL, ''
				                       ,  ', '||num_civ 
				                       )||decode( suffisso
				                                , NULL, ''
				                                , '/'||suffisso )                               indirizzo_dich
				     , decode ( nvl(SOGGETTI.CAP,ad4_com_res.CAP)
				              , NULL, ''
				              , nvl(SOGGETTI.CAP,ad4_com_res.CAP) 
				                || ' ' || ad4_com_res.DENOMINAZIONE
				              ) || decode( ad4_pro_res.SIGLA
				                         , NULL, ''
				                         , ' (' || ad4_pro_res.SIGLA || ')'
				                         )                                                      residenza_dich
				     , PRATICHE_TRIBUTO.TIPO_TRIBUTO                                            tipo_trib
				     , f_descrizione_titr(PRATICHE_TRIBUTO.tipo_tributo,PRATICHE_TRIBUTO.anno)  descr_tipo_tributo
				     , PRATICHE_TRIBUTO.TIPO_PRATICA                                            tipo_pratica
				     , to_char(SOGGETTI.DATA_NAS,'dd/mm/yyyy')                                  data_nascita
				     , ad4_com_nas.denominazione 
				       ||decode(ad4_pro_nas.sigla
				               ,null, ''
				               ,' (' || ad4_pro_nas.sigla
				                     || decode(ad4_pro_nas.sigla
				                              ,null, ''
				                              , ' )'
				                              )
				               )                                                                luogo_nascita
				     , TRANSLATE(SOGGETTI.RAPPRESENTANTE, '/',' ')                              rappresentante
				     , SOGGETTI.COD_FISCALE_RAP                                                 cod_fiscale_rap
				     , SOGGETTI.INDIRIZZO_RAP                                                   indirizzo_rap
				     , ad4_com_rap.denominazione 
				       ||decode(ad4_pro_rap.sigla
				               ,null, ''
				               ,' (' || ad4_pro_rap.sigla
				                     || decode(ad4_pro_rap.sigla
				                              ,null, ''
				                              ,' )'
				                              )
				               )                                                                comune_rap
				     , sapr.ruolo                                                               ruolo
				     , PRATICHE_TRIBUTO.NUMERO                                                  numero_pratica
				     , PRATICHE_TRIBUTO.DATA_NOTIFICA                                           data_notifica
				     , PRATICHE_TRIBUTO.PRATICA                                                 pratica
				     , PRATICHE_TRIBUTO.DATA                                                    data_pratica
				     , vers.vers_multipli                                                       vers_multipli
				     , vers.data_pag                                                            data_pagamento
				     , sanz.importo_tributo                                                     importo_tributo
				     ,'NO'                                                                      ins_imp
				     ,decode(PRATICHE_TRIBUTO.TIPO_PRATICA
				            ,'A','SI'
				            ,'NO'
				            )                                                                   ins_acc
				     ,decode(PRATICHE_TRIBUTO.TIPO_PRATICA
				            ,'L','SI'
				            ,'NO'
				            )                                                                   ins_liq  
				     , F_PRIMO_EREDE(soggetti.ni)                                               primo_erede 
				     , decode(f_pratica(pratiche_tributo.pratica_rif)  
				             ,'GUP',pratiche_tributo.pratica_rif
				             ,'GUD',pratiche_tributo.pratica_rif
				             ,to_number(null))                                                  ingiunzione
				     , PRATICHE_TRIBUTO.TIPO_ATTO                                               tipo_atto
				 FROM ARCHIVIO_VIE
				    , AD4_COMUNI      ad4_com_res
				    , AD4_PROVINCIE   ad4_pro_res
				    , SOGGETTI
				    , DATI_GENERALI
				    , (select sum(nvl(vers.importo_versato,0)) I_Vtutti
				            , min(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)),to_date(null))) data_pag
				            , decode(count(1),1,'','<')  vers_multipli
				            , VERS.PRATICA PRAT
				            , VERS.COD_FISCALE CF
				         from versamenti VERS
				            , PRATICHE_TRIBUTO PRTR
				        where VERS.PRATICA    = PRTR.PRATICA 
				          and PRTR.TIPO_PRATICA   in ('A','L')
				          and nvl(PRTR.stato_accertamento,'D') = 'D'
				     GROUP BY VERS.PRATICA
				            , VERS.COD_FISCALE
				      ) vers
				    , (select sum(nvl(vers.importo_versato,0)) I_V
				            , sum(decode(sign(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)) 
				                                    - trunc(prtr.data_notifica) 
				                                    - decode(prtr.tipo_tributo
				                                            ,'ICI',decode(sign(trunc(prtr.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy'))
				                                                         ,1,60
				                                                         ,90
				                                                         )
				                                            ,'TASI',decode(sign(trunc(prtr.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy'))
				                                                         ,1,60
				                                                         ,90
				                                                         )
				                                            ,60
				                                            ) 
				                                 ,0))
				                        , 1, 0
				                        , nvl(vers.importo_versato,0))
				                    ) I_V60
				            , min(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)),to_date(null))) D_P
				            , VERS.PRATICA PRAT
				            , VERS.COD_FISCALE CF
				       from versamenti VERS
				          , PRATICHE_TRIBUTO PRTR
				      where nvl(trunc(VERS.DATA_PAGAMENTO),trunc(prtr.data_notifica)) - trunc(PRTR.DATA_NOTIFICA)  <= 90
				        and VERS.PRATICA    = PRTR.PRATICA
				        and PRTR.pratica_rif    is null 
				        and PRTR.TIPO_PRATICA   in ('A','L')
				        and nvl(PRTR.stato_accertamento,'D') = 'D'
				   GROUP BY VERS.PRATICA
				          , VERS.COD_FISCALE
				         ) tot_vers
				    , (select max(nvl(ruolo,to_number(null))) ruolo
				            , pratica
				         from sanzioni_pratica
				     group by pratica
				         ) sapr
				    , (select sum(decode(sap2.tipo_tributo||sap2.cod_sanzione
				                                         , 'ICI1', sap2.importo
				                                         , 'ICI21', sap2.importo
				                                         , 'ICI101', sap2.importo
				                                         , 'ICI121', sap2.importo
				                                         , 'TASI1', sap2.importo
				                                         , 'TASI21', sap2.importo
				                                         , 'TASI101', sap2.importo
				                                         , 'TASI121', sap2.importo
				                                         , 'ICP1', sap2.importo
				                                         , 'ICP11', sap2.importo
				                                         , 'ICP21', sap2.importo
				                                         , 'ICP31', sap2.importo
				                                         , 'ICP41', sap2.importo
				                                         , 'ICP101', sap2.importo
				                                         , 'ICP111', sap2.importo
				                                         , 'ICP121', sap2.importo
				                                         , 'ICP131', sap2.importo
				                                         , 'ICP141', sap2.importo
				                                         , 'TOSAP1', sap2.importo
				                                         , 'TOSAP11', sap2.importo
				                                         , 'TOSAP21', sap2.importo
				                                         , 'TOSAP31', sap2.importo
				                                         , 'TOSAP41', sap2.importo
				                                         , 'TOSAP101', sap2.importo
				                                         , 'TOSAP111', sap2.importo
				                                         , 'TOSAP121', sap2.importo
				                                         , 'TOSAP131', sap2.importo
				                                         , 'TOSAP141', sap2.importo
				                                         , 0)) importo_tributo
				            , pratica pratica
				         from sanzioni_pratica sap2
				     group by pratica
				         ) sanz
				    , PRATICHE_TRIBUTO
				    , RAPPORTI_TRIBUTO
				    , CONTRIBUENTI
				    , AD4_COMUNI      ad4_com_nas
				    , AD4_PROVINCIE   ad4_pro_nas
				    , AD4_COMUNI      ad4_com_rap
				    , AD4_PROVINCIE   ad4_pro_rap
				    , tipi_tributo    titr
				WHERE ad4_com_res.provincia_stato                  = ad4_pro_res.provincia (+)
				  and soggetti.cod_pro_res                         = ad4_com_res.provincia_stato (+)
				  and soggetti.cod_com_res                         = ad4_com_res.comune (+)
				  and soggetti.cod_via                             = archivio_vie.cod_via (+)
				  and ad4_com_nas.provincia_stato                  = ad4_pro_nas.provincia (+)
				  and soggetti.cod_pro_nas                         = ad4_com_nas.provincia_stato (+)
				  and soggetti.cod_com_nas                         = ad4_com_nas.comune (+)
				  and ad4_com_rap.provincia_stato                  = ad4_pro_rap.provincia (+)
				  and soggetti.cod_pro_rap                         = ad4_com_rap.provincia_stato (+)
				  and soggetti.cod_com_rap                         = ad4_com_rap.comune (+)
				  and nvl(pratiche_tributo.stato_accertamento,'D') = 'D' 
				  and CONTRIBUENTI.NI                              = SOGGETTI.NI 
				  and PRATICHE_TRIBUTO.PRATICA                     = RAPPORTI_TRIBUTO.PRATICA
				  and RAPPORTI_TRIBUTO.COD_FISCALE                 = CONTRIBUENTI.COD_FISCALE
				  and sapr.pratica                                 = pratiche_tributo.pratica
				  and sanz.pratica                                 = pratiche_tributo.pratica
				  and ( pratiche_tributo.pratica_rif is null
				      or ( pratiche_tributo.pratica_rif is not null
				          and substr(f_pratica(pratiche_tributo.pratica_rif),1,1) = 'G'
				         )
				       )
				  AND PRATICHE_TRIBUTO.TIPO_PRATICA                in ('A','L')
				  AND CONTRIBUENTI.COD_FISCALE                  like :p_cf
				  and titr.tipo_tributo||''                        = pratiche_tributo.tipo_tributo
				  AND PRATICHE_TRIBUTO.ANNO                  between :p_anno_da AND :p_anno_a
				  and PRATICHE_TRIBUTO.data_notifica between to_date(:p_data_noti_da, 'dd/mm/yyyy')
				                                     and     to_date(:p_data_noti_a, 'dd/mm/yyyy') 
               	  and nvl(SOGGETTI.nome_ric,'%')                like :p_nome
                  and nvl(SOGGETTI.cognome_ric,'%')             like :p_cognome
				  AND vers.PRAT (+)                                = RAPPORTI_TRIBUTO.PRATICA
				  AND tot_vers.PRAT (+)                            = RAPPORTI_TRIBUTO.PRATICA
				  AND vers.CF (+)                                  = RAPPORTI_TRIBUTO.COD_FISCALE
				  AND tot_vers.CF (+)                              = RAPPORTI_TRIBUTO.COD_FISCALE
				  and (nvl(decode(nvl(titr.flag_canone,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                 ,'N1',ROUND(PRATICHE_TRIBUTO.IMPORTO_RIDOTTO,0) 
				                 ,ROUND(PRATICHE_TRIBUTO.IMPORTO_RIDOTTO,2)
				                 ),0)
				       - nvl(tot_vers.i_v60,0) )					> decode(dati_generali.fase_euro,1,1000,1)
				  and (nvl(decode(nvl(titr.flag_canone,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                 ,'N1',ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,0) 
				                 ,ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,2)
				                 ),0)  
				       - nvl(tot_vers.i_v,0) ) 						> decode(dati_generali.fase_euro,1,1000,1)
				  and (trunc(sysdate) - trunc(PRATICHE_TRIBUTO.DATA_NOTIFICA) ) >
				                                     decode(pratiche_tributo.tipo_tributo
				                                           ,'ICI',decode(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy'))
				                                                        ,1,60
				                                                        ,90
				                                                        )
				                                           ,'TASI',decode(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy'))
				                                                        ,1,60
				                                                        ,90
				                                                        )
				                                           ,60
				                                           )
				  AND nvl(decode(nvl(titr.flag_canone,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                 ,'N1',ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,0) 
				                 ,ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,2)
				                 ),0) 
				      - F_ROUND(nvl(vers.i_vtutti,0),1)
				                                                     between :p_imp_da AND :p_imp_a
				  AND nvl(decode(nvl(titr.flag_canone,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                 ,'N1',ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,0) 
				                 ,ROUND(PRATICHE_TRIBUTO.IMPORTO_TOTALE,2)
				                 ),0) 
				      - F_ROUND(nvl(vers.i_vtutti,0),1) > 0
				  and PRATICHE_TRIBUTO.tipo_tributo = :p_tipo_tributo
			"""
            if (filtri.codContribuente) {
                sql += "and CONTRIBUENTI.COD_CONTRIBUENTE = :p_cod_contribuente "
            }
        } else {
            sql += """
				UNION ALL
				SELECT F_ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),1)             dovuto
				     , nvl(decode(nvl(titr.flag_tariffa,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                ,'N1',ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),0) 
				                ,ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),2)
				                ),0)                                                            dovuto_arr
				     , PRATICHE_TRIBUTO.ANNO                                                    anno
				     , CONTRIBUENTI.COD_FISCALE                                                 cod_fiscale
				     , soggetti.ni                                                              ni
				     , nvl(vers.i_vtutti,0)                                                     versato
				     , nvl(vers.i_vtutti,0) - nvl(tot_vers.I_V,0)                               tardivo
				     , TRANSLATE(SOGGETTI.COGNOME_NOME, '/',' ')                                contribuente
				     , decode ( SOGGETTI.COD_VIA
				              , NULL, DENOMINAZIONE_VIA
				              , DENOM_UFF
				              )||decode( num_civ
				                       , NULL, ''
				                       ,  ', '||num_civ 
				                       )||decode( suffisso
				                                , NULL, ''
				                                , '/'||suffisso )                               indirizzo_dich
				     , decode ( nvl(SOGGETTI.CAP,ad4_com_res.CAP)
				              , NULL, ''
				              , nvl(SOGGETTI.CAP,ad4_com_res.CAP) 
				                || ' ' || ad4_com_res.DENOMINAZIONE
				              ) || decode( ad4_pro_res.SIGLA
				                         , NULL, ''
				                         , ' (' || ad4_pro_res.SIGLA || ')'
				                         )                                                      residenza_dich
				     ,PRATICHE_TRIBUTO.TIPO_TRIBUTO                                             tipo_trib
				      ,f_descrizione_titr(PRATICHE_TRIBUTO.tipo_tributo,PRATICHE_TRIBUTO.anno)  descr_tipo_tributo
				     , PRATICHE_TRIBUTO.TIPO_PRATICA                                            tipo_pratica
				     , to_char(SOGGETTI.DATA_NAS,'dd/mm/yyyy')                                  data_nascita
				     , ad4_com_nas.denominazione 
				       ||decode(ad4_pro_nas.sigla
				               ,null, ''
				               ,' (' || ad4_pro_nas.sigla
				                     || decode(ad4_pro_nas.sigla
				                              ,null, ''
				                              , ' )'
				                              )
				               )                                                                luogo_nascita
				     , TRANSLATE(SOGGETTI.RAPPRESENTANTE, '/',' ')                              rappresentante
				     , SOGGETTI.COD_FISCALE_RAP                                                 cod_fiscale_rap
				     , SOGGETTI.INDIRIZZO_RAP                                                   indirizzo_rap
				     , ad4_com_rap.denominazione 
				       ||decode(ad4_pro_rap.sigla
				               ,null, ''
				               ,' (' || ad4_pro_rap.sigla
				                     || decode(ad4_pro_rap.sigla
				                              ,null, ''
				                              ,' )'
				                              )
				               )                                                                comune_rap
				     , sapr.ruolo                                                               ruolo
				     , PRATICHE_TRIBUTO.NUMERO                                                  numero_pratica
				     , PRATICHE_TRIBUTO.DATA_NOTIFICA                                           data_notifica
				     , PRATICHE_TRIBUTO.PRATICA                                                 pratica
				     , PRATICHE_TRIBUTO.DATA                                                    data_pratica
				     , vers.vers_multipli                                                       vers_multipli
				     , vers.data_pag                                                            data_pagamento
				     , sanz.importo_tributo 
				       + round(sanz.importo_tributo * nvl(cata.addizionale_eca,0) / 100,2)
				       + round(sanz.importo_tributo * nvl(cata.maggiorazione_eca,0) / 100,2)
				       + round(sanz.importo_tributo * nvl(cata.addizionale_pro,0) / 100,2)
				       + round(sanz.importo_tributo * nvl(cata.aliquota,0) / 100,2)             importo_tributo
				     ,'NO'                                                                      ins_imp
				     ,decode(PRATICHE_TRIBUTO.TIPO_PRATICA
				            ,'A','SI'
				            ,'NO'
				            )                                                                   ins_acc
				     ,decode(PRATICHE_TRIBUTO.TIPO_PRATICA
				            ,'L','SI'
				            ,'NO'
				            )                                                                   ins_liq  
				     , F_PRIMO_EREDE(soggetti.ni)                                               primo_erede 
				     , decode(f_pratica(pratiche_tributo.pratica_rif)  
				             ,'GUP',pratiche_tributo.pratica_rif
				             ,'GUD',pratiche_tributo.pratica_rif
				             ,to_number(null))                                                  ingiunzione
				     , PRATICHE_TRIBUTO.TIPO_ATTO                                               tipo_atto
				 FROM ARCHIVIO_VIE
				    , AD4_COMUNI      ad4_com_res
				    , AD4_PROVINCIE   ad4_pro_res
				    , SOGGETTI
				    , DATI_GENERALI
				    , carichi_tarsu     cata
				    , (select sum(nvl(vers.importo_versato,0)) I_Vtutti
				            , min(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)),to_date(null))) data_pag
				            , decode(count(1),1,'','<')  vers_multipli
				            , VERS.PRATICA PRAT
				            , VERS.COD_FISCALE CF
				         from versamenti VERS
				            , PRATICHE_TRIBUTO PRTR
				        where VERS.PRATICA    = PRTR.PRATICA 
				          and PRTR.pratica_rif    is null 
				          and PRTR.TIPO_PRATICA   in ('A','L')
				          and nvl(PRTR.stato_accertamento,'D') = 'D'
				     GROUP BY VERS.PRATICA
				            , VERS.COD_FISCALE
				      ) vers
				    , (select sum(nvl(vers.importo_versato,0)) I_V
				            , sum(decode(sign(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)) 
				                                    - trunc(prtr.data_notifica) - 60 
				                                 ,0))
				                        , 1, 0
				                        , nvl(vers.importo_versato,0))
				                    ) I_V60
				            , min(nvl(nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica)),to_date(null))) D_P
				            , VERS.PRATICA PRAT
				            , VERS.COD_FISCALE CF
				       from versamenti VERS
				          , PRATICHE_TRIBUTO PRTR
				      where nvl(trunc(VERS.DATA_PAGAMENTO),trunc(prtr.data_notifica)) - trunc(PRTR.DATA_NOTIFICA)  <= 90
				        and VERS.PRATICA    = PRTR.PRATICA
				        and PRTR.pratica_rif    is null 
				        and PRTR.TIPO_PRATICA   in ('A','L')
				        and nvl(PRTR.stato_accertamento,'D') = 'D'
				   GROUP BY VERS.PRATICA
				          , VERS.COD_FISCALE
				         ) tot_vers
				    , (select max(nvl(ruolo,to_number(null))) ruolo
				            , pratica
				         from sanzioni_pratica
				     group by pratica
				         ) sapr
				    , (select sum(decode(sap2.tipo_tributo||sap2.cod_sanzione
				                                         , 'TARSU1', sap2.importo
				                                         , 'TARSU9', sap2.importo
				                                         , 'TARSU100', sap2.importo
				                                         , 'TARSU101', sap2.importo
				                                         , 'TARSU111', sap2.importo
				                                         , 'TARSU121', sap2.importo
				                                         , 'TARSU131', sap2.importo
				                                         , 'TARSU141', sap2.importo
				                                         , 0)) importo_tributo
				            , pratica pratica
				         from sanzioni_pratica sap2
				     group by pratica
				         ) sanz
				    , PRATICHE_TRIBUTO
				    , RAPPORTI_TRIBUTO
				    , CONTRIBUENTI
				    , AD4_COMUNI      ad4_com_nas
				    , AD4_PROVINCIE   ad4_pro_nas
				    , AD4_COMUNI      ad4_com_rap
				    , AD4_PROVINCIE   ad4_pro_rap
				    , tipi_tributo    titr
				WHERE ad4_com_res.provincia_stato                  = ad4_pro_res.provincia (+)
				  and soggetti.cod_pro_res                         = ad4_com_res.provincia_stato (+)
				  and soggetti.cod_com_res                         = ad4_com_res.comune (+)
				  and soggetti.cod_via                             = archivio_vie.cod_via (+)
				  
				  and ad4_com_nas.provincia_stato                  = ad4_pro_nas.provincia (+)
				  and soggetti.cod_pro_nas                         = ad4_com_nas.provincia_stato (+)
				  and soggetti.cod_com_nas                         = ad4_com_nas.comune (+)
				  
				  and ad4_com_rap.provincia_stato                  = ad4_pro_rap.provincia (+)
				  and soggetti.cod_pro_rap                         = ad4_com_rap.provincia_stato (+)
				  and soggetti.cod_com_rap                         = ad4_com_rap.comune (+)
				  
				  and nvl(pratiche_tributo.stato_accertamento,'D') = 'D' 
				  and CONTRIBUENTI.NI                              = SOGGETTI.NI 
				  and PRATICHE_TRIBUTO.PRATICA                     = RAPPORTI_TRIBUTO.PRATICA
				  and RAPPORTI_TRIBUTO.COD_FISCALE                 = CONTRIBUENTI.COD_FISCALE
				  and sapr.pratica                                 = pratiche_tributo.pratica
				  and sanz.pratica                                 = pratiche_tributo.pratica
				  and ( pratiche_tributo.pratica_rif is null
				      or ( pratiche_tributo.pratica_rif is not null
				          and substr(f_pratica(pratiche_tributo.pratica_rif),1,1) = 'G'
				         )
				       )
				  AND PRATICHE_TRIBUTO.TIPO_PRATICA                in ('A','L')
				  AND CONTRIBUENTI.COD_FISCALE                  like :p_cf
				  AND PRATICHE_TRIBUTO.ANNO                  between :p_anno_da AND :p_anno_a
				  and PRATICHE_TRIBUTO.data_notifica between to_date(:p_data_noti_da, 'dd/mm/yyyy')
				                                     and     to_date(:p_data_noti_a, 'dd/mm/yyyy') 
               	  and nvl(SOGGETTI.nome_ric,'%')                like :p_nome
                  and nvl(SOGGETTI.cognome_ric,'%')             like :p_cognome
				  AND vers.PRAT (+)                                = RAPPORTI_TRIBUTO.PRATICA
				  AND tot_vers.PRAT (+)                            = RAPPORTI_TRIBUTO.PRATICA
				  AND vers.CF (+)                                  = RAPPORTI_TRIBUTO.COD_FISCALE
				  AND tot_vers.CF (+)                              = RAPPORTI_TRIBUTO.COD_FISCALE
				  and (nvl(decode(nvl(titr.flag_tariffa,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                ,'N1',ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'S'),0) 
				                ,ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'S'),2)
				                ),0) 
				       - nvl(tot_vers.i_v60,0) )
				                                                   > decode(dati_generali.fase_euro,1,1000,1)
				  and (nvl(decode(nvl(titr.flag_tariffa,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                ,'N1',ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),0) 
				                ,ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),2)
				                ),0)  
				       - nvl(tot_vers.i_v,0) )
				                                                   > decode(dati_generali.fase_euro,1,1000,1)
				  and (trunc(sysdate) - trunc(PRATICHE_TRIBUTO.DATA_NOTIFICA) )
				                                                   > 60
				  AND nvl(decode(nvl(titr.flag_tariffa,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                ,'N1',ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),0) 
				                ,ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),2)
				                ),0) 
				      - F_ROUND(nvl(vers.i_vtutti,0),1)
				                                                     between :p_imp_da AND :p_imp_a
				  AND nvl(decode(nvl(titr.flag_tariffa,'N')||to_char(sign(trunc(pratiche_tributo.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
				                ,'N1',ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),0) 
				                ,ROUND(f_importo_acc_lordo(pratiche_tributo.pratica,'N'),2)
				                ),0)
				      - F_ROUND(nvl(vers.i_vtutti,0),1)
				                                                     > 0
				  and cata.anno       = PRATICHE_TRIBUTO.anno
				  and PRATICHE_TRIBUTO.tipo_tributo = :p_tipo_tributo
				  and titr.tipo_tributo||''         = :p_tipo_tributo
			"""
            if (filtri.codContribuente) {
                sql += "and CONTRIBUENTI.COD_CONTRIBUENTE = :p_cod_contribuente "
            }
        }

        String sqlResult = """
					select *
					from (${sql})
					where ${finalWhere}
					${sqlSortBy} ni ASC
		"""

        def result = sessionFactory.currentSession.createSQLQuery(sqlResult).with {
            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        // Filtro su tardivi
        if (filtri.soloTardivi) {
            result = result.findAll { it.tardivo > 0 }
        }

        // Filtro su ruolo
        if (filtri.filtroRuolo != "Tutti") {
            if (filtri.filtroRuolo == "Senza") {
                result = result.findAll { it.ruolo == null }
            } else { //Caso 'Con'
                if (filtri.ruolo) {
                    result = result.findAll { it.ruolo == filtri.ruolo.id }
                } else {
                    result = result.findAll { it.ruolo != null }
                }
            }
        }

        // Calcolo dei totali
        def totali = [:]
        if (!ignoraTotali) {
            totali.totalCount = result.size()
            totali.totDovuto = result.sum { it.dovuto ?: 0 }
            totali.totDovutoArr = result.sum { it.dovutoArr ?: 0 }
            totali.totVersato = result.sum { it.versato ?: 0 }
            totali.totTardivo = result.sum { it.tardivo ?: 0 }
            totali.totInsolvenza = (totali.totDovutoArr ?: 0) - (totali.totVersato ?: 0)
        }

        // Paginazione
        result = commonService.getPage(result, paging.activePage, paging.pageSize)

        result.each {
            it.insolvenza = (it.dovutoArr ?: 0) - (it.versato ?: 0)
        }

        return [records: result, totali: totali, totalCount: totali.totalCount]
    }

    def getListaRuoli(TipoTributoDTO tipoTributo, Short anno, Short annoDa = null, Short annoA = null, Boolean specieRuolo = false) {

        return Ruolo.createCriteria().list {
            eq('tipoTributo', tipoTributo.toDomain())
            if (anno) {
                eq('annoRuolo', anno)
            }
            if (annoDa) {
                ge('annoRuolo', annoDa)
            }
            if (annoA) {
                le('annoRuolo', annoA)
            }
            if (specieRuolo != null) {
                eq('specieRuolo', specieRuolo)
            }

            order("tipoRuolo")
            order("annoRuolo")
            order("annoEmissione")
            order("progrEmissione")
            order("dataEmissione")
            order("invioConsorzio")

        }.toDTO()
    }

}
