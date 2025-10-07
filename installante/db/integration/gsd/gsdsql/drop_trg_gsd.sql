--liquibase formatted sql
--changeset abrandolini:20250514_124200_drop_trg_gsd_su_GSD stripComments:false runOnChange:true context:"TRG2 or TRV2"

/*	DATA: 12/07/2000	*/

create or replace procedure DROP_TRG_GSD
is
cursor_name integer;
w_controllo integer:=0;
errore_p exception;
errore_t exception;
pragma exception_init (errore_p, -4043);
pragma exception_init (errore_t, -4080);

BEGIN
BEGIN
select 1
into w_controllo
from dati_generali
where (pro_cliente = 36 and com_cliente = 40)  -- Sassuolo
   or (pro_cliente = 50 and com_cliente = 29)  -- Pontedera
   or (pro_cliente = 6  and com_cliente = 174) -- Tortona
   or (pro_cliente = 52 and com_cliente = 28)  -- San Gimignano
   or (pro_cliente = 48 and com_cliente = 33)  -- Pontassieve
   or (pro_cliente = 15 and com_cliente = 77)  -- Cinisello Balsamo
   or (pro_cliente = 15 and com_cliente = 209) -- Sesto San Giovanni
   or (pro_cliente = 48 and com_cliente = 10)  -- Castelfiorentino
   or (flag_provincia = 'S')                   -- Prov Livorno, Frosinone, Siracusa
;
cursor_name := dbms_sql.OPEN_CURSOR;
BEGIN
     dbms_sql.parse(cursor_name, 'drop procedure ANAANA_TR4_FI', dbms_sql.native);
EXCEPTION
     when errore_p then null;
END;
BEGIN
     dbms_sql.parse(cursor_name, 'drop trigger ANAANA_TR4_TD', dbms_sql.native);
EXCEPTION
     when errore_t then null;
END;
BEGIN
     dbms_sql.parse(cursor_name, 'drop trigger ANAANA_TR4_TIU', dbms_sql.native);
EXCEPTION
     when errore_t then null;
END;
BEGIN
     dbms_sql.parse(cursor_name, 'drop procedure ANAFAM_TR4_FI', dbms_sql.native);
EXCEPTION
     when errore_p then null;
END;
BEGIN
     dbms_sql.parse(cursor_name, 'drop trigger ANAFAM_TR4_TIU', dbms_sql.native);
EXCEPTION
     when errore_t then null;
END;
   dbms_sql.close_cursor(cursor_name);
EXCEPTION
    WHEN no_data_found THEN
      null;
WHEN others THEN
      RAISE_APPLICATION_ERROR
	(-20999,'Errore in ricerca Comune',true);
END;
END;
/* End Procedure: DROP_TRG_GSD */
/

