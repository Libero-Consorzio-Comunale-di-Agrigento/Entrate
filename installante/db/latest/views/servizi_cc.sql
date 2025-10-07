--liquibase formatted sql 
--changeset abrandolini:20250326_152401_servizi_cc stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW SERVIZI_CC
(FONTE, SEGNALAZIONE, RAGIONESOCIALE, CODICEFISCALE, ANNO,
 NUMOGGETTI, NUMFABBRICATI, NUMTERRENI, NUMAREE, DIFFERENZA_IMPOSTA,
 RES_STORICO_GSD_INIZIO_ANNO, RES_STORICO_GSD_FINE_ANNO, RESIDENTE_DAL, PERSONAFISICA, DATA_NASCITA,
 AIRE_STORICO_GSD_INIZIO_ANNO, AIRE_STORICO_GSD_FINE_ANNO, DECEDUTO, DATADECESSO, XXCONTRIBUENTE_DA_FARE,
 MIN_MAX_PERC_POSSESSO, DIFFERENZA_OGGETTI_CATASTO, DIFFERENZA_TERRENI_CATASTO, OGGETTI_NON_CATASTO, TERRENI_NON_CATASTO,
 CATA_NO_TR4, CATA_NO_TR4_TERRENI, LIQUIDAZIONE_ACCERTAMENTO, LIQUIDAZIONE_ADS, ITER_ADS,
 RAVVEDIMENTO_IMU, TIPO_TRIBUTO, VERSATO, DOVUTO, DOVUTO_COMUNALE,
 DOVUTO_ERARIALE, DOVUTO_ACCONTO, DOVUTO_COMUNALE_ACCONTO, DOVUTO_ERARIALE_ACCONTO, DIFF_TOT_CONTR,
 DENUNCE_IMU, CODICE_ATTIVITA_CONT, RESIDENTE_OGGI, AB_PR, PERT,
 ALTRI_FABBRICATI, FABBRICATI_D, TERRENI, TERRENI_RIDOTTI, AREE,
 ABITATIVO, COMMERCIALIARTIGIANALI, RURALI)
AS
select 'SERVIZI_CATA_NO_TR4' fonte
   , -- IMU ANNO 2018
 --   'Solo Catasto NO tr4 per Anno'
 ' ' segnalazione
   ,nvl(sogg.cognome_nome, pcur.cognome_nome_ric) ragionesociale
   ,pcur.cod_fiscale_ric codicefiscale
   ,anni.anno anno
   ,to_number(null) numoggetti
   ,to_number(null) numfabbricati
   ,to_number(null) numterreni
   ,to_number(null) numaree
   ,0 differenza_imposta
   ,/*max(decode(decode(sogg.tipo_residente
   ,0, f_ult_eve_al(sogg.matricola
    ,to_number(to_char(to_date('0101' || to_char(2018)
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
   ,/*max(decode(decode(sogg.tipo_residente
   ,0, f_ult_eve_al(sogg.matricola
    ,to_number(to_char(to_date('3112' || to_char(2018)
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
  null res_storico_gsd_fine_anno
   , /*max(to_date(decode(sogg.tipo_residente
  ,0, f_ult_eve_al(sogg.matricola
   ,to_number(to_char(to_date('0101' || to_char(2018)
     ,'ddmmyyyy'
     )
      ,'J'
      ))
   ,'DATA_EVE'
   )
  ,null
  )
    ,'j'
    )) */
 to_number(null) residente_dal
   ,max(decode(sogg.tipo,  1, 'PersonaFisica',  2, 'PersonaGiuridica',  'IntestazioniParticolari')
 )
  personafisica
   ,max(data_nas) data_nascita
   ,/*max(decode(decode(sogg.tipo_residente
   ,0, f_ult_eve_al(sogg.matricola
    ,to_number(to_char(to_date('0101' || to_char(2018)
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
   ,/*max(decode(decode(sogg.tipo_residente
   ,0, f_ult_eve_al(sogg.matricola
    ,to_number(to_char(to_date('3112' || to_char(2018)
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
   ,case
      when anni.anno <> 0 then
        supporto_servizi_pkg.f_serv_cata_no_cont(anni.anno
        --,'ICI'
        ,pcur.cod_fiscale_ric
        )
      else
        0
    end cata_no_tr4
   ,case
      when anni.anno <> 0 then
        supporto_servizi_pkg.f_serv_cata_no_cont_terr(anni.anno
        ,pcur.cod_fiscale_ric
        )
      else
        0
    end cata_no_tr4_terreni
   ,to_number(null) liquidazione_accertamento
   ,'' liquidazione_ads
   ,'' iter_ads
   ,to_number(null) ravvedimento_imu
   ,anni.tipo_tributo tipo_tributo
   ,0 versato
   ,to_number(null) dovuto
   ,to_number(null) dovuto_comunale
   ,to_number(null) dovuto_erariale
   ,to_number(null) dovuto_acconto
   ,to_number(null) dovuto_comunale_acconto
   ,to_number(null) dovuto_erariale_acconto
   ,to_number(null) diff_tot_contr
   ,to_number(null) denunce_imu
   ,null codice_attivita_cont
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
  from cc_soggetti pcur
   ,soggetti sogg
   ,(select distinct anno,tipo_tributo from oggetti_imposta
   where tipo_tributo in ('ICI','TASI')
  union
  select distinct anno,tipo_tributo from versamenti
   where tipo_tributo in ('ICI','TASI')) anni
 -- non deve esistere un dovuto
 where not exists
  (select 'x'
  from oggetti_imposta ogim
 where ogim.anno = anni.anno
   and ogim.tipo_tributo || '' = anni.tipo_tributo
   and ogim.flag_calcolo = 'S'
   and ogim.cod_fiscale = pcur.cod_fiscale_ric)
   -- non deve esistere un versamento
   and not exists
  (select 'x'
  from versamenti
 where versamenti.tipo_tributo || '' = anni.tipo_tributo
   --         and versamenti.pratica is null  AB 04/12/2023
   and versamenti.anno = anni.anno
   and pcur.cod_fiscale_ric = versamenti.cod_fiscale)
   --   and F_CATA_NO_CONT (2018, 'ICI', pcur.COD_FISCALE_ric) >0
   and pcur.cod_fiscale_ric = sogg.cod_fiscale(+)
   and pcur.cod_fiscale_ric is not null
 group by nvl(sogg.cognome_nome, pcur.cognome_nome_ric)
   ,pcur.cod_fiscale_ric,anni.anno,anni.tipo_tributo
;
comment on table SERVIZI_CC is 'SECC - Servizi CC';

