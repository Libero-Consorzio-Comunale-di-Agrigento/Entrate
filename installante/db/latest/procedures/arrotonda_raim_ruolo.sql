--liquibase formatted sql 
--changeset abrandolini:20250326_152423_arrotonda_raim_ruolo stripComments:false runOnChange:true 
 
create or replace procedure ARROTONDA_RAIM_RUOLO
(p_ruolo IN number)
is
cursor sel_raim (w_ruolo number) is
select round(  nvl(raim.imposta,0)
             + nvl(raim.addizionale_eca,0)
             + nvl(raim.addizionale_pro,0)
             + nvl(raim.maggiorazione_eca,0)
             + nvl(raim.iva,0)
            ,0)                                                                 raim_imposta_round
     , round(  nvl(ogim.imposta,0)
             + nvl(ogim.addizionale_eca,0)
             + nvl(ogim.addizionale_pro,0)
             + nvl(ogim.maggiorazione_eca,0)
             + nvl(ogim.iva,0)
            ,0)                                                                 ogim_imposta_round
     , ogim.oggetto_imposta
     , raim.rata_imposta
     , raim.rata
     , ruol.rate                                                                rate_ruolo
  from oggetti_imposta ogim
     , rate_imposta    raim
     , ruoli           ruol
 where raim.oggetto_imposta = ogim.oggetto_imposta
   and ogim.ruolo           = w_ruolo
   and ruol.ruolo           = w_ruolo
order by ogim.oggetto_imposta
       , raim.rata
     ;
w_imposta_round   number := 0;
w_tot_imposta     number := 0;
w_oggetto_imposta number := 0;
errore            exception;
w_errore         varchar2(2000);
BEGIN
   for rec_raim in sel_raim(p_ruolo)
   LOOP
        if w_oggetto_imposta <> rec_raim.oggetto_imposta then
           w_tot_imposta     := 0;
        end if;
        w_oggetto_imposta := rec_raim.oggetto_imposta;
        if rec_raim.rate_ruolo <> rec_raim.rata then
           w_imposta_round := rec_raim.raim_imposta_round;
           w_tot_imposta := w_tot_imposta + rec_raim.raim_imposta_round;
        else
           w_imposta_round := rec_raim.ogim_imposta_round - w_tot_imposta;
        end if;
        if w_imposta_round < 0 then
           w_imposta_round := 0;
        end if;
         BEGIN
            update rate_imposta
               set imposta_round = w_imposta_round
             where rata_imposta  = rec_raim.rata_imposta
           ;
        EXCEPTION
          WHEN others THEN
           w_errore := 'Errore in aggiornamento rate_imposta ' || ' (' ||SQLERRM || ')';
           RAISE errore;
        END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999, w_errore);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: ARROTONDA_RAIM_RUOLO */
/

