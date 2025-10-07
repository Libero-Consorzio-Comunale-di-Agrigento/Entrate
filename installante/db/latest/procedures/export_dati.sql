--liquibase formatted sql 
--changeset abrandolini:20250326_152423_export_dati stripComments:false runOnChange:true 
 
create or replace procedure EXPORT_DATI
(a_tipo_export            IN    tipi_export.tipo_export%type )
IS
w_errore               varchar2(2000);
errore                 exception;
w_descrizione_export   tipi_export.descrizione%type;
w_nome_procedura       tipi_export.nome_procedura%type;
w_stringa_lancio       varchar2(4000) := '';
w_stringa_parametri    varchar2(4000) := '';
w_ultimo_valore        parametri_export.ultimo_valore%type;
w_num_parametri_uscita number := 0;
w_par_out1_number      number;
w_par_out1_varchar2    varchar2(2000);
w_par_out1_date        date;
w_formato_paex_out1    varchar2(100);
w_par_out2_number      number;
w_par_out2_varchar2    varchar2(2000);
w_par_out2_date        date;
w_formato_paex_out2    varchar2(100);
w_par_out3_number      number;
w_par_out3_varchar2    varchar2(2000);
w_par_out3_date        date;
w_formato_paex_out3    varchar2(100);
w_conta_parametri_out number := 0;
CURSOR sel_paex (p_tipo_export tipi_export.tipo_export%type) IS
    select paex.parametro_export
         , paex.nome_parametro
         , paex.tipo_parametro
         , paex.formato_parametro
         , paex.ultimo_valore
         , paex.valore_predefinito
      from parametri_export paex
     where paex.tipo_export     = p_tipo_export
  order by paex.parametro_export
    ;
CURSOR sel_paex_out (p_tipo_export tipi_export.tipo_export%type) IS
    select paex.parametro_export
         , paex.nome_parametro
         , paex.tipo_parametro
         , paex.formato_parametro
         , paex.ultimo_valore
         , paex.valore_predefinito
      from parametri_export paex
     where paex.tipo_export     = p_tipo_export
       and paex.tipo_parametro in ('A','U')
  order by paex.parametro_export
    ;
