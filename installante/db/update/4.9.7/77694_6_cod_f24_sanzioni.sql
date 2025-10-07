--liquibase formatted sql 
--changeset rvattolo:20250715_171621_77694_6_cod_f24_sanzioni stripComments:false runOnChange:true 

-- 
--	77694/78175 : Rinomina sanzioni 
-- 	  N° 06 : Aggiorna codice F24 non compilati su alcune sanzioni 'Evaso'
--
update sanzioni
   set cod_tributo_f24 = '3944'
 where tipo_tributo = 'TARSU'
   and cod_sanzione in (641, 711, 721, 731, 741)
   and cod_tributo_f24 is null
/
update sanzioni
   set cod_tributo_f24 = '3946'
 where tipo_tributo = 'TARSU'
   and cod_sanzione in (646, 716, 726, 736, 746)
   and cod_tributo_f24 is null
/
update sanzioni
   set cod_tributo_f24 = '3946'
 where tipo_tributo = 'TARSU'
   and cod_sanzione in (617,627,637,647, 717,727,737,747)
   and cod_tributo_f24 is null
/
update sanzioni
   set cod_tributo_f24 = '3946'
 where tipo_tributo = 'TARSU'
   and cod_sanzione in (618,628,638,648, 718,728,738,748)
   and cod_tributo_f24 is null
/
update sanzioni
   set cod_tributo_f24 = '3946'
 where tipo_tributo = 'TARSU'
   and cod_sanzione in (139, 619,629,639,649, 719,729,739,749)
   and cod_tributo_f24 is null
/
