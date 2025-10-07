--liquibase formatted sql
--changeset abrandolini:20250331_123138_ff_matricola_md_TR4 stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

CREATE OR REPLACE function F_MATRICOLA_MD
   (p_matricola      number)
return number
IS
w_matricola_md      number;
begin
   w_matricola_md   := null;
   return w_matricola_md;
end;

/
