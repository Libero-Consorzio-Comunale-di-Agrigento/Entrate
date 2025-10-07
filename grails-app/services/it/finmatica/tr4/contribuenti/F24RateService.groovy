package it.finmatica.tr4.contribuenti

import grails.transaction.Transactional
import org.hibernate.transform.AliasToEntityMapResultTransformer

@Transactional
class F24RateService {

    def sessionFactory

    private String f24Query() {

        String f24RateSQL =
                """
			select righe_f24.*,
			       F_STAMPA_RATEAZIONE_F24(righe_f24.ord3,
			                               righe_f24.ord2,
			                               righe_f24.cotr_riga_1,
			                               righe_f24.rata,
			                               righe_f24.tot_rate,
			                               'S') rateazione_riga_1,
			       F_STAMPA_RATEAZIONE_F24(righe_f24.ord3,
			                               righe_f24.ord2,
			                               righe_f24.cotr_riga_2,
			                               righe_f24.rata,
			                               righe_f24.tot_rate,
			                               'S') rateazione_riga_2,
			       F_STAMPA_RATEAZIONE_F24(righe_f24.ord3,
			                               righe_f24.ord2,
			                               righe_f24.cotr_riga_3,
			                               righe_f24.rata,
			                               righe_f24.tot_rate,
			                               'S') rateazione_riga_3,
			       F_STAMPA_RATEAZIONE_F24(righe_f24.ord3,
			                               righe_f24.ord2,
			                               righe_f24.cotr_riga_4,
			                               righe_f24.rata,
			                               righe_f24.tot_rate,
			                               'S') rateazione_riga_4
			  from (select decode('C',
			              'C',
			              contribuenti.cod_fiscale,
			              soggetti.cognome_nome || contribuenti.cod_fiscale) ord1,
			       prtr.anno ord2,
			       prtr.tipo_tributo ord3,
			       prtr.pratica ord4,
			       rtpr.rata ord5,
			       contribuenti.cod_fiscale,
			       translate(soggetti.cognome_nome, '/', ' ') csoggnome,
			       ad4_comuni_b.denominazione comune_nas,
			       ad4_provincie_b.sigla provincia_nas,
			       soggetti.sesso sesso,
			       soggetti.cognome cognome,
			       soggetti.nome nome,
			       to_char(soggetti.data_nas, 'yyyy') anno_nascita,
			       to_char(soggetti.data_nas, 'mm') mese_nascita,
			       to_char(soggetti.data_nas, 'dd') giorno_nascita,
			       to_char(prtr.anno) anno,
			       rtpr.quota_imposta_rata importo_riga_1,
			       rtpr.quota_tefa_rata importo_riga_2,
			       rtpr.quota_capitale_rata importo_riga_3,
			       rtpr.quota_interessi_rata importo_riga_4,
			       decode(nvl(rtpr.quota_imposta_rata, 0),
			              0,
			              to_char(null),
			              to_char(rtpr.tributo_imposta_f24)) cotr_riga_1,
			       decode(nvl(rtpr.quota_tefa_rata, 0),
			              0,
			              to_char(null),
			              to_char(rtpr.tributo_tefa_f24)) cotr_riga_2,
			       decode(nvl(rtpr.quota_capitale_rata, 0),
			              0,
			              to_char(null),
			              to_char(rtpr.tributo_capitale_f24)) cotr_riga_3,
			       decode(nvl(rtpr.quota_interessi_rata, 0),
			              0,
			              to_char(null),
			              to_char(rtpr.tributo_interessi_f24)) cotr_riga_4,
			       decode(nvl(nvl(prtr.importo_rate, rtpr.importo_rata), 0),
			              0,
			              to_number(null),
			              trunc(nvl(prtr.importo_rate, rtpr.importo_rata))) totale_f24,
			       substr(lpad(to_char((nvl(prtr.importo_rate, rtpr.importo_rata) -
			                           trunc(nvl(prtr.importo_rate, rtpr.importo_rata))) * 100),
			                   2,
			                   '0'),
			              1,
			              1) dec1_totale_f24,
			       substr(lpad(to_char((nvl(prtr.importo_rate, rtpr.importo_rata) -
			                           trunc(nvl(prtr.importo_rate, rtpr.importo_rata))) * 100),
			                   2,
			                   '0'),
			              2,
			              1) dec2_totale_f24,
			       decode(dage.flag_provincia,
			              'S',
			              rpad(ad4_provincie_c.sigla, 4),
			              ad4_comuni_c.sigla_cfis) codice_comune,
			       decode(to_number(to_char(sysdate, 'yyyy')),
			              to_number(to_char(prtr.anno, '9999')),
			              to_char(null),
			              'X') anno_imposta_diverso_solare,
			       f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
			       ' ' ravvedimento,
			       rtpr.rata rata,
			       max(rtpr.rata) over() tot_rate,
			       decode(prtr.tipo_pratica,
			              'L',
			              'LIQP',
			              'A',
			              'ACC' || decode(prtr.tipo_tributo,
			                              'ICI',
			                              decode(prtr.tipo_evento, 'T', 'T', 'P'),
			                              nvl(prtr.tipo_evento, 'U')),
			              '') || rpad(to_char(prtr.anno), 4, '0') ||
			       lpad(to_char(rtpr.rata), 2, '0') ||
			       lpad(to_char(prtr.pratica), 8, '0') identificativo_operazione
			  from soggetti,
			       contribuenti,
			       ad4_comuni       ad4_comuni_b,
			       ad4_provincie    ad4_provincie_b,
			       dati_generali    dage,
			       ad4_comuni       ad4_comuni_c,
			       ad4_provincie    ad4_provincie_c,
			       pratiche_tributo prtr,
			       (select
						  decode(rate_f24_a,'S',nvl(rtpr2.importo_arr,rtpr2.importo_calcolato_arr), nvl(rtpr2.importo,rtpr2.importo_calcolato)) importo_rata,
						  decode(rate_f24_a,'S',nvl(rtpr2.importo_arr,rtpr2.importo_calcolato_arr) -
						                         round(rtpr2.quota_tefa_rata,0) - 
						                         round(rtpr2.quota_capitale_rata,0) - 
						                         round(rtpr2.quota_interessi_rata,0),
						                        nvl(rtpr2.quota_imposta_rata,
						                         nvl(rtpr2.importo,rtpr2.importo_calcolato) -
						                          rtpr2.quota_tefa_rata - 
						                          rtpr2.quota_capitale_rata - 
						                          rtpr2.quota_interessi_rata)
												) as quota_imposta_rata,
			              decode(rate_f24_a,'S',round(rtpr2.quota_tefa_rata,0),rtpr2.quota_tefa_rata) as quota_tefa_rata,
			              decode(rate_f24_a,'S',round(rtpr2.quota_capitale_rata,0),rtpr2.quota_capitale_rata) as quota_capitale_rata,
			              decode(rate_f24_a,'S',round(rtpr2.quota_interessi_rata,0),rtpr2.quota_interessi_rata) as quota_interessi_rata,
			              rtpr2.pratica pratica,
			              rtpr2.rata rata,
			              rtpr2.importo_capitale importo_capitale,
			              rtpr2.importo_interessi importo_interessi,
			              rtpr2.tributo_imposta_f24 tributo_imposta_f24,
			              rtpr2.tributo_tefa_f24 tributo_tefa_f24,
			              rtpr2.tributo_interessi_f24 tributo_interessi_f24,
			              rtpr2.tributo_capitale_f24 tributo_capitale_f24
			        from
			           (select 
	                      nvl(rtpr1.importo_capitale, 0) + 
	                        nvl(rtpr1.importo_interessi, 0) +
	                        coalesce(rtpr1.aggio_rimodulato, rtpr1.aggio, 0) +
	                        coalesce(rtpr1.dilazione_rimodulata, rtpr1.dilazione, 0) +
	                        nvl(rtpr1.oneri, 0) as importo_calcolato,
	                      round(nvl(rtpr1.importo_capitale, 0) + 
	                        nvl(rtpr1.importo_interessi, 0) +
	                        coalesce(rtpr1.aggio_rimodulato, rtpr1.aggio, 0) +
	                        coalesce(rtpr1.dilazione_rimodulata, rtpr1.dilazione, 0) +
	                        nvl(rtpr1.oneri, 0), 0) as importo_calcolato_arr,
			              nvl(rtpr1.quota_tassa, 0) quota_imposta_rata,
			              nvl(rtpr1.quota_tefa, 0) quota_tefa_rata,
			              decode(rtpr1.quota_tassa, '', nvl(rtpr1.importo_capitale, 0), 0) + 
			                     nvl(rtpr1.oneri, 0) + coalesce(rtpr1.aggio_rimodulato, rtpr1.aggio, 0) quota_capitale_rata,
			              nvl(rtpr1.importo_interessi, 0) + coalesce(rtpr1.dilazione_rimodulata, rtpr1.dilazione, 0) quota_interessi_rata,
			              inpa.rate_f24_a,
			              rtpr1.*
			           from
			              rate_pratica rtpr1,
			              (select decode(prtr1.importo_rate,
                                              null,
                                              f_inpa_valore('RATE_F24_A'),
                                              null) rate_f24_a
                                  from pratiche_tributo prtr1
                                 where prtr1.pratica = :pPratica) inpa
			            where
			              rtpr1.pratica = :pPratica
			            ) rtpr2
			      ) rtpr
			 where ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
			   and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
			   and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
			   and dage.pro_cliente = ad4_comuni_c.provincia_stato
			   and dage.com_cliente = ad4_comuni_c.comune
			   and ad4_comuni_c.provincia_stato = ad4_provincie_c.provincia
			   and contribuenti.ni = soggetti.ni
			   and rtpr.pratica = prtr.pratica
			   and prtr.cod_fiscale = contribuenti.cod_fiscale
			   and prtr.pratica = :pPratica
			   and (round(rtpr.importo_capitale) > 0 or
			       round(rtpr.importo_interessi) > 0)) righe_f24
			order by righe_f24.ord5
        """

        return f24RateSQL

    }

    def f24RateDettaglio(Long pratica) {

        // Recupero del tributo
        String sql = f24Query()

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def dettagli = sqlQuery.with {
            setParameter('pPratica',pratica)
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        return !dettagli.empty ? dettagli : null

    }
}
