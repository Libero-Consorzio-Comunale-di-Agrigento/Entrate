--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_spazi_stringa stripComments:false runOnChange:true 
 
create or replace function F_SPAZI_STRINGA
(a_frase IN varchar2)
RETURN varchar2
IS
w_stringa2 varchar2(50):= '';
w_lunghezza    NUMBER;
w_stringa1 varchar2(50):= '';
begin
  w_lunghezza := length(a_frase);
  FOR i IN 1..w_lunghezza - 1 LOOP
      w_stringa1 := substr(a_frase,i,1);
      w_stringa2 := w_stringa2 || w_stringa1 || ' ';
  END LOOP;
  w_stringa2 := w_stringa2 || substr(a_frase,w_lunghezza,1);
  RETURN (w_stringa2);
EXCEPTION
   WHEN OTHERS THEN
        RETURN null;
end;
/* End Function: F_SPAZI_STRINGA */
/

