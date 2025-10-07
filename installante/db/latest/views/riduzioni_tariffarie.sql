--liquibase formatted sql 
--changeset abrandolini:20250326_152401_riduzioni_tariffarie stripComments:false runOnChange:true 
 
create or replace force view riduzioni_tariffarie as
select cotr.tipo_tributo                                                        tipo_tributo
     , tari.tributo                                                             tributo
     , cotr.descrizione                                                         desc_tributo
     , tari.categoria                                                           categoria
     , cate.descrizione                                                         desc_categoria
     , tari.tipo_tariffa                                                        tipo_tariffa
     , tari.descrizione                                                         desc_tariffa
     , tari.anno                                                                anno
     , tari.tariffa                                                             tariffa
     , tari_1.tariffa                                                           tariffa_base
     , decode(nvl(tari_1.tariffa,0)
             ,0,null
             ,100 - round(tari.tariffa / tari_1.tariffa * 100, 2)
             )                                                                  riduzione
  from codici_tributo cotr
     , categorie      cate
     , tariffe        tari
     , tariffe        tari_1
 where cotr.tributo   = cate.tributo
   and cate.tributo   = tari.tributo
   and cate.categoria = tari.categoria
   and cate.tributo   = tari_1.tributo
   and cate.categoria = tari_1.categoria
   and tari_1.tipo_tariffa = 1
   and tari.anno      = tari_1.anno;
comment on table RIDUZIONI_TARIFFARIE is 'RITA - Riduzioni Tariffarie';

