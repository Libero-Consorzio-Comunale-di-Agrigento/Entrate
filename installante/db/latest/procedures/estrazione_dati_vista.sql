--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_dati_vista stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_DATI_VISTA
(a_nome_vista                    in varchar2
,a_separatore                    in varchar2
,a_intestazione_campi            in varchar2
) is
cursor sel_col is
   select column_name  nomecol
     from user_tab_columns
    where table_name = upper(a_nome_vista)
 order by column_id
     ;
squery           varchar2(4000);
lseparatore      number;
w_esiste_vista   number;
BEGIN
  -- Verifica che la vista esista
  begin
     select count(1)
       into w_esiste_vista
       from user_objects
      where object_type = 'VIEW'
        and object_name = upper(a_nome_vista)
          ;
  exception
     WHEN others THEN
        w_esiste_vista := 0;
  end;
  if w_esiste_vista = 0 then
      RAISE_APPLICATION_ERROR(-20919,'Errore: La vista indicata non esiste!');
  end if;
  BEGIN
      si4.sql_execute('truncate table wrk_trasmissioni');
  EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in pulizia tabella di lavoro '||
                                        ' ('||SQLERRM||')');
  END;
  lseparatore := length(a_separatore);
  -- inserimento intestazione
  if substr(a_intestazione_campi,1,1) = 'S' then
     squery := 'insert into wrk_trasmissioni  (numero, dati)
                values (lpad(to_char(1),15,''0''), ''';
     FOR rec_col IN sel_col LOOP
            squery := squery||rec_col.nomecol||a_separatore;
     end loop;
     squery := substr(squery,1, length(squery) - lseparatore);
     squery := squery||''')';
     si4.SQL_EXECUTE(squery);
  end if;
  squery := 'insert into wrk_trasmissioni  (numero, dati)
             select lpad(to_char(rownum + 1),15,''0''), ';
  FOR rec_col IN sel_col LOOP
         squery := squery||rec_col.nomecol||'||'''||a_separatore||'''||';
  end loop;
  squery := substr(squery,1, length(squery) - (lseparatore + 6));
  squery := squery||' from '||a_nome_vista;
  si4.SQL_EXECUTE(squery);
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR(-20919,'Errore generico '||
                                   ' ('||sqlerrm||')');
END;
/* End Procedure: ESTRAZIONE_DATI_VISTA */
/

