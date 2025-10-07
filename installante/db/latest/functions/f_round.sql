--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_round stripComments:false runOnChange:true 
 
create or replace function F_ROUND
(a_valore    in number,
 a_tipo    in number
)
return number
is
nValore    number;
sFase_Euro number;
nArr       number;
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
         nArr    := 0;
         nValore := a_valore;
      else
         nArr    := 2;
         nValore := a_valore;
      end if;
   elsif a_tipo != 3 then
      if sFase_Euro = 1 then
         nArr    := -3;
         nValore := a_valore - 1;
      else
         nArr    := 2;
         nValore := a_valore;
      end if;
   elsif a_tipo = 3 then -- per gestire arrotondamento a 3 decimali per le rendite AB (13/12/2013)
      if sFase_Euro = 1 then
         nArr    := -3;
         nValore := a_valore - 1;
      else
         nArr    := 3;
         nValore := a_valore;
      end if;
   end if;
   nValore := round(nValore,nArr);
   return nValore;
end;
/* End Function: F_ROUND */
/

