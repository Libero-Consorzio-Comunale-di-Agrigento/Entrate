--liquibase formatted sql 
--changeset abrandolini:20250326_152401_oggetti_contribuente_anno stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW OGGETTI_CONTRIBUENTE_ANNO
(UTENTE, ANNO, COD_FISCALE, ANNO_OGCO, TIPO_TRIBUTO,
 DES_TIPO_TRIBUTO, TIPO_PRATICA, TIPO_EVENTO, TIPO_RAPPORTO, DATA_DECORRENZA,
 DATA_CESSAZIONE, MESI_POSSESSO, MESI_AB_PRINCIPALE, MESI_ESCLUSIONE, MESI_RIDUZIONE,
 TRIBUTO, CATEGORIA, TIPO_TARIFFA, CONSISTENZA, RENDITA,
 VALORE, OGGETTO, DESCRIZIONE, ID_IMMOBILE, INDIRIZZO,
 DES_VIA, NUM_CIV, SUFFISSO, TIPO_OGGETTO, PARTITA,
 SEZIONE, FOGLIO, NUMERO, SUBALTERNO, ZONA,
 LATITUDINE, LONGITUDINE, ESTREMI_CATASTO, CATEGORIA_CATASTO, CLASSE,
 FLAG_POSSESSO, PERC_POSSESSO, FLAG_ESCLUSIONE, FLAG_RIDUZIONE, FLAG_CONTENZIOSO,
 IMM_STORICO, DATA_CESSAZIONE_OGGE, FLAG_OGGETTO_CESSATO, FLAG_PUNTO_RACCOLTA, FLAG_RFID,
 FLAG_AB_PRINCIPALE, NUMERO_FAMILIARI, PRATICA, OGGETTO_PRATICA, INIZIO_VALIDITA,
 FINE_VALIDITA, INIZIO_VALIDITA_RIOG, FLAG_ALIQUOTE_OGCO, FLAG_UTILIZZI_OGGETTO, FLAG_ANOMALIE,
 FLAG_PERTINENZA_DI, OGGETTO_PRATICA_RIF_AP, FLAG_FAMILIARI, FLAG_ALTRI_CONTRIBUENTI, TIPO_VIOLAZIONE)
AS
select paut.utente
     ,to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                                                                anno
     ,ogco.cod_fiscale
     ,ogco.anno anno_ogco
     ,prtr.tipo_tributo
     ,f_descrizione_titr(prtr.tipo_tributo
    ,prtr.anno
    )
                                                                des_tipo_tributo
     ,prtr.tipo_pratica
     ,prtr.tipo_evento
     ,ogco.tipo_rapporto
     ,ogco.data_decorrenza
     ,ogco.data_cessazione
     ,ogco.mesi_possesso
     ,to_number(null) mesi_ab_principale
     ,ogco.mesi_esclusione
     ,ogco.mesi_riduzione
     ,ogpr.tributo
     ,ogpr.categoria categoria
     ,ogpr.tipo_tariffa
     ,ogpr.consistenza
     ,round(f_rendita(ogpr.valore
                ,nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                ,prtr.anno
                ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                )
    ,2
    )
                                                                rendita
     ,ogpr.valore
     ,ogge.oggetto
     ,ogge.descrizione
     ,ogge.id_immobile
     ,decode(ogge.cod_via
    ,null, indirizzo_localita
    ,denom_uff ||
     decode(num_civ, null, '', ',' || num_civ) ||
     decode(suffisso, null, '', '/' || suffisso) ||
     decode(interno, null, '', ' int. ' || interno)
    )
                                                                indirizzo
     ,decode(ogge.cod_via, null, indirizzo_localita, denom_uff) des_via
     ,to_char(ogge.num_civ) num_civ
     ,ogge.suffisso
     , /*21/01/2015 Betta e Andrea se tarsu visualizziamo il tipo oggetto dell oggetto*/
    decode(prtr.tipo_tributo
        ,'TARSU', ogge.tipo_oggetto
        ,nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
        )
                                                                tipo_oggetto
     ,ogge.partita
     ,ogge.sezione
     ,ogge.foglio
     ,ogge.numero
     ,ogge.subalterno
     ,ogge.zona
     ,ogge.latitudine
     ,ogge.longitudine
     , -- OGGE.ESTREMI_CATASTO,per ora lo costruiamo con lpad,ma sistemeremo i trigger per usare il campo di ogge
        lpad(nvl(ogge.sezione, ' ')
            ,3
            ,' '
            ) ||
        lpad(nvl(ogge.foglio, ' ')
            ,5
            ,' '
            ) ||
        lpad(nvl(ogge.numero, ' ')
            ,5
            ,' '
            ) ||
        lpad(nvl(ogge.subalterno, ' ')
            ,4
            ,' '
            ) ||
        lpad(nvl(ogge.zona, ' ')
            ,3
            ,' '
            )
                                                                estremi_catasto
     ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto) categoria_catasto
     ,nvl(ogpr.classe_catasto, ogge.classe_catasto) classe
     ,decode(prtr.tipo_tributo
    ,'ICI', flag_possesso
    ,'TASI', flag_possesso
    ,null
    )
                                                                flag_possesso
     ,ogco.perc_possesso
     ,ogco.flag_esclusione
     ,ogco.flag_riduzione
     ,ogpr.flag_contenzioso
     ,ogpr.imm_storico
     ,ogge.data_cessazione data_cessazione_ogge
     ,decode(ogge.data_cessazione, null, null, 'S') flag_oggetto_cessato
     ,ogco.flag_punto_raccolta
     ,f_conta_rfid(ogco.cod_fiscale,ogge.oggetto) flag_rfid
     ,ogco.flag_ab_principale
     ,f_get_num_fam_cosu(ogpr.oggetto_pratica
    ,ogco.flag_ab_principale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,to_number(null)
    )
                                                                numero_familiari
     ,prtr.pratica
     ,ogpr.oggetto_pratica
     ,to_date(null) inizio_validita
     ,to_date(null) fine_validita
     ,to_date(null) inizio_validita_riog
     ,'' flag_aliquote_ogco
     ,'' flag_utilizzi_oggetto
     ,'' flag_anomalie
     ,'' flag_pertinenza_di
     ,to_number(null) oggetto_pratica_rif_ap
     ,to_number(null) flag_familiari
     ,'' flag_altri_contribuenti
     ,prtr.tipo_violazione tipo_violazione
