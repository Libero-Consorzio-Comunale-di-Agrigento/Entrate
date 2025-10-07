--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_importi_ici stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_IMPORTI_ICI
(a_valore            in     NUMBER
,a_valore_d          in     NUMBER
,a_aliquota_1        in     NUMBER
,a_aliquota_2        in     NUMBER
,a_flag_riduzione    in     VARCHAR2
,a_perc_possesso     in     NUMBER
,a_mesi_possesso     in     NUMBER
,a_mesi_riduzione    in     NUMBER
,a_mesi_al_ridotta   in     NUMBER
,a_perc              in     NUMBER
,a_imm_storico       in     varchar2
,a_anno              in     number
,a_importo           in out NUMBER
,a_importo_d         in out NUMBER
) IS
--     Routine per la determinazione delle imposte e imposte dovute.
--     La routine e` costruita in forma complessa; per i casi piu`
--     semplici e` sufficiente passare i parametri di input in modo
--     che risultino ininfluenti.
w_mesi_riduzione     number;
BEGIN
   -- Gestione Immobili storici dal 2012 in poi
   -- In presenza di immobile storico si riconduce alla situazione
   -- che per tutti i mesi di possesso si ha la riduzione
   if nvl(a_imm_storico,'N') = 'S' and a_anno >= 2012 then
      w_mesi_riduzione := a_mesi_possesso;
   else
      w_mesi_riduzione := a_mesi_riduzione;
   end if;
   if nvl(a_mesi_al_ridotta,0) = 0 then
      if nvl(w_mesi_riduzione,0) = 0 then
--dbms_output.put_line('No mesi al Ridotta e no mesi Riduzione');
         select round(
                (a_valore * a_aliquota_1 / 1000)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
               ,round(
                (a_valore_d * a_aliquota_1 / 1000)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
           into a_importo
               ,a_importo_d
           from dati_generali
         ;
      else
--dbms_output.put_line('No mesi al Ridotta e si mesi Riduzione');
         select round(
                (a_valore * a_aliquota_1 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                +
                (a_valore * a_aliquota_1 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
               ,round(
                (a_valore_d * a_aliquota_1 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                +
                (a_valore_d * a_aliquota_1 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100) *
                (a_mesi_possesso / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
           into a_importo
               ,a_importo_d
           from dati_generali
         ;
      end if;
   else
      if nvl(w_mesi_riduzione,0) = 0 then
--dbms_output.put_line('Si mesi al Ridotta e no mesi Riduzione');
         select round(
                (a_valore * a_aliquota_1 / 1000)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore * a_aliquota_2 / 1000)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
               ,round(
                +
                (a_valore_d * a_aliquota_1 / 1000)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore_d * a_aliquota_2 / 1000)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
           into a_importo
               ,a_importo_d
           from dati_generali
         ;
      else
--dbms_output.put_line('Si mesi al Ridotta e si mesi Riduzione');
         select round(
                (a_valore * a_aliquota_1 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore * a_aliquota_1 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore * a_aliquota_2 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                +
                (a_valore * a_aliquota_2 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
               ,round(
                (a_valore_d * a_aliquota_1 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore_d * a_aliquota_1 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100) *
                (nvl(a_mesi_al_ridotta,a_mesi_possesso) / 12) * (a_perc / 100)
                +
                (a_valore_d * a_aliquota_2 / 1000)
                * nvl(w_mesi_riduzione,a_mesi_possesso) / (a_mesi_possesso * 2)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                +
                (a_valore_d * a_aliquota_2 / 1000)
                * (a_mesi_possesso - nvl(w_mesi_riduzione,a_mesi_possesso))
                / (a_mesi_possesso)
                * (a_perc_possesso / 100)
                * ((a_mesi_possesso - nvl(a_mesi_al_ridotta,0)) / 12) * (a_perc / 100)
                ,decode(fase_euro,1,0,2))
           into a_importo
               ,a_importo_d
           from dati_generali
         ;
      end if;
   end if;
--dbms_output.put_line('Valore          = '||to_char(a_valore));
--dbms_output.put_line('Aliquota 1      = '||to_char(a_aliquota_1));
--dbms_output.put_line('Aliquota 2      = '||to_char(a_aliquota_2));
--dbms_output.put_line('% Possesso      = '||to_char(a_rc_possesso));
--dbms_output.put_line('Mesi Possesso   = '||to_char(a_mesi_possesso));
--dbms_output.put_line('Mesi Riduzione  = '||to_char(a_mesi_riduzione));
--dbms_output.put_line('Mesi Al.Ridotta = '||to_char(a_mesi_al_ridotta));
--dbms_output.put_line('Flag Riduzione  = '||a_flag_riduzione);
--dbms_output.put_line('Perc Acconto    = '||to_char(a_perc));
--dbms_output.put_line(' ');
--dbms_output.put_line('Imposta         = '||to_char(a_importo));
--dbms_output.put_line('-----------------------------------------------------');
EXCEPTION
   WHEN OTHERS THEN
      a_importo   := 0;
      a_importo_d := 0;
END;
/* End Procedure: DETERMINA_IMPORTI_ICI */
/

