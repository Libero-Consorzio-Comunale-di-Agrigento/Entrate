--liquibase formatted sql
--changeset abrandolini:20250331_123138_f_matricola_pd_TR4 stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

CREATE OR REPLACE function F_MATRICOLA_PD
   (p_matricola      number)
return number
IS
w_matricola_pd      number;
begin
   w_matricola_pd   := null;
   return w_matricola_pd;
end;

/
