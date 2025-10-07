--liquibase formatted sql 
--changeset abrandolini:20250326_152401_servizi_ctr stripComments:false runOnChange:true 
 
create or replace force view servizi_ctr as
select 'SERVIZI_CONT_SOLO_VERS' fonte
   , --   decode (max(F_CONT_OGGE_CATA ( VERS.ANNO,vers.tipo_tributo,cont.COD_FISCALE)),
  --  0,'Contribuente con solo versamento Sconosciuto a catasto','Contribuente con solo versamento Presente a catasto')
 ' ' segnalazione
   ,max(sogg.cognome_nome) ragionesociale
   ,cont.cod_fiscale codicefiscale
   ,vers.anno anno
   ,to_number(null) numoggetti
   ,to_number(null) numfabbricati
   ,to_number(null) numterreni
   ,to_number(null) numaree
--   , --   decode(vers.tipo_tributo,'ICI',0
--  --  - nvl(F_TOT_VERS (vers.anno, 'ICI', CONT.COD_FISCALE),0),0)
-- 0 differenza_imu
--   ,0 -
-- nvl(supporto_servizi_pkg.f_serv_tot_vers(vers.anno
--     ,'TASI'
--     ,cont.cod_fiscale
--     )
-- ,0
-- )
--  differenza_imposta_tasi
   ,0 differenza_imposta
   , /*max(decode(decode(sogg.tipo_residente
   ,0, f_ult_eve_al(sogg.matricola
    ,to_number(to_char(to_date('0101' || to_char(vers.anno)
      ,'ddmmyyyy'
      )
    ,'J'
    ))
    ,'FASCIA'
    )
   ,null
   )
  ,1, 'RESIDENTE'
  )) */
 null res_storico_gsd_inizio_anno
   , /*max(decode(decode(sogg.tipo_residente
    ,0, f_ult_eve_al(sogg.matricola
     ,to_number(to_char(to_date('3112' || to_char(vers.anno)
       ,'ddmmyyyy'
       )
     ,'J'
     ))
     ,'FASCIA'
     )
    ,null
    )
   ,1, 'RESIDENTE'
   ))*/
 null res_storico_gsd_fine_anno
   , /*max(to_date(decode(sogg.tipo_residente
  ,0, f_ult_eve_al(sogg.matricola
   ,to_number(to_char(to_date('0101' || to_char(vers.anno)
     ,'ddmmyyyy'
     )
      ,'J'
      ))
   ,'DATA_EVE'
   )
  ,null
  )
    ,'j'
    ))*/
 to_number(null) residente_dal
   ,max(decode(sogg.tipo,  1, 'PersonaFisica',  2, 'PersonaGiuridica',  'IntestazioniParticolari')
 )
  personafisica
   ,max(data_nas) data_nascita
   , /*max(decode(decode(sogg.tipo_residente
    ,0, f_ult_eve_al(sogg.matricola
     ,to_number(to_char(to_date('0101' || to_char(vers.anno)
       ,'ddmmyyyy'
       )
     ,'J'
     ))
     ,'FASCIA'
     )
    ,null
    )
   ,3, 'AIRE'
   )) */
 null aire_storico_gsd_inizio_anno
   , /*max(decode(decode(sogg.tipo_residente
    ,0, f_ult_eve_al(sogg.matricola
     ,to_number(to_char(to_date('3112' || to_char(vers.anno)
       ,'ddmmyyyy'
       )
     ,'J'
     ))
     ,'FASCIA'
     )
    ,null
    )
   ,3, 'AIRE'
   )) */
 null aire_storico_gsd_fine_anno
   ,max(decode(sogg.stato, 50, 'Deceduto')) deceduto
   ,max(decode(sogg.stato, 50, data_ult_eve)) datadecesso
   ,'' xxcontribuente_da_fare
   ,'' min_max_perc_possesso
   ,to_number(null) differenza_oggetti_catasto
   ,to_number(null) differenza_terreni_catasto
   ,to_number(null) oggetti_non_catasto
   ,to_number(null) terreni_non_catasto
   ,max(supporto_servizi_pkg.f_serv_cont_ogge_cata(vers.anno
     ,vers.tipo_tributo
     ,cont.cod_fiscale
     ))
  cata_no_tr4
   ,max(supporto_servizi_pkg.f_serv_cont_terre_cata(vers.anno
      ,cont.cod_fiscale
      ))
  cata_no_tr4_terreni
   ,to_number(null) liquidazione_accertamento
   ,' ' liquidazione_ads
   ,null iter_ads
   ,to_number(null) ravvedimento_imu
   ,max(vers.tipo_tributo) tipo_tributo
   ,nvl(supporto_servizi_pkg.f_serv_tot_vers(vers.anno
     ,vers.tipo_tributo
     ,cont.cod_fiscale
     )
 ,0
 )
  versato
   ,to_number(null) dovuto
   ,to_number(null) dovuto_comunale
   ,to_number(null) dovuto_erariale
   ,to_number(null) dovuto_acconto
   ,to_number(null) dovuto_comunale_acconto
   ,to_number(null) dovuto_erariale_acconto
   ,0   diff_tot_contr
   ,to_number(null) denunce_imu
   ,max(cont.cod_attivita) codice_attivita_cont
   ,max(decode(sogg.tipo_residente, 0, (decode(fascia, 1, 'RESIDENTE', '')), '')
 )
  residente_oggi
   ,to_number(null) ab_pr
   ,to_number(null) pert
   ,to_number(null) altri_fabbricati
   ,to_number(null) fabbricati_d
   ,to_number(null) terreni
   ,to_number(null) terreni_ridotti
   ,to_number(null) aree
   ,to_number(null) abitativo
   ,to_number(null) commercialiartigianali
   ,to_number(null) rurali
  from contribuenti cont
   ,soggetti sogg
   ,versamenti vers
 where cont.cod_fiscale = vers.cod_fiscale
   and cont.ni = sogg.ni
   and vers.tipo_tributo in ('ICI', 'TASI')
   --  and vers.anno between 2017 and 2021
   and vers.cod_fiscale is not null
   and not exists
  (select 'x'
  from oggetti_imposta ogim
 where ogim.anno = vers.anno
   and ogim.tipo_tributo = vers.tipo_tributo
   and ogim.flag_calcolo = 'S'
   and ogim.cod_fiscale = vers.cod_fiscale)
 group by vers.anno
   ,cont.cod_fiscale
   ,vers.tipo_tributo
;
comment on table SERVIZI_CTR is 'SECT - Servizi CTR';

