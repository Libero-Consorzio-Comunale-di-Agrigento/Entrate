--liquibase formatted sql 
--changeset abrandolini:20250326_152423_intestazione_minuta_ruolo stripComments:false runOnChange:true 
 
create or replace procedure INTESTAZIONE_MINUTA_RUOLO
(a_ruolo      IN    number,
 a_tributo_1      IN OUT   number,
 a_tributo_2      IN OUT   number,
 a_tributo_3      IN OUT   number,
 a_tributo_4      IN OUT   number,
 a_tributo_5      IN OUT   number,
 a_tributo_6      IN OUT   number)
IS
w_conta         number := 0;
CURSOR sel_ruco IS
       select distinct ruco.tributo
         from ruoli_contribuente ruco
      where ruco.ruolo   = a_ruolo
    order by decode(ruco.tributo,434,1,453,1,433,2,ruco.tributo)
       ;
BEGIN
  a_tributo_1  := '';
  a_tributo_2  := '';
  a_tributo_3  := '';
  a_tributo_4  := '';
  a_tributo_5  := '';
  a_tributo_6  := '';
  FOR rec_ruco IN sel_ruco LOOP
      w_conta := w_conta + 1;
      IF w_conta = 1 THEN
         a_tributo_1  := rec_ruco.tributo;
      ELSIF w_conta = 2 THEN
         a_tributo_2  := rec_ruco.tributo;
      ELSIF w_conta = 3 THEN
       a_tributo_3  := rec_ruco.tributo;
      ELSIF w_conta = 4 THEN
    a_tributo_4  := rec_ruco.tributo;
      ELSIF w_conta = 5 THEN
    a_tributo_5  := rec_ruco.tributo;
      ELSE
    a_tributo_6  := rec_ruco.tributo;
      END IF;
  END LOOP;
END;
/* End Procedure: INTESTAZIONE_MINUTA_RUOLO */
/

