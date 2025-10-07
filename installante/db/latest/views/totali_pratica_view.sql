--liquibase formatted sql 
--changeset abrandolini:20250326_152401_totali_pratica_view stripComments:false runOnChange:true 
 
create or replace force view totali_pratica_view as
select SANZIONI_PRATICA.PRATICA,
       sum(decode(SANZIONI.FLAG_IMPOSTA,'S', SANZIONI_PRATICA.IMPORTO,0)) totale_imposta,
       sum(decode(SANZIONI.FLAG_IMPOSTA,'', decode(SANZIONI.FLAG_PENA_PECUNIARIA,'',
           decode(SANZIONI.FLAG_INTERESSI,'',
           decode(sanzioni_pratica.cod_sanzione,24, 0,
                  SANZIONI_PRATICA.IMPORTO),0),0),0)) totale_soprattasse,
       sum(decode(SANZIONI.FLAG_PENA_PECUNIARIA,'S', SANZIONI_PRATICA.IMPORTO,0)) totale_pene_pecuniarie,
       sum(decode(SANZIONI.FLAG_INTERESSI,'S', SANZIONI_PRATICA.IMPORTO,0)) totale_interessi,
       max(x.totale_versato) totale_versato
  from SANZIONI, SANZIONI_PRATICA,
       (select sum(importo_versato) totale_versato, pratica
          from versamenti
         where pratica is not null
         group by pratica) x
 where x.pratica (+) = SANZIONI_PRATICA.PRATICA
   and SANZIONI.TIPO_TRIBUTO = SANZIONI_PRATICA.TIPO_TRIBUTO
   and SANZIONI.COD_SANZIONE = SANZIONI_PRATICA.COD_SANZIONE
 group by SANZIONI_PRATICA.PRATICA;
comment on table TOTALI_PRATICA_VIEW is 'TOPR - Totali Pratica';

