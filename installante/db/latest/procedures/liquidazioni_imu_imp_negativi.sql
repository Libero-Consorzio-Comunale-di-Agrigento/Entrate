--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_imu_imp_negativi stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_IMU_IMP_NEGATIVI
(a_imp                   IN number,
 a_imp_ab            IN OUT number,
 a_imp_ter_comu      IN OUT number,
 a_imp_ter_erar      IN OUT number,
 a_imp_aree_comu     IN OUT number,
 a_imp_aree_erar     IN OUT number,
 a_imp_rur           IN OUT number,
 a_imp_fab_d_comu    IN OUT number,
 a_imp_fab_d_erar    IN OUT number,
 a_imp_altri_comu    IN OUT number,
 a_imp_altri_erar    IN OUT number,
 a_imp_fab_merce     IN OUT number
)
IS
 errore                    exception;
 w_errore                  varchar2(2000);
 w_tot_negativi_comu       number := 0;
 w_tot_negativi_erar       number := 0;
 i    BINARY_INTEGER;
 TYPE type_importo IS TABLE OF number
 INDEX BY BINARY_INTEGER;
 t_imp_comu  type_importo;
 t_imp_erar  type_importo;
BEGIN
   if a_imp > 0 and
      (   a_imp_ab < 0 or a_imp_rur < 0
       or a_imp_ter_comu < 0 or a_imp_ter_erar < 0
       or a_imp_aree_comu < 0 or a_imp_aree_erar < 0
       or a_imp_fab_d_comu < 0 or a_imp_fab_d_erar < 0
       or a_imp_altri_comu < 0 or a_imp_altri_erar < 0
       or a_imp_fab_merce < 0
      )  then
      -- Inizializzazione
      t_imp_comu(1) := a_imp_ab;
      t_imp_comu(2) := a_imp_rur;
      t_imp_comu(3) := a_imp_ter_comu;
      t_imp_comu(4) := a_imp_aree_comu;
      t_imp_comu(5) := a_imp_fab_d_comu;
      t_imp_comu(6) := a_imp_altri_comu;
      t_imp_comu(7) := a_imp_fab_merce;
      t_imp_erar(1) := a_imp_ter_erar;
      t_imp_erar(2) := a_imp_aree_erar;
      t_imp_erar(3) := a_imp_fab_d_erar;
      t_imp_erar(4) := a_imp_altri_erar;
      -- Estraggo il totale negativo per il Comune --
      for i in 1..6 loop
         if t_imp_comu(i) < 0 then
            w_tot_negativi_comu := w_tot_negativi_comu - t_imp_comu(i);
            t_imp_comu(i) := 0;
         end if;
      end loop;
      -- Scalo il totale negativo per il Comune sugli importi positivi per il Comune --
      if w_tot_negativi_comu > 0 then
         for i in 1..6 loop
            if t_imp_comu(i) > 0 and w_tot_negativi_comu > 0 then
               if t_imp_comu(i) > w_tot_negativi_comu then
                  t_imp_comu(i) := t_imp_comu(i) - w_tot_negativi_comu;
                  w_tot_negativi_comu := 0;
               else
                  w_tot_negativi_comu := w_tot_negativi_comu - t_imp_comu(i);
                  t_imp_comu(i) := 0;
               end if;
            end if;
         end loop;
      end if;
      -- Estraggo il totale negativo per lo Stato --
      for i in 1..4 loop
         if t_imp_erar(i) < 0 then
            w_tot_negativi_erar := w_tot_negativi_erar - t_imp_erar(i);
            t_imp_erar(i) := 0;
         end if;
      end loop;
      -- Scalo il totale negativo per lo Stato sugli importi positivi per lo Stato --
      if w_tot_negativi_erar > 0 then
         for i in 1..4 loop
            if t_imp_erar(i) > 0 and w_tot_negativi_erar > 0 then
               if t_imp_erar(i) > w_tot_negativi_erar then
                  t_imp_erar(i) := t_imp_erar(i) - w_tot_negativi_erar;
                  w_tot_negativi_erar := 0;
               else
                  w_tot_negativi_erar := w_tot_negativi_erar - t_imp_erar(i);
                  t_imp_erar(i) := 0;
               end if;
            end if;
         end loop;
      end if;
      -- Scalo il totale negativo per il Comune sugli importi positivi per lo Stato --
      if w_tot_negativi_comu > 0 then
         for i in 1..4 loop
            if t_imp_erar(i) > 0 and w_tot_negativi_comu > 0 then
               if t_imp_erar(i) > w_tot_negativi_comu then
                  t_imp_erar(i) := t_imp_erar(i) - w_tot_negativi_comu;
                  w_tot_negativi_comu := 0;
               else
                  w_tot_negativi_comu := w_tot_negativi_comu - t_imp_erar(i);
                  t_imp_erar(i) := 0;
               end if;
            end if;
         end loop;
      end if;
      -- Scalo il totale negativo per lo Stato sugli importi positivi per il Comune --
      if w_tot_negativi_erar > 0 then
         for i in 1..6 loop
            if t_imp_comu(i) > 0 and w_tot_negativi_erar > 0 then
               if t_imp_comu(i) > w_tot_negativi_erar then
                  t_imp_comu(i) := t_imp_comu(i) - w_tot_negativi_erar;
                  w_tot_negativi_erar := 0;
               else
                  w_tot_negativi_erar := w_tot_negativi_erar - t_imp_comu(i);
                  t_imp_comu(i) := 0;
               end if;
            end if;
         end loop;
      end if;
      -- Finalizzazione --
      a_imp_ab         := t_imp_comu(1);
      a_imp_rur        := t_imp_comu(2);
      a_imp_ter_comu   := t_imp_comu(3);
      a_imp_aree_comu  := t_imp_comu(4);
      a_imp_fab_d_comu := t_imp_comu(5);
      a_imp_altri_comu := t_imp_comu(6);
      a_imp_fab_merce  := t_imp_comu(7);
      a_imp_ter_erar   := t_imp_erar(1);
      a_imp_aree_erar  := t_imp_erar(2);
      a_imp_fab_d_erar := t_imp_erar(3);
      a_imp_altri_erar := t_imp_erar(4);
   end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore,TRUE);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'Errore in LIQUIDAZIONI_IMU_IMP_NEGATIVI -'||'- ('||SQLERRM||')');
END;
/* End Procedure: LIQUIDAZIONI_IMU_IMP_NEGATIVI */
/

