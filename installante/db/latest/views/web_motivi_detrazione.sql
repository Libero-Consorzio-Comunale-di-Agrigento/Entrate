--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_motivi_detrazione stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW WEB_MOTIVI_DETRAZIONE AS
SELECT
     tipo_tributo
   , motivo_detrazione
   , descrizione
   , tipo_tributo || lpad(to_char(motivo_detrazione), 2, '0') id_motivo_detrazione
FROM
  motivi_detrazione;
comment on table WEB_MOTIVI_DETRAZIONE is 'WEB_MOTIVI_DETRAZIONE';

