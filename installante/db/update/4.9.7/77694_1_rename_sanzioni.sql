--liquibase formatted sql 
--changeset rvattolo:20250715_171616_77694_1_rename_sanzioni stripComments:false runOnChange:true 
 
-- 
--	77694/78175 : Rinomina sanzioni 
-- 	  N° 01 : Interessi Supplettivo per descrizione errata
--
update sanzioni set descrizione = 'INTERESSI SUPPLETTIVO RATA 1'
 where tipo_tributo = 'TARSU' and cod_sanzione = 791
   and descrizione = 'INTERESSI SALDO/TOTALE RATA 1'
/
update sanzioni set descrizione = 'INTERESSI SUPPLETTIVO RATA 2'
 where tipo_tributo = 'TARSU' and cod_sanzione = 792
   and descrizione = 'INTERESSI SALDO/TOTALE RATA 2'
/
update sanzioni set descrizione = 'INTERESSI SUPPLETTIVO RATA 3'
 where tipo_tributo = 'TARSU' and cod_sanzione = 793
   and descrizione = 'INTERESSI SALDO/TOTALE RATA 3'
/
update sanzioni set descrizione = 'INTERESSI SUPPLETTIVO RATA 4'
 where tipo_tributo = 'TARSU' and cod_sanzione = 794
   and descrizione = 'INTERESSI SALDO/TOTALE RATA 4'
/
