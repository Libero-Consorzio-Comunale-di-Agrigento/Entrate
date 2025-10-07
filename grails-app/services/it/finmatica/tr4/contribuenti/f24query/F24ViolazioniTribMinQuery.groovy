package it.finmatica.tr4.contribuenti.f24query

class F24ViolazioniTribMinQuery {

    static def query(def tipoTributo) {
        return """
            select 
               '${tipoTributo}' as tributo, 
               contribuenti.cod_fiscale,
               translate(soggetti.cognome_nome, '/', ' ') csoggnome,
               decode(soggetti.cod_via,
                      null,
                      soggetti.denominazione_via,
                      archivio_vie.denom_uff) ind,
               soggetti.num_civ num_civ,
               soggetti.suffisso suff,
               decode(soggetti.cod_via,
                      null,
                      soggetti.denominazione_via,
                      archivio_vie.denom_uff) ||
               decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
               decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) indirizzo_dich,
               ad4_comuni_a.denominazione comune,
               ad4_provincie_a.sigla provincia,
               ad4_comuni_b.denominazione comune_nas,
               ad4_provincie_b.sigla provincia_nas,
               soggetti.sesso sesso,
               soggetti.cognome cognome,
               soggetti.nome nome,
               to_char(soggetti.data_nas, 'yyyy') anno_nascita,
               to_char(soggetti.data_nas, 'mm') mese_nascita,
               to_char(soggetti.data_nas, 'dd') giorno_nascita,
               to_char(prtr.anno, '9999') anno,
               to_number(substr(f_f24_viol_tributi_minori(1,
                                                          prtr.tipo_tributo,
                                                          prtr.anno,
                                                          prtr.pratica,
                                                          :pImportoRidotto),
                                5,
                                10)) importo_riga_1,
               to_number(substr(f_f24_viol_tributi_minori(2,
                                                          prtr.tipo_tributo,
                                                          prtr.anno,
                                                          prtr.pratica,
                                                          :pImportoRidotto),
                                5,
                                10)) importo_riga_2,
               to_number(substr(f_f24_viol_tributi_minori(3,
                                                          prtr.tipo_tributo,
                                                          prtr.anno,
                                                          prtr.pratica,
                                                          :pImportoRidotto),
                                5,
                                10)) importo_riga_3,
               to_number(substr(f_f24_viol_tributi_minori(4,
                                                          prtr.tipo_tributo,
                                                          prtr.anno,
                                                          prtr.pratica,
                                                          :pImportoRidotto),
                                5,
                                10)) importo_riga_4,
               substr(f_f24_viol_tributi_minori(1,
                                                prtr.tipo_tributo,
                                                prtr.anno,
                                                prtr.pratica,
                                                :pImportoRidotto),
                      1,
                      4) cotr_riga_1,
               substr(f_f24_viol_tributi_minori(2,
                                                prtr.tipo_tributo,
                                                prtr.anno,
                                                prtr.pratica,
                                                :pImportoRidotto),
                      1,
                      4) cotr_riga_2,
               substr(f_f24_viol_tributi_minori(3,
                                                prtr.tipo_tributo,
                                                prtr.anno,
                                                prtr.pratica,
                                                :pImportoRidotto),
                      1,
                      4) cotr_riga_3,
               substr(f_f24_viol_tributi_minori(4,
                                                prtr.tipo_tributo,
                                                prtr.anno,
                                                prtr.pratica,
                                                :pImportoRidotto),
                      1,
                      4) cotr_riga_4,
               ' ' acconto,
               ' ' saldo,
               ad4_comuni_c.sigla_cfis codice_comune,
               decode(to_number(to_char(sysdate, 'yyyy')),
                      to_number(to_char(prtr.anno, '9999')),
                      '',
                      'X') anno_imposta_diverso_solare,
               f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
               'ACC' || decode(prtr.tipo_evento, 'T', 'T', 'P') ||
               to_char(prtr.anno) || lpad(to_char(prtr.pratica), 10, '0') identificativo_operazione
          from ad4_comuni       ad4_comuni_a,
               ad4_provincie    ad4_provincie_a,
               archivio_vie,
               soggetti,
               contribuenti,
               ad4_comuni       ad4_comuni_b,
               ad4_provincie    ad4_provincie_b,
               dati_generali    dage,
               ad4_comuni       ad4_comuni_c,
               pratiche_tributo prtr
         where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
           and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
           and soggetti.cod_com_res = ad4_comuni_a.comune(+)
           and soggetti.cod_via = archivio_vie.cod_via(+)
           and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
           and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
           and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
           and soggetti.cod_via = archivio_vie.cod_via(+)
           and dage.pro_cliente = ad4_comuni_c.provincia_stato
           and dage.com_cliente = ad4_comuni_c.comune
           and contribuenti.ni = soggetti.ni
           and contribuenti.cod_fiscale = prtr.cod_fiscale
           and prtr.cod_fiscale = :pCodFiscale
           and prtr.pratica = :pPratica
        """
    }

}
