--liquibase formatted sql 
--changeset abrandolini:20250326_152423_num_ruolo_per_contribuente stripComments:false runOnChange:true 
 
create or replace procedure NUM_RUOLO_PER_CONTRIBUENTE
(a_ruolo            IN    number)
--
-- Questa procedura modifica il numero di bollettino (su oggetti_imposta
-- e rate_imposta) in modo tale da modificare i bollettini di un ruolo numerati
-- per errore per utenza, in numerati per contribuente
--
IS
nOgpr           number;
nOgpr_Rif       number;
cursor sel_ogim (p_ruolo number) is
select max(ogim.num_bollettino) num_bollettino
     , ogim.cod_fiscale
from oggetti_imposta ogim
where ogim.ruolo = p_ruolo
group by ogim.cod_fiscale
;
cursor sel_raim (p_ruolo number) is
select  raim.num_bollettino
      , raim.cod_fiscale
     , raim.rata
from oggetti_imposta ogim
   , rate_imposta raim
where ogim.oggetto_imposta = raim.oggetto_imposta
  and ogim.ruolo = p_ruolo
;
begin
   for rec_ogim in sel_ogim (a_ruolo)
   loop
         update oggetti_imposta
            set num_bollettino = rec_ogim.num_bollettino
          where ruolo = a_ruolo
          and cod_fiscale = rec_ogim.cod_fiscale
         ;
   end loop;
   for rec_raim in sel_raim (a_ruolo)
   loop
         update rate_imposta
            set num_bollettino = (select max(raim.num_bollettino)
                                    from oggetti_imposta ogim
                                       , rate_imposta raim
                                   where ogim.oggetto_imposta = raim.oggetto_imposta
                                     and ogim.ruolo = a_ruolo
                                     and raim.cod_fiscale = rec_raim.cod_fiscale
                            and raim.rata = rec_raim.rata  )
          where cod_fiscale = rec_raim.cod_fiscale
          and num_bollettino = rec_raim.num_bollettino
         ;
   end loop;
exception
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||SQLERRM);
end;
/* End Procedure: NUM_RUOLO_PER_CONTRIBUENTE */
/

