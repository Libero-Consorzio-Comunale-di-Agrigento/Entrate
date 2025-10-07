--liquibase formatted sql 
--changeset abrandolini:20250326_152423_lire_euro stripComments:false runOnChange:true 
 
create or replace procedure LIRE_EURO
( A_cambio  IN     NUMBER
, A_lire    IN OUT NUMBER
, A_euro    IN OUT NUMBER
)
is
D_cambio    number(6,2);
begin
   if nvl(A_cambio,0) = 0 then
      raise_application_error(-20999,'Cambio obbligatorio per effetuare conversione');
   elsif (A_lire is not null and A_euro is not null) or
         (A_lire is null and A_euro is null) then
         raise_application_error(-20999,'Importo Lire ed Euro sono mutualmente esclusivi');
   end if;
--
   D_cambio := round(A_cambio,2);
   A_lire := round(A_lire);
   A_euro := round(A_euro,2);
--
   if A_lire is not null then
      A_euro := round(A_lire / D_cambio,2);
   else
      A_lire := round(A_euro * D_cambio);
   end if;
end;
/* End Procedure: LIRE_EURO */
/