from archivio_vie arvi
   ,oggetti ogge
   ,pratiche_tributo prtr
   ,oggetti_pratica ogpr
   ,oggetti_contribuente ogco
   ,ad4_utenti paut
where arvi.cod_via(+) = ogge.cod_via
  and prtr.pratica = ogpr.pratica
  and ogge.oggetto = ogpr.oggetto
  and ogpr.oggetto_pratica = ogco.oggetto_pratica
  and prtr.tipo_pratica in ('A', 'D', 'L')
  and prtr.flag_annullamento is null
  and nvl(to_number(to_char(ogco.data_decorrenza
    ,'YYYY'
    ))
          ,nvl(ogco.anno, 0)
          ) <= (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                from dual)
    /* inserita il 22/10/2003 la decode per risolvere per anno 9999
       da controllare e verifica re per D e A < anno
       e A con flag_possesso is null */
  and ogpr.oggetto_pratica =
      f_max_ogpr_cont_ogge(ogge.oggetto
          ,ogco.cod_fiscale
          ,prtr.tipo_tributo
          ,decode(to_number(f_paut_valore(paut.utente
          ,'SIT_CONTR'
          ,'annoOggetti'
          ))
                               ,9999, '%'
                               ,prtr.tipo_pratica
                               )
          ,to_number(f_paut_valore(paut.utente
          ,'SIT_CONTR'
          ,'annoOggetti'
          ))
          ,'%
                             '
          )
  and decode(prtr.tipo_tributo
          ,'ICI', decode(flag_possesso
                 ,'S', flag_possesso
                 ,decode(to_number(f_paut_valore(paut.utente
                    ,'SIT_CONTR'
                    ,'annoOggetti'
                    ))
                             ,9999, 'S'
                             ,prtr.anno, 'S'
                             ,null
                             )
                 )
          ,'S'
          ) = 'S'
  and (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
       from dual) = 9999
