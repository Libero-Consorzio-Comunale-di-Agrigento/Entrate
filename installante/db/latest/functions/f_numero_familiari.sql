--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_numero_familiari stripComments:false runOnChange:true 
 
create or replace function F_NUMERO_FAMILIARI
(a_ni      IN number
)
RETURN number
IS
familiari       number(3) := 0;
w_tipo_residente   number;
w_fascia      number;
w_cod_fam     number;
BEGIN
  BEGIN
    select tipo_residente,fascia,cod_fam
      into w_tipo_residente,w_fascia,w_cod_fam
      from soggetti
     where ni = a_ni
    ;
  EXCEPTION
    WHEN others THEN
    RETURN -1;
  END;
  IF w_tipo_residente = 0 and w_fascia in (1,3) THEN
    BEGIN
      select count(ni)
        into familiari
        from soggetti a
       where a.fascia  = w_fascia
         and a.cod_fam = w_cod_fam
      ;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN -1;
    END;
  END IF;
  RETURN familiari;
END;
/* End Function: F_NUMERO_FAMILIARI */
/