BEGIN
   BEGIN
      select tiex.descrizione
           , tiex.nome_procedura
        into w_descrizione_export
           , w_nome_procedura
        from tipi_export tiex
       where tiex.tipo_export = a_tipo_export
         ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Tipo Export Non previsto';
         raise errore;
   end;
   w_stringa_lancio := w_nome_procedura;
   for rec_paex in sel_paex(a_tipo_export) loop
     w_errore := 'Sel.parametri export';
      if rec_paex.ultimo_valore is null then
         if rec_paex.formato_parametro = 'date' and rec_paex.valore_predefinito = 'SYSDATE' then
            w_ultimo_valore := to_char(sysdate,'dd/mm/yyyy');
         else
            w_ultimo_valore := rec_paex.valore_predefinito;
         end if;
      else
         w_ultimo_valore := rec_paex.ultimo_valore;
      end if;
      if rec_paex.tipo_parametro  = 'I' then
         w_errore := 'Sel.parametri export I';
         if rec_paex.formato_parametro = 'number' then
            w_stringa_parametri := w_stringa_parametri||','||nvl(replace(w_ultimo_valore,',','.'),'to_number(null)');
         elsif rec_paex.formato_parametro = 'varchar2' then
            w_stringa_parametri := w_stringa_parametri||','||''''||w_ultimo_valore||'''';
         elsif rec_paex.formato_parametro = 'date' then
            w_stringa_parametri := w_stringa_parametri||','||'to_date('''||w_ultimo_valore||''',''dd/mm/yyyy'')';
         else
            w_errore := 'Formato Parametro '||rec_paex.nome_parametro||' non previsto';
            raise errore;
         end if;
      else
         w_errore := 'Sel.parametri export O';
         if w_num_parametri_uscita = 0 then
            w_stringa_parametri := w_stringa_parametri||','||':par1';
            if rec_paex.formato_parametro = 'number' then
               w_par_out1_number   := to_number(replace(w_ultimo_valore,',','.'));
               w_formato_paex_out1 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'varchar2' then
               w_par_out1_varchar2 := w_ultimo_valore;
               w_formato_paex_out1 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'date' then
               w_par_out1_date     := to_date(w_ultimo_valore,'dd/mm/yyyy');
               w_formato_paex_out1 := rec_paex.formato_parametro;
            else
               w_errore := 'Formato Parametro '||rec_paex.nome_parametro||' non previsto';
               raise errore;
            end if;
         elsif w_num_parametri_uscita = 1 then
           w_stringa_parametri := w_stringa_parametri||','||':par2';
            if rec_paex.formato_parametro = 'number' then
               w_par_out2_number   := to_number(replace(w_ultimo_valore,',','.'));
               w_formato_paex_out2 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'varchar2' then
               w_par_out2_varchar2 := w_ultimo_valore;
               w_formato_paex_out2 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'date' then
               w_par_out2_date     := to_date(w_ultimo_valore,'dd/mm/yyyy');
               w_formato_paex_out2 := rec_paex.formato_parametro;
            else
               w_errore := 'Formato Parametro '||rec_paex.nome_parametro||' non previsto';
               raise errore;
            end if;
         elsif w_num_parametri_uscita = 2 then
            w_stringa_parametri := w_stringa_parametri||','||':par3';
            if rec_paex.formato_parametro = 'number' then
               w_par_out3_number   := to_number(replace(w_ultimo_valore,',','.'));
               w_formato_paex_out3 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'varchar2' then
               w_par_out3_varchar2 := w_ultimo_valore;
               w_formato_paex_out3 := rec_paex.formato_parametro;
            elsif rec_paex.formato_parametro = 'date' then
               w_par_out3_date     := to_date(w_ultimo_valore,'dd/mm/yyyy');
               w_formato_paex_out3 := rec_paex.formato_parametro;
            else
               w_errore := 'Formato Parametro '||rec_paex.nome_parametro||' non previsto';
               raise errore;
            end if;
         end if;
         w_num_parametri_uscita := w_num_parametri_uscita + 1;
      end if;
   end loop;
   w_errore := 'Composizione stringa lancio';
   if w_stringa_parametri is not null then
      w_stringa_lancio := w_stringa_lancio||'('||substr(w_stringa_parametri,2)||')';
   end if;
   w_errore := w_stringa_lancio;
--   raise errore;
   if w_num_parametri_uscita = 0 then
      w_stringa_lancio := 'BEGIN '||w_stringa_lancio ||'; END;';
      execute immediate (w_stringa_lancio);
   elsif w_num_parametri_uscita = 1 then
      if w_formato_paex_out1 = 'number' then
         execute immediate 'BEGIN '||w_stringa_lancio ||'; END;'
         using  in out w_par_out1_number;
      elsif w_formato_paex_out1 = 'varchar2' then
         execute immediate 'BEGIN '||w_stringa_lancio ||'; END;'
         using  in out w_par_out1_varchar2;
      elsif w_formato_paex_out1 = 'date' then
         execute immediate 'BEGIN '||w_stringa_lancio ||'; END;'
         using  in out w_par_out1_date;
      else
         w_errore := 'Formato Parametro '||w_formato_paex_out1||' non previsto';
         raise errore;
      end if;
   elsif w_num_parametri_uscita = 3 then  -- Previsti solo tre parametri numerici
      execute immediate 'BEGIN '||w_stringa_lancio ||'; END;'
      using  in out w_par_out1_number, in out w_par_out2_number, in out w_par_out3_number;
   else
      w_errore := 'Numero Parametri di uscita ('||to_char(w_num_parametri_uscita)||') non previsti';
      raise errore;
   end if;
   for rec_paex_out in sel_paex_out(a_tipo_export) loop
      w_errore := 'Sel.parametri uscita';
      w_conta_parametri_out := w_conta_parametri_out + 1;
      begin
         update parametri_export
            set ultimo_valore = decode(w_conta_parametri_out
                                      ,1,decode(rec_paex_out.formato_parametro
                                               ,'number',replace(to_char(w_par_out1_number),'.',',')
                                               ,'varchar2',w_par_out1_varchar2
                                               ,'date',to_char(w_par_out1_date,'dd/mm/yyyy')
                                               ,''
                                               )
                                      ,2,decode(rec_paex_out.formato_parametro
                                               ,'number',replace(to_char(w_par_out2_number),'.',',')
                                               ,'varchar2',w_par_out2_varchar2
                                               ,'date',to_char(w_par_out2_date,'dd/mm/yyyy')
                                               ,''
                                               )
                                      ,3,decode(rec_paex_out.formato_parametro
                                               ,'number',replace(to_char(w_par_out3_number),'.',',')
                                               ,'varchar2',w_par_out3_varchar2
                                               ,'date',to_char(w_par_out3_date,'dd/mm/yyyy')
                                               ,''
                                               )
                                      )
          where tipo_export      = a_tipo_export
            and parametro_export = rec_paex_out.parametro_export
            ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in aggiornamento paramtri di Uscita';
            raise errore;
      end;
   end loop;
   commit;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Export Dati - '||w_errore||
         '('||SQLERRM||')');
END;
/* End Procedure: EXPORT_DATI */
/