--      or  prtr.tipo_tributo not in ('ICI', 'TASI', 'TARSU'))
union
select paut.utente
     ,to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                                                                anno
     ,wrkp.cod_fiscale
     ,wrkp.anno
     ,wrkp.tipo_tributo
     ,f_descrizione_titr(wrkp.tipo_tributo
    ,wrkp.anno
    )
                                                                descr_tipo_tributo
     ,wrkp.tipo_pratica
     ,wrkp.tipo_evento
     ,wrkp.tipo_rapporto
     ,wrkp.data_decorrenza
     ,wrkp.data_cessazione
     ,f_get_mesi_possesso(wrkp.tipo_tributo
    ,wrkp.cod_fiscale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,ogge.oggetto
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                mesi_possesso
     ,f_get_mesi_ab_princ(wrkp.tipo_tributo
    ,wrkp.cod_fiscale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto_pratica
    ,wrkp.flag_ab_principale
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                mesi_ab_princ
    ,decode(to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
          , wrkp.anno, wrkp.mesi_esclusione
          , '')                                                 mesi_esclusione
    ,decode(to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
          , wrkp.anno, wrkp.mesi_riduzione
          , '')                                                 mesi_riduzione
     ,wrkp.tributo
     ,wrkp.categoria_ogpr
     ,wrkp.tipo_tariffa
     ,wrkp.consistenza
     ,decode(f_rendita_data_riog(ogge.oggetto
                 ,wrkp.inizio_validita
                 )
    ,null, round(f_rendita(wrkp.valore
                     ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto)
                     ,wrkp.anno
                     ,nvl(wrkp.categoria_catasto, ogge.categoria_catasto)
                     )
                 ,2
                 )
    ,f_rendita_data_riog(ogge.oggetto
                 ,wrkp.inizio_validita
                 )
    )
                                                                rendita
     ,decode(f_rendita_data_riog(ogge.oggetto
                 ,wrkp.inizio_validita
                 )
    ,null, f_valore(wrkp.valore
                 ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto)
                 ,wrkp.anno
                 ,to_number(f_paut_valore(paut.utente
                    ,'SIT_CONTR'
                    ,'annoOggetti'
                    ))
                 ,nvl(wrkp.categoria_catasto
                        ,ogge.categoria_catasto
                        )
                 ,wrkp.tipo_pratica
                 ,'S'
                 )
    ,f_valore_da_rendita(f_rendita_data_riog(ogge.oggetto
                             ,wrkp.inizio_validita
                             )
                 ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto)
                 ,to_number(f_paut_valore(paut.utente
                    ,'SIT_CONTR'
                    ,'annoOggetti'
                    ))       --wrkp.anno
                 ,nvl(wrkp.categoria_catasto
                             ,ogge.categoria_catasto
                             )
                 ,wrkp.imm_storico
                 )
    )
                                                                valore
     ,ogge.oggetto
     ,ogge.descrizione
     ,ogge.id_immobile
     ,decode(ogge.cod_via
    ,null, indirizzo_localita
    ,denom_uff ||
     decode(num_civ, null, '', ',' || num_civ) ||
     decode(suffisso, null, '', '/' || suffisso) ||
     decode(interno, null, '', ' int. ' || interno)
    )
                                                                indir
     ,decode(ogge.cod_via, null, indirizzo_localita, denom_uff) indirizzo
     ,to_char(ogge.num_civ) num_civ
     ,ogge.suffisso suff
     ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto) tipo_oggetto
     ,ogge.partita
     ,ogge.sezione
     ,ogge.foglio
     ,ogge.numero
     ,ogge.subalterno
     ,ogge.zona
     ,ogge.latitudine
     ,ogge.longitudine
     ,lpad(nvl(ogge.sezione, ' ')
          ,3
          ,' '
          ) ||
      lpad(nvl(ogge.foglio, ' ')
          ,5
          ,' '
          ) ||
      lpad(nvl(ogge.numero, ' ')
          ,5
          ,' '
          ) ||
      lpad(nvl(ogge.subalterno, ' ')
          ,4
          ,' '
          ) ||
      lpad(nvl(ogge.zona, ' ')
          ,3
          ,' '
          )
                                                                estremi_catasto
     ,coalesce(f_get_riog_data(wrkp.oggetto
                   ,wrkp.inizio_validita
                   ,'CA'
                   )
    ,wrkp.categoria_catasto
    ,ogge.categoria_catasto
    )
                                                                categoria
     ,coalesce(f_get_riog_data(wrkp.oggetto
                   ,wrkp.inizio_validita
                   ,'CL'
                   )
    ,wrkp.classe_catasto
    ,ogge.classe_catasto
    )
                                                                classe
     ,case
          when wrkp.fine_validita >= to_date('31/12' ||
                                             to_number(f_paut_valore(paut.utente
                                                 ,'SIT_CONTR'
                                                 ,'annoOggetti'
                                                 ))
              ,'dd/mm/yyyy'
              ) then wrkp.flag_possesso
          else null
    end
                                                                flag_p
     --      ,WRKP.flag_possesso FLAG_P
     ,wrkp.perc_possesso
     ,wrkp.flag_esclusione
     ,wrkp.flag_riduzione
     ,wrkp.flag_contenzioso
     ,wrkp.imm_storico
     ,ogge.data_cessazione
     ,decode(ogge.data_cessazione, null, null, 'S') flag_oggetto_cessato
     ,null flag_punto_raccolta
     ,f_conta_rfid(wrkp.cod_fiscale,ogge.oggetto) flag_rfid
     ,decode(wrkp.flag_ab_principale
    ,null, decode(wrkp.oggetto_pratica_rif_ap
                 ,null, wrkp.flag_ab_principale
                 ,f_get_ab_principale(wrkp.cod_fiscale
                      ,wrkp.anno
                      ,wrkp.oggetto_pratica_rif_ap
                      )
                 )
    ,wrkp.flag_ab_principale
    )
                                                                flag_ab_principale
     ,f_get_num_fam_cosu(wrkp.oggetto_pratica
    ,wrkp.flag_ab_principale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,to_number(null)
    )
                                                                numero_familiari
     ,wrkp.pratica
     ,wrkp.oggetto_pratica
     ,wrkp.inizio_validita inizio_validita
     ,wrkp.fine_validita fine_validita
     ,wrkp.inizio_validita_riog
     ,f_conta_aliquote_ogco(wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.cod_fiscale
    ,wrkp.oggetto_pratica
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                flag_aliq_ogco
     ,f_conta_utilizzi_oggetto(wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                flag_util_ogge
     ,f_conta_anomalie(wrkp.cod_fiscale
    -- , wrkp.anno
    ,f_paut_valore(paut.utente
                           ,'SIT_CONTR'
                           ,'annoOggetti'
                           )
    ,wrkp.oggetto_pratica
    ,wrkp.oggetto
    )
                                                                flag_anomalie
     ,wrkp.flag_pertinenza_di
     ,wrkp.oggetto_pratica_rif_ap
     ,to_number(null) flag_familiari
     ,f_conta_altri_contribuenti(wrkp.cod_fiscale
    ,wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto
    ) flag_altri_contribuenti
     ,wrkp.tipo_violazione
from archivio_vie arvi
   ,oggetti ogge
   ,periodi_ogco_riog wrkp
   ,ad4_utenti paut
where arvi.cod_via(+) = ogge.cod_via
  and ogge.oggetto = wrkp.oggetto
  and wrkp.inizio_validita <= (select to_date('3112' ||
                                              to_number(f_paut_valore(paut.utente
                                                  ,'SIT_CONTR'
                                                  ,'annoOggetti'
                                                  ))
                                          ,'ddmmyyyy'
                                          )
                               from dual)
  and wrkp.fine_validita >= (select to_date('0101' ||
                                            to_number(f_paut_valore(paut.utente
                                                ,'SIT_CONTR'
                                                ,'annoOggetti'
                                                ))
                                        ,'ddmmyyyy'
                                        )
                             from dual)
  and nvl(to_number(to_char(wrkp.data_decorrenza
    ,'YYYY'
    ))
          ,nvl(wrkp.anno, 0)
          ) <= (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                from dual)
  and (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
       from dual) <> 9999
  and wrkp.tipo_tributo in ('ICI', 'TASI')
union
select paut.utente
     ,to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                                                                anno
     ,wrkp.cod_fiscale
     ,wrkp.anno
     ,wrkp.tipo_tributo
     ,f_descrizione_titr(wrkp.tipo_tributo
    ,wrkp.anno
    )
                                                                descr_tipo_tributo
     ,wrkp.tipo_pratica
     ,wrkp.tipo_evento
     ,wrkp.tipo_rapporto
     ,wrkp.data_decorrenza
     ,wrkp.data_cessazione
     ,f_get_mesi_possesso(wrkp.tipo_tributo
    ,wrkp.cod_fiscale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,ogge.oggetto
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                mesi_possesso
     ,f_get_mesi_ab_princ(wrkp.tipo_tributo
    ,wrkp.cod_fiscale
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto_pratica
    ,wrkp.flag_ab_principale
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                mesi_ab_princ
    ,to_number('')                                              mesi_esclusione
    ,to_number('')                                              mesi_riduzione
     ,wrkp.tributo
     ,wrkp.categoria_ogpr
     ,wrkp.tipo_tariffa
     ,wrkp.consistenza
     , /*decode (
          f_rendita_data_riog (ogge.oggetto, wrkp.inizio_validita)
        , null, round (
                 f_rendita (
                  wrkp.valore
                , nvl (wrkp.tipo_oggetto, ogge.tipo_oggetto)
                , wrkp.anno
                , nvl (wrkp.categoria_catasto, ogge.categoria_catasto))
               , 2)
        , f_rendita_data_riog (ogge.oggetto, wrkp.inizio_validita)) */
    to_number(null) rendita
     , /*decode (
          f_rendita_data_riog (ogge.oggetto, wrkp.inizio_validita)
        , null, f_valore (
                 wrkp.valore
               , nvl (wrkp.tipo_oggetto, ogge.tipo_oggetto)
               , wrkp.anno
               , to_number (
                  f_paut_valore (paut.utente, 'SIT_CONTR', 'annoOggetti'))
               , nvl (wrkp.categoria_catasto, ogge.categoria_catasto)
               , wrkp.tipo_pratica
               , 'S')
        , f_valore_da_rendita (
           f_rendita_data_riog (ogge.oggetto, wrkp.inizio_validita)
         , nvl (wrkp.tipo_oggetto, ogge.tipo_oggetto)
         , to_number (f_paut_valore (paut.utente, 'SIT_CONTR', 'annoOggetti')) --wrkp.anno
         , nvl (wrkp.categoria_catasto, ogge.categoria_catasto)
         , wrkp.imm_storico)) */
    to_number(null) valore
     ,ogge.oggetto
     ,ogge.descrizione
     ,ogge.id_immobile
     ,decode(ogge.cod_via
    ,null, indirizzo_localita
    ,denom_uff ||
     decode(num_civ, null, '', ',' || num_civ) ||
     decode(suffisso, null, '', '/' || suffisso) ||
     decode(interno, null, '', ' int. ' || interno)
    )
                                                                indir
     ,decode(ogge.cod_via, null, indirizzo_localita, denom_uff) indirizzo
     ,to_char(ogge.num_civ) num_civ
     ,ogge.suffisso suff
     ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto) tipo_oggetto
     ,ogge.partita
     ,ogge.sezione
     ,ogge.foglio
     ,ogge.numero
     ,ogge.subalterno
     ,ogge.zona
     ,ogge.latitudine
     ,ogge.longitudine
     ,lpad(nvl(ogge.sezione, ' ')
          ,3
          ,' '
          ) ||
      lpad(nvl(ogge.foglio, ' ')
          ,5
          ,' '
          ) ||
      lpad(nvl(ogge.numero, ' ')
          ,5
          ,' '
          ) ||
      lpad(nvl(ogge.subalterno, ' ')
          ,4
          ,' '
          ) ||
      lpad(nvl(ogge.zona, ' ')
          ,3
          ,' '
          )
                                                                estremi_catasto
     ,coalesce(f_get_riog_data(wrkp.oggetto
                   ,wrkp.inizio_validita
                   ,'CA'
                   )
    ,wrkp.categoria_catasto
    ,ogge.categoria_catasto
    )
                                                                categoria
     ,coalesce(f_get_riog_data(wrkp.oggetto
                   ,wrkp.inizio_validita
                   ,'CL'
                   )
    ,wrkp.classe_catasto
    ,ogge.classe_catasto
    )
                                                                classe
     ,case
          when wrkp.fine_validita >= to_date('31/12' ||
                                             to_number(f_paut_valore(paut.utente
                                                 ,'SIT_CONTR'
                                                 ,'annoOggetti'
                                                 ))
              ,'dd/mm/yyyy'
              ) then wrkp.flag_possesso
          else null
    end
                                                                flag_p
     --      ,WRKP.flag_possesso FLAG_P
     ,wrkp.perc_possesso
     ,wrkp.flag_esclusione
     ,wrkp.flag_riduzione
     ,wrkp.flag_contenzioso
     ,wrkp.imm_storico
     ,ogge.data_cessazione
     ,decode(ogge.data_cessazione, null, null, 'S') oggetto_cessato
     ,wrkp.flag_punto_raccolta
     ,f_conta_rfid(wrkp.cod_fiscale, ogge.oggetto) flag_rfid
     ,decode(wrkp.flag_ab_principale
    ,null, decode(wrkp.oggetto_pratica_rif_ap
                 ,null, wrkp.flag_ab_principale
                 ,f_get_ab_principale(wrkp.cod_fiscale
                      ,wrkp.anno
                      ,wrkp.oggetto_pratica_rif_ap
                      )
                 )
    ,wrkp.flag_ab_principale
    )
                                                                flag_ab_principale
     ,f_get_num_fam_cosu(wrkp.oggetto_pratica
    ,decode(wrkp.flag_ab_principale
                             ,null, decode(wrkp.oggetto_pratica_rif_ap
                ,null, wrkp.flag_ab_principale
                ,f_get_ab_principale(wrkp.cod_fiscale
                                               ,wrkp.anno
                                               ,wrkp.oggetto_pratica_rif_ap
                                               )
                )
                             ,wrkp.flag_ab_principale
                             )
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,to_number(null)
    )
                                                                numero_familiari
     ,wrkp.pratica
     ,wrkp.oggetto_pratica
     ,wrkp.inizio_validita inizio_validita
     ,wrkp.fine_validita fine_validita
     ,to_date(null) inizio_validita_riog
     ,f_conta_aliquote_ogco(wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.cod_fiscale
    ,wrkp.oggetto_pratica
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                flag_aliq_ogco
     ,f_conta_utilizzi_oggetto(wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto
    ,wrkp.inizio_validita
    ,wrkp.fine_validita
    )
                                                                flag_util_ogge
     ,f_conta_anomalie(wrkp.cod_fiscale
    -- , wrkp.anno
    ,f_paut_valore(paut.utente
                           ,'SIT_CONTR'
                           ,'annoOggetti'
                           )
    ,wrkp.oggetto_pratica
    ,wrkp.oggetto
    )
                                                                flag_anomalie
     ,wrkp.flag_pertinenza_di
     ,wrkp.oggetto_pratica_rif_ap
     ,decode(decode(wrkp.flag_ab_principale
                 ,null, decode(wrkp.oggetto_pratica_rif_ap
                        ,null, wrkp.flag_ab_principale
                        ,f_get_ab_principale(wrkp.cod_fiscale
                                   ,wrkp.anno
                                   ,wrkp.oggetto_pratica_rif_ap
                                   )
                        )
                 ,wrkp.flag_ab_principale
                 )
    ,'S', f_conta_familiari_soggetto(wrkp.cod_fiscale
                 ,f_paut_valore(paut.utente
                                         ,'SIT_CONTR'
                                         ,'annoOggetti'
                                         )
                 )
    ,to_number(null)
    )
                                                                flag_familiari
     ,f_conta_altri_contribuenti(wrkp.cod_fiscale
    ,wrkp.tipo_tributo
    ,to_number(f_paut_valore(paut.utente
            ,'SIT_CONTR'
            ,'annoOggetti'
            ))
    ,wrkp.oggetto
    ) flag_altri_contribuenti
     ,wrkp.tipo_violazione
from archivio_vie arvi
   ,oggetti ogge
   ,periodi_ogco_tarsu_trmi wrkp
   ,ad4_utenti paut
where arvi.cod_via(+) = ogge.cod_via
  and ogge.oggetto = wrkp.oggetto
  and nvl(wrkp.inizio_validita
          ,to_date('01011900'
              ,'ddmmyyyy'
              )
          ) <= (select to_date('3112' ||
                               to_number(f_paut_valore(paut.utente
                                   ,'SIT_CONTR'
                                   ,'annoOggetti'
                                   ))
                           ,'ddmmyyyy'
                           )
                from dual)
  and nvl(wrkp.fine_validita
          ,to_date('31129999'
              ,'ddmmyyyy'
              )
          ) >= (select to_date('0101' ||
                               to_number(f_paut_valore(paut.utente
                                   ,'SIT_CONTR'
                                   ,'annoOggetti'
                                   ))
                           ,'ddmmyyyy'
                           )
                from dual)
  and nvl(to_number(to_char(wrkp.data_decorrenza
    ,'YYYY'
    ))
          ,nvl(wrkp.anno, 0)
          ) <= (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
                from dual)
  and (select to_number(f_paut_valore(paut.utente
    ,'SIT_CONTR'
    ,'annoOggetti'
    ))
       from dual) <> 9999
  and wrkp.tipo_tributo in ('TARSU','TOSAP','ICP','CUNI')
;

