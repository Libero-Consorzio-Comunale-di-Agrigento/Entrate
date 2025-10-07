--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_arrotonda stripComments:false runOnChange:true 
 
create or replace function F_ARROTONDA
(a_tipo in number)
return number
is
nArr       number(2);
sFase_Euro number(1);
begin
   begin
      select fase_euro
        into sFase_Euro
        from dati_generali
       where chiave = 1
      ;
   exception
      when no_data_found then
         sFase_Euro := 2;
   end;
   if a_tipo = 0 then
      if sFase_Euro = 1 then
         nArr := 0;
      else
         nArr := 2;
      end if;
   else
      if sFase_Euro = 1 then
         nArr := -3;
      else
         nArr := 0;
      end if;
   end if;
   return nArr;
end;
/* End Function: F_ARROTONDA */
/

