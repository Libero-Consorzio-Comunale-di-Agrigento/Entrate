--liquibase formatted sql 
--changeset abrandolini:20250326_152401_immobili_soggetto_cc stripComments:false runOnChange:true 
 
create or replace force view immobili_soggetto_cc as
select    --distinct
 fabb.id_immobile contatore
 ,sogg.id_soggetto_ric proprietario
 ,sogg.cod_fiscale_ric
 ,indi.toponimo
 ,ltrim(rtrim(indi.indirizzo)) indirizzo
 ,rtrim(ltrim(ltrim(indi.civico1
    ,'0'
    ))) ||
  decode(rtrim(ltrim(ltrim(indi.civico2
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(indi.civico2
  ,'0'
  )))
  ) ||
  decode(rtrim(ltrim(ltrim(indi.civico3
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(indi.civico3
  ,'0'
  )))
  )
   num_civ
 ,rtrim(ltrim(ltrim(fabb.lotto
    ,'0'
    )))
   lotto
 ,rtrim(ltrim(ltrim(fabb.edificio
    ,'0'
    )))
   edificio
 ,rtrim(ltrim(ltrim(fabb.scala
    ,'0'
    )))
   scala
 ,rtrim(ltrim(ltrim(fabb.interno_1
    ,'0'
    ))) ||
  decode(rtrim(ltrim(ltrim(fabb.interno_2
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(fabb.interno_2
  ,'0'
  )))
  )
   interno
 ,rtrim(ltrim(ltrim(fabb.piano_1
    ,'0'
    ))) ||
  decode(rtrim(ltrim(ltrim(fabb.piano_2
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(fabb.piano_2
  ,'0'
  )))
  ) ||
  decode(rtrim(ltrim(ltrim(fabb.piano_3
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(fabb.piano_3
  ,'0'
  )))
  ) ||
  decode(rtrim(ltrim(ltrim(fabb.piano_4
  ,'0'
  )))
  ,'', ''
  ,'-' ||
   rtrim(ltrim(ltrim(fabb.piano_4
  ,'0'
  )))
  )
   piano
 ,rtrim(ltrim(ltrim(tito.quota_numeratore
    ,'0'
    )))
   numeratore
 ,rtrim(ltrim(ltrim(tito.quota_denominatore
    ,'0'
    )))
   denominatore
 ,rtrim(ltrim(tito.codice_diritto)) cod_titolo
 ,rtrim(ltrim(tito.titolo_non_codificato)) des_titolo
 ,rtrim(ltrim(diri.descrizione)) des_diritto
 ,tito.tipo_immobile
 ,tito.partita partita_titolarita
 ,fabb.partita partita
 ,iden.progr_identificativo
 ,rtrim(ltrim(ltrim(iden.sezione
    ,'0'
    )))
   sezione
 ,substr(rtrim(ltrim(ltrim(iden.foglio
  ,'0'
  )))
  ,1
  ,5
  )
   foglio
 ,substr(rtrim(ltrim(ltrim(iden.numero
  ,'0'
  )))
  ,1
  ,5
  )
   numero
 ,rtrim(ltrim(ltrim(iden.subalterno
    ,'0'
    )))
   subalterno
 ,rtrim(ltrim(ltrim(fabb.zona
    ,'0'
    )))
   zona
 ,rtrim(ltrim(ltrim(fabb.categoria
    ,'0'
    )))
   categoria
 ,rtrim(ltrim(ltrim(fabb.classe
    ,'0'
    )))
   classe
 ,rtrim(ltrim(ltrim(fabb.consistenza
    ,'0'
    )))
   consistenza
 ,rtrim(ltrim(ltrim(fabb.superficie
    ,'0'
    )))
   superficie
 ,rtrim(ltrim(ltrim(decode(dage.cambio_euro, 1, fabb.rendita_lire, fabb.rendita_euro)
    ,'0'
    )))
   rendita
 ,rtrim(ltrim(ltrim(fabb.rendita_euro
    ,'0'
    )))
   rendita_euro
 ,null descrizione
 ,f_adatta_data(fabb.data_efficacia) data_efficacia
 ,f_adatta_data(fabb.data_efficacia_2) data_fine_efficacia
 ,f_adatta_data(fabb.data_registrazione_atti) data_iscrizione
 ,f_adatta_data(fabb.data_registrazione_atti_2) data_fine_iscrizione
 ,f_adatta_data(tito.data_validita) data_validita
 ,f_adatta_data(tito.data_validita_2) data_fine_validita
 ,tito.tipo_nota tit_tipo_nota
 ,tito.numero_nota tit_numero_nota
 ,tito.progressivo_nota tit_progressivo_nota
 ,tito.anno_nota tit_anno_nota
 ,tito.tipo_nota_2 tit_tipo_nota_2
 ,tito.numero_nota_2 tit_numero_nota_2
 ,tito.progressivo_nota_2 tit_progressivo_nota_2
 ,tito.anno_nota_2 tit_anno_nota_2
 ,tito.data_registrazione_atti tit_data_registrazione_atti
 ,decode(greatest(15
  ,to_number(to_char(f_adatta_data(tito.data_validita)
     ,'dd'
     ))
  )
  ,15, to_date('01' ||
   to_char(f_adatta_data(tito.data_validita)
    ,'mmyyyy'
    )
  ,'ddmmyyyy'
  )
  ,last_day(f_adatta_data(tito.data_validita)) + 1
  )
   inizio_validita_ogco
 ,iden.estremi_catasto estremi_catasto
 ,fabb.protocollo_notifica
 ,f_adatta_data(fabb.data_notifica) data_notifica
 ,fabb.cod_causale_atto_generante fab_cod_caus_atto_generante
 ,fabb.des_atto_generante fab_des_atto_generante
 ,fabb.cod_causale_atto_conclusivo fab_cod_caus_atto_conclusivo
 ,fabb.des_atto_conclusivo fab_des_atto_conclusivo
 ,fabb.flag_classamento
 ,fabb.annotazione note
 ,tito.cod_causale_atto_generante tit_cod_caus_atto_generante
 ,tito.des_atto_generante tit_des_atto_generante
 ,tito.cod_causale_atto_conclusivo tit_cod_caus_atto_conclusivo
 ,tito.des_atto_conclusivo tit_des_atto_conclusivo
 ,iden.sezione_ric sezione_ric
 ,iden.foglio_ric foglio_ric
 ,iden.numero_ric numero_ric
 ,iden.subalterno_ric subalterno_ric
 ,indi.indirizzo_ric indirizzo_ric
 ,fabb.zona_ric zona_ric
 ,fabb.categoria_ric categoria_ric
 ,fabb.partita_ric partita_ric
   from dati_generali dage
 ,(select *
  from cc_indirizzi
 where tipo_immobile = 'F'
   and progr_indirizzo = 1) indi
 ,(select *
  from cc_titolarita
 where tipo_immobile = 'F') tito
 ,cc_identificativi iden
 ,cc_fabbricati fabb
 ,cc_soggetti sogg
 ,cc_diritti diri
  where tito.id_soggetto = sogg.id_soggetto_ric
 and tito.tipo_soggetto = nvl(sogg.tipo_soggetto, sogg.tipo_soggetto_2)
 and indi.id_immobile(+) = fabb.id_immobile
 and indi.progressivo(+) = fabb.progressivo
 and indi.codice_amm(+) = fabb.codice_amm
 and nvl(indi.sezione_amm(+), ' ') = nvl(fabb.sezione_amm, ' ')
 and iden.id_immobile = fabb.id_immobile
 and iden.progressivo = fabb.progressivo
 and iden.codice_amm = fabb.codice_amm
 and nvl(iden.sezione_amm, ' ') = nvl(fabb.sezione_amm, ' ')
 -- and nvl(iden.progr_identificativo,1) = 1
 and tito.id_immobile = fabb.id_immobile
 and tito.codice_amm = fabb.codice_amm
 and nvl(tito.sezione_amm, ' ') = nvl(fabb.sezione_amm, ' ')
 and diri.codice_diritto(+) = tito.codice_diritto
 and nvl(f_adatta_data(fabb.data_efficacia)
  ,to_date('01011900'
    ,'ddmmyyyy'
    )
  ) <= nvl(f_adatta_data(tito.data_validita_2)
    ,to_date('31122999'
   ,'ddmmyyyy'
   )
    )
 and nvl(f_adatta_data(fabb.data_efficacia_2)
  ,to_date('31122999'
    ,'ddmmyyyy'
    )
  ) >= nvl(f_adatta_data(tito.data_validita)
    ,to_date('01011900'
   ,'ddmmyyyy'
   )
    )
-- and sogg.id_soggetto_ric > 0
;
comment on table IMMOBILI_SOGGETTO_CC is 'IMSO - IMMOBILI_SOGGETTO_CC';

