--liquibase formatted sql 
--changeset abrandolini:20250326_152401_immobili_catasto_terreni_cc stripComments:false runOnChange:true 
 
create or replace force view immobili_catasto_terreni_cc as
select part.id_immobile
 ,sogg.id_soggetto_ric id_soggetto
 ,sogg.cod_fiscale_ric
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
 ,part.partita partita
 ,substr(rtrim(ltrim(ltrim(part.sezione_amm
  ,'0'
  )))
  ,1
  ,1
  )
   sezione
 ,substr(rtrim(ltrim(ltrim(part.foglio
  ,'0'
  )))
  ,1
  ,5
  )
   foglio
 ,substr(rtrim(ltrim(ltrim(part.numero
  ,'0'
  )))
  ,1
  ,4
  )
   numero
 ,substr(rtrim(ltrim(ltrim(part.subalterno
  ,'0'
  )))
  ,1
  ,4
  )
   subalterno
 ,part.edificialita
 ,substr(rtrim(ltrim(ltrim(part.qualita
  ,'0'
  )))
  ,1
  ,3
  )
   qualita
 ,substr(rtrim(ltrim(ltrim(part.classe
  ,'0'
  )))
  ,1
  ,2
  )
   classe
 ,substr(rtrim(ltrim(ltrim(part.ettari
  ,'0'
  )))
  ,1
  ,5
  )
   ettari
 ,substr(rtrim(ltrim(ltrim(part.are
  ,'0'
  )))
  ,1
  ,2
  )
   are
 ,substr(rtrim(ltrim(ltrim(part.centiare
  ,'0'
  )))
  ,1
  ,2
  )
   centiare
 ,rtrim(ltrim(ltrim(tito.quota_numeratore
    ,'0'
    )))
   numeratore
 ,rtrim(ltrim(ltrim(tito.quota_denominatore
    ,'0'
    )))
   denominatore
 ,part.flag_reddito
 ,part.flag_porzione
 ,part.flag_deduzioni
 ,substr(rtrim(ltrim(ltrim(part.reddito_dominicale_lire
  ,'0'
  )))
  ,1
  ,12
  )
   reddito_dominicale_lire
 ,substr(rtrim(ltrim(ltrim(part.reddito_agrario_lire
  ,'0'
  )))
  ,1
  ,11
  )
   reddito_agrario_lire
 ,substr(rtrim(ltrim(ltrim(part.reddito_dominicale_euro
  ,'0'
  )))
  ,1
  ,9
  )
   reddito_dominicale_euro
 ,substr(rtrim(ltrim(ltrim(part.reddito_agrario_euro
  ,'0'
  )))
  ,1
  ,8
  )
   reddito_agrario_euro
 ,nvl(f_adatta_data(part.data_efficacia)
  ,to_date('01011900'
    ,'ddmmyyyy'
    )
  )
   data_efficacia
 ,f_adatta_data(part.data_efficacia_1) data_fine_efficacia
 ,nvl(f_adatta_data(part.data_registrazione_atti)
  ,to_date('01011900'
    ,'ddmmyyyy'
    )
  )
   data_iscrizione
 ,f_adatta_data(part.data_registrazione_atti_1) data_fine_iscrizione
 ,decode(part.data_registrazione_atti
  ,null, to_date('01011900'
    ,'ddmmyyyy'
    )
  ,decode(greatest(15
   ,to_number(to_char(f_adatta_data(part.data_registrazione_atti)
   ,'dd'
   ))
   )
   ,15, to_date('01' ||
    to_char(f_adatta_data(part.data_registrazione_atti)
     ,'mmyyyy'
     )
   ,'ddmmyyyy'
   )
   ,last_day(f_adatta_data(part.data_registrazione_atti)) +
    1
   )
  )
   inizio_validita_ogco
 ,part.tipo_nota
 ,substr(rtrim(ltrim(ltrim(part.numero_nota
  ,'0'
  )))
  ,1
  ,6
  )
   numero_nota
 ,substr(rtrim(ltrim(ltrim(part.progressivo_nota
  ,'0'
  )))
  ,1
  ,3
  )
   progressivo_nota
 ,substr(rtrim(ltrim(ltrim(part.anno_nota
  ,'0'
  )))
  ,1
  ,4
  )
   anno_nota
 ,part.tipo_nota_1
 ,substr(rtrim(ltrim(ltrim(part.numero_nota_1
  ,'0'
  )))
  ,1
  ,6
  )
   numero_nota_1
 ,substr(rtrim(ltrim(ltrim(part.progressivo_nota_1
  ,'0'
  )))
  ,1
  ,3
  )
   progressivo_nota_1
 ,substr(rtrim(ltrim(ltrim(part.anno_nota_1
  ,'0'
  )))
  ,1
  ,4
  )
   anno_nota_1
 ,substr(rtrim(ltrim(ltrim(part.partita
  ,'0'
  )))
  ,1
  ,7
  )
   partita_terreno
 ,substr(rtrim(ltrim(part.annotazione))
  ,1
  ,200
  ) ||
  decode(ltrim(ltrim(part.sezione_amm
  ,'0'
  ))
  ,'', ''
  ,' Sezione: ' || part.sezione_amm
  )
   annotazione
 ,part.sezione_ric sezione_ric
 ,part.foglio_ric foglio_ric
 ,part.numero_ric numero_ric
 ,part.subalterno_ric subalterno_ric
 ,indi.indirizzo_ric indirizzo_ric
 ,part.estremi_catasto
 ,part.id_mutazione_iniziale ter_id_mutazione_iniziale
 ,part.id_mutazione_finale ter_id_mutazione_finale
 ,part.cod_causale_atto_generante ter_causale_atto_generante
 ,part.des_atto_generante ter_des_atto_generante
 ,part.cod_causale_atto_conclusivo ter_causale_atto_conclusivo
 ,part.des_atto_conclusivo ter_des_atto_conclusivo
 ,tito.codice_diritto cod_titolo
 ,tito.titolo_non_codificato des_titolo
 ,rtrim(ltrim(diri.descrizione)) des_diritto
 ,tito.regime tit_regime
 ,tito.soggetto_riferimento tit_soggetto_riferimento
 ,f_adatta_data(tito.data_validita) data_validita
 ,tito.tipo_nota tit_tipo_nota
 ,tito.numero_nota tit_numero_nota
 ,tito.progressivo_nota tit_progressivo_nota
 ,tito.anno_nota tit_anno_nota
 ,f_adatta_data(tito.data_registrazione_atti)
   tit_data_registrazione_atti
 ,tito.partita tit_partita
 ,f_adatta_data(tito.data_validita_2) data_fine_validita
 ,tito.tipo_nota_2 tit_tipo_nota_2
 ,tito.numero_nota_2 tit_numero_nota_2
 ,tito.progressivo_nota_2 tit_progressivo_nota_2
 ,tito.anno_nota_2 tit_anno_nota_2
 ,f_adatta_data(tito.data_registrazione_atti_2) tit_data_fine_reg_atti
 ,tito.id_mutazione_iniziale tit_id_mutazione_iniziale
 ,tito.id_mutazione_finale tit_id_mutazione_finale
 ,tito.id_titolarita tit_id_titolarita
 ,tito.cod_causale_atto_generante tit_causale_atto_generante
 ,tito.des_atto_generante tit_des_atto_generante
 ,tito.cod_causale_atto_conclusivo tit_causale_atto_conclusivo
 ,tito.des_atto_conclusivo tit_des_atto_conclusivo
   from (select *
  from cc_indirizzi
 where tipo_immobile = 'T') indi
 ,(select *
  from cc_titolarita
 where tipo_immobile = 'T') tito
 ,cc_particelle part
 ,cc_soggetti sogg
 ,cc_diritti diri
  where indi.id_immobile(+) = part.id_immobile
 and indi.codice_amm(+) = part.codice_amm
 and indi.tipo_immobile(+) = part.tipo_immobile
 and indi.progressivo(+) = part.progressivo
 and tito.id_immobile = part.id_immobile
 and tito.codice_amm = part.codice_amm
 and tito.tipo_immobile = part.tipo_immobile
 and tito.id_soggetto = sogg.id_soggetto_ric
 and tito.tipo_soggetto = nvl(sogg.tipo_soggetto, sogg.tipo_soggetto_2)
 and diri.codice_diritto(+) = tito.codice_diritto
 and nvl(f_adatta_data(part.data_efficacia)
  ,to_date('01011900'
    ,'ddmmyyyy'
    )
  ) <= nvl(f_adatta_data(tito.data_validita_2)
    ,to_date('31122999'
   ,'ddmmyyyy'
   )
    )
 and nvl(f_adatta_data(part.data_efficacia_1)
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
comment on table IMMOBILI_CATASTO_TERRENI_CC is 'Immobili Catasto Terreni CC';

