--liquibase formatted sql 
--changeset abrandolini:20250326_152401_rate_tributi_minori stripComments:false runOnChange:true 
 
create or replace force view rate_tributi_minori as
select raim.cod_fiscale,
       raim.tipo_tributo,
       raim.anno,
       raim.rata,
       sum(nvl(raim.imposta_round,raim.imposta)) importo_rata,
       sum(nvl(raim.imposta_round,raim.imposta)) importo_rata_perm,
       to_number(null)                           importo_rata_temp
  from rate_imposta      raim
 where raim.tipo_tributo in ('TOSAP','ICP','TARSU')
   and raim.oggetto_imposta is null
 group by raim.cod_fiscale, raim.tipo_tributo, raim.anno, raim.rata
 union
select raim.cod_fiscale,
       raim.tipo_tributo,
       raim.anno,
       raim.rata,
       sum(nvl(raim.imposta_round,raim.imposta)) importo_rata,
       sum(decode(ogpr.tipo_occupazione,'P',nvl(raim.imposta_round,raim.imposta),0)) importo_rata_perm,
       sum(decode(ogpr.tipo_occupazione,'T',nvl(raim.imposta_round,raim.imposta),0)) importo_rata_temp
  from rate_imposta    raim,
       oggetti_imposta ogim,
       oggetti_pratica ogpr
 where raim.tipo_tributo in ('TOSAP','ICP','TARSU')
   and raim.oggetto_imposta is not null
   and raim.oggetto_imposta = ogim.oggetto_imposta
   and ogim.oggetto_pratica = ogpr.oggetto_pratica
   and ogim.ruolo is null
 group by raim.cod_fiscale, raim.tipo_tributo, raim.anno, raim.rata;
comment on table RATE_TRIBUTI_MINORI is 'RTMI - Rate Tributi Minori';

