--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_num_pratiche_ruolo_cont stripComments:false runOnChange:true 
 
create or replace function F_NUM_PRATICHE_RUOLO_CONT
( a_cod_fiscale  in varchar2
, a_ruolo        in number
) return number
IS
   w_num_pratiche      number;
BEGIN
   begin
      select count(1) num_pratiche_a_ruolo
        into w_num_pratiche
        from ( SELECT count(1) conta
                 FROM RUOLI
                    , RUOLI_CONTRIBUENTE
                WHERE ruoli.ruolo = ruoli_contribuente.ruolo (+)
                  and RUOLI.SPECIE_RUOLO = 1
                  and ruoli.ruolo        = a_ruolo
                  and ruoli_contribuente.cod_fiscale = a_cod_fiscale
             GROUP BY RUOLI_CONTRIBUENTE.pratica
             )
             ;
   end;
   return w_num_pratiche;
END;
/* End Function: F_NUM_PRATICHE_RUOLO_CONT */
/

