--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_delta_rate stripComments:false runOnChange:true 
 
create or replace function F_DELTA_RATE
(a_ruolo IN number)
Return number
is
--Dato un ruolo, si confronta la data di emissione con le date
--di scadenza dei pagamenti totalizzando quelle scadute.
w_delta_rate     number;
BEGIN
   select count(*)
     into w_delta_rate
     from scadenze          scad
         ,ruoli             ruol
    where scad.anno            = ruol.anno_ruolo
      and scad.tipo_tributo    = ruol.tipo_tributo
      and scad.tipo_scadenza   = 'V'
      and scad.data_scadenza   < ruol.data_emissione
      and (    scad.rata       = 0
           and not exists
              (select 1
                 from scadenze sca2
                where sca2.tipo_tributo    = scad.tipo_tributo
                  and sca2.anno            = scad.anno
                  and sca2.tipo_scadenza   = 'V'
                  and sca2.rata            > 0
              )
           or  scad.rata       > 0
          )
      and ruol.ruolo           = a_ruolo
   ;
   Return w_delta_rate;
END;
/* End Function: F_DELTA_RATE */
/

