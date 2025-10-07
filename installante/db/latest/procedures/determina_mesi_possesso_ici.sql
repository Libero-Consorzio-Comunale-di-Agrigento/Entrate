--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_mesi_possesso_ici stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_MESI_POSSESSO_ICI
(a_flag_possesso            IN varchar2,
 a_flag_possesso_prec       IN varchar2,
 a_anno                     IN number,
 a_mesi_possesso            IN number,
 a_mesi_possesso_1s         IN OUT number,
 a_data_inizio_possesso     OUT date,
 a_data_fine_possesso       OUT date,
 a_data_inizio_possesso_1s  OUT date,
 a_data_fine_possesso_1s    OUT date,
 a_da_mese_possesso         IN number default null
) IS
   errore                     exception;
   w_errore                   varchar2(200);
   w_data_inizio_anno         date;
   w_data_fine_anno           date;
   w_data_fine_semestre       date;
   w_mesi_possesso            number;
   w_mesi_possesso_1s         number;
   w_da_mese_possesso         number;
   w_flag_possesso            varchar2(1);
   w_flag_possesso_prec       varchar2(1);
   w_data_inizio_possesso     date;
   w_data_fine_possesso       date;
   w_data_inizio_possesso_1s  date;
   w_data_fine_possesso_1s    date;
/******************************************************************************
   NAME:       POSSESSO_ICI
   PURPOSE:
******************************************************************************/
BEGIN
   w_data_inizio_anno   := to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   w_data_fine_anno     := to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   w_data_fine_semestre := to_date('3006'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
   w_mesi_possesso      := a_mesi_possesso;
   w_mesi_possesso_1s   := a_mesi_possesso_1s;
   w_da_mese_possesso   := a_da_mese_possesso;
   w_flag_possesso      := nvl(a_flag_possesso,'N');
   w_flag_possesso_prec := nvl(a_flag_possesso_prec,'N');
   if nvl(w_da_mese_possesso,0) = 0 then
      if w_mesi_possesso > 0 then
         if w_flag_possesso = 'S' then
            w_data_inizio_possesso    := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
            w_data_fine_possesso      := w_data_fine_anno;
         else
            if w_mesi_possesso_1s is not null then
               if w_mesi_possesso_1s = 0 then
                  w_data_inizio_possesso  := w_data_fine_semestre +1;
                  w_data_fine_possesso    := add_months(w_data_fine_semestre ,w_mesi_possesso );
               else
                  if w_mesi_possesso > w_mesi_possesso_1s then
                     w_data_inizio_possesso  := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
                     w_data_fine_possesso    := add_months(w_data_fine_semestre, w_mesi_possesso - w_mesi_possesso_1s ) ;
                  else
                     w_data_inizio_possesso  := w_data_inizio_anno;
                     w_data_fine_possesso    := add_months(w_data_inizio_anno,w_mesi_possesso) -1;
                  end if;
               end if;
            else
               if w_flag_possesso_prec = 'S' then
                  w_data_inizio_possesso    := w_data_inizio_anno;
                  w_data_fine_possesso      := add_months(w_data_inizio_anno,w_mesi_possesso) -1;
               else
                  w_data_inizio_possesso  := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
                  w_data_fine_possesso    := w_data_fine_anno;
               end if;
            end if;
         end if;
      else
         w_data_inizio_possesso       := null;
         w_data_fine_possesso         := null;
      end if;
   else
      w_data_inizio_possesso := to_date('01'||lpad(w_da_mese_possesso,2,'0')||a_anno,'ddmmyyyy');
      w_data_fine_possesso   := last_day(to_date('01'||lpad(w_da_mese_possesso + w_mesi_possesso - 1,2,'0')||a_anno,'ddmmyyyy'));
   end if;
   if nvl(w_da_mese_possesso,0) = 0 then
      if w_mesi_possesso > 6 then
         if w_flag_possesso = 'S'  then
            w_mesi_possesso_1s        := w_mesi_possesso - 6;
            w_data_inizio_possesso_1s := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
            w_data_fine_possesso_1s   := w_data_fine_semestre;
         else
            if w_mesi_possesso_1s is not null then
               w_data_inizio_possesso_1s := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
               w_data_fine_possesso_1s   := w_data_fine_semestre;
            else
               if w_flag_possesso_prec = 'S' then
                  w_mesi_possesso_1s        := 6;
                  w_data_inizio_possesso_1s := w_data_inizio_anno;
                  w_data_fine_possesso_1s   := w_data_fine_semestre;
               else
                  w_mesi_possesso_1s        := w_mesi_possesso - 6;
                  w_data_inizio_possesso_1s := add_months(w_data_fine_anno + 1,w_mesi_possesso * -1);
                  w_data_fine_possesso_1s   := w_data_fine_semestre;
               end if;
            end if;
         end if;
      else
         if w_flag_possesso = 'S' then
            w_mesi_possesso_1s        := 0;
            w_data_inizio_possesso_1s := null;
            w_data_fine_possesso_1s   := null;
         else
            if w_mesi_possesso_1s is not null then
               if w_mesi_possesso_1s = 0 then
                  w_mesi_possesso_1s        := 0;
                  w_data_inizio_possesso_1s := null;
                  w_data_fine_possesso_1s   := null;
               else
                  if w_mesi_possesso > w_mesi_possesso_1s then
                     w_data_inizio_possesso_1s := add_months(w_data_fine_semestre + 1,w_mesi_possesso_1s * -1);
                     w_data_fine_possesso_1s   := w_data_fine_semestre;
                  else
                     w_data_inizio_possesso_1s := w_data_inizio_anno;
                     w_data_fine_possesso_1s   := add_months(w_data_inizio_anno,w_mesi_possesso_1s) -1;
                  end if;
               end if;
            else
               if w_flag_possesso_prec = 'S' then
                  w_mesi_possesso_1s        := w_mesi_possesso;
                  w_data_inizio_possesso_1s := w_data_inizio_anno;
                  w_data_fine_possesso_1s   := add_months(w_data_inizio_anno,w_mesi_possesso_1s) -1;
               else
                  w_mesi_possesso_1s        := 0;
                  w_data_inizio_possesso_1s := null;
                  w_data_fine_possesso_1s   := null;
               end if;
            end if;
         end if;
      end if;
   else
      if nvl(w_da_mese_possesso,0) <= 6 then
         w_mesi_possesso           := 6 - w_da_mese_possesso + 1;
         w_data_inizio_possesso_1s := to_date('01'||lpad(w_da_mese_possesso,2,'0')||a_anno,'ddmmyyyy');
         w_data_fine_possesso_1s   := w_data_fine_semestre;
      elsif
         nvl(w_da_mese_possesso,0) > 6 then
         w_mesi_possesso_1s        := 0;
         w_data_inizio_possesso_1s := null;
         w_data_fine_possesso_1s   := null;
      end if;
   end if;
   a_mesi_possesso_1s         := w_mesi_possesso_1s;
   a_data_inizio_possesso     := w_data_inizio_possesso;
   a_data_fine_possesso       := w_data_fine_possesso;
   a_data_inizio_possesso_1s  := w_data_inizio_possesso_1s;
   a_data_fine_possesso_1s    := w_data_fine_possesso_1s;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
     RAISE;
   --   RAISE_APPLICATION_ERROR(-20999,w_errore||' ('||SQLERRM||')',true);
  WHEN others THEN
      ROLLBACK;
     RAISE;
 --     RAISE_APPLICATION_ERROR
 --     (-20999,'Errore in Possesso ICI ('||SQLERRM||')');
END;
/* End Procedure: DETERMINA_MESI_POSSESSO_ICI */
/

